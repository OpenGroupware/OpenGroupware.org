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

#include <LSFoundation/LSDBObjectSetCommand.h>

@class NSNumber;

/*
  parameter:
    value   - value of accounting ('NSNumber')
    account - account ('eo/invoiceaccount' type)
    
 */

@interface LSInvoiceAccountingCommand : LSDBObjectSetCommand
{
  NSNumber* value;
  id        account;
}

@end

#include "common.h"

@implementation LSInvoiceAccountingCommand

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->value);
  RELEASE(self->account);
  [super dealloc];
}
#endif

- (void)_prepareForExecutionInContext:(id)_context {
  id            acc;
  NSEnumerator *teamEnum;
  id            team;
  BOOL          access = NO;
  
  acc = [_context valueForKey:LSAccountKey];
  teamEnum =
    [LSRunCommandV(_context, @"account", @"teams",
                  @"account", acc,
                  @"returnType", intObj(LSDBReturnType_ManyObjects),
                  nil) objectEnumerator];
  
  while ((team = [teamEnum nextObject])) {
    if ([[team valueForKey:@"login"] isEqualToString:@"invoices"]) {
      access = YES;
      break;
    }
  }
  [self assert:access
        reason:@"You have no permission for doing that!"];
  
  [super _prepareForExecutionInContext:_context];
}

- (void)_executeInContext:(id)_context {
  id     obj;
  id     oldVal;
  id     newVal;
  double grossAmount;
  
  obj = [self object];
  grossAmount = [[obj valueForKey:@"grossAmount"] doubleValue];
  
  oldVal = [obj valueForKey:@"paid"];
  oldVal = ((oldVal == nil) || (![oldVal isNotNull]))
    ? [NSNumber numberWithDouble:0.0]
    : oldVal;
  
  newVal = [NSNumber numberWithDouble:
                     [oldVal doubleValue]
                     + [self->value doubleValue]];
  [obj takeValue:newVal forKey:@"paid"];
  [super _executeInContext:_context];

  LSRunCommandV(_context,
                @"invoiceaccounting", @"new",
                @"invoiceId", [obj valueForKey:@"invoiceId"],
                @"accountId", [self->account valueForKey:@"invoiceAccountId"],
                @"value",     value,
                nil);
  if (grossAmount <= [newVal doubleValue]) {
    LSRunCommandV(_context,
                  @"invoice", @"finish",
                  @"object", obj,
                  nil);
  }
}

- (NSString*)entityName {
  return @"Invoice";
}

// accessors

- (void)setValue:(NSNumber *)_value {
  ASSIGN(self->value, _value);
}
- (NSNumber *)value {
  return self->value;
}

- (void)setAccount:(id)_account {
  ASSIGN(self->account, _account);
}
- (id)account {
  return self->account;
}

// key/value coding

- (void)takeValue:(id)_val forKey:(id)_key {
  if ([_key isEqualToString:@"value"]) {
    [self setValue:_val];
    return;
  }
  if ([_key isEqualToString:@"account"]) {
    [self setAccount:_val];
    return;
  }
  [super takeValue:_val forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"value"]) {
    return [self value];
  }
  if ([_key isEqualToString:@"account"]) {
    return [self account];
  }
  return [super valueForKey:_key];
}


@end
