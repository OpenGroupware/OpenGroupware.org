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

#include "SkyInvoiceViewer.h"
#include "SkyInvoiceEditor.h"
#include "common.h"
#include <OGoFoundation/LSWSession.h>
#include <OGoFoundation/LSWNotifications.h>
#include "SkyCurrencyFormatter.h"

@interface SkyInvoiceViewer(PrivateMethods)
- (void)setTabKey:(NSString *)_key;
- (void)_fetchDebitor;
- (void)_fetchActions;
- (void)_fetchArticles;
- (void)_fetchAdditional;
- (void)_loadFormatter;
- (void)setArticles:(NSArray*)_articles;
- (void)setActions:(NSArray*)_actions;
- (id)invoice;
- (NSArray*)articles;
- (void)setFormatter:(SkyInvoicePrintoutFormatter*)_formatter;
- (BOOL)isInvoiceNotPrinted;
- (NSString *)currency;
@end

@interface WOComponent(PrivateMethods)
- (void)setInvoice:(id)_invoice;
@end

@implementation SkyInvoiceViewer

- (id)init {
  if ((self = [super init])) {
    NSUserDefaults *ud= [[self session] userDefaults];
    NSString* subView =
      [ud valueForKey:@"invoice_viewer_sub_view"];
    [self setTabKey:(subView != nil) ? subView : @"attributes"];
    
    [self registerForNotificationNamed:@"LSWNewInvoice"];
    [self registerForNotificationNamed:@"LSWUpdatedInvoice"];
    [self registerForNotificationNamed:@"LSWDeletedInvoice"];
    [self registerForNotificationNamed:@"LSWUpdatedInvoiceArticle"];
    [self registerForNotificationNamed:@"LSWNewInvoiceAccounting"];
    
    self->fetchDebitor    = YES;
    self->fetchArticles   = YES;
    self->reloadFormatter = YES;
    self->fetchActions    = YES;
    self->fetchAdditionalInvoiceValues = YES;

    self->currency = [ud stringForKey:@"invoice_currency"];
    RETAIN(self->currency);
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->tabKey);
  RELEASE(self->articles);
  RELEASE(self->article);
  RELEASE(self->actions);
  RELEASE(self->action);
  RELEASE(self->selectedAttribute);
  RELEASE(self->formatter);
  RELEASE(self->currency);
  [super dealloc];
}
#endif

- (void)noteChange:(NSString*)_cn onObject:(id)_object {
  [super noteChange:_cn onObject:_object];

  if (([_cn isEqualToString:@"LSWNewInvoice"]) ||
      ([_cn isEqualToString:@"LSWUpdatedInvoice"]) ||
      ([_cn isEqualToString:@"LSWDeletedInvoice"]) ||
      ([_cn isEqualToString:@"LSWUpdatedInvoiceArticle"]))
    {
      self->fetchArticles = YES;
      self->fetchDebitor  = YES;
      self->reloadFormatter = YES;
      self->fetchActions = YES;
      self->fetchAdditionalInvoiceValues = YES;
    }
  if ([_cn isEqualToString:@"LSWNewInvoiceAccounting"]) {
    self->fetchActions = YES;
    self->reloadFormatter = YES;
  }
}

- (void)syncAwake {
  [super syncAwake];

  if (self->fetchDebitor) {
    [self _fetchDebitor];
    self->fetchDebitor = NO;
  }
  if (self->fetchArticles) {
    [self _fetchArticles];
    self->fetchArticles = NO;
  }
  if (self->reloadFormatter) {
    [self _loadFormatter];
    self->reloadFormatter = NO;
  }
  if (self->fetchAdditionalInvoiceValues) {
    [self _fetchAdditional];
    self->fetchAdditionalInvoiceValues = NO;
  }
  if (self->fetchActions) {
    [self _fetchActions];
    self->fetchActions = NO;
  }
  if ((![self isInvoiceNotPrinted]) &&
      ([self->tabKey isEqualToString:@"preview"])) {
    [self setTabKey:@"attributes"];
  }
}

- (void)_fetchAdditional {
  [self runCommand:@"invoice::fetch-additional",
        @"objects", [NSArray arrayWithObject: [self invoice]],
        nil];
}

