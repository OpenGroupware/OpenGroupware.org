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

#import "common.h"
#include <LSFoundation/LSBaseCommand.h>

@interface LSMonthCommand : LSBaseCommand
{
@private
  NSCalendarDate *dateInYear;
}

- (void)setDateInYearFromString:(NSString *)_dateInYearString;
- (void)setDateInYear:(NSCalendarDate *)_dateInYear;
- (NSCalendarDate *)dateInYear;

@end

@implementation LSMonthCommand

- (void)dealloc {
  [dateInYear release];
  [super dealloc];
}

/* command methods */

- (void)_executeInContext:(id)_context {
  NSMutableArray *monthDates;
  int            i, lastMonth;
  NSCalendarDate *monthDate;
  
  monthDates = [[NSMutableArray alloc] init];
  lastMonth  = 12;
  monthDate  = self->dateInYear;
    
  for (i = 0; i < lastMonth; i++) {
    NSCalendarDate *date;
    
    date = [monthDate dateByAddingYears:0 months:(i * 1) days:0
                      hours:0 minutes:0 seconds:0];
    [monthDates addObject:date];
  }
  [self setReturnValue:monthDates];
  [monthDates release]; monthDates = nil;
}  

/* accessors */

- (void)setDateInYearFromString:(NSString *)_dateInYearString {
  NSCalendarDate *myDate = nil;
  
  myDate = [NSCalendarDate dateWithString:_dateInYearString
                           calendarFormat:@"%Y-%m-%d %H:%M:%S"];

  [self setDateInYear:myDate];
}

- (void)setDateInYear:(NSCalendarDate *)_dateInYear {
  ASSIGN(dateInYear, _dateInYear);
}
- (NSCalendarDate *)dateInYear {
  return dateInYear;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"dateInYear"]) {
    if ([_value isKindOfClass:[NSCalendarDate class]])
      [self setDateInYear:_value];
    else
      [self setDateInYearFromString:[_value stringValue]];      
  }
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"dateInYear"])
    return [self dateInYear];

  return [super valueForKey:_key];
}

@end /* LSMonthCommand */
