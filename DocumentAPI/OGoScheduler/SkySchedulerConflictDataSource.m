/*
  Copyright (C) 2000-2004 SKYRIX Software AG

  This file is part of OpenGroupware.org.

  OGo is free software; you can redistribute it and/or modify it under
  the terms of the GNU Lesser General Public License as published by the
  Free Software Foundation; either version 2, or (at your option) any
  later version.

  OGo is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or
  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
  License for more details.

  You should have received a copy of the GNU Lesser General Public
  License along with OGo; see the file COPYING.  If not, write to the
  Free Software Foundation, 59 Temple Place - Suite 330, Boston, MA
  02111-1307, USA.
*/
// $Id$

#include "SkySchedulerConflictDataSource.h"
#include <LSFoundation/OGoContextSession.h>
#include "common.h"
#include "SkyAppointmentQualifier.h"
#include <EOControl/EOSortOrdering.h>
#include "OGoCycleDateCalculator.h"

@implementation SkySchedulerConflictDataSource

static NSArray  *startDateSortOrderings = nil;
static NSArray  *coreAttrNames          = nil;
static NSNumber *yesNum        = nil;
static int      LSMaxAptCycles = 0;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  if (startDateSortOrderings == nil) {
    EOSortOrdering *so;
    
    so = [EOSortOrdering sortOrderingWithKey:@"startDate" 
                         selector:EOCompareAscending];
    startDateSortOrderings = [[NSArray alloc] initWithObjects:&so count:1];
  }

  if (coreAttrNames == nil) {
    coreAttrNames = 
        [[NSArray alloc] initWithObjects:@"startDate", @"endDate",
                         @"resourceNames", @"title", @"location",
                         @"globalID", @"permissions", @"dateId",
                         @"participants.isTeam",
                         @"participants.isAccount",
                         @"participants.companyId",
                         @"participants.login",
                         @"participants.name",
                         @"participants.description",
                         nil];
  }
  
  LSMaxAptCycles = [[ud objectForKey:@"LSMaxAptCycles"] intValue];
  if (LSMaxAptCycles < 1) LSMaxAptCycles = 100;
  
  if (yesNum == nil) yesNum = [[NSNumber numberWithBool:YES] retain];
}

- (id)initWithContext:(id)_ctx {
  if ((self = [super init])) {
    self->lso = [_ctx retain];
  }
  return self;
}
- (id)init {
  return [self initWithContext:nil];
}

- (void)dealloc {
  [self->appointment release];
  [self->conflicts   release];
  [self->lso         release];
  [self->dataSources release];
  [super dealloc];
}

/* operations */

- (int)_computeDayForItem:(int)_i {
  NSCalendarDate *startDate;
  NSCalendarDate *testDate;
  
  startDate = [self->appointment valueForKey:@"startDate"];
  testDate  = [startDate dateByAddingYears:0 months:0
                         days:(_i * 1) hours:0 minutes:0 seconds:0];
  return [testDate dayOfWeek];
}

- (NSArray *)_appointmentDates {
  NSString       *type;
  NSCalendarDate *sD, *eD, *cycleDate;
  id             apt, tmp;
  NSNumber       *dateId;
  
  apt    = self->appointment;
  type   = [apt valueForKey:@"type"];
  sD     = [[[apt valueForKey:@"startDate"] copy] autorelease];
  eD     = [[[apt valueForKey:@"endDate"] copy] autorelease];
  
  tmp = [apt valueForKey:@"cycleEndDate"];
  cycleDate = [tmp isNotNull] ? [tmp endOfDay] : nil;
  
  dateId = [apt valueForKey:@"dateId"];
  
  if ([[apt valueForKey:@"setAllCyclic"] boolValue])
    return [apt valueForKey:@"cyclics"];
  
  if ([type isNotNull] && (![dateId isNotNull])) {
    return
      [OGoCycleDateCalculator cycleDatesForStartDate:sD
                              endDate:eD
                              type:type
                              maxCycles:LSMaxAptCycles
                              startAt:0
                              endDate:cycleDate
                              keepTime:YES];
  }
  
  tmp = [NSDictionary dictionaryWithObjectsAndKeys:
			sD, @"startDate", eD, @"endDate",
		        dateId, @"dateId", nil];
  return [NSArray arrayWithObject:tmp];
}

/* accessors */

- (void)setAppointment:(id)_apt {
  if (self->appointment != _apt) {
    [self->conflicts release]; 
    self->conflicts = nil;
  }
  ASSIGN(self->appointment, _apt);
}
- (id)appointment {
  return self->appointment;
}

- (void)setContext:(id)_ctx {
  if ([_ctx isKindOfClass:[OGoContextSession class]])
    _ctx = [_ctx commandContext];
  
  ASSIGN(self->lso, _ctx);
}
- (id)context {
  return self->lso;
}

- (void)addDataSource:(EODataSource *)_ds {
  if (self->dataSources == nil)
    self->dataSources = [[NSMutableArray alloc] init];
  if (![self->dataSources containsObject:_ds])
    [self->dataSources addObject:_ds];
}

- (BOOL)hasConflicts {
  return ([[self fetchObjects] count] > 0) ? YES : NO;
}

