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
#include "SkyAppointmentFormatter.h"

@class NSCalendarDate;

@interface SkyInlineWeekChart : SkyInlineAptDataSourceView
{
@protected
  int day;
  int hour;
  int maxInfoLength;

  NSCalendarDate *weekStart;

  /* transient */
  NSArray *hours;
  NSCalendarDate *aptStartDate; // non-retained (only for matrix processing)
  NSCalendarDate *aptEndDate;   // non-retained (only for matrix processing)
}

@end

#include <OGoFoundation/WOComponent+config.h>
#include <OGoFoundation/OGoSession.h>
#include <OGoFoundation/OGoNavigation.h>
#include <OGoFoundation/WOComponent+Commands.h>
#include <LSFoundation/LSCommandContext.h>
#import <NGObjWeb/NGObjWeb.h>
#import <NGExtensions/NGExtensions.h>
#import <Foundation/Foundation.h>

@implementation SkyInlineWeekChart

+ (int)version {
  return [super version] + 0;
}

- (id)init {
  if ((self = [super init])) {
    self->maxInfoLength =
      [[(id)[self session] userDefaults]
              integerForKey:@"scheduler_weekchart_maxaptinfolength"];
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->hours);
  RELEASE(self->weekStart);
  [super dealloc];
}
#endif

- (void)sleep {
  RELEASE(self->hours);       self->hours = nil;
  [super sleep];
}

/* accessors */

- (void)setAppointment:(id)_apt {
  if (self->appointment != _apt) {
    [super setAppointment:_apt];

    self->aptStartDate = [self->appointment valueForKey:@"startDate"];
    self->aptEndDate   = [self->appointment valueForKey:@"endDate"];
  }
}

- (void)setWeekStart:(NSCalendarDate *)_weekStart {
  ASSIGN(self->weekStart,_weekStart);
}
- (NSCalendarDate *)weekStart {
  return self->weekStart;
}

- (void)setDay:(int)_day {
  self->day = _day;
}
- (int)day {
  return self->day;
}
- (void)setHour:(int)_hour {
  self->hour = _hour;
}
- (int)hour {
  return self->hour;
}

- (NSString *)currentDayLabel {
  static NSString *days[] = {
    @"Monday", @"Tuesday", @"Wednesday",
    @"Thursday", @"Friday", @"Saturday",
    @"Sunday"
  };
  return [[self labels] valueForKey:days[[self day]]];
}
- (NSString *)currentTimeLabel {
  if ([self showAMPMDates]) {
    BOOL am;
    int h = self->hour / 2;
    am = (h > 11) ? NO : YES;
    h  = h % 12;
    if (!h) h = 12;
    return [NSString stringWithFormat:@"%02i:00 %@",
                     h, am ? @"AM" : @"PM"];
  }
  return [NSString stringWithFormat:@"%02i:00",
                     self->hour / 2];
}

- (NSCalendarDate *)dateOfDayWithMinutesOffset:(unsigned)_mins {
  NSCalendarDate *date;
  
  date = [self weekStart];
  date = [date hour:0 minute:0 second:0];
  date = [date dateByAddingYears:0 months:0 days:self->day
               hours:0 minutes:_mins seconds:0];
  return date;
}
- (NSCalendarDate *)currentStartDate {
  return [self dateOfDayWithMinutesOffset:(self->hour * 30)];
}
- (NSCalendarDate *)currentDayDate {
  return [self dateOfDayWithMinutesOffset:0];
}

- (NSTimeInterval)slotSize {
  return 1800.0; // half an hour in seconds
}

- (NSCalendarDate *)weekday {
  NSCalendarDate *date;

  date = [self weekStart];
  date = [date hour:0 minute:0 second:0];
  date = [date dateByAddingYears:0 months:0 days:self->day
               hours:0 minutes:0 seconds:0];
  return date;
}

/* matrix support */

- (NSArray *)hoursToShow {
  NSMutableArray *a;
  NSUserDefaults *ud;
  int i, start, end;
  
  if (self->hours != nil)
    return self->hours;

  ud = [(OGoSession *)[self session] userDefaults];
    
  start = [ud integerForKey:@"scheduler_weekchart_starthour"] * 2;
  end   = [ud integerForKey:@"scheduler_weekchart_endhour"]   * 2;
    
  if (end <= start)
    end = start + 2;
    
  a = [NSMutableArray arrayWithCapacity:24];

  for (i = start; i <= end; i++) {
    [a addObject:[NSNumber numberWithInt:i]];
  }
    
  self->hours = [a copy];
  return self->hours;
}

- (BOOL)isAppointmentInRow {
  /* optimization method, not required (reduced matrix scan passes) */
  int startMins, endMins;
  id item;
  unsigned mins, slotEnd;
  
  if ((item = self->appointment) == nil)
    return NO;
  
  if ([self->aptEndDate dayOfMonth] != [self->aptStartDate dayOfMonth])
    return YES;
  if ([self->aptEndDate monthOfYear] != [self->aptStartDate monthOfYear])
    return YES;
  if ([self->aptEndDate yearOfCommonEra]!=[self->aptStartDate yearOfCommonEra])
    return YES;
  
  mins = [self hour] * 30; // hour contains half-hours in reality
  slotEnd = mins + (unsigned)([self slotSize] / 60.0);
  
  startMins = [self->aptStartDate hourOfDay] * 60 +
              [self->aptStartDate minuteOfHour] - 1;
  endMins   = [self->aptEndDate   hourOfDay] * 60 +
              [self->aptEndDate   minuteOfHour] + 1;
  
  //NSLog(@"check row %d-%d, %d-%d ..", mins, slotEnd, startMins, endMins);
  
  if (startMins >= slotEnd)
    return NO;
  if (endMins < mins)
    return NO;

  return YES;
}
- (BOOL)isAppointmentInCell {
  /* is apt in position specified by 'day' and 'hour' */
  NSTimeInterval start, end;
  NSTimeInterval aptStart, aptEnd;
  id item;
  
  if ((item = self->appointment) == nil)
    return NO;

  start = [[self currentStartDate] timeIntervalSince1970];
  end   = start + [self slotSize] - 1;
  
  aptStart = [self->aptStartDate timeIntervalSince1970];
  aptEnd   = [self->aptEndDate   timeIntervalSince1970] - 2;
  
  if (aptStart >= end)
    return NO;
  if (aptEnd < start)
    return NO;
  
  return YES;
}

- (NSCalendarDate *)referenceDateForFormatter {
  return self->currentDate;
}

- (NSFormatter *)aptInfoFormatter {
  NSString *format;

  format = [NSString stringWithFormat:@"%%%dT", self->maxInfoLength];

  return [SkyAppointmentFormatter formatterWithFormat:format];
}

@end /* SkyInlineWeekChart */
