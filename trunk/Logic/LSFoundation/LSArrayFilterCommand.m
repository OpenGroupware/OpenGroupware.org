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

#include "LSArrayFilterCommand.h"
#include "common.h"

@implementation LSArrayFilterCommand

- (void)dealloc {
  [self->removeFromSource release];
  [super dealloc];
}

/* command type */

- (BOOL)requiresChannel {
  return NO;
}
- (BOOL)requiresTransaction {
  return NO;
}

/* execution */

- (BOOL)includeObjectInResult:(id)_object {
  [self logWithFormat:@"ERROR(%s): subclass should override this method!",
	  __PRETTY_FUNCTION__];
  return NO;
}
- (BOOL)includeObjectInResult:(id)_object replacementObject:(id *)_newObject {
  *_newObject = nil;
  return [self includeObjectInResult:_object];
}

- (void)_executeInContext:(id)_context {
  NSEnumerator   *source    = [[self object] objectEnumerator];
  NSMutableArray *result    = nil;
  id             obj        = nil;
  BOOL           doRemove   = [self->removeFromSource boolValue];
  int            cnt        = 0;
  NSMutableArray *removeIdx = nil;

  if (source == nil) return;

  if (doRemove) removeIdx = [NSMutableArray arrayWithCapacity:64];

  while ((obj = [source nextObject])) {
    id replacement = nil;
    
    if ([self includeObjectInResult:obj replacementObject:&replacement]) {
      if (result == nil)
        result = [[NSMutableArray allocWithZone:[source zone]] init];

      [result addObject:replacement ? replacement : obj];
      if (doRemove) [removeIdx addObject:[NSNumber numberWithUnsignedInt:cnt]];
    }
    cnt++;
  }

  if (doRemove) {
    NSMutableArray *sourceArray = [self object];
    int count = [removeIdx count];

    for (cnt = 0; cnt < count; cnt++)
      [sourceArray removeObjectAtIndex:[[removeIdx objectAtIndex:cnt] intValue]];
  }

  if (result) {
    [self setReturnValue:result];
    [result release]; result = nil;
  }
  else
    [self setReturnValue:[NSArray array]];
}

/* accessors */

- (void)setRemoveFromSource:(NSNumber *)_flag {
  ASSIGN(self->removeFromSource, _flag);
}
- (NSNumber *)removeFromSource {
  return self->removeFromSource;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"removeFromSource"])
    [self setRemoveFromSource:_value];
  else
    [self foundInvalidSetKey:_key];
}
- (id)valueForKey:(id)_key {
  return ([_key isEqualToString:@"removeFromSource"])
    ? [self removeFromSource]
    : [self foundInvalidGetKey:_key];
}

@end /* LSArrayFilterCommand */
