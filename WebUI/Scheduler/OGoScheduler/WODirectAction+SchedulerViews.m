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

/*
  declares the following direct actions:

    viewWeek

      Parameter
        ?week  - number of week in year
        ?year  - year, defaults to current year
        ?tz    - name of timezone to use (defaults to session-tz)
      
      Example
        /wa/viewWeek?week=16&year=2000&tz=PDT
      
*/

#include <NGObjWeb/WODirectAction.h>
#include <OGoFoundation/OGoFoundation.h>
#include <OGoFoundation/OGoSession.h>
#include <OGoBase/LSCommandContext+Doc.h>
#include <NGObjWeb/NGObjWeb.h>
#include <OGoScheduler/SkyAptDataSource.h>
#include "common.h"

@interface NSObject(Privates)
- (void)setResources:(id)_resources;
- (void)setParticipantsFromGids:(id)_gids;
- (void)reconfigure;
- (void)reconfigureMonthDataSource;
@end

@implementation WODirectAction(SchedulerActions)

- (id<WOActionResults>)viewWeekAction {
  NSString   *tzName;
  int        weekNo, year, month;
  NSTimeZone *tz;
  id         page;
  NSCalendarDate *date;
  //  NSString   *selection;
  
  weekNo = [[[self request] formValueForKey:@"week"] intValue];
  year   = [[[self request] formValueForKey:@"year"] intValue];
  month  = [[[self request] formValueForKey:@"month"] intValue];
  tzName = [[self request] formValueForKey:@"tz"];
  //  selection = [[self request] formValueForKey:@"selection"];
  
  page = [self pageWithName:@"SkySchedulerPage"];

#if 0
  if (selection) {
    if ([selection hasPrefix:@"company :"]) {
      NSNumber *compId =
        [NSNumber numberWithInt:
                  [[selection substringFromIndex:9] intValue]];
      [[self session] transferObject:compId
                      owner:nil];
                  }
    else {
      // resource ..
      [[self session] transferObject:[selection substringFromIndex:9]
                      owner:nil];
    }
  }
#endif
  
  tz = (tzName)
    ? [NSTimeZone timeZoneWithAbbreviation:tzName]
    : [page timeZone];
  
  if (tz == nil)
    tz = [(id)[self session] timeZone];
  
  if (year == 0)
    year = [[NSCalendarDate calendarDate] yearOfCommonEra];
  if (month == 0)
    month = [[NSCalendarDate calendarDate] monthOfYear];
  if (weekNo == 0)
    weekNo = [[NSCalendarDate calendarDate] weekOfYear];
  
  date = [NSCalendarDate mondayOfWeek:weekNo inYear:year timeZone:tz];
  [date setTimeZone:tz];
  if ([date hourOfDay] != 0) {
    NSLog(@"%s: bug in date computing (foundation bug should be "
          @"fixed with libFoundation v1.0.21): %@",
          __PRETTY_FUNCTION__, date);
    // time zone detail changed -> foundation bug
    // trying to fix
    date = [date beginOfDay];
    if ([date dayOfWeek] == 0)
      // sunday due switch of timezone detail (foundation bug)
      date = [[date dateByAddingYears:0 months:0 days:1] beginOfDay];
    NSLog(@"%s: foundation bug: corrected date to: %@",
          __PRETTY_FUNCTION__, date);
  }
  
  [page takeValue:tz   forKey:@"timeZone"];
  [page takeValue:date forKey:@"weekStart"];
  [page takeValue:[NSNumber numberWithInt:year]  forKey:@"year"];
  [page takeValue:[NSNumber numberWithInt:month] forKey:@"month"];
  [page takeValue:@"weekoverview" forKey:@"selectedTab"];
  return page;
}

- (id<WOActionResults>)viewMonthAction {
  int        year, month;
  NSString   *tzName;
  NSTimeZone *tz;
  id         page;

  year   = [[[self request] formValueForKey:@"year"] intValue];
  month  = [[[self request] formValueForKey:@"month"] intValue];
  tzName = [[self request] formValueForKey:@"tz"];

  page = [self pageWithName:@"SkySchedulerPage"];
  tz = (tzName)
    ? [NSTimeZone timeZoneWithAbbreviation:tzName]
    : [page timeZone];
  if (tz == nil)
    tz = [(id)[self session] timeZone];
  if (year == 0)
    year = [[NSCalendarDate calendarDate] yearOfCommonEra];
  if (month == 0)
    month = [[NSCalendarDate calendarDate] monthOfYear];

  [page takeValue:[NSNumber numberWithInt:year]  forKey:@"year"];
  [page takeValue:[NSNumber numberWithInt:month] forKey:@"month"];
  [page takeValue:tz forKey:@"timeZone"];
  [page takeValue:@"monthoverview" forKey:@"selectedTab"];
  
  if ([page isContentPage])
    [[[self session] navigation] enterPage:page];
  
  return page;
}

