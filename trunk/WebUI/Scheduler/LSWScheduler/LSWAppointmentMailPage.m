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

#include <OGoFoundation/OGoObjectMailPage.h>

@interface LSWAppointmentMailPage : OGoObjectMailPage
@end

@interface LSWAppointmentHtmlMailPage : LSWAppointmentMailPage
@end

@interface LSWAppointmentTextMailPage : LSWAppointmentMailPage
@end

#include "common.h"

static int compareParticipants(id part1, id part2, void *context);

@implementation LSWAppointmentMailPage

+ (int)version {
  return [super version] + 0; // TODO: which version?
}

/* accessors */

- (NSString *)entityName {
  return @"Date";
}

- (NSString *)getCmdName {
  return @"appointment::get";
}

/* setting and patching object */

- (void)_ensureObjectOwner {
  NSNumber *ownerId;
  id       owner, obj;

  obj   = [self object];
  owner = nil;
  
  ownerId = [obj valueForKey:@"ownerId"];
  if ([ownerId isNotNull]) {
    owner = [self runCommand:@"account::get", @"companyId", ownerId, nil];
    if ([owner isKindOfClass:[NSArray class]])
      owner = [owner lastObject];
  }
  if (owner) 
    [obj takeValue:owner forKey:@"owner"];
}
- (void)_fixupDateValues {
  id             obj;
  NSTimeZone     *tz;
  NSCalendarDate *sD, *eD;

  obj   = [self object];
  
  tz = [[self session] timeZone];
  sD = [obj valueForKey:@"startDate"];
  eD = [obj valueForKey:@"endDate"];
  [sD setTimeZone:tz];
  [eD setTimeZone:tz];
}

- (void)setObject:(id)_object {
  [super setObject:_object];
  [self _ensureObjectOwner];
  [self _fixupDateValues];
}

/* more accessors */

- (NSString *)objectUrlKey {
  return [NSString stringWithFormat:
                     @"x/activate?oid=%@",
                     [[self object] valueForKey:@"dateId"]];
}

- (NSString *)stringValueForDateKey:(NSString *)_key {
  NSCalendarDate *date;
  NSString *tmp;
  id day;
  
  date = [[self object] valueForKey:_key];
  if (![date isNotNull])
    return @"";
  
  day  = [date descriptionWithCalendarFormat:@"%A"];
  day  = [[self labels] valueForKey:day];
  tmp  = [date descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M %Z"];

  return [NSString stringWithFormat:@"%@, %@", day, tmp];
}

- (NSString *)startDate {
  return [self stringValueForDateKey:@"startDate"];
}
- (NSString *)endDate {
  return [self stringValueForDateKey:@"endDate"];
}

- (BOOL)hasOldStartDate {
  id date;

  date = [[self object] valueForKey:@"oldStartDate"];
  return (date == nil) ? NO : YES;
}

- (NSString *)oldStartDate {
  return [self stringValueForDateKey:@"oldStartDate"];
}

- (NSArray *)expandedParticipantsForParticipants:(NSArray *)_parts {
  int i, cnt;
  id  staffSet;

  cnt      = [_parts count];
  staffSet = [NSMutableSet set];
        
  for (i = 0; i < cnt; i++) {
    NSArray *members;
    id staff;

    staff = [_parts objectAtIndex:i];
    
    if (![[staff valueForKey:@"isTeam"] boolValue]) {
      [staffSet addObject:staff]; 
      continue;
    }
    
    if ((members = [staff valueForKey:@"members"]) == nil) {
      [self runCommand:@"team::members", @"object", staff, nil];
      members = [staff valueForKey:@"members"];
    }
    if (members) [staffSet addObjectsFromArray:members];
  }
  staffSet = [staffSet allObjects];
  staffSet = [staffSet sortedArrayUsingFunction:compareParticipants
                       context:self];
  return staffSet;
}

- (NSString *)_getPersonName:(id)_person {
  NSMutableString *str;
  NSString *n, *f;

  if (_person == nil)
    return @"";

  str = [NSMutableString stringWithCapacity:64];    
  
  n = [_person valueForKey:@"name"];
  f = [_person valueForKey:@"firstname"];
  if (f != nil) {
    [str appendString:f];
    [str appendString:@" "];
  }
  if (n) [str appendString:n];
  return str;
}

- (NSString *)creator {
  id       creator;
  NSNumber *crId;

  if ((crId = [[self object] valueForKey:@"ownerId"]) == nil)
    return @"";
  
  creator = [[[self session]
                    runCommand:@"account::get", @"companyId", crId, nil]
                    lastObject];
  return [self _getPersonName:creator];
}

- (NSString *)participants {
  NSMutableString *str;
  id   tmp, parts, obj;
  BOOL isFirst;
  
  tmp     = [[self session] runCommand:@"appointment::get-participants",
                            @"appointment", [self object], nil];
  parts   = [[self expandedParticipantsForParticipants:tmp] objectEnumerator];
  str     = [NSMutableString stringWithCapacity:64];
  isFirst = YES;
  
  while ((obj = [parts nextObject])) {
    if (!isFirst)
      [str appendString:@", "];
    
    [str appendString:[self _getPersonName:obj]];
    isFirst = NO;
  }
  return str;
}

- (NSString *)comment {
  [[self session] runCommand:@"appointment::get-comment",
                  @"object", [self object],
                  @"relationKey", @"dateInfo", nil];
  return [[[self object] valueForKey:@"dateInfo"] valueForKey:@"comment"];
}

@end /* LSWAppointmentMailPage */

@implementation LSWAppointmentHtmlMailPage
@end /* LSWAppointmentHtmlMailPage */

@implementation LSWAppointmentTextMailPage
@end /* LSWAppointmentTextMailPage */

static int compareParticipants(id part1, id part2, void *context) {
  NSString *name1, *name2;
  
  name1 = [part1 valueForKey:@"name"];
  name2 = [part2 valueForKey:@"name"];

  if (name1 == nil)
    name1 = @"";

  if (name2 == nil)
    name2 = @"";

  return [name1 compare:name2];    
}
