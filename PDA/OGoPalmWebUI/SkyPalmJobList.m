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

#include <OGoPalmUI/SkyPalmEntryList.h>

/*

  a table view for viewing palm jobs

   > subKey    - userDefaultSubKey                    (may be nil)
                 ("SkyPalmJobList_$subKey_$key",
                  $key = "BlockSize"|"SortOrder"|"SortKey"|"Attributes")
   > action    - action for single job                (may be nil)
   
  <  job       - current job in iteration


 */

@interface SkyPalmJobList : SkyPalmEntryList
{}
@end

#include <Foundation/Foundation.h>
#include <OGoFoundation/OGoFoundation.h>
#include <OGoPalm/SkyPalmJobDocument.h>

@implementation SkyPalmJobList

// overwriting
- (NSString *)palmDb {
  return @"ToDoDB";
}
- (NSString *)itemKey {
  return @"job";
}
- (NSString *)updateNotificationName {
  return @"LSWUpdatedPalmJob";
}
- (NSString *)deleteNotificationName {
  return @"LSWDeletedPalmJob";
}
- (NSString *)newNotificationName {
  return @"LSWNewPalmJob";
}
- (NSString *)newDirectActionName {
  return @"newPalmJob";
}
- (NSString *)viewDirectActionName {
  return @"viewPalmJob";
}
- (NSString *)primaryKey {
  return @"palm_todo_id";
}

// values
- (NSString *)stateIcon {
  NSCalendarDate *date    = [NSCalendarDate date];
  NSCalendarDate *duedate = [[self record] valueForKey:@"duedate"];
  [date setTimeZone:[[self session] timeZone]];

  if ([[self record] isArchived])
    return @"led_dark.gif";
  
  return ([(SkyPalmJobDocument *)[self record] isCompleted])
    ? @"led_green.gif"
    : ((duedate == nil) || ([duedate earlierDate:date] == date))
      ? @"led_yellow.gif"
      : @"led_red.gif";
}

- (NSString *)completed {
  NSString *compl;
  compl = ([(SkyPalmJobDocument *)[self record] isCompleted])
    ? @"complete"
    : @"incomplete";
  if ([[self record] isArchived])
    compl = [compl stringByAppendingString:@"_archived"];
  return compl;
}

- (NSString *)duedateColor {
  NSCalendarDate *date = [NSCalendarDate date];
  [date setTimeZone:[[self session] timeZone]];

  return ([[[self record] valueForKey:@"duedate"] earlierDate:date] == date)
    ? @"black"
    : @"red";
}

- (NSString *)priority {
  static NSDictionary *ps = nil;

  if (ps == nil) {
    ps =
      [[NSDictionary alloc] initWithObjectsAndKeys:
                            @"pri_very_high", [NSNumber numberWithInt:1],
                            @"pri_hight",     [NSNumber numberWithInt:2],
                            @"pri_normal",    [NSNumber numberWithInt:3],
                            @"pri_low",       [NSNumber numberWithInt:4],
                            @"pri_very_low",  [NSNumber numberWithInt:5],
                            nil];
  }
  return [ps objectForKey:[[self record] valueForKey:@"priority"]];
}

- (id)viewSkyrixRecord {
  id gid = nil;

  gid = [[[self record] skyrixRecord] valueForKey:@"globalID"];

  if (gid) {
    [[self session] transferObject:gid owner:self];
    [self executePasteboardCommand:@"view"];
  }

  return nil;
}

@end
