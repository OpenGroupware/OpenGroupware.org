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

#ifndef __LSLogic_LSInvoice_LSFetchAdditionalInvoiceValuesCommand_H__
#define __LSLogic_LSInvoice_LSFetchAdditionalInvoiceValuesCommand_H__

#include <LSFoundation/LSBaseCommand.h>

/*
  Parameter:
    invoices/objects - array of invoices ('invoice' objetcs)

  - Fetches Information about VAT-Groups into the objects
  - if kind==invoice_cancel fetch information about reference invoice
  - specialy for the printout

*/

@interface LSFetchAdditionalInvoiceValuesCommand: LSBaseCommand
{
  NSArray *invoices;
}
@end

#endif /* __LSLogic_LSInvoice_LSFetchAdditionalInvoiceValuesCommand_H__ */

#include <math.h>
#include <Foundation/NSNumberFormatter.h>
#include <EOControl/EOControl.h>
#import "common.h"

@implementation LSFetchAdditionalInvoiceValuesCommand

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->invoices);
  [super dealloc];
}
#endif

- (NSDictionary *)_vatGroupForFactor:(NSNumber *)_vat
                          fromGroups:(NSArray *)_groups
{
  NSEnumerator *groupEnum;
  NSString     *curVat = nil;
  NSString     *vat    = nil;
  id           group;
  NSNumberFormatter *format;
  
  groupEnum = [_groups objectEnumerator];
  format    = [[NSNumberFormatter alloc] init];
  AUTORELEASE(format);

  [format setFormat:@"0.0000"];
  curVat = [format stringForObjectValue:_vat];
  
  while ((group = [groupEnum nextObject])) {
    vat = [format stringForObjectValue:[group objectForKey:@"factor"]];
    if ([vat isEqualToString:curVat]) {
      return group;
    }
  }
  return nil;
}

- (void)_prepareForExecutionInContext:(id)_context {
  id           account;
  NSEnumerator *teamEnum;
  id           team;
  BOOL         access = NO;
  
  account = [_context valueForKey:LSAccountKey];
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
  [self assert:access
        reason:@"You have no permission for doing that!"];
}

- (void)_fetchAdditionalValuesForCancelInvoice:(id)_inv inContext:(id)_ctx 
{
  id parent;
  parent = [_inv valueForKey:@"parentInvoiceId"];
  if ((parent == nil) || (![parent isNotNull]))
    return;
  
  parent = [EOKeyGlobalID globalIDWithEntityName:@"Invoice"
                       keys:&parent keyCount:1
                       zone:nil];
  parent = LSRunCommandV(_ctx, @"invoice", @"get-by-globalid",
                         @"gids", [NSArray arrayWithObject:parent],
                         nil);
  parent = [parent lastObject];
  [_inv takeValue:[parent valueForKey:@"paid"] forKey:@"alreadyPaid"];
  [_inv takeValue:[parent valueForKey:@"invoiceNr"] forKey:@"parentInvoiceNr"];
}

- (void)_executeInContext:(id)_context {
  id invoice;
  NSEnumerator *invEnum;
  
  invEnum = [self->invoices objectEnumerator];
  while ((invoice = [invEnum nextObject])) {
    NSArray      *articles =
      [invoice valueForKey:@"toInvoiceArticleAssignment"];
    NSEnumerator *articleEnum = [articles objectEnumerator];
    id           article;
    NSNumber     *vat;
    NSMutableArray      *vatGroups = [NSMutableArray array];
    NSDictionary        *origGroup;
    NSMutableDictionary *vatGroup;
    double              netAmount;

    while ((article = [articleEnum nextObject])) {
      vat = [article valueForKey:@"vat"];
      vat = ((vat != nil) && ([vat isNotNull]))
        ? vat
        : [[article valueForKey:@"toArticle"] valueForKey:@"vat"];
      // this should only happen at older assignment-entries
      origGroup = [self _vatGroupForFactor:vat fromGroups:vatGroups];
      if (origGroup == nil) {
        vatGroup =
          [NSMutableDictionary dictionaryWithObjectsAndKeys:
                               vat, @"factor", nil];
        netAmount = 0.0;
      } else {
        vatGroup =
          [NSMutableDictionary dictionaryWithDictionary:origGroup];
        netAmount = [[vatGroup objectForKey:@"netAmount"] doubleValue];
      }
      netAmount +=
        (rint([[article valueForKey:@"netAmount"] doubleValue]
              *[[article valueForKey:@"articleCount"] doubleValue]*100.0)
         * 0.01);
      [vatGroup takeValue: [NSNumber numberWithDouble: netAmount]
                forKey:@"netAmount"];
      if (origGroup != nil) {
        [vatGroups removeObject: origGroup];
      }
      [vatGroups addObject: vatGroup];
    }
    {
      NSEnumerator* groupEnum = [vatGroups objectEnumerator];
      double vatAmount = 0.0;
      double netAmount = 0.0;
      vatGroup = nil;
      while ((vatGroup = [groupEnum nextObject])) {
        netAmount = [[vatGroup objectForKey:@"netAmount"] doubleValue];
        netAmount = rint(netAmount * 100.0) * 0.01;
        vatAmount =
          netAmount*[[vatGroup objectForKey:@"factor"] doubleValue];
        vatAmount = rint(vatAmount * 100.0) * 0.01;
        [vatGroup takeValue: [NSNumber numberWithDouble:vatAmount]
                  forKey:@"vatAmount"];
        [vatGroup takeValue: [NSNumber numberWithDouble:netAmount]
                  forKey:@"netAmount"];
        [vatGroup takeValue:
                  [NSNumber numberWithDouble:
                            rint(100.0 *
                             [[vatGroup valueForKey:@"factor"] doubleValue])]
                  forKey:@"vatLabel"];
      }
    }
    [invoice takeValue: vatGroups forKey:@"vatGroups"];
    // invoice_cancel??
    if ([[invoice valueForKey:@"kind"] isEqualToString:@"invoice_cancel"]) {
      [self _fetchAdditionalValuesForCancelInvoice:invoice inContext:_context];
    }
  }
  [self setReturnValue: self->invoices];
}

- (NSString *)entityName {
  return @"Invoice";
}

//accessors

- (void)setInvoices:(NSArray *)_invoices {
  ASSIGN(self->invoices, _invoices);
}
- (NSArray *)invoices {
  return self->invoices;
}

// key/value coding

- (void)takeValue:(id)_value forKey:(id)_key {
  if (([_key isEqualToString:@"invoices"]) ||
      ([_key isEqualToString:@"objects"])) {
    [self setInvoices:_value];
    return;
  }
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if (([_key isEqualToString:@"invoices"]) ||
      ([_key isEqualToString:@"objects"])) {
    return [self invoices];
  }
  return [super valueForKey:_key];
}

@end
