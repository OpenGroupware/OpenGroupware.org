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

#include "SkyInlineAptDataSourceView.h"
#include "SkyAppointmentFormatter.h"

@class NSCalendarDate, SkySchedulerPage;

@interface SkyInlineMonthOverview : SkyInlineAptDataSourceView
{
@protected
  int            year;
  int            month;

  id             dayDataSource;
  BOOL           isInMonth;
  // config
  int            maxInfoLength; // max. lenght of apt description
  int            maxAptCount;   // max. count of apts per day
  /* transient */
  int            dayOfWeek;
  int            weekOfYear;
  // intern
  NSString       *monthDayCellColor;
  NSString       *noMonthDayCellColor;
  NSString       *todayCellColor;
  NSArray        *appointments;
}

@end

#include <OGoScheduler/SkyAptDataSource.h>
#include <OGoFoundation/WOComponent+config.h>
#include <OGoFoundation/LSWSession.h>
#include <OGoFoundation/LSWNavigation.h>
#include <OGoFoundation/WOComponent+Commands.h>
#include <LSFoundation/LSCommandContext.h>
#include <NGExtensions/EOFilterDataSource.h>
#include <NGMime/NGMimeType.h>
#include "common.h"

@interface SkyInlineMonthOverview(PrivateMethods)
- (void)setMonthDayCellColor:(NSString *)_color;
- (void)setNoMonthDayCellColor:(NSString *)_color;
- (void)setTodayCellColor:(NSString *)_color;
- (EOQualifier*)dayQualifier;
@end

@implementation SkyInlineMonthOverview

+ (int)version {
  return [super version] + 0;
}

- (id)init {
  if ((self = [super init])) {
    self->maxAptCount =
      [[(id)[self session] userDefaults]
              integerForKey:@"scheduler_monthoverview_maxaptperday"];
    self->maxInfoLength =
      [[(id)[self session] userDefaults]
              integerForKey:@"scheduler_monthoverview_maxaptinfolength"];
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->dayDataSource);
  RELEASE(self->monthDayCellColor);
  RELEASE(self->noMonthDayCellColor);
  RELEASE(self->todayCellColor);
  RELEASE(self->appointments);
  [super dealloc];
}
#endif

- (void)awake {
  [super awake];
  [self setMonthDayCellColor:
        [[self config] valueForKey:@"colors_monthDayCell"]];
  [self setNoMonthDayCellColor:
        [[self config] valueForKey:@"colors_noMonthDayCell"]];
  [self setTodayCellColor:
        [[self config] valueForKey:@"colors_todayCell"]];
}

/* accessors */

- (void)setDataSource:(id)_ds {
  if (self->dataSource != _ds) {
    [super setDataSource:_ds];
    RELEASE(self->dayDataSource);
    //    self->dayDataSource =
    //      [[EOFilterDataSource alloc] initWithDataSource:_ds];
    self->dayDataSource =
      [[EOFilterDataSource alloc] initWithDataSource:[self cacheDataSource]];
    [self->dayDataSource setSortOrderings:[self sortOrderings]];
  }
}

- (id)dayDataSource {
  return self->dayDataSource;
}

- (void)setYear:(int)_year {
  self->year = _year;
}
- (int)year {
  return self->year;
}

- (void)setMonth:(int)_month {
  self->month = _month;
}
- (int)month {
  return self->month;
}

- (void)setIsInMonth:(BOOL)_flag {
  self->isInMonth = _flag;
}
- (BOOL)isInMonth {
  return self->isInMonth;
}

- (NSTimeZone *)timeZone {
  return [[self dataSource] timeZone];
}

- (void)setStartDate:(NSCalendarDate *)_startDate {
  [self setCurrentDate:_startDate];
  [self->dayDataSource setAuxiliaryQualifier:[self dayQualifier]];
}
- (NSCalendarDate *)startDate {
  return [self currentDate];
}

- (void)setDayOfWeek:(int)_day {
  self->dayOfWeek = _day;
}
- (int)dayOfWeek {
  return self->dayOfWeek;
}

- (void)setWeekOfYear:(int)_week {
  self->weekOfYear = _week;
}
- (int)weekOfYear {
  return self->weekOfYear;
}

- (void)setMonthDayCellColor:(NSString *)_color {
  ASSIGN(self->monthDayCellColor,_color);
}
- (NSString *)monthDayCellColor {
  return self->monthDayCellColor;
}

- (void)setNoMonthDayCellColor:(NSString *)_color {
  ASSIGN(self->noMonthDayCellColor,_color);
}
- (NSString *)noMonthDayCellColor {
  return self->noMonthDayCellColor;
}

