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

#include "common.h"
#include "SkyInvoiceEditor.h"
#include "SkyCurrencyFormatter.h"

@interface SkyInvoiceEditor(privateMethods)
- (void)setResultList:(id)_resultList;
- (void)setMappedArticles:(id)_mappedArticles;
- (void)setArticlesText:(NSString *)_text;
- (NSArray*)invoiceKinds;
- (void)_fetchDebitor;
- (void)_computeArticlesToAdd;
- (void)_computeInvoiceComment;
- (NSDictionary*)_assignArticlesToArticleNr:(NSArray*)_articles;
- (id)invoice;
- (id)reference;
- (void)setErrors:(NSString*)_errors;
- (void)setInvoiceDate:(NSString*)_date;
@end

@implementation SkyInvoiceEditor

- (id)init {
  if ((self = [super init])) {
    self->debitor    = nil;
    self->resultList = nil;
    self->articles   = nil;
    self->fetchDebitor = YES;
    self->hasAddErrors  = NO;
    self->reference = nil;
    self->currencyFormatter = nil;
    [self setArticlesText:@""];
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->item);
  RELEASE(self->attribute);
  RELEASE(self->searchString);
  RELEASE(self->resultList);
  RELEASE(self->debitor);
  RELEASE(self->articles);
  RELEASE(self->articlesText);
  RELEASE(self->errors);
  RELEASE(self->invoiceDate);
  RELEASE(self->reference);
  RELEASE(self->mappedArticles);
  RELEASE(self->currencyFormatter);
  [super dealloc];
}
#endif

- (BOOL)prepareForEditCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  NSMutableArray* assignments =
    [self runCommand:@"invoice::get-articles",
          @"object", [self object],
          @"returnType", intObj(LSDBReturnType_ManyObjects),
          nil];
  
  NSFormatter* format = [[self session] formatDate];

  [self setArticles: [NSMutableArray arrayWithArray:assignments]];
  [self _putArticlesToTextField];
  [self setInvoiceDate:
        [format stringForObjectValue:
                [[self invoice] valueForKey:@"invoiceDate"]]];

  return YES;
}

- (BOOL)prepareForActivationCommand:(NSString *)_command
  type: (NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  NSArray* origArt;

  //fetch knownArticles
  origArt = [self runCommand:@"article::get",
                  @"returnType", intObj(LSDBReturnType_ManyObjects),
                  nil];
  [self setMappedArticles: [self _assignArticlesToArticleNr: origArt]];
    
  return  [super prepareForActivationCommand:_command
                 type:_type
                 configuration:_cmdCfg];
}

- (BOOL)prepareForNewCommand:(NSString *)_command
   type:(NGMimeType *)_type
   configuration:(NSDictionary *)_cmdCfg
{
  NSFormatter *format= [[self session] formatDate];
  [self setInvoiceDate:
        [format stringForObjectValue: [NSCalendarDate date]]];

  return YES;
}

- (void)sleep {
  [super sleep];
  RELEASE(self->currencyFormatter); self->currencyFormatter = nil;
}

- (void)syncAwake {
  [super syncAwake];

  if ((![self isInNewMode]) && (self->fetchDebitor)) {
    self->fetchDebitor = NO;
    [self _fetchDebitor];
  }

}

