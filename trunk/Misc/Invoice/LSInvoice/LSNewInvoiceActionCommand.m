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
    accountId   - accountId of account
    invoiceId   - invoiceId of invoice to log (optional)
    documentId  - documentId of refering document (optional)
    kind        - 00_accouting | 05_monition_printout |
                  10_invoice_printout | 15_canceling |
                  20_settling | ...
    logText     - logText for the action
 */
@interface LSNewInvoiceActionCommand : LSDBObjectNewCommand
{
}
@end

#import "common.h"

@implementation LSNewInvoiceActionCommand

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
  [self assert:([self valueForKey:@"accountId"] != nil)
        reason:@"No accountId set!"];
  [self assert:([self valueForKey:@"kind"] != nil)
        reason:@"No kind set!"];
  
  [self takeValue:[NSCalendarDate date] forKey:@"actionDate"];
  [super _prepareForExecutionInContext:_context];
}

- (NSString*)entityName {
  return @"InvoiceAction";
}

@end
