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

#include "common.h"
#include "LSSystemCtxLogCommand.h"

@implementation LSSystemCtxLogCommand

- (void)dealloc {
  [self->keysToLog release];
  [self->out       release];
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
  id key;

  keys = [keysToLog objectEnumerator];
  [out writeString:@"logging context\n"];
  while ((key = [keys nextObject])) {
    id value = [_context valueForKey:key];

    if (value != nil) [out writeFormat:@"  %8@: %@\n", key, value];
  }
  [out writeString:@"-\n"];

}

/* accessors */

- (void)setLogStream:(id<NSObject,NGExtendedTextOutputStream>)_stream {
  ASSIGN(out, _stream);
}
- (id<NSObject,NGExtendedTextOutputStream>)logStream {
  return out;
}

- (void)setKeysToLog:(NSArray *)_keys {
  ASSIGNCOPY(keysToLog, _keys);
}
- (NSArray *)keysToLog {
  return keysToLog;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"logStream"])
    [self setLogStream:_value];
  else if ([_key isEqualToString:@"keysToLog"])
    [self setKeysToLog:_value];
  else
    [self foundInvalidSetKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"logStream"])
    return [self logStream];
  if ([_key isEqualToString:@"keysToLog"])
    return [self keysToLog];

  return nil;
}

@end /* LSSystemCtxLogCommand */
