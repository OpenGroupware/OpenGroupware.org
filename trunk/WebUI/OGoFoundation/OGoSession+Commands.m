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

#include "OGoSession.h"
#include "common.h"
#include <LSFoundation/OGoContextSession.h>
#include <LSFoundation/OGoContextManager.h>

@interface WOComponent(RequiredMethods)
- (void)setErrorString:(NSString *)_value;
@end

@implementation OGoSession(Commands)

/* LSOffice commands */

static NSNull *null = nil;

static inline NSMutableDictionary *_vaToDict(OGoSession *self, va_list *va) {
  NSMutableDictionary *result = nil;
  NSString *argName = nil;
  id       argValue = nil;
  
  if (va == NULL) return nil;

  if (null == nil) null = [[NSNull null] retain];
  
  do {
    if ((argName = va_arg(*va, NSString *)) == nil)
      // all arguments are processed
      break;
    
    if ((argValue = va_arg(*va, id)) == nil)
      argValue = null;
    
    if (result == nil)
      result = [NSMutableDictionary dictionaryWithCapacity:64];
    
    [result setObject:argValue forKey:argName];
  }
  while (YES);

  return result;
}

- (BOOL)handleException:(NSException *)_exc
  inCommand:(NSString *)_command
  arguments:(NSDictionary *)_args
{
  [self logWithFormat:@"command %@(%@) failed:\n"
          @"  name:   %@"
          @"  reason: %@"
          @"  info:   %@",
          _command, _args ? (id)_args : @"<void>",
          [_exc name], [_exc reason],
          [_exc userInfo] ? (id)[_exc userInfo] : @"<none>"];

  [[[self context] page]
          setErrorString:[NSString stringWithFormat:@"%@: %@ %@",
                                     _command, [_exc name], [_exc reason]]];
  
  if ([[NSUserDefaults standardUserDefaults]
                       boolForKey:@"LSCoreOnCommandException"]) {
    NSLog(@"dumping core because of LSCoreOnCommandException is turned on ..");
    abort();
  }
  
  return NO;
}
- (void)logFailedCommand:(NSString *)_command arguments:(NSDictionary *)_args {
  [self logWithFormat:@"FAIL: %@(%@) failed.",
          _command, _args ? (id)_args : @"<void>"];
}

- (id)runCommand:(NSString *)_command arguments:(NSDictionary *)_args {
  BOOL isOk = YES;
  id result;

  *(&result) = nil;
  
  NS_DURING {
    result = [[self commandContext] runCommand:_command arguments:_args];
  }
  NS_HANDLER {
    isOk = [self handleException:localException
                 inCommand:_command
                 arguments:_args];
  }
  NS_ENDHANDLER;

  if (isOk) return result;

  [self logFailedCommand:_command arguments:_args];
  return nil;
}
- (id)runCommandInTransaction:(NSString *)_comm arguments:(NSDictionary *)_args {
  BOOL isOk    = YES;
  BOOL beganTx;
  id   result;

  *(&result) = nil;
  beganTx = [[self commandContext] isTransactionInProgress] ? NO : YES;
  
  NS_DURING {
    result = [[self commandContext] runCommand:_comm arguments:_args];
  }
  NS_HANDLER {
    isOk = [self handleException:localException
                 inCommand:_comm
                 arguments:_args];
  }
  NS_ENDHANDLER;

  if (isOk) {
    if ([[self commandContext] isTransactionInProgress]) {
      if (![[self commandContext] commit]) {
        [[self commandContext] rollback];
        [self logWithFormat:@"commit during command %@ did fail !", _comm];
        return nil;
      }
    }
    return result;
  }
  else {
    if (beganTx) {
      if (![[self commandContext] rollback]) {
        [self logWithFormat:@"rollback after failure of command %@ failed !",
                _comm];
      }
    }
    [self logFailedCommand:_comm arguments:_args];
    return nil;
  }
}

- (id)runCommand1:(NSString *)_command, ... {
  va_list      va;
  NSDictionary *args  = nil;
  id           result = nil;
  
  va_start(va, _command);
  args = _vaToDict(self, &va);
  va_end(va);
  
  [args takeValue:intObj(LSDBReturnType_OneObject) forKey:@"returnType"];
  result = [self runCommand:_command arguments:args];
  result = [result lastObject];
  return result;
}
- (id)runCommand:(NSString *)_command, ... {
  va_list      va;
  NSDictionary *args = nil;
  
  va_start(va, _command);
  args = _vaToDict(self, &va);
  va_end(va);

  return [self runCommand:_command arguments:args];
}
- (id)runCommandInTransaction:(NSString *)_command, ... {
  va_list      va;
  NSDictionary *args = nil;
  
  va_start(va, _command);
  args = _vaToDict(self, &va);
  va_end(va);

  return [self runCommandInTransaction:_command arguments:args];
}

// Controlling transactions

- (BOOL)commit {
  BOOL ok = [[self commandContext] commit];
  if (!ok) [self logWithFormat:@"WARNING: tx commit failed !"];
  return ok;
}
- (BOOL)rollback {
  BOOL ok;
  [self logWithFormat:@"tx is going to be rolled back .."];
  ok = [[self commandContext] rollback];
  if (!ok) [self logWithFormat:@"WARNING: tx commit failed !"];
  return ok;
}

- (BOOL)beginTransaction { // deprecated
  [self debugWithFormat:@"explicit tx begin (ignored) (lso=%@)..", self->lso];
  return YES;
}
- (BOOL)commitTransaction { // deprecated
  return [self commit];
}
- (BOOL)rollbackTransaction { // deprecated
  return [self rollback];
}

- (BOOL)isTransactionInProgress {
  return [[self commandContext] isTransactionInProgress];
}

@end /* OGoSession(Commands) */
