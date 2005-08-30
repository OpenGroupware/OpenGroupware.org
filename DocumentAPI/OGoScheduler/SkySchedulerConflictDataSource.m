/*
  Copyright (C) 2000-2005 SKYRIX Software AG

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
static NSArray  *emptyArray    = nil;
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
  
  if (yesNum     == nil) yesNum     = [[NSNumber numberWithBool:YES] retain];
  if (emptyArray == nil) emptyArray = [[NSArray alloc] init];
}

- (id)initWithContext:(LSCommandContext *)_ctx {
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

/* cycle calculation */

- (NSArray *)_appointmentDates {
  /* 
     Calculate 'date slots', process cycles.
  */
  NSString       *type;
  NSCalendarDate *sD, *eD, *cycleDate;
  id             apt, tmp;
  NSNumber       *dateId;
  
  apt  = self->appointment;
  type = [apt valueForKey:@"type"];
  sD   = [[[apt valueForKey:@"startDate"] copy] autorelease];
  eD   = [[[apt valueForKey:@"endDate"]   copy] autorelease];
  
  tmp = [apt valueForKey:@"cycleEndDate"];
  cycleDate = [tmp isNotNull] ? [tmp endOfDay] : nil;
  
  dateId = [apt valueForKey:@"dateId"];
  
  // TODO: what does this do?
  if ([[apt valueForKey:@"setAllCyclic"] boolValue])
    return [apt valueForKey:@"cyclics"];
  
  if ([type isNotNull] && ![dateId isNotNull]) {
    /* process as cycle */
    return [OGoCycleDateCalculator cycleDatesForStartDate:sD endDate:eD
                                   type:type maxCycles:LSMaxAptCycles
                                   startAt:0 endDate:cycleDate
                                   keepTime:YES];
  }
  
  tmp = [NSDictionary dictionaryWithObjectsAndKeys:
			sD, @"startDate", eD, @"endDate",
		        dateId, @"dateId", nil];
  return tmp ? [NSArray arrayWithObject:tmp] : nil;
}

/* accessors */

- (void)setAppointment:(id)_apt {
  if (self->appointment == _apt)
    return;

  [self->conflicts release]; 
  self->conflicts = nil;
  ASSIGN(self->appointment, _apt);

  [self postDataSourceChangedNotification];
}
- (id)appointment {
  return self->appointment;
}

- (void)setContext:(LSCommandContext *)_ctx {
  if ([_ctx isKindOfClass:[OGoContextSession class]]) {
    [self errorWithFormat:@"Called with OGoContextSession: %@", _ctx];
    _ctx = [(OGoContextSession *)_ctx commandContext];
  }
  
  ASSIGN(self->lso, _ctx);
}
- (LSCommandContext *)context {
  return self->lso;
}

- (void)addDataSource:(EODataSource *)_ds {
  if (self->dataSources == nil)
    self->dataSources = [[NSMutableArray alloc] initWithCapacity:2];
  
  if (![self->dataSources containsObject:_ds]) {
    [self->dataSources addObject:_ds];
    [self postDataSourceChangedNotification];
  }
}

- (BOOL)hasConflicts {
  // TODO: hm, hm. Should be done by the client, not a DS method!
  [self errorWithFormat:@"Called deprecated method: %s", __PRETTY_FUNCTION__];
  return ([[self fetchObjects] count] > 0) ? YES : NO;
}

/* source datasource */

- (EOFetchSpecification *)fetchSpecificationForDate:(NSDictionary *)_slot
  participants:(NSArray *)_participants
  resources:(NSArray *)_resources
{
  EOFetchSpecification    *fs;
  SkyAppointmentQualifier *qual;
  NSCalendarDate          *sD;
  
  qual = [[SkyAppointmentQualifier alloc] init];
  [qual setStartDate:(sD = [_slot valueForKey:@"startDate"])];
  [qual setEndDate:   [_slot valueForKey:@"endDate"]];
  [qual setTimeZone:  [sD timeZone]];
  [qual setCompanies: [_participants valueForKey:@"globalID"]];
  [qual setResources: _resources];

  fs = [EOFetchSpecification fetchSpecificationWithEntityName:@"date"
                             qualifier:qual 
                             sortOrderings:startDateSortOrderings];
  [qual release]; qual = nil;
  
  return fs;
}

- (NSArray *)fetchConflictsFromDataSource:(EODataSource *)_ds
  forDate:(NSDictionary *)_slot
  participants:(NSArray *)_participants
  resources:(NSArray *)_resources
{
  /* 
     Fetch all dates in the given range which match the participants
     and resources, aka 'the conflicts'.
  */
  EOFetchSpecification *fs;
  NSArray              *result;
  
  fs = [self fetchSpecificationForDate:_slot 
             participants:_participants resources:_resources];

  [_ds setFetchSpecification:fs];
  result = [_ds fetchObjects];
  return result;
}

