/*
  Copyright (C) 2000-2003 SKYRIX Software AG

  This file is part of OGo

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

#include "SkyAptAction.h"
#import <Foundation/Foundation.h>

#include "SkyAppointmentResourceCache.h"
#include <LSFoundation/LSFoundation.h>
#include <EOControl/EOKeyGlobalID.h>

@implementation SkyAptAction(InputParsing)

/*" extract array of participants out of array of id, url , login or
    team description. returns nil on empty array, or array with current
    login if argument is nil "*/
- (NSArray *)_extractParticipants:(NSArray *)_participants {
  // might be id, url, login or team description
  int            max;
  NSMutableArray *ma;
  NSMutableArray *pa;
  int            i, k;
  id             one;
  id             ctx = [self commandContext];
  id             dm  = [ctx documentManager];
  id             gid;

  if (_participants == nil) {
    // default: active account
    return [NSArray arrayWithObject:[ctx valueForKey:LSAccountKey]];
  }
  if (![_participants isKindOfClass:[NSArray class]])
    _participants = [NSArray arrayWithObject:_participants];
  max = [_participants count];

  if (max == 0) {
    // empty participants array
    // --> not valid
    return nil;
  }
  
  ma  = [NSMutableArray arrayWithCapacity:max];
  pa  = [NSMutableArray arrayWithCapacity:max];

  for (i = 0; i < max; i++) {
    gid = nil;
    one = [_participants objectAtIndex:i];
    
    if ([one isKindOfClass:[NSNumber class]]) {
      [self _ensureCurrentTransactionIsCommitted];
      gid = [dm globalIDForURL:one];
    } 
    else if ((k = [one intValue]) > 9999) {
      [self _ensureCurrentTransactionIsCommitted];
      gid = [dm globalIDForURL:[NSNumber numberWithInt:k]];
    }
    else if ([(NSString *)one hasPrefix:@"skyrix://"]) {
      [self _ensureCurrentTransactionIsCommitted];
      gid = [dm globalIDForURL:one];
    }
    if (gid != nil)
      [ma addObject:gid];
    else {
      id tmp;
      [self _ensureCurrentTransactionIsCommitted];
      // might still be login
      tmp = [ctx runCommand:@"account::get-by-login",
                 @"login", one,
                 @"suppressAdditionalInfos",
                 [NSNumber numberWithBool:YES],
                 nil];
      if (tmp != nil) [pa addObject:tmp];
      else {
        // team ??
        [self _ensureCurrentTransactionIsCommitted];
        tmp = [ctx runCommand:@"team::get-by-login",
                   @"login", one,
                   nil];
        if (tmp != nil) [pa addObject:tmp];
        else {
          NSLog(@"WARNING[%s]: unknown participant: %@",
                __PRETTY_FUNCTION__, one);
        }
      }
    }
  }

  [self _ensureCurrentTransactionIsCommitted];
  if ([ma count]) {
    ma = [ctx runCommand:@"staff::get-by-globalid",
              @"gids",       ma,
              @"attributes", [NSArray arrayWithObjects:@"companyId",
                                      @"globalID", @"isTeam", @"isAccount",
                                      nil],
              nil];
    [pa addObjectsFromArray:ma];
  }
  return ([pa count] > 0) ? pa : nil;
}

/*" extract array of resources out of array of resources :-)
    argument may also be a string with resourcenames separated
    by ',' or ', ' "*/
