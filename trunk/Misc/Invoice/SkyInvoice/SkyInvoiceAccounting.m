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

#include <OGoFoundation/LSWEditorPage.h>

@class NSNumber, NSFormatter;

@interface SkyInvoiceAccounting : LSWEditorPage
{
  id          account;
  id          invoice;
  NSNumber    *debit;
  NSNumber    *balance;
  NSString    *logText;

  NSFormatter *currencyFormatter;
}

@end

#include "common.h"
#include "SkyCurrencyFormatter.h"

@implementation SkyInvoiceAccounting

- (id)init {
  if ((self = [super init])) {
    self->account = nil;
    self->invoice = nil;
    [self takeValue:[NSNumber numberWithDouble:0.0] forKey:@"debit"];
    [self takeValue:[NSNumber numberWithDouble:0.0] forKey:@"balance"];
    self->logText = nil;
    self->currencyFormatter = nil;
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->account);
  RELEASE(self->invoice);
  RELEASE(self->balance);
  RELEASE(self->debit);
  RELEASE(self->logText);
  RELEASE(self->currencyFormatter);
  [super dealloc];
}
#endif

- (void)sleep {
  [super sleep];
  RELEASE(self->currencyFormatter); self->currencyFormatter = nil;
}

//accessors

- (void)setAccount:(id)_account {
  ASSIGN(self->account,_account);
}
- (id)account {
  return self->account;
}

- (void)setInvoice:(id)_invoice {
  ASSIGN(self->invoice,_invoice);
}
- (id)invoice {
  return self->invoice;
}

- (void)setDebit:(NSNumber*)_debit {
  ASSIGN(self->debit,_debit);
}
- (NSNumber*)debit {
  return self->debit;
}

- (void)setBalance:(NSNumber*)_balance {
  ASSIGN(self->balance,_balance);
}
- (NSNumber*)balance {
  return self->balance;
}

- (void)setLogText:(NSString*)_logText {
  ASSIGN(self->logText,_logText);
}
- (NSString*)logText {
  return self->logText;
}

- (NSString *)currency {
  return [[(id)[self session] userDefaults] stringForKey:@"invoice_currency"];
}
- (NSFormatter *)currencyFormatter {
  if (self->currencyFormatter == nil) {
    SkyCurrencyFormatter *f = [[SkyCurrencyFormatter alloc] init];

    [f setCurrency:[self currency]];
    [f setFormat:@".__0,00"];
    [f setThousandSeparator:@"."];
    [f setDecimalSeparator:@","];

    self->currencyFormatter = f;
  }

  return self->currencyFormatter;
}
// key/value coding

- (void)takeValue:(id)_val forKey:(id)_key {
  if ([_key isEqualToString:@"account"]) {
    [self setAccount:_val];
    return;
  }
  if ([_key isEqualToString:@"invoice"]) {
    [self setInvoice:_val];
    return;
  }
  if ([_key isEqualToString:@"debit"]) {
    [self setDebit:_val];
    return;
  }
  if ([_key isEqualToString:@"balance"]) {
    [self setBalance:_val];
    return;
  }
  if ([_key isEqualToString:@"logText"]) {
    [self setLogText:_val];
    return;
  }
  [super takeValue:_val forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"account"]) {
    return [self account];
  }
  if ([_key isEqualToString:@"invoice"]) {
    return [self invoice];
  }
  if ([_key isEqualToString:@"debit"]) {
    return [self debit];
  }
  if ([_key isEqualToString:@"balance"]) {
    return [self balance];
  }
  if ([_key isEqualToString:@"logText"])
    return [self logText];
  return [super valueForKey:_key];
}

//conditional

- (BOOL)hasInvoice {
  return (self->invoice != nil) ? YES : NO;
}

- (void)syncAwake {
  if (self->account == nil) {
    [self setErrorString:@"No Account Set"];
  } else {
    [self setErrorString:nil];
  }
}

// notifications

- (NSString *)insertNotificationName {
  return @"LSWNewInvoiceAccounting";
}

//actions

- (id)save {
  double deb;
  double bal;
  double value;
  id     obj;

  deb = [self->debit doubleValue];
  bal = [self->balance doubleValue];
  obj = [self snapshot];

  if (self->account == nil) {
    [self setErrorString:@"No Account Set"];
    return nil;
  }

  if ((deb == 0.0) &&
      (bal == 0.0)) {
    [self setErrorString:@"Invalid Accounting Values"];
    return nil;
  }
  if (deb != 0.0) {
    if (bal != 0.0) {
      [self setErrorString:@"Choose Debit Or Balance, Not Both!"];
      return nil;
    }
    value = (-1)*deb;
  } else {
    value = bal;
  }

  [obj takeValue:[self->account valueForKey:@"invoiceAccountId"]
       forKey:@"accountId"];
  [obj takeValue:[NSNumber numberWithDouble:value]
       forKey:@"value"];
  if (![self hasInvoice]) {
    [obj takeValue:self->logText forKey:@"logText"];
  }
  if (self->invoice != nil) {
    [obj takeValue:[self->invoice valueForKey:@"invoiceId"]
         forKey:@"invoiceId"];
  }
  return [super save];
}

- (id)insertObject {
  if ([self hasInvoice]) {
    return 
      [self runCommand:@"invoice::accounting",
            @"object",  self->invoice,
            @"account", self->account,
            @"value",   [[self snapshot] valueForKey:@"value"],
            nil];
  }
  return [self runCommand:@"invoiceaccounting::new" arguments:[self snapshot]];
}

@end
