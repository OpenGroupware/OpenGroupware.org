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

#include "SkyUnsettledInvoicesList.h"
#include "common.h"

#include "SkyCurrencyFormatter.h"

@interface SkyUnsettledInvoicesList(PrivateMethods)
- (void)setCurrencyFormatter:(NSFormatter*)_formatter;
- (void)setUnsettledInvoices:(NSArray*)_invoices;
- (void)setActions:(NSArray*)_actions;
- (void)setAttributes:(NSArray*)_attributes;
- (void)setSelected:(NSArray*)_selected;
- (void)setFormName:(NSString*)_name;
- (id)debitor;
- (void)setFormattedAttributes:(NSArray*)_attributes;
@end

@implementation SkyUnsettledInvoicesList

- (id)init {
  if ((self = [super init])) {
    self->currencyFormatter = nil;
    self->debitor           = nil;
    self->selected          = nil;
    self->unsettledInvoices = nil;
    self->formName          = nil;
    self->invoice           = nil;
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->debitor);
  RELEASE(self->unsettledInvoices);
  RELEASE(self->selected);
  RELEASE(self->formName);
  RELEASE(self->invoice);
  RELEASE(self->currencyFormatter);
  [super dealloc];
}
#endif

- (void)sleep {
  [super sleep];
  RELEASE(self->currencyFormatter); self->currencyFormatter = nil;
}
//accessors

- (void)setDebitor:(id)_debitor {
  ASSIGN(self->debitor, _debitor);
}
- (id)debitor {
  return self->debitor;
}

- (void)setUnsettledInvoices:(NSArray *)_invoices {
  ASSIGN(self->unsettledInvoices, _invoices);
}
- (NSArray *)unsettledInvoices {
  return self->unsettledInvoices;
}

- (void)setSelected:(NSArray *)_selected {
  ASSIGN(self->selected, _selected);
}
- (NSArray *)selected {
  return self->selected;
}

- (void)setFormName:(NSString *)_name {
  ASSIGN(self->formName, _name);
}
- (NSString *)formName {
  return self->formName;
}

- (void)setInvoice:(id)_invoice {
  ASSIGN(self->invoice, _invoice);
}
- (id)invoice {
  return self->invoice;
}

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

@end
