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

#include <OGoFoundation/LSWEditorPage.h>

@class NSString, NSArray;

@interface SkyAptResourceEditor : LSWEditorPage
{
  NSString *notificationTime;
  id       item;
  NSArray  *categories;
  id       category;
  NSString *categoryName;
}

- (void)setNotificationTime:(NSString *)_time;

@end

#include "common.h"
#include <GDLExtensions/GDLExtensions.h>
#include <LSFoundation/LSFoundation.h>
#include <OGoFoundation/OGoFoundation.h>

@implementation SkyAptResourceEditor

- (void)dealloc {
  [self->notificationTime release];
  [self->item             release];
  [self->category         release];
  [self->categories       release];
  [self->categoryName     release];
  [super dealloc];
}

- (BOOL)prepareForActivationCommand:(NSString *)_c type:(NGMimeType *)_t
  configuration:(NSDictionary *)_cfg 
{
  self->categories = 
    [[self runCommand:@"appointmentresource::categories", nil] retain];
  
  return [super prepareForActivationCommand:_c type:_t configuration:_cfg];
}

- (BOOL)prepareForEditCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  id       aptResource;
  NSString *string     =  nil;
  
  aptResource = [self object];
  NSAssert(aptResource, @"no object available");

  /* notification time */

  if ([aptResource valueForKey:@"notificationTime"] != nil) {
    NSString *time;

    time = [[aptResource valueForKey:@"notificationTime"] stringValue];
    [self setNotificationTime:time];
  }
  string = [aptResource valueForKey:@"category"];

  if (string != nil) {
    id           obj         = nil;
    NSEnumerator *enumerator = nil;

    enumerator = [self->categories objectEnumerator];
    while ((obj = [enumerator nextObject])) {
      if ([obj isEqualToString:string] == YES) {
        ASSIGN(self->category, obj);
        break;
      }
    }
  }
  [self->categoryName release]; self->categoryName = nil;
  return YES;
}

// accessors

- (id)aptResource {
  return [self snapshot];
}

- (void)setNotificationTime:(NSString *)_time {
  ASSIGN(self->notificationTime, _time);
}
- (NSString *)notificationTime {
  return self->notificationTime;
}

- (void)setItem:(id)_item {
  ASSIGN(self->item, _item);
}
- (id)item {
  return self->item;
}

/* notifications */

- (NSString *)insertNotificationName {
  return @"LSWNewAptResourceNotification";
}
- (NSString *)updateNotificationName {
  return @"LSWUpdatedAptResourceNotification";
}
- (NSString *)deleteNotificationName {
  return @"LSWDeletedAptResourceNotification";
}

- (BOOL)checkConstraintsForSave {
  NSString *rn;
  
  rn = [[self aptResource] valueForKey:@"name"];
  if ([rn length] == 0) {
    [self setErrorString:@"Missing resource name"];
    return NO;
  }
  return [rn rangeOfString:@":"].length == 0 ? YES : NO;
}

- (id)insertObject {
  id aptResource = [self snapshot];

  [aptResource takeValue:[NSNull null] forKey:@"notificationTime"];

  if (self->notificationTime != nil) {
    [aptResource
      takeValue: [NSNumber numberWithInt:[self->notificationTime intValue]]
      forKey:@"notificationTime"];
  }
  
  return [self runCommand:@"appointmentresource::new" arguments:aptResource];
}

- (id)updateObject {
  id aptResource = [self snapshot];

  [aptResource takeValue:[NSNull null] forKey:@"notificationTime"];

  if (self->notificationTime != nil) {
    [aptResource
      takeValue: [NSNumber numberWithInt:[self->notificationTime intValue]]
      forKey:@"notificationTime"];
  }
  return [self runCommand:@"appointmentresource::set" arguments:aptResource];
}

- (id)deleteObject {
  id result;

  result = [[self object] run:@"appointmentresource::delete", 
                          @"reallyDelete", [NSNumber numberWithBool:YES],
                          nil];
  return result;
}

- (id)save {
  if (self->category != nil)
    [[self aptResource] takeValue:self->category forKey:@"category"];
  else if ((self->categoryName != nil) && ([self->categoryName length] > 0))
    [[self aptResource] takeValue:self->categoryName forKey:@"category"];
  else
    [[self aptResource] takeValue:[NSNull null] forKey:@"category"];

  [self saveAndGoBackWithCount:1];

  if ([[self navigation] activePage] != self) {
    if ([self isInNewMode]) {
      [self runCommand:@"object::add-log",
            @"logText",     @"Appointment Resource created",
            @"action",      @"00_created",
            @"objectToLog", [self object], nil];
    }
    else {
      [self runCommand:@"object::add-log",
            @"logText",     @"Appointment Resource changed",
            @"action",      @"05_changed",
            @"objectToLog", [self object], nil];
    }
  }
  return nil;
}

- (id)category {
  return self->category;
}
- (void)setCategory:(id)_c {
  ASSIGN(self->category, _c);
}

- (NSArray *)categories {
  return self->categories;
}

- (NSString *)categoryName {
  return self->categoryName;
}

- (void)setCategoryName:(NSString *)_s {
  ASSIGN(self->categoryName, _s);
}

@end /* SkyAptResourceEditor */
