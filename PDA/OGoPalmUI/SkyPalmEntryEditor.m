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

#include "SkyPalmEntryEditor.h"

#import <Foundation/Foundation.h>
#include <LSFoundation/LSFoundation.h>
#include <OGoFoundation/OGoFoundation.h>
#include <OGoPalm/SkyPalmCategoryDataSource.h>
#include <OGoPalm/SkyPalmDocument.h>

@interface SkyPalmEntryEditor(PrivatMethods)
- (NSString *)palmDb;
@end

@implementation SkyPalmEntryEditor

- (id)init {
  if ((self = [super init])) {
    self->ds         = nil;
    self->categories = nil;
    self->devices    = nil;
    self->item       = nil;
  }
  return self;
}

- (BOOL)prepareForNewCommand:(NSString *)_command
                        type:(NGMimeType *)_type
               configuration:(id)_cfg
{
  if ([[self object] deviceId] == nil) {
    [self setErrorString:
          @"No Entries found in database!\n"
          @"Could not set default device-id!\n"
          @"First sync with Palm-Device!\n"];
    return NO;
  }
  return YES;
}
- (BOOL)prepareForActivationCommand:(NSString *)_command
                               type:(NGMimeType *)_type
                      configuration:(id)_cfg
{
  id obj = [[self session] getTransferObject];

  [self clearEditor];
  [self setObject:obj];
  //  self->activationCommand = [_command copyWithZone:[self zone]];

  [self setIsInNewMode:[_command hasPrefix:@"new"]];

  if ([self isInNewMode])
    return [self prepareForNewCommand:_command type:_type
                 configuration:nil];
  return [self prepareForEditCommand:_command type:_type
               configuration:nil];
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->ds);
  RELEASE(self->categories);
  RELEASE(self->devices);
  RELEASE(self->item);
  [super dealloc];
}
#endif

// accessors

- (id)snapshot {
  return [self object];
}
- (SkyPalmDocument *)document {
  return (SkyPalmDocument *)[self snapshot];
}

- (NSArray *)categories {
  if (self->categories == nil) {
    self->categories = [[self document] categories];
    RETAIN(self->categories);
  }
  return self->categories;
}

- (NSArray *)devices {
  if (self->devices == nil) {
    self->devices = [[self document] devices];
    RETAIN(self->devices);
  }
  return self->devices;
}

- (void)setItem:(id)_item {
  ASSIGN(self->item,_item);
}
- (id)item {
  return self->item;
}

// popup support
- (void)setCategoryIndex:(id)_idx {
  NSEnumerator *e   = [[self categories] objectEnumerator];
  id           cat  = nil;

  while ((cat = [e nextObject])) {
    if ([cat isEqual:_idx])
      [[self document] takeValue:[cat valueForKey:@"palm_id"]
                       forKey:@"categoryId"];
  }
}
- (id)categoryIndex {
  NSNumber     *idx = [[self snapshot] valueForKey:@"categoryId"];
  NSEnumerator *e   = [[self categories] objectEnumerator];
  id           cat  = nil;

  while ((cat = [e nextObject])) {
    if ([[cat valueForKey:@"palm_id"] isEqual:idx])
      return cat;
  }
  return nil;
}

// checking support
// for string with multiple lines
- (void)checkStringForKey:(NSString *)_key {
  NSString     *str = [[self snapshot] valueForKey:_key];
  NSEnumerator *e   = nil;
  NSString     *one = nil;

  e = [[str componentsSeparatedByString:@"\r\n"] objectEnumerator];
  str = [e nextObject];
  if (str == nil)
    str = @"";
  while ((one = [e nextObject])) {
    str = [NSString stringWithFormat:@"%@\n%@", str, one];
  }
  [[self snapshot] takeValue:str forKey:_key];
}

// actions

- (id)searchCategories {
  RELEASE(self->categories);  self->categories = nil;
  return nil;
}

- (id)insertObject {
  [[self document] save];
  return [self document];
}
- (id)updateObject {
  [[self document] save];
  return [self document];
}
- (id)cancel {
  id page;
  [[self document] revert];
  page = [super cancel];
  return page;
}

- (NSString *)insertNotificationName {
  return [[self document] insertNotificationName];
}
- (NSString *)updateNotificationName {
  return [[self document] updateNotificationName];
}

// overwriting

- (NSString *)palmDb {
  [self logWithFormat:@"- (NSString *)palmDb not overwritten!!!"];
  return nil;
}

@end /* SkyPalmEntryEditor */
