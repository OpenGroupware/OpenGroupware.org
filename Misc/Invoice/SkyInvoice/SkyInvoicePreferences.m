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
#include "common.h"

@interface SkyInvoicePreferences : LSWContentPage
{
  id             account;
  NSUserDefaults *defaults;
  
  NSNumber       *blockSize;
  NSString       *noOfCols;
  NSString       *invoiceViewerSubview;
  
  BOOL           isNoOfColsEditable;
  BOOL           isBlockSizeEditable;
  BOOL           isInvoiceViewerSubviewEditable;
  
  BOOL           isRoot;
}
@end

@implementation SkyInvoicePreferences

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->account);
  RELEASE(self->defaults);
  RELEASE(self->blockSize);
  RELEASE(self->noOfCols);
  RELEASE(self->invoiceViewerSubview);
  [super dealloc];
}
#endif

/* notifications */

- (void)awake {
  [super awake];
  self->isRoot = [[self session] activeAccountIsRoot];
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

  RELEASE(self->defaults);             self->defaults      = nil;
  RELEASE(self->blockSize);            self->blockSize     = nil;
  RELEASE(self->noOfCols);             self->noOfCols      = nil;
  RELEASE(self->invoiceViewerSubview); self->invoiceViewerSubview = nil;
  
  ASSIGN(self->account, _account);
  
  ud = _account
    ? [self runCommand:@"userdefaults::get",
              @"user", _account, nil]
    : [self runCommand:@"userdefaults::get", nil];

  self->defaults = RETAIN(ud);

  self->blockSize = [self->defaults objectForKey:@"invoice_blocksize"];
  self->noOfCols  = [self->defaults objectForKey:@"invoice_no_of_cols"];
  self->invoiceViewerSubview =
    [self->defaults objectForKey:@"invoice_viewer_sub_view"];
  RETAIN(self->blockSize);
  RETAIN(self->noOfCols);
  RETAIN(self->invoiceViewerSubview);

  self->isBlockSizeEditable = [self _isEditable:@"invoice_blocksize"];
  self->isNoOfColsEditable  = [self _isEditable:@"invoice_no_of_cols"];
  self->isInvoiceViewerSubviewEditable =
    [self _isEditable:@"invoice_viewer_sub_view"];

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
  if (self->isRoot) {
    self->isNoOfColsEditable = _flag;
  }
}

- (void)setBlockSize:(NSNumber *)_number {
  ASSIGN(self->blockSize, _number);
}
- (NSNumber *)blockSize {
  return self->blockSize;
}

- (BOOL)isBlockSizeEditable {
  return self->isBlockSizeEditable || self->isRoot;
}

- (void)setIsBlockSizeEditableRoot:(BOOL)_flag {
  if (self->isRoot)
    self->isBlockSizeEditable = _flag;
}

- (void)setInvoiceViewerSubview:(NSString*)_subview {
  ASSIGN(self->invoiceViewerSubview, _subview);
}
- (NSString*)invoiceViewerSubview {
  return self->invoiceViewerSubview;
}

- (BOOL)isInvoiceViewerSubviewEditable {
  return self->isInvoiceViewerSubviewEditable || self->isRoot;
}

- (void)setIsInvoiceViewerSubviewEditableRoot:(BOOL)_flag {
  if (self->isRoot)
    self->isInvoiceViewerSubviewEditable = _flag;
}

/* actions */

- (id)cancel {
  [self leavePage];
  return nil;
}

- (id)save {
  id uid;

  uid = [[self account] valueForKey:@"companyId"];

  if ([self isBlockSizeEditable]) {
    [self runCommand:@"userdefaults::write",
            @"key",      @"invoice_blocksize",
            @"value",    [self blockSize],
            @"defaults", self->defaults,
            @"userId",   uid,
            nil];
  }
  if ([self isNoOfColsEditable]) {
    [self runCommand:@"userdefaults::write",
            @"key",      @"invoice_no_of_cols",
            @"value",    [self noOfCols],
            @"defaults", self->defaults,
            @"userId",   uid,
            nil];
  }
  if ([self isInvoiceViewerSubviewEditable]) {
    [self runCommand:@"userdefaults::write",
            @"key",      @"invoice_viewer_sub_view",
            @"value",    [self invoiceViewerSubview],
            @"defaults", self->defaults,
            @"userId",   uid,
            nil];
  }
  
  [self postChange:LSWUpdatedAccountNotificationName onObject:[self account]];
  
  return [self leavePage];
}

@end
