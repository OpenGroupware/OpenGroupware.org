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

#include "LSAppointment+Filters.h"
#include "common.h"

@implementation NSObject(LSAppointmentFilters)

- (BOOL)filterOutAttendanceWithSpec:(id)_ctx {
  if (![[_ctx valueForKey:@"withAttendance"] boolValue] &&
      [[self valueForKey:@"isAttendance"] boolValue])
    return NO;

  return YES;
}

- (BOOL)filterOutAbsenceWithSpec:(id)_ctx {
  if (![[_ctx valueForKey:@"withAbsence"] boolValue] &&
      [[self valueForKey:@"isAbsence"] boolValue])
    return NO;
  
  return YES;
}

- (BOOL)filterOutSeveralDaysWithSpec:(id)_ctx {
  NSTimeInterval interval;
  
  interval = [[self valueForKey:@"endDate"]
                    timeIntervalSinceDate:[self valueForKey:@"startDate"]];
  
  if (![[_ctx valueForKey:@"withSeveralDays"] boolValue] && (interval > 86400.0))
    return NO;
  
  return YES;
}

- (BOOL)filterAbsenceWithSpec:(id)_ctx {
  if ([[self valueForKey:@"isAttendance"] boolValue])
    return NO;
  if ([[self valueForKey:@"isAbsence"] boolValue])
    return YES;
  return NO;
}

- (BOOL)filterAttendanceWithSpec:(id)_ctx {
  return [[self valueForKey:@"isAttendance"] boolValue] ? YES : NO;
}

- (BOOL)filterSeveralDaysWithSpec:(id)_ctx {
  NSTimeInterval interval;
  
  interval = [[self valueForKey:@"endDate"]
                    timeIntervalSinceDate:[self valueForKey:@"startDate"]];

  return interval > 86400 ? YES : NO;
}

@end

@implementation NSObject(WeekDaysFiltersImp)

- (BOOL)filterWeekDayWithSpec:(id)_ctx {
  NSCalendarDate *startDate, *tmpDate;
  int            startWeekDay;

  if (![self filterOutAttendanceWithSpec:_ctx])
    return NO;
  
  if (![self filterOutAbsenceWithSpec:_ctx])
    return NO;

  if (![self filterOutSeveralDaysWithSpec:_ctx])
    return NO;
  
  startDate    = [self valueForKey:@"startDate"];
  tmpDate      = startDate;
  startWeekDay = [startDate dayOfWeek]; 
  
  if (startWeekDay == 0) {
    startWeekDay = 7;
    tmpDate      = [startDate yesterday];
  }

  if (![tmpDate isDateInSameWeek:[_ctx valueForKey:@"mondayOfWeek"]])
    return NO;
    
  if (startWeekDay != [[_ctx valueForKey:@"weekDay"] intValue])
    return NO;
  
  return YES;
}

@end
