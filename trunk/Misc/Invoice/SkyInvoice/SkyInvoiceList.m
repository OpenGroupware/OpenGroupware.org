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

#include "SkyInvoiceList.h"
#include "common.h"

#include "SkyCurrencyFormatter.h"

#include <EOControl/EOArrayDataSource.h>
#include "SkyInvoiceDataSource.h"
#include "SkyInvoiceDocument.h"
#include <NGExtensions/EOCacheDataSource.h>
#include <EOControl/EOKeyGlobalID.h>

#include <OGoFoundation/LSWSession.h>

@implementation SkyInvoiceList

- (id)init {
  if ((self = [super init])) {
    self->formName = @"InvoiceList";
    RETAIN(self->formName);

    self->invoices   = nil;
    self->item       = nil;
    self->selected   = nil;
    self->attributes = nil;
    self->showViewAction = YES;
    self->showNewAction  = YES;
    self->currencyFormatter = nil;
    self->invoiceCache   = nil;

    {
      id  s   = [self session];
      SEL sel = @selector(reloadInvoices:);
      [s addObserver:self selector:sel name:@"LSWNewInvoice"     object:nil];
      [s addObserver:self selector:sel name:@"LSWUpdatedInvoice" object:nil];
      [s addObserver:self selector:sel name:@"LSWDeletedInvoice" object:nil];
    }
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  [(id)[self session] removeObserver:self];
  RELEASE(self->invoices);
  RELEASE(self->selected);
  RELEASE(self->item);
  RELEASE(self->attributes);
  RELEASE(self->formName);
  RELEASE(self->currencyFormatter);
  RELEASE(self->invoiceCache);
  [super dealloc];
}
#endif

- (void)sleep {
  [super sleep];
  RELEASE(self->currencyFormatter); self->currencyFormatter = nil;
  [(EOCacheDataSource *)self->invoiceCache clear];
}

- (void)reloadInvoices:(NSNotification *)_notification {
  RELEASE(self->invoiceCache);  self->invoiceCache = nil;
  RELEASE(self->invoices);      self->invoices     = nil;
  RELEASE(self->selected);      self->selected     = nil;
}

//accessors
- (void)setInvoices:(NSArray *)_invoices {
  if (![self->invoices isEqual:_invoices]) {
    RELEASE(self->invoiceCache); self->invoiceCache = nil;
  }
  ASSIGN(self->invoices, _invoices);
}
- (NSArray *)invoices {
  return self->invoices;
}
- (EODataSource *)dataSource {
  if (self->invoiceCache == nil) {
    SkyInvoiceDataSource *ds =
      [[SkyInvoiceDataSource alloc] initWithInvoices:self->invoices];
    self->invoiceCache = [[EOCacheDataSource alloc] initWithDataSource:ds];
    RELEASE(ds);
  }
  return self->invoiceCache;
}

- (void)setItem:(id)_item {
  ASSIGN(self->item,_item);
}
- (id)item {
  return self->item;
}

- (void)setAttributes: (NSArray *)_attributes {
  ASSIGN(self->attributes, _attributes);
}
- (NSArray*)attributes {
  return self->attributes;
}

- (void)setFormName:(NSString *)_name {
  ASSIGN(self->formName,_name);
}
- (NSString*)formName {
  return self->formName;
}

- (void)setSelected:(NSArray *)_selected {
  ASSIGN(self->selected,_selected);
}
- (NSArray*)selected {
  return self->selected;
}

- (void)setShowViewAction:(BOOL)_flag {
  self->showViewAction = _flag;
}
- (BOOL)showViewAction {
  return self->showViewAction;
}
- (void)setShowNewAction:(BOOL)_flag {
  self->showNewAction = _flag;
}
- (BOOL)showNewAction {
  return self->showNewAction;
}

// needed accessors for item

- (NSString *)itemState {
  return [self->item state];
}
- (NSString *)stateIconFilename {
  static NSDictionary *iconMap = nil;
  if (iconMap == nil)
    iconMap =
      [[NSDictionary alloc]
                     initWithObjectsAndKeys:
                     @"led_yellow.gif", @"00_created",
                     @"led_green.gif",  @"05_printed",
                     @"led_dark.gif",   @"10_canceled",
                     @"led_red.gif",    @"15_monition",
                     @"led_red.gif",    @"16_monition2",
                     @"led_red.gif",    @"17_monition3",
                     @"led_dark.gif",   @"20_done",
                     nil];
  return [iconMap valueForKey:[self itemState]];
}
- (NSString *)itemKind {
  return [self->item kind];
}


// formatting currency
- (NSString *)currency {
  return [[(id)[self session] userDefaults] stringForKey:@"invoice_currency"];
}
- (SkyCurrencyFormatter *)currencyFormatter {
  if (self->currencyFormatter == nil) {
    SkyCurrencyFormatter *f = [[SkyCurrencyFormatter alloc] init];

    [f setCurrency:[self currency]];
    [f setShowCurrencyLabel:YES];
    [f setFormat:@".__0,00"];
    [f setThousandSeparator:@"."];
    [f setDecimalSeparator:@","];

    self->currencyFormatter = f;
  }

  return self->currencyFormatter;
}

// actions

- (id)newInvoice {
  NGMimeType  *mt = [NGMimeType mimeType:@"eo/invoice"];
  WOComponent *ct = nil;

  ct = [[self session] instantiateComponentForCommand:@"new" type:mt];
  if (ct) [self enterPage:(id)ct];
  return nil;  
}
- (id)viewInvoice {
  id invoice = [(EOKeyGlobalID *)[self->item globalID] keyValues][0];
  invoice = [self runCommand:@"invoice::get",
                  @"returnType", intObj(LSDBReturnType_ManyObjects),
                  @"invoiceId", invoice, nil];
  [self runCommand:@"invoice::set-debitor",
        @"relationKey", @"debitor",
        @"objects", invoice,
        nil];
  invoice = [invoice lastObject];
  [(id)[(id)[self session] navigation] activateObject:invoice
       withVerb:@"view"];
  return nil;
}

@end /* SkyInvoiceList */
