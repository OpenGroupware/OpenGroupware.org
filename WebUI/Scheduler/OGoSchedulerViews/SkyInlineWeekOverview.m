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

@interface SkyInlineWeekOverview : SkyInlineAptDataSourceView
{
@protected
  int            dayIndex;
  NSCalendarDate *weekStart;
}

@end

@interface NSObject(SkyInlineWeekOverview_PRIVATE)
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

@implementation SkyInlineWeekOverview

+ (int)version {
  return [super version] + 0;
}

/* accessors */

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

- (int)dayIndex {
  return self->dayIndex;
}

- (NSCalendarDate *)referenceDateForFormatter {
  return [self currentDate];
}

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

/* actions */

- (id)newWeekdayAppointment {
  id e = nil;

  [[self session] transferObject:
                  [[self currentDate] hour:11 minute:0 second:0] owner:self];
  e = [[self session] instantiateComponentForCommand:@"new"
                      type:[NGMimeType mimeType:@"eo/date"]];

  if (e != nil) {
    [e setResources:[[self dataSource] resources]];
    [e setParticipantsFromGids:[[self dataSource] companies]];
  }

  return e;
}

- (id)personWasDropped:(id)_person {
  [self setCurrentDate:[[self currentDate] hour:11 minute:0 second:0]];

  return [super personWasDropped:_person];
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

@end /* SkyInlineWeekOverview */
