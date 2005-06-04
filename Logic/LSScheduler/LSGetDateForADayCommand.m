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

@class NSCalendarDate, NSTimeZone, NSString, NSMutableSet;

@interface LSGetDateForADayCommand : LSDBObjectBaseCommand
{
@private
  NSCalendarDate *day;
  NSTimeZone     *timeZone;
  BOOL           fetchOwners;
  BOOL           withoutPrivate;
  id             team; // primary key of team
  NSMutableSet   *accounts;
  NSString       *title;
  NSString       *time;
}

// accessors

- (void)setDay:(NSCalendarDate *)_day;
- (NSCalendarDate *)day;

@end

#import "common.h"

@implementation LSGetDateForADayCommand

static NSNumber *nYes = nil;
static NSNumber *nNo  = nil;

+ (void)initialize {
  if (nYes == nil) nYes = [[NSNumber numberWithBool:YES] retain];
  if (nNo  == nil) nNo  = [[NSNumber numberWithBool:NO]  retain];
}
  
#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->accounts);
  RELEASE(self->team);
  RELEASE(self->timeZone);
  RELEASE(self->day);
  [super dealloc];
}
#endif

// command methods

- (void)_prepareForExecutionInContext:(id)_context {
  // prepare team

  if (self->day == nil)
    [self assert:(self->day != nil) reason:@"no day was setting"];
  
  if (self->accounts)
    [self->accounts removeAllObjects];
  else {
    self->accounts = [[NSMutableSet allocWithZone:[self zone]]
                                    initWithCapacity:16];
  }
  
  if (self->team) {
    NSArray *tmp;
    int i, count;

    tmp = [_context runCommand:@"team::members", @"object", self->team, nil];
    
    for (i = 0, count = [tmp count]; i < count; i++) {
      id account = [tmp objectAtIndex:i];
      if (account) [self->accounts addObject:account];
    }
    if (!self->withoutPrivate) {
      id login = nil;
	
      // get login
      login = [_context valueForKey:LSAccountKey];
      if (login) [self->accounts addObject:login];
    }
    else {
    }
  }
  else { // if team=nil => private
    id login = nil;

    login = [_context valueForKey:LSAccountKey];
    if (login) [self->accounts addObject:login];
  }
}

- (NSArray *)_filterAppointments:(NSArray *)_dates context:(id)_ctx {
  NSMutableArray *filtered = nil;
  int i, count = [_dates count];
  
  filtered = [[NSMutableArray allocWithZone:[self zone]] initWithCapacity:count];
  
  for (i = 0; i < count; i++) {
    id appointment;
    id participants;
    
    appointment  = [_dates objectAtIndex:i];
    participants = [appointment valueForKey:@"participants"];
    
    [self assert:(participants != nil)
          reason:@"participants key not set in appointment"];
    
    if ([participants count] == 0) {
      NSLog(@"WARNING: %@ no participants set for appointment %@, filtered out.",
            self, [appointment valueForKey:@"title"]);
      continue;
    }
    
    /* turn teams into accounts */
    participants = [_ctx runCommand:@"team::expand",
                           @"object", participants,
                           @"returnSet", nYes, nil];
    
    if ([participants intersectsSet:self->accounts])
      [filtered addObject:appointment];
  }

  if ([filtered count] != count) {
    return AUTORELEASE(filtered);
  }
  else {
    RELEASE(filtered); filtered = nil;
    return _dates;
  }
}

- (EOSQLQualifier *)_buildQualifierInContext:(id)_ctx {
  EOAdaptor      *adaptor;
  EOAttribute    *dateAttr;
  EOSQLQualifier *result;
  EOEntity       *entity;

  entity   = [self entity];
  adaptor  = [self databaseAdaptor];
  dateAttr = [entity attributeNamed:@"startDate"];
  
  result = [EOSQLQualifier allocWithZone:[self zone]];
  if (self->time == nil) {
    result = [result initWithEntity:entity
                     qualifierFormat:@"(%@ BETWEEN %@ AND %@)",
                       [adaptor formatAttribute:dateAttr],
                       [adaptor formatValue:[self->day beginOfDay]
                                forAttribute:dateAttr],
                       [adaptor formatValue:[self->day endOfDay]
                                forAttribute:dateAttr]];
  }
  else {
    NSCalendarDate *aDate  = nil;
    NSString       *dayRep = nil;
    
    dayRep = [self->day descriptionWithCalendarFormat:@"%Y.%m.%d "];
    dayRep = [dayRep stringByAppendingString:self->time];
    
    aDate  = [NSCalendarDate dateWithString:dayRep
                             calendarFormat:@"%Y.%m.%d %H:%M"];
    
    result = [result initWithEntity: entity
                     qualifierFormat:@"(%@ = %@)",
                       [adaptor formatAttribute:dateAttr],
                       [adaptor formatValue:aDate forAttribute:dateAttr]];
  }

  if (self->title != nil) {
    EOAttribute *titleAttr = nil;
    EOSQLQualifier *titleQua  = nil;
    
    titleAttr = [entity attributeNamed:@"title"];
    titleQua  = [EOSQLQualifier allocWithZone:[self zone]];
    titleQua = [titleQua initWithEntity:entity
                         qualifierFormat:@"%@ = %@",
                         [adaptor formatAttribute:titleAttr],
                         [adaptor formatValue:self->title
                                  forAttribute:titleAttr]];
    [result conjoinWithQualifier:titleQua];
  }
  [result setUsesDistinct:YES];
  return AUTORELEASE(result);
}