- (NSArray *)fetchConflictsFromDataSource:(EODataSource *)_ds
                                  forDate:(NSDictionary *)_dict
                             participants:(NSArray *)_participants
                                resources:(NSArray *)_resources
{
  EOFetchSpecification    *fs;
  SkyAppointmentQualifier *qual;
  NSCalendarDate          *sD;
  NSArray                 *result;
  
  qual = [[SkyAppointmentQualifier alloc] init];
  [qual setStartDate:(sD = [_dict valueForKey:@"startDate"])];
  [qual setEndDate:   [_dict valueForKey:@"endDate"]];
  [qual setTimeZone:  [sD timeZone]];
  [qual setCompanies: [_participants valueForKey:@"globalID"]];
  [qual setResources: _resources];

  fs = [EOFetchSpecification fetchSpecificationWithEntityName:@"date"
                             qualifier:qual 
                             sortOrderings:startDateSortOrderings];
  [qual release];
  [_ds setFetchSpecification:fs];
  result = [_ds fetchObjects];
  return result;
}

- (NSCalendarDate *)copyDateObject:(NSCalendarDate *)_date {
  // TODO: this looks weird? why not use -copy? (must have a reason...)
  if (![_date isNotNull])
    return nil;
  
  return [NSCalendarDate dateWithYear:[_date yearOfCommonEra]
                         month:[_date monthOfYear]
                         day:[_date dayOfMonth]
                         hour:[_date hourOfDay]
                         minute:[_date minuteOfHour]
                         second:[_date secondOfMinute]
                         timeZone:[_date timeZone]];
}

- (NSArray *)_fetchConflictGIDsForParticipants:(NSArray *)_participants
  andResources:(NSArray *)_resources
  from:(NSCalendarDate *)_startDate to:(NSCalendarDate *)_endDate
  onAppointment:(id)_apt
{
  NSArray      *lconflicts;
  NSDictionary *args;
  
  if ([[_apt valueForKey:@"dateId"] isNotNull]) {
    args = [NSDictionary dictionaryWithObjectsAndKeys:
                           _startDate,    @"begin",
                           _endDate,      @"end",
                           _participants, @"staffList",
                           yesNum,        @"fetchGlobalIDs",
                           _resources,    @"resourceList",
                           _apt,          @"appointment",
                         nil];
  }
  else {
    args = [NSDictionary dictionaryWithObjectsAndKeys:
                           _startDate,    @"begin",
                           _endDate,      @"end",
                           _participants, @"staffList",
                           yesNum,        @"fetchGlobalIDs",
                           _resources,    @"resourceList",
                         nil];
  }
        
  lconflicts = [(id)self->lso
                    runCommand:@"appointment::conflicts"
                    arguments:args];
  return lconflicts;
}

- (NSArray *)_fetchAppointmentsForGIDs:(NSArray *)_gids 
  timeZone:(NSTimeZone *)_tz 
{
  NSDictionary *args;
  
  if (_gids == nil)
    return nil;
  if ([_gids count] == 0)
    return [NSArray array];

  args = [NSDictionary dictionaryWithObjectsAndKeys:
                           _gids,                  @"gids",
                           startDateSortOrderings, @"sortOrderings",
                           _tz,                    @"timeZone",
                           coreAttrNames,          @"attributes",
                       nil];
  return [(id)self->lso
              runCommand:@"appointment::get-by-globalid"
              arguments:args];
}

- (NSArray *)fetchObjects {
  // TODO: split up method
  NSTimeZone     *tz = nil;
  NSCalendarDate *startDate, *endDate;
  NSArray        *a, *aptDates, *participants;
  NSMutableArray *cs, *gids;
  id             apt;
  int i, cnt;
  int k, max;
  
  // TODO: datasources should never cache on their own but the client should
  //       use an EOCacheDataSource
  if (self->conflicts) /* cached */
    return self->conflicts;
  
  apt  = self->appointment;
  cs   = [NSMutableArray array];
  gids = [NSMutableArray array];
    
  if ((![[apt valueForKey:@"isConflictDisabled"] boolValue]) &&
      (![[apt valueForKey:@"isWarningIgnored"] boolValue])) {
    NSString *resourceNames = nil;

    aptDates = [self _appointmentDates];
      
      resourceNames = [apt valueForKey:@"resourceNames"];
      
      a = (![resourceNames isNotNull])
        ? [NSArray array]
        : [resourceNames componentsSeparatedByString:@", "];
      
      participants = [apt valueForKey:@"participants"];
      
      for (i = 0, cnt = [aptDates count]; i < cnt; i++) {
        id apt;
        NSArray *lconflicts;
        
        apt = [aptDates objectAtIndex:i];
        
        startDate = [self copyDateObject:[apt valueForKey:@"startDate"]];
        endDate   = [self copyDateObject:[apt valueForKey:@"endDate"]];
        if (i == 0) tz = [startDate timeZone];
        
        lconflicts = [self _fetchConflictGIDsForParticipants:participants
                           andResources:a
                           from:startDate to:endDate
                           onAppointment:apt];
        
        if ([lconflicts count] > 0)
          [gids addObjectsFromArray:lconflicts];
        
        /* fetch conflicting appointments from */
        for (k = 0, max = [self->dataSources count]; k < max; k++) {
          NSArray *llconflicts;
          
          llconflicts = [self fetchConflictsFromDataSource:
                                [self->dataSources objectAtIndex:k]
                              forDate:apt participants:participants 
                              resources:a];
          if ([llconflicts count] > 0)
            [cs addObjectsFromArray:llconflicts];
        }
      }
  }
  
  /* fetch appointments for global-ids */
  
  if ([gids count] > 0) {
    [cs addObjectsFromArray:
          [self _fetchAppointmentsForGIDs:gids timeZone:tz]];
  }
  
  self->conflicts = 
    [[cs sortedArrayUsingKeyOrderArray:startDateSortOrderings] retain];
  
  return self->conflicts;
}

@end /* SkySchedulerConflictDataSource */
