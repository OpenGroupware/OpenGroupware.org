/*
  Copyright (C) 2005 SKYRIX Software AG

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

#include "NSCalendarDate+OGoScheduler.h"
#include "common.h"

@implementation NSCalendarDate(OGoScheduler)

/*
    eg: "2005-01-03 00:00:00 +0100", cw = 1 => 1, 2005
    
    This is supposed to set the proper tab info, I suppose for monday of week.
    Eg if the monday is in the last year, what should the year/month tab show?
    I guess the "new" year, not the last one.
    
    This is probably the reason for "year + 1" (which does not properly work
    currently).
    
    NOTE: the first week of a year is NOT necessarily the first week containing
          days of the new year! I think the rule (check NGExtensions!) is that
	  the week belongs to the year with most days in the week.
	  TODO: might be culture specific.
*/

#warning BROKEN, RETURNS 2006

- (BOOL)isFirstWeekOfYear {
  /* is it the first week in the year? */
  int cw;
  
  cw = [self bestWeekForWeekView];
  [self logWithFormat:@"WEEK: %i", cw];
  return (cw < 2) ? YES : NO;
}
- (BOOL)isYearTransitionWeek {
  /* 'self' is supposed to be the monday! */
  NSCalendarDate *lastDay;
  
  lastDay = [self dateByAddingYears:0 months:0 days:7
		  hours:0 minutes:0 seconds:-1];
  [self logWithFormat:@"COMPARE: %@ with %@", self, lastDay];
  return [self yearOfCommonEra] != [lastDay yearOfCommonEra] ? YES : NO;
}

- (int)bestMonthForWeekView:(NSCalendarDate *)_weekStart {
  if (_weekStart == nil) _weekStart = self;
  return [_weekStart isYearTransitionWeek] ? 1 : [self monthOfYear];
}
- (int)bestYearForWeekView:(NSCalendarDate *)_weekStart {
  if (_weekStart == nil) _weekStart = self;
  
  if ([_weekStart isYearTransitionWeek]) {
    /* the week being displayed is a transition week */
    
    /* now we need to check whether the week begins on the first */
    
    // Note: _weekStart might be in the _old_ year
    [self logWithFormat:@"IS TRANSITION WEEK: %@", _weekStart];
    
    return [self yearOfCommonEra] + 1;
  }
  else
    [self logWithFormat:@"IS NOT TRANSITION: %@", _weekStart];
  
  return [self yearOfCommonEra];
}

- (int)bestWeekForWeekView {
  NSCalendarDate *d;
  int woy, nowy;
  
  // TODO: document what this does
  d    = self;
  woy  = [d weekOfYear];
  nowy = [d numberOfWeeksInYear];
  if (woy > nowy) {
    // TODO: does it patch the year on week overflow?
    d   = [d dateByAddingYears:0 months:0 days:7
	     hours:0 minutes:0 seconds:0];
    woy = [d weekOfYear] - 1;
  }
  return woy;
}

@end /* NSCalendarDate(OGoScheduler) */
