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

#include "LSSystemCtxTransferCommand.h"
#include "common.h"

// TODO: actually used anywhere?!

@implementation LSSystemCtxTransferCommand

- (id)initForOperation:(NSString *)_operation inDomain:(NSString *)_domain {
  if ((self = [super initForOperation:_operation inDomain:_domain])) {
    self->keysToTransfer = [[NSMutableDictionary alloc] initWithCapacity:16];
  }
  return self;
}

- (void)dealloc {
  [self->keysToTransfer release];
  [self->command        release];
  [super dealloc];
}

/* command type */

- (BOOL)requiresChannel {
  return NO;
}
- (BOOL)requiresTransaction {
  return NO;
}

/* command methods */

- (void)_executeInContext:(id)_context {
  NSEnumerator *keys;
  NSString *key;
  
  keys = [keysToTransfer keyEnumerator];
  while ((key = [keys nextObject]) != nil) {
    NSString *targetKey = [keysToTransfer objectForKey:key];

    NSAssert([key isKindOfClass:[NSString class]], 
	     @"key must be a string");
    NSAssert([targetKey isKindOfClass:[NSString class]], 
	     @"key must be a string");

    [command takeValue:[_context valueForKey:key]
             forKey:targetKey];
  }

  [command runInContext:_context];
}

/* accessors */

- (void)setCommand:(id<NSObject,LSCommand>)_command {
  ASSIGN(command, _command);
}
- (id<NSObject,LSCommand>)command {
  return command;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  NSAssert([_key isKindOfClass:[NSString class]], @"key must be a string");
  
  if ([_key isEqualToString:@"command"])
    [self setCommand:_value];
  else {
    NSAssert([_value isKindOfClass:[NSString class]], 
	     @"value must be a string");
    [keysToTransfer setObject:_value forKey:_key];
  }
}

- (id)valueForKey:(NSString *)_key {
  NSAssert([_key isKindOfClass:[NSString class]], @"key must be a string");
  
  if ([_key isEqualToString:@"command"])
    return [self command];

  return [keysToTransfer objectForKey:_key];
}

@end /* LSSystemCtxTransferCommand */
