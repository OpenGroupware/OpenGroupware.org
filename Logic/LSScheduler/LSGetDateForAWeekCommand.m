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

#include <LSFoundation/LSDBObjectBaseCommand.h>

@class NSCalendarDate, NSTimeZone;

@interface LSGetDateForAWeekCommand : LSDBObjectBaseCommand
{
@private
  NSCalendarDate *monday;
  NSTimeZone     *timeZone;
  BOOL           fetchOwners;
  BOOL           withoutPrivate;
  BOOL           fetchGlobalIDs;
  id             team; 
  id             company;
  NSString       *resourceName;
}

/* accessors */

- (void)setMonday:(NSCalendarDate *)_monday;
- (NSCalendarDate *)monday;
- (BOOL)fetchGlobalIDs;

@end

#include "common.h"
#include <EOControl/EOKeyGlobalID.h>
#include <EOControl/EOSortOrdering.h>

@implementation LSGetDateForAWeekCommand

static NSArray *sortStartDateAsc = nil;

+ (void)initialize {
  if (sortStartDateAsc == nil) {
    EOSortOrdering *so;

    so = [EOSortOrdering sortOrderingWithKey:@"startDate" 
			 selector:EOCompareAscending];
    sortStartDateAsc = [[NSArray alloc] initWithObjects:&so count:1];
  }
}

- (void)dealloc {
  RELEASE(self->company);
  RELEASE(self->team);
  RELEASE(self->timeZone);
  RELEASE(self->monday);
  [super dealloc];
}

/* prepare for exec */

- (void)_prepareForExecutionInContext:(id)_context {
  if (self->timeZone == nil) {
    self->timeZone = [[self->monday timeZone] retain];
  }
  if ((self->company == nil) && (self->team == nil) &&
      (self->withoutPrivate) && (self->resourceName == nil)) {
    [self assert:YES reason:@"WARNING: missing values for query"];
  }
}

/* exec */

- (void)_executeInContext:(id)_context {
  NSCalendarDate *fromDate, *toDate;
  NSMutableArray *companies;
  NSArray        *aptGids;

  /* construct date range */
  
  fromDate = self->monday
    ? self->monday
    : [NSCalendarDate date];
  
  /* these two stmts should be reversed (workaround for LSWScheduler1) ! */
  /* this *breaks* SkyScheduler ! */
  fromDate = [fromDate mondayOfWeek];
  fromDate = [fromDate beginOfDay];  
  [fromDate setTimeZone:self->timeZone];

  toDate = [fromDate dateByAddingYears:0 months:0 days:7
                     hours:0 minutes:0 seconds:0];
  
  /* construct company set */

  companies = [NSMutableArray arrayWithCapacity:4];
  
  if (!self->withoutPrivate) {
    EOGlobalID *gid;
    gid = [[_context valueForKey:LSAccountKey] valueForKey:@"globalID"];
    [companies addObject:gid];
  }
  
  if (self->team) {
    EOGlobalID *gid;
    
    gid = [self->team valueForKey:@"globalID"];
    [companies addObject:gid];
  }

  if (self->company) {
    EOGlobalID *gid;
    
    gid = [self->company valueForKey:@"globalID"];
    [companies addObject:gid];
  }

  /* perform query */
  
  aptGids = LSRunCommandV(_context,
                          @"appointment", @"query",
                          @"fromDate",  fromDate,
                          @"toDate",    toDate,
                          @"companies", companies,
                          @"resourceNames", [NSArray arrayWithObject:
                                                     self->resourceName],
                          nil);
  if (!self->fetchGlobalIDs) {
    NSArray *eos;
    
    /* fetch objects */
    eos = LSRunCommandV(_context,
                        @"appointment", @"get-by-globalid",
                        @"gids",          aptGids,
                        @"timeZone",      self->timeZone,
                        @"sortOrderings", sortStartDateAsc,
                        nil);
    [self setReturnValue:eos];
  }
  else {
    [self setReturnValue:aptGids];
  }
}

