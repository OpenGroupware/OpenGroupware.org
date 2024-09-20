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

#include "NSCalendarDate+OGoScheduler.h"
#include <OGoFoundation/LSWNotifications.h>
#include "common.h"
#include <OGoScheduler/SkyAptDataSource.h>
#include <NGExtensions/EOCacheDataSource.h>

@implementation SkySchedulerPage

static NSArray* months = nil; /* label keys */

+ (void)initialize {
  months = [[NSArray alloc] initWithObjects:
                              @"January", @"February", @"March",
                              @"April", @"May", @"June", @"July",
                              @"August", @"September", @"October",
                              @"November", @"December", nil];
}

- (BOOL)_loadDataSourceBundle:(NSString *)_bundleName {
  NGBundleManager *bm;
  NSBundle *bundle;
  
  bm = [NGBundleManager defaultBundleManager];
  if ((bundle = [bm bundleWithName:_bundleName type:@"ds"]) == nil) {
    NSLog(@"ERROR: missing bundle: %@", _bundleName);
    return NO;
  }
  if (![bundle load]) {
    NSLog(@"ERROR: failed to load bundle: %@", bundle);
    return NO;
  }
  return YES;
}

- (BOOL)defaultShowPalmDates {
  NSUserDefaults *ud = [(id)[self session] userDefaults];
  return [[ud valueForKey:@"scheduler_show_palm_dates"] boolValue];
}
- (BOOL)defaultShowTasks {
  NSUserDefaults *ud = [(id)[self session] userDefaults];
  return [[ud valueForKey:@"scheduler_show_jobs"] boolValue];
}

- (SkyHolidayCalculator *)_newHolidaysCalculator {
  SkyHolidayCalculator *c;
  
  c = [SkyHolidayCalculator calculatorWithYear:self->year
			    timeZone:self->timeZone
			    userDefaults:[(id)[self session] userDefaults]];
  return [c retain];
}

- (SkyAptDataSource *)_newAptDataSource {
  SkyAptDataSource *ds;
  
  // TODO: no -initWithContext:?
  ds = [[SkyAptDataSource alloc] init];
  [ds setContext:[(OGoSession *)[self session] commandContext]];
  return ds;
}

- (BOOL)_addDataSource:(NSString *)_dsName fromBundle:(NSString *)_bundleName {
  LSCommandContext *ctx;
  EODataSource *ds;
  Class c;
  
  if (![self _loadDataSourceBundle:_bundleName])
    return NO;
  
  if ((c = NSClassFromString(_dsName)) == Nil) {
    [self logWithFormat:@"ERROR: missing datasource class: %@", _dsName];
    return NO;
  }
  
  ctx = [(id)[self session] commandContext];
  // TODO: wrong cast (was best match)
  ds = [(SkyAccessManager *)[c alloc] initWithContext:ctx];
  [self->dataSource addSource:ds];
  [ds release]; ds = nil;
  return YES;
}

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
    [self setDay:[NSCalendarDate calendarDate]];
    [self setWeekStart:[self->day mondayOfWeek]];
    
    if ([self defaultShowTasks] || [self defaultShowPalmDates]) {
      self->dataSource = [[SkyAptCompoundDataSource alloc] init];

      [self->dataSource addSource:[self _newAptDataSource]];
      
      if ([self defaultShowPalmDates])
	[self _addDataSource:@"SkyPalmDateDataSource" fromBundle:@"OGoPalmDS"];
      
      if ([self defaultShowTasks]) {
	[self _addDataSource:@"SkySchedulerJobDataSource" 
	      fromBundle:@"OGoJobs"];
      }
    }
    else
      self->dataSource = [self _newAptDataSource];
    
    self->year     = [self->day yearOfCommonEra];
    self->month    = [self->day monthOfYear];
    self->holidays = [self _newHolidaysCalculator];
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

  ds = self->dataSource;
  [ds setIsResCategorySelected:_flag];
}
- (BOOL)isResCategorySelected {
  id ds;
  
  ds = self->dataSource;
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
  if ([self->timeZone isEqual:_tz])
    return;
  
  ASSIGN(self->timeZone, _tz);
  [self setDay:self->day];
}
- (NSTimeZone *)timeZone {
  return self->timeZone;
}

