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
#import "LSCopyInvoicesCommand.h"

@interface LSCopyInvoicesCommand(PrivatMethods)
- (void)setInvoices:(NSArray*)_invoices;
- (void)setCopyTo:(NSCalendarDate*)_date;
@end

@implementation LSCopyInvoicesCommand

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->invoices);
  RELEASE(self->copyTo);
  [super dealloc];
}
#endif

- (id)_copyInvoice:(id)_invoice inContext:(id)_context {
  NSArray* articles = [_invoice valueForKey:@"articles"];
  NSMutableDictionary *newInvoice;
  articles = ((articles != nil) && ([articles isNotNull])) 
    ? articles
    : LSRunCommandV(_context,
                    @"invoice",    @"get-articles",
                    @"object",     _invoice,
                    @"returnType", intObj(LSDBReturnType_ManyObjects),
                    nil);
  newInvoice =
    LSRunCommandV(_context,
                  @"invoice",     @"new",
                  @"debitorId",   [_invoice valueForKey:@"debitorId"],
                  @"kind",        [_invoice valueForKey:@"kind"],
                  @"articles",    articles,
                  @"invoiceDate", self->copyTo,
                  @"comment",     [_invoice valueForKey:@"comment"],
                  nil);
  return newInvoice;
}

- (void)_prepareForExecutionInContext:(id)_context {
  id account = [_context valueForKey:LSAccountKey];
  NSEnumerator *teamEnum =
    [LSRunCommandV(_context,
                   @"account",    @"teams",
                   @"account",    account,
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
  if (self->copyTo == nil)
    [self setCopyTo:[NSCalendarDate date]];
}

- (void)_executeInContext:(id)_context {
  NSMutableArray *newInvoices = [NSMutableArray array];
  NSEnumerator   *invEnum     = [self->invoices objectEnumerator];
  id invoice;

  while ((invoice = [invEnum nextObject])) {
    [newInvoices addObject:
                 [self _copyInvoice: invoice inContext:_context]];
  }
  [self setReturnValue: newInvoices];
}

- (NSString*)entityName {
  return @"invoice";
}

// accessors

- (void)setInvoices:(NSArray*)_invoices {
  ASSIGN(self->invoices, _invoices);
}
- (NSArray*)invoices {
  return self->invoices;
}

- (void)setCopyTo:(NSCalendarDate*)_date {
  ASSIGN(self->copyTo, _date);
}
- (NSCalendarDate*)copyTo {
  return self->copyTo;
}

// key/value coding

- (void)takeValue:(id)_value forKey:(id)_key {
  if (([_key isEqualToString:@"invoices"]) ||
      ([_key isEqualToString:@"objects"])) {
    [self setInvoices:_value];
    return;
  }
  if ([_key isEqualToString:@"copyTo"]) {
    [self setCopyTo:_value];
    return;
  }
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if (([_key isEqualToString:@"invoices"]) ||
      ([_key isEqualToString:@"objects"])) {
    return [self invoices];
  }
  if ([_key isEqualToString:@"copyTo"]) {
    return [self copyTo];
  }
  return [super valueForKey:_key];
}

@end
