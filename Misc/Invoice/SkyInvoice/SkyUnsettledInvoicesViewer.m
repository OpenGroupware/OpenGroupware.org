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

#include "SkyUnsettledInvoicesViewer.h"
#include "common.h"

@interface SkyUnsettledInvoicesViewer(PrivateMethods)
- (id)debitor;
- (void)setTabKey:(NSString *)_key;
- (void)setViewerTitle:(NSString *)_title;
- (void)setUnsettledInvoices:(NSArray *)_invoices;
- (void)setFormatter:(SkyInvoicePrintoutFormatter *)_formatter;
- (NSString *)currency;
- (void)_resetSelected;
@end

@implementation SkyUnsettledInvoicesViewer

- (id)init {
  if ((self = [super init])) {
    [self setTabKey:@"monitions"];

    [self registerForNotificationNamed:@"LSWUpdatedInvoice"];
    
    self->reloadFormatter = YES;
    self->fetchInvoices   = YES;
    self->selected        = nil;
    [self _resetSelected];
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->unsettledInvoices);
  RELEASE(self->selected);
  RELEASE(self->invoice);
  RELEASE(self->tabKey);
  RELEASE(self->viewerTitle);
  RELEASE(self->formatter);
  [super dealloc];
}
#endif

- (void)noteChange:(NSString*)_cn onObject:(id)_object {
  [super noteChange:_cn onObject:_object];
  
  if ([_cn isEqualToString:@"LSWUpdatedInvoice"]) {
    self->reloadFormatter = YES;
    self->fetchInvoices   = YES;
  }
}

- (void)_loadFormatter {
  NSUserDefaults              *ud;
  NSDictionary                *formatSettings;
  NSDictionary                *settings;
  NSDictionary                *monitionSettings;
  NSDictionary                *monitionLevels;
  NSDictionary                *monitionLevel;
  NSString                    *printoutAttr;
  NSNumber                    *maxMonLevel;
  SkyInvoicePrintoutFormatter *format;

  ud = [[self session] userDefaults];
  formatSettings   = [ud dictionaryForKey:@"invoice_format_settings"];
  settings         = [formatSettings objectForKey:@"standard-printout"];
  monitionSettings = [formatSettings objectForKey:@"monition-printout"];
  monitionLevels   = [ud dictionaryForKey:@"monition_levels"];
  maxMonLevel      = [[self debitor] valueForKey:@"highestMonitionLevel"];
  monitionLevel    = [monitionLevels objectForKey: [maxMonLevel stringValue]];
  printoutAttr     = [monitionLevel objectForKey:@"printout"];
  format = [SkyInvoicePrintoutFormatter
             skyInvoicePrintoutFormatterWithDefaultSettings: settings];
  [format setFormatSettings: monitionSettings];
  if (printoutAttr != nil) {
    [format setFormatSettings: [formatSettings objectForKey:printoutAttr]];
  }

  [format setInvoices:self->unsettledInvoices];
  [format setDebitor:[self debitor]];
  [format setCurrency:[self currency]];
  [self setFormatter:format];
}

- (void)_fetchInvoices {
  [self setUnsettledInvoices:
      [self runCommand:@"enterprise::fetch-unsettled-invoices",
            @"object", [self debitor],
            nil]];
}

- (void)syncAwake {
  if (self->viewerTitle == nil) {
    NSString* titleLabel =
      [[self labels] valueForKey:@"unsettledInvoicesFor"];
    [self setViewerTitle:
          [titleLabel stringByAppendingString:
                      [[self debitor] valueForKey:@"description"]]];
  }
  
  if (self->fetchInvoices) {
    [self _fetchInvoices];
    self->fetchInvoices = NO;
  }
  if (self->reloadFormatter) {
    [self _loadFormatter];
    self->reloadFormatter = NO;
  }
  [super syncAwake];
}

//accessors

- (NSArray*)unsettledInvoices {
  return self->unsettledInvoices;
}

- (void)setSelected:(NSArray*)_selected {
  ASSIGN(self->selected, _selected);
}
- (NSArray*)selected {
  return self->selected;
}

