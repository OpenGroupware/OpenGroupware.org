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

#include <LSFoundation/LSDBObjectGetCommand.h>

/*

  Parameter:

    debitors - array of debitors ('enterprise' objects)
   or
    debitor  - single debitor ('enterprise' object)
*/

@interface LSFetchUnsettledInvoicesCommand: LSDBObjectGetCommand
{
  NSArray *objects;

  /* calculation state */
  NSString            *debitorIdsIN;
  NSMutableDictionary *pkeyToDebitor;
}

@end

#import "common.h"

#define LSINVOICE_MONITION  @"15_monition"
#define LSINVOICE_MONITION2 @"16_monition2"
#define LSINVOICE_MONITION3 @"17_monition3"

@interface LSFetchUnsettledInvoicesCommand(PrivateMethods)
- (NSArray*)objects;
@end

@implementation LSFetchUnsettledInvoicesCommand

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->pkeyToDebitor);
  RELEASE(self->objects);
  RELEASE(self->debitorIdsIN);
  [super dealloc];
}
#endif

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
  [self assert: (([self object] != nil) || ([self objects] != nil))
        reason: @"No Debitor set!"];
  
  [super _prepareForExecutionInContext:_context];

  /* construct IN ids */
  
  self->pkeyToDebitor = [[NSMutableDictionary alloc] init];
  
  if (self->objects == nil) {
    id pkey;
    
    pkey = [[self object] valueForKey:@"companyId"];
    self->debitorIdsIN = [[pkey stringValue] copy];
    [self->pkeyToDebitor setObject:[self object] forKey:pkey];
    [[self object] takeValue: [NSMutableArray array]
                   forKey:@"unsettledInvoices"];
  }
  else {
    NSMutableString *s;
    NSEnumerator    *e;
    id   obj;
    BOOL isFirst;
    
    s = [NSMutableString stringWithCapacity:255];

    e = [self->objects objectEnumerator];
    isFirst = YES;
    while ((obj = [e nextObject])) {
      id pkey;
      if (isFirst) isFirst = NO;
      else [s appendString:@","];
      
      pkey = [obj valueForKey:@"companyId"];
      [s appendString:[pkey stringValue]];
      
      [self->pkeyToDebitor setObject:obj forKey:pkey];
      [obj takeValue:[NSMutableArray array] forKey:@"unsettledInvoices"];
    }
    
    self->debitorIdsIN = [s copy];
  }
}