/* handle NSCalendarDate objects */

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
    args = [[NSDictionary alloc] initWithObjectsAndKeys:
                           _startDate,    @"begin",
                           _endDate,      @"end",
                           _participants, @"staffList",
                           yesNum,        @"fetchGlobalIDs",
                           _resources,    @"resourceList",
                           _apt,          @"appointment",
                         nil];
  }
  else {
    args = [[NSDictionary alloc] initWithObjectsAndKeys:
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
  [args release]; args = nil;
  
  return lconflicts;
}

- (NSArray *)_fetchAppointmentsForGIDs:(NSArray *)_gids 
  timeZone:(NSTimeZone *)_tz 
{
  NSDictionary *args;
  
  if (_gids == nil)
    return nil;
  if ([_gids count] == 0)
    return emptyArray;

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

/* process apt */

- (BOOL)shouldProcessAppointment:(id)_apt {
  if ([[_apt valueForKey:@"isConflictDisabled"] boolValue])
    return NO;
  if ([[_apt valueForKey:@"isWarningIgnored"] boolValue])
    return NO;
  return YES;
}

- (NSTimeZone *)processAppointment:(id)apt
  addToConflicts:(NSMutableArray *)cs
  returnAptGIDs:(NSArray **)_gids
{
  /*
    Note: this uses and returns the timezone of the first object.
  */
  // TODO: whats the diff between 'cs' and _gids?
  //       I think 'cs' are objects from other datasources, like PalmDS
  NSMutableArray *gids;
  NSTimeZone     *tz = nil;
  NSString       *resourceNames = nil;
  NSCalendarDate *startDate, *endDate;
  NSArray        *a, *aptDates, *participants;
  int i, cnt;

  gids = [NSMutableArray arrayWithCapacity:16];
  
  /* this calculates recurrences and returns a set of slots(start/end/id) */
  aptDates = [self _appointmentDates];
  
  a = [(resourceNames = [apt valueForKey:@"resourceNames"]) isNotNull]
    ? [resourceNames componentsSeparatedByString:@", "]
    : emptyArray;
      
  participants = [apt valueForKey:@"participants"];
  
  /* aptDates contains the slots, usually just one, but for cycles more! */
  for (i = 0, cnt = [aptDates count]; i < cnt; i++) {
    NSArray *lconflicts;
    int k, max;
    NSDictionary *aptSlot;
    
    aptSlot = [aptDates objectAtIndex:i];
    
    startDate = [self copyDateObject:[aptSlot valueForKey:@"startDate"]];
    endDate   = [self copyDateObject:[aptSlot valueForKey:@"endDate"]];
    if (i == 0) tz = [startDate timeZone]; // TODO: is this correct? (use apt?)
    
    /* this calls appointment::conflicts */

    lconflicts = [self _fetchConflictGIDsForParticipants:participants
                       andResources:a
                       from:startDate to:endDate
                       onAppointment:aptSlot];
    
    if ([lconflicts count] > 0)
      [gids addObjectsFromArray:lconflicts];
    
    /* I _think_ that this the stuff below is to support Palm DS */
    
    for (k = 0, max = [self->dataSources count]; k < max; k++) {
      NSArray *llconflicts;
      
      /* all appointments in the same timeslot with the matching users */
      llconflicts = [self fetchConflictsFromDataSource:
                            [self->dataSources objectAtIndex:k]
                          forDate:aptSlot participants:participants 
                          resources:a];
      if ([llconflicts count] > 0)
        [cs addObjectsFromArray:llconflicts];
    }
  }

  if (_gids != NULL) *_gids = gids;
  return tz;
}

/* primary entry method */

- (NSArray *)fetchObjects {
  // TODO: split up method
  NSAutoreleasePool *pool;
  NSTimeZone     *tz = nil;
  NSMutableArray *cs;
  NSArray        *gids = nil;
  
  // TODO: datasources should never cache on their own but the client should
  //       use an EOCacheDataSource
  if (self->conflicts != nil) /* cached */
    return self->conflicts;

  pool = [[NSAutoreleasePool alloc] init];
  
  cs = [NSMutableArray arrayWithCapacity:16];
  if ([self shouldProcessAppointment:self->appointment]) {
    tz = [self processAppointment:self->appointment
               addToConflicts:cs
               returnAptGIDs:&gids];
  }
  
  /* fetch appointments for global-ids */
  
  if ([gids count] > 0) {
    [cs addObjectsFromArray:
          [self _fetchAppointmentsForGIDs:gids timeZone:tz]];
  }
  
  [self->conflicts release]; self->conflicts = nil;
  self->conflicts = 
    [[cs sortedArrayUsingKeyOrderArray:startDateSortOrderings] retain];
  
  [pool release]; pool = nil;
  
  return self->conflicts;
}

@end /* SkySchedulerConflictDataSource */
