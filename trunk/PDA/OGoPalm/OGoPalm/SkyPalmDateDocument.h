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

#ifndef __SkyPalmDateDocument_H__
#define __SkyPalmDateDocument_H__

#include <OGoPalm/SkyPalmDocument.h>

#define REPEAT_TYPE_SINLGE 0
#define REPEAT_TYPE_DAILY  1
#define REPEAT_TYPE_WEEKLY 2
#define REPEAT_TYPE_MONTHLY_BY_WEEKDAY 3
#define REPEAT_TYPE_MONTHLY_BY_DATE    4
#define REPEAT_TYPE_YEARLY 5

@class SkyPalmDateDocumentCopy;

@interface SkyPalmDateDocument : SkyPalmDocument
{
  // record values
  int            alarmAdvanceTime;
  int            alarmAdvanceUnit;
  NSString       *description;
  NSCalendarDate *enddate;
  BOOL           isAlarmed;
  BOOL           isUntimed;
  NSString       *note;
  NSCalendarDate *repeatEnddate;
  int            repeatFrequency;
  int            repeatOn;
  int            repeatStartWeek;
  int            repeatType;
  NSCalendarDate *startdate;
  NSArray        *exceptions; // date exceptions
}

- (int)repeatType;
- (void)setRepeatType:(int)_type;

- (int)repeatFrequency;
- (void)setRepeatFrequency:(int)_freq;

- (int)repeatOn;
- (void)setRepeatOn:(int)_repeatOn;

- (int)repeatStartWeek;
- (void)setRepeatStartWeek:(int)_week;

- (int)alarmAdvanceUnit;
- (void)setAlarmAdvanceUnit:(int)_unit;

- (int)alarmAdvanceTime;
- (void)setAlarmAdvanceTime:(int)_time;

- (BOOL)isAlarmed;

- (BOOL)isUntimed;
- (void)setIsUntimed:(BOOL)_flag;

- (NSCalendarDate *)repeatEnddate;
- (void)setRepeatEnddate:(NSCalendarDate *)_enddate;

- (NSArray *)exceptions;
- (void)setExceptions:(NSArray *)_exceptions;

- (NSCalendarDate *)startdate;
- (void)setStartdate:(NSCalendarDate *)_date;

- (NSCalendarDate *)enddate;
- (void)setEnddate:(NSCalendarDate *)_date;

- (void)setDescription:(NSString *)_desc;

- (void)setNote:(NSString *)_note;
- (NSString *)note;

- (NSString *)_exceptions;
- (NSArray *)weekdays;

@end /* SkyPalmDateDocument */

// repeat support
@interface SkyPalmDateDocument(DateDocumentCopy)

- (NSArray *)repeatsBetween:(NSCalendarDate *)_start
                        and:(NSCalendarDate *)_end;
- (id)detachDate:(SkyPalmDateDocumentCopy *)_child;
- (id)repetitionAtIndex:(unsigned)_idx;

@end /* SkyPalmDateDocument(DateDocumentCopy) */

@interface SkyPalmDateDocument(SkySchedulerSupport)

- (NSString *)permissions;
- (BOOL)isViewAllowed;
- (NSCalendarDate *)startDate;
- (NSCalendarDate *)endDate;
- (NSString *)title;
- (NSNumber *)ownerId;
- (NSArray *)participants;

@end /* SkyPalmDateDocument(SkySchedulerSupport) */

@interface SkyPalmDateDocumentSelection: SkyPalmDocumentSelection
{}
@end /* SkyPalmDateDocumentSelection */

#endif /* __SkyPalmDateDocument_H__ */
