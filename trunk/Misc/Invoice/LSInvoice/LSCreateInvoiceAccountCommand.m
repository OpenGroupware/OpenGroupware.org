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

#include <LSFoundation/LSDBObjectBaseCommand.h>

/*
  parameter:
    companyId
    accountNr
    balance (optional) default: 0.0

*/

@class NSNumber;

@interface LSCreateInvoiceAccountCommand : LSDBObjectBaseCommand
{
  NSNumber *companyId;
  NSString *accountNr;
  NSNumber *balance;
}

@end

#include "common.h"

@implementation LSCreateInvoiceAccountCommand

- (id)initForOperation:(NSString*)_operation
              inDomain:(NSString*)_domain
{
  if ((self = [super initForOperation:_operation inDomain:_domain])) {
    self->companyId = nil;
    self->accountNr = nil;
    self->balance   = nil;
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->companyId);
  RELEASE(self->accountNr);
  RELEASE(self->balance);
  [super dealloc];
}
#endif

// accessors

- (void)setCompanyId:(NSNumber*)_companyId {
  ASSIGN(self->companyId,_companyId);
}
- (NSNumber*)companyId {
  return self->companyId;
}

- (void)setAccountNr:(NSString*)_accountNr {
  ASSIGN(self->accountNr,_accountNr);
}
- (NSString*)accountNr {
  return self->accountNr;
}

- (void)setBalance:(NSNumber*)_balance {
  ASSIGN(self->balance,_balance);
}
- (NSNumber*)balance {
  return self->balance;
}

// key/value coding

- (void)takeValue:(id)_val forKey:(id)_key {
  if ([_key isEqualToString:@"companyId"]) {
    [self setCompanyId:_val];
    return;
  }
  if ([_key isEqualToString:@"accountNr"]) {
    [self setAccountNr:_val];
    return;
  }
  if ([_key isEqualToString:@"balance"]) {
    [self setBalance:_val];
    return;
  }
  [super takeValue:_val forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"companyId"]) {
    return [self companyId];
  }
  if ([_key isEqualToString:@"accountNr"]) {
    return [self accountNr];
  }
  if ([_key isEqualToString:@"balance"]) {
    return [self balance];
  }
  return [super valueForKey:_key];
}

// command

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
    if ([[team valueForKey:@"login"] isEqualToString:INVOICES_TEAM]) {
      access = YES;
    }
  }
  [self assert:access
        reason:@"You have no permission for doing that!"];

  [self assert:(self->companyId != nil)
        reason:@"No companyId set!"];
  [self assert:(self->accountNr != nil)
        reason:@"No accountNr set!"];

  if (self->balance == nil) {
    [self setBalance:[NSNumber numberWithDouble:0.0]];
  }

  [super _prepareForExecutionInContext:_context];
}

- (void)_executeInContext:(id)_context {
  id account;
    
  account =
    LSRunCommandV(_context,
                  @"invoiceaccount", @"new",
                  @"companyId", self->companyId,
                  @"accountNr", self->accountNr,
                  @"balance", [NSNumber numberWithDouble:0.0],
                  nil);
  LSRunCommandV(_context,
                @"invoiceaccounting", @"new",
                @"accountId", [account valueForKey:@"invoiceAccountId"],
                @"value", self->balance,
                @"logText", @"Openning balance",
                nil);
  
  [self setReturnValue:account];
}

@end
