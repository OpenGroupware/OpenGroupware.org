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

#include "WOComponent+Commands.h"
#include "WOSession+LSO.h"
#include "common.h"

@implementation WOComponent(Commands)

- (void)setErrorString:(NSString *)_str {
  [self logWithFormat:@"ErrorString: %@", _str];
}
- (NSString *)errorString {
  return nil;
}

// errors

- (void)handleFailedTransactionCommit {
  [self logWithFormat:@"%s: commit failed !", __PRETTY_FUNCTION__];
  if ([[self errorString] length] < 1)
    [self setErrorString:@"transaction failed."];
}

- (void)handleFailedCommand:(id<LSCommand>)_command {
  [self logWithFormat:@"%s: command %@ failed !", __PRETTY_FUNCTION__, _command];
  if ([[self errorString] length] < 1) {
    [self setErrorString:
            [NSString stringWithFormat:@"Command %@ failed.", _command]];
  }
}

- (void)handleException:(NSException *)_exc fromCommand:(id<LSCommand>)_command {
  [self logWithFormat:
           @"command exception:\n"
           @"  name=  %@\n  reason=%@\n  info=  %@\n  command=%@",
          [_exc name], [_exc reason], [_exc userInfo],
          [_command description]];
  [self setErrorString:[NSString stringWithFormat:@"%@: %@ %@",
                                   [_command description],
                                   [_exc name], [_exc reason]]];

  if ([[[NSUserDefaults standardUserDefaults]
                        objectForKey:@"LSCoreOnCommandException"]
                        boolValue])
    abort();
}

// run

static NSNull *null = nil;

static inline NSDictionary *_vaToDict(WOComponent *self, va_list *va) {
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
  while (1);

  return result;
}

- (id)runCommand:(NSString *)_command, ... {
  va_list      va;
  NSDictionary *args = nil;
  
  va_start(va, _command);
  args = _vaToDict(self, &va);
  va_end(va);

  return [[self session] runCommand:_command arguments:args];
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
- (id)runCommandN:(NSString *)_command, ... {
  va_list      va;
  NSDictionary *args  = nil;
  id           result = nil;
  
  va_start(va, _command);
  args = _vaToDict(self, &va);
  va_end(va);
  
  [args takeValue:intObj(LSDBReturnType_ManyObjects) forKey:@"returnType"];
  result = [self runCommand:_command arguments:args];
  result = [result lastObject];
  return result;
}

- (id)runCommandInTransaction:(NSString *)_command, ... {
  va_list      va;
  NSDictionary *args = nil;
  id result;
  
  va_start(va, _command);
  args = _vaToDict(self, &va);
  va_end(va);

  result = [[self session] runCommand:_command arguments:args];
  
  if ([[self session] commit])
    return result;
  else {
    [self handleFailedTransactionCommit];
    [[self session] rollback];
    return nil;
  }
}

- (id)runCommand:(NSString *)_command object:(id)_object {
  NSDictionary *args = nil;
  NSAssert(_object != nil, @"object parameter is missing !");
  args = [NSDictionary dictionaryWithObject:_object forKey:@"object"];
  return [self runCommand:_command arguments:args];
}

- (id)runCommand:(NSString *)_command arguments:(NSDictionary *)_args {
  return [[self session] runCommand:_command arguments:_args];
}
- (id)runCommandInTransaction:(NSString *)_comm arguments:(NSDictionary *)_args {
  id result;
  
  result = [[self session] runCommand:_comm arguments:_args];
  
  if ([[self session] commit])
    return result;
  else {
    [self handleFailedTransactionCommit];
    [[self session] rollback];
    return nil;
  }
}

// Controlling transactions

- (BOOL)commit {
  return [[self session] commit];
}
- (BOOL)rollback {
  return [[self session] rollback];
}
- (BOOL)isTransactionInProgress {
  return [[self session] isTransactionInProgress];
}

- (BOOL)beginTransaction {
  [self logWithFormat:@"explicit tx begin (ignored%s) ..",
          [self isTransactionInProgress] ? ", tx is in progress" : ""];
  return YES;
}
- (BOOL)commitTransaction {
  return [[self session] commit];
}
- (BOOL)rollbackTransaction {
  return [[self session] rollback];
}

@end

void __link_WOComponent_Commands(void) {
  __link_WOComponent_Commands();
}
