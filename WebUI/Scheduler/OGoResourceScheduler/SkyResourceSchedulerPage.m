/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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
// $Id$

#include <OGoFoundation/LSWContentPage.h>

@class NSTimeZone, NSCalendarDate, NSNumber;
@class SkyHolidayCalculator;

@interface SkyResourceSchedulerPage : LSWContentPage
{
  NSTimeZone     *timeZone;
  id             dataSource;
  NSString       *selectedTab;
  /* week overview */
  NSCalendarDate *weekStart;
  NSString       *weekViewKey;
  /* month overview */
  int            month;
  int            year;
  /* day overview */
  NSCalendarDate *day;
  NSString       *dayViewKey;
  // holidays
  SkyHolidayCalculator *holidays;
}

- (void)setWeekStart:(NSCalendarDate *)_ws;
- (void)setDay:(NSCalendarDate *)_day;
- (void)setMonth:(int)_month;
- (void)setYear:(int)_year;
- (void)setSelectedTab:(NSString *)_tab;

@end

#include "common.h"
#include <OGoScheduler/SkyHolidayCalculator.h>
#include <OGoScheduler/SkyAptDataSource.h>

@interface NSObject(SkyResourceSchedulerPage_PRIVATE)
- (void)addResources:(id)_resources;
- (void)setParticipantsFromGids:(id)_gids;
@end

@implementation SkyResourceSchedulerPage

- (id)init {
  id p;

  /* this component is a session-singleton */
  if ((p = [self persistentInstance])) {
    [self release];
    return [p retain];
  }
  
  if ((self = [super init])) {
    [self registerAsPersistentInstance];

    self->timeZone = [[(id)[self session] timeZone] copy];
    {
      NSCalendarDate *d;
      d = [NSCalendarDate calendarDate];
      [self setDay:d];
    }
    [self setWeekStart:[self->day mondayOfWeek]];
    [self setSelectedTab:@"weekoverview"];
    [self takeValue:@"hchart" forKey:@"weekViewKey"];
    [self takeValue:@"hchart" forKey:@"dayViewKey"];
    
    self->dataSource = (SkyAptDataSource *)[[SkyAptDataSource alloc] init];
    [self->dataSource setContext:[(id)[self session] commandContext]];
    
    self->year  = [self->day yearOfCommonEra];
    self->month = [self->day monthOfYear];

    /* holiday calculator */
    {
      SkyHolidayCalculator *c;

      c = [SkyHolidayCalculator calculatorWithYear:self->year
                                timeZone:self->timeZone
                                userDefaults:
				  [(id)[self session] userDefaults]];
      ASSIGN(self->holidays,c);
    }
  }
  return self;
}

- (void)dealloc {
  [self->weekStart   release];
  [self->selectedTab release];
  [self->timeZone    release];
  [self->dataSource  release];
  [self->day         release];
  [self->holidays    release];
  [self->weekViewKey release];
  [self->dayViewKey  release];
  [super dealloc];
}

/* notifications */

- (void)sleep {
  [super sleep];
  [self setErrorString:nil];
}

- (void)noteChange:(NSString *)_cn onObject:(id)_object {
  [super noteChange:_cn onObject:_object];

  if ([_cn isEqualToString:LSWNewAppointmentNotificationName] ||
      [_cn isEqualToString:LSWUpdatedAppointmentNotificationName] ||
      [_cn isEqualToString:LSWDeletedAppointmentNotificationName]) {
    [self->dataSource clear];
  }
  else if ([_cn isEqualToString:LSWUpdatedAccountNotificationName] ||
           [_cn isEqualToString:LSWUpdatedAccountPreferenceNotificationName]) {
    [self->dataSource clear];
    [self->holidays setUserDefaults:[(id)[self session] userDefaults]];
  }
}

/* accessors */

- (void)setIsResCategorySelected:(BOOL)_flag {
  [self->dataSource setIsResCategorySelected:_flag];
}
- (BOOL)isResCategorySelected {
  return ([self->dataSource isResCategorySelected]
          && ([[self->dataSource  companies] count] == 0));
}
- (BOOL)isNotResCategorySelected {
  return ![self isResCategorySelected];
}

- (void)setDay:(NSCalendarDate *)_day {
  NSCalendarDate *d;

  d = [NSCalendarDate dateWithYear:[_day yearOfCommonEra]
                      month:[_day monthOfYear] day:[_day dayOfMonth]
                      hour:0 minute:0 second:0 timeZone:self->timeZone];
  ASSIGN(self->day, d);
}
- (NSCalendarDate *)day {
  return self->day;
}

- (void)setTimeZone:(NSTimeZone *)_tz {
  if (![self->timeZone isEqual:_tz]) {
    ASSIGN(self->timeZone, _tz);
    [self setDay:self->day];
  }
}
- (NSTimeZone *)timeZone {
  return self->timeZone;
}

- (void)setWeekStart:(NSCalendarDate *)_ws {
  if (![self->weekStart isEqualToDate:_ws]) {
    ASSIGN(self->weekStart,_ws);
  }
}
- (NSCalendarDate *)weekStart {
  return self->weekStart;
}