- (void)_fetchDebitor {
  [self runCommand:@"invoice::set-debitor",
        @"relationKey", @"debitor",
        @"object", self->object,
        nil];
}

- (void)_loadFormatter {
  NSUserDefaults *ud             = [[self session] userDefaults];
  NSDictionary   *formatSettings =
    [ud dictionaryForKey:@"invoice_format_settings"];
  NSDictionary   *settings       =
    [formatSettings objectForKey:@"standard-printout"];
  SkyInvoicePrintoutFormatter *printout =
    [SkyInvoicePrintoutFormatter skyInvoicePrintoutFormatterWithDefaultSettings: settings];
  NSDictionary* invoiceKinds     = [ud dictionaryForKey:@"invoice_kinds"];
  NSDictionary* invoiceKind      =
    [invoiceKinds objectForKey:[[self invoice] valueForKey:@"kind"]];
  NSString *printoutAttr         = [invoiceKind objectForKey:@"printout"];
  
  if (printoutAttr != nil) {
    [printout setFormatSettings:
              [formatSettings objectForKey:printoutAttr]];
  }

  [printout setCurrency: [self currency]];
  [printout setInvoice:  [self invoice]];
  [printout setDebitor:  [[self invoice] valueForKey:@"debitor"]];
  [printout setArticles: [self articles]];
  [self setFormatter:printout];
}

- (void)_fetchArticles {
  [self setArticles: [self runCommand:@"invoice::get-articles",
                           @"object", [self object],
                           @"returnType", intObj(LSDBReturnType_ManyObjects),
                           nil]];
}

- (void)_fetchActions {
  [self setActions:
        [self runCommand:@"invoiceaction::get",
              @"invoiceId", [[self invoice] valueForKey:@"invoiceId"],
              @"returnType", intObj(LSDBReturnType_ManyObjects),
              nil]];
  [self runCommand:@"invoiceaction::fetch-account",
        @"relationKey", @"account",
        @"objects", self->actions,
        nil];
  [self runCommand:@"invoiceaction::fetch-document",
        @"relationKey", @"document",
        @"objects", self->actions,
        nil];
  [self runCommand:@"invoiceaction::fetch-accounting",
        @"relationKey", @"accounting",
        @"objects", self->actions,
        nil];
}

// accessors

- (id)invoice {
  return self->object;
}

- (void)setTabKey:(NSString *)_tabKey {
  ASSIGN(self->tabKey, _tabKey);
}
- (NSString *)tabKey {
  return self->tabKey;
}

- (NSArray*)articles {
  return self->articles;
}
- (void)setArticles:(NSArray*)_articles {
  ASSIGN(self->articles,_articles);
}

- (void)setActions:(NSArray*)_actions {
  ASSIGN(self->actions,_actions);
}
- (NSArray*)actions {
  return self->actions;
}

- (id)article {
  return self->article;
}
- (void)setArticle:(id)_article {
  ASSIGN(self->article,_article);
}

- (void)setAction:(id)_action {
  ASSIGN(self->action,_action);
}
- (id)action {
  return self->action;
}

- (void)setStart:(unsigned)_startIndex {
  self->startIndex = _startIndex;
}
- (unsigned)start {
  return self->startIndex;
}

- (BOOL)isDescending {
  return self->isDescending;
}
- (void)setIsDescending:(BOOL)_isDescending {
  self->isDescending = _isDescending;
}

- (NSDictionary*)selectedAttribute {
  return self->selectedAttribute;
}
- (void)setSelectedAttribute:(NSDictionary*)_selectedAttribute {
  ASSIGN(self->selectedAttribute,_selectedAttribute);
}

- (void)setFormatter:(SkyInvoicePrintoutFormatter*)_formatter {
  ASSIGN(self->formatter,_formatter);
}
- (SkyInvoicePrintoutFormatter*)formatter {
  return self->formatter;
}

- (void)setCurrency:(NSString *)_cur {
  if (![_cur isEqualToString:self->currency]) {
    ASSIGN(self->currency,_cur);
    [[[self session] userDefaults] setObject:_cur forKey:@"invoice_currency"];
    self->reloadFormatter = YES;
  }
}
- (NSString *)currency {
  return self->currency;
}

