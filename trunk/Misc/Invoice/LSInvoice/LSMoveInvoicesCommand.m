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
#import "LSMoveInvoicesCommand.h"

@interface LSMoveInvoicesCommand(PrivatMethods)
- (void)setMoveTo:(NSCalendarDate*)_date;
@end

@implementation LSMoveInvoicesCommand

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->invoices);
  RELEASE(self->moveTo);
  [super dealloc];
}
#endif

- (void)_moveInvoice:(id)_invoice inContext:(id)_context {
  [_invoice takeValue:self->moveTo forKey:@"invoiceDate"];
  LSRunCommandV(_context, @"invoice", @"set",
                @"object", _invoice,
                nil);
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
    }
  }
  [self assert:access
        reason:@"You have no permission for doing that!"];
  if (self->moveTo == nil) {
    [self setMoveTo:[NSCalendarDate date]];
  }
}

- (void)_executeInContext:(id)_context {
  NSEnumerator *invEnum = [self->invoices objectEnumerator];
  id invoice;

  while ((invoice = [invEnum nextObject])) {
    [self _moveInvoice: invoice inContext: _context];
    LSRunCommandV(_context,
                  @"object", @"add-log",
                  @"logText",
                  [NSString stringWithFormat:
                            @"Invoice moved to %@",
                            self->moveTo],
                  @"action", @"05_changed",
                  @"objectToLog", invoice,
                  nil);
  }
  [self setReturnValue: invoices];
}

- (NSString*)entityName {
  return @"Invoice";
}

// accessors

- (void)setInvoices:(NSArray*)_invoices {
  ASSIGN(self->invoices, _invoices);
}
- (NSArray*)invoices {
  return self->invoices;
}

- (void)setMoveTo:(NSCalendarDate*)_date {
  ASSIGN(self->moveTo, _date);
}
- (NSCalendarDate*)moveTo {
  return self->moveTo;
}

// key/value coding

- (void)takeValue:(id)_value forKey:(id)_key {
  if (([_key isEqualToString:@"invoices"]) ||
      ([_key isEqualToString:@"objects"])) {
    [self setInvoices:_value];
    return;
  }
  if ([_key isEqualToString:@"moveTo"]) {
    [self setMoveTo:_value];
    return;
  }
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if (([_key isEqualToString:@"invoices"]) ||
      ([_key isEqualToString:@"objects"])) {
    return [self invoices];
  }
  if ([_key isEqualToString:@"moveTo"]) {
    return [self moveTo];
  }
  return [super valueForKey:_key];
}

@end
