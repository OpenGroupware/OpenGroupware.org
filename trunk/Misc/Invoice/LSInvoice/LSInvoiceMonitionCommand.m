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
#import "LSInvoiceMonitionCommand.h"

@implementation LSInvoiceMonitionCommand

- (void)_prepareForExecutionInContext:(id)_context {
  id            account;
  NSEnumerator *teamEnum;
  id            team;
  BOOL          access = NO;
  
  account = [_context valueForKey:LSAccountKey];
  teamEnum =
    [LSRunCommandV(_context, @"account", @"teams",
                  @"account", account,
                  @"returnType", intObj(LSDBReturnType_ManyObjects),
                  nil) objectEnumerator];
  while ((team = [teamEnum nextObject])) {
    if ([[team valueForKey:@"login"] isEqualToString:@"invoices"]) {
      access = YES;
    }
  }
  [self assert:access
        reason:@"You have no permission for doing that!"];

  //  [super _prepareForExecutionInContext:_context];
}

- (void)_increaseMonitionLevelForInvoice:(id)_invoice inContext:(id)_context {
  NSString     *status;
  NSNumber     *level;
  NSDictionary *mapping;

  status = [_invoice valueForKey:@"status"];
  [self assert:(![status isEqualToString:@"17_monition3"])
        reason:@"Invoice already in highest monition level."];
  [self assert:
        (([status isEqualToString:@"05_printed"]) ||
         ([status isEqualToString:@"15_monition"]) ||
         ([status isEqualToString:@"16_monition2"]))
        reason:@"Monition level isn't increaseable in this status."];
  mapping =
    [NSDictionary dictionaryWithObjectsAndKeys:
                  @"05_printed",   [NSNumber numberWithInt:0],
                  @"15_monition",  [NSNumber numberWithInt:1],
                  @"16_monition2", [NSNumber numberWithInt:2],
                  @"17_monition3", [NSNumber numberWithInt:3],
                  nil];
  level = [[mapping allKeysForObject: status] lastObject];
  level = [NSNumber numberWithInt:[level intValue] + 1];
  [_invoice takeValue: [mapping objectForKey: level] forKey: @"status"];
}

- (void)_executeInContext:(id)_context {
  NSEnumerator *e;
  id            invoice;
  NSArray      *invoices;
  
  if (![[self object] isKindOfClass:[NSArray class]]) {
    invoices = [NSArray arrayWithObject:[self object]];
  } else {
    invoices = [self object];
  }

  e = [invoices objectEnumerator];

  while ((invoice = [e nextObject])) {
    [self _increaseMonitionLevelForInvoice:invoice inContext:_context];
    PREPAREINVOICEMONEY(invoice);
    [self setObject:invoice];
    [super _executeInContext:_context];
    LSRunCommandV(_context,
                  @"object", @"add-log",
                  @"logText", @"Invoice reminder level increased",
                  @"action", @"05_changed",
                  @"objectToLog", [self object],
                  nil);
  }
  [self setReturnValue:invoices];
}

- (NSString*)entityName {
  return @"Invoice";
}

//key/value coding

- (void)takeValue:(id)_value forKey:(id)_key {
  if (([_key isEqualToString:@"invoices"]) ||
      ([_key isEqualToString:@"objects"])) {
    [self setObject:_value];
    return;
  }
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if (([_key isEqualToString:@"invoices"]) ||
      ([_key isEqualToString:@"objects"])) {
    return [self object];
  }
  return [super valueForKey:_key];
}


@end
