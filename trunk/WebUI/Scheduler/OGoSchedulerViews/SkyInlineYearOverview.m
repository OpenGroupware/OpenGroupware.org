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

#include "SkyInlineAptDataSourceView.h"

@class NSCalendarDate, NSTimeZone;

@interface SkyInlineYearOverview : SkyInlineAptDataSourceView
{
@protected
  int            year;
  NSTimeZone     *tz;
  // colors
  NSString       *todayCellColor;
  NSString       *monthDayCellColor;
  NSString       *noMonthDayCellColor;

  // transient
  NSCalendarDate *startDate;
  NSCalendarDate *endDate;
  int            month;
  int            weekOfYear;
  int            dayOfWeek;
  BOOL           isInMonth;
}

@end

#import <Foundation/Foundation.h>
#include <NGExtensions/NGExtensions.h>
#include <OGoFoundation/WOComponent+config.h>

@implementation SkyInlineYearOverview

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->todayCellColor);
  RELEASE(self->monthDayCellColor);
  RELEASE(self->noMonthDayCellColor);
  RELEASE(self->startDate);
  RELEASE(self->endDate);

  [super dealloc];
}
#endif

- (void)awake {
  NSString *color;
  
  [super awake];

  color = [[self config] valueForKey:@"colors_todayCell"];
  ASSIGN(self->todayCellColor,color);
  color = [[self config] valueForKey:@"colors_monthDayCell"];
  ASSIGN(self->monthDayCellColor,color);
  color = [[self config] valueForKey:@"colors_noMonthDayCell"];
  ASSIGN(self->noMonthDayCellColor,color);
}

// accessors

- (void)setYear:(int)_year {
  self->year = _year;
}
- (int)year {
  return self->year;
}

- (void)setTimeZone:(NSTimeZone *)_tz {
  ASSIGN(self->tz,_tz);
}
- (NSTimeZone *)timeZone {
  return self->tz;
}

- (void)setStartDate:(NSCalendarDate *)_startDate {
  ASSIGN(self->startDate,_startDate);
}
- (NSCalendarDate *)startDate {
  return self->startDate;
}

- (void)setEndDate:(NSCalendarDate *)_endDate {
  ASSIGN(self->endDate,_endDate);
}
- (NSCalendarDate *)endDate {
  return self->endDate;
}

- (void)setMonth:(int)_month {
  self->month = _month;
}
- (int)month {
  return self->month;
}

- (void)setWeekOfYear:(int)_week {
  self->weekOfYear = _week;
}
- (int)weekOfYear {
  return self->weekOfYear;
}

- (void)setDayOfWeek:(int)_day {
  self->dayOfWeek = _day;
}
- (int)dayOfWeek {
  return self->dayOfWeek;
}

- (void)setIsInMonth:(BOOL)_flag {
  self->isInMonth = _flag;
}
- (BOOL)isInMonth {
  return self->isInMonth;
}

// additional accessors

- (BOOL)isToday {
  return [self->startDate isToday];
}

- (BOOL)isCurrentWeek {
  NSCalendarDate *now;

  now = [NSCalendarDate calendarDate];
  [now setTimeZone:[self timeZone]];

  return (([now weekOfYear] == [self weekOfYear]) &&
          ([now yearOfCommonEra] == [self year])) ? YES : NO;
}

- (NSString *)colorOfWeekCell {
  if ([self isCurrentWeek])
    return [[self config] valueForKey:@"colors_currentWeekCell"];
  return [[self config] valueForKey:@"colors_weekCell"];
}

- (NSString *)colorOfDayCell {
  if (!self->isInMonth)
    return self->noMonthDayCellColor;
  if ([self->startDate isToday])
    return self->todayCellColor;
  return self->monthDayCellColor;
}

- (NSString *)weekdayString {
  NSArray *days =
    [NSArray arrayWithObjects:@"short_Sunday", @"short_Monday",
             @"short_Tuesday",@"short_Wednesday", @"short_Thursday",
             @"short_Friday", @"short_Saturday", nil];
  return [days objectAtIndex:self->dayOfWeek];
}

- (NSString *)monthString {
  NSArray *months =
    [NSArray arrayWithObjects:@"January", @"February", @"March", @"April",
             @"May", @"June", @"July", @"August", @"September",
             @"October", @"November", @"December", nil];
  return [months objectAtIndex:(self->month - 1)];
}

- (int)yearForViewWeek {
  if ((self->month == 1) && (self->weekOfYear > 50))
    return self->year - 1;
  if ((self->month == 12) && (self->weekOfYear < 30))
    return self->year + 1;
  return self->year;
}

// conditional

- (BOOL)includeTRStartTag {
  return (self->month % 4 == 1) ? YES : NO;
}

- (BOOL)includeTREndTag {
  return (self->month % 4 == 0) ? YES : NO;
}


@end
