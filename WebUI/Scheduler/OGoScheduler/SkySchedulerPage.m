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

#include <OGoFoundation/OGoContentPage.h>
#include <OGoScheduler/SkyHolidayCalculator.h>
#include <OGoScheduler/SkyAptCompoundDataSource.h>

@class NSTimeZone, NSCalendarDate, NSNumber;

@interface SkySchedulerPage : OGoContentPage
{
  NSTimeZone     *timeZone;
  id             dataSource;
  NSCalendarDate *weekStart;
  NSString       *selectedTab;
  NSString       *weekViewKey;
  NSString       *dayViewKey;
  /* month overview */
  int            month;
  int            year;
  /* day overview */
  NSCalendarDate *day;
  // holidays
  SkyHolidayCalculator *holidays;
}

- (void)setWeekStart:(NSCalendarDate *)_ws;
- (void)setDay:(NSCalendarDate *)_day;
- (void)setMonth:(int)_month;
- (void)setYear:(int)_year;
- (void)setSelectedTab:(NSString *)_tab;
- (int)currentWeek;

@end

@interface NSObject(SkySchedulerPage_PRIVATE)
- (void)addResources:(id)_resources;
- (void)setParticipantsFromGids:(id)_gids;
- (void)setObject:(id)_object;
- (void)setGoBackWithCount:(unsigned)_goBackWithCount;
@end

#import <Foundation/Foundation.h>
#import <EOControl/EOControl.h>
#include <NGExtensions/NGExtensions.h>
#include <NGObjWeb/NGObjWeb.h>
#include <NGMime/NGMime.h>
#include <OGoFoundation/OGoSession.h>
#include <OGoFoundation/LSWNotifications.h>
#include <OGoScheduler/SkyAptDataSource.h>
#include <NGExtensions/EOCacheDataSource.h>

// #define USE_CACHE 1

@implementation SkySchedulerPage

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
    //[self setSelectedTab:@"weekoverview"];
    self->selectedTab = nil;
    //[self takeValue:@"overview" forKey:@"weekViewKey"];
    self->weekViewKey = nil;
    //[self takeValue:@"overview" forKey:@"dayViewKey"];
    self->dayViewKey  = nil;

    /*
    self->dataSource = (SkyAptDataSource *)[[SkyAptDataSource alloc] init];
    [self->dataSource setContext:[(id)[self session] skyrixContext]];
    */
    self->dataSource = [[SkyAptCompoundDataSource alloc] init];
    {
      // building needed dataSources
      NSUserDefaults *ud = [(id)[self session] userDefaults];
      id ctx = [(id)[self session] commandContext];
      id ds  = nil;
      Class c;
      NGBundleManager *bm = [NGBundleManager defaultBundleManager];
      NSBundle        *bundle;

      ds = [[SkyAptDataSource alloc] init];
      [ds setContext:ctx];
      [self->dataSource addSource:ds];
      RELEASE(ds);

      if ([[ud valueForKey:@"scheduler_show_palm_dates"] boolValue]) {
        if ((bundle = [bm bundleWithName:@"OGoPalmDS" type:@"ds"])) {
          if (![bundle load]) {
            [self debugWithFormat:@"failed to load bundle %@", bundle];
          }
          else if ((c = NSClassFromString(@"SkyPalmDateDataSource"))) {
	    // TODO: wrong cast (was best match)
            ds = [(SkyAccessManager *)[c alloc] initWithContext:ctx];
            [self->dataSource addSource:ds];
            [ds release];
          }
          else
            [self debugWithFormat:@"missing SkyPalmDateDataSource class"];
        }
        else {
          [self debugWithFormat:@"missing OGoPalmDS.ds bundle"];
        }
      }

      if ([[ud valueForKey:@"scheduler_show_jobs"] boolValue]) {
        if ((bundle = [bm bundleWithName:@"OGoJobs" type:@"ds"])) {      
          if (![bundle load]) {
            [self debugWithFormat:@"failed to load bundle %@", bundle];
          }
          if ((c = NSClassFromString(@"SkySchedulerJobDataSource"))) {
	    // TODO: wrong cast (was best match)
            ds = [(SkyAccessManager *)[c alloc] initWithContext:ctx];
            [self->dataSource addSource:ds];
            [ds release];
          }
          else
            [self debugWithFormat:@"missing SkySchedulerJobDataSource class"];
        }
        else {
          [self debugWithFormat:@"missing OGoJobs.ds bundle"];
        }
      }
    }
    

#if USE_CACHE
    {
      EODataSource *ds;

      ds = self->dataSource;
      self->dataSource = [[EOCacheDataSource alloc] initWithDataSource:ds];
      [self->dataSource setTimeout:120.0];
      RELEASE(ds); ds = nil;
    }