- (void)setInvoice:(id)_invoice {
  ASSIGN(self->invoice,_invoice);
}
- (id)invoice {
  return self->invoice;
}

- (NSString*)tabKey {
  return self->tabKey;
}

- (NSString*)viewerTitle {
  return self->viewerTitle;
}

- (SkyInvoicePrintoutFormatter*)formatter {
  return self->formatter;
}


//actions

- (id)viewInvoice {
  [[self session] transferObject:self->invoice owner:self];
  [self executePasteboardCommand:@"view"];
  return nil;
}

- (NSArray *)selectedEOs {
  NSMutableArray *ma = [NSMutableArray array];
  NSEnumerator   *e  = [self->selected objectEnumerator];
  id             one = nil;
  while ((one = [e nextObject]))
    [ma addObject:[one globalID]];

  one = [self runCommand:@"invoice::get-by-globalid",
              @"gids", ma, nil];
  [self runCommand:@"invoice::set-debitor",
        @"relationKey", @"debitor",
        @"objects", one,
        nil];
  
  return one;
}
- (id)increaseMonitionLevel {
  NSEnumerator *e;
  id inv;
  NSArray *eos = [self selectedEOs];

  //  NSLog(@"%s: selected: %@", __PRETTY_FUNCTION__, eos);
  [self runCommand:@"invoice::monition",
        @"objects", eos,
        nil];

  e = [eos objectEnumerator];
  while ((inv = [e nextObject])) {
    [self postChange:@"LSWUpdatedInvoice" onObject:inv];
  }
  [self _fetchInvoices];
  self->fetchInvoices = NO;
  [self _resetSelected];
  return nil;
}

- (id)printMonition {
  SkyInvoicePrintoutFormatter *format = [self formatter];
  WOResponse *response =
    [WOResponse responseWithRequest: [[self context] request]];
  [response setStatus:200];
  [response setHeader:@"text/plain"
            forKey:@"content-type"];
  [response setContent: [format createOutput]];
  return response;
}

- (id)certifyMonitionPrintout {
  [self runCommand:@"enterprise::print-monition",
        @"object", [self debitor],
        @"invoices", [self unsettledInvoices],
        @"printout", [[self formatter] createOutput],
        nil];
  [self postChange:@"LSWNewInvoiceAction" onObject:[self unsettledInvoices]];
  return nil;
}

- (id)settleInvoices {
  NSArray      *eos     = [self selectedEOs];
  NSEnumerator *invEnum = [eos objectEnumerator];
  id inv;
  while ((inv = [invEnum nextObject])) {
    [self runCommand:@"invoice::finish",
          @"object", inv,
          nil];
    [self postChange:@"LSWUpdatedInvoice" onObject: inv];
  }
  if (self->fetchInvoices) {
    [self _fetchInvoices];
    self->fetchInvoices = NO;
  }
  [self _resetSelected];
  return nil;
}

@end /* SkyUnsettledInvoicesViewer */

@implementation SkyUnsettledInvoicesViewer(PrivateMethods)

- (id)debitor {
  return [self object];
}
- (void)setTabKey:(NSString*)_key {
  ASSIGN(self->tabKey,_key);
}
- (void)setViewerTitle:(NSString*)_title {
  ASSIGN(self->viewerTitle,_title);
}
- (void)setUnsettledInvoices:(NSArray*)_invoices {
  ASSIGN(self->unsettledInvoices,_invoices);
}
- (void)setFormatter:(SkyInvoicePrintoutFormatter*)_formatter {
  ASSIGN(self->formatter,_formatter);
}
- (NSString *)currency {
  return [[(id)[self session] userDefaults] stringForKey:@"invoice_currency"];
}

- (void)_resetSelected {
  if (self->selected != nil)
    RELEASE(self->selected);
  
  self->selected = [NSMutableArray array];
  RETAIN(self->selected);
}


@end /* SkyUnsettledInvoicesViewer(PrivateMethods) */
