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

#include "SkyInvoices.h"
#include "SkyInvoicePrintoutFormatter.h"
#include "SkyCurrencyFormatter.h"
#include "common.h"
#include <OGoFoundation/LSWSession.h>
#include <Foundation/NSDateFormatter.h>

@interface SkyInvoices(privateMethods)

//fetching functions
- (void)_fetchListInvoices;
- (void)_fetchBadDebitors;
- (id)searchArticles;
- (void)_fetchArticleCategories;
- (void)_fetchUnits;
- (void)_fetchAccounts;
- (NSArray *)_fetchOverviewInvoices;

//internal computing functions
- (NSArray *)_filterInvoices:(NSArray *)_allInvoices;
- (BOOL)_addString:(NSString *)_string toList:(NSMutableArray *)_list;
- (void)_computeKinds;
- (void)_computeMonth;
- (void)_setSortableArticleNr;

//accessors
- (void)setSelectedAttribute:(NSDictionary *)_attr;
- (void)setInvoices:(NSArray *)_invoices;
- (void)setListInvoices:(NSArray *)_invoices;
- (void)setSelected:(NSArray *)_selected;
- (void)setTabKey:(NSString *)_tabKey;
- (void)setSelectedYear:(NSString *)_year;
- (void)setMonths:(NSArray *)_months;
- (void)setOverviewFrom:(NSString *)_from;
- (void)setOverviewTo:(NSString *)_to;
- (void)setOverviewOutput:(NSString *)_output;

- (NSString *)currency;

- (void)_resetSelected;
@end

#include "SkyInvoiceDocument.h"

@implementation SkyInvoices