#endif
    
    self->year  = [self->day yearOfCommonEra];
    self->month = [self->day monthOfYear];

    /* holiday calculator */
    {
      SkyHolidayCalculator *c;

      c = [SkyHolidayCalculator calculatorWithYear:self->year
                                timeZone:self->timeZone
                                userDefaults:[(id)[self session]
                                                  userDefaults]];
      ASSIGN(self->holidays,c);
    }
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->weekStart);
  RELEASE(self->selectedTab);
  RELEASE(self->timeZone);
  RELEASE(self->dataSource);
  RELEASE(self->day);
  RELEASE(self->holidays);
  RELEASE(self->weekViewKey);
  RELEASE(self->dayViewKey);
  [super dealloc];
}
#endif

/* notifications */

- (void)sleep {
  //[self->dataSource clear];
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
  id ds;
#if USE_CACHE
  ds = [self->dataSource source];
#else
  ds = self->dataSource;
#endif
  [ds setIsResCategorySelected:_flag];
}
- (BOOL)isResCategorySelected {
  id ds;
#if USE_CACHE
  ds = [self->dataSource source];
#else
  ds = self->dataSource;
#endif
  return ([ds isResCategorySelected] && ([[ds companies] count] == 0));
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
    ASSIGNCOPY(self->selectedTab, _tab);
    if ([self->selectedTab isEqualToString:@"weekoverview"]) {
      int cw;
      cw = [self currentWeek];
      [self setMonth:(cw < 2) ? 1 : [self->weekStart monthOfYear]];
      [self setYear:[self->weekStart yearOfCommonEra] + ((cw < 2) ? 1 : 0)];
    }
    if ([self->selectedTab isEqualToString:@"dayoverview"]) {
      int cw;
      cw = [self currentWeek];
      [self setWeekStart:[self->day mondayOfWeek]];
      [self setMonth:(cw < 2) ? 1 : [self->day monthOfYear]];
      [self setYear:[self->day yearOfCommonEra] + ((cw < 2) ? 1 : 0)];
    }
  }
}
- (NSString *)selectedTab {
  if (self->selectedTab == nil) {
    NSString *tab = [[[self session] userDefaults]
                            valueForKey:@"schedulerpage_tab"];
    if (![tab length]) tab = @"weekoverview";
    [self setSelectedTab:tab];
  }
  return self->selectedTab;
}

- (void)setWeekViewKey:(NSString *)_key {
  ASSIGNCOPY(self->weekViewKey,_key);
}
- (NSString *)weekViewKey {
  if (self->weekViewKey == nil) {
    NSString *tab = [[[self session] userDefaults]
                            valueForKey:@"schedulerpage_weekview"];
    if (![tab length]) tab = @"overview";
    [self setWeekViewKey:tab];
  }
  return self->weekViewKey;
}
- (void)setDayViewKey:(NSString *)_key {
  ASSIGNCOPY(self->dayViewKey,_key);
}
- (NSString *)dayViewKey {
  if (self->dayViewKey == nil) {
    NSString *tab = [[[self session] userDefaults]
                            valueForKey:@"schedulerpage_dayview"];
    if (![tab length]) tab = @"overview";
    [self setDayViewKey:tab];
  }
  return self->dayViewKey;
}

/* month labels */

- (NSString *)monthLabel_weekoverview {
  id label, month1;
  NSCalendarDate *ws, *we;
  
  ws = [self weekStart];
  we = [ws dateByAddingYears:0 months:0 days:6
	   hours:23 minutes:0 seconds:0];
  
  if ([ws monthOfYear] == [we monthOfYear]) {
    month1 = [ws descriptionWithCalendarFormat: @"%B"];
    label = [NSString stringWithFormat:@"%@ %@",
		      [[self labels] valueForKey:month1],
		      [ws descriptionWithCalendarFormat: @"%Y"]];
  }
  else {
    id month2;
    
    month1 = [ws descriptionWithCalendarFormat:@"%B"];
    month2 = [we descriptionWithCalendarFormat:@"%B"];
    
    label = [NSString stringWithFormat:@"%@ %@ / %@ %@",
		      [[self labels] valueForKey:month1],
		      [ws descriptionWithCalendarFormat: @"%Y"],
		      [[self labels] valueForKey:month2],
		      [we descriptionWithCalendarFormat: @"%Y"]];
  }
  return label;
}

- (NSString *)monthLabel_monthoverview {
  NSCalendarDate *m;
  NSString       *monthKey;
  NSString       *label;

  m = [NSCalendarDate dateWithYear:self->year month:self->month
		      day:1 hour:0 minute:0 second:0
		      timeZone:self->timeZone];
    
  monthKey = [m descriptionWithCalendarFormat:@"%B"];
  label    = [NSString stringWithFormat:@"%@ %@",
		         [[self labels] valueForKey:monthKey],
                         [m descriptionWithCalendarFormat:@"%Y"]];
  return label;
}

- (NSString *)monthLabel_yearoverview {
  switch (self->year) { /* very minor speed-up for 4 years ;-) */
  case 2002: return @"2002";
  case 2003: return @"2003";
  case 2004: return @"2004";
  case 2005: return @"2005";
  default:   return [NSString stringWithFormat:@"%d", self->year];
  }
}

- (NSString *)monthLabel_dayoverview {
  return [[(OGoSession *)[self session] formatDate]
	   stringForObjectValue:self->day];
}

