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

#include "SkyMonitionPrintout.h"
#include "common.h"

@interface SkyMonitionPrintout(PrivateMethods)
- (void)setHeader:(NSString*)_header;
- (void)setSummary:(NSString*)_summary;
- (void)setAll:(NSString*)_all;
- (void)setFormat:(SkyInvoicePrintoutFormatter*)_format;
@end

@implementation SkyMonitionPrintout

- (id)init {
  if ((self = [super init])) {
    [self registerForNotificationNamed:@"LSWUpdatedInvoice"];
    self->invoices = nil;
    self->debitor = nil;
    self->recomputeOutput = YES;
    self->currency = nil;
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->invoices);
  RELEASE(self->debitor);
  RELEASE(self->invoice);
  RELEASE(self->format);
  RELEASE(self->header);
  RELEASE(self->summary);
  RELEASE(self->all);
  RELEASE(self->currency);
  [super dealloc];
}
#endif

- (void)_computeOutput {
  NSUserDefaults              *ud;
  NSDictionary                *formatSettings;
  NSDictionary                *settings;
  NSDictionary                *monitionSettings;
  NSDictionary                *monitionLevels;
  NSDictionary                *monitionLevel;
  NSString                    *printoutAttr;
  NSNumber                    *maxMonLevel;
  SkyInvoicePrintoutFormatter *formatter;

  ud = [[self session] userDefaults];
  formatSettings   = [ud dictionaryForKey:@"invoice_format_settings"];
  settings         = [formatSettings objectForKey:@"standard-printout"];
  monitionSettings = [formatSettings objectForKey:@"monition-printout"];
  monitionLevels   = [ud dictionaryForKey:@"monition_levels"];
  maxMonLevel      = [self->debitor valueForKey:@"highestMonitionLevel"];
  monitionLevel    = [monitionLevels objectForKey:[maxMonLevel stringValue]];
  printoutAttr     = [monitionLevel objectForKey:@"printout"];
  formatter        = [SkyInvoicePrintoutFormatter
                       skyInvoicePrintoutFormatterWithDefaultSettings:settings];
  [formatter setFormatSettings:monitionSettings];
  
  if (printoutAttr != nil) {
    [formatter setFormatSettings:[formatSettings objectForKey:printoutAttr]];
  }

  [formatter setInvoices:self->invoices];
  [formatter setDebitor:self->debitor];
  [formatter setCurrency:self->currency];
  [self setHeader:[formatter stringForKey:@"HEADER_ITEM"  andObject:nil]];
  [self setSummary:[formatter stringForKey:@"FOOTER_ITEM" andObject:nil]];
  [self setAll:[formatter formattedString]];
  [self setFormat:formatter];
}

- (void)noteChange:(NSString*)_cn onObject:(id)_object {
  [super noteChange:_cn onObject:_object];
  
  if ([_cn isEqualToString:@"LSWUpdatedInvoice"]) {
    self->recomputeOutput = YES;
  }
}

- (void)syncAwake {
  [super syncAwake];
  if (self->recomputeOutput) {
    [self _computeOutput];
    self->recomputeOutput = NO;
  }
}

//accessors

- (void)setInvoices:(NSArray *)_invoices {
  ASSIGN(self->invoices, _invoices);
}
- (NSArray *)invoices {
  return self->invoices;
}

- (void)setDebitor:(id)_debitor {
  ASSIGN(self->debitor, _debitor);
}
- (id)debitor {
  return self->debitor;
}

- (void)setInvoice:(id)_invoice {
  ASSIGN(self->invoice, _invoice);
}
- (id)invoice {
  return self->invoice;
}

- (void)setHeader:(NSString *)_header {
  ASSIGN(self->header, _header);
}
- (NSString *)header {
  return self->header;
}

- (void)setSummary:(NSString *)_summary {
  ASSIGN(self->summary, _summary);
}
- (NSString *)summary {
  return self->summary;
}

- (void)setAll:(NSString *)_all {
  ASSIGN(self->all, _all);
}
- (NSString*)all {
  return self->all;
}

- (void)setFormat:(SkyInvoicePrintoutFormatter*)_format {
  ASSIGN(self->format, _format);
}
- (SkyInvoicePrintoutFormatter*)format {
  return self->format;
}

- (void)setCurrency:(NSString *)_cur {
  if (![_cur isEqualToString:self->currency]) {
    ASSIGN(self->currency,_cur);
    self->recomputeOutput = YES;
  }
}
- (NSString *)currency {
  return self->currency;
}

//

- (NSString*)invoiceString {
  return
    [self->format stringForKey:@"INVOICE_ITEM" andObject:self->invoice];
}

- (NSData*)createOutput {
  return [self->all dataUsingEncoding:[NSString defaultCStringEncoding]];
}

- (id)createResponse {
  WOResponse *response = nil;

  response = [WOResponse responseWithRequest:[[self context] request]];
  [response setStatus:200];
  [response setHeader:@"text/plainx" forKey:@"content-type"];
  [response setContent:[self createOutput]];

  return response;
}

- (id)viewInvoice {
  [[self session] transferObject:self->invoice owner:self];
  [self executePasteboardCommand:@"view"];
  return nil;
}

@end