- (void)syncSleep {
  [self setErrorString:nil];
  [super syncSleep];
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

- (void)_fetchDebitor {
  [self runCommand:@"invoice::set-debitor",
        @"relationKey", @"debitor",
        @"object", [self object],
        nil];
  [self setDebitor:[[self object] valueForKey:@"debitor"]];
  [self setResultList:[NSArray arrayWithObject:self->debitor]];
}

- (NSDictionary*)_assignArticlesToArticleNr:(NSArray*)_articles {
  NSEnumerator *artEnum = [_articles objectEnumerator];
  id              art;
  NSMutableDictionary *map =
    [NSMutableDictionary dictionary];

  while ((art = [artEnum nextObject])) {
    [map takeValue:art forKey:[art valueForKey:@"articleNr"]];
  }
  return [NSDictionary dictionaryWithDictionary:map];
}

- (NSString*)_removeSpacesAtStartAndEnd:(NSString*)_string{
  NSArray* elements;
  NSMutableString* newStr = nil;
  NSEnumerator* elemEnum;
  id str;

  if ([_string hasSuffix:@"\r"]) {
    _string = [NSString stringWithCString:[_string cString]
                        length: [_string length] - 1];
  }

  elements = [_string componentsSeparatedByString:@" "];
  elemEnum = [elements objectEnumerator];
  
  while ((str = [elemEnum nextObject])) {
    if (![str isEqualToString:@""]) {
      if (newStr == nil) {
        newStr = [NSMutableString stringWithString:str];
      } else {
        [newStr appendFormat:@" %@", str];
      }
    }
  }
  return [NSString stringWithString:newStr];
}

- (NSArray*)_separateString:(NSString*)_orig byString:(NSString*)_sep {
  NSMutableArray *sepStr = [_orig componentsSeparatedByString:_sep];
  NSString* str;
  int i;

  for (i = 0; i < [sepStr count]; i++) {
    str = [sepStr objectAtIndex:i];
    if (([str hasSuffix:@"\\"]) && (![str hasSuffix:@"\\\\"])) {
      NSString *nextStr;
      if ((i+1) < [sepStr count])
        nextStr = [sepStr objectAtIndex: i+1];
      else nextStr = @"";
      [sepStr replaceObjectAtIndex:i
              withObject:[NSString stringWithFormat:@"%@%@%@",
                                   str, _sep, nextStr]];
      if ((i+1) < [sepStr count]) {
        [sepStr removeObjectAtIndex: i+1];
        i--;
      }
    }
  }
  return sepStr;
}

- (void)_computeArticlesToAdd {
  if (![self->articlesText isEqualToString:@""]) {
    NSMutableArray           *textArticles =
      [self->articlesText componentsSeparatedByString:@"\n"];
    NSDictionary             *knownArticles = self->mappedArticles;
    NSMutableArray           *addedArticles = [NSMutableArray array];
    NSString                 *artItem;
    int                      i;
    NSMutableString*         occErrors =
      [NSMutableString stringWithString:@""];

    for (i = 0; i < [textArticles count]; i++) {
      NSArray                   *article;
      NSDictionary              *knownArticle = nil;
      NSMutableDictionary       *newArticle   = nil;
      BOOL                      ok            = YES;
      NSString                  *artCount;
      double                    fcount        = 0.0;
      NSString                  *artNr;
      NSString                  *comment      = nil;
      NSString                  *artPrice     = nil;
      NSNumber                  *nsPrice      = nil;
      
      artItem = [textArticles objectAtIndex:i];
      article = [self _separateString: artItem byString:@":"];
      
      if (([artItem isEqualToString:@""]) ||
          ([artItem isEqualToString:@"\r"])) {
        [textArticles removeObjectAtIndex:i--];
        ok = NO;
      } else if ([article count] >= 2) {
        
        artNr =    [self _removeSpacesAtStartAndEnd:[article objectAtIndex:0]];
        artCount = [self _removeSpacesAtStartAndEnd:[article objectAtIndex:1]];
        
        if ([article count] >= 3) {
          comment =
            [self _removeSpacesAtStartAndEnd:[article objectAtIndex:2]];

          if ([article count] >= 4)
            artPrice =
              [self _removeSpacesAtStartAndEnd:[article objectAtIndex:3]];
        }
        
        knownArticle = [knownArticles valueForKey:artNr];
        if (knownArticle == nil) {
          ok = NO;
          [occErrors appendFormat:
                     @"Line %i:Unknown article       : %@\n",
                     i+1,artItem];
        } else {
          if (![[NSScanner scannerWithString:artCount] scanDouble:&fcount]) {
        // Achtung NSScanner is putt, fcount nicht weiter benutzen
            ok = NO;
            [occErrors appendFormat:
                       @"Line %i:Wrong syntax for count: %@\n",
                       i+1,artItem];
          }
          if (([article count] >= 4) &&
              (![[self currencyFormatter] getObjectValue:&nsPrice
                                          forString:artPrice
                                          errorDescription:NULL]))
            {
              ok = NO;
              [occErrors appendFormat:
                         @"Line %i:Wrong syntax for price: %@\n",
                         i+1,artItem];
            }
        }
      } else {
        ok = NO;
        [occErrors appendFormat:@"Line %i:Wrong syntax          : %@\n",
                   i+1,artItem];
      }
      if (ok) {
        newArticle = [NSMutableDictionary dictionary];
        if ((comment != nil) &&
            (![comment isEqualToString:@""]) &&
            (![comment isEqualToString:@" "])) {
          [newArticle takeValue:comment forKey:@"comment"];
        } else {
          [newArticle takeValue:@"" forKey:@"comment"];
        }
        [newArticle takeValue:
                    [NSNumber numberWithDouble:[artCount doubleValue]]
                    forKey:@"articleCount"];
        [newArticle takeValue: [knownArticle valueForKey:@"articleId"]
                    forKey:@"articleId"];
        // for database
        if (artPrice == nil) {
          nsPrice = [knownArticle valueForKey:@"price"];
        } else {
          NSFormatter *f = [self currencyFormatter];

          [f getObjectValue:&nsPrice forString:artPrice errorDescription:NULL];
        }
        {
          double vat = 0.0;

          vat = [[knownArticle valueForKey:@"vat"] doubleValue];
          
          [newArticle takeValue:nsPrice forKey:@"netAmount"];
          [newArticle takeValue:[knownArticle valueForKey:@"articleNr"]
                      forKey:@"articleNr"];
          [newArticle takeValue:[knownArticle valueForKey:@"articleName"]
                      forKey:@"articleName"];
          [newArticle takeValue:[NSNumber numberWithDouble:vat]
                      forKey:@"vat"];
        }
        [addedArticles addObject:newArticle];
        [textArticles removeObjectAtIndex:i--];
      }
    }
    [self setArticles:addedArticles];
    [self setArticlesText:[textArticles componentsJoinedByString:@"\n"]];
    if ([textArticles count] != 0) {
      self->hasAddErrors = YES;
      [occErrors appendString:
                 @"\nSyntax                       : <articleNr>:<articleCount>[:<additionalComment>[:<singlePrice>]]"];
      [self setErrors: occErrors];
    } else {
      self->hasAddErrors = NO;
      [self setErrors: nil];
    }
    
    [self _putArticlesToTextField];
  }
}

- (void)_computeInvoiceComment {
  NSString        *comment    = [[self invoice] valueForKey:@"comment"];
  NSUserDefaults  *ud         = [[self session] userDefaults];
  NSString        *kind       = [[self invoice] valueForKey:@"kind"];
  NSString        *newComment = @"";
  NSDictionary    *invKind;

  comment = (comment != nil)
    ? (([comment isEqualToString:@" "] == YES) ? (id)@"" : (id)comment)
    : (id)@"";
  if (kind != nil) {
    invKind = [[ud dictionaryForKey:@"invoice_kinds"] objectForKey:kind];
    newComment = [invKind objectForKey:@"comment"];
    if (([kind isEqualToString:@"invoice_cancel"]) &&
        (self->reference != nil))
      {
        newComment =
          [NSString stringWithFormat:newComment,
                    [self->reference valueForKey:@"invoiceNr"],
                    [[self->reference valueForKey:@"invoiceDate"]
                                      descriptionWithCalendarFormat:
                                      @"%Y-%m-%d"],
                    nil];
      }
  }
  [[self invoice] takeValue:[comment stringByAppendingString:newComment]
                  forKey:@"comment"];
}

- (void)_putArticlesToTextField {
  if ([self->articles count] != 0) {
    NSEnumerator* artEnum = [self->articles objectEnumerator];
    id article;
    NSString* output = self->articlesText;
    while ((article = [artEnum nextObject])) {
      NSString *artNr    = [article valueForKey:@"articleNr"];
      NSNumber *artCount = [article valueForKey:@"articleCount"];
      NSString *artCom   = [article valueForKey:@"comment"];
      NSNumber *artPrice = [article valueForKey:@"netAmount"];

      output = [NSString stringWithFormat:@"%@%10@:%10@:%0@:%@\n",
                         output, artNr, artCount, artCom,
                         [[self currencyFormatter]
                                stringForObjectValue:artPrice]];
    }
    [self setArticlesText: output];
  }
}

//accessors

- (NSArray *)invoiceKinds {
  return
    [[[[self session] userDefaults]
             dictionaryForKey:@"invoice_kinds"] allKeys];
}

- (id)item {
  return self->item;
}
- (void)setItem:(id)_item {
  ASSIGN(self->item,_item);
}

- (NSDictionary *)attribute {
  return self->attribute;
}
- (void)setAttribute:(NSDictionary *)_attribute {
  ASSIGN(self->attribute,_attribute);
}

- (NSString *)searchString {
  return self->searchString;
}
- (void)setSearchString:(NSString *)_searchString {
  ASSIGN(self->searchString,_searchString);
}

- (NSString*)articlesText {
  return self->articlesText;
}
- (void)setArticlesText:(NSString *)_text {
  ASSIGN(self->articlesText,_text);
}

- (NSMutableArray*)articles {
  return self->articles;
}
- (void)setArticles:(NSMutableArray *)_articles {
  ASSIGN(self->articles,_articles);
}

- (NSArray*)resultList {
  return self->resultList;
}
- (void)setResultList:(NSArray *)_resultList {
  ASSIGN(self->resultList,_resultList);
}

- (id)debitor {
  return self->debitor;
}
- (void)setDebitor:(id)_debitor {
  ASSIGN(self->debitor,_debitor);
}

- (void)setMappedArticles:(id)_mappedArticles {
  ASSIGN(self->mappedArticles, _mappedArticles);
}
- (NSDictionary*)mappedArticles {
  return self->mappedArticles;
}

- (id)invoice {
  return [self snapshot];
}

- (NSString *)kindName {
  NSString *label = [[self labels] valueForKey:self->item];
  return (label != nil) ? label : self->item;
}

- (NSString*)attributeLabel {
  return [[self labels] valueForKey:[attribute valueForKey:@"label"]];
}

- (void)setSelectedDebitor:(NSArray *)_debitor {
  [self setDebitor:[_debitor lastObject]];
}
- (NSMutableArray *)selectedDebitor {
  if (self->debitor != nil)
    return [NSMutableArray arrayWithObject:self->debitor];
  return [NSMutableArray array];
}

- (void)setHasAddErrors:(BOOL)_errors {
  self->hasAddErrors = _errors;
}
- (BOOL)hasAddErrors {
  return self->hasAddErrors;
}

- (NSNumberFormatter*)articleFormatterWithArticle:(id)_item {
  NSNumberFormatter* format = [[NSNumberFormatter alloc] init];
  NSString* formatString = [_item valueForKey:@"format"];
  if (formatString == nil) {
    [format setFormat:@"0"];
  } else {
    [format setFormat: formatString];
  }
  return AUTORELEASE(format);
}

- (NSNumberFormatter*)articleFormatter {
  return [self articleFormatterWithArticle:self->item];
}

- (void)setErrors:(NSString *)_errors {
  ASSIGN(self->errors, _errors);
}
- (NSString *)errors {
  return self->errors;
}

- (void)setInvoiceDate:(NSString*)_date {
  ASSIGN(self->invoiceDate,_date);
}
- (NSString*)invoiceDate {
  return self->invoiceDate;
}

- (void)setReference:(id)_ref {
  NSMutableArray *assignments;
  NSNumber       *toPay;
  NSNumber       *paid;
  ASSIGN(self->reference, _ref);
  [[self invoice] takeValue:@"invoice_cancel"
                  forKey:@"kind"];
  [[self invoice] takeValue:[_ref valueForKey:@"invoiceId"]
                  forKey:@"parentInvoiceId"];
  
  toPay = [_ref valueForKey:@"grossAmount"];
  paid  = [_ref valueForKey:@"paid"];
  paid = ((paid != nil) && ([paid isNotNull]))
    ? paid
    : [NSNumber numberWithDouble:0.0];
  toPay = [NSNumber numberWithDouble:[toPay doubleValue] - [paid doubleValue]];
  
  [[self invoice] takeValue:toPay forKey:@"paid"];
  [self _computeInvoiceComment];

  assignments =
    [self runCommand:@"invoice::get-articles",
          @"object", [self reference],
          @"returnType", intObj(LSDBReturnType_ManyObjects),
          nil];
  
  [self setArticles: [NSMutableArray arrayWithArray:assignments]];
  [self _putArticlesToTextField];
  [self setDebitor:[_ref valueForKey:@"debitor"]];
}
- (id)reference {
  return self->reference;
}

- (int)noOfCols {
  id  d = [[[self session] userDefaults] objectForKey:@"invoice_no_of_cols"];
  int n = [d intValue];
  
  return (n > 0) ? n : 2;
}

//conditional

- (BOOL)hasDebitor {
  return ((self->resultList != nil) && ([self->resultList count] > 0))
          ? YES : NO;
}

- (BOOL)hasErrors {
  return ((self->errors == nil) || ( [self->errors isEqualToString:@""]))
    ? YES : NO;
}

- (BOOL)isTypeEditable {
  id parent = [[self invoice] valueForKey:@"parentInvoiceId"];
  return ((parent == nil) || (![parent isNotNull]))
    ? YES : NO;
}

- (BOOL)areArticlesEditable {
  id parent = [[self invoice] valueForKey:@"parentInvoiceId"];
  return ((parent == nil) || (![parent isNotNull]))
    ? YES : NO;
}

// notifications

- (NSString *)insertNotificationName {
  return @"LSWNewInvoice";
}
- (NSString *)updateNotificationName {
  return @"LSWUpdatedInvoice";
}
- (NSString *)deleteNotificationName {
  return @"LSWDeletedInvoice";
}

//actions

- (id)_parseSnapshotValues {
  NSFormatter *format = [[self session] formatDate];
  NSCalendarDate *invDate;
  NSString *error = @"";
  id invoice = [self snapshot];
  [invoice takeValue:self->articles forKey:@"articles"];
  [invoice takeValue:[self->debitor valueForKey:@"companyId"]
           forKey:@"debitorId"];
  
  if (([self->invoiceDate isEqualToString:@""]) ||
      (![format getObjectValue:&invDate
                forString:self->invoiceDate
                errorDescription: &error])) {
    invDate = [NSCalendarDate date];
  }
  [invoice takeValue:invDate forKey:@"invoiceDate"];
  
  return invoice;
}

- (id)searchDebitor {
  [self setResultList:[self runCommand:
                            @"enterprise::extended-search",
                            @"operator",    @"OR",
                            @"description", self->searchString,
                            @"number",      self->searchString,
                            nil]];
        
  if ([self->resultList count] == 1)
    [self setDebitor:[self->resultList objectAtIndex:0]];
  
  return nil;
}

- (id)insertObject {
  id invoice = [self _parseSnapshotValues];

  return [self runCommand:@"invoice::new" arguments:invoice];
}

- (id)updateObject {
  id invoice = [self _parseSnapshotValues];
                    
  return [self runCommand:@"invoice::set" arguments:invoice];
}

- (id)check {
  [self _computeArticlesToAdd];
  return nil;
}

- (id)save {
  [self _computeArticlesToAdd];
  if (!self->hasAddErrors) {
    return [super save];
  } else {
    [self setErrorString:@"Unable to add all articles"];
  }
  return nil;
}

- (id)removeArticle {
  [self->articles removeObject:self->item];
  return nil;
}

- (id)updateKind {
  [self _computeInvoiceComment];
  return nil;
}


@end
