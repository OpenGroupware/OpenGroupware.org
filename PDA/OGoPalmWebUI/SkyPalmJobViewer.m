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

#include <OGoPalmUI/SkyPalmEntryViewer.h>

@interface SkyPalmJobViewer : SkyPalmEntryViewer
{
}

@end /* SkyPalmJobViewer */

#import <Foundation/Foundation.h>
#include <OGoPalm/SkyPalmJobDocument.h>
#include <OGoFoundation/OGoFoundation.h>

@implementation SkyPalmJobViewer

// overwriting
- (NSString *)updateNotificationName {
  return @"LSWUpdatedPalmJob";
}
- (NSString *)deleteNotificationName {
  return @"LSWDeletedPalmJob";
}
- (NSString *)palmDb {
  return @"ToDoDB";
}
- (NSString *)entityName {
  return @"palm_todo";
}

// accessors
- (id)palmJob {
  return [self object];
}

- (NSString *)complete {
  return ([[self palmJob] isCompleted])
    ? @"bool_yes" : @"bool_no";
}

- (NSString *)priority {
  return [[self palmJob] priorityString];
}

- (NSString *)duedateColor {
  NSCalendarDate *date = [NSCalendarDate date];
  [date setTimeZone:[(id)[self session] timeZone]];

  return ([[[self palmJob] valueForKey:@"duedate"] earlierDate:date] == date)
    ? @"black"
    : @"red";
}

// actions
- (id)completeJob {
  if ([[self palmJob] completeJob] == nil)
    return [self back];
  return nil;
}
- (id)uncompleteJob {
  if ([[self palmJob] uncompleteJob] == nil)
    return [self back];
  return nil;
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

@end /* SkyPalmJobViewer */
