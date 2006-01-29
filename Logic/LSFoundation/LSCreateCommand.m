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

#include "LSCreateCommand.h"
#include "common.h"

id<NSObject,LSCommandFactory> commandFactory = nil;

id<LSCommand> LSCommand(NSString *_domain, NSString *_command) {
  return [commandFactory command:_command inDomain:_domain];
}

static NSNull *null = nil;

id<NSObject,LSCommand>
LSCommandAV(NSString *_domain, NSString *_command, NSString *firstKey,
            va_list va) {
  id<NSObject,LSCommand> cmd;

  if ((cmd = [commandFactory command:_command inDomain:_domain])) {
    NSString *key  = nil;

    if (null == nil) null = [[NSNull null] retain];
  
    for (key = firstKey; key; key = va_arg(va, id)) {
      id value;
      
      value = va_arg(va, id);
      if (value == null) value = nil;
      
      [cmd takeValue:value forKey:key];
      //  NSLog(@"! %@: did not take value %@ for key %@\n",
      //             cmd, value, key);
    }
  }

  return cmd;
}

id<NSObject,LSCommand>
LSCommandA(NSString *_domain, NSString *_command, NSString *firstKey, ...) {
  id<NSObject,LSCommand> cmd = nil;
  va_list va;
  
  va_start(va, firstKey);
  cmd = LSCommandAV(_domain, _command, firstKey, va);
  va_end(va);

  return cmd;
}