- (void)setWeekStart:(NSCalendarDate *)_ws {
  if ([self->weekStart isEqualToDate:_ws])
    return;
  ASSIGN(self->weekStart,_ws);
}
- (NSCalendarDate *)weekStart {
  return self->weekStart;
}

- (void)setSelectedTab:(NSString *)_tab {
  if ([_tab isEqualToString:self->selectedTab])
    return;
  
  ASSIGNCOPY(self->selectedTab, _tab);
  
  // TODO: see OGo bug 1132
#if ENABLE_OGO_BUG_1132
  if ([self->selectedTab isEqualToString:@"weekoverview"]) {
    NSCalendarDate *ws;
    
    ws = [self weekStart];
    [self setMonth:[ws bestMonthForWeekView:ws]];
    [self setYear:[ws bestYearForWeekView:ws]];
  }
#endif
  if ([self->selectedTab isEqualToString:@"dayoverview"]) {
    /*
       Note: this makes the "new year" and "new month" as visible in the 
             weekview appear in the tabs, not the month/year of the day itself.
    */
    
    // Note: uses a different week start for calc and set?
    // unused: ws = [self weekStart];
    [self setWeekStart:[self->day mondayOfWeek]]; /* set new weekstart */
#if ENABLE_OGO_BUG_1132
    [self setMonth:[self->day bestMonthForWeekView:ws]];
    [self setYear:[self->day  bestYearForWeekView:ws]];
#endif
  }
}
- (NSString *)selectedTab {
  NSString *tab;
  
  if (self->selectedTab != nil)
    return self->selectedTab;
  
  tab = [[[self session] userDefaults] valueForKey:@"schedulerpage_tab"];
  if ([tab length] == 0) tab = @"weekoverview";
  [self setSelectedTab:tab];
  return self->selectedTab;
}

- (void)setWeekViewKey:(NSString *)_key {
  ASSIGNCOPY(self->weekViewKey,_key);
}
- (NSString *)weekViewKey {
  NSString *tab;
  
  if (self->weekViewKey != nil)
    return self->weekViewKey;
  
  tab = [[[self session] userDefaults] valueForKey:@"schedulerpage_weekview"];
  if ([tab length] == 0) tab = @"overview";
  [self setWeekViewKey:tab];
  return self->weekViewKey;
}
- (void)setDayViewKey:(NSString *)_key {
  ASSIGNCOPY(self->dayViewKey,_key);
}
- (NSString *)dayViewKey {
  NSString *tab;
  
  if (self->dayViewKey != nil)
    return self->dayViewKey;
  
  tab = [[[self session] userDefaults] valueForKey:@"schedulerpage_dayview"];
  if ([tab length] == 0) tab = @"overview";
  [self setDayViewKey:tab];
  return self->dayViewKey;
}

/* month labels */

- (NSString *)monthLabel_weekoverview {
  NSString *label, *month1;
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
    NSString *month2;
    
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
  case 2006: return @"2006";
  case 2007: return @"2007";
  default: {
    char buf[8];
    sprintf(buf, "%d", self->year);
    return [NSString stringWithCString:buf];
  }
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
  // DEPRECATED
  return [_date bestWeekForWeekView];
}
- (int)currentWeek {
  return [[self weekStart] bestWeekForWeekView];
}
- (NSString *)weekTabLabel {
  NSString *format = [[self labels] valueForKey:@"weekTabLabelFormat"];
  return [NSString stringWithFormat:format, [self currentWeek]];
}
- (NSString *)monthTabLabel {
  
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

// TODO: move to icon object
- (NSString *)monthIcon {
  char buf[16];
  sprintf(buf, "month%02d", self->month);
  return [NSString stringWithCString:buf];
}
- (NSString *)weekIcon {
  char buf[16];
  sprintf(buf, "week%02d", [self currentWeek]);
  return [NSString stringWithCString:buf];
}
- (NSString *)yearIcon {
  char buf[16];
  
  if (!(((self->year > 1995) && (self->year < 2016))))
    return @"year";
    
  sprintf(buf, "year%04d", self->year);
  return [NSString stringWithCString:buf];
}
- (NSString *)dayIcon {
  char buf[16];
  sprintf(buf, "day%02d", [[self day] dayOfMonth]);
  return [NSString stringWithCString:buf];
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
