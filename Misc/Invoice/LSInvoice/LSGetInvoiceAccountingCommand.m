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
  parameter:
    invoiceAccountId (optional) --> filter accountings for invoice-account
 */

@class NSNumber;

@interface LSGetInvoiceAccountingCommand : LSDBObjectGetCommand
{
  NSNumber *accountId;
}
@end

#import "common.h"

@implementation LSGetInvoiceAccountingCommand

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->accountId);
  [super dealloc];
}
#endif

- (EOSQLQualifier *)_qualifier {
  EOAdaptor      *adaptor;
  EOEntity       *myEntity;
  EOSQLQualifier *qual;
  
  if (self->accountId == nil)
    return [super _qualifier];

  adaptor  = [self databaseAdaptor];
  myEntity = [self entity];
  
  qual    = [EOSQLQualifier allocWithZone:[self zone]];
  qual = [qual initWithEntity: myEntity
               qualifierFormat:@"%A = %@",
               @"toInvoiceAction.accountId", self->accountId];
  return AUTORELEASE(qual);
}

- (void)_prepareForExecutionInContext:(id)_context {
  id           account;
  NSEnumerator *teamEnum;
  id           team;
  BOOL         access = NO;
  
  account = [_context valueForKey:LSAccountKey];
  teamEnum =
    [LSRunCommandV(_context, @"account", @"teams",
                  @"account", account,
                  @"returnType", intObj(LSDBReturnType_ManyObjects),
                  nil) objectEnumerator];
  while ((team = [teamEnum nextObject])) {
    if ([[team valueForKey:@"login"] isEqualToString:INVOICES_TEAM]) {
      access = YES;
      break;
    }
  }
  [self assert:access
        reason:@"You have no permission for doing that!"];
  
  [super _prepareForExecutionInContext:_context];
}

- (NSString*)entityName {
  return @"InvoiceAccounting";
}

//accessors

- (void)setAccountId:(NSNumber*)_accountId {
  ASSIGN(self->accountId, _accountId);
}
- (NSNumber *)accountId {
  return self->accountId;
}

// key/value coding

- (void)takeValue:(id)_val forKey:(id)_key {
  if ([_key isEqualToString:@"invoiceAccountId"]) {
    [self setAccountId:_val];
    return;
  }
  [super takeValue:_val forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"invoiceAccountId"]) {
    return [self accountId];
  }
  return [super valueForKey:_key];
}

@end
