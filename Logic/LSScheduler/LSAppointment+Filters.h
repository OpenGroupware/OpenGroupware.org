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

#ifndef __LSAppointment_Filters_H__
#define __LSAppointment_Filters_H__

#import <Foundation/NSObject.h>

/*
  A category for using filter commands with EOQualifiers.
*/

@interface NSObject(LSAppointmentFilters)

/* ----- common filters ----- */

/*
  if 'withAttendance' is not set in _ctx, filters out all objects with
  'isAttendance' set.
*/
- (BOOL)filterOutAttendanceWithSpec:(id)_ctx;

/*
  if 'withAbsence' is not set in _ctx, filters out all objects with
  'isAbsence' set.
*/
- (BOOL)filterOutAbsenceWithSpec:(id)_ctx;

/*
  if 'withSeveralDays' is not set in _ctx, filters out all objects where
  the duration from 'startDate' to 'endDate' is above one day.
*/
- (BOOL)filterOutSeveralDaysWithSpec:(id)_ctx;

/*
  filters all objects where 'isAbsence' is set and 'isAttendance' is not.
  No context properties are used.
*/
- (BOOL)filterAbsenceWithSpec:(id)_ctx;

/*
  filters all objects where 'isAttendance' is set.
  No context properties are used.
*/
- (BOOL)filterAttendanceWithSpec:(id)_ctx;

/*
  filters all objects which take longer than one day (or 86400 seconds ..)
*/
- (BOOL)filterSeveralDaysWithSpec:(id)_ctx;

@end

@interface NSObject(WeekDaysFilters)

/*
  filter's out all objects of the week specified
  by the 'mondayOfWeek' property in _ctx and of the day specified
  by the 'weekDay' property in _ctx.

  Prior it filters using:
    - filterOutAttendanceWithSpec:
    - filterOutAbsenceWithSpec:
    - filterOutSeveralDaysWithSpec:
*/
- (BOOL)filterWeekDayWithSpec:(id)_ctx;

/*
  filter's out all objects in 'PM'.
  
  Prior it filters using:
    - filterWeekDayWithSpec:
*/
- (BOOL)filterPMWeekDayWithSpec:(id)_ctx;

/*
  filter's out all objects in 'AM' of the week specified
  by the 'mondayOfWeek' property in _ctx.

  Prior it filters using:
    - filterOutAttendanceWithSpec:
    - filterOutAbsenceWithSpec:
    - filterOutSeveralDaysWithSpec:
*/
- (BOOL)filterAMWeekDayWithSpec:(id)_ctx;

@end

@interface NSObject(AppointmentFilterStaff)

/*
  filter's all objects which have at least one object common in it's
  'toDateCompanyAssignment' objects with the 'staffList' property in _ctx.
*/
- (BOOL)filterStaffWithSpec:(id)_ctx;

@end

#endif /* __LSAppointment_Filters_H__ */
