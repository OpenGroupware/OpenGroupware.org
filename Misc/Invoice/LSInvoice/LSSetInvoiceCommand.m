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

#import "common.h"
#import "LSSetInvoiceCommand.h"
#include <Foundation/NSNumberFormatter.h>

@implementation LSSetInvoiceCommand

- (id)initForOperation:(NSString *)_operation
              inDomain:(NSString *)_domain
{
  if ((self = [super initForOperation:_operation inDomain:_domain])) {
    self->saveArticles = YES;
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->articles);
  [super dealloc];
}
#endif

- (NSString *)_vatGroupForFactor:(NSNumber *)_vat
                      fromGroups:(NSDictionary *)_groups
{
  NSEnumerator      *groupEnum;
  NSDictionary      *group;
  NSString          *groupStr = nil;
  NSString          *factor;
  NSString          *vat;
  NSNumber          *fac      = nil;
  NSNumberFormatter *format   = nil;

  groupEnum = [[_groups allKeys] objectEnumerator];
  
  format = [[NSNumberFormatter alloc] init];
  AUTORELEASE(format);

  [format setFormat:@"0.0000"];
  vat = [format stringForObjectValue:_vat];

  while ((groupStr = [groupEnum nextObject])) {
    group = [_groups objectForKey:groupStr];
    fac= [NSNumber numberWithDouble: [[group objectForKey:@"factor"] doubleValue]];

    if (fac == nil) {
      continue;
    }
    factor = [format stringForObjectValue:fac];

    if ([vat isEqualToString: factor]) {
      return groupStr;
    }
  }
  return nil;
}

- (void)_computeNetAndGrossAmountsInContext:(id)_context {
  double         netA   = 0.0;
  double         grossA = 0.0;
  double         net    = 0.0;
  double         vat    = 0.0;
  double         cnt    = 0.0;
  id             article;
  NSEnumerator   *artEnum = [self->articles objectEnumerator];
  double         netAmount;
  id             account  = [_context valueForKey:LSAccountKey];
  NSUserDefaults *ud =
    LSRunCommandV(_context,
                  @"userdefaults", @"get",
                  @"user", account, nil);
  NSMutableDictionary *vatGroups =
    [[NSMutableDictionary alloc]
                          initWithDictionary:
                          [ud dictionaryForKey:
                              @"invoice_article_vat_groups"]
                          copyItems: YES];
  NSMutableDictionary *vatGroup;
  NSString            *groupStr = nil;
  NSNumber            *vatGroupNet;

  while ((article = [artEnum nextObject])) {
    vatGroupNet = nil;
    vat         = [[article valueForKey:@"vat"] doubleValue];
    groupStr    = [self _vatGroupForFactor:[NSNumber numberWithDouble:vat]
                        fromGroups: vatGroups];

    [self assert: (groupStr != nil) reason: @"Invalid vat value!"];
    vatGroup = [NSMutableDictionary dictionaryWithDictionary:
                                    [vatGroups objectForKey:groupStr]];
    vatGroupNet = [vatGroup objectForKey:@"netAmount"];
    vatGroupNet = (vatGroupNet != nil)
      ? vatGroupNet
      : [NSNumber numberWithDouble: 0.0];

    cnt = [[article valueForKey:@"articleCount"] doubleValue];
    net = [[article valueForKey:@"netAmount"] doubleValue]*cnt;
    net = rint(net * 100.0) * 0.01;
    netA += net;

    vatGroupNet =
      [NSNumber numberWithDouble:([vatGroupNet doubleValue]+net)];
    [vatGroup takeValue:vatGroupNet forKey:@"netAmount"];
    [vatGroups takeValue:vatGroup forKey:groupStr];
  }
  {
    NSEnumerator *groupEnum = [[vatGroups allKeys] objectEnumerator];

    while ((vatGroup = [vatGroups objectForKey:[groupEnum nextObject]])) {
      vatGroupNet = nil;
      vatGroupNet = [vatGroup objectForKey:@"netAmount"];

      if (vatGroupNet != nil) {
        netAmount = [vatGroupNet doubleValue];
        vat = [[vatGroup objectForKey:@"factor"] doubleValue];
        vat = rint(netAmount*vat*100.0) * 0.01;
        netAmount += vat;
        grossA += netAmount;
      }
    }
  }
  grossA = rint(grossA * 100.0) * 0.01;

  if ([[self valueForKey:@"kind"] isEqualToString:@"invoice_cancel"]) {
    if (([self valueForKey:@"paid"] == nil) ||
        (![[self valueForKey:@"paid"] isNotNull]))
      //[self takeValue:[NSNumber numberWithDouble:grossA] forKey:@"paid"];
      [self takeValue:MONEY2SAVEFORDOUBLE(grossA) forKey:@"paid"];
  } else {
    //[self takeValue:[NSNumber numberWithDouble:0.0] forKey:@"paid"];
    [self takeValue:MONEY2SAVEFORDOUBLE(0.0) forKey:@"paid"];
  }
  //[self takeValue: [NSNumber numberWithDouble:netA]  forKey:@"netAmount"];
  //[self takeValue: [NSNumber numberWithDouble:grossA] forKey:@"grossAmount"];
  [self takeValue:MONEY2SAVEFORDOUBLE(netA)   forKey:@"netAmount"];
  [self takeValue:MONEY2SAVEFORDOUBLE(grossA) forKey:@"grossAmount"];
  RELEASE(vatGroups); vatGroups = nil;
}

