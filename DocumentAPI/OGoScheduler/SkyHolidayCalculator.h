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

#ifndef __SkyHolidayCalculator_H__
#define __SkyHolidayCalculator_H__

/*
  SkyHolidayCalculator
    - calculates holdidays for a year
*/

#import <Foundation/Foundation.h>

@class NSTimeZone, NSCalendarDate, NSUserDefaults;

@interface SkyHolidayCalculator : NSObject
{
@protected
  NSUserDefaults *userDefaults;
  
  // currently cached year
  int year;
  // timeZone
  NSTimeZone *timeZone;
  // cache
  NSDictionary   *holidays;
  NSCalendarDate *easter;

  // fixed day cache
  NSCalendarDate *firstMay;
  NSCalendarDate *christmasEve;
  NSCalendarDate *firstAdvent;
}

+ (SkyHolidayCalculator *)calculatorWithYear:(int)_year
  timeZone:(NSTimeZone *)_tz
  userDefaults:(NSUserDefaults *)_ud;
- (id)initWithYear:(int)_year
  timeZone:(NSTimeZone *)_tz
  userDefaults:(NSUserDefaults *)_ud;

- (NSArray *)holidaysOfDate:(NSCalendarDate *)_date;

- (void)setTimeZone:(NSTimeZone *)_tz;
- (NSTimeZone *)timeZone;

- (void)setUserDefaults:(NSUserDefaults *)_ud;
- (NSUserDefaults *)userDefaults;

@end

#endif /* __SkyHolidayCalculator_H__ */
