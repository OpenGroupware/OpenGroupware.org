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

#include <OGoFoundation/LSWContentPage.h>
#include <OGoFoundation/LSWNotifications.h>
#include "common.h"

@interface SkyNewsPreferences : LSWContentPage
{
  id             account;
  NSUserDefaults *defaults;

  NSNumber       *blockSize;
  NSNumber       *filterDays;
  BOOL           showOverdueJobs;

  BOOL           isShowNewsOnTop;
  BOOL           isRoot;
}

@end

@implementation SkyNewsPreferences

- (void)dealloc {
  [self->account release];
  [self->defaults release];
  [self->blockSize release];
  [self->filterDays release];
  [super dealloc];
}

/* notifications */

- (void)awake {
  [super awake];
  self->isRoot = [[self session] activeAccountIsRoot];
}

- (void)sleep {
  [super sleep];
}

/* accessors */

- (BOOL)isEditorPage {
  return YES;
}

- (BOOL)_isEditable:(NSString *)_defName {
  id obj;

  _defName = [@"rootAccess" stringByAppendingString:_defName];
  obj = [self->defaults objectForKey:_defName];

  return obj ? [obj boolValue] : YES;
}

- (void)setAccount:(id)_account {
  NSUserDefaults *ud;

  [self->defaults release];  self->defaults  = nil;
  [self->blockSize release]; self->blockSize = nil;

  ASSIGN(self->account, _account);
  
  ud = _account
    ? [self runCommand:@"userdefaults::get",
              @"user", _account, nil]
    : [self runCommand:@"userdefaults::get", nil];

  self->defaults = [ud retain];

  self->blockSize = [self->defaults objectForKey:@"news_blocksize"];
  if (self->blockSize == nil) self->blockSize = [NSNumber numberWithInt:100];

  self->blockSize = [self->blockSize retain];

  self->filterDays = [self->defaults objectForKey:@"news_filterDays"];
  if (self->filterDays == nil) self->filterDays = [NSNumber numberWithInt:7];

  self->filterDays = [self->filterDays retain];

  self->isShowNewsOnTop= [[self->defaults objectForKey:@"news_showNewsOnTop"]
                                          boolValue];
  self->showOverdueJobs = [self->defaults boolForKey:@"news_showOverdueJobs"];
}
- (id)account {
  return self->account;
}

- (NSString *)accountLabel {
  return [[self session] labelForObject:[self account]];
}

- (void)setBlockSize:(NSNumber *)_blockSize {
  ASSIGN(self->blockSize, _blockSize);
}
- (NSNumber *)blockSize {
  return self->blockSize;
}

- (void)setIsShowNewsOnTop:(BOOL)_flag {
  self->isShowNewsOnTop = _flag;
}
- (BOOL)isShowNewsOnTop {
  return self->isShowNewsOnTop;
}

- (void)setShowOverdueJobs:(BOOL)_flag {
  self->showOverdueJobs = _flag;
}
- (BOOL)showOverdueJobs {
  return self->showOverdueJobs;
}
     
- (void)setFilterDays:(NSNumber *)_filterDays {
  ASSIGN(self->filterDays, _filterDays);
}
- (NSNumber *)filterDays {
  return self->filterDays;
}

- (BOOL)isRoot {
  return self->isRoot;
}

/* actions */

- (id)cancel {
  [self leavePage];
  return nil;
}

- (id)save {
  id uid;

  uid = [[self account] valueForKey:@"companyId"];

  [self runCommand:@"userdefaults::write",
        @"key",      @"news_blocksize",
        @"value",    [self blockSize],
        @"defaults", self->defaults,
        @"userId",   uid,
        nil];

  [self runCommand:@"userdefaults::write",
        @"key",      @"news_showNewsOnTop",
        @"value",    [NSNumber numberWithBool:self->isShowNewsOnTop],
        @"defaults", self->defaults,
        @"userId",   uid,
        nil];
  [self runCommand:@"userdefaults::write",
        @"key",      @"news_showOverdueJobs",
        @"value",    [NSNumber numberWithBool:self->showOverdueJobs],
        @"defaults", self->defaults,
        @"userId",   uid,
        nil];
  [self runCommand:@"userdefaults::write",
        @"key",      @"news_filterDays",
        @"value",    self->filterDays,
        @"defaults", self->defaults,
        @"userId",   uid,
        nil];

  [self postChange:LSWUpdatedAccountNotificationName onObject:[self account]];
  
  return [self leavePage];
}

@end /* SkyNewsPreferences */
