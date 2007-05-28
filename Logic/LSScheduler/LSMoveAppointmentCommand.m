/*
  Copyright (C) 2000-2007 SKYRIX Software AG

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

#include "LSSetAppointmentCommand.h"

@interface LSMoveAppointmentCommand : LSSetAppointmentCommand
{
}

@end

#include "common.h"

@implementation LSMoveAppointmentCommand

- (void)_prepareForExecutionInContext:(id)_context {
  NSCalendarDate *oldStart, *newStart, *newEnd;
  NSString       *logText;

  oldStart = [[self object] valueForKey:@"startDate"];
  newStart = [self valueForKey:@"newStartDate"];
  newEnd   = [self valueForKey:@"newEndDate"];

  if ([oldStart isDateOnSameDay:newStart]) {
    logText =
      [NSString stringWithFormat:@"appointment moved from %@ to %@",
                [oldStart descriptionWithCalendarFormat:@"%H:%M %Z"],
                [newStart descriptionWithCalendarFormat:@"%H:%M %Z"]];
  }
  else {
    logText =
      [NSString stringWithFormat:@"appointment moved from %@ to %@",
                [oldStart descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M %Z"],
                [newStart descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M %Z"]];
  }
  
  [self takeValue:logText  forKey:@"logText"];
  [self takeValue:newStart forKey:@"startDate"];
  [self takeValue:newEnd   forKey:@"endDate"];

  [super _prepareForExecutionInContext:_context];
}

@end /* LSMoveAppointmentCommand */