- (id)init {
  id p;

  /* this component is a session-singleton */
  if ((p = [self persistentInstance])) {
    RELEASE(self);
    return RETAIN(p);
  }

  if ((self = [super init])) {
    NSCalendarDate *now;

    [self registerAsPersistentInstance];
    
    [self setTabKey:@"invoices"];
    {
      id  s   = [self session];
      SEL sel = @selector(reloadInvoices:);
      [s addObserver:self selector:sel name:@"LSWNewInvoice"     object:nil];
      [s addObserver:self selector:sel name:@"LSWUpdatedInvoice" object:nil];
      [s addObserver:self selector:sel name:@"LSWDeletedInvoice" object:nil];
    }

    [self registerForNotificationNamed:@"LSWNewInvoiceArticle"];
    [self registerForNotificationNamed:@"LSWUpdatedInvoiceArticle"];
    [self registerForNotificationNamed:@"LSWDeletedInvoiceArticle"];

    [self registerForNotificationNamed:@"LSWNewArticleCategory"];
    [self registerForNotificationNamed:@"LSWUpdatedArticleCategory"];
    [self registerForNotificationNamed:@"LSWDeletedArticleCategory"];
    
    [self registerForNotificationNamed:@"LSWNewArticleUnit"];
    [self registerForNotificationNamed:@"LSWUpdatedArticleUnit"];
    [self registerForNotificationNamed:@"LSWDeletedArticleUnit"];
    
    self->fetchListInvoices = YES;
    self->fetchArticleCategories = YES;
    self->fetchUnits = YES;
    self->fetchBadDebitors = YES;
    self->fetchAccounts = YES;
    self->startIndex = 0;
    self->searchingInvoices = NO;

    now = [NSCalendarDate date];

    [self setSelectedYear:[now descriptionWithCalendarFormat:@"%Y"]];
    [self setMonths:[[[self session] userDefaults]
                            valueForKey:@"invoice_overview_months"]];
    [self _computeMonth];
    [self _computeKinds];
    [self setOverviewFrom:[now descriptionWithCalendarFormat:@"%Y-%m-%d"]];
    [self setOverviewTo:[now descriptionWithCalendarFormat:@"%Y-%m-%d"]];
    [self setOverviewOutput:@""];

    self->currencyFormatter = nil;

    self->selected = nil;
    [self _resetSelected];
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  [self unregisterAsObserver];
  [(id)[self session] removeObserver:self];
  RELEASE(self->listInvoices);
  RELEASE(self->invoices);
  RELEASE(self->badDebitors);
  RELEASE(self->selected);
  RELEASE(self->articles);
  RELEASE(self->accounts);
  RELEASE(self->articleSearchString);
  RELEASE(self->invoiceSearchString);
  RELEASE(self->articleCategories);
  RELEASE(self->units);
  RELEASE(self->selectedYear);
  RELEASE(self->months);
  RELEASE(self->selectedMonth);
  RELEASE(self->invoiceKinds);
  RELEASE(self->selectedKind);
  RELEASE(self->item);
  RELEASE(self->button);
  RELEASE(self->selectedAttribute);
  RELEASE(self->tabKey);
  RELEASE(self->overviewFrom);
  RELEASE(self->overviewTo);
  RELEASE(self->overviewOutput);
  RELEASE(self->currencyFormatter);
  [super dealloc];
}
#endif

- (void)sleep {
  [super sleep];
  RELEASE(self->currencyFormatter); self->currencyFormatter = nil;
}

- (void)syncAwake {
  [super syncAwake];

  if (self->fetchListInvoices && [self->tabKey isEqualToString:@"invoices"]) {
    [self _fetchListInvoices];
    self->fetchListInvoices = NO;

    [self setInvoices:[self _filterInvoices:self->listInvoices]];
  }

  if ((self->fetchBadDebitors) &&
      ([self->tabKey isEqualToString:@"monitions"])) {
    [self _fetchBadDebitors];
    self->fetchBadDebitors = NO;
  }

  if ((self->fetchAccounts) &&
      ([self->tabKey isEqualToString:@"accounts"])) {
    [self _fetchAccounts];
    self->fetchAccounts = NO;
  }

  if (self->fetchArticleCategories) {
    [self _fetchArticleCategories];
    self->fetchArticleCategories = NO;
  }

  if (self->fetchUnits) {
    [self _fetchUnits];
    self->fetchUnits = NO;
  }
}

- (void)syncSleep {
  [self setErrorString:nil];
  [super syncSleep];
}

- (void)reloadInvoices:(NSNotification *)_notification {
  self->fetchListInvoices = YES;
  self->fetchBadDebitors = YES;
  self->fetchAccounts = YES;
}

- (void)noteChange:(NSString *)_cn onObject:(id)_object {
  [super noteChange:_cn onObject:_object];

  if (([_cn isEqualToString:@"LSWNewInvoice"]) ||
      ([_cn isEqualToString:@"LSWUpdatedInvoice"]) ||
      ([_cn isEqualToString:@"LSWDeletedInvoice"]))
    {
      self->fetchListInvoices = YES;
      self->fetchBadDebitors = YES;
      self->fetchAccounts = YES;
    }
  if (([_cn isEqualToString:@"LSWNewInvoiceArticle"]) ||
      ([_cn isEqualToString:@"LSWUpdatedInvoiceArticle"]) ||
      ([_cn isEqualToString:@"LSWDeletedInvoiceArticle"]))
    {
      [self searchArticles];
    }
  if (([_cn isEqualToString:@"LSWNewArticleCategory"]) ||
      ([_cn isEqualToString:@"LSWUpdatedArticleCategory"]) ||
      ([_cn isEqualToString:@"LSWDeletedArticleCategory"]))
    {
      self->fetchArticleCategories = YES;
    }
  if (([_cn isEqualToString:@"LSWNewArticleUnit"]) ||
      ([_cn isEqualToString:@"LSWUpdatedArticleUnit"]) ||
      ([_cn isEqualToString:@"LSWDeletedArticleUnit"]))
    {
      self->fetchUnits = YES;
    }
  if (([_cn isEqualToString:@"LSWNewInvoiceAccount"]) ||
      ([_cn isEqualToString:@"LSWUpdatedInvoiceAccount"]) ||
      ([_cn isEqualToString:@"LSWDeletedInvoiceAccount"]))
    {
      self->fetchAccounts = YES;
    }
}

//actions

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

- (id)search {
  [self _fetchListInvoices];
  self->fetchListInvoices = NO;
  [self setInvoices:[self _filterInvoices:self->listInvoices]];
  [self _resetSelected];

  return nil;
}

- (id)searchInvoice {
  NSArray *result = nil;

  self->searchingInvoices = YES;

  result = [self runCommand:
                 @"invoice::extended-search",
                 @"operator",       @"OR",
                 @"invoiceNr",      self->invoiceSearchString,
                 @"comment",        self->invoiceSearchString,
                 @"maxSearchCount", [NSNumber numberWithInt:1000],
                 nil];
  ASSIGN(self->invoices, result);

  [self runCommand:@"invoice::set-debitor",
        @"relationKey", @"debitor",
        @"objects", self->invoices,
        nil];

  return nil;
}

- (id)searchArticles {
  NSArray *result = nil;

  result = [self runCommand:
                 @"article::extended-search",
                 @"operator",       @"OR",
                 @"articleNr",      self->articleSearchString,
                 @"articleName",    self->articleSearchString,
                 @"maxSearchCount", [NSNumber numberWithInt:1000],
                 nil];

  ASSIGN(self->articles, result);

  [self _setSortableArticleNr];
  
  [self runCommand:@"article::set-unit",
        @"relationKey", @"articleUnit",
        @"objects", self->articles,
        nil];
  [self runCommand:@"article::set-category",
        @"relationKey", @"articleCategory",
        @"objects", self->articles,
        nil];

  self->startIndex = 0;

  return nil;
}

- (id)clearSearch {
  RELEASE(self->invoiceSearchString);
  self->invoiceSearchString = nil;

  self->searchingInvoices = NO;

  self->fetchListInvoices = YES;

  return [self search];
}

- (id)tabClicked {
  self->startIndex   = 0;
  self->isDescending = NO;
  
  [self setSelectedAttribute:nil];

  if ([self->tabKey isEqualToString:@"invoices"]) {
    if (self->fetchListInvoices) {
      [self _fetchListInvoices];
      
      self->fetchListInvoices = NO;
      [self setInvoices:[self _filterInvoices:self->listInvoices]];
    }
  }
  if (([self->tabKey isEqualToString:@"monitions"]) &&
      (self->fetchBadDebitors)) {
    [self _fetchBadDebitors];
    self->fetchBadDebitors = NO;
  }

  if (([self->tabKey isEqualToString:@"accounts"]) &&
      (self->fetchAccounts)) {
    [self _fetchAccounts];
    self->fetchAccounts = NO;
  }
  return nil;
}

- (id)buttonAction {
  NSString *action = [self->button valueForKey:@"action"];
  SEL sel =
    NSSelectorFromString(action);
  return ([self respondsToSelector: sel])
    ? [self performSelector:sel] : nil;
}

- (id)newInvoice {
  NGMimeType  *mt = [NGMimeType mimeType:@"eo/invoice"];
  WOComponent *ct = nil;

  ct = [[self session] instantiateComponentForCommand:@"new" type:mt];
  if (ct) [self enterPage:(id)ct];
  return nil;
}

//- (id)viewInvoice {
//  [[self session] transferObject:self->item owner:self];
//  [self executePasteboardCommand:@"view"];
//  return nil;
//}

- (id)copyInvoices {
  WOComponent* ct = [self pageWithName:@"SkyInvoiceCopyPanel"];

  if (ct) {
    [ct takeValue:[self selectedEOs] forKey:@"invoices"];
    [self _resetSelected];
    [ct takeValue:COPY_ACTION forKey:@"action"];
    [self enterPage:(id)ct];
  }
  return nil;
}

- (id)moveInvoices {
  WOComponent* ct = [self pageWithName:@"SkyInvoiceCopyPanel"];
  if (ct) {
    [ct takeValue:[self selectedEOs] forKey:@"invoices"];
    [self _resetSelected];
    [ct takeValue:MOVE_ACTION forKey:@"action"];
    [self enterPage:(id)ct];
  }
  return nil;
}

- (id)certifyPrintouts {
  NSEnumerator    *invEnum;
  id              invs;
  id              inv;
  NSArray         *invArticles;
  id              deb;
  SkyInvoicePrintoutFormatter *format;
  NSUserDefaults  *ud;
  NSDictionary    *formatSettings;
  NSDictionary    *settings;

  invs           = [self selectedEOs];
  [self runCommand:@"invoice::fetch-additional", @"invoices", invs, nil];
  invEnum        = [invs objectEnumerator];
  ud             = [[self session] userDefaults];
  formatSettings =
    [ud dictionaryForKey:@"invoice_format_settings"];
  settings       =
    [formatSettings objectForKey:@"standard-printout"];

  while ((inv = [invEnum nextObject])) {
    NSDictionary *invoiceKind;
    NSString     *curKind      = [inv valueForKey:@"kind"];
    NSDictionary *knds         = [ud dictionaryForKey:@"invoice_kinds"];
    NSString     *printoutAttr = nil;

    format =
      [SkyInvoicePrintoutFormatter
        skyInvoicePrintoutFormatterWithDefaultSettings:settings];

    invoiceKind = [knds objectForKey:curKind];
    printoutAttr = [invoiceKind objectForKey:@"printout"];

    if (printoutAttr != nil) {
      [format setFormatSettings:[formatSettings objectForKey:printoutAttr]];
    }
    
    deb = [inv valueForKey:@"debitor"];
    invArticles = [self runCommand:@"invoice::get-articles",
                     @"object", inv,
                     @"returnType", intObj(LSDBReturnType_ManyObjects),
                     nil];
    [format setCurrency:[self currency]];
    [format setInvoice: inv];
    [format setDebitor: deb];
    [format setArticles: invArticles];

    [self runCommand:@"invoice::print",
          @"object",   inv,
          @"printout", [format createOutput],
          nil];
    
    [self postChange:@"LSWUpdatedInvoice" onObject: inv];
  }
  [self _resetSelected];

  return nil;
}

- (id)settleInvoices {
  NSEnumerator *invEnum;
  id inv;

  invEnum = [[self selectedEOs] objectEnumerator];
  
  while ((inv = [invEnum nextObject])) {
    [self runCommand:@"invoice::finish", @"object", inv, nil];
    [self postChange:@"LSWUpdatedInvoice" onObject:inv];
  }
  [self _resetSelected];
  
  return nil;
}

- (id)newArticle {
  NGMimeType  *mt = [NGMimeType mimeType:@"eo/article"];
  WOComponent *ct = nil;

  ct = [[self session] instantiateComponentForCommand:@"new" type:mt];
  if (ct) [self enterPage:(id)ct];
  return nil;
}

- (id)viewArticle {
  [[self session] transferObject:self->item owner:self];
  [self executePasteboardCommand:@"view"];
  return nil;
}

- (id)newArticleCategory {
  NGMimeType  *mt = [NGMimeType mimeType:@"eo/articlecategory"];
  WOComponent *ct = nil;

  ct = [[self session] instantiateComponentForCommand:@"new" type:mt];
  if (ct) [self enterPage:(id)ct];
  return nil;
}

- (id)viewArticleCategory {
  [[self session] transferObject:self->item owner:self];
  [self executePasteboardCommand:@"view"];
  return nil;
}

- (id)newUnit {
  NGMimeType  *mt = [NGMimeType mimeType:@"eo/articleunit"];
  WOComponent *ct = nil;

  ct = [[self session] instantiateComponentForCommand:@"new" type:mt];
  if (ct) [self enterPage:(id)ct];
  return nil;
}

- (id)viewUnit {
  [[self session] transferObject:self->item owner:self];
  [self executePasteboardCommand:@"view"];
  return nil;
}

- (id)viewMonitions {
  LSWViewerPage *viewer =
    [self pageWithName:@"SkyUnsettledInvoicesViewer"];
  if (viewer) {
    [viewer setObject:self->item];
    [self enterPage:viewer];
  }
  return nil;
}

- (id)computeOverview {
  NSArray           *overviewInvoices;
  NSEnumerator      *invEnum;
  NSString          *header;
  NSString          *formatR;
  NSString          *formatS;
  NSMutableString   *output;
  NSNumberFormatter *numberFormat;
  id                sort;
  id                inv;

  output       = [[NSMutableString alloc] init];
  numberFormat = [[NSNumberFormatter alloc] init];

  sort              = [(LSWSession *)[self session] eoSorter];
  overviewInvoices  = [self _fetchOverviewInvoices];
  overviewInvoices  = [sort sortArray:overviewInvoices
                            inContext:@"invoiceNr"
                            ordering:LSAscendingOrder];
  invEnum           = [overviewInvoices objectEnumerator];
  
  header = @"   brutto     netto RE-Nr  F RDatum  faellig Debitr "
           @"Buchungstext\n----------------------------------------"
           @"----------------------------------------\n";

  formatR = @"%9@ %9@ R%5@ %1@ %8@    10d %6@ %@";
  formatS = @"%9@ %9@ S%5@ %1@ %8@    10d %6@ %@";

  [output setString:header];
  [numberFormat setFormat:@"0.00"];

  while ((inv = [invEnum nextObject])) {
    NSEnumerator *articleEnum;
    NSArray      *arts;
    NSString     *format;
    NSString     *invDate;
    NSString     *invDeb;
    NSString     *invNr;
    BOOL         isStornoInv = NO;
    id           article;

    arts = [self runCommand:@"invoice::get-articles", @"object", inv, nil];

    invDate     = [[inv valueForKey:@"invoiceDate"]
                        descriptionWithCalendarFormat:@"%Y%m%d"];
    invDeb      = [[inv valueForKey:@"debitor"] valueForKey:@"number"];
    invNr       = [inv valueForKey:@"invoiceNr"];

    articleEnum = [arts objectEnumerator];
    
    format = formatR;

    if ([invNr hasPrefix:@"S"]) {
      format      = formatS;
      isStornoInv = YES;
    }

    if ([invNr length] > 9)
      invNr = [invNr substringFromIndex:5];
    else
      invNr = [invNr substringFromIndex:4];
    
    while ((article = [articleEnum nextObject])) {
      double    n;
      double    b;
      NSNumber *netto;
      NSNumber *brutto;

      n = ([[article valueForKey:@"netAmount"] doubleValue] *
           [[article valueForKey:@"articleCount"] doubleValue]);
      b = n * (1 + [[article valueForKey:@"vat"] doubleValue]);

      if (isStornoInv) {
        n = 0.00 - n;
        b = 0.00 - b;
      }

      netto  = [NSNumber numberWithDouble:n];
      brutto = [NSNumber numberWithDouble:b];

      {
        NSString *s;

        s = [NSString stringWithFormat:format,
                          [numberFormat stringForObjectValue:brutto],
                          [numberFormat stringForObjectValue:netto],
                          invNr,
                          [[article valueForKey:@"articleCategory"]
                                    valueForKey:@"categoryAbbrev"],
                          invDate,
                          invDeb,
                          [article valueForKey:@"comment"]];
        if ([s length] > 80) {
          [output appendString:[s substringToIndex:80]];
        }
        else
          [output appendString:s];
        [output appendString:@"\n"];
      }
    }
  }
  [self setOverviewOutput:output];

  RELEASE(output);       output       = nil;
  RELEASE(numberFormat); numberFormat = nil;

  return nil;
}

- (id)viewAccount {
  [[self session] transferObject:self->item owner:self];
  [self executePasteboardCommand:@"view"];
  return nil;
}

//fetching functions

- (void)_fetchListInvoices { //invoices for invoices-tab
  NSCalendarDate *from;
  NSCalendarDate *to;

  from = [NSCalendarDate
                        dateWithYear:[self->selectedYear intValue]
                        month:[self->selectedMonth intValue]
                        day:1
                        hour:0
                        minute:0
                        second:0
                        timeZone: [NSTimeZone localTimeZone]];
  to = [NSCalendarDate
                      dateWithYear:[self->selectedYear intValue]
                      month:[self->selectedMonth intValue]
                      day:31
                      hour:23
                      minute:59
                      second:59
                      timeZone:[NSTimeZone localTimeZone]];
  
  [self setListInvoices:
        [self runCommand:@"invoice::get",
              @"returnType", intObj(LSDBReturnType_ManyObjects),
              @"from",       from,
              @"to",         to,
              nil]];
  
  [self runCommand:@"invoice::set-debitor",
        @"relationKey", @"debitor",
        @"objects",     self->listInvoices,
        nil];
}

- (void)_fetchArticleCategories {
  [self takeValue:
        [self runCommand:@"articlecategory::get",
              @"returnType", intObj(LSDBReturnType_ManyObjects),
              nil]
        forKey:@"articleCategories"];
}

- (void)_fetchUnits {
  [self takeValue:
        [self runCommand:@"articleunit::get",
              @"returnType", intObj(LSDBReturnType_ManyObjects),
              nil]
        forKey:@"units"];
}

- (void)_fetchAccounts {
  [self takeValue:
        [self runCommand:@"invoiceaccount::get",
              @"returnType", intObj(LSDBReturnType_ManyObjects),
              nil]
        forKey:@"accounts"];
  [self runCommand:@"invoiceaccount::fetch-debitor",
        @"relationKey", @"debitor",
        @"objects", self->accounts,
        nil];
}

- (void)_fetchBadDebitors {
  id allFiltered =
    [self runCommand:@"enterprise::get-with-invoice-status",
          @"states",
          [NSArray arrayWithObjects:
                   @"05_printed",
                   @"15_monition",
                   @"16_monition2",
                   @"17_monition3", nil],
          @"returnType", intObj(LSDBReturnType_ManyObjects),
          nil];
  [self runCommand:@"enterprise::fetch-unsettled-invoices",
        @"objects",    allFiltered,
        @"returnType", intObj(LSDBReturnType_ManyObjects),
        nil];

  [self takeValue:allFiltered forKey:@"badDebitors"];
}

- (NSArray *)_fetchOverviewInvoices {
  NSCalendarDate *from;
  NSCalendarDate *to;
  NSArray        *overviewInvoices;

  from = [NSCalendarDate dateWithString:self->overviewFrom
                         calendarFormat:@"%Y-%m-%d"];
  to   = [NSCalendarDate dateWithString: self->overviewTo
                         calendarFormat:@"%Y-%m-%d"];

  overviewInvoices = [self runCommand:@"invoice::get",
                           @"returnType", intObj(LSDBReturnType_ManyObjects),
                           @"from", from,
                           @"to",   to,
                           nil];
  
  [self runCommand:@"invoice::set-debitor",
        @"relationKey", @"debitor",
        @"objects",      overviewInvoices,
        nil];

  return overviewInvoices;
}

//internal computing functions
- (BOOL)_addString:(NSString *)_string toList:(NSMutableArray *)_list {
  NSEnumerator   *listEnum = [_list objectEnumerator];
  NSString       *itm;

  while ((itm = [listEnum nextObject])) {
    if ([itm isEqualToString: _string]) {
      return NO;
    }
  }
  [_list addObject: _string];
  return YES;
}

- (void)_computeMonth {
  int   month         = [[NSCalendarDate date] monthOfYear];
  self->selectedMonth = [NSNumber numberWithInt:month];
}

- (void)_computeKinds {
  NSMutableArray *knds    = [NSMutableArray array];
  NSEnumerator   *invEnum =
    [[[[[self session] userDefaults]
              dictionaryForKey:@"invoice_kinds"]
              allKeys] objectEnumerator];
  id knd;

  [self _addString: @"allKindsSelected" toList: knds];

  while ((knd = [invEnum nextObject])) {
    [self _addString: knd
          toList: knds];
  }
  [self takeValue:knds forKey:@"invoiceKinds"];
  if ([knds count] > 0)
    [self takeValue:[knds objectAtIndex:0] forKey:@"selectedKind"];
}

- (NSArray *)_filterInvoices:(NSArray *)_allInvoices {
  NSEnumerator    *invEnum          = nil;
  int             year;
  int             filterYear;
  int             month;
  int             filterMonth;
  NSMutableArray  *filteredInvoices = nil;
  NSCalendarDate  *date             = nil;
  NSString        *invoiceKind      = nil;
  NSString        *filterKind       = nil;
  id              inv;
  BOOL            kindIsSelected    = NO;

  [self _resetSelected];

  invEnum          = [_allInvoices objectEnumerator];
  filterYear       = [self->selectedYear intValue];
  filterMonth      = [self->selectedMonth intValue];
  filteredInvoices = [NSMutableArray array];
  filterKind       = self->selectedKind;

  while ((inv = [invEnum nextObject])) {
    invoiceKind = [inv valueForKey:@"kind"];
    date        = [inv valueForKey:@"invoiceDate"];
    year        = [date yearOfCommonEra];
    month       = [date monthOfYear];
    
    kindIsSelected =
      (([invoiceKind isEqualToString: filterKind]) ||
       ([filterKind isEqualToString:@"allKindsSelected"]))
      ? YES : NO;
    
    if ((year == filterYear) &&
        (month == filterMonth) &&
        (kindIsSelected)) {
      [filteredInvoices addObject:inv];
    }
  }
  return filteredInvoices;
}

- (void)_setSortableArticleNr {
  int i, cnt;

  for (i = 0, cnt = [self->articles count]; i < cnt; i++) {
    id       obj    = nil;
    NSString *artNr = nil;
    NSString *sArtNr = nil;

    obj   = [self->articles objectAtIndex:i];
    artNr = [obj valueForKey:@"articleNr"];

    if (artNr != nil) {
      sArtNr = [NSString stringWithFormat:@"%.4d", [artNr intValue]];
      [obj takeValue:sArtNr forKey:@"sArticleNr"];
    }
  }
}

//special accessors

- (NSFormatter *)numberFormatter {
  NSNumberFormatter* format = [[NSNumberFormatter alloc] init];
  [format setFormat:@".__0,00"];
  [format setThousandSeparator:@"."];
  [format setDecimalSeparator:@","];
  return AUTORELEASE(format);
}

- (NSString *)labelForItem {
  NSString *label = [[self labels] valueForKey: self->item];
  return (label == nil) ? item : label;
}

- (NSString *)monthLabelKey {
  return [[self->months objectAtIndex:[self->item intValue]-1]
                        valueForKey:@"labelKey"];
}
- (NSString *)monthLabel {
  NSString *label = [[self labels] valueForKey:[self monthLabelKey]];
  if (label == nil)
    label = [self->item valueForKey:@"labelKey"];
  
  return (label != nil)
    ? label
    : self->item;
}

- (BOOL)isListViewDisabled {
  return (self->searchingInvoices)
    ? YES
    : NO;
}

// accessors

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

- (void)setListInvoices:(NSArray *)_invoices {
  ASSIGN(self->listInvoices, _invoices);
}
- (NSArray *)listInvoices {
  return self->listInvoices;
}

- (void)setInvoices:(NSArray *)_invoices {
  ASSIGN(self->invoices, _invoices);
}
- (NSArray *)invoices {
  return self->invoices;
}

- (void)setBadDebitors:(NSArray *)_debitors {
  ASSIGN(self->badDebitors, _debitors);
}
- (NSArray *)badDebitors {
  return self->badDebitors;
}

- (void)setSelected:(NSArray *)_selected {
  ASSIGN(self->selected, _selected);
}
- (NSArray *)selected {
  return self->selected;
}

- (void)setArticles:(NSArray *)_articles {
  ASSIGN(self->articles, _articles);
}
- (NSArray *)articles {
  return self->articles;
}

- (void)setArticleSearchString:(NSString *)_string {
  ASSIGN(self->articleSearchString, _string);
}
- (NSString *)articleSearchString {
  return self->articleSearchString;
}

- (void)setInvoiceSearchString:(NSString *)_string {
  ASSIGN(self->invoiceSearchString,_string);
}
- (NSString *)invoiceSearchString {
  return self->invoiceSearchString;
}

- (void)setArticleCategories:(NSArray *)_categories {
  ASSIGN(self->articleCategories, _categories);
}
- (NSArray *)articleCategories {
  return self->articleCategories;
}

- (void)setUnits:(NSArray *)_units {
  ASSIGN(self->units, _units);
}
- (NSArray *)units {
  return self->units;
}

- (void)setAccounts:(NSArray *)_accounts {
  ASSIGN(self->accounts, _accounts);
}
- (NSArray *)accounts {
  return self->accounts;
}

- (void)setSelectedYear:(NSString *)_year {
  ASSIGN(self->selectedYear, _year);
}
- (NSString *)selectedYear {
  return self->selectedYear;
}

- (void)setMonths:(NSArray *)_months {
  ASSIGN(self->months, _months);
}
- (NSArray *)months {
  return self->months;
}

- (void)setSelectedMonth:(id)_month {
  if ([_month intValue] > 0)
    ASSIGN(self->selectedMonth, _month);
}
- (id)selectedMonth {
  return self->selectedMonth;
}

- (void)setInvoiceKinds: (NSArray *)_kinds {
  ASSIGN(self->invoiceKinds, _kinds);
}
- (NSArray *)invoiceKinds {
  return self->invoiceKinds;
}

- (void)setSelectedKind: (NSString *)_kind {
  ASSIGN(self->selectedKind, _kind);
}
- (NSString*)selectedKind {
  return self->selectedKind;
}

- (void)setStart:(unsigned)_startIndex {
  self->startIndex = _startIndex;
}
- (unsigned)start {
  return self->startIndex;
}

- (void)setIsDescending:(BOOL)_isDescending {
  self->isDescending = _isDescending;
}
- (BOOL)isDescending {
  return self->isDescending;
}

- (void)setItem:(id)_item {
  ASSIGN(self->item, _item);
}
- (id)item {
  return self->item;
}

- (void)setButton:(id)_button {
  ASSIGN(self->button,_button);
}
- (id)button {
  return self->button;
}

- (void)setSelectedAttribute:(NSDictionary *)_selectedAttribute {
  ASSIGN(self->selectedAttribute, _selectedAttribute);
}
- (NSDictionary *)selectedAttribute {
  return self->selectedAttribute;
}

- (void)setTabKey:(NSString *)_tabKey {
  ASSIGN(self->tabKey, _tabKey);
}
- (NSString *)tabKey {
  return self->tabKey;
}

- (void)setOverviewFrom:(NSString *)_from {
  ASSIGN(self->overviewFrom, _from);
}
- (NSString *)overviewFrom {
  return self->overviewFrom;
}

- (void)setOverviewTo:(NSString *)_to {
  ASSIGN(self->overviewTo, _to);
}
- (NSString*)overviewTo {
  return self->overviewTo;
}

- (void)setOverviewOutput:(NSString *)_output {
  ASSIGN(self->overviewOutput, _output);
}
- (NSString *)overviewOutput {
  return self->overviewOutput;
}

// key/value coding

- (void)takeValue:(id)_val forKey:(id)_key {
  if ([_key isEqualToString:@"listInvoices"]) {
    [self setListInvoices:_val];
    return;
  }
  if ([_key isEqualToString:@"invoices"]) {
    [self setInvoices:_val];
    return;
  }
  if ([_key isEqualToString:@"badDebitors"]) {
    [self setBadDebitors:_val];
    return;
  }
  if ([_key isEqualToString:@"selected"]) {
    [self setSelected:_val];
    return;
  }
  if ([_key isEqualToString:@"articles"]) {
    [self setArticles:_val];
    return;
  }
  if ([_key isEqualToString:@"articleCategories"]) {
    [self setArticleCategories:_val];
    return;
  }
  if ([_key isEqualToString:@"units"]) {
    [self setUnits:_val];
    return;
  }
  if ([_key isEqualToString:@"accounts"]) {
    [self setAccounts:_val];
    return;
  }
  if ([_key isEqualToString:@"selectedYear"]) {
    [self setSelectedYear:_val];
    return;
  }
  if ([_key isEqualToString:@"months"]) {
    [self setMonths:_val];
    return;
  }
  if ([_key isEqualToString:@"selectedMonth"]) {
    [self setSelectedMonth:_val];
    return;
  }
  if ([_key isEqualToString:@"invoiceKinds"]) {
    [self setInvoiceKinds:_val];
    return;
  }
  if ([_key isEqualToString:@"selectedKind"]) {
    [self setSelectedKind:_val];
    return;
  }
  if ([_key isEqualToString:@"selectedAttribute"]) {
    [self setSelectedAttribute:_val];
    return;
  }
  if ([_key isEqualToString:@"tabKey"]) {
    [self setTabKey:_val];
    return;
  }
  if ([_key isEqualToString:@"overviewFrom"]) {
    [self setOverviewFrom:_val];
    return;
  }
  if ([_key isEqualToString:@"overviewTo"]) {
    [self setOverviewTo:_val];
    return;
  }
  if ([_key isEqualToString:@"overviewOutput"]) {
    [self setOverviewOutput:_val];
    return;
  }

  [super takeValue:_val forKey:_key];
}

@end /* SkyInvoices */

@implementation SkyInvoices(PrivateMethods)

- (void)_resetSelected {
  if (self->selected != nil)
    RELEASE(self->selected);
  
  self->selected = [NSMutableArray array];
  RETAIN(self->selected);
}

@end /* SkyInvoices(PrivateMethods) */
