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

@class NSTimeZone;

@interface SkyPrintMonthOverview : SkyInlineAptDataSourceView
{
  int dayOfWeek;
  int year;
  int month;
  int weekOfYear;

  NSTimeZone *tz;
}
@end

#include "SkyAppointmentFormatter.h"
#include "common.h"
#include <OGoScheduler/SkyAptDataSource.h>
#include <OGoFoundation/OGoSession.h>

@implementation SkyPrintMonthOverview

static NSArray *days   = nil;
static NSArray *months = nil;

+ (void)initialize {
  if (days == nil) {
    days =  [[NSArray alloc] initWithObjects:@"Sunday", @"Monday", @"Tuesday",
			       @"Wednesday", @"Thursday", @"Friday", 
			       @"Saturday", nil];
  }
  if (months == nil) {
    months = [[NSArray alloc] initWithObjects:
				@"January", @"February", @"March", @"April",
			        @"May", @"June", @"July", @"August", 
			        @"September", @"October", @"November", 
			        @"December", nil];
  }
}

- (void)dealloc {
  [self->tz release];
  [super dealloc];
}

/* accessors */

- (BOOL)isInMonth {
  return [[self currentDate] monthOfYear] == self->month;
}

- (void)setMonth:(int)_m {
  self->month = _m;
}
- (int)month {
  return self->month;
}

- (void)setYear:(int)_y {
  self->year = _y;
}
- (int)year {
  return self->year;
}

- (void)setWeekOfYear:(int)_w {
  self->weekOfYear = _w;
}
- (int)weekOfYear {
  return self->weekOfYear;
}

- (void)setTimeZone:(NSTimeZone *)_tz {
  ASSIGN(self->tz,_tz);
}
- (NSTimeZone *)timeZone {
  return self->tz;
}

/* additional accessors */

- (NSString *)weekDayString {
  return [days objectAtIndex:self->dayOfWeek];
}
- (NSString *)monthString {
  return [months objectAtIndex:(self->month - 1)];
}

- (BOOL)appointmentViewAccessAllowed {
  NSString *perms;
  
  perms = [self->appointment valueForKey:@"permissions"];
  if ([perms isNotNull])
    return [perms rangeOfString:@"v"].length > 0 ? YES : NO;
  
  return [[self->appointment valueForKey:@"isViewAllowed"] boolValue];
}

- (NSFormatter *)aptFormatter {
  SkyAppointmentFormatter *f;
  
  f = [SkyAppointmentFormatter printFormatterWithAppointment:self->appointment
			       isViewAccessAllowed:
				 [self appointmentViewAccessAllowed]
			       addTrailingNewline:NO
			       relationDate:self->currentDate
			       showFullNames:[self showFullNames]];
  return f;
}

- (void)setDayOfWeek:(int)_day {
  self->dayOfWeek = _day;
}
- (int)dayOfWeek {
  return self->dayOfWeek;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"month"])
    [self setMonth:[_value intValue]];
  else if ([_key isEqualToString:@"year"])
    [self setYear:[_value intValue]];
  else if ([_key isEqualToString:@"timeZone"])
    [self setTimeZone:_value];
  else
    [super takeValue:_value forKey:_key];
}

@end /* SkyPrintMonthOverview */
