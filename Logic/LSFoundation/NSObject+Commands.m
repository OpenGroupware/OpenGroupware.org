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

#include "NSObject+Commands.h"
#include "OGoContextSession.h"
#include "common.h"
#include <LSFoundation/LSFoundation.h>

static inline OGoContextSession *_getSession(void) {
  static Class OGoContextSessionClass = Nil;
  if (OGoContextSessionClass == Nil)
    OGoContextSessionClass = [OGoContextSession class];
  return [OGoContextSessionClass activeSession];
}

static inline NSMutableDictionary *_vaToDict(va_list *va);

@implementation NSObject(Commands)

- (id)run:(NSString *)_command
  marguments:(NSMutableDictionary *)_args
  session:(OGoContextSession *)_sn
{
  NSAssert(_sn, @"no LSOffice3 session is active for command execution");
#if DEBUG
  NSLog(@"DEPRECATED: %@, use LSCommandContext !", NSStringFromSelector(_cmd));
#endif
  [_args setObject:self forKey:@"object"];
  return [[_sn commandContext] runCommand:_command arguments:_args];
}

- (id)run:(NSString *)_command
  arguments:(NSDictionary *)_args
  session:(OGoContextSession *)_sn
{
#if DEBUG
  NSLog(@"DEPRECATED: %@, use LSCommandContext !", NSStringFromSelector(_cmd));
#endif
  return [self run:_command
               marguments:[[_args mutableCopy] autorelease]
               session:_sn];
}

@end /* NSObject(Commands) */

@implementation NSObject(SessionContext)

- (OGoContextSession *)skySession {
  return _getSession();
}
- (id)commandContext {
  return [[self skySession] commandContext];
}

@end /* NSObject(SessionContext) */

@implementation NSObject(CallCommands)

- (id)call:(NSString *)_command, ... {
  NSMutableDictionary *args = nil;
  va_list va;

#if DEBUG
  NSLog(@"DEPRECATED: %@, use LSCommandContext !", NSStringFromSelector(_cmd));
#endif
  
  va_start(va, _command);
  args = _vaToDict(&va);
  va_end(va);

  if (args)
    [args setObject:self forKey:@"object"];
  else
    args = [NSDictionary dictionaryWithObject:self forKey:@"object"];
  return [[[self skySession] commandContext] runCommand:_command arguments:args];
}

- (id)call1:(NSString *)_command, ... {
  NSMutableDictionary *args = nil;
  va_list va;
  id      result = nil;

#if DEBUG
  NSLog(@"DEPRECATED: %@, use LSCommandContext !", NSStringFromSelector(_cmd));
#endif
  
  va_start(va, _command);
  args = _vaToDict(&va);
  va_end(va);

  if (args == nil)
    args = [NSMutableDictionary dictionaryWithCapacity:4];
  
  [args setObject:self forKey:@"object"];
  [args setObject:[NSNumber numberWithInt:LSDBReturnType_OneObject]
        forKey:@"returnType"];
  result = [[[self skySession] commandContext]
                   runCommand:_command arguments:args];
  result = [result lastObject];
  return result;
}

- (id)callN:(NSString *)_command, ... {
  NSMutableDictionary *args = nil;
  va_list va;
  id      result = nil;

#if DEBUG
  NSLog(@"DEPRECATED: %@, use LSCommandContext !", NSStringFromSelector(_cmd));
#endif
  
  va_start(va, _command);
  args = _vaToDict(&va);
  va_end(va);

  if (args == nil)
    args = [NSMutableDictionary dictionaryWithCapacity:4];
  
  [args setObject:self forKey:@"object"];
  [args setObject:[NSNumber numberWithInt:LSDBReturnType_ManyObjects]
        forKey:@"returnType"];
  result = [[[self skySession] commandContext]
                   runCommand:_command arguments:args];
  result = [result lastObject];
  return result;
}

@end /* NSObject(CallCommands) */

static NSNull *null = nil;

static NSMutableDictionary *_vaToDict(va_list *va) {
  NSMutableDictionary *result = nil;
  NSString *argName = nil;
  id       argValue = nil;
  void     (*setObjForKey)(id, SEL, id, id) = NULL;

  if (va == NULL) return nil;
  if (null == nil) null = [[NSNull null] retain];

  do {
    if ((argName = va_arg(*va, NSString *)) == nil)
      // all arguments are processed
      break;

    /* replace nil argValue with NSNull, since we are going to add
       via 'setObject:' */
    if ((argValue = va_arg(*va, id)) == nil)
      argValue = null;
    
    if (result == nil) {
      result = [NSMutableDictionary dictionaryWithCapacity:64];
      setObjForKey = (void *)
        [result methodForSelector:@selector(setObject:forKey:)];
    }

    if (setObjForKey)
      setObjForKey(result, @selector(setObject:forKey:), argValue, argName);
    else
      [result setObject:argValue forKey:argName];
  }
  while (YES);

  return result;
}