- (NSArray *)_extractResources:(id)_resources {
  NSArray *resources = _resources;
  if (_resources == nil) return [NSArray array];
  if (![_resources isKindOfClass:[NSArray class]]) {
    // may be string
    if (![_resources isKindOfClass:[NSString class]])
      return nil;

    // if , in string its a list of resources
    if ([_resources indexOfString:@", "] != NSNotFound) {
      resources = [_resources componentsSeparatedByString:@", "];
    }
    else if ([_resources indexOfString:@","] != NSNotFound) {
      resources = [_resources componentsSeparatedByString:@","];
    }
    // or only one resource
    else if ([_resources length])
      resources = [NSArray arrayWithObject:_resources];
    else
      return [NSArray array];
  }
  {
    SkyAppointmentResourceCache *cache;
    NSArray        *all;
    NSEnumerator   *e;
    id             ctx, one;
    NSMutableArray *ma = [NSMutableArray arrayWithCapacity:[resources count]];

    ctx   = [self commandContext];
    cache = [SkyAppointmentResourceCache cacheWithCommandContext:ctx];
    all   = [[cache allObjectsWithContext:ctx] valueForKey:@"name"];
    e     = [resources objectEnumerator];

    while ((one = [e nextObject])) {
      if ([all containsObject:one]) [ma addObject:one];
      else {
        NSLog(@"%s unknown resource name: %@", __PRETTY_FUNCTION__, one);
#if 0
        return nil;
#endif
      }
    }
    resources = [ma copy];
    AUTORELEASE(resources);
  }
  return resources;
}
- (NSArray *)_extractResourceCategories:(id)_categories {
  if (_categories == nil) return [NSArray array];
  if (![_categories isKindOfClass:[NSArray class]]) {
    if (![_categories isKindOfClass:[NSString class]])
      return nil;
    if ([_categories indexOfString:@", "] != NSNotFound)
      _categories = [_categories componentsSeparatedByString:@", "];
    else if ([_categories indexOfString:@","] != NSNotFound)
      _categories = [_categories componentsSeparatedByString:@","];
    else if ([_categories length])
      _categories = [NSArray arrayWithObject:_categories];
    else
      return [NSArray array];
  }
  if ([_categories count]) {
    SkyAppointmentResourceCache *cache;
    NSArray        *all;
    NSEnumerator   *e;
    id             ctx, one;
    NSMutableArray *ma =
      [NSMutableArray arrayWithCapacity:[_categories count]];

    ctx   = [self commandContext];
    cache = [SkyAppointmentResourceCache cacheWithCommandContext:ctx];
    all   = [cache allCategoriesWithContext:ctx];
    e     = [_categories objectEnumerator];

    while ((one = [e nextObject])) {
      if ([all containsObject:one]) [ma addObject:one];
      else {
        NSLog(@"%s unknown resource category: %@", __PRETTY_FUNCTION__, one);
#if 0
        return nil;
#endif
      }
    }
    _categories = [ma copy];
    AUTORELEASE(_categories);
  }
  return _categories;
}

- (NSCalendarDate *)_extractDate:(id)_val
                     defaultDate:(NSCalendarDate *)_dDate
                     defaultHour:(int)_dHour
                   defaultMinute:(int)_dMin
                   defaultSecond:(int)_dSec
{
  NSCalendarDate *date = nil;
  if (_val == nil) { // nil --> default date
    if (_dDate == nil) return nil;
    date = _dDate;
    date = [NSCalendarDate dateWithYear:[date yearOfCommonEra]
                           month:[date monthOfYear]
                           day:[date dayOfMonth]
                           hour:_dHour
                           minute:_dMin
                           second:_dSec
                           timeZone:[self timeZone]];
    return date;
  }
  if ([_val isKindOfClass:[NSCalendarDate class]]) {
    [_val setTimeZone:[self timeZone]];
    return _val;
  }

  if ([_val isKindOfClass:[NSString class]]) {
    date = [NSCalendarDate dateWithString:_val
                           calendarFormat:@"%Y-%m-%d %H:%M:%S %Z"];

    if (date == nil) {
      date = [NSCalendarDate dateWithString:_val
                             calendarFormat:@"%Y-%m-%d %H:%M:%S"];
      [date setTimeZone:[self timeZone]];
    }

    if (date == nil) {
      date = [NSCalendarDate dateWithString:_val
                             calendarFormat:@"%Y-%m-%d %H:%M"];
      [date setTimeZone:[self timeZone]];
    }
    if (date == nil) {
      date = [NSCalendarDate dateWithString:_val
                             calendarFormat:@"%Y-%m-%d"];
      if (date) {
        date = [NSCalendarDate dateWithYear:[date yearOfCommonEra]
                               month:[date monthOfYear]
                               day:[date dayOfMonth]
                               hour:_dHour
                               minute:_dMin
                               second:_dSec
                               timeZone:[self timeZone]];
      }
    }
    if (date != nil) 
      return date;

    date = [NSCalendarDate dateWithString:_val
                           calendarFormat:@"%H:%M:%S"];
    if (date == nil)
      date = [NSCalendarDate dateWithString:_val
                             calendarFormat:@"%H:%M"];
    if (date != nil) {
      NSCalendarDate *now = _dDate;
      if (now == nil) return nil;
      date = [NSCalendarDate dateWithYear:[now yearOfCommonEra]
                             month:[now monthOfYear]
                             day:[now dayOfMonth]
                             hour:[date hourOfDay]
                             minute:[date minuteOfHour]
                             second:[date secondOfMinute]
                             timeZone:[self timeZone]];
      return date;
    }
  }
  return nil;
}
- (NSCalendarDate *)_extractDate:(id)_val {
  return [self _extractDate:_val defaultDate:[NSCalendarDate date]
               defaultHour:11 defaultMinute:0 defaultSecond:0];
}

