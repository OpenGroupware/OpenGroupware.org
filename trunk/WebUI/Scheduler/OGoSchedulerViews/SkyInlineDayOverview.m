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
#import <Foundation/NSDate.h>

@class NSCalendarDate, NSArray;

@interface SkyInlineDayOverview : SkyInlineAptDataSourceView
{
@protected
  NSCalendarDate *day;
  id             intervalDataSource;

  // config
  NSTimeInterval interval;
  NSTimeInterval dayStart;
  NSTimeInterval dayEnd;

  NSArray        *currentApts;
  NSArray        *moreDayApts;
  NSArray        *allDayDates;
}

@end

#include <OGoScheduler/SkyAptDataSource.h>
#include "SkyAppointmentFormatter.h"
#include "common.h"
#include <OGoFoundation/WOComponent+config.h>
#include <OGoFoundation/OGoSession.h>
#include <OGoFoundation/OGoNavigation.h>
#include <OGoFoundation/WOComponent+Commands.h>
#include <LSFoundation/LSCommandContext.h>
#include <NGExtensions/EOFilterDataSource.h>

@implementation SkyInlineDayOverview

- (id)init {
  if ((self = [super init])) {
    NSNotificationCenter *nc = nil;

    nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(noteChange:)
        name:@"SkyDataSourceWillClear" object:nil];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self->intervalDataSource release];
  [self->day                release];
  [self->moreDayApts        release];
  [self->currentApts        release];
  [self->allDayDates        release];
  [super dealloc];
}

/* notifications */

- (void)syncAwake {
  NSUserDefaults *ud;

  [super syncAwake];

  ud = [(id)[self session] userDefaults];
  self->interval =
    [[ud objectForKey:@"scheduler_dayoverview_timeinterval"] doubleValue];
  self->dayStart =
    [[ud objectForKey:@"scheduler_dayoverview_daystart"] doubleValue];
  self->dayEnd =
    [[ud objectForKey:@"scheduler_dayoverview_dayend"] doubleValue];
  [self->moreDayApts release]; self->moreDayApts = nil;
  [self->allDayDates release]; self->allDayDates = nil;
  [self->currentApts release]; self->currentApts = nil;
  [self setCurrentDate:nil];
}

- (void)noteChange:(id)_note {
  [self->moreDayApts release]; self->moreDayApts = nil;
  [self->currentApts release]; self->currentApts = nil;
  [self->allDayDates release]; self->allDayDates = nil;
}

/* filter datasource support */

- (EOQualifier *)intervalQualifier {
  EOQualifier *q;
  NSCalendarDate *s, *e;
  NSCalendarDate *begin, *end1, *end2;

  s = [self currentDate];
  e = [s dateByAddingYears:0 months:0 days:0 hours:0 minutes:0
         seconds:(int)self->interval];

  begin = [s beginOfDay];
  end1  = [[s endOfDay] dateByAddingYears:0 months:0 days:0
                        hours:0 minutes:-1 seconds:0]; // 23:58:59
  end2  = [begin dateByAddingYears:0 months:0 days:1
                 hours:0 minutes:0 seconds:0]; // 24:00:00

  q = [EOQualifier qualifierWithQualifierFormat:
                   @"(startDate > %@ OR startDate = %@)"
                   @" AND (startDate < %@) AND NOT "
                   @"((startDate = %@) AND (endDate > %@) AND (endDate < %@ ))",
                   s, s, e, begin, end1, end2];
  return q;
}

- (EOQualifier *)allDayAptsQualifier {
  EOQualifier *q;
  NSCalendarDate *begin, *end1, *end2;

  begin = [self->day beginOfDay];
  end1  = [[begin endOfDay] dateByAddingYears:0 months:0 days:0
                            hours:0 minutes:-1 seconds:0]; // 23:58:59
  end2  = [begin dateByAddingYears:0 months:0 days:1
                 hours:0 minutes:0 seconds:0]; // 24:00:00
  q = [EOQualifier qualifierWithQualifierFormat:
                   @"startDate = %@ AND endDate > %@ AND endDate < %@",
                   begin, end1, end2];
  return q;
}

- (EOQualifier *)moreDayAptsQualifier {
  EOQualifier *q;
  NSCalendarDate *s;

  s = [self->day beginOfDay];
  q = [EOQualifier qualifierWithQualifierFormat:
		     @"(startDate < %@) AND (endDate > %@)", s, s];
  return q;
}

