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

#include <LSFoundation/LSArrayFilterCommand.h>

@class NSNumber;

@interface LSFilterWeekDaysCommand : LSArrayFilterCommand
{
@private
  NSNumber *weekDay;
}

/* accessors */

- (void)setWeekDay:(NSNumber *)_weekDay;
- (NSNumber *)weekDay;

@end

#include "common.h"

@implementation LSFilterWeekDaysCommand

- (void)dealloc {
  [self->weekDay release];
  [super dealloc];
}

/* command methods */

- (BOOL)includeObjectInResult:(id)_object {
  NSCalendarDate *startDate;
  int            myWeekDay;
  
  startDate = [_object valueForKey:@"startDate"];
  myWeekDay  = [startDate dayOfWeek]; 
  
  return (myWeekDay == [[self weekDay] intValue]);
}

/* accessors */

- (void)setDateList:(NSArray *)_dateList {
  [self setObject:_dateList];
}
- (NSArray *)dateList {
  return [self object];
}

- (void)setWeekDay:(NSNumber *)_weekDay {
  ASSIGNCOPY(self->weekDay, _weekDay);
}
- (NSNumber *)weekDay {
  return self->weekDay;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"dateList"] || [_key isEqualToString:@"object"])
    [self setObject:_value];
  else  if ([_key isEqualToString:@"weekDay"])
    [self setWeekDay:_value];
  else 
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"dateList"] || [_key isEqualToString:@"object"])
    return [self object];
  else if ([_key isEqualToString:@"weekDay"])
    return [self weekDay];
  else 
    return [super valueForKey:_key];
}

@end /* LSFilterWeekDaysCommand */
