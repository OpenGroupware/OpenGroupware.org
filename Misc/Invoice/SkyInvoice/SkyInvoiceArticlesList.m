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

#include <OGoFoundation/LSWComponent.h>

// this list is for articles of a invoice, not simple invoicearticles, but
// special invoice_article_bindings

// takes current currency from the userDefaults: invoice_currency

#import <Foundation/NSFormatter.h>

@interface SkyInvoiceArticlesList : LSWComponent
{
  NSArray         *articles;           // > articles
  NSString        *action;             // > action (String)

  NSFormatter     *currencyFormatter;
  NSFormatter     *numberFormatter;
  id              item;                // > item
}

@end /* SkyInvoiceArticlesList */

#import <Foundation/Foundation.h>

#include <OGoFoundation/LSWSession.h>
#include "SkyCurrencyFormatter.h"

@implementation SkyInvoiceArticlesList

- (id)init {
  if ((self = [super init])) {
    self->articles          = nil;
    self->currencyFormatter = nil;
    self->numberFormatter   = nil;
    self->item              = nil;
    self->action            = nil;
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->articles);
  RELEASE(self->action);
  RELEASE(self->currencyFormatter);
  RELEASE(self->numberFormatter);
  RELEASE(self->item);
  [super dealloc];
}
#endif

- (void)sleep {
  [super sleep];

  RELEASE(self->currencyFormatter); self->currencyFormatter = nil;
}

// accessors
- (void)setArticles:(NSArray *)_articles {
  ASSIGN(self->articles,_articles);
}
- (NSArray *)articles {
  return self->articles;
}

- (void)setItem:(id)_item {
  ASSIGN(self->item,_item);
}
- (id)item {
  return self->item;
}

- (void)setAction:(NSString *)_action {
  ASSIGN(self->action,_action);
}
- (NSString *)action {
  return self->action;
}

- (NSString *)currency {
  return [[(id)[self session] userDefaults] stringForKey:@"invoice_currency"];
}
- (NSFormatter *)currencyFormatter {
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
- (NSFormatter *)numberFormatter {
  if (self->numberFormatter == nil) {
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];

    [f setFormat:@".__0,00"];
    [f setThousandSeparator:@"."];
    [f setDecimalSeparator:@","];

    self->numberFormatter = f;
  }

  return self->numberFormatter;
}

- (BOOL)hasAction {
  return (self->action)
    ? YES : NO;
}
- (id)viewArticle {
  return [self performParentAction:self->action];
}

@end /* SkyInvoiceArticlesList */