- (void)setSelectedTab:(NSString *)_tab {
  if (![_tab isEqualToString:self->selectedTab]) {
    ASSIGN(self->selectedTab, _tab);
    if ([self->selectedTab isEqualToString:@"weekoverview"]) {
      [self setMonth:[self->weekStart monthOfYear]];
      [self setYear:[self->weekStart yearOfCommonEra]];
    }
    if ([self->selectedTab isEqualToString:@"dayoverview"]) {
      [self setWeekStart:[self->day mondayOfWeek]];
      [self setMonth:[self->day monthOfYear]];
      [self setYear:[self->day yearOfCommonEra]];
    }
  }
}
- (NSString *)selectedTab {
  return self->selectedTab;
}

- (void)setWeekViewKey:(NSString *)_key {
  ASSIGN(self->weekViewKey,_key);
}
- (NSString *)weekViewKey {
  return self->weekViewKey;
}
- (void)setDayViewKey:(NSString *)_key {
  ASSIGN(self->dayViewKey,_key);
}
- (NSString *)dayViewKey {
  return self->dayViewKey;
}

- (NSString *)monthLabel {
  // TODO: this should probably be a formatter!
  if ([self->selectedTab isEqualToString:@"weekoverview"]) {
    id label  = nil;
    id month1 = nil;
    id month2 = nil;
    NSCalendarDate *ws, *we;

    ws = [self weekStart];
    we = [ws dateByAddingYears:0 months:0 days:6
             hours:23 minutes:0 seconds:0];
  
    if ([ws monthOfYear] == [we monthOfYear]) {
      // TODO: descriptionWithCalendarFormat is expensive
      month1 = [ws descriptionWithCalendarFormat: @"%B"];
      label = [NSString stringWithFormat:@"%@ %@",
                        [[self labels] valueForKey:month1],
                        [ws descriptionWithCalendarFormat: @"%Y"]];
    }
    else {
      // TODO: descriptionWithCalendarFormat is expensive
      month1 = [ws descriptionWithCalendarFormat: @"%B"];
      month2 = [we descriptionWithCalendarFormat: @"%B"];

      label = [NSString stringWithFormat:@"%@ %@ / %@ %@",
                        [[self labels] valueForKey:month1],
                        [ws descriptionWithCalendarFormat: @"%Y"],
                        [[self labels] valueForKey:month2],
                        [we descriptionWithCalendarFormat: @"%Y"]];
    }
    return label;
  }
  if ([self->selectedTab isEqualToString:@"monthoverview"]) {
    NSCalendarDate *m;
    NSString       *monthKey;
    NSString       *label;

    m = [NSCalendarDate dateWithYear:self->year month:self->month
                            day:1 hour:0 minute:0 second:0
                            timeZone:self->timeZone];
    
    // TODO: descriptionWithCalendarFormat is expensive
    monthKey = [m descriptionWithCalendarFormat:@"%B"];
    label    = [NSString stringWithFormat:@"%@ %@",
                         [[self labels] valueForKey:monthKey],
                         [m descriptionWithCalendarFormat:@"%Y"]];
    return label;
  }
  
  if ([self->selectedTab isEqualToString:@"yearoverview"]) {
    unsigned char buf[64];
    sprintf(buf, "%d", self->year);
    return [NSString stringWithCString:buf];
  }
  
  if ([self->selectedTab isEqualToString:@"dayoverview"]) {
    NSString *label;
    
    label =
      [[(LSWSession *)[self session] formatDate] 
	stringForObjectValue:self->day];
    return label;
  }
  return @"SkyScheduler 2";
}

- (NSString *)dayTabLabel {
  return [[(LSWSession *)[self session] formatDate]
                       stringForObjectValue:self->day];
}

- (NSString *)weekTabLabel {
  NSString *format = [[self labels] valueForKey:@"weekTabLabelFormat"];
  return [NSString stringWithFormat:format, [[self weekStart] weekOfYear]];
}
- (NSString *)monthTabLabel {
  static NSArray *months = nil;

  if (months == nil) {
    months = [[NSArray alloc] initWithObjects:
                              @"January", @"February", @"March",
                              @"April", @"May", @"June", @"July",
                              @"August", @"September", @"October",
                              @"November", @"December", nil];
  }
  if ((self->month > 12) || (self->month < 1))
    return @"";
  
  return [[self labels] valueForKey:[months objectAtIndex:(self->month-1)]];
}

/* month overview */

- (void)setMonth:(int)_month {
  self->month = _month;
}
- (int)month {
  return self->month;
}

- (void)setYear:(int)_year {
  self->year = _year;
}
- (int)year {
  return self->year;
}

/* holidays */

- (void)setHolidays:(SkyHolidayCalculator *)_holidays {
  ASSIGN(self->holidays,_holidays);
}
- (SkyHolidayCalculator *)holidays {
  return self->holidays;
}

/* fetchSpecification */

