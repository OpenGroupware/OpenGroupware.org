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

#include <LSFoundation/LSDBObjectGetCommand.h>

@interface LSGetInvoiceActionCommand : LSDBObjectGetCommand
{

}
@end

#import "common.h"

@implementation LSGetInvoiceActionCommand

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
  
  [super _prepareForExecutionInContext:_context];
}

- (NSString*)entityName {
  return @"InvoiceAction";
}

@end
