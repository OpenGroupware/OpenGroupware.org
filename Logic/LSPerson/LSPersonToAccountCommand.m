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

#include <LSFoundation/LSDBObjectBaseCommand.h>

@class NSString;

/* 
   The command sets the isAccount flag to YES
   must be NO before
*/

@interface LSPersonToAccountCommand : LSDBObjectBaseCommand
@end

#include "common.h"

@implementation LSPersonToAccountCommand

- (void)_prepareForExecutionInContext:(id)_context {
  id  obj = [self object];
  BOOL isAccount;

  [self assert:([self object] != nil)
        reason:@"no person object to act on"];

  [self assert:[_context isRoot]
        reason:@"Only root or user itself can account state."];
  
  isAccount = [[obj valueForKey:@"isAccount"] boolValue];
  [self assert:!isAccount
        reason:@"only non-accounts accepted"];
  
  [super _prepareForExecutionInContext:_context];
}

- (void)_executeInContext:(id)_context {
  LSRunCommandV(_context, @"person", @"change-login-status",
                @"object",      [self object],
                @"loginStatus", [NSNumber numberWithBool:YES], nil);
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"object"] ||
      [_key isEqualToString:@"account"]) {
    [self setObject:_value];
    return;
  }
  [self logWithFormat:
	  @"WARNING[%s]: key %@ is not setable in toaccount command",
	  __PRETTY_FUNCTION__, _key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"object"] ||
      [_key isEqualToString:@"account"]) {
    return [self object];
  }
  [self logWithFormat:@"WARNING[%s]: key %@ is not valid in toaccount command",
        __PRETTY_FUNCTION__, _key];
  return nil;
}

@end /* LSPersonToAccountCommand */
