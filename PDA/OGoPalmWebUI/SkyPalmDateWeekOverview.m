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

#include <OGoPalmUI/SkyPalmDataSourceViewer.h>

@class NSArray;

@interface SkyPalmDateWeekOverview : SkyPalmDataSourceViewer
{
  int     dayIndex;
  NSArray *events;
  int     eventIndex;
}

@end

#import <Foundation/Foundation.h>
#include <NGExtensions/NGExtensions.h>
#include <NGExtensions/EOFilterDataSource.h>
#include <EOControl/EOControl.h>

@implementation SkyPalmDateWeekOverview

- (id)init {
  if ((self = [super init])) {
    self->events = nil;
  }
  return self;
}

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

// accessors
- (void)setDayIndex:(int)_idx {
  self->dayIndex = _idx;
  RELEASE(self->events);  self->events = nil;
}
- (int)dayIndex {
  return self->dayIndex;
}
- (void)setEventIndex:(int)_idx {
  self->eventIndex = _idx;
}
- (int)eventIndex {
  return self->eventIndex;
}

// additional
- (NSArray *)sortOrderings {
  return nil;
}
- (NSTimeZone *)timeZone {
  return [self valueForBinding:@"timeZone"];
}
- (NSCalendarDate *)weekStart {
  return [self valueForBinding:@"weekStart"];
}
- (NSCalendarDate *)currentDate {
  NSCalendarDate *date = [self weekStart];
  return [date dateByAddingYears:0 months:0 days:self->dayIndex];
}

// config
- (NSString *)titleColor {
  NSString *color;
  
  if (self->dayIndex == 6)
    color = @"colors_sundayHeaderCell";
  else if (self->dayIndex == 5)
    color = @"colors_saturdayHeaderCell";
  else
    color = @"colors_weekdayHeaderCell";

  return [[self config] valueForKey:color];
}

- (NSString *)contentColor {
  id color;

  color  = [[self currentDate] isToday]
    ? @"colors_selectedContentCell"
    : @"colors_contentCell";
  color  = [[self config] valueForKey:color];
  
  return color;
}

// labels
- (NSString *)currentWeekdayLabel {
  int idx = self->dayIndex;
  idx = (idx == 6) ? 0 : idx + 1;
  return [NSString stringWithFormat:@"weekday_long_%i", idx];
}

// events
- (EOQualifier *)eventOfDayQualifier {
  NSCalendarDate *s, *e;
  s = [self currentDate];
  e = [s dateByAddingYears:0 months:0 days:1];
  return
    [EOQualifier qualifierWithQualifierFormat:
                 @"is_untimed=1 AND (startdate > %@ OR startdate = %@) "
                 @"AND startdate < %@", s, s, e];
}
- (EOQualifier *)noEventQualifier {
  return [EOQualifier qualifierWithQualifierFormat:@"is_untimed=0"];
}
- (NSArray *)eventsOfDay {
  if (self->events == nil) {
    EOFilterDataSource *eventDs;
    eventDs =
      [[EOFilterDataSource alloc] initWithDataSource:[self dataSource]];
    [eventDs setSortOrderings:[self sortOrderings]];
    [eventDs setAuxiliaryQualifier:[self eventOfDayQualifier]];
    self->events = [eventDs fetchObjects];
    RETAIN(self->events);
  }
  return self->events;
}
- (NSArray *)recordsWithoutEvents {
  EOFilterDataSource *ds;
  ds =
    [[EOFilterDataSource alloc] initWithDataSource:[self dataSource]];
  [ds setSortOrderings:[self sortOrderings]];
  [ds setAuxiliaryQualifier:[self noEventQualifier]];
  return [ds fetchObjects];
}
- (BOOL)hasDayEvents {
  NSArray *ev = [self eventsOfDay];
  return (ev == nil)
    ? NO
    : (([ev count] == 0)
       ? NO : YES);
}


@end /* SkyPalmDateWeekOverview */
