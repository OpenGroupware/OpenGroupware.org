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
#import "LSNewInvoiceArticleAssignmentCommand.h"

@implementation LSNewInvoiceArticleAssignmentCommand

- (void)_prepareForExecutionInContext:(id)_context {
  NSNumber *invoiceId = [self valueForKey:@"invoiceId"];
  id invoice = [LSRunCommandV(_context,
                              @"invoice", @"get",
                              @"invoiceId", invoiceId,
                              nil) lastObject];
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
  [self assert:
        [[invoice valueForKey:@"status"] isEqualToString:@"00_created"]
        reason:@"Invoice isn't editable is this status"];
  [super _prepareForExecutionInContext:(id)_context];
}

- (NSString*)entityName {
  return @"InvoiceArticleAssignment";
}

@end
