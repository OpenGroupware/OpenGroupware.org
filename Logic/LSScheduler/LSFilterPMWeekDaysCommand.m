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

@class NSNumber, NSCalendarDate;

@interface LSFilterPMWeekDaysCommand : LSArrayFilterCommand
{
@private
  NSNumber       *weekDay;
  NSCalendarDate *mondayOfWeek;
  BOOL           withSeveralDays;
  BOOL           withAbsence;
  BOOL           withAttendance;
}

- (void)setWeekDay:(NSNumber *)_weekDay;
- (NSNumber *)weekDay;

@end

#include "LSAppointment+Filters.h"
#include "common.h"

@implementation NSObject(PMWeekDaySelector)

- (BOOL)filterPMWeekDayWithSpec:(id)_ctx {
  if (![self filterWeekDayWithSpec:_ctx])
    return NO;
  
  if ([[self valueForKey:@"startDate"] hourOfDay] < 12)
    return NO;
  
  return YES;
}

@end /* NSObject(PMWeekDaySelector) */

@implementation LSFilterPMWeekDaysCommand

- (void)dealloc {
  [self->weekDay      release];
  [self->mondayOfWeek release];
  [super dealloc];
}

/* command methods */

- (BOOL)includeObjectInResult:(id)_object {
  return [_object filterPMWeekDayWithSpec:self];
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

- (void)setMondayOfWeek:(NSCalendarDate *)_monday {
  ASSIGNCOPY(self->mondayOfWeek, _monday);
}
- (NSCalendarDate *)mondayOfWeek {
  return self->mondayOfWeek;
}

- (void)setWithSeveralDays:(BOOL)_withSeveralDays {
  self->withSeveralDays = _withSeveralDays;
}
- (BOOL)withSeveralDays {
  return self->withSeveralDays;
}

- (void)setWithAbsence:(BOOL)_withAbsence {
  self->withAbsence = _withAbsence;
}
- (BOOL)withAbsence {
  return self->withAbsence;
}

- (void)setWithAttendance:(BOOL)_withAttendance {
  self->withAttendance = _withAttendance;
}
- (BOOL)withAttendance {
  return self->withAttendance;
}


/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"dateList"] || [_key isEqualToString:@"object"])
    [self setObject:_value];
  else  if ([_key isEqualToString:@"weekDay"])
    [self setWeekDay:_value];
  else  if ([_key isEqualToString:@"mondayOfWeek"])
    [self setMondayOfWeek:_value];
  else  if ([_key isEqualToString:@"withSeveralDays"])
    [self setWithSeveralDays:[_value boolValue]];
  else  if ([_key isEqualToString:@"withAbsence"])
    [self setWithAbsence:[_value boolValue]];
  else if ([_key isEqualToString:@"withAbsence"])
    [self setWithAttendance:[_value boolValue]];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"dateList"] || [_key isEqualToString:@"object"])
    return [self object];
  if ([_key isEqualToString:@"weekDay"])
    return [self weekDay];
  if ([_key isEqualToString:@"mondayOfWeek"])
    return [self mondayOfWeek];
  if ([_key isEqualToString:@"withSeveralDays"])
    return [NSNumber numberWithBool:self->withSeveralDays];
  if ([_key isEqualToString:@"withAbsence"])
    return [NSNumber numberWithBool:self->withAbsence];
  if ([_key isEqualToString:@"withAttendance"])
    return [NSNumber numberWithBool:self->withAttendance];
  return [super valueForKey:_key];
}

@end /* LSFilterPMWeekDaysCommand */