- (id<WOActionResults>)viewYearAction {
  int        year;
  NSString   *tzName;
  NSTimeZone *tz;
  id         page;

  year   = [[[self request] formValueForKey:@"year"] intValue];
  tzName = [[self request] formValueForKey:@"tz"];

  page = [self pageWithName:@"SkySchedulerPage"];
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

- (id<WOActionResults>)viewDayAction {
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
  
  page = [self pageWithName:@"SkySchedulerPage"];
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
  if (day == 0)
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

- (id<WOActionResults>)viewDateAction {
  NSTimeZone *tz;
  NSString   *tzName;
  NSString   *oid;
  EOGlobalID *gid;
  id         sn;

  sn = [self session];
  
  if ((oid = [[self request] formValueForKey:@"oid"]) == nil) {
    [self logWithFormat:@"missing object id in activation-action."];
    return nil;
  }

  gid = [[[sn commandContext] typeManager] globalIDForPrimaryKey:oid];
  
  if (gid == nil) {
    [self logWithFormat:@"couldn't determine gid of objectid %@", oid];
    return nil;
  }
  
  tzName = [[self request] formValueForKey:@"tz"];
  
  tz = (tzName)
    ? [NSTimeZone timeZoneWithAbbreviation:tzName]
    : nil;
  
  if (tz == nil)
    tz = [sn timeZone];
  
  if ([tz isNotNull]) {
    /* pass timezone in context */
    WOContext *ctx;
    
    ctx = [(WOSession *)sn context];
    if (ctx == nil) [self logWithFormat:@"CONTEXT IS NIL !"];
    [ctx takeValue:tz forKey:@"SkySchedulerTimeZone"];
  }
  
  /* lookup global-id and activate */
  
  {
    WOComponent *page;
    page = [[sn navigation] activateObject:gid withVerb:@"view"];
    return page;
  }
}

- (BOOL)hasDateEntityFormValue {
  NSString *entity;

  entity = [[self request] formValueForKey:@"entity"];
  if ((entity == nil) ||
      ([entity length] == 0) ||
      ([entity isEqualToString:@"date"]) ||
      ([entity isEqualToString:@"appointment"]))
    return YES;

  return NO;
}

- (EOKeyGlobalID *)globalIDForMultiKeyValue:(NSArray *)oids {
  // TODO: explain when a multi-value key can happen!
  EOKeyGlobalID *gid;
  unsigned      i, cnt;
  id            *pKeys;
  
  if ((cnt = [oids count]) < 2)
    return nil;
  
  pKeys = (id *)calloc(cnt + 2, sizeof(id));
  for (i = 0; i < cnt; i++)
    pKeys[i] = [NSNumber numberWithInt:[[oids objectAtIndex:i] intValue]];
  
  gid = [EOKeyGlobalID globalIDWithEntityName:[gid entityName]
		       keys:pKeys keyCount:cnt zone:nil];
  if (pKeys != NULL) free(pKeys);
  
  return gid;
}

- (id<WOActionResults>)viewAptAction {
  OGoSession       *sn;
  LSCommandContext *ctx;
  EOKeyGlobalID    *gid;
  id oid;
  id obj;
  id last, c;
  
  if ([self hasDateEntityFormValue])
    return [self viewDateAction];
  
  oid = [[self request] formValueForKey:@"oid"];
  if (oid == nil) {
    [self logWithFormat:@"missing object id in activation-action."];
    return nil;
  }
  
  sn  = [self session];
  ctx = [sn commandContext];
  gid = (EOKeyGlobalID *)[[ctx typeManager] globalIDForPrimaryKey:oid];
  
  if (gid == nil) {
    [self logWithFormat:@"could not determine gid of objectid %@", oid];
    return nil;
  }
  
  {
    // check wether we have a multi pKey gid
    NSArray *oids;
    unsigned cnt;
    
    oids = [oid componentsSeparatedByString:@"-"];
    if ((cnt = [oids count]) > 1)
      gid = [self globalIDForMultiKeyValue:oids];
  }

  last = [[sn navigation] activePage];
  c = [[sn navigation]
           activateObject:gid
           withVerb:@"view"];

  if (c != last)
    return c;
  
  if ([[last errorString] length] > 0)
    [last setErrorString:nil];
  
  obj = [[ctx documentManager] documentForGlobalID:gid];
  if (gid == nil) {
    [self logWithFormat:@"could not determine document of gid %@", gid];
    return nil;
  }
  
  c = [[sn navigation] activateObject:obj withVerb:@"view"];
  if (c == nil) {
    [self logWithFormat:@"could not determine viewer page for " 
            @"gid %@ or document %@", gid, obj];
    return nil;
  }
  return c;
}

- (id<WOActionResults>)newAptAction {
  NSTimeZone     *tz; 
  NSString       *tzName;
  id             sn;
  int            year, month, day, hour, minute, duration;
  NSCalendarDate *date, *endDate, *now;
  NSDictionary   *d;
  id             page;
  OGoContentPage *activePage;
  
  sn = [self session];

  tzName = [[self request] formValueForKey:@"tz"];
  
  tz = (tzName)
    ? [NSTimeZone timeZoneWithAbbreviation:tzName]
    : nil;
  
  if (tz == nil)
    tz = [sn timeZone];
  
  year     = [[[self request] formValueForKey:@"year"]   intValue];
  month    = [[[self request] formValueForKey:@"month"]  intValue];
  day      = [[[self request] formValueForKey:@"day"]    intValue];
  hour     = [[[self request] formValueForKey:@"hour"]   intValue];
  minute   = [[[self request] formValueForKey:@"minute"] intValue];
  duration = [[[self request] formValueForKey:@"duration"] intValue];

  now = [NSCalendarDate date];
  if ((day < 1) || (day > 31))         day      = [now dayOfMonth];
  if ((month < 1) || (month > 12))     month    = [now monthOfYear];
  if ((year  < 1700) || (year > 2300)) year     = [now yearOfCommonEra];
  if ((hour  < 1) || (hour > 24))      hour     = 11;
  if (duration < 1)                    duration = 60; // 1 hour
  
  date = [[NSCalendarDate alloc] initWithYear:year month:month day:day
                                 hour:hour minute:minute second:0
                                 timeZone:tz];
  [date autorelease];

  if (date == nil) date = now;

  endDate = [date dateByAddingYears:0 months:0 days:0
                  hours:0 minutes:duration seconds:0];

  d = [NSDictionary dictionaryWithObjectsAndKeys:
                      date,    @"startDate",
                      endDate, @"endDate",
                      nil];
  
  [sn transferObject:d owner:nil];
  
  activePage = [[sn navigation] activePage];
  page       = [sn instantiateComponentForCommand:@"new"
                   type:[NGMimeType mimeType:@"eo/date"]];
  
  if (([[activePage name] isEqualToString:@"SkySchedulerPage"]) ||
      ([[activePage name] isEqualToString:@"SkyResourceSchedulerPage"])) {
    SkyAptDataSource *dataS;

    dataS = (SkyAptDataSource *)[(id)activePage dataSource];
    
    if (![dataS isResCategorySelected])
      [page setResources:[dataS resources]];
    
    [page setParticipantsFromGids:[dataS companies]];
  }

  if ([page isContentPage])
    [[sn navigation] enterPage:page];
  
  return page;
}

#if 0 // TODO: why is this commented out?
- (id<WOActionResults>)newEventAction {
  NSTimeZone *tz;
  NSString   *tzName;
  id         sn;
  int        year, month, day, hour, minute, duration;
  NSCalendarDate *date, *endDate, *now;

  sn = [self session];

  tzName = [[self request] formValueForKey:@"tz"];
  
  tz = (tzName)
    ? [NSTimeZone timeZoneWithAbbreviation:tzName]
    : nil;
  
  if (tz == nil)
    tz = [sn timeZone];
  
  year     = [[[self request] formValueForKey:@"year"]   intValue];
  month    = [[[self request] formValueForKey:@"month"]  intValue];
  day      = [[[self request] formValueForKey:@"day"]    intValue];
  hour     = [[[self request] formValueForKey:@"hour"]   intValue];
  minute   = [[[self request] formValueForKey:@"minute"] intValue];

  now = [NSCalendarDate date];
  if ((day < 1) || (day > 31))         day      = [now dayOfMonth];
  if ((month < 1) || (month > 12))     month    = [now monthOfYear];
  if ((year  < 1700) || (year > 2300)) year     = [now yearOfCommonEra];
  if ((hour  < 1) || (hour > 24))      hour     = 11;

  date = [[NSCalendarDate alloc] initWithYear:year month:month day:day
                                 hour:hour minute:minute second:0
                                 timeZone:tz];
  AUTORELEASE(date);

  if (date == nil) date = now;

  [sn transferObject:date owner:nil];
  
  return [[self session] instantiateComponentForCommand:@"new"
                         type:[NGMimeType mimeType:@"eo/event"]];
}
#endif

@end /* WODirectAction(SchedulerActions) */
