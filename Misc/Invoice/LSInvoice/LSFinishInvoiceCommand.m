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

#import "common.h"
#import "LSFinishInvoiceCommand.h"

@implementation LSFinishInvoiceCommand

- (void)_prepareForExecutionInContext:(id)_context {
  NSString     *status, *no;
  NSEnumerator *teamEnum;
  id           account, obj, team;
  BOOL         access = NO;

  obj     = [self object];
  status  = [obj valueForKey:@"status"];
  no      = [obj valueForKey:@"invoiceNr"];
  account = [_context valueForKey:LSAccountKey];

  teamEnum = [LSRunCommandV(_context, @"account", @"teams",
                            @"account", account,
                            @"returnType", intObj(LSDBReturnType_ManyObjects),
                            nil)
                           objectEnumerator];

  while ((team = [teamEnum nextObject])) {
    if ([[team valueForKey:@"login"] isEqualToString:@"invoices"]) {
      access = YES;
    }
  }
  [self assert:access reason:@"No permission to finish invoice!"];
  [self assert:(
        ([status isEqualToString:@"05_printed"]) ||
        ([status isEqualToString:@"15_monition"]) ||
        ([status isEqualToString:@"16_monition2"]) ||
        ([status isEqualToString:@"17_monition3"]))
        format:
        @"\nInvoice %@ can't be finished in this status!"
        @"\nRechnung %@ kann in diesem Status nicht beglichen werden!", no, no];
  
  [super _prepareForExecutionInContext:_context];
}

- (void)_executeInContext:(id)_context {
  id grossAmount;
  id paid;
  id value;
  id type;
  id invoice;
  id debitor;
  id account;

  invoice     = [self object];
  grossAmount = [invoice valueForKey:@"grossAmount"];
  paid        = [invoice valueForKey:@"paid"];
  type        = [invoice valueForKey:@"kind"];
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
  if (![type isEqualToString:@"invoice_cancel"]) {
    [invoice takeValue:grossAmount forKey:@"paid"];
  }
  [invoice takeValue:@"20_done" forKey:@"status"];
    
  PREPAREINVOICEMONEY(invoice);
  [super _executeInContext:_context];

  if (([value doubleValue] != 0.0) &&
      (![type isEqualToString:@"invoice_cancel"])) {
    LSRunCommandV(_context,
                  @"invoiceaccounting", @"new",
                  @"invoiceId", [invoice valueForKey:@"invoiceId"],
                  @"accountId", [account valueForKey:@"invoiceAccountId"],
                  @"value", value,
                  nil);
  }
  LSRunCommandV(_context,
                @"invoiceaction", @"new",
                @"accountId", [account valueForKey:@"invoiceAccountId"],
                @"invoiceId", [invoice valueForKey:@"invoiceId"],
                @"kind", @"20_settling",
                @"logText", @"Invoice settled",
                nil);
  
  LSRunCommandV(_context,
                @"object", @"add-log",
                @"logText", @"Invoice settled",
                @"action", @"05_changed",
                @"objectToLog", [self object],
                nil);
}

- (NSString*)entityName {
  return @"Invoice";
}


@end
