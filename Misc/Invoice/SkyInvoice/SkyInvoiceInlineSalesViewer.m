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

@class NSArray, NSNumber;

@interface SkyInvoiceInlineSalesViewer : LSWComponent
{
  NSArray *sales;
  id      sale;

  NSString *from;
  NSString *to;

  NSNumber *allNet;
  NSNumber *allGross;

  NSArray  *validArticles;

  BOOL     detailsOn;
  BOOL     showSkyrix;          // else showMDLink
}

- (void)_fetchSales;

@end /* SkyInvoiceInlineSalesViewer */

#import <Foundation/Foundation.h>
#include <math.h>
#include <NGExtensions/NGExtensions.h>
#include <LSFoundation/LSFoundation.h>
#include <OGoFoundation/OGoFoundation.h>
#include "SkyCurrencyFormatter.h"

@implementation  SkyInvoiceInlineSalesViewer

- (id)init {
  if ((self = [super init])) {
    NSCalendarDate *date = [NSCalendarDate date];
    self->sales = nil;
    self->sale  = nil;
    
    self->to    = [date descriptionWithCalendarFormat:@"%Y-%m-%d"];
    RETAIN(self->to);
    date = [date dateByAddingYears:0 months:-1 days:0];
    self->from  = [date descriptionWithCalendarFormat:@"%Y-%m-%d"];
    RETAIN(self->from);

    self->allNet        = nil;
    self->allGross      = nil;
    self->validArticles = nil;

    self->detailsOn  = NO;
    self->showSkyrix = YES;
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->sales);
  RELEASE(self->sale);
  RELEASE(self->from);
  RELEASE(self->to);
  RELEASE(self->allNet);
  RELEASE(self->allGross);
  RELEASE(self->validArticles);
  [super dealloc];
}
#endif

// accessors
- (BOOL)synchronizesVariablesWithBindings {
  return NO;
}

- (NSArray *)sales {
  if (self->sales == nil) {
    [self _fetchSales];
  }
  if (self->detailsOn) {
    NSEnumerator   *e   = [self->sales objectEnumerator];
    NSMutableArray *all = [NSMutableArray array];
    id             one  = nil;

    while ((one = [e nextObject])) {
      [all addObject:one];
      [all addObjectsFromArray:[one valueForKey:@"articles"]];
    }
    return all;
  }
  return self->sales;
}
- (void)setSale:(id)_sale {
  ASSIGN(self->sale,_sale);
}
- (id)sale {
  return self->sale;
}

- (NSNumber *)allNet {
  if (self->allNet == nil) {
    [self _fetchSales];
  }
  return self->allNet;
}
- (NSNumber *)allGross {
  if (self->allGross == nil) {
    [self _fetchSales];
  }
  return self->allGross;
}

- (void)setFrom:(NSString *)_from {
  ASSIGN(self->from,_from);
}
- (NSString *)from {
  return self->from;
}

- (void)setTo:(NSString *)_to {
  ASSIGN(self->to,_to);
}
- (NSString *)to {
  return self->to;
}

- (NSArray *)validArticles {
  if (self->validArticles == nil) {
    self->validArticles = [self valueForBinding:@"validArticleIds"];
    RETAIN(self->validArticles);
  }
  return self->validArticles;
}

// fetching

- (NSCalendarDate *)_fromDate {
  NSCalendarDate *date = [NSCalendarDate dateWithString:self->from
                                         calendarFormat:@"%Y-%m-%d"];
  return (date == nil)
    ? [[NSCalendarDate date] beginOfDay]
    : [date beginOfDay];
}
- (NSCalendarDate *)_toDate {
  NSCalendarDate *date = [NSCalendarDate dateWithString:self->to
                                         calendarFormat:@"%Y-%m-%d"];
  return (date == nil)
    ? [[NSCalendarDate date] endOfDay]
    : [date endOfDay];
}
- (NSArray *)_fetchInvoices {
  NSCalendarDate *start = nil;
  NSCalendarDate *end   = nil;

  start = [self _fromDate];
  end   = [self _toDate];

  return [self runCommand:@"invoice::get",
               @"from", start,
               @"to", end,
               @"states", [NSArray arrayWithObjects:
                                   @"10_canceled",
                                   @"15_monition",
                                   @"16_monition2",
                                   @"17_monition3",
                                   @"20_done",
                                   nil],
               @"returnType", intObj(LSDBReturnType_ManyObjects),
               nil];
}

