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

@class NSString, NSNumber, NSUserDefaults;

@interface LSWJobPreferences : LSWContentPage
{
  id             account;
  NSUserDefaults *defaults;

  NSString       *jobListView;
  NSString       *jobView;
  NSNumber       *blockSize;
  NSString       *noOfCols;
  
  BOOL           isJobListViewEditable;
  BOOL           isJobViewEditable;
  BOOL           isBlockSizeEditable;
  BOOL           isNoOfColsEditable;
  BOOL           isRoot;
}

@end

#include <OGoFoundation/LSWNotifications.h>
#include "common.h"

@implementation LSWJobPreferences

- (void)dealloc {
  [self->account     release];
  [self->defaults    release];
  [self->jobListView release];
  [self->jobView     release];
  [self->noOfCols    release];
  [self->blockSize   release];
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

  [self->defaults    release]; self->defaults      = nil;
  [self->jobListView release]; self->jobListView   = nil;
  [self->jobView     release]; self->jobView       = nil;
  [self->blockSize   release]; self->blockSize     = nil;
  [self->noOfCols    release]; self->noOfCols    = nil;
  
  ASSIGN(self->account, _account);
  
  ud = _account
    ? [self runCommand:@"userdefaults::get",
              @"user", _account, nil]
    : [self runCommand:@"userdefaults::get", nil];

  self->defaults = [ud retain];

  self->jobView =
      [[self->defaults stringForKey:@"job_view"] copy];
  self->jobListView =
      [[self->defaults stringForKey:@"joblist_view"] copy];
  self->blockSize = [[self->defaults objectForKey:@"job_blocksize"]  copy];
  self->noOfCols  = [[self->defaults objectForKey:@"job_no_of_cols"] copy];
  
  self->isBlockSizeEditable   = [self _isEditable:@"job_blocksize"];
  self->isNoOfColsEditable    = [self _isEditable:@"job_no_of_cols"];
  self->isJobViewEditable     = [self _isEditable:@"job_view"];
  self->isJobListViewEditable = [self _isEditable:@"joblist_view"];
}
- (id)account {
  return self->account;
}

- (NSString *)accountLabel {
  return [[self session] labelForObject:[self account]];
}

- (BOOL)isRoot {
  return self->isRoot;
}

- (void)setNoOfCols:(NSString *)_number {
  ASSIGN(self->noOfCols, _number);
}
- (NSString *)noOfCols {
  return self->noOfCols;
}
- (BOOL)isNoOfColsEditable {
  return self->isNoOfColsEditable || self->isRoot;
}
- (void)setIsNoOfColsEditable:(BOOL)_flag {
  if (self->isRoot)
    self->isNoOfColsEditable = _flag;
}
- (void)setIsNoOfColsEditableRoot:(BOOL)_flag {
  if (self->isRoot) 
    self->isNoOfColsEditable = _flag;
}

- (void)setBlockSize:(NSNumber *)_number {
  ASSIGN(self->blockSize, _number);
}
- (NSNumber *)blockSize {
  return self->blockSize;
}

- (void)setIsBlockSizeEditableRoot:(BOOL)_flag {
  if (self->isRoot)
    self->isBlockSizeEditable = _flag;
}
- (BOOL)isBlockSizeEditable {
  return self->isBlockSizeEditable || self->isRoot;
}

- (NSString *) jobListView {
  return self->jobListView;
}

- (NSString *) jobView {
  return self->jobView;
}

- (void)setJobListView:(NSString *)_str {
  ASSIGN(self->jobListView,_str);
}

- (void)setJobView:(NSString *)_str {
  ASSIGN(self->jobView,_str);
}

- (BOOL)isJobViewEditable {
  return self->isJobViewEditable || self->isRoot;
}

- (void)setIsJobViewEditableRoot:(BOOL)_flag {
  if (self->isRoot)
    self->isJobViewEditable = _flag;
}

- (BOOL)isJobListViewEditable {
  return self->isJobListViewEditable || self->isRoot;
}

- (void)setIsJobListViewEditableRoot:(BOOL)_flag {
  if (self->isRoot)
    self->isJobListViewEditable = _flag;
}


/* actions */

- (id)cancel {
  [self leavePage];
  return nil;
}

- (id)save {
  id uid;

  uid = [[self account] valueForKey:@"companyId"];

  if ([self isJobListViewEditable]) {
    [self runCommand:@"userdefaults::write",
            @"key",      @"joblist_view",
            @"value",    self->jobListView,
            @"defaults", self->defaults,
            @"userId",   uid,
            nil];
  }
  if ([self isBlockSizeEditable]) {
    [self runCommand:@"userdefaults::write",
            @"key",      @"job_blocksize",
            @"value",    [self blockSize],
            @"defaults", self->defaults,
            @"userId",   uid,
            nil];
  }
  if ([self isNoOfColsEditable]) {
    [self runCommand:@"userdefaults::write",
            @"key",      @"job_no_of_cols",
            @"value",    [self noOfCols],
            @"defaults", self->defaults,
            @"userId",   uid,
            nil];
  }
  if ([self isJobViewEditable]) {
    [self runCommand:@"userdefaults::write",
            @"key",      @"job_view",
            @"value",    self->jobView,
            @"defaults", self->defaults,
            @"userId",   uid,
            nil];
  }
  
  [self postChange:LSWUpdatedAccountNotificationName onObject:[self account]];
  
  return [self leavePage];
}

@end /* LSWJobPreferences */