- (NSNumber *)_extractNotify:(id)_notify {
  int factor, value;

  factor = 1;
  
  if ([_notify isKindOfClass:[NSNumber class]]) {
    if ([_notify intValue] < 1) return nil;
    return _notify;
  }

  if (![_notify isKindOfClass:[NSString class]]) {
    return nil;
  }

  value = [_notify intValue];

  if (value < 1) return nil;

  if (([_notify hasSuffix:@"m"]) || ([_notify hasSuffix:@" minute"]) ||
      ([_notify hasSuffix:@" minutes"]) || ([_notify hasSuffix:@" min"]))
    factor = 1;
  else if (([_notify hasSuffix:@"h"]) || ([_notify hasSuffix:@" hour"]) ||
           ([_notify hasSuffix:@" hours"]))
    factor = 60;
  else if (([_notify hasSuffix:@"d"]) || ([_notify hasSuffix:@" day"]) ||
           ([_notify hasSuffix:@" days"]))
    factor = 1440;
  else if (([_notify hasSuffix:@"w"]) || ([_notify hasSuffix:@" week"]) ||
           ([_notify hasSuffix:@" weeks"]))
    factor = 10080;

  return [NSNumber numberWithInt:factor*value];
}

- (NSNumber *)_extractAccessTeamId:(id)_accessTeam {
  int t;
  if (_accessTeam == nil) return nil;
  if ([_accessTeam isKindOfClass:[NSNumber class]])
    return _accessTeam;
  if (![_accessTeam isKindOfClass:[NSString class]])
    return nil;
  if ((t = [_accessTeam intValue]) > 9999)
    return [NSNumber numberWithInt:t];

  if ([(NSString *)_accessTeam hasPrefix:@"skyrix://"]) {
    id dm  = [[self commandContext] documentManager];
    id gid;
    [self _ensureCurrentTransactionIsCommitted];
    gid = [dm globalIDForURL:_accessTeam];
    if (gid != nil) {
      if (![[gid entityName] isEqualToString:@"Team"]) return nil;
      return [gid keyValues][0];
    }
  }
  [self _ensureCurrentTransactionIsCommitted];
  // maybe team name
  _accessTeam = [[self commandContext] runCommand:@"team::get-by-login",
                                       @"login", _accessTeam,
                                       nil];
  return [_accessTeam valueForKey:@"companyId"];
}

- (NSArray *)_validAptTypes {
  static NSArray *aptTypes = nil;
  if (aptTypes == nil) {
   aptTypes =
     [[[self commandContext] userDefaults]
             objectForKey:@"SkyScheduler_defaultAppointmentTypes"];
   if (aptTypes == nil) aptTypes = [NSArray array];
   {
     NSArray *custom;
     custom = [[[self commandContext] userDefaults]
                      objectForKey:@"SkyScheduler_customAppointmentTypes"];
     if (custom != nil)
       aptTypes = [aptTypes arrayByAddingObjectsFromArray:custom];
   }
   RETAIN(aptTypes);
  }
  return aptTypes;
}
- (NSArray *)_validAptTypeNames {
  static NSArray *aptTypeNames = nil;
  if (aptTypeNames == nil) {
    aptTypeNames = [[self _validAptTypes] valueForKey:@"type"];
    RETAIN(aptTypeNames);
  }
  return aptTypeNames;
}
#if 0
- (NSString *)_checkAptType:(NSString *)_aptType {
  if (_aptType == nil) return nil;
  if (![_aptType isKindOfClass:[NSString class]]) return nil;
  if (![[self _validAptTypeNames] containsObject:_aptType]) return nil;
  return _aptType;
}
#endif