- (void)setDataSource:(id)_ds {
  if (self->dataSource == _ds)
    return;

  [super setDataSource:_ds];
  [self->intervalDataSource release];
#if 0 // TODO: explain
  self->intervalDataSource =
    [[EOFilterDataSource alloc] initWithDataSource:_ds];
#else
  self->intervalDataSource =
    [[EOFilterDataSource alloc] initWithDataSource:[self cacheDataSource]];
#endif
  [self->intervalDataSource setSortOrderings:[self sortOrderings]];
}

- (id)intervalDataSource {
  return self->intervalDataSource;
}

- (void)setDay:(NSCalendarDate *)_day {
  ASSIGN(self->day,_day);
}
- (NSCalendarDate *)day {
  return self->day;
}

- (void)setCurrentTime:(NSCalendarDate *)_time {
  if (![_time isEqual:self->currentDate]) {
    RELEASE(self->currentApts); self->currentApts = nil;
    [self setCurrentDate:_time];
  }
}
- (NSCalendarDate *)currentTime {
  return [self currentDate];
}

- (NSArray *)moreDayApts {
  NSArray *ma;

  if (self->moreDayApts)
    return self->moreDayApts;

  [self->intervalDataSource setAuxiliaryQualifier:[self moreDayAptsQualifier]];
  ma = [self->intervalDataSource fetchObjects];
  ASSIGN(self->moreDayApts, ma);
  return self->moreDayApts;
}

- (NSArray *)allDayApts {
  if (self->allDayDates == nil) {
    NSArray *aa;

    [self->intervalDataSource setAuxiliaryQualifier:
         [self allDayAptsQualifier]];
    aa = [self->intervalDataSource fetchObjects];
    ASSIGN(self->allDayDates, aa);
  }
  return self->allDayDates;
}

/* month browser support */

- (NSString *)browserFontColor {
  // TODO: use CSS
  if ([self->browserDate isDateOnSameDay:self->day])
    return @"#FF0000";
  if (!self->browserDateInMonth)
    return @"#555555";
  return @"#000000";
}

/* conditional */

- (BOOL)hasMoreDayApts {
  return ([[self moreDayApts] count] > 0) ? YES : NO;
}
- (BOOL)hasAllDayApts {
  return ([[self allDayApts] count] > 0) ? YES : NO;
}

/* additional accessors */

- (int)secondsFromTimeInterval:(NSTimeInterval)_interval {
  return [[NSNumber numberWithDouble:_interval] intValue];
}

- (NSArray *)listOfTimes {
  // TODO: split up this huge method
  NSArray        *apts;
  NSCalendarDate *firstDate;
  NSCalendarDate *lastDate;
  NSCalendarDate *date;
  double         helper;
  NSMutableArray *times;

  apts = [[self cacheDataSource] fetchObjects];
  //  apts = [self->dataSource fetchObjects];

  // hope that array is time sorted

  firstDate = nil;

  if ([apts count] > 0) {
    int            cnt = 0;
    id             apt;
    NSCalendarDate *d;
    BOOL           hasOneDayApts = NO;
    NSArray        *ma;

    firstDate = [self->day beginOfDay];
    ma        = [self moreDayApts];

    while (cnt < [apts count]) {
      apt = [apts objectAtIndex:cnt++];
      d   = [apt valueForKey:@"startDate"];

      if (!d)
        continue;

      // ignore all day apts
      if ([self isThisAllDayApt:apt])
        continue;
      // to jump over more day apts
      if ([ma containsObject:apt])
        continue;

      firstDate     = d;
      hasOneDayApts = YES;
      break;
    }
    if (!hasOneDayApts) {
      // no one-day apts
      firstDate = [self->day endOfDay];
      lastDate  = [self->day beginOfDay];
    }
    else {
      lastDate = [[apts lastObject] valueForKey:@"startDate"];
    }
  }
  else {
    // to force the next condition to proceed
    firstDate = [self->day endOfDay];
    lastDate  = [self->day beginOfDay];
  }

  helper = self->dayStart;
  if (helper <= ([firstDate hourOfDay]*60 + [firstDate minuteOfHour])) {
    firstDate = [firstDate beginOfDay];
    firstDate =
      [NSCalendarDate dateWithTimeIntervalSince1970:
                      [firstDate timeIntervalSince1970] + helper*60];
  }
  else {
    date = [firstDate beginOfDay];
    helper = [firstDate hourOfDay]*3600 + [firstDate minuteOfHour]*60 +
             [firstDate secondOfMinute];

    while (([date hourOfDay]*3600 + [date minuteOfHour]*60 +
            [date secondOfMinute] + self->interval) <= helper)
      {
        unsigned seconds = (unsigned)self->interval;

        date = [date dateByAddingYears:0 months:0 days:0 hours:0 minutes:0
                     seconds:seconds];
      }
    firstDate = date;
  }

  helper = self->dayEnd;
  if (helper > ([lastDate hourOfDay]*60 + [lastDate minuteOfHour])) {
    lastDate = [lastDate beginOfDay];
    lastDate =
      [NSCalendarDate dateWithTimeIntervalSince1970:
                      [lastDate timeIntervalSince1970] + helper*60];
  }

  [firstDate setTimeZone:[self->day timeZone]];
  [lastDate setTimeZone:[self->day timeZone]];

  times = [NSMutableArray array];

  while ((firstDate != nil) &&
         (([firstDate earlierDate:lastDate] == firstDate) ||
          ([firstDate isEqual:lastDate])))
    {
      unsigned seconds = (unsigned)self->interval;

      [times addObject:firstDate];
      firstDate = [firstDate dateByAddingYears:0 months:0 days:0 hours:0
                             minutes:0 seconds:seconds];
    }

  return times;
}