- (NSString *)monthLabel {
  /* hh asks: can someone explain that to me, looks weird? */
  
  if ([[self selectedTab] isEqualToString:@"weekoverview"])
    return [self monthLabel_weekoverview];
  
  if ([[self selectedTab] isEqualToString:@"monthoverview"])
    return [self monthLabel_monthoverview];
  
  if ([[self selectedTab] isEqualToString:@"yearoverview"])
    return [self monthLabel_yearoverview];
  
  if ([[self selectedTab] isEqualToString:@"dayoverview"])
    return [self monthLabel_dayoverview];
  
  return @"SkyScheduler 2";
}

- (NSString *)dayTabLabel {
  return [[(OGoSession *)[self session] formatDate]
                       stringForObjectValue:self->day];
}
- (int)weekOfDate:(NSCalendarDate *)_date {
  NSCalendarDate *d;
  int woy, nowy;

  d    = _date;
  woy  = [d weekOfYear];
  nowy = [d numberOfWeeksInYear];
  if (woy > nowy) {
    d   = [d dateByAddingYears:0 months:0 days:7
	     hours:0 minutes:0 seconds:0];
    woy = [d weekOfYear] - 1;
  }
  return woy;
}
- (int)currentWeek {
  return [self weekOfDate:[self weekStart]];
}
- (NSString *)weekTabLabel {
  NSString *format = [[self labels] valueForKey:@"weekTabLabelFormat"];
  return [NSString stringWithFormat:format, [self currentWeek]];
}
- (NSString *)monthTabLabel {
  static NSArray* months = nil;

  if (months == nil)
    months = [[NSArray alloc] initWithObjects:
                              @"January", @"February", @"March",
                              @"April", @"May", @"June", @"July",
                              @"August", @"September", @"October",
                              @"November", @"December", nil];

  if ((self->month > 12) || (self->month < 1))
    return @"";
  return [[self labels] valueForKey:[months objectAtIndex:(self->month-1)]];
}

// month overview

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
  return [NSString stringWithFormat:@"week%02d", [self currentWeek]];
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
- (id)switchToWeekColumnView {
  [self takeValue:@"columnview" forKey:@"weekViewKey"];
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
  [page takeValue:[self timeZone] forKey:@"timeZone"];
  r = [page generateResponse];
  [r setHeader:@"text/html" forKey:@"content-type"];

  return r;
}

- (id)overviewPrint {
  WOResponse *r;

  if ([[self selectedTab] isEqualToString:@"dayoverview"]) {
    r = [self dayOverviewPrint];
  }
  else if ([[self selectedTab] isEqualToString:@"weekoverview"]) {
    id         page;

    page = [self pageWithName:@"SkyPrintWeekOverview"];
    [page takeValue:self->dataSource forKey:@"dataSource"];
    [page takeValue:self->weekStart  forKey:@"weekStart"];
    [page takeValue:self->holidays   forKey:@"holidays"];
    r = [page generateResponse];
    [r setHeader:@"text/html" forKey:@"content-type"];
  }
  else if ([[self selectedTab] isEqualToString:@"monthoverview"]) {
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

#if 0
- (NSCalendarDate *)dateForEvent {
  NSCalendarDate* date;
  if ([[self selectedTab] isEqualToString:@"dayoverview"])
    date = self->day;
  else if ([[self selectedTab] isEqualToString:@"weekoverview"])
    date = self->weekStart;
  else if ([[self selectedTab] isEqualToString:@"monthoverview"])
    date = [NSCalendarDate dateWithYear:self->year month:self->month day:1
                           hour:0 minute:0 second:0 timeZone:self->timeZone];
  else
    date = [NSCalendarDate dateWithYear:self->year month:1 day:1
                           hour:0 minute:0 second:0 timeZone:self->timeZone];
  date = [date beginOfDay];
  return date;
}

- (id)newEvent {
  id ct;

  [[self session] transferObject:[self dateForEvent] owner:nil];
  ct = [[self session] instantiateComponentForCommand:@"new"
                       type:[NGMimeType mimeType:@"eo/event"]];
  if (ct)
    [self->dataSource clear];
  return ct;
}
#endif

#if 0 //hh

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
  return [super valueForKey:_key];
}

#endif

@end /* SkySchedulerPage */


@implementation SkySchedulerPage(TrashPrivateMethodes)

- (NSString *)loginPermissionsFor:(id)_app {
  NSString *perms;
  id       obj;

  obj = _app;
  if (obj == nil) return nil;
  
  if ((perms = [obj valueForKey:@"permissions"]))
    return perms;

  perms = [(id)self runCommand:@"appointment::access",
                @"gid", [obj valueForKey:@"globalID"],
                nil];
  if (perms == nil) {
    [self setErrorString:@"couldn't get permissions for appointment !"];
    return @"";
  }
  else
    [obj takeValue:perms forKey:@"permissions"];
  
  return perms;
}

@end /* SkySchedulerPage(TrashPrivateMethodes) */
