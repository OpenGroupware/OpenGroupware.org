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

#include "SkyPalmDateChartViews.h"
#import <Foundation/Foundation.h>
#include <OGoFoundation/LSWSession.h>

@interface SkyPalmDateChartViews(PrivatMethods)
- (void)setDay:(NSCalendarDate *)_day;
@end

@implementation SkyPalmDateChartViews

- (id)init {
  if ((self = [super init])) {
    NSCalendarDate *d;

    // setting time values
    self->tz = [[(id)[self session] timeZone] copy];
    d = [NSCalendarDate calendarDate];
    [d setTimeout:self->tz];
    [self setDay:_d];

    ...
  }
  return self;
}

// accessors
// internal
- (void)_setDay:(NSCalendarDate *)_day {
  ASSIGN(self->day,_day);
}
- (void)_setWeekStart:(NSCalendarDate *)_start {
  ASSIGN(self->weekStart,_start);
}

// external
- (void)setDay:(NSCalendarDate *)_day {
  [_day setTimezone:self->tz];
  [self _setDay:_day];
  [self _setWeekStart:[_day mondayOfWeek]];
}

...


@end /* SkyPalmDateChartViews */
