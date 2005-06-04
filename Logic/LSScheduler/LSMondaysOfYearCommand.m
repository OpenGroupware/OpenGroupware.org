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

#include <LSFoundation/LSBaseCommand.h>

@class NSString, NSCalendarDate;

@interface LSMondaysOfYearCommand : LSBaseCommand
{
@private
  NSCalendarDate  *dateInYear;
}

/* accessors */

- (void)setDateInYearFromString:(NSString *)_dateInYearString;
- (void)setDateInYear:(NSCalendarDate *)_dateInYear;
- (NSCalendarDate *)dateInYear;

@end

#include "common.h"

@implementation LSMondaysOfYearCommand

- (void)dealloc {
  [self->dateInYear release];
  [super dealloc];
}

/* command methods */

- (void)_executeInContext:(id)_context {
  NSMutableArray *mondays;
  NSCalendarDate *silvester    = nil;
  NSCalendarDate *janFirst     = nil;
  NSCalendarDate *mondayOfWeek = nil;
  int            i, lastWeek, currentYear;

  mondays     = [[NSMutableArray alloc] init];
  currentYear = [self->dateInYear yearOfCommonEra];

  if ([self->dateInYear weekOfYear] == 53) {
    NSCalendarDate *nextJanFirst;

    nextJanFirst = [NSCalendarDate dateWithYear:currentYear+1
                                   month:1 day:1
                                   hour:0 minute:0 second:0
                                   timeZone:[self->dateInYear timeZone]];

    if ([nextJanFirst weekOfYear] == 1)
      currentYear++;
  }

  janFirst  = [NSCalendarDate dateWithYear:currentYear
                              month:1 day:1
                              hour:0 minute:0 second:0
                              timeZone:[self->dateInYear timeZone]];
  silvester = [NSCalendarDate dateWithYear:currentYear
                              month:12 day:31
                              hour:23 minute:59 second:59
                              timeZone:[self->dateInYear timeZone]];

  lastWeek = [silvester weekOfYear];

  if (lastWeek == 53) {
    NSCalendarDate *nextJanFirst = nil;

    nextJanFirst = [NSCalendarDate dateWithYear:currentYear+1
                                   month:1 day:1
                                   hour:0 minute:0 second:0
                                   timeZone:[self->dateInYear timeZone]];

    if ([nextJanFirst weekOfYear] == 1)
      lastWeek = 52;
  }
  
  if ([janFirst weekOfYear] != 1) {
    mondayOfWeek = [janFirst mondayOfWeek];
    mondayOfWeek = [mondayOfWeek dateByAddingYears:0 months:0 days:7
                                 hours:0 minutes:0 seconds:0];
  }
  else {
    mondayOfWeek = [janFirst mondayOfWeek];
  }

  for (i = 0; i < lastWeek; i++) {
    id tmp;
    
    if (i > 0) {
      mondayOfWeek = [mondayOfWeek dateByAddingYears:0 months:0 days:7
                                   hours:0 minutes:0 seconds:0];
    }
    
    tmp = [mondayOfWeek copy];
    [mondays addObject:tmp];
    [tmp release];
  }

  [self setReturnValue:mondays];
  [mondays release]; mondays = nil;
}  

/* accessors */

- (void)setDateInYearFromString:(NSString *)_dateInYearString {
  NSCalendarDate *myDate = nil;
  
  _dateInYearString = [_dateInYearString stringByAppendingString:
                                         @" 12:00:00"];
  myDate = [NSCalendarDate dateWithString:_dateInYearString
                           calendarFormat:@"%Y-%m-%d %H:%M:%S"];

  [self setDateInYear:myDate];
}

- (void)setDateInYear:(NSCalendarDate *)_dateInYear {
  ASSIGNCOPY(dateInYear, _dateInYear);
}
- (NSCalendarDate *)dateInYear {
  return dateInYear;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"dateInYear"]) {
    if ([_value isKindOfClass:[NSCalendarDate class]])
      [self setDateInYear:_value];
    else
      [self setDateInYearFromString:[_value stringValue]];      
    return;
  }
  
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"dateInYear"])
    return [self dateInYear];
  
  return [super valueForKey:_key];
}

@end /* LSMondaysOfYearCommand */
