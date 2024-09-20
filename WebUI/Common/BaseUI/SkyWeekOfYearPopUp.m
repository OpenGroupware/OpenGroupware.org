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

#include <OGoFoundation/OGoComponent.h>

@class NSCalendarDate, NSTimeZone;

/*
  a component to generate a PopUp for week-of-year-selection as used in the
  scheduler page.

  Input-Parameters:

    timeZone  - required timeZone
    year      - year as an integer, eg '2000'
  
  Output-Parameters:
    
    weekStart - an NSCalendarDate of the monday of the selected week
*/

@interface SkyWeekOfYearPopUp : OGoComponent
{
  NSCalendarDate *firstMonday;
  short          lastWeek;
  id             item;
}
@end

#include "common.h"

@implementation SkyWeekOfYearPopUp

+ (int)version {
  return 1;
}
- (BOOL)synchronizesVariablesWithBindings {
  return NO;
}

- (void)dealloc {
  RELEASE(self->firstMonday);
  RELEASE(self->item);
  [super dealloc];
}

/* accessors */

- (void)setItem:(id)_item {
  ASSIGN(self->item, _item);
}
- (id)item {
  return self->item;
}

- (NSCalendarDate *)itemDate {
  int dayOffset;

  dayOffset = [self->item intValue] - 1;
  dayOffset *= 7;
  
  return [self->firstMonday dateByAddingYears:0 months:0 days:dayOffset];
}

- (NSString *)itemLabel {
  NSCalendarDate *date;
  static int showYear = -1;
  unsigned year;
  
  if (showYear == -1) {
    showYear = [[NSUserDefaults standardUserDefaults]
                                boolForKey:@"SkyWeekOfYearPopUp_showYear"]
      ? 1 :0;
  }
  
  date       = [self itemDate];
  year       = [date yearOfCommonEra];
  // unused: weekOfYear = [date weekOfYear];
  
  if ([self->item intValue] == 1) {
    short woy, nowy;
    
    woy  = [date weekOfYear];
    nowy = [date numberOfWeeksInYear];
    
    if (woy > nowy)
      year++;
  }
  
  if (showYear) {
    return [NSString stringWithFormat:@"%@: %04i-%02i (%02i-%02i)",
                       [[self labels] valueForKey:@"week"],
                       year,
                       [self->item intValue],
                       [date monthOfYear],
                       [date dayOfMonth]];
  }
  else {
    return [NSString stringWithFormat:@"%@: %02i (%02i-%02i)",
                       [[self labels] valueForKey:@"week"],
                       [self->item intValue],
                       [date monthOfYear],
                       [date dayOfMonth]];
  }
}

- (NSTimeZone *)timeZone {
  NSTimeZone *tz;
  
  if ((tz = [self valueForBinding:@"timeZone"])) {
    //NSLog(@"TZ BINDING: %@", tz);
    return tz;
  }
  
  //NSLog(@"TZ from session: %@", [(id)[self session] timeZone]);
  return [(id)[self session] timeZone];
}

- (void)setWeekStart:(id)_weekStart {
  if (_weekStart) {
    [self setItem:_weekStart];
    [self setValue:[self itemDate] forBinding:@"weekStart"];
  }
}
- (id)weekStart {
  NSCalendarDate *weekStart;
  int woy;

  weekStart = [self valueForBinding:@"weekStart"];
  woy = [weekStart weekOfYear];

  if ([weekStart yearOfCommonEra] !=
      [[self valueForBinding:@"year"] intValue]) {
    // --> weekStart is monday --> must be first week of year !!"
    woy = 1;
  }
  return [NSNumber numberWithInt:woy];
}

/* being the list */

- (unsigned int)count {
  return self->lastWeek;
}
- (id)objectAtIndex:(unsigned int)_idx {
  NSAssert(self->firstMonday, @"missing firstmonday ..");
  return [NSNumber numberWithInt:_idx + 1];
#if 0
  return [self->firstMonday dateByAddingYears:0
                            months:0
                            days:(7 * (_idx))];
#endif
}

/* notifications */

- (void)reconfigure {
  NSCalendarDate *dateInYear;
  id         year, tmp;
  
  year = [self valueForBinding:@"year"];

  //  NSLog(@"Binding value of year is:%@",year);
  
  if (year) {
    dateInYear = [NSCalendarDate dateWithYear:[year intValue] month:6 day:1
                                 hour:0 minute:0 second:0
                                 timeZone:[self timeZone]];
  }
  else {
#if 0
    NSLog(@"MISSING YEAR BINDING ..");
#endif
    dateInYear = [NSCalendarDate calendarDate];
    [dateInYear setTimeZone:[self timeZone]];
  }
  
  RELEASE(self->firstMonday); self->firstMonday = nil;
  self->firstMonday =
    [[dateInYear firstMondayAndLastWeekInYear:&(self->lastWeek)] copy];
  
  tmp = [self valueForBinding:@"weekStart"];
  if ([(NSCalendarDate *)tmp weekOfYear] > self->lastWeek) 
    self->lastWeek = [(NSCalendarDate *)tmp weekOfYear];
  //NSLog(@"WEEK START: %i - %@", [tmp weekOfYear], tmp);
  //if (tmp) [self setWeekStart:[NSNumber numberWithInt:[tmp weekOfYear]]];

#if 0
  NSLog(@"monday=%@, #weeks: %i", self->firstMonday, (int)self->lastWeek);
#endif
}

- (void)syncAwake {
  [super syncAwake];
  [self reconfigure];
}

- (void)sleep {
  [self setItem:nil];
  [super sleep];
}

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  [self reconfigure];
  [super appendToResponse:_response inContext:_ctx];
}

@end /* SkyWeekOfYearPopUp */
