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
#import "LSNewInvoiceCommand.h"
#include <math.h>
#include <Foundation/NSNumberFormatter.h>

NSString *LSInvoiceCreated     = @"00_created";
NSString *LSInvoicePrinted     = @"05_printed";
NSString *LSInvoiceCanceled    = @"10_canceled";
NSString *LSInvoiceMonition    = @"15_monition";
NSString *LSInvoice2ndMonition = @"16_monition2";
NSString *LSInvoice3rdMonition = @"17_monition3";
NSString *LSInvoiceDone        = @"20_done";

@implementation LSNewInvoiceCommand

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
  NSString          *groupStr  = nil;
  NSString          *factor;
  NSString          *vat;
  NSNumber          *fac       = nil;
  NSNumberFormatter *format;

  groupEnum = [[_groups allKeys] objectEnumerator];
  format    = [[NSNumberFormatter alloc] init];
  AUTORELEASE(format);

  [format setFormat:@"0.0000"];
  vat = [format stringForObjectValue:_vat];

  while ((groupStr = [groupEnum nextObject])) {
    group = [_groups objectForKey:groupStr];
    fac =
      [NSNumber numberWithDouble:
                [[group objectForKey:@"factor"] doubleValue]];
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
    vat = [[article valueForKey:@"vat"] doubleValue];
    groupStr = [self _vatGroupForFactor:[NSNumber numberWithDouble:vat]
                     fromGroups:vatGroups];
    [self assert: (groupStr != nil) reason: @"Invalid vat value!"];

    vatGroup =
      [NSMutableDictionary dictionaryWithDictionary:
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
        netAmount = rint(netAmount * 100.0) * 0.01;
        vat = [[vatGroup objectForKey:@"factor"] doubleValue];
        grossA += netAmount * (1+vat);
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
  //[self takeValue: [NSNumber numberWithDouble:netA]   forKey:@"netAmount"];
  //[self takeValue: [NSNumber numberWithDouble:grossA] forKey:@"grossAmount"];
  [self takeValue: MONEY2SAVEFORDOUBLE(netA)   forKey:@"netAmount"];
  [self takeValue: MONEY2SAVEFORDOUBLE(grossA) forKey:@"grossAmount"];
  RELEASE(vatGroups); vatGroups = nil;
}

- (void)_computeNewInvoiceNrInContext:(id)_context {
  NSString *prefix      = @"";
  NSString *nrFormat    = @"%@%@-%@";
  NSString *cntFormat   = @"000000";
  NSCalendarDate *today = [NSCalendarDate date];
  NSArray  *oldInvoices =
    LSRunCommandV(_context,
                  @"invoice",@"get",
                  @"returnType",intObj(LSDBReturnType_ManyObjects),
                  nil);
  NSEnumerator *invEnum = [oldInvoices objectEnumerator];
  NSNumberFormatter *format;
  id             inv;
  NSString       *newestNr;
  NSString       *invNr;
  NSString       *thisYear = [today descriptionWithCalendarFormat:@"%Y"];
  unsigned       nr;
  NSUserDefaults *ud =
    LSRunCommandV(_context,
                  @"userdefaults", @"get",
                  @"user", [_context valueForKey:LSAccountKey], nil);
  NSDictionary   *knds = [ud dictionaryForKey:@"invoice_kinds"];
  NSDictionary   *knd = [knds objectForKey:[self valueForKey:@"kind"]];
  prefix = [knd objectForKey:@"prefix"];

  format = [[NSNumberFormatter alloc] init];

  [format setFormat:cntFormat];
  newestNr = [format stringForObjectValue:[NSNumber numberWithInt:1]];
  nr = [cntFormat length];

  while ((inv = [invEnum nextObject])) {
    if ([[[inv valueForKey:@"invoiceDate"]
               descriptionWithCalendarFormat:@"%Y"]
               isEqualToString:thisYear]) {
      invNr = [[inv valueForKey:@"invoiceNr"] substringFromIndex:4];

      if ([invNr compare:newestNr] == 1) 
        newestNr = invNr;
    }
  }
  nr = ([newestNr intValue] + 1);
  newestNr = [format stringForObjectValue:[NSNumber numberWithInt:nr]];
  thisYear = [today descriptionWithCalendarFormat:@"%y"];
  [self takeValue:
        [NSString stringWithFormat: nrFormat, prefix, thisYear, newestNr]
        forKey:@"invoiceNr"];
  RELEASE(format); format = nil;
}

- (void)_prepareForExecutionInContext:(id)_context {
  id account = [_context valueForKey:LSAccountKey];
  NSEnumerator *teamEnum =
    [LSRunCommandV(_context, @"account", @"teams",
                  @"account", account,
                  @"returnType", intObj(LSDBReturnType_ManyObjects),
                  nil) objectEnumerator];
  id team;
  BOOL access = NO;

  while ((team = [teamEnum nextObject])) {
    if ([[team valueForKey:@"login"] isEqualToString:@"invoices"]) {
      access = YES;
      break;
    }
  }
  [self assert:access
        reason:@"You have no permission for doing that!"];
  [self takeValue:LSInvoiceCreated forKey:@"status"];

  [self assert:([self valueForKey:@"debitorId"] != nil)
        reason:@"No debitor set!"];

  [self _computeNewInvoiceNrInContext:_context];
  [self _computeNetAndGrossAmountsInContext:_context];
  [super _prepareForExecutionInContext:_context];
}

- (void)_executeInContext:(id)_context {
  [super _executeInContext:_context];

  if ([self->articles count] > 0) {
    LSRunCommandV(_context,
                  @"invoice", @"set-articles",
                  @"articles", self->articles,
                  @"object", [self object],
                   nil);
  }
  LSRunCommandV(_context,
                @"object", @"add-log",
                @"logText", @"Invoice created",
                @"action", @"00_created",
                @"objectToLog", [self object],
                nil);
}

- (NSString*)entityName {
  return @"Invoice";
}

// accessors

- (void)setArticles:(NSArray *)_articles {
  ASSIGN(self->articles, _articles);
}
- (NSArray *)articles {
  return self->articles;
}

// key/value coding

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"articles"]) {
    [self setArticles:_value];
    return;
  }
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"articles"])
    return [self articles];
  return [super valueForKey:_key];
}

@end
