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

#include "SkyInvoiceArticleViewer.h"
#include "common.h"
#include "SkyCurrencyFormatter.h"
#include <OGoFoundation/LSWSession.h>

@interface SkyInvoiceArticleViewer(PrivateMethods)
- (void)setTabKey:(NSString *)_key;
- (void)_fetchUnit;
- (void)_fetchCategory;
@end

@implementation SkyInvoiceArticleViewer

- (id)init {
  if ((self = [super init])) {
    [self setTabKey:@"attributes"];
    self->fetchUnit     = NO;
    self->fetchCategory = NO;
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->tabKey);
  [super dealloc];
}
#endif

- (void)syncAwake {
  [super syncAwake];

  if (self->fetchUnit) {
    [self _fetchUnit];
    self->fetchUnit = NO;
  }
  if (self->fetchCategory) {
    [self _fetchCategory];
    self->fetchCategory = NO;
  }
}

- (void)_fetchUnit {
  [self runCommand:@"article::set-unit",
        @"object",      [self object],
        @"relationKey", @"articleUnit",
        nil];
}

- (void)_fetchCategory {
  [self runCommand:@"article::set-category",
        @"object",      [self object],
        @"relationKey", @"articleCategory",
        nil];
}

//conditional

- (BOOL)isEditEnabled {
  return YES;
  // has to be improved
}

- (BOOL)isDeleteEnabled {
  return YES;
  // has to be improved
}

//accessors

- (id)article {
  return self->object;
}

- (void)setTabKey:(NSString *)_tabKey {
  ASSIGN(self->tabKey,_tabKey);
}
- (NSString *)tabKey {
  return self->tabKey;
}

- (NSFormatter*)numberFormatter {
  NSNumberFormatter* format = [[NSNumberFormatter alloc] init];
  [format setFormat:@"_,__0.00"];
  return AUTORELEASE(format);
}
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


//actions

- (id)edit {
  if ([self isEditEnabled]) {
    return [super edit];
  }
  [self setErrorString:@"Article isn't editable!"];
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

  result = [[self object] run:@"article::delete",
                         @"reallyDelete", [NSNumber numberWithBool:YES],
                         nil];
  [self setIsInWarningMode:NO];
  if (result) {
    if (![self commit]) {
      [self setErrorString:@"Couldn't commit article delete !"];
      [self rollback];
      return nil;
    }
    [self postChange:@"LSWDeletedInvoiceArticle" onObject: result];
    [self back];
  }
  
  return nil;
}


- (id)cancel {
  [self setIsInWarningMode:NO];
  return nil;
}

// sales
- (NSArray *)articleIds {
  return [NSArray arrayWithObject:[[self article] valueForKey:@"articleId"]];
}

@end