- (void)_checkForCancelInvoice {
  id       obj;
  NSString *iNr;
  NSString *iKind;

  obj   = [self object];
  iNr   = [obj valueForKey:@"invoiceNr"];
  iKind = [obj valueForKey:@"kind"];

  if ([iKind isEqualToString:@"invoice_cancel"] && ![iNr hasPrefix:@"S"]) {
    NSString *nr = @"S";

    nr = [nr stringByAppendingString:[iNr substringFromIndex:1]];
    
    [obj takeValue:nr forKey:@"invoiceNr"];
  }
  else if (![iKind isEqualToString:@"invoice_cancel"] && [iNr hasPrefix:@"S"]) {
    NSString *nr = @"R";

    nr = [nr stringByAppendingString:[iNr substringFromIndex:1]];
    
    [obj takeValue:nr forKey:@"invoiceNr"];
  }
}

- (void)_prepareForExecutionInContext:(id)_context {
  NSString     *status;
  NSEnumerator *teamEnum;
  id           account;
  id           team;
  BOOL         access = NO;

  status   = [[self object] valueForKey:@"status"];
  account  = [_context valueForKey:LSAccountKey];
  teamEnum =
    [LSRunCommandV(_context,
                   @"account",    @"teams",
                   @"account",    account,
                   @"returnType", intObj(LSDBReturnType_ManyObjects),
                   nil) objectEnumerator];

  while ((team = [teamEnum nextObject])) {
    if ([[team valueForKey:@"login"] isEqualToString:@"invoices"]) {
      access = YES;
    }
  }
  [self assert:access reason:@"You have no permission for doing that!"];

  [self assert:([status isEqualToString:@"00_created"])
        reason:@"Invoice isn't editable in this status!"];
  [self assert:([[self object] valueForKey:@"debitorId"] != nil)
        reason:@"No debitor set!"];

  if ((!self->saveArticles) && (self->articles == nil)) {
    [self setArticles:
          LSRunCommandV(
                        _context,
                        @"invoice",    @"get-articles",
                        @"object",     [self object],
                        @"returnType", intObj(LSDBReturnType_ManyObjects),
                        nil)];
  }

  [self _computeNetAndGrossAmountsInContext:_context];
  [super _prepareForExecutionInContext:_context];
  [self _checkForCancelInvoice];
}

- (void)_executeInContext:(id)_context {
  [self assert:([self object] != nil) reason:@"no invoice to act on!"];

  [super _executeInContext:_context];

  if (([self->articles count] > 0) && (self->saveArticles)) {
    LSRunCommandV(_context,
                  @"invoice",  @"set-articles",
                  @"articles", self->articles,
                  @"object",   [self object],
                   nil);
  }
  LSRunCommandV(_context,
                @"object",  @"add-log",
                @"logText", @"Invoice changed",
                @"action",  @"05_changed",
                @"objectToLog", [self object],
                nil);
}

- (NSString *)entityName {
  return @"Invoice";
}

// accessors

- (void)setArticles:(NSArray *)_articles {
  ASSIGN(self->articles, _articles);
}
- (NSArray *)articles {
  return self->articles;
}

- (void)setSaveArticles:(NSNumber *)_save {
  self->saveArticles = [_save boolValue];
}
- (NSNumber *)saveArticles {
  return [NSNumber numberWithBool:self->saveArticles];
}

// key/value coding

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"articles"]) {
    [self setArticles:_value];
    return;
  }
  else if ([_key isEqualToString:@"saveArticles"]) {
    [self setSaveArticles:_value];
    return;
  }
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"articles"])
    return [self articles];
  if ([_key isEqualToString:@"saveArticles"])
    return [self saveArticles];

  return [super valueForKey:_key];
}

@end