- (void)setFetchSpecification:(EOFetchSpecification *)_fspec {
  [self->dataSource setFetchSpecification:_fspec];
}

- (NSString *)monthIcon {
  return [NSString stringWithFormat:@"month%02d", self->month];
}

- (NSString *)weekIcon {
  return [NSString stringWithFormat:@"week%02d",
                   [[self weekStart] weekOfYear]];
}

- (NSString *)yearIcon {
  return ((self->year > 1995) && (self->year < 2016))
    ? [NSString stringWithFormat:@"year%04d", self->year]
    : @"year";
}

- (NSString *)dayIcon {
  return [NSString stringWithFormat:@"day%02d",
                   [[self day] dayOfMonth]];
}

- (id)dataSource {
  return self->dataSource;
}

/* actions */

- (id)switchToWeekOverview {
  [self takeValue:@"overview" forKey:@"weekViewKey"];
  return nil;
}
- (id)switchToWeekVChart {
  [self takeValue:@"vchart" forKey:@"weekViewKey"];
  return nil;
}
- (id)switchToWeekHChart {
  [self takeValue:@"hchart" forKey:@"weekViewKey"];
  return nil;
}
- (id)switchToDayOverview {
  [self takeValue:@"overview" forKey:@"dayViewKey"];
  return nil;
}
- (id)switchToDayVChart {
  [self takeValue:@"vchart" forKey:@"dayViewKey"];
  return nil;
}
- (id)switchToDayHChart {
  [self takeValue:@"hchart" forKey:@"dayViewKey"];
  return nil;
}

- (id)dayOverviewPrint {
  id         page;
  WOResponse *r;

  page = [self pageWithName:@"SkyInlineDayOverview"];
  [page takeValue:self->dataSource forKey:@"dataSource"];
  [page takeValue:self->day forKey:@"day"];
  [page takeValue:self->holidays forKey:@"holidays"];
  [page takeValue:[NSNumber numberWithBool:YES] forKey:@"printMode"];
  r = [page generateResponse];
  [r setHeader:@"text/html" forKey:@"content-type"];
  
  return r;
}

- (id)monthOverviewPrint {
  id page;
  WOResponse *r;

  page = [self pageWithName:@"SkyPrintMonthOverview"];
  [page takeValue:self->dataSource forKey:@"dataSource"];
  [page takeValue:self->holidays   forKey:@"holidays"];
  [page takeValue:[NSNumber numberWithInt:self->month] forKey:@"month"];
  [page takeValue:[NSNumber numberWithInt:self->year]  forKey:@"year"];
  r = [page generateResponse];
  [r setHeader:@"text/html" forKey:@"content-type"];

  return r;
}

- (id)overviewPrint {
  WOResponse *r;

  if ([self->selectedTab isEqualToString:@"dayoverview"]) {
    r = [self dayOverviewPrint];
  }
  else if ([self->selectedTab isEqualToString:@"weekoverview"]) {
    id         page;

    page = [self pageWithName:@"SkyPrintWeekOverview"];
    [page takeValue:self->dataSource forKey:@"dataSource"];
    [page takeValue:self->weekStart  forKey:@"weekStart"];
    [page takeValue:self->holidays   forKey:@"holidays"];
    r = [page generateResponse];
    [r setHeader:@"text/html" forKey:@"content-type"];
  }
  else if ([self->selectedTab isEqualToString:@"monthoverview"]) {
    r = [self monthOverviewPrint];
  }
  
  return r;
}

- (id)appointmentProposal {
  id ct;
  
  ct = [[self session] instantiateComponentForCommand:@"proposal"
                       type:[NGMimeType mimeType:@"eo/date"]];
  [[self context] takeValue:self->timeZone forKey:@"SkySchedulerTimeZone"];

  if (ct) {
    if (![self->dataSource isResCategorySelected]) {
      [ct addResources:[self->dataSource resources]];
    }
    [ct setParticipantsFromGids:[self->dataSource companies]];
    [self->dataSource clear];
  }
  
  return ct;
}

// KV-Coding

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"year"]) {
    [self setYear:[_value intValue]];
    return;
  }
  if ([_key isEqualToString:@"month"]) {
    [self setMonth:[_value intValue]];
    return;
  }
  if ([_key isEqualToString:@"weekViewKey"]) {
    [self setWeekViewKey:_value];
    return;
  }
  if ([_key isEqualToString:@"dayViewKey"]) {
    [self setDayViewKey:_value];
    return;
  }
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"year"]) {
    return [NSNumber numberWithInt:self->year];
  }
  if ([_key isEqualToString:@"month"]) {
    return [NSNumber numberWithInt:self->month];
  }
  if ([_key isEqualToString:@"weekViewKey"]) {
    return [self weekViewKey];
  }
  if ([_key isEqualToString:@"dayViewKey"]) {
    return [self dayViewKey];
  }
  if ([_key isEqualToString:@"dataSource"]) {
    return [self dataSource];
  }
  return [super valueForKey:_key];
}

@end /* SkySchedulerPage */
