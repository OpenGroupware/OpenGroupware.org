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

#include <OGoPalmUI/SkyPalmEntryList.h>

/*
  a table view for viewing palm dates

  > subKey       - userDefaultSubKey                      (may be nil)
  > action       - action for single job                  (may be nil)

  < date         - current address in iteration

 */

#define REPEAT_TYPE_NONE             0
#define REPEAT_TYPE_DAILY            1
#define REPEAT_TYPE_WEEKLY           2
#define REPEAT_TYPE_MONTHLY_BY_DAY   3
#define REPEAT_TYPE_MONTHLY_BY_DATE  4
#define REPEAT_TYPE_YEARLY           5
  
@interface SkyPalmDateList : SkyPalmEntryList
{}
@end

#import <Foundation/Foundation.h>
#include <OGoPalm/SkyPalmDateDocument.h>
#include <NGExtensions/NSCalendarDate+misc.h>

@implementation SkyPalmDateList

// overwriting
- (NSString *)palmDb {
  return @"DatebookDB";
}
- (NSString *)itemKey {
  return @"date";
}
- (NSString *)updateNotificationName {
  return @"LSWUpdatedPalmDate";
}
- (NSString *)deleteNotificationName {
  return @"LSWDeletedPalmDate";
}
- (NSString *)newNotificationName {
  return @"LSWNewPalmDate";
}
- (NSString *)newDirectActionName {
  return @"newPalmDate";
}
- (NSString *)viewDirectActionName {
  return @"viewPalmDate";
}
- (NSString *)primaryKey {
  return @"palm_date_id";
}

// values
- (NSString *)frequencyLabel:(int)_freq {
  int      tmp    = _freq;
  NSString *label = nil;

  _freq %= 100;
  if ((_freq == 11) || (_freq == 12) || (_freq == 13)) {
    label = [[self labels] valueForKey:@"frequencyTH"];
  }
  else {
    _freq %= 10;
    switch (_freq) {
      case 1:
        label = [[self labels] valueForKey:@"frequencyST"];
        break;
      case 2:
        label = [[self labels] valueForKey:@"frequencyND"];
        break;
      case 3:
        label = [[self labels] valueForKey:@"frequencyRD"];
        break;
      default:
        label = [[self labels] valueForKey:@"frequencyTH"];
        break;
    }
  }
  return [NSString stringWithFormat:@"%i%@", tmp, label];
}
- (NSString *)repeatFrequencyLabel:(int)_freq {
  if (_freq == 1)
    return [[self labels] valueForKey:@"frequencyFirst"];
  if (_freq == 2)
    return [[self labels] valueForKey:@"frequencySecond"];
  
  return [self frequencyLabel:_freq];
}
- (NSString *)monthByDayFrequencyLabel:(int)_freq {
  if (_freq == 5)
    return [[self labels] valueForKey:@"frequencyLast"];
  return [self frequencyLabel:_freq];
}

- (NSString *)weekdayLabel:(int)_day {
  NSString *weekday = nil;
  weekday = [NSString stringWithFormat:@"weekday_short_%i", _day];
  weekday = [[self labels] valueForKey:weekday];
  return weekday;
}

- (NSString *)monthLabel:(int)_month {
  NSString *month = nil;
  month = [NSString stringWithFormat:@"month_%i", _month];
  month = [[self labels] valueForKey:month];
  return month;
}

- (NSString *)weekdayListing:(NSArray *)weekdays {
  int      count    = [weekdays count];
  int      pos      = 0;
  id       weekday  = nil;
  NSString *listing = @"";

  while (pos < count) {
    weekday = [weekdays objectAtIndex:pos++];
    weekday = [self weekdayLabel:[weekday intValue]];
    if (pos != 1) {
      if (pos == count)
        listing = [listing stringByAppendingFormat:@" %@ ",
                           [[self labels] valueForKey:@"and"]];
      else
        listing = [listing stringByAppendingString:@", "];
    }
    listing = [listing stringByAppendingString:weekday];
  }

  return listing;
}