//conditional

- (BOOL)isEditEnabled {
  return ([[self->object valueForKey:@"status"]
                         isEqualToString:@"00_created"])
    ? YES : NO;
}

- (BOOL)isDeleteEnabled {
  return ([[self->object valueForKey:@"status"]
                         isEqualToString:@"00_created"])
    ? YES : NO;
}

- (BOOL)isPrintEnabled {
  return ([[self->object valueForKey:@"status"]
                         isEqualToString:@"00_created"])
    ? YES : NO;
}

- (BOOL)isNewArticleEnabled {
  id parent = [self->object valueForKey:@"parentInvoiceId"];
  if ((parent != nil) && ([parent isNotNull]))
    return NO;
  return ([[self->object valueForKey:@"status"]
                         isEqualToString:@"00_created"])
    ? YES : NO;
}

- (BOOL)isMonitionEnabled {
  NSString *status;

  if ([[self->object valueForKey:@"kind"] isEqualToString:@"invoice_cancel"])
    return NO;
    
  status = [self->object valueForKey:@"status"];
  return (([status isEqualToString:@"05_printed"]) ||
          ([status isEqualToString:@"15_monition"]) ||
          ([status isEqualToString:@"16_monition2"]))
    ? YES : NO;
}

- (BOOL)isCancelEnabled {
  NSString *status;

  if ([[self->object valueForKey:@"kind"] isEqualToString:@"invoice_cancel"])
    return NO;

  status = [self->object valueForKey:@"status"];
  return (([status isEqualToString:@"05_printed"]) ||
          ([status isEqualToString:@"15_monition"]) ||
          ([status isEqualToString:@"16_monition2"]) ||
          ([status isEqualToString:@"17_monition3"]))
    ? YES : NO;
}

- (BOOL)isFinishEnabled {
  NSString *status;

  status = [self->object valueForKey:@"status"];
  return (([status isEqualToString:@"05_printed"]) ||
          ([status isEqualToString:@"15_monition"]) ||
          ([status isEqualToString:@"16_monition2"]) ||
          ([status isEqualToString:@"17_monition3"]))
    ? YES : NO;
}

- (BOOL)isAccountingEnabled {
  if ([[self->object valueForKey:@"kind"] isEqualToString:@"invoice_cancel"])
    return NO;
  return [self isFinishEnabled];
}

- (BOOL)isInvoiceNotPrinted {
  return ([[self->object valueForKey:@"status"]
                         isEqualToString:@"00_created"])
                         ? YES : NO;
}

- (BOOL)isCopyEnabled {
  return YES;
}

- (NSFormatter *)currencyFormatter {
  //  NSNumberFormatter* format = [[NSNumberFormatter alloc] init];
  SkyCurrencyFormatter *format = [[SkyCurrencyFormatter alloc] init];
  [format setCurrency:[self currency]];
  [format setShowCurrencyLabel:YES];
  
  [format setFormat:@".__0,00"];
  [format setThousandSeparator:@"."];
  [format setDecimalSeparator:@","];
  return AUTORELEASE(format);
}

- (NSString*)printoutString {
  SkyInvoicePrintoutFormatter *printout = [self formatter];

  return [printout formattedString];
}

//actions

- (id)edit {
  if ([self isEditEnabled])
    return [super edit];
  [self setErrorString:@"Invoice isn't editable in this status!"];
  return nil;
}

- (id)delete {
  [self setWarningOkAction:@"reallyDelete"];
  [self setWarningPhrase:@"Really Delete"];
  [self setIsInWarningMode:YES];

  return nil;
}

- (id)reallyDelete {
  id result;

  result = [[self object] run:@"invoice::delete",
                         @"reallyDelete", [NSNumber numberWithBool:YES],
                         nil];
  [self setIsInWarningMode:NO];
  [self postChange:@"LSWDeletedInvoice" onObject: result];
  [self back];
  
  return nil;
}

