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

#include <OGoFoundation/OGoContentPage.h>

/*
 *  SkyMonthBrowser
 *  Component to browse months
 *  Example:
 
     html:
      <#Browser>
        <#DayLabel />
      </#Browser>
      
     wod:
      Browser: SkyMonthBrowser {
        ...
        date = currentDate;
        ...
      }
      DayLabel: WOString {
        value = currentDate;
      }
 *
 *  Attributes:
       > year
       > month
       > months          (default: 1)
       > timeZone        (default: session.timeZone)
       > showTitle       (default: YES)
       > showWeekOfYear  (default: NO)

      <  date
      <  isInMonth
 
 *
 */

@class NSTimeZone, NSCalendarDate;

@interface SkyMonthBrowser : OGoContentPage
{
@protected
  // interface
  int        year;            // year of the first month
  int        month;           // number of the first month
  int        months;          // number of months (default: 1)
  NSTimeZone *timeZone;       // timeZone (default: sessions.timeZone)

  BOOL       showTitle;       // show month label (default: YES)
  BOOL       showWeekOfYear;  // show week of year label (default: NO)

  NSCalendarDate *date;
  BOOL       isInMonth;

  // intern
  int        monthOffset;
  int        dayOfWeek;
  int        weekOfYear;
}

@end

#include "common.h"
#include <OGoFoundation/OGoSession.h>
#include <OGoFoundation/WOComponent+config.h>

@interface SkyMonthBrowser(PrivateMethods)
- (void)setTimeZone:(NSTimeZone *)_tz;
@end

@implementation SkyMonthBrowser

static NSArray *fullMonthNames   = nil;
static NSArray *fullWeekdayNames = nil;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  fullMonthNames = 
    [[ud arrayForKey:@"OGoScheduler_MonthBrowser_FullMonths"] copy];
  fullWeekdayNames = 
    [[ud arrayForKey:@"OGoScheduler_MonthBrowser_FullWeekdays"] copy];
}

- (id)init {
  if ((self = [super init]) != nil) {
    NSCalendarDate *now;

    [self setTimeZone:[(id)[self session] timeZone]];
    now = [NSCalendarDate date];
    [now setTimeZone:self->timeZone];
    
    self->year   = [now yearOfCommonEra];
    self->month  = [now monthOfYear];
    self->months = 1;
    
    self->showTitle      = YES;
    self->showWeekOfYear = NO;
  }
  return self;
}

- (void)dealloc {
  [self->timeZone release];
  [self->date     release];
  [super dealloc];
}

/* component type */

- (BOOL)synchronizesVariablesWithBindings {
  return NO;
}

/* accessors */

- (void)setTimeZone:(NSTimeZone *)_tz {
  ASSIGN(self->timeZone,_tz);
}
- (NSTimeZone *)timeZone {
  return self->timeZone;
}

- (int)year {
  return self->year;
}
- (int)month {
  return self->month;
}
- (int)months { // number of months to display?
  return self->months;
}

- (BOOL)showTitle {
  return self->showTitle;
}
- (BOOL)showWeekOfYear {
  return self->showWeekOfYear;
}

// internal
- (void)setMonthOffset:(int)_offs {
  self->monthOffset = _offs;
}
- (int)monthOffset {
  return self->monthOffset;
}

// somehow the NGObjWeb cursor feature confuses the SkyMonthRepetition
// so this is here to leave cursor==component
- (void)setItem:(id)_item {
}
- (id)item {
  return nil;
}

- (void)setDayOfWeek:(int)_dow {
  self->dayOfWeek = _dow;
}
- (int)dayOfWeek {
  return self->dayOfWeek;
}

- (void)setWeekOfYear:(int)_woy {
  self->weekOfYear = _woy;
}
- (int)weekOfYear {
  return self->weekOfYear;
}

/* additional accessors */

- (NSArray *)monthsArray {
  NSMutableArray *ma;
  unsigned       cnt;
  
  ma = [NSMutableArray arrayWithCapacity:self->months];
  for (cnt = 0; cnt < self->months; cnt++)
    [ma addObject:[NSNumber numberWithInt:cnt]];
  return ma;
}

- (int)currentMonth {
  int m;
  
  for (m = self->monthOffset + self->month; m > 12; m -= 12)
    ;
  return m;
}
- (int)currentYear {
  int m;
  int div;
  
  for (m = self->monthOffset + self->month, div = 0; m > 12; div++, m -= 12)
    ;
  return (self->year + div);
}

- (void)setDate:(NSCalendarDate *)_date {
  ASSIGN(self->date,_date);
  [self setValue:_date forBinding:@"date"];
}
- (void)setIsInMonth:(BOOL)_flag {
  self->isInMonth = _flag;
  [self setValue:[NSNumber numberWithBool:_flag] forBinding:@"isInMonth"];
}

- (NSString *)monthLabel {
  NSString *l;
  
  l = [fullMonthNames objectAtIndex:([self currentMonth] - 1)];
  l = [[self labels] valueForKey:l];
  
  return [NSString stringWithFormat:@"%@ %04i", l, [self currentYear]];
}

- (NSString *)weekdayTitle {
  NSString *l;

  l = [fullWeekdayNames objectAtIndex:self->dayOfWeek];
  if (YES) // configuration possibility may come later (shortWeekdayTitles)
    l = l ? [@"short_" stringByAppendingString:l] : (NSString *)nil;
  return [[self labels] valueForKey:l];
}

- (NSString *)cellColor {
  id c;

  c = [self config]; // TODO: replace that with CSS!
  
  if (!self->isInMonth)
    return [c valueForKey:@"colors_noMonthDayCell"];
  
  if ([self->date isToday])
    return [c valueForKey:@"colors_todayCell"];
  
  return [c valueForKey:@"colors_dayCell"];
}

// building page
- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  id val = nil;
  
  if ((val = [self valueForBinding:@"year"]))
    self->year = [val intValue];
  if ((val = [self valueForBinding:@"month"]))
    self->month = [val intValue];
  if ((val = [self valueForBinding:@"months"]))
    self->months = [val intValue];
  if ((val = [self valueForBinding:@"timeZone"]))
    [self setTimeZone:val];
  if ((val = [self valueForBinding:@"showTitle"]))
    self->showTitle = [val boolValue];
  if ((val = [self valueForBinding:@"showWeekOfYear"]))
    self->showWeekOfYear = [val boolValue];

  [super appendToResponse:_response inContext:_ctx];
}

// directAction support

- (int)yearForViewWeek {
  int m = [self currentMonth];
  int w = self->weekOfYear;
  
  if ((m == 1) && (w > 50))
    return [self currentYear] - 1;
  if ((m == 12) && (w < 30))
    return [self currentYear] + 1;
  return [self currentYear];
}
- (int)monthForViewWeek {
  return [self currentMonth];
}
- (int)weekForViewWeek {
  return self->weekOfYear;
}

@end /* SkyMonthBrowser */
