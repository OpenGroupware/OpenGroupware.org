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


#include <OGoFoundation/LSWComponent.h>

// this list is for real articles
// (articles not bound to an invoice)

// takes current currency from the userDefaults: invoice_currency

@class EODataSource;
@class NSFormatter;

@interface SkyArticlesList : LSWComponent
{
  NSArray         *articles;           // > articles
  NSString        *action;             // > action (String)

  NSFormatter     *currencyFormatter;
  NSFormatter     *numberFormatter;
  id              item;                // > item

  EODataSource    *dataSource;
}

@end /* SkyArticlesList */

#import <Foundation/Foundation.h>

#include <OGoFoundation/LSWSession.h>
#include "SkyCurrencyFormatter.h"
#import <Foundation/NSFormatter.h>
#include <EOControl/EOArrayDataSource.h>


@implementation SkyArticlesList

- (id)init {
  if ((self = [super init])) {
    self->articles          = nil;
    self->currencyFormatter = nil;
    self->numberFormatter   = nil;
    self->item              = nil;
    self->action            = nil;
    self->dataSource        = nil;
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
  RELEASE(self->dataSource);
  [super dealloc];
}
#endif

- (void)sleep {
  [super sleep];

  RELEASE(self->currencyFormatter); self->currencyFormatter = nil;
}

// accessors
- (void)setArticles:(NSArray *)_articles {
  if (![self->articles isEqual:_articles]) {
    RELEASE(self->dataSource); self->dataSource = nil;
  }
  ASSIGN(self->articles,_articles);
}
- (NSArray *)articles {
  return self->articles;
}

- (EODataSource *)dataSource {
  if (self->dataSource == nil) {
    EOArrayDataSource *ds = [[EOArrayDataSource alloc] init];
    [ds setArray:self->articles];
    self->dataSource = ds;
  }
  return self->dataSource;
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

@end /* SkyArticlesList */
