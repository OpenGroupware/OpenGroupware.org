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

#include "SkyInvoiceArticleEditor.h"
#include "SkyCurrencyFormatter.h"
#include "common.h"

@interface SkyInvoiceArticleEditor(PrivateMethods)
- (void)setUnits:(NSArray*)_units;
- (void)setCategories:(NSArray*)_categories;
- (void)setVats:(NSDictionary*)_vats;
- (void)_fetchUnits;
- (void)_fetchCategories;
//- (void)_parseValues;
- (NSMutableDictionary*)article;
@end

@implementation SkyInvoiceArticleEditor

- (id)init {
  if((self = [super init])) {
    [self registerForNotificationNamed:@"LSWNewArticleCategory"];
    [self registerForNotificationNamed:@"LSWUpdatedArticleCategory"];
    [self registerForNotificationNamed:@"LSWDeletedArticleCategory"];
    
    [self registerForNotificationNamed:@"LSWNewArticleUnit"];
    [self registerForNotificationNamed:@"LSWUpdatedArticleUnit"];
    [self registerForNotificationNamed:@"LSWDeletedArticleUnit"];

    self->fetchUnits = YES;
    self->fetchCategories = YES;
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->units);
  RELEASE(self->vats);
  RELEASE(self->categories);
  RELEASE(self->item);
  [super dealloc];
}
#endif

- (BOOL)prepareForEditCommand:(NSString *)_command
  type: (NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  id article =  [self snapshot];
  id obj     =  [self object];
  id unit    =  [obj valueForKey:@"articleUnit"];
  id category = [obj valueForKey:@"articleCategory"];

  [article takeValue:unit     forKey:@"articleUnit"];
  [article takeValue:category forKey:@"articleCategory"];

  return YES;
}

- (BOOL)prepareForActivationCommand:(NSString *)_command
  type: (NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  NSDictionary *vatDict =
    [NSDictionary dictionaryWithDictionary:
                  [[[self session] userDefaults]
                          dictionaryForKey:
                          @"invoice_article_vat_groups"]];
  [self setVats:vatDict];
 
  return  [super prepareForActivationCommand:_command
                 type:_type
                 configuration:_cmdCfg];
}

- (BOOL)prepareForNewCommand:(NSString *)_command
                        type:(NGMimeType *)_type
               configuration:(NSDictionary *)_cmdCfg
{
  [[self article] takeValue:@"vat_A" forKey:@"vatGroup"];
  return YES;
}
  
- (void)syncAwake {
  [super syncAwake];

  if (self->fetchUnits) {
    [self _fetchUnits];
    self->fetchUnits = NO;
  }
  if (self->fetchCategories) {
    [self _fetchCategories];
    self->fetchCategories = NO;
  }
}

- (void)noteChange:(NSString*)_cn onObject:(id)_object {
  [super noteChange:_cn onObject:_object];

  if (([_cn isEqualToString:@"LSWNewArticleCategory"]) ||
      ([_cn isEqualToString:@"LSWUpdatedArticleCategory"]) ||
      ([_cn isEqualToString:@"LSWDeletedArticleCategory"]))
    {
      self->fetchCategories = YES;
    }
  if (([_cn isEqualToString:@"LSWNewArticleUnit"]) ||
      ([_cn isEqualToString:@"LSWUpdatedArticleUnit"]) ||
      ([_cn isEqualToString:@"LSWDeletedArticleUnit"]))
    {
      self->fetchUnits = YES;
    }
}

- (void)_fetchUnits {
  [self setUnits:
        [self runCommand: @"articleunit::get",
              @"returnType", intObj(LSDBReturnType_ManyObjects),
              nil]];
}

- (void)_fetchCategories {
  [self setCategories:
        [self runCommand: @"articlecategory::get",
              @"returnType", intObj(LSDBReturnType_ManyObjects),
              nil]];
}

//accessors

- (NSMutableDictionary *)article {
  return [self snapshot];
}

- (void)setUnits:(NSArray *)_units {
  ASSIGN(self->units, _units);
}
- (NSArray *)units {
  return self->units;
}

- (void)setCategories:(NSArray *)_categories {
  ASSIGN(self->categories, _categories);
}
- (NSArray *)categories {
  return self->categories;
}

- (void)setVats:(NSDictionary *)_vats {
  ASSIGN(self->vats, _vats);
}
- (NSDictionary *)vats {
  return self->vats;
}

- (void)setItem:(id)_item {
  ASSIGN(self->item, _item);
}
- (id)item {
  return self->item;
}

- (NSString *)currency {
  return [[(id)[self session] userDefaults] stringForKey:@"invoice_currency"];
}
- (NSFormatter *)currencyFormatter {
  SkyCurrencyFormatter *f = [[SkyCurrencyFormatter alloc] init];

  [f setCurrency:[self currency]];
  [f setFormat:@".__0,00"];
  [f setThousandSeparator:@"."];
  [f setDecimalSeparator:@","];

  return AUTORELEASE(f);
}
//

- (NSArray *)vatGroups {
  return [self->vats allKeys];
}

- (NSString *)vatValue {
  return [[[self->vats objectForKey:self->item]
                       objectForKey:@"factor"]
                       stringValue];
}

// notifications

- (NSString *)insertNotificationName {
  return @"LSWNewInvoiceArticle";
}
- (NSString *)updateNotificationName {
  return @"LSWUpdatedInvoiceArticle";
}
- (NSString *)deleteNotificationName {
  return @"LSWDeletedInvoiceArticle";
}

//actions

- (void)_parseValues {
  double   vat  = 0.00;
  float    vatf = 0.00;
  NSString *vatGroup;
  id       at;

  at       = [self article];
  vatGroup = [at valueForKey:@"vatGroup"];

  vat = [[[self->vats objectForKey:vatGroup] objectForKey:@"factor"]
                      doubleValue];
  vat = rint(vat * 100.0) * 0.01;
  vatf = vat * 1.0;
  [at setObject:[NSNumber numberWithFloat:vatf] forKey:@"vat"];
  [at setObject:
      [[at valueForKey:@"articleUnit"] valueForKey:@"articleUnitId"]
      forKey: @"articleUnitId"];
  [at setObject:[[at valueForKey:@"articleCategory"]
                     valueForKey:@"articleCategoryId"]
      forKey: @"articleCategoryId"];
}

- (id)insertObject {
  [self _parseValues];
  return [self runCommand:@"article::new" arguments:[self article]];
}

- (id)updateObject {
  [self _parseValues];
  return [self runCommand:@"article::set" arguments:[self article]];
}

@end