- (NSArray *)_fetchArticlesForInvoice:(id)_inv {
  return [self runCommand:@"invoice::get-articles",
               @"object", _inv,
               nil];
}

- (NSArray *)_filterArticlesForInvoice:(id)_inv {
  NSEnumerator *e  = [[self _fetchArticlesForInvoice:_inv] objectEnumerator];
  id           one = nil;
  
  NSMutableArray *filtered = [NSMutableArray array];

  while ((one = [e nextObject])) {
    if (([[self validArticles] containsObject:[one valueForKey:@"articleId"]]))
      [filtered addObject:one];
  }
  return filtered;
}

- (void)_handleArticles:(NSArray *)_arts
              netAmount:(double *)_net
            grossAmount:(double *)_gross
                mapping:(NSDictionary **)_mapping
{
  NSEnumerator        *e       = [_arts objectEnumerator];
  id                  one      = nil;
  NSMutableDictionary *mapping = nil;

  mapping = [NSMutableDictionary dictionaryWithCapacity:8];
  
  while ((one = [e nextObject])) {
    double cnt;
    double net;
    double vat;
    double gross;

    id dict;

    cnt      = [[one valueForKey:@"articleCount"] doubleValue];
    net      = [[one valueForKey:@"allNetAmount"] doubleValue];
    
    dict = [mapping valueForKey:[one valueForKey:@"articleId"]];
    if (dict == nil) {
      dict =
        [NSMutableDictionary dictionaryWithObjectsAndKeys:
                             [one valueForKey:@"articleName"],  @"name",
                             [one valueForKey:@"articleNr"],    @"nr",
                             [one valueForKey:@"netAmount"],    @"net",
                             [one valueForKey:@"vat"],          @"vat",
                             
                             [one valueForKey:@"articleCount"], @"count",
                             [one valueForKey:@"allNetAmount"], @"allNet",
                             nil];
    }
    else {
      double allCnt = [[dict valueForKey:@"count"]  doubleValue] + cnt;
      double allN   = [[dict valueForKey:@"allNet"] doubleValue] + net;
      [dict setObject:[NSNumber numberWithDouble:allCnt] forKey:@"count"];
      [dict setObject:[NSNumber numberWithDouble:allN]   forKey:@"allNet"];
    }
    [mapping setObject:dict forKey:[one valueForKey:@"articleId"]];
    
    vat      = [[one valueForKey:@"vat"] doubleValue];
    gross    = net * (1+vat);
    gross    = rint(gross * 100.0) * 0.01;
    
    *_net   += net;
    *_gross += gross;
    *_mapping = mapping;
  }
}

- (void)_computeValuesForArticles:(NSDictionary *)_kinds {
  NSEnumerator *e       = nil;
  NSString     *kind    = nil;
  NSArray      *arts    = nil;
  id           one      = nil;
  double        allNetA   = 0.0;
  double        allGrossA = 0.0;
  NSDictionary *mapping = nil;
  
  NSMutableArray *sls = [NSMutableArray array];  // sales

  e = [_kinds keyEnumerator];
  while ((kind = [e nextObject])) {
    double netAmount   = 0.0;
    double grossAmount = 0.0;
    arts = [_kinds valueForKey:kind];
    [self _handleArticles:arts netAmount:&netAmount grossAmount:&grossAmount
          mapping:&mapping];
    if ([kind isEqualToString:@"invoice_cancel"]) {
      allNetA   -= netAmount;
      allGrossA -= grossAmount;
    }
    else {
      allNetA   += netAmount;
      allGrossA += grossAmount;
    }
    one = 
      [NSDictionary dictionaryWithObjectsAndKeys:
                    kind,                                    @"kind",
                    [NSNumber numberWithDouble:netAmount],   @"netAmount",
                    [NSNumber numberWithDouble:grossAmount], @"grossAmount",
                    [mapping allValues],                     @"articles",
                    nil];
    [sls addObject:one];
  }
  ASSIGN(self->sales,sls);
  RELEASE(self->allNet);
  RELEASE(self->allGross);
  self->allNet   = [[NSNumber alloc] initWithDouble:allNetA];
  self->allGross = [[NSNumber alloc] initWithDouble:allGrossA];
}

