/*
  Copyright (C) 2000-2003 SKYRIX Software AG

  This file is part of OGo

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
// $Id$

#include "NSObject+Commands.h"
#include "OGoSession.h"
#include <LSFoundation/LSFoundation.h>
#include "common.h"

static inline NSMutableDictionary *_vaToDict(va_list *va);

@implementation NSObject(LSWCommands)

static inline OGoSession *_getSession(void) {
  return (OGoSession *)[[WOApplication application] session];
}

- (id)run:(NSString *)_command arguments:(NSDictionary *)_args {

  if (_args) {
    NSMutableDictionary *margs;
    margs = [[_args mutableCopy] autorelease];
    [margs setObject:self forKey:@"object"];
    _args = margs;
  }
  else
    _args = [NSDictionary dictionaryWithObject:self forKey:@"object"];

  return [_getSession() runCommand:_command arguments:_args];
}

- (id)run:(NSString *)_command, ... {
  NSMutableDictionary *args = nil;
  va_list va;
  
  va_start(va, _command);
  args = _vaToDict(&va);
  va_end(va);

  if (args)
    [args setObject:self forKey:@"object"];
  else
    args = [NSDictionary dictionaryWithObject:self forKey:@"object"];
  return [_getSession() runCommand:_command arguments:args];
}

- (id)run1:(NSString *)_command, ... {
  NSMutableDictionary *args = nil;
  va_list va;
  id      result = nil;
  
  va_start(va, _command);
  args = _vaToDict(&va);
  va_end(va);

  if (args == nil)
    args = [NSMutableDictionary dictionaryWithCapacity:4];
  
  [args setObject:self forKey:@"object"];
  [args setObject:[NSNumber numberWithInt:LSDBReturnType_OneObject]
        forKey:@"returnType"];
  result = [_getSession() runCommand:_command arguments:args];
  result = [result lastObject];
  return result;
}

@end

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
  while (1);

  return result;
}