- (void)_fetchInvoicesInContext:(id)_context {
  id                entity;
  EOSQLQualifier    *invoiceQualifier;
  EODatabaseChannel *dbChannel;
  id                invoice;
  NSDictionary      *monitionLevels;
  
  entity = [[self database] entityNamed:[self entityName]];
  invoiceQualifier =
    [[EOSQLQualifier alloc]
                     initWithEntity:entity
                     qualifierFormat:
                     @"(status='05_printed' OR "
                     @"status='15_monition' OR "
                     @"status='16_monition2' OR "
                     @"status='17_monition3')"
                     @" AND debitor_id IN (%@)",
                     self->debitorIdsIN];
  [invoiceQualifier setUsesDistinct:YES];
  
  dbChannel = [self databaseChannel];
  
  monitionLevels =
    [NSDictionary dictionaryWithObjectsAndKeys:
                  [NSNumber numberWithInt:0], @"05_printed",
                  [NSNumber numberWithInt:1], @"15_monition",
                  [NSNumber numberWithInt:2], @"16_monition2",
                  [NSNumber numberWithInt:3], @"17_monition3",
                  nil];
  
  [dbChannel selectObjectsDescribedByQualifier: invoiceQualifier
             fetchOrder: nil];
  
  while ((invoice = [dbChannel fetchWithZone:nil])) {
    NSCalendarDate   *date;
    NSNumber         *level;
    id               debitor;
    NSMutableArray   *result;
    NSCalendarDate   *oldestMonitionDate;
    NSNumber         *cnt;
    NSNumber         *maxMonitionLevel;
    NSNumber         *allMonitionValue;
    NSNumber         *toPay;
    NSNumber         *grossAmount;
    NSNumber         *paid;

    debitor     = [self->pkeyToDebitor objectForKey:
                       [invoice valueForKey:@"debitorId"]];
    date        = [invoice valueForKey:@"invoiceDate"];
    level       = [monitionLevels objectForKey:
                                  [invoice valueForKey:@"status"]];
    grossAmount = [invoice valueForKey:@"grossAmount"];
    paid        = [invoice valueForKey:@"paid"];
    
    paid    = ((paid == nil) || (![paid isNotNull]))
      ? [NSNumber numberWithDouble:0.0]
      : paid;

    if ([[invoice valueForKey:@"kind"] isEqualToString:@"invoice_cancel"]) {
      toPay = [NSNumber numberWithDouble:([paid doubleValue]*(-1))];
      [invoice takeValue:[NSNumber numberWithDouble:0.0]
               forKey:@"grossAmount"];
    } else {
      toPay = [NSNumber numberWithDouble:
                        [grossAmount doubleValue] - [paid doubleValue]];
    }
    
    result             = [debitor valueForKey:@"unsettledInvoices"];
    oldestMonitionDate = [debitor valueForKey:@"oldestUnsettledInvoiceDate"];
    cnt                = [debitor valueForKey:@"unsettledInvoicesCount"];
    maxMonitionLevel   = [debitor valueForKey:@"highestMonitionLevel"];
    allMonitionValue   = [debitor valueForKey:@"allMonitionValue"];

    if ((result != nil) && ([result containsObject: invoice])) {
      continue;
    }
    
    if ((result == nil) || ([result count] == 0)) {      
      result             = [NSMutableArray array];
      oldestMonitionDate = date;
      cnt                = [NSNumber numberWithInt: 1];
      maxMonitionLevel   =
        [monitionLevels objectForKey:[invoice valueForKey:@"status"]];
      allMonitionValue   = toPay;
    } else {
      oldestMonitionDate =
        ([oldestMonitionDate compare: date] == NSOrderedAscending)
        ? oldestMonitionDate : date;
      cnt = [NSNumber numberWithInt: [cnt intValue]+1];
      if ([level intValue] > [maxMonitionLevel intValue])
        maxMonitionLevel = level;
      allMonitionValue =
        [NSNumber numberWithDouble:
                  [allMonitionValue doubleValue]
                  + [toPay doubleValue]];
    }

    [invoice takeValue:level forKey:@"monitionLevel"];
    [invoice takeValue:toPay forKey:@"toPay"];
    [result  addObject:invoice];
    [debitor takeValue:cnt
             forKey:@"unsettledInvoicesCount"];
    [debitor takeValue:oldestMonitionDate
             forKey:@"oldestUnsettledInvoiceDate"];
    [debitor takeValue:maxMonitionLevel
             forKey:@"highestMonitionLevel"];
    [debitor takeValue:allMonitionValue
             forKey:@"allMonitionValue"];
    [debitor takeValue:result
             forKey:@"unsettledInvoices"];
  }
}

- (void)_executeInContext:(id)_context {
  [self _fetchInvoicesInContext:_context];
  [self setReturnValue:
        (self->objects == nil)
        ? [[self object] valueForKey:@"unsettledInvoices"]
        : [self objects]];
}

- (NSString *)entityName {
  return @"Invoice";
}

// key/value coding

- (void)setObjects:(NSArray*)_objects {
  ASSIGN(self->objects, _objects);
}
- (NSArray*)objects {
  return self->objects;
}

- (void)takeValue:(id)_val forKey:(id)_key {
  if (([_key isEqualToString:@"objects"]) ||
      ([_key isEqualToString:@"debitors"])) {
    [self setObjects: _val];
    return;
  }
  [super takeValue:_val forKey:_key];
}

- (id)valueForKey:(id)_key {
  if (([_key isEqualToString:@"objects"]) ||
      ([_key isEqualToString:@"debitors"])) {
    return [self objects];
  }
  return [super valueForKey:_key];
}


@end
