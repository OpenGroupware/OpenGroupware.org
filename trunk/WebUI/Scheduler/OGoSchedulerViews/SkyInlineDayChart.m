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

@class NSCalendarDate;

@interface SkyInlineDayChart : SkyInlineAptDataSourceView
{
@protected
  NSCalendarDate *day;
  
  // config
  NSTimeInterval interval;
  NSTimeInterval dayStart;
  NSTimeInterval dayEnd;
  int            maxInfoLength;
  BOOL           isPadColumn;
}

@end

#include <OGoScheduler/SkyAptDataSource.h>
#include "SkyAppointmentFormatter.h"
#include <OGoFoundation/WOComponent+config.h>
#include <OGoFoundation/OGoSession.h>
#include <OGoFoundation/OGoNavigation.h>
#include <OGoFoundation/WOComponent+Commands.h>
#include <LSFoundation/LSCommandContext.h>
#include <NGExtensions/NGExtensions.h>
#include <NGMime/NGMimeType.h>
#include "common.h"

@implementation SkyInlineDayChart

- (id)init {
  if ((self = [super init])) {
    // TODO: do not query session in -init ! (no good ...)
    self->maxInfoLength =
      [[(id)[self session] userDefaults]
              integerForKey:@"scheduler_daychart_maxaptinfolength"];
  }
  return self;
}

- (void)dealloc {
  [self->day release];
  [super dealloc];
}

/* notifications */

- (void)syncAwake {
  NSUserDefaults *ud;
  
  ud = (id)[(id)[self session] userDefaults];
  self->interval =
    [[ud objectForKey:@"scheduler_dayoverview_timeinterval"] doubleValue];
  self->dayStart =
    [[ud objectForKey:@"scheduler_dayoverview_daystart"] doubleValue];
  self->dayEnd =
    [[ud objectForKey:@"scheduler_dayoverview_dayend"] doubleValue];
  [self setCurrentDate:nil];
  [super syncAwake];
}

/* accessors */

- (void)setDay:(NSCalendarDate *)_day {
  ASSIGN(self->day,_day);
}
- (NSCalendarDate *)day {
  return self->day;
}

- (void)setCurrentTime:(NSCalendarDate *)_time {
  if (![_time isEqual:self->currentDate]) {
    [self setCurrentDate:_time];
  }
}
- (NSCalendarDate *)currentTime {
  return [self currentDate];
}

- (void)setIsPadColumn:(BOOL)_flag {
  self->isPadColumn = _flag;
}
- (BOOL)isPadColumn {
  return self->isPadColumn;
}

/* month browser support */

- (NSString *)browserFontColor {
  if ([self->browserDate isDateOnSameDay:self->day])
    return @"#FF0000";
  if (!self->browserDateInMonth)
    return @"#555555";
  return @"#000000";
}

/* additional accessors */

- (int)secondsFromTimeInterval:(NSTimeInterval)_interval {
  return [[NSNumber numberWithDouble:_interval] intValue];
}

- (NSArray *)listOfTimes {
  NSArray        *apts;
  NSCalendarDate *firstDate;
  NSCalendarDate *lastDate;
  NSCalendarDate *date;
  double         helper;
  NSMutableArray *times;

  //  apts = [self->dataSource fetchObjects];
  apts = [[self cacheDataSource] fetchObjects];

  // hope that array is time sorted
  if ([apts count] > 0) {
    unsigned       cnt = 0;
    id             apt;
    NSCalendarDate *d;
    BOOL           hasOneDayApts = NO;

    firstDate = [self->day beginOfDay];
    
    while (cnt < [apts count]) {
      apt = [apts objectAtIndex:cnt++];
      d   = [apt valueForKey:@"startDate"];
      // to jump over more day apts
      if (([d earlierDate:firstDate] == firstDate) ||
          ([d isEqual:firstDate])) {
        firstDate = d;
        hasOneDayApts = YES;
        break;
      }
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
  if (helper < ([firstDate hourOfDay]*60 + [firstDate minuteOfHour])) {
    firstDate = [firstDate beginOfDay];
    firstDate =
      [NSCalendarDate dateWithTimeIntervalSince1970:
                      [firstDate timeIntervalSince1970] + helper*60];
  }
  else {
    date = [firstDate beginOfDay];
    helper = [firstDate hourOfDay]*3600 + [firstDate minuteOfHour]*60 +
             [firstDate secondOfMinute];
    
    while ((([date hourOfDay] * 3600) + ([date minuteOfHour] * 60) +
            [date secondOfMinute] + self->interval) <= helper) {
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
                      [lastDate timeIntervalSince1970] + (helper * 60)];
  }

  [firstDate setTimeZone:[self->day timeZone]];
  [lastDate setTimeZone:[self->day timeZone]];
  
  times = [NSMutableArray array];
    
  while (([firstDate earlierDate:lastDate] == firstDate) ||
         ([firstDate isEqual:lastDate])) {
    unsigned seconds = (unsigned)self->interval;

    [times addObject:firstDate];
    firstDate = [firstDate dateByAddingYears:0 months:0 days:0 hours:0
			   minutes:0 seconds:seconds];
  }
  
  return times;
}

- (NSString *)labelOfCurrentTime {
  NSString *format;
  format = [self showAMPMDates] ? @"%I:%M %p" : @"%H:%M";
  return [self->currentDate descriptionWithCalendarFormat:format];
}

- (NSCalendarDate *)referenceDateForFormatter {
  return self->day;
}

- (NSTimeInterval)slotSize {
  return self->interval;
}

- (BOOL)isAppointmentInCell {
  NSTimeInterval start, end;
  NSTimeInterval aptStart, aptEnd;
  id item;

  if ([[self valueForKey:@"isPadColumn"] boolValue])
    return NO;
  
  item = self->appointment;
  
  start = [self->currentDate timeIntervalSince1970];
  end   = start + [self slotSize] - 1;
  
  aptStart =
    [[item valueForKey:@"startDate"] timeIntervalSince1970];
  aptEnd   =
    [[item valueForKey:@"endDate"]   timeIntervalSince1970] - 2;

#if HEAVY_LOG
  NSLog(@"apt %@ %@ active at %@ ?",
        [self->appointment valueForKey:@"title"],
        [self->appointment valueForKey:@"startDate"],
        self->currentDate);
#endif
  
  if (aptStart >= end)
    return NO;
  if (aptEnd < start)
    return NO;
  
  return YES;
}

- (NSFormatter *)aptInfoFormatter {
  NSString *format;
  
  format = [NSString stringWithFormat:@"%%%dT", self->maxInfoLength];
  
  return [SkyAppointmentFormatter formatterWithFormat:format];
}

@end /* SkyInlineDayChart */