- (id)printInvoice {
  if ([self isPrintEnabled]) {
    WOResponse *response = nil;
    SkyInvoicePrintoutFormatter *printout = [self formatter];

    response = [WOResponse responseWithRequest:[[self context] request]];
    [response setStatus:200];
    [response setHeader:@"text/plain"
              forKey:@"content-type"];
    [response setContent:[printout createOutput]];
    return response;
  }

  return nil;
}

- (id)monition {
  [self runCommand:@"invoice::monition",
        @"object", [self invoice],
        nil];
  [self postChange:@"LSWUpdatedInvoice" onObject:[self invoice]];
  return nil;
}

- (id)cancelInvoice {
  NGMimeType  *mt = [NGMimeType mimeType:@"eo/invoice"];
  SkyInvoiceEditor *ct = nil;
  NSString *cmd = @"invoice::cancel";
  id obj = [self invoice];

  [obj run: cmd, nil];

  if (![self commit]) {
    [self rollback];
    return nil;
  }

  [self postChange:@"LSWUpdatedInvoice" onObject:[self invoice]];
  ct = (SkyInvoiceEditor*)
    [[self session] instantiateComponentForCommand:@"new" type:mt];
  [ct setReference: obj];
  if (ct) [self enterPage:(id)ct];

  return nil;
}

- (id)finishInvoice {
  [self runCommand:@"invoice::finish",
        @"object", [self invoice],
        nil];
  [self postChange:@"LSWUpdatedInvoice" onObject:[self invoice]];
  return nil;
}

- (id)copyInvoice {
  id newInvoice = [[self runCommand:@"invoice::copy-invoices",
                        @"invoices",
                        [NSArray arrayWithObject:[self invoice]],
                        nil] lastObject];
  if (newInvoice != nil) {
    [[self session] transferObject:newInvoice owner:self];
    [self executePasteboardCommand:@"view"];
  }
  
  return nil;
}

- (id)certifyPrintout {
  [self runCommand:@"invoice::print",
        @"object",   [self invoice],
        @"printout", [[self formatter] createOutput],
        nil];
  [self postChange:@"LSWUpdatedInvoice" onObject: [self invoice]];
  return nil;
}

- (id)tabClicked {
  return nil;
}

- (id)viewDebitor {
  [[self session] transferObject:[self->object valueForKey:@"debitor"]
                  owner:self];
  [self executePasteboardCommand:@"view"];
  return nil;
}

- (id)viewArticle {
  [[self session] transferObject: self->article
                  owner:self];
  [self executePasteboardCommand:@"view"];
  return nil;
}

- (id)cancel {
  [self setIsInWarningMode:NO];
  return nil;
}

- (id)newArticleAssignment {
  NGMimeType  *mt = [NGMimeType mimeType:@"eo/invoicearticleassignment"];
  WOComponent *ct = nil;

  ct = [[self session] instantiateComponentForCommand:@"new" type:mt];
  if (ct) {
    [ct setInvoice: [self invoice]];
    [self enterPage:(id)ct];
  }
  return nil;
}

- (id)accounting {
  NGMimeType  *mt;
  WOComponent *ct = nil;
  id inv;
  id acc;

  mt = [NGMimeType mimeType:@"eo/invoiceaccounting"];

  inv = [self invoice];
  acc = [self runCommand: @"invoiceaccount::get",
              @"companyId", [inv valueForKey:@"debitorId"],
              nil];
  acc = [acc lastObject];

  if ((acc == nil) || (![acc isNotNull])) {
    acc =
      [self runCommand: @"enterprise::create-invoiceaccount",
            @"object", [inv valueForKey:@"debitor"],
            nil];
  }

  ct = [[self session] instantiateComponentForCommand:@"new" type:mt];

  if (ct) {
    [ct takeValue: inv forKey:@"invoice"];
    [ct takeValue: acc forKey:@"account"];
    [self enterPage:(id)ct];
  }
  return nil;
}

- (id)viewAccount {
  [[self session] transferObject:[self->action valueForKey:@"account"]
                  owner:self];
  [self executePasteboardCommand:@"view"];
  return nil;
}

- (id)viewDocument {
  [[self session] transferObject:[self->action valueForKey:@"document"]
                  owner:self];
  [self executePasteboardCommand:@"view"];
  return nil;
}

@end