- (NSArray *)weekdays:(int)_repeaton {
  int            tmp = _repeaton;
  int            cnt = 0;
  NSMutableArray *ma = [NSMutableArray array];

  for (cnt = 0; cnt < 7; cnt++) {
    if ((tmp & 1) == 1) {
      [ma addObject:[NSNumber numberWithInt:cnt]];
    }
    tmp >>= 1;
  }
  return ma;
}

- (NSString *)repeatText {
  int            repeatType  = 0;
  int            repeatFreq  = 0;
  int            repeatOn    = 0;
  int            week        = 0;
  int            day         = 0;
  int            month       = 0;
  NSString       *repeatText = nil;
  NSCalendarDate *date       = nil;
  
  SkyPalmDateDocument *rec = (SkyPalmDateDocument *)[self record];

  repeatType = [rec repeatType];
  repeatFreq = [rec repeatFrequency];

  switch (repeatType) {
    case REPEAT_TYPE_DAILY:
      repeatText = [[self labels] valueForKey:@"repeatDailyFormat"];
      repeatText = [NSString stringWithFormat:repeatText,
                             [self repeatFrequencyLabel:repeatFreq]];
      break;
    case REPEAT_TYPE_WEEKLY:
      repeatOn = [rec repeatOn];
      
      repeatText = [[self labels] valueForKey:@"repeatWeeklyFormat"];
      repeatText = [NSString stringWithFormat:repeatText,
                             [self repeatFrequencyLabel:repeatFreq],
                             [self weekdayListing:[self weekdays:repeatOn]]];

      break;
    case REPEAT_TYPE_MONTHLY_BY_DAY:
      repeatOn = [rec repeatOn];
      week     = repeatOn / 7 + 1;
      day      = repeatOn % 7;

      repeatText = [[self labels] valueForKey:@"repeatMonthlyByDayFormat"];
      repeatText = [NSString stringWithFormat:repeatText,
                             [self monthByDayFrequencyLabel:week],
                             [self weekdayLabel:day],
                             [self repeatFrequencyLabel:repeatFreq]];
      break;
    case REPEAT_TYPE_MONTHLY_BY_DATE:
      date = [[self record] valueForKey:@"startdate"];
      day  = [date dayOfMonth];
      
      repeatText = [[self labels] valueForKey:@"repeatMonthlyByDateFormat"];
      repeatText = [NSString stringWithFormat:repeatText,
                             [self frequencyLabel:day],
                             [self repeatFrequencyLabel:repeatFreq]];
      break;
    case REPEAT_TYPE_YEARLY:
      date  = [[self record] valueForKey:@"startdate"];
      month = [date monthOfYear];
      day   = [date dayOfMonth];

      repeatText = [[self labels] valueForKey:@"repeatYearlyFormat"];
      repeatText = [NSString stringWithFormat:repeatText,
                             [self frequencyLabel:day],
                             [self monthLabel:month],
                             [self repeatFrequencyLabel:repeatFreq]];
      break;
    default:
      repeatText = [[self labels] valueForKey:@"repeatNoneFormat"];
  }
  return repeatText;
}

- (NSString *)timeText {
  NSCalendarDate *start;
  NSCalendarDate *end;

  start = [(SkyPalmDateDocument *)[self record] startdate];
  
  if ([(SkyPalmDateDocument *)[self record] isUntimed]) {
    return [start descriptionWithCalendarFormat:@"%Y-%m-%d"];
  }

  end = [(SkyPalmDateDocument *)[self record] enddate];

  if ([start isDateOnSameDay:end])
    return [NSString stringWithFormat:@"%@ - %@",
                     [start descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M"],
                     [end   descriptionWithCalendarFormat:@"%H:%M"]];
  if ([start yearOfCommonEra] == [end yearOfCommonEra])
    return [NSString stringWithFormat:@"%@ - %@",
                     [start descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M"],
                     [end   descriptionWithCalendarFormat:@"%m-%d %H:%M"]];

    return [NSString stringWithFormat:@"%@ - %@",
                     [start descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M"],
                     [end   descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M"]];
}

@end