/* accessors */

- (void)setMondayFromString:(NSString *)_mondayString {
  NSCalendarDate *myDate = nil;
  
  _mondayString = [_mondayString stringByAppendingString:@" 12:00:00"];
  myDate = [NSCalendarDate dateWithString:_mondayString
                           calendarFormat:@"%Y-%m-%d %H:%M:%S"];
  [self setMonday:myDate];
}

- (void)setMonday:(NSCalendarDate *)_monday {
  NSAssert1([_monday isKindOfClass:[NSCalendarDate class]],
            @"invalid parameter %@ ..", _monday);
  ASSIGNCOPY(self->monday, _monday);
}
- (NSCalendarDate *)monday {
  return self->monday;
}

- (void)setFetchOwners:(BOOL)_flag {
  self->fetchOwners = _flag;
}
- (BOOL)fetchOwners {
  return self->fetchOwners;
}

- (void)setFetchGlobalIDs:(BOOL)_flag {
  self->fetchGlobalIDs = _flag;
}
- (BOOL)fetchGlobalIDs {
  return self->fetchGlobalIDs;
}

- (void)setWithoutPrivate:(BOOL)_flag {
  self->withoutPrivate = _flag;
}
- (BOOL)withoutPrivate {
  return self->withoutPrivate;
}

- (void)setTimeZone:(NSTimeZone *)_zone {
  NSAssert1([_zone isKindOfClass:[NSTimeZone class]],
            @"invalid parameter %@ ..", _zone);
  ASSIGN(self->timeZone, _zone);
}
- (NSTimeZone *)timeZone {
  return self->timeZone;
}

- (void)setTeam:(id)_team {
  if (![_team isNotNull]) _team = nil;
  ASSIGN(self->team, _team);
}
- (id)team {
  return self->team;
}

- (void)setCompany:(id)_company {
  ASSIGN(self->company, _company);
}
- (id)company {
  return self->company;
}

- (void)setResourceName:(NSString *)_name {
  ASSIGNCOPY(self->resourceName, _name);
}
- (id)resourceName {
  return self->resourceName;
}

/* key-value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"monday"]) {
    if ([_value isKindOfClass:[NSCalendarDate class]])
      [self setMonday:_value];
    else
      [self setMondayFromString:[_value stringValue]];      
  }
  else if ([_key isEqualToString:@"resourceName"])
    [self setResourceName:_value];
  else if ([_key isEqualToString:@"team"])
    [self setTeam:_value];
  else if ([_key isEqualToString:@"company"])
    [self setCompany:_value];
  else if ([_key isEqualToString:@"fetchOwners"])
    [self setFetchOwners:[_value boolValue]];
  else if ([_key isEqualToString:@"withoutPrivate"])
    [self setWithoutPrivate:[_value boolValue]];
  else if ([_key isEqualToString:@"fetchGlobalIDs"])
    [self setFetchGlobalIDs:[_value boolValue]];
  else if ([_key isEqualToString:@"timeZone"])
    [self setTimeZone:_value];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  id v;
  
  if ([_key isEqualToString:@"monday"])
    v = [self monday];
  else if ([_key isEqualToString:@"team"])
    v = [self team];
  else if ([_key isEqualToString:@"resourceName"])
    v = [self resourceName];
  else if ([_key isEqualToString:@"company"])
    v = [self company];
  else if ([_key isEqualToString:@"fetchOwners"])
    v = [NSNumber numberWithBool:[self fetchOwners]];
  else if ([_key isEqualToString:@"timeZone"])
    v = [self timeZone];
  else if ([_key isEqualToString:@"withoutPrivate"])
    v = [NSNumber numberWithBool:[self withoutPrivate]];
  else if ([_key isEqualToString:@"fetchGlobalIDs"])
    v = [NSNumber numberWithBool:[self fetchGlobalIDs]];
  else 
    v = [super valueForKey:_key];
  
  return v;
}

@end /* LSGetDateForAWeekCommand */
