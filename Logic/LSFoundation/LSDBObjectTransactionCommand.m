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

#include "LSDBObjectTransactionCommand.h"
#include "LSDBTransaction.h"
#include "common.h"

@implementation LSDBObjectTransactionCommand

+ (int)version {
  return 1;
}

/* command methods */

- (void)_prepareForExecutionInContext:(id)_context {
  [[self dBTransaction] beginTransaction];
  [self debugWithFormat:@"\n# Transaction begins"];
}

- (void)_executeInContext:(id)_context {
}

- (void)_executeCommandsInContext:(id)_context {
  NSEnumerator           *cmds = [[self commands] objectEnumerator];
  id<NSObject,LSCommand> command = nil;

  while ((command = [cmds nextObject])) {
    id obj = [command runInContext:_context];

    [self setReturnValue:obj];

    isCommandOk = [command isCommandOk];
    if (!isCommandOk) {
      break;
    }
  }
}

- (void)_validateInContext:(id)_context {
  BOOL isOk = NO;

  if ([self isCommandOk]) {
    [self debugWithFormat:@"! All commands for transaction seem to be ok!"];
    isOk = [[self dBTransaction] commitTransaction];

    if (isOk)
      [self logWithFormat:@"# Transaction successfully committed !\n"];
  }
  else {
    [self logWithFormat:
            @"! Not all commands for transaction were ok !\n"
          @"! => Transaction will roll back !\n"];
    isOk = [[self dBTransaction] rollbackTransaction];

    if (isOk)
      [self logWithFormat:@"# Transaction successfully rolled back!"];
  }
}

- (EODatabase *)database {
  return [activeContext valueForKey:LSDatabaseKey];
}

- (EOAdaptor *)databaseAdaptor {
  return [[self database] adaptor];
}

- (void)primaryRunInContext:(id)_context {
  [[NSNotificationCenter defaultCenter]
                           addObserver:self
                           selector:@selector(gotSybaseMessage:)
                           name:@"Sybase10Notification"
                           object:[self databaseAdaptor]];

  [self _prepareForExecutionInContext:_context];
  [self _executeCommandsInContext:_context];
  [self _validateInContext:_context];
}

// database tranaction

- (LSDBTransaction *)dBTransaction {
  return [activeContext valueForKey:LSDBTransactionKey];
}

@end
