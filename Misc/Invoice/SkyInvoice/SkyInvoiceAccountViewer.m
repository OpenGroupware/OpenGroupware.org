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

#include <OGoFoundation/LSWViewerPage.h>

@interface SkyInvoiceAccountViewer : LSWViewerPage
{
  NSString         *tabKey;
  
  NSArray          *accountings;
  id                item;

  BOOL              fetchAccount;
  BOOL              fetchAccountings;
  
  NSDictionary     *selectedAttribute;
  unsigned          startIndex;
  BOOL              isDescending;
}

@end

#include "common.h"
#include "SkyCurrencyFormatter.h"

@interface SkyInvoiceAccountViewer(PrivateMethods)
- (void)_fetchAccount;
- (void)_fetchAccountings;
@end

@implementation SkyInvoiceAccountViewer

- (id)init {
  if ((self = [super init])) {
    [self registerForNotificationNamed:@"LSWUpdatedInvoiceAccount"];
    [self registerForNotificationNamed:@"LSWDeletedInvoiceAccount"];
    [self registerForNotificationNamed:@"LSWNewInvoiceAccounting"];
    [self registerForNotificationNamed:@"LSWUpdatedInvoiceAccounting"];
    [self registerForNotificationNamed:@"LSWDeletedInvoiceAccounting"];
    
    [self takeValue:@"attributes" forKey:@"tabKey"];

    self->fetchAccount     = YES;
    self->fetchAccountings = YES;
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->tabKey);
  RELEASE(self->accountings);
  RELEASE(self->item);
  RELEASE(self->selectedAttribute);
  [super dealloc];
}
#endif

- (void)noteChange:(NSString*)_cn onObject:(id)_object {
  [super noteChange:_cn onObject:_object];

  if (([_cn isEqualToString:@"LSWUpdatedInvoiceAccount"]) ||
      ([_cn isEqualToString:@"LSWDeletedInvoiceAccount"]))
    {
      self->fetchAccount = YES;
    }
  else if (([_cn isEqualToString:@"LSWNewInvoiceAccounting"]) ||
           ([_cn isEqualToString:@"LSWUpdatedInvoiceAccounting"]) ||
           ([_cn isEqualToString:@"LSWDeletedInvoiceAccounting"]))
    {
      self->fetchAccountings = YES;
    }
}

- (void)syncAwake {
  [super syncAwake];

  if (self->fetchAccount) {
    [self _fetchAccount];
    self->fetchAccount = NO;
  }
  if (self->fetchAccountings) {
    [self _fetchAccountings];
    self->fetchAccountings = NO;
  }
}

- (void)_fetchAccount {
  [self setObject:
        [[self runCommand:
              @"invoiceaccount::get",
              @"invoiceAccountId",
              [[self object] valueForKey:@"invoiceAccountId"],
              @"returnType", intObj(LSDBReturnType_OneObject),
              nil] lastObject]];
  [self runCommand:
        @"invoiceaccount::fetch-debitor",
        @"relationKey", @"debitor",
        @"object", [self object],
        nil];
}

- (void)_fetchAccountings {
  [self takeValue:
        [self runCommand:
              @"invoiceaccounting::get",
              @"invoiceAccountId",
              [[self object] valueForKey:@"invoiceAccountId"],
              @"returnType", intObj(LSDBReturnType_ManyObjects),
              nil]
        forKey:@"accountings"];
  [self runCommand:
        @"invoiceaccounting::fetch-invoice",
        @"relationKey", @"invoice",
        @"actionRelationKey", @"toInvoiceAction",
        @"objects", self->accountings,
        nil];
}

// accessors

- (id)account {
  return [self object];
}

- (void)setTabKey:(NSString*)_tabKey {
  ASSIGN(self->tabKey, _tabKey);
}
- (NSString*)tabKey {
  return self->tabKey;
}

- (void)setAccountings:(NSArray*)_accountings {
  ASSIGN(self->accountings, _accountings);
}
- (NSArray*)accountings {
  return self->accountings;
}

- (void)setItem:(id)_item {
  ASSIGN(self->item,_item);
}
- (id)item {
  return self->item;
}

- (void)setSelectedAttribute:(NSDictionary*)_attribute {
  ASSIGN(self->selectedAttribute,_attribute);
}
- (NSDictionary*)selectedAttribute {
  return self->selectedAttribute;
}

- (void)setStart:(unsigned)_start {
  self->startIndex = _start;
}
- (unsigned)start {
  return self->startIndex;
}

- (void)setIsDescending:(BOOL)_flag {
  self->isDescending = _flag;
}
- (BOOL)isDescending {
  return self->isDescending;
}

//

- (NSString *)currency {
  return [[(id)[self session] userDefaults] stringForKey:@"invoice_currency"];
}
- (NSFormatter *)currencyFormatter {
  SkyCurrencyFormatter *f = [[SkyCurrencyFormatter alloc] init];

  [f setCurrency:[self currency]];
  [f setShowCurrencyLabel:YES];
  [f setFormat:@".__0,00"];
  [f setThousandSeparator:@"."];
  [f setDecimalSeparator:@","];

  return AUTORELEASE(f);
}

// key/value coding

- (void)takeValue:(id)_val forKey:(id)_key {
  if ([_key isEqualToString:@"tabKey"]) {
    [self setTabKey:_val];
    return;
  }
  if ([_key isEqualToString:@"accountings"]) {
    [self setAccountings:_val];
    return;
  }
  [super takeValue:_val forKey:_key];
}

// actions

- (id)viewDebitor {
  [[self session] transferObject:[[self account] valueForKey:@"debitor"]
                  owner:self];
  [self executePasteboardCommand:@"view"];
  return nil;
}

- (id)viewInvoice {
  [[self session] transferObject:[self->item valueForKey:@"invoice"]
                  owner:self];
  [self executePasteboardCommand:@"view"];
  return nil;
}

- (id)newAccounting {
  NGMimeType  *mt = [NGMimeType mimeType:@"eo/invoiceaccounting"];
  WOComponent *ct = nil;

  ct = [[self session] instantiateComponentForCommand:@"new" type:mt];
  if (ct) {
    [ct takeValue:[self account] forKey:@"account"];
    [self enterPage:(id)ct];
  }
  return nil;
}

@end