- (BOOL)_checkForString:(NSString *)_one other:(NSString *)_other
              inInvoice:(id)_inv
{
  /*
   * one    - the 'must be'
   * other  - the 'may be' but not before one
   */
  NSString *number = nil;
  int      pos     = 0;
  int      pos2    = 0;

  number = [_inv valueForKey:@"invoiceNr"];
  if ((pos = [number indexOfString:_one]) == NSNotFound)
    return NO;
  if ((pos2 = [number indexOfString:_other]) == NSNotFound)
    return YES;

  return (pos < pos2)
    ? YES : NO;
}

// check invoice wether from skyrix RXX.XXXX
- (BOOL)_checkForSkyrix:(id)_inv {
  return [self _checkForString:@"." other:@"-" inInvoice:_inv];
}
// check invoice wether from mdlink RXX-XXXX
- (BOOL)_checkForMDLink:(id)_inv {
  return [self _checkForString:@"-" other:@"." inInvoice:_inv];
}

- (BOOL)showSkyrix {
  return self->showSkyrix;
}
- (BOOL)showMDLink {
  return (self->showSkyrix)
    ? NO : YES;
}

- (void)_fetchSales {
  NSArray             *invs  = nil;
  NSMutableDictionary *kinds = nil;
  NSEnumerator        *e     = nil;
  id                  one    = nil;

  // collecting articles
  kinds = [NSMutableDictionary dictionaryWithCapacity:4];

  invs = [self _fetchInvoices];
  e    = [invs objectEnumerator];
  while ((one = [e nextObject])) {
    NSString *key   = [one valueForKey:@"kind"];
    id       kind   = [kinds valueForKey:key];

    if (([self showSkyrix]) && (![self _checkForSkyrix:one]))
      continue;

    if (([self showMDLink]) && (![self _checkForMDLink:one]))
      continue;
        
    if (kind == nil)
      kind = [NSMutableArray array];
    
    [kind addObjectsFromArray:[self _filterArticlesForInvoice:one]];
    if ([kind count] > 0)
      [kinds setObject:kind forKey:key];
  }

  // computing result
  [self _computeValuesForArticles:kinds];
}

// actions

- (id)showSales {
  RELEASE(self->sales); self->sales = nil;

  return nil;
}

- (id)changeToMDLink {
  self->showSkyrix = NO;
  return [self showSales];
}
- (id)changeToSkyrix {
  self->showSkyrix = YES;
  return [self showSales];
}

- (id)showDetails {
  self->detailsOn = YES;
  return nil;
}
- (id)hideDetails {
  self->detailsOn = NO;
  return nil;
}

// values

- (NSString *)kindLabelKey {
  return [self->sale valueForKey:@"kind"];
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
- (NSFormatter *)numberFormatter {
  NSNumberFormatter *format = [[NSNumberFormatter alloc] init];
  [format setFormat:@".__0,00"];
  [format setThousandSeparator:@"."];
  [format setDecimalSeparator:@","];
  return AUTORELEASE(format);
}

- (BOOL)isDetail {
  return ([self->sale valueForKey:@"kind"] == nil)
    ? YES : NO;
}
- (BOOL)detailsOn {
  return self->detailsOn;
}

@end /* SkyInvoiceInlineSalesViewer */