- (void)setTodayCellColor:(NSString *)_color {
  ASSIGN(self->todayCellColor,_color);
}
- (NSString *)todayCellColor {
  return self->todayCellColor;
}

// additional accessors

- (BOOL)isToday {
  return [self->currentDate isToday];
}
- (BOOL)isCurrentWeek {
  NSCalendarDate *now;

  now = [NSCalendarDate calendarDate];
  //  [now setTimeZone:[[self dataSource] timeZone]];
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
  if ([self->currentDate isToday])
    return self->todayCellColor;
  return self->monthDayCellColor;
}

/* filter datasource support */

- (EOQualifier *)dayQualifier {
  EOQualifier *q;
  NSCalendarDate *s, *e;

  s = [[self currentDate] beginOfDay];
  e = [s dateByAddingYears:0 months:0 days:1];

  q = [EOQualifier qualifierWithQualifierFormat:
                   @"((startDate > %@ OR startDate = %@)"
                   @" AND startDate < %@) OR (startDate < %@ AND endDate > %@)",
                   s, s, e, s, s];
  return q;
}

- (NSArray *)appointmentsForDay {
  RELEASE(self->appointments);
  self->appointments = [[self->dayDataSource fetchObjects] copy];

  return self->appointments;
}

- (NSString *)weekDayString {
  NSArray *days =
    [NSArray arrayWithObjects:@"Sunday", @"Monday", @"Tuesday",
             @"Wednesday", @"Thursday", @"Friday", @"Saturday", nil];
  return [days objectAtIndex:self->dayOfWeek];
}

- (int)yearForViewWeek {
  if ((self->month == 1) && (self->weekOfYear > 50))
    return self->year - 1;
  if ((self->month == 12) && (self->weekOfYear < 30))
    return self->year + 1;
  return self->year;
}

#if 0
- (NSString *)monthString {
  NSArray *months =
    [NSArray arrayWithObjects:@"January", @"February", @"March", @"April",
             @"May", @"June", @"July", @"August", @"September", @"October",
             @"November", @"December", nil];
  return [months objectAtIndex:(self->month - 1)];
}
#endif

- (NSString *)headerCellBGColor {
  return [[self config] valueForKey:@"colors_weekdayHeaderCell"];
}

// conditional

- (BOOL)hasDayApts {
  NSArray *apts;

  apts = self->appointments;

  return ((apts != nil) && ([apts count] > 0)) ? YES : NO;
}

- (BOOL)hasMoreThanMaxApts {
  return ([self->appointments count] > self->maxAptCount) ? YES : NO;
}

- (int)maxAptCount {
  return self->maxAptCount;
}

- (NSCalendarDate *)referenceDateForFormatter {
  return self->currentDate;
}

- (NSFormatter *)aptInfoFormatter {
  NSString *format;

  format = [NSString stringWithFormat:@"%%%dT", self->maxInfoLength];

  return [SkyAppointmentFormatter formatterWithFormat:format];
}

- (NSFormatter *)aptLongInfoFormatter {
  SkyAppointmentFormatter *f;
  f = [SkyAppointmentFormatter formatterWithFormat:@"%25T; %5P"];
  [f setShowFullNames:[self showFullNames]];
  return f;
}

/* actions */

- (id)personWasDropped:(id)_person {
  [self setCurrentDate:[[self currentDate] hour:11 minute:0 second:0]];
  
  return [super personWasDropped:_person];
}

// dnd support

- (NSCalendarDate *)droppedAptDateWithOldDate:(NSCalendarDate *)_date {
  NSCalendarDate *toDate = [self currentDate];
  return [NSCalendarDate dateWithYear:[toDate yearOfCommonEra]
                         month:[toDate monthOfYear]
                         day:[toDate dayOfMonth]
                         hour:[_date hourOfDay]
                         minute:[_date minuteOfHour]
                         second:[_date secondOfMinute]
                         timeZone:[_date timeZone]];
}

/* k/v coding */

- (void)takeValue:(id)_val forKey:(id)_key {
  if ([_key isEqualToString:@"month"])
    self->month = [_val intValue];
  else if ([_key isEqualToString:@"year"])
    self->year = [_val intValue];
  else
    [super takeValue:_val forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"month"])
   return [NSNumber numberWithInt:self->month];
  if ([_key isEqualToString:@"year"])
   return [NSNumber numberWithInt:self->year];
  
  return [super valueForKey:_key];
}

@end /* SkyInlineMonthOverview */
