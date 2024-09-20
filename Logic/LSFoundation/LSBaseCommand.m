/*
  Copyright (C) 2000-2007 SKYRIX Software AG
  Copyright (C) 2007      Helge Hess

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

#include "LSCommandFactory.h"
#include "LSBaseCommand.h"
#include "LSDBObjectCommandException.h"
#include "common.h"

static BOOL   profileCommands = NO;
static int    profileNesting = 0;
static NSNull *null = nil;

id LSCommandLookupV(id _factory, NSString *_domain, NSString *_command, ...) {
  va_list  va;
  id       command = LSCommandLookup(_factory, _domain, _command);
  NSString *parameter;
  id       value;
  
  if (command == nil) return nil;
  if (null == nil) null = [[NSNull null] retain];

  va_start(va, _command);
  do {
    parameter = va_arg(va, NSString *);
    value     = va_arg(va, id);
    
    if (parameter) {
      if (value == null) value = nil;
      [command takeValue:value forKey:parameter];
    }
    else
      break;
  }
  while (YES);
  va_end(va);

  return command;
}

id LSCommandRunV(id _ctx, id _factory, NSString *_domain, NSString *_command, ...) {
  va_list  va;
  id       command;
  NSString *parameter;
  id       value;
  
  if ((command = LSCommandLookup(_factory, _domain, _command)) == nil)
    return nil;
  
  if (null == nil) null = [[NSNull null] retain];
  
  va_start(va, _command);
  do {
    parameter = va_arg(va, NSString *);
    value     = va_arg(va, id);
    
    if (parameter) {
      if (value == null) value = nil;
      [command takeValue:value forKey:parameter];
    }
    else
      break;
  }
  while (YES);
  va_end(va);

  return [command runInContext:_ctx];
}

@interface LSBaseCommand(Misc)
- (void)logCommandDuration:(NSTimeInterval)_duration;
@end

@implementation LSBaseCommand

+ (int)version {
  return 1;
}

static BOOL debug = NO;

+ (void)setDebuggingEnabled:(BOOL)_flag {
  debug = _flag;
}
+ (BOOL)isDebuggingEnabled {
  return debug;
}

- (id)initForOperation:(NSString *)_operation inDomain:(NSString *)_domain {
  if ((self = [super init]) != nil) {
    static BOOL didInit = NO;
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    
    if (!didInit) {
      didInit = YES;
      profileCommands = [ud boolForKey:@"LSProfileCommands"];
    }
    
    self->operation = [_operation copy];
    self->domain    = [_domain    copy];
    isCommandOk = NO;
  }
  return self;
}
- (id)init {
  return [self initForOperation:nil inDomain:nil];
}

- (void)dealloc {
  [self->commands  release];
  [self->operation release];
  [self->domain    release];
  [self->object    release];
  [super dealloc];
}

/* accessors */

- (NSString *)operation {
  return self->operation; 
}

- (NSString *)domain {
  return self->domain;
}

- (NSArray *)commands {
  return self->commands;
}

- (void)setObject:(id)_object {
  ASSIGN(self->object, _object);
}
- (id)object {
  return self->object;
}

- (void)setReturnValue:(id)_value {
  ASSIGN(self->object, _value);
}
- (id)returnValue {
  return self->object;
}

- (BOOL)isCommandOk {
  return isCommandOk;
}

/* command type */

- (BOOL)requiresChannel {
  return YES;
}
- (BOOL)requiresTransaction {
  return YES;
}

/* command methods */

- (id)runInContext:(id)_context {
  NSTimeInterval start = 0.0;
    
  if (profileCommands)
    start = [[NSDate date] timeIntervalSince1970];
  profileNesting++;
  
  if (debug) {
    fprintf(stderr, "# run %s %s::%s #subcommands=%"PRIuPTR" object=%s\n",
                 [NSStringFromClass([self class]) cString],
                 [[self domain] cString], [[self operation] cString],
                 [self->commands count],
                 [[[self object] description] cString]);
  }
  self->activeContext = [[_context retain] autorelease];
  [self primaryRunInContext:activeContext];
  self->activeContext = nil;
  
  if (profileCommands) {
    NSTimeInterval end;
    end = [[NSDate date] timeIntervalSince1970];
    profileNesting--;
    [self logCommandDuration:(end - start)];
  }
  return self->object;
}

- (NSString *)callStackDescription {
  return [NSString stringWithFormat:@"%@::%@ (class=%@, self=0x%p)",
                     [self domain], [self operation],
                     NSStringFromClass([self class]), self];
}

- (void)attachCommandInfoToException:(NSException *)_exception {
#if COCOA_Foundation_LIBRARY || NeXT_Foundation_LIBRARY || GNUSTEP_BASE_LIBRARY
#if 0 // who cares ...
#  warning Note: command exception userinfo is limited on this Foundation\
                 (no NSException -setUserInfo: method available)
#endif
#else
  NSMutableDictionary *userInfo;
  NSMutableArray      *callStack = nil;
  
  userInfo  = [[_exception userInfo] mutableCopy];
  if (userInfo == nil) userInfo = [[NSMutableDictionary alloc] init];

  callStack = [[userInfo objectForKey:@"callStack"] mutableCopy];
  if (callStack == nil) callStack = [[NSMutableArray alloc] init];
  [callStack addObject:[self callStackDescription]];
  [userInfo setObject:callStack forKey:@"callStack"];
  [callStack release];
  
  [_exception setUserInfo:userInfo];
  [userInfo release]; userInfo = nil;
#endif
}

