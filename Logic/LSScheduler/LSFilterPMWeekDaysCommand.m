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

#import "common.h"
#include <LSFoundation/LSArrayFilterCommand.h>
#include "LSAppointment+Filters.h"

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

@implementation NSObject(PMWeekDaySelector)

- (BOOL)filterPMWeekDayWithSpec:(id)_ctx {
  if (![self filterWeekDayWithSpec:_ctx])
    return NO;
  
  if ([[self valueForKey:@"startDate"] hourOfDay] < 12)
    return NO;
  
  return YES;
}

@end

@implementation LSFilterPMWeekDaysCommand

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->weekDay);
  RELEASE(self->mondayOfWeek);
  [super dealloc];
}
#endif

// command methods

- (BOOL)includeObjectInResult:(id)_object {
  return [_object filterPMWeekDayWithSpec:self];
}

// accessors

- (void)setDateList:(NSArray *)_dateList {
  [self setObject:_dateList];
}
- (NSArray *)dateList {
  return [self object];
}

- (void)setWeekDay:(NSNumber *)_weekDay {
  ASSIGN(self->weekDay, _weekDay);
}
- (NSNumber *)weekDay {
  return self->weekDay;
}

- (void)setMondayOfWeek:(NSCalendarDate *)_monday {
  ASSIGN(self->mondayOfWeek, _monday);
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


// key/value coding

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"dateList"] || [_key isEqualToString:@"object"]) {
    [self setObject:_value];
    return;
  }
  else  if ([_key isEqualToString:@"weekDay"]) {
    [self setWeekDay:_value];
    return;
  }
  else  if ([_key isEqualToString:@"mondayOfWeek"]) {
    [self setMondayOfWeek:_value];
    return;
  }
  else  if ([_key isEqualToString:@"withSeveralDays"]) {
    [self setWithSeveralDays:[_value boolValue]];
    return;
  }
  else  if ([_key isEqualToString:@"withAbsence"]) {
    [self setWithAbsence:[_value boolValue]];
    return;
  }
  else if ([_key isEqualToString:@"withAbsence"]) {
    [self setWithAttendance:[_value boolValue]];
    return;
  }
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"dateList"] || [_key isEqualToString:@"object"])
    return [self object];
  else if ([_key isEqualToString:@"weekDay"])
    return [self weekDay];
  else if ([_key isEqualToString:@"mondayOfWeek"])
    return [self mondayOfWeek];
  else if ([_key isEqualToString:@"withSeveralDays"])
    return [NSNumber numberWithBool:self->withSeveralDays];
  else if ([_key isEqualToString:@"withAbsence"])
    return [NSNumber numberWithBool:self->withAbsence];
  else if ([_key isEqualToString:@"withAttendance"])
    return [NSNumber numberWithBool:self->withAttendance];
  return [super valueForKey:_key];
}

@end
