/*
  Copyright (C) 2000-2003 SKYRIX Software AG

  This file is part of OGo

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

#include "SkyInlineAptDataSourceView.h"
#include <OGoScheduler/SkyAptDataSource.h>
#include "SkyAppointmentFormatter.h"

@interface SkyInlineWeekColumnView : SkyInlineAptDataSourceView
{
@protected
  char           dayIndex;
  NSCalendarDate *weekStart;
}

@end

@interface NSObject(SkyInlineWeekColumnView_PRIVATE)
- (void)setResources:(id)_resources;
- (void)setParticipantsFromGids:(id)_gids;
@end

#include <OGoFoundation/OGoFoundation.h>
#include <LSFoundation/LSFoundation.h>
#include <NGExtensions/NGExtensions.h>
#include <NGExtensions/EOFilterDataSource.h>
#include <EOControl/EOQualifier.h>
#include <NGMime/NGMimeType.h>
#import <NGObjWeb/NGObjWeb.h>
#import <Foundation/Foundation.h>

@implementation SkyInlineWeekColumnView

+ (int)version {
  return [super version] + 0;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->weekStart);
  [super dealloc];
}
#endif

- (void)setDataSource:(id)_ds {
  if (self->dataSource != _ds) {
    [super setDataSource:_ds];
  }
}

/* accessors */

- (NSArray *)appointments {
  //  return [self->dataSource fetchObjects];
  return [[self cacheDataSource] fetchObjects];
}


- (void)setWeekStart:(NSCalendarDate *)_weekStart {
  ASSIGN(self->weekStart,_weekStart);
}
- (NSCalendarDate *)weekStart {
  return self->weekStart;  
}

- (void)setDayIndex:(char)_idx {
  NSCalendarDate *d;
  
  if ((self->dayIndex == _idx) && (self->currentDate != nil))
    return;

  self->dayIndex = _idx;
  
  if (_idx > 0) {
    d = [[self weekStart]
               dateByAddingYears:0 months:0 days:_idx
               hours:0 minutes:0 seconds:0];
  }
  else
    d = [self weekStart];

  [self setCurrentDate:d];
}
- (char)dayIndex {
  return self->dayIndex;
}
- (NSCalendarDate *)weekday {
  return [self currentDate];
}

// week column view title colors

- (NSString *)titleColor {
  if ([[self currentDate] dayOfWeek] == 6)
    return [[self config] valueForKey:@"colors_sundayHeaderCell"];
  else if ([[self currentDate] dayOfWeek] == 5)
    return [[self config] valueForKey:@"colors_saturdayHeaderCell"];
  else
    return [[self config] valueForKey:@"colors_weekdayHeaderCell"];
}

- (NSString *)dayCellColor {
  id color;

  color  = [[self weekday] isToday]
    ? @"colors_selectedContentCell"
    : @"colors_contentCell";
  color  = [[self config] valueForKey:color];
  
  return color;
}

/* actions */

- (id)newWeekdayAppointment {
  id e = nil;

  [[self session] transferObject:
                  [[self weekday] hour:11 minute:0 second:0] owner:self];
  e = [[self session] instantiateComponentForCommand:@"new"
                      type:[NGMimeType mimeType:@"eo/date"]];

  if (e != nil) {
    [e setResources:[[self dataSource] resources]];
    [e setParticipantsFromGids:[[self dataSource] companies]];
  }

  return e;
}

- (id)dropAction {
  //  NSLog(@"object is %@", [self appointment]);

  return [self droppedAppointment];
}

// dnd support

- (NSCalendarDate *)droppedAptDateWithOldDate:(NSCalendarDate *)_date {
  NSCalendarDate *toDate = [self currentDate];

  return [NSCalendarDate dateWithYear:[toDate yearOfCommonEra]
                         month:[toDate monthOfYear]
                         day:[toDate dayOfMonth]
                         hour:[_date hourOfDay]
                         minute:[_date minuteOfHour]
                         second:[_date secondOfMinute]
                         timeZone:[_date timeZone]];
}


// design of appointment

- (NSString *)startTime {
  NSString       *fm;
  NSCalendarDate *sD, *wD;
  
  fm = [self showAMPMDates] ? @"%I:%M %p" : @"%H:%M";
  sD = [self->appointment valueForKey:@"startDate"];
  wD = [self currentDate];
  
  if (([sD dayOfYear]       <  [wD dayOfYear]) &&
      ([sD yearOfCommonEra] <= [wD yearOfCommonEra])) {
    fm = [fm stringByAppendingString:@"(%m-%d)"];
  }

  if ([sD yearOfCommonEra] < [wD yearOfCommonEra]) {
    fm = [fm stringByAppendingString:@"(%Y-%m-%d)"];
  }
  
  return [sD descriptionWithCalendarFormat:fm];
}

- (NSString *)endTime {
  NSString       *fm;
  NSCalendarDate *eD, *wD;
  
  fm = [self showAMPMDates] ? @"%I:%M %p" : @"%H:%M";
  eD = [self->appointment valueForKey:@"endDate"];
  wD = [self currentDate];
  
  if ([wD dayOfYear] < [eD dayOfYear] &&
      ([eD yearOfCommonEra] >= [wD yearOfCommonEra])) {
    fm = [fm stringByAppendingString:@"(%m-%d)"];
  }

  if ([eD yearOfCommonEra] > [wD yearOfCommonEra]) {
    fm = [fm stringByAppendingString:@"(%Y-%m-%d)"];
  }
  
  return [eD descriptionWithCalendarFormat:fm];
}

- (NSString *)shortTextForApt {
  SkyAppointmentFormatter *f;
  
  f = [SkyAppointmentFormatter formatterWithFormat:
                               @"\n%T;\n%L;\n%5P;\n%50R"];
  [f setShowFullNames:[self showFullNames]];
  
  //  [f setRelationDate:self->day]; ???

  return [NSString stringWithFormat:@"%@:%@ - %@;%@",
                   [self aptTypeLabel],
                   [self startTime],
                   [self endTime],
                   [f stringForObjectValue:self->appointment]];
}

- (NSFormatter *)aptTitleFormatter {
  SkyAppointmentFormatter *format;
  
  format = [SkyAppointmentFormatter formatterWithFormat:@" %50T"];
  //  [format setRelationDate:self->day]; ???
  return format;
}


@end /* SkyInlineWeekColumnView */