- (NSString *)_checkRepetitionType:(NSString *)_repType {
  static NSArray *validRepTypes = nil;
  if (validRepTypes == nil) {
    validRepTypes = [NSArray arrayWithObjects:
                             @"daily",   @"weekly", @"monthly",
                             @"weekday", @"14_daily", @"4_weekly",
                             @"yearly", nil];
    RETAIN(validRepTypes);
  }
  if ([validRepTypes containsObject:_repType]) return _repType;
  return nil;
}

- (BOOL)_extractTimeDistance:(NSNumber *)_amount
                        unit:(NSString *)_unit
                       years:(int *)_years
                      months:(int *)_months
                        days:(int *)_days
                       hours:(int *)_hours
                     minutes:(int *)_minutes
                     seconds:(int *)_seconds
{
  int amount;

  *_years   = 0;
  *_months  = 0;
  *_days    = 0;
  *_hours   = 0;
  *_minutes = 0;
  *_seconds = 0;
  
  if (_amount == nil) {
    [self invalidArgument:@"amount"];
    return NO;
  }
  if ((![_amount isKindOfClass:[NSNumber class]]) &&
      (![_amount isKindOfClass:[NSString class]])) {
    [self invalidArgument:@"amount"];
    return NO;
  }

  amount = [_amount intValue];
  if (_unit == nil) {
    // default: minutes
    *_minutes = amount;
    return YES;
  }
  if (![_unit isKindOfClass:[NSString class]]) {
    [self invalidArgument:@"unit"];
    return NO;
  }

  if (([_unit isEqualToString:@"second"]) ||
      ([_unit isEqualToString:@"seconds"]) ||
      ([_unit isEqualToString:@"s"])) {
    *_seconds = amount;
    return YES;
  }
  if (([_unit isEqualToString:@"minute"]) ||
      ([_unit isEqualToString:@"minutes"]) ||
      ([_unit isEqualToString:@"min"])) {
    *_minutes = amount;
    return YES;
  }
  if (([_unit isEqualToString:@"hour"]) ||
      ([_unit isEqualToString:@"hours"]) ||
      ([_unit isEqualToString:@"h"])) {
    *_hours = amount;
    return YES;
  }
  if (([_unit isEqualToString:@"day"]) ||
      ([_unit isEqualToString:@"days"]) ||
      ([_unit isEqualToString:@"d"])) {
    *_days = amount;
    return YES;
  }
  if (([_unit isEqualToString:@"week"]) ||
      ([_unit isEqualToString:@"weeks"]) ||
      ([_unit isEqualToString:@"w"])) {
    *_days = amount * 7;
    return YES;
  }
  if (([_unit isEqualToString:@"month"]) ||
      ([_unit isEqualToString:@"months"]) ||
      ([_unit isEqualToString:@"m"])) {
    *_months = amount;
    return YES;
  }
  if (([_unit isEqualToString:@"year"]) ||
      ([_unit isEqualToString:@"years"]) ||
      ([_unit isEqualToString:@"y"])) {
    *_years = amount;
    return YES;
  }
  [self invalidArgument:@"unit"];
  return NO;
}

- (NSArray *)_extractAptTypes:(NSArray *)_types {
  if (_types == nil) return [NSArray array];
  if (![_types isKindOfClass:[NSArray class]]) {
    if ([_types isKindOfClass:[NSString class]]) {
      return [NSArray arrayWithObject:_types];
    }
    return nil;
  }

  return _types;
}

@end /* SkyAptAction(InputParsing) */