- (void)_executeInContext:(id)_context {
  id             appointment = nil;
  EOSQLQualifier *q          = nil;
  NSArray        *fetchOrder = nil;
  NSMutableArray *results    = nil;
  NSArray        *filtered;

  [self assert:[self->accounts count] > 0
        reason:@"selected team has no members or user is not logged in."];

  /* construct qualifier */
  
  q  = [self _buildQualifierInContext:_context];

  /* perform fetch */
  
  fetchOrder = [NSArray arrayWithObject:
    [EOAttributeOrdering attributeOrderingWithAttribute:
                           [[self entity] attributeNamed:@"startDate"]
                         ordering:EOAscendingOrder]];
  
  [self assert:[[self databaseChannel] selectObjectsDescribedByQualifier:q
                                       fetchOrder:fetchOrder]];

  results = [[NSMutableArray allocWithZone:[self zone]] initWithCapacity:32];
  while ((appointment = [[self databaseChannel] fetchWithZone:NULL])) {
    [results addObject:appointment];
    
    if (self->timeZone) {
      [[appointment valueForKey:@"startDate"] setTimeZone:self->timeZone];
      [[appointment valueForKey:@"endDate"]   setTimeZone:self->timeZone];
      [[appointment valueForKey:@"cycleDate"] setTimeZone:self->timeZone];
    }
    appointment = nil;
  }
  
  /* fetch participants */
  
  LSRunCommandV(_context, @"appointment", @"get-participants",
                @"appointments", results, nil);

  /* filter appointments where the participant set intersects the account set */
  
  filtered = [self _filterAppointments:results context:_context];
  
  if (filtered != results) {
    ASSIGN(results, filtered);
  }
  
  /* fetch comments */
  
  LSRunCommandV(_context, @"appointment", @"get-comments",
                @"objects", results, nil);
  
  /* fetch owners */
  
  if (self->fetchOwners) {
    [self logWithFormat:@"ERROR(%s): fetching owners is not implemented!",
	  __PRETTY_FUNCTION__];
  }
  
  /* determine access info */

  LSRunCommandV(_context, @"appointment", @"get-access-team-info",
                @"appointments", results, nil);
  
  /* return result */
  
  [self setReturnValue:results];
  [results release]; results    = nil;

  [self->accounts removeAllObjects];
}

/* record initializer */

- (NSString *)entityName {
  return @"Date";
}

/* accessors */

- (void)setDayFromString:(NSString *)_string {
  NSCalendarDate *myDate = nil;
  
  _string = [_string stringByAppendingString:@" 12:00:00"];
  myDate = [NSCalendarDate dateWithString:_string
                           calendarFormat:@"%Y-%m-%d %H:%M:%S"];
  [self setDay:myDate];
}

- (void)setDay:(NSCalendarDate *)_day {
  NSAssert1([_day isKindOfClass:[NSCalendarDate class]],
            @"invalid parameter %@ ..", _day);
  ASSIGNCOPY(self->day, _day);
}
- (NSCalendarDate *)day {
  return self->day;
}

- (void)setFetchOwners:(BOOL)_flag {
  self->fetchOwners = _flag;
}
- (BOOL)fetchOwners {
  return self->fetchOwners;
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

- (void)setTime:(id)_time {
  ASSIGNCOPY(self->time, _time);
}
- (id)time {
  return self->time;
}

- (void)setTitle:(id)_title {
  ASSIGNCOPY(self->title, _title);
}
- (id)title {
  return self->title;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"day"]) {
    if ([_value isKindOfClass:[NSCalendarDate class]])
      [self setDay:_value];
    else
      [self setDayFromString:[_value stringValue]];      
  }
  else if ([_key isEqualToString:@"time"])
    [self setTime:_value];
  else if ([_key isEqualToString:@"title"])
    [self setTitle:_value];
  else if ([_key isEqualToString:@"team"])
    [self setTeam:_value];
  else if ([_key isEqualToString:@"fetchOwners"])
    [self setFetchOwners:[_value boolValue]];
  else if ([_key isEqualToString:@"withoutPrivate"])
    [self setWithoutPrivate:[_value boolValue]];
  else if ([_key isEqualToString:@"timeZone"])
    [self setTimeZone:_value];
  else
    [super takeValue:_value forKey:_key];

  return;
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"day"])
    return [self day];
  if ([_key isEqualToString:@"team"])
    return [self team];
  if ([_key isEqualToString:@"fetchOwners"])
    return [NSNumber numberWithBool:[self fetchOwners]];
  if ([_key isEqualToString:@"timeZone"])
    return [self timeZone];
  if ([_key isEqualToString:@"withoutPrivate"])
    return [NSNumber numberWithBool:[self withoutPrivate]];
  
  return [super valueForKey:_key];
}

@end /* LSGetDateForADayCommand */
