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

#include "SkyAptAction.h"
#import <Foundation/Foundation.h>
#include <LSFoundation/LSFoundation.h>
#include <NGExtensions/NGExtensions.h>
#include <EOControl/EOSortOrdering.h>

@implementation SkyAptAction(Conflicts)

- (int)_conflictDayForItem:(int)_i appointment:(id)_apt {
  NSCalendarDate *startDate;
  NSCalendarDate *testDate;
  
  startDate = [_apt valueForKey:@"startDate"];
  testDate  = [startDate dateByAddingYears:0 months:0
                         days:(_i * 1) hours:0 minutes:0 seconds:0];
  return [testDate dayOfWeek];
}
- (NSArray *)_conflictAptDates:(id)_apt {
  int                 i          = 1;
  BOOL                cycleEnd   = NO;
  BOOL                isWeekend  = NO;
  NSString            *type      = nil;
  NSCalendarDate      *sD        = nil;
  NSCalendarDate      *eD        = nil;
  NSCalendarDate      *cycleDate = nil;
  NSMutableArray      *apts      = nil;
  id                  apt        = nil;
  NSTimeZone          *tz        = nil;
  id                  dateId;

  
  apt    = _apt;
  type   = [apt valueForKey:@"type"];
  sD     = [apt valueForKey:@"startDate"];
  eD     = [apt valueForKey:@"endDate"];
  tz     = [sD timeZone];

  dateId = [apt valueForKey:@"dateId"];
  
  apts = [NSMutableArray arrayWithCapacity:32];

  {
    NSMutableDictionary *a = nil;

    a = [NSMutableDictionary dictionaryWithCapacity:2];
    
    [a setObject:sD forKey:@"startDate"];
    [a setObject:eD forKey:@"endDate"];

    if ([dateId isNotNull])
      [a setObject:dateId forKey:@"dateId"];
    
    [apts addObject:a]; 

    if ([[apt valueForKey:@"setAllCyclic"] boolValue]) {
      [apts addObjectsFromArray:[apt valueForKey:@"cyclics"]];
      return apts;
    }
  }
  
  if (type != nil && (![dateId isNotNull])) {
    cycleDate = [[apt valueForKey:@"cycleEndDate"] endOfDay];
    while (cycleEnd == NO) {
      NSCalendarDate *newStartDate = nil;
      NSCalendarDate *newEndDate   = nil;

      if ([type isEqual:@"daily"]) {
        newStartDate = [sD dateByAddingYears:0 months:0 days:i*1];
        newEndDate   = [eD dateByAddingYears:0 months:0 days:i*1];
      }
      else if ([type isEqual:@"weekday"]) {
        int day  = [self _conflictDayForItem:i appointment:apt];

        newStartDate = [sD dateByAddingYears:0 months:0 days:i*1];
        newEndDate   = [eD dateByAddingYears:0 months:0 days:i*1];
      
        if (day > 0 && day < 6) {
          isWeekend = NO;
        }
        else
          isWeekend = YES;
      }
      else if ([type isEqual:@"weekly"]) {
        newStartDate = [sD dateByAddingYears:0 months:0 days:i*7];
        newEndDate   = [eD dateByAddingYears:0 months:0 days:i*7];
      }
      else if ([type isEqual:@"14_daily"]) {
        newStartDate = [sD dateByAddingYears:0 months:0 days:i*14];
        newEndDate   = [eD dateByAddingYears:0 months:0 days:i*14];
      }
      else if ([type isEqual:@"4_weekly"]) {
        newStartDate = [sD dateByAddingYears:0 months:0 days:i*28];
        newEndDate   = [eD dateByAddingYears:0 months:0 days:i*28];
      }
      else if ([type isEqual:@"monthly"]) {
        newStartDate = [sD dateByAddingYears:0 months:i*1 days:0];
        newEndDate   = [eD dateByAddingYears:0 months:i*1 days:0];
      }
      else if ([type isEqual:@"yearly"]) {
        newStartDate = [sD dateByAddingYears:i*1 months:0 days:0];
        newEndDate   = [eD dateByAddingYears:i*1 months:0 days:0];
      }
      if ([newStartDate compare:cycleDate] == NSOrderedAscending) {
        if (!isWeekend) {
          NSMutableDictionary *a = nil;

          a = [NSMutableDictionary dictionaryWithCapacity:2];
          [a setObject:newStartDate forKey:@"startDate"];
          [a setObject:newEndDate forKey:@"endDate"];
          [apts addObject:a];
        }
        i++;
      }
      else {
        cycleEnd = YES;
      }

      if (i > 100) {
        cycleEnd = YES;
      }
    }
  }
  return apts;
}

- (NSArray *)conflictGIDsForAppointment:(id)_apt {
  NSTimeZone     *tz;
  NSCalendarDate *startDate, *endDate;
  NSArray        *a;
  NSArray        *aptDates;
  NSArray        *participants;
  NSDictionary   *args;
  NSMutableArray *cs;
  id  apt;
  int i, cnt;
    
  apt  = _apt;
  cs   = [NSMutableArray array];
    
  if ((![[apt valueForKey:@"isConflictDisabled"] boolValue]) &&
      (![[apt valueForKey:@"isWarningIgnored"] boolValue])) {
    NSString *resourceNames = nil;

    aptDates = [self _conflictAptDates:apt];
      
    resourceNames = [apt valueForKey:@"resourceNames"];
      
    a = (![resourceNames isNotNull])
      ? [NSArray array]
      : [resourceNames componentsSeparatedByString:@", "];
      
    participants = [apt valueForKey:@"participants"];
      
    for (i = 0, cnt = [aptDates count]; i < cnt; i++) {

      apt = [aptDates objectAtIndex:i];
        
      startDate = [apt valueForKey:@"startDate"]; 
      endDate   = [apt valueForKey:@"endDate"];
      if (i == 0) tz = [startDate timeZone];


      if ([apt valueForKey:@"dateId"] != nil) {
        args = [NSDictionary dictionaryWithObjectsAndKeys:
                             AUTORELEASE([startDate copy]), @"begin",
                             AUTORELEASE([endDate copy]),   @"end",
                             participants                 , @"staffList",
                             [NSNumber numberWithBool:YES], @"fetchGlobalIDs",
                             a,                             @"resourceList",
                             apt,                           @"appointment",
                             nil];
      }
      else {
        args = [NSDictionary dictionaryWithObjectsAndKeys:
                             AUTORELEASE([startDate copy]), @"begin",
                             AUTORELEASE([endDate copy]),   @"end",
                             participants,                  @"staffList",
                             [NSNumber numberWithBool:YES], @"fetchGlobalIDs",
                             a,                             @"resourceList",
                             nil];
      }
      [cs addObjectsFromArray:
          [[self commandContext]
                 runCommand:@"appointment::conflicts" arguments:args]];
    }
  }
  return cs;
}


@end /* SkyAptAction(Conflicts) */