- (void)primaryRunInContext:(id)_context {
  NS_DURING {
    [self _checkPermissionInContext:_context];
    [self _prepareForExecutionInContext:_context];
    [self _executeInContext:_context];
    [self _executeCommandsInContext:_context];
    [self _validateInContext:_context];
  }
  NS_HANDLER {
    [self attachCommandInfoToException:localException];
    [localException raise];
  }
  NS_ENDHANDLER;
}

- (void)_checkPermissionInContext:(id)_context {
}

- (void)_prepareForExecutionInContext:(id)_context {
}

- (void)_executeInContext:(id)_context {
}

- (void)_executeCommandsInContext:(id)_context {
  id       oldParent  = nil;
  NSString *parentKey = nil;
    
  oldParent = [_context valueForKey:LSParentCommandKey];
  parentKey = LSParentCommandKey; // needed in exception handler
  [_context takeValue:self forKey:LSParentCommandKey];

  NS_DURING {
    id<NSObject,LSCommand> command = nil;
    NSEnumerator *cmds = [self->commands objectEnumerator];

    while ((command = [cmds nextObject]))
      [command runInContext:_context];
  }
  NS_HANDLER {
    [_context takeValue:(oldParent ? oldParent : (id)[NSNull null])
              forKey:parentKey];
    [localException raise];
  }
  NS_ENDHANDLER;

  [_context takeValue:(oldParent ? oldParent : (id)[NSNull null])
            forKey:parentKey];
}

- (void)_validateInContext:(id)_context {
}

/* context functions */

- (id<NSObject,LSCommandFactory>)commandFactory {
  NSAssert((self->activeContext != nil),
           @"! LSBaseCommand(commandFactory): no context yet !\n");

  return [self->activeContext valueForKey:LSCommandFactoryKey];
}

/* logging */

- (void)logCommandDuration:(NSTimeInterval)_duration {
  int i;
  for (i = 0; i < profileNesting; i++)
    fprintf(stderr, "  ");
  fprintf(stderr,
          "%.3fs %s::%s\n", _duration,
          [[self domain]    cString],
          [[self operation] cString]);
}

- (void)logWithFormat:(NSString *)_format, ... {
  NSString *value = nil;
  va_list  ap;

  va_start(ap, _format);
  value = [[NSString alloc] initWithFormat:_format arguments:ap];
  va_end(ap);
  
  NSLog(@"[%@::%@] %@", [self domain], [self operation], value);
  [value release];
}
- (void)debugWithFormat:(NSString *)_format, ... {
  NSString *value = nil;
  va_list  ap;

  va_start(ap, _format);
  value = [[NSString alloc] initWithFormat:_format arguments:ap];
  va_end(ap);

  NSLog(@"<%@::%@> %@", [self domain], [self operation], value);
  [value release];
}

/* assertions */

- (void)assert:(BOOL)_condition reason:(NSString *)_reason {
  _reason = [NSString stringWithFormat:@"%@::%@ failed: %@",
                        [self domain], [self operation], _reason];
  [LSDBObjectCommandException raiseOnFail:_condition
                              object:self
                              reason:_reason];
}

- (void)assert:(BOOL)_condition {
  // raises with sybaseMessages
  [self assert:_condition reason:@"assertion failed."];
}

#if USE_VA_LIST_PTR
- (void)assert:(BOOL)_condition format:(NSString *)_fmt 
  arguments:(va_list *)_ap 
#else
- (void)assert:(BOOL)_condition format:(NSString *)_fmt arguments:(va_list)_ap 
#endif
{
  NSString *s;

  if (_condition) return;
#if USE_VA_LIST_PTR
  s = [[NSString alloc] initWithFormat:_fmt arguments:*_ap];
#else
  s = [[NSString alloc] initWithFormat:_fmt arguments:_ap];
#endif
  s = [s autorelease];
  [self assert:_condition reason:s];
}
- (void)assert:(BOOL)_condition format:(NSString *)_fmt, ... {
  if (!_condition) {
#if USE_VA_LIST_PTR
    va_list *ap;
    *(&ap) = NULL;
#else
    va_list ap; // on gcc 3.3 "volatile" isn't allowed ?!
#endif
    
    va_start(ap, _fmt);
#if MAC_OS_X_VERSION_MAX_ALLOWED >= 1050
    [self assert:_condition format:_fmt arguments:ap];
    // TBD: do we leak here if we have an exception?
#else
    NS_DURING {
      [self assert:_condition format:_fmt arguments:ap];
    }
    NS_HANDLER {
      va_end(ap);
      [localException raise];
    }
    NS_ENDHANDLER;
#endif
    va_end(ap);
  }
}

/* description */

- (NSString *)description {
  return [NSString stringWithFormat:
                     @"<Command: domain=%@ operation=%@ hasSubCommands=%s>",
                     self->domain, self->operation,
                     [self->commands count] > 0 ? "YES" : "NO"
                   ];
}

/* key/value coding */

- (BOOL)foundInvalidSetKey:(NSString *)_key {
  NSString *r;
  
  r = [NSString stringWithFormat:
                  @"key: %@ is not valid in domain '%@' for operation '%@'.",
                  _key, [self domain], [self operation]];
  [LSDBObjectCommandException raiseOnFail:NO object:self
                              reason:r];
  return NO;
}
- (id)foundInvalidGetKey:(NSString *)_key {
  return nil;
}

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"object"])
    [self setObject:_value];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"object"])
    return [self object];
  return nil;
}

- (void)takeValuesFromDictionary:(NSDictionary *)_dict {
  /* optimize method calls */
  NSEnumerator *keys;
  NSString     *key;
  
  keys = [_dict keyEnumerator];
  while ((key = [keys nextObject]))
    [self takeValue:[_dict objectForKey:key] forKey:key];
}

@end /* LSBaseCommand */
