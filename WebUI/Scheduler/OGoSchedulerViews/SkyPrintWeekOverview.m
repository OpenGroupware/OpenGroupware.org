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

#include "SkyInlineAptDataSourceView.h"
@class NSCalendarDate;

@interface SkyPrintWeekOverview : SkyInlineAptDataSourceView
{
  int            dayIndex;
  NSCalendarDate *weekStart;
}

@end

#include "SkyAppointmentFormatter.h"
#include "common.h"

@implementation SkyPrintWeekOverview

+ (int)version {
  return [super version] + 0;
}

- (void)dealloc {
  [self->weekStart release];
  [super dealloc];
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

/* formatter */

- (NSFormatter *)appointmentFormatter {
  SkyAppointmentFormatter *f;
  
  f = [SkyAppointmentFormatter printFormatterWithAppointment:self->appointment
			       isViewAccessAllowed:
				 [self appointmentViewAccessAllowed]
			       addTrailingNewline:YES
			       relationDate:[self currentDate]
			       showFullNames:[self showFullNames]];
  return f;
}

/* weekName */

- (NSString *)weekName {
  NSCalendarDate *ws, *we;
  NSString *label;
  
  ws = [self weekStart];
  we = [ws dateByAddingYears:0 months:0 days:7 hours:0 minutes:0 seconds:0];

  if ([ws monthOfYear] == [we monthOfYear]) {
    NSString *month;
    
    month = [ws descriptionWithCalendarFormat:@"%B"];
    label = [NSString stringWithFormat:@"%@ %@",
                      [[self labels] valueForKey:month],
                      [ws descriptionWithCalendarFormat: @"%Y"]];
  }
  else {
    NSString *month1, *month2;

    month1 = [ws descriptionWithCalendarFormat: @"%B"];
    month2 = [we descriptionWithCalendarFormat: @"%B"];
    
    label = [NSString stringWithFormat:@"%@ %@ / %@ %@",
                      [[self labels] valueForKey:month1],
                      [ws descriptionWithCalendarFormat: @"%Y"],
                      [[self labels] valueForKey:month2],
                      [we descriptionWithCalendarFormat: @"%Y"]];
  }
  
  label = [NSString stringWithFormat:@"%@, %@ %i",
                      label,
                      [[self labels] valueForKey:@"week"],
                      [ws weekOfYear]];
  
  return label;
}

@end
