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

#include <LSFoundation/LSDBObjectNewCommand.h>
/*
  Parameter:
    invoiceId - invoiceId of invoice (optional)
    accountId - accountId of account
    value     - value to account
    logText   - text for action-log (optional)
 */

@class NSNumber;

@interface LSNewInvoiceAccountingCommand : LSDBObjectNewCommand
{
  NSNumber *value;
  NSNumber *invoiceId;
  NSNumber *accountId;
  NSString *logText;
}
@end

#import "common.h"
#include <math.h>

@interface LSNewInvoiceAccountingCommand(PrivateMethods)
- (void)setLogText:(NSString*)logText;
@end

@implementation LSNewInvoiceAccountingCommand

- (id)initForOperation:(NSString*)_operation
              inDomain:(NSString*)_domain
{
  if ((self = [super initForOperation:_operation inDomain:_domain])) {
    self->logText = nil;
    self->value = nil;
    self->invoiceId = nil;
    self->accountId = nil;
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->value);
  RELEASE(self->invoiceId);
  RELEASE(self->accountId);
  RELEASE(self->logText);
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
    [LSRunCommandV(_context, @"account", @"teams",
                  @"account", account,
                  @"returnType", intObj(LSDBReturnType_ManyObjects),
                  nil) objectEnumerator];
  while ((team = [teamEnum nextObject])) {
    if ([[team valueForKey:@"login"] isEqualToString:INVOICES_TEAM]) {
      access = YES;
    }
  }
  [self assert:access
        reason:@"You have no permission for doing that!"];

  [self assert:(self->accountId != nil)
        reason:@"No accountId set!"];
  [self assert:(self->value != nil)
        reason:@"No value set!"];

  if ([self->value doubleValue] < 0.0) {
    [self takeValue:
          [NSNumber numberWithDouble:[self->value doubleValue]*(-1.0)]
          forKey:@"debit"];
    [self takeValue:nil forKey:@"balance"];
    if (self->logText == nil)
      [self setLogText:@"Invoice"];
  } else {
    [self takeValue:self->value forKey:@"balance"];
    [self takeValue:nil         forKey:@"debit"];
    if (self->logText == nil)
      [self setLogText:@"Balance"];
  }

  [self takeValue:[NSCalendarDate date] forKey:@"actionDate"];
  [super _prepareForExecutionInContext:_context];
}

- (void)_executeInContext:(id)_context {
  id action;
  id account;
  id balance;

  action =
    LSRunCommandV(_context, @"invoiceaction", @"new",
                  @"accountId", self->accountId,
                  @"kind",      @"00_accounting",
                  @"logText",   self->logText,
                  @"invoiceId", self->invoiceId,
                  nil);

  [[self object]
         takeValue:[action valueForKey:@"invoiceActionId"]
         forKey:@"actionId"];
  
  [super _executeInContext:_context];
  account =
    [LSRunCommandV(_context,
                   @"invoiceAccount", @"get",
                   @"invoiceAccountId", self->accountId,
                   nil) lastObject];
  {
    // rounding balance value for correct db entry
    double all = [[account valueForKey:@"balance"] doubleValue];

    all += [self->value doubleValue];
    balance = MONEY2SAVEFORDOUBLE(all);
    //all = rint(all * 100.0) * 0.01;
    //balance = [NSNumber numberWithDouble:all];
  }
  LSRunCommandV(_context,
                @"invoiceAccount", @"set",
                @"object", account,
                @"balance", balance,
                @"accountNr", [account valueForKey:@"accountNr"],
                @"companyId", [account valueForKey:@"companyId"],
                nil);
};

- (NSString *)entityName {
  return @"InvoiceAccounting";
}

//accessors

- (void)setValue:(NSNumber *)_value {
  ASSIGN(self->value, _value);
}
- (NSNumber *)value {
  return self->value;
}

- (void)setInvoiceId:(NSNumber *)_invoiceId {
  ASSIGN(self->invoiceId, _invoiceId);
}
- (NSNumber *)invoiceId {
  return self->invoiceId;
}

- (void)setAccountId:(NSNumber *)_accountId {
  ASSIGN(self->accountId, _accountId);
}
- (NSNumber *)accountId {
  return self->accountId;
}

- (void)setLogText:(NSString *)_logText {
  ASSIGN(self->logText, _logText);
}
- (NSString *)logText {
  return self->logText;
}

// key/value coding

- (void)takeValue:(id)_val forKey:(id)_key {
  if ([_key isEqualToString:@"value"]) {
    [self setValue:_val];
    return;
  }
  if ([_key isEqualToString:@"invoiceId"]) {
    [self setInvoiceId:_val];
    return;
  }
  if ([_key isEqualToString:@"accountId"]) {
    [self setAccountId:_val];
    return;
  }  
  if ([_key isEqualToString:@"logText"]) {
    [self setLogText:_val];
    return;
  }  
  [super takeValue:_val forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"value"]) {
    return [self value];
  }
  if ([_key isEqualToString:@"invoiceId"]) {
    return [self invoiceId];
  }
  if ([_key isEqualToString:@"accountId"]) {
    return [self accountId];
  }
  if ([_key isEqualToString:@"logText"]) {
    return [self logText];
  }
  return [super valueForKey:_key];
}

@end
