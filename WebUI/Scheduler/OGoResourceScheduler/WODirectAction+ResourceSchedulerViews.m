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

/*
  declares the direct actions for resource views:
*/

#include "common.h"
#include <OGoScheduler/SkyAptDataSource.h>

@implementation WODirectAction(ResourceSchedulerActions)

- (id<WOActionResults>)viewWeekResourcesAction {
  NSString   *tzName;
  int        weekNo, year, month;
  NSTimeZone *tz;
  id         page;
  NSCalendarDate *date;
  NSString   *selection;
  
  weekNo    = [[[self request] formValueForKey:@"week"] intValue];
  year      = [[[self request] formValueForKey:@"year"] intValue];
  month     = [[[self request] formValueForKey:@"month"] intValue];
  tzName    = [[self request] formValueForKey:@"tz"];
  selection = [[self request] formValueForKey:@"selection"];
  
  page = [self pageWithName:@"SkyResourceSchedulerPage"];

  if (selection)
    [[self session] transferObject:selection owner:nil];
  
  tz = (tzName) 
    ? [NSTimeZone timeZoneWithAbbreviation:tzName]
    : [page timeZone];
  
  if (tz == nil)
    tz = [(id)[self session] timeZone];
  
  if (year == 0)
    year = [[NSCalendarDate calendarDate] yearOfCommonEra];

  date = [NSCalendarDate mondayOfWeek:weekNo inYear:year timeZone:tz];
  
  [page takeValue:tz                             forKey:@"timeZone"];
  [page takeValue:date                           forKey:@"weekStart"];
  [page takeValue:[NSNumber numberWithInt:year]  forKey:@"year"];
  [page takeValue:[NSNumber numberWithInt:month] forKey:@"month"];
  [page takeValue:@"weekoverview"                forKey:@"selectedTab"];
  return page;
}

- (id<WOActionResults>)viewMonthResourcesAction {
  int        year, month;
  NSString   *tzName;
  NSTimeZone *tz;
  id         page;

  year   = [[[self request] formValueForKey:@"year"] intValue];
  month  = [[[self request] formValueForKey:@"month"] intValue];
  tzName = [[self request] formValueForKey:@"tz"];

  page = [self pageWithName:@"SkyResourceSchedulerPage"];
  if (tzName)
    tz = [NSTimeZone timeZoneWithAbbreviation:tzName];
  else
    tz = [page timeZone];
  if (tz == nil)
    tz = [(id)[self session] timeZone];
  if (year == 0)
    year = [[NSCalendarDate calendarDate] yearOfCommonEra];

  [page takeValue:[NSNumber numberWithInt:year]  forKey:@"year"];
  [page takeValue:[NSNumber numberWithInt:month] forKey:@"month"];
  [page takeValue:tz forKey:@"timeZone"];
  [page takeValue:@"monthoverview" forKey:@"selectedTab"];
  
  if ([page isContentPage])
    [[[self session] navigation] enterPage:page];
  
  return page;
}

- (id<WOActionResults>)viewYearResourcesAction {
  int        year;
  NSString   *tzName;
  NSTimeZone *tz;
  id         page;

  year   = [[[self request] formValueForKey:@"year"] intValue];
  tzName = [[self request] formValueForKey:@"tz"];

  page = [self pageWithName:@"SkyResourceSchedulerPage"];
  if (tzName)
    tz = [NSTimeZone timeZoneWithAbbreviation:tzName];
  else
    tz = [page timeZone];
  if (tz == nil)
    tz = [(id)[self session] timeZone];
  if (year == 0)
    year = [[NSCalendarDate calendarDate] yearOfCommonEra];

  [page takeValue:[NSNumber numberWithInt:year]  forKey:@"year"];
  [page takeValue:tz forKey:@"timeZone"];
  [page takeValue:@"yearoverview" forKey:@"selectedTab"];
  
  if ([page isContentPage])
    [[[self session] navigation] enterPage:page];
  
  return page;
}

- (id<WOActionResults>)viewDayResourcesAction {
  int            year;
  int            month;
  int            day;
  NSString       *tzName;
  NSTimeZone     *tz;
  NSCalendarDate *d, *monday;
  id             page;

  year   = [[[self request] formValueForKey:@"year"] intValue];
  month  = [[[self request] formValueForKey:@"month"] intValue];
  day    = [[[self request] formValueForKey:@"day"] intValue];
  tzName = [[self request] formValueForKey:@"tz"];
  
  page = [self pageWithName:@"SkyResourceSchedulerPage"];
  if (tzName)
    tz = [NSTimeZone timeZoneWithAbbreviation:tzName];
  else
    tz = [page timeZone];
  if (tz == nil)
    tz = [(id)[self session] timeZone];
  if (year == 0)
    year = [[NSCalendarDate calendarDate] yearOfCommonEra];
  if (month == 0)
    month = [[NSCalendarDate calendarDate] monthOfYear];
  if (month == 0)
    day = [[NSCalendarDate calendarDate] dayOfMonth];

  d = [NSCalendarDate dateWithYear:year month:month day:day
                      hour:0 minute:0 second:0 timeZone:tz];
  monday = [d mondayOfWeek];
  
  [page takeValue:tz     forKey:@"timeZone"];
  [page takeValue:d      forKey:@"day"];
  [page takeValue:monday forKey:@"weekStart"];
  [page takeValue:[NSNumber numberWithInt:year]  forKey:@"year"];
  [page takeValue:[NSNumber numberWithInt:month] forKey:@"month"];
  [page takeValue:@"dayoverview" forKey:@"selectedTab"];
  
  if ([page isContentPage])
    [[[self session] navigation] enterPage:page];
  
  return page;
}

@end /* WODirectAction(SchedulerActions) */