- (NSArray *)currentAppointments {
  NSArray *apts;

  if (self->currentApts)
    return self->currentApts;

  if (self->currentDate == nil) {
    apts = [self moreDayApts];
  }
  else {
    [self->intervalDataSource setAuxiliaryQualifier:[self intervalQualifier]];
    apts = [self->intervalDataSource fetchObjects];
  }
  ASSIGN(self->currentApts, apts);
  return self->currentApts;
}

- (BOOL)hasCurrentAppointments {
  NSArray *apts;

  apts = [self currentAppointments];
  return ((apts!= nil) && ([apts count] > 0)) ? YES : NO;
}

- (int)rowspanForCurrentTime {
  int rowspan;
  rowspan = [[self currentAppointments] count];
  return (rowspan > 0) ? rowspan : 1;
}

- (int)rowspanForMoreDayApts {
  int rowspan;
  rowspan = [[self moreDayApts] count];
  return (rowspan > 0) ? rowspan : 1;
}

- (int)rowspanForAllDayApts {
  int rowspan;
  rowspan = [[self allDayApts] count];
  return (rowspan > 0) ? rowspan : 1;
}

- (NSString *)labelOfCurrentTime {
  NSString *format;
  format = [self showAMPMDates] ? @"%I:%M %p" : @"%H:%M";
  return [self->currentDate descriptionWithCalendarFormat:format];
}

- (NSCalendarDate *)referenceDateForFormatter {
  return self->day;
}

- (NSFormatter *)aptFullInfoFormatter {
  id f;

  f = [super aptFullInfoFormatter];
  [f setRelationDate:self->day];

  return f;
}

- (NSFormatter *)aptContentFormatter {
  SkyAppointmentFormatter *f;
  NSMutableString         *format;
  id                      res, loc;

  format = [NSMutableString stringWithCapacity:128];

  res = [self->appointment valueForKey:@"resourceNames"];
  loc = [self->appointment valueForKey:@"location"];
  if (![res isNotNull]) res = nil;
  if (![loc isNotNull]) loc = nil;
  if ([res length] == 0 || [res isEqualToString:@" "]) res = nil;
  if ([loc length] == 0 || [loc isEqualToString:@" "]) loc = nil;


  /* GLC we hide some information at user sight */
  /*
  if (loc != nil) [format appendString:@"; %L"];
  [format appendString:@"; %P"];
  if (res != nil) [format appendString:@"; %R"];
  */

  f = [SkyAppointmentFormatter formatterWithFormat:format];
  [f setShowFullNames:[self showFullNames]];
  return f;
}

- (NSFormatter *)aptTimeFormatter {
  SkyAppointmentFormatter *format;

  format = [SkyAppointmentFormatter formatterWithFormat:@"%S - %E; "];
  [format setRelationDate:self->day];
  if ([self showAMPMDates]) [format switchToAMPMTimes:YES];
  return format;
}

- (NSString *)currentDayInfo {
  NSString *info;

  [self setCurrentDate:self->day];
  info = [self holidayInfo];
  [self setCurrentDate:nil];

  return info;
}

- (BOOL)hasHolidays {
  return ([[self currentDayInfo] length]) ? YES : NO;
}

/* key/value coding */

- (void)takeValue:(id)_val forKey:(id)_key {
  if ([_key isEqualToString:@"day"]) {
    [self setDay:_val];
    return;
  }

  [super takeValue:_val forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"day"])
    return [self day];

  return [super valueForKey:_key];
}

@end /* SkyInlineDayOverview */
