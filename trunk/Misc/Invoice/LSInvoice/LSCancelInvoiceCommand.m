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
#import "LSCancelInvoiceCommand.h"

@implementation LSCancelInvoiceCommand

- (void)_prepareForExecutionInContext:(id)_context {
  NSString* status = [[self object] valueForKey:@"status"];
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
  [self assert: (
                 ([status isEqualToString:@"05_printed"]) ||
                 ([status isEqualToString:@"15_monition"]) ||
                 ([status isEqualToString:@"16_monition2"]) ||
                 ([status isEqualToString:@"17_monition3"])
                 )
        reason:@"Invoice isn't cancelenabled in this status."];
  [self assert:
        (![[[self object] valueForKey:@"kind"]
                  isEqualToString:@"invoice_cancel"])
        reason:@"Invoice_cancel isn't cancelenabled."];
  [super _prepareForExecutionInContext:_context];
}

- (void)_executeInContext:(id)_context {
  id grossAmount;
  id paid;
  id value;
  id invoice;
  id debitor;
  id account;

  invoice     = [self object];
  grossAmount = [invoice valueForKey:@"grossAmount"];
  paid        = [invoice valueForKey:@"paid"];
  debitor     =
    LSRunCommandV(_context,
                  @"enterprise", @"get",
                  @"companyId", [invoice valueForKey:@"debitorId"],
                  nil);
  debitor     = [debitor lastObject];
  account     =
    LSRunCommandV(_context,
                  @"invoiceaccount", @"get",
                  @"companyId", [invoice valueForKey:@"debitorId"],
                  nil);
  account     = [account lastObject];

  if ((account == nil) || (![account isNotNull])) {
    account =
      LSRunCommandV(_context,
                    @"enterprise", @"create-invoiceaccount",
                    @"object", debitor,
                    nil);
  }
  
  paid = ((paid == nil) || (![paid isNotNull]))
    ? [NSNumber numberWithDouble:0.0]
    : paid;

  value = [NSNumber numberWithDouble:
                    [grossAmount doubleValue]
                    - [paid doubleValue]];

  [invoice takeValue:@"10_canceled" forKey:@"status"];
  PREPAREINVOICEMONEY(invoice);
  [super _executeInContext:_context];

  LSRunCommandV(_context,
                @"invoiceaction", @"new",
                @"accountId", [account valueForKey:@"invoiceAccountId"],
                @"invoiceId", [invoice valueForKey:@"invoiceId"],
                @"kind", @"15_canceling",
                @"logText", @"Invoice canceled",
                nil);

  LSRunCommandV(_context,
                @"object", @"add-log",
                @"logText", @"Invoice canceled",
                @"action", @"05_changed",
                @"objectToLog", [self object],
                nil);
}

- (NSString*)entityName {
  return @"Invoice";
}


@end
