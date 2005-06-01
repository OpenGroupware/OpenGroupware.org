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

#include "SxDavAction.h"
#include "SxObject.h"
#include "common.h"

@implementation SxDavAction

- (id)initWithName:(NSString *)_name properties:(NSDictionary *)_props
  forObject:(SxObject *)_object
{
  if ((self = [super init])) {
    self->name      = [_name copy];
    self->props     = [_props retain];
    self->object    = [_object retain];
    self->keys      = [[_props allKeys] mutableCopy];
    self->changeSet = [[NSMutableDictionary alloc] init];
  }
  return self;
}

- (void)dealloc {
  [self->changeSet release];
  [self->keys   release];
  [self->object release];
  [self->name   release];
  [self->props  release];
  [super dealloc];
}

/* process */

- (BOOL)isDebugEnabled {
  return NO;
}

- (NSString *)expectedMessageClass {
  return nil;
}

- (BOOL)checkMessageClass {
  NSString *exp;
  NSString *tmp;
  
  if ((exp = [self expectedMessageClass]) == nil) {
    [self logWithFormat:@"WARNING: expectedMessageClass not specified"];
    [keys removeObject:@"outlookMessageClass"];
    return YES;
  }
  
  if ((tmp = [self->props objectForKey:@"outlookMessageClass"]) == nil)
    /* no message class transferred */
    return YES;
  
  if (![tmp isEqualToString:exp]) {
    [self logWithFormat:
            @"WARNING: got unexpected message class: %@. expected: %@",
            tmp, exp];
    [keys removeObject:@"outlookMessageClass"];
    return NO;
  }
  [keys removeObject:@"outlookMessageClass"];
  return YES;
}

- (void)logRemainingKeys {
  if ([keys count] == 0)
    return;
  
  [self logWithFormat:@"loosing keys: %@", 
          [keys componentsJoinedByString:@","]];
}

- (NSString *)createdLogText {
  return [NSString stringWithFormat:@"created by ZideStore %@ (lost=%@)",
                   [[changeSet allKeys] componentsJoinedByString:@","],
                   [keys componentsJoinedByString:@","]];
}

- (NSString *)modifiedLogText {
  return [NSString stringWithFormat:@"updated by ZideStore %@ (lost=%@)",
                   [[changeSet allKeys] componentsJoinedByString:@","],
                   [keys componentsJoinedByString:@","]];
}

- (BOOL)removeUnknownMAPIKeys {
  return YES;
}

- (NSArray *)unusedKeys {
  [self logWithFormat:@"SxDavAction: override unusedKeys in action class !"];
  return [NSArray array];
}

- (void)removeUnusedKeys {
  NSArray *remKeys;
  int max, i;
  
  remKeys = [self unusedKeys];
  max     = [remKeys count];
  
  for (i = 0; i < max; i++)
    [keys removeObject:[remKeys objectAtIndex:i]];
  
  if (![self removeUnknownMAPIKeys])
    return;
  
  /* now remove all MAPI keys (unknown values can't be processed ...) */
  max = [keys count];
  for (i = 0; i < max; i++) {
    NSString *key = [keys objectAtIndex:i];
    
    if (![key hasPrefix:@"mapiID_"])
      continue;
    
    [keys removeObjectAtIndex:i];
    max--;
    i--;
  }
}

- (NSNumber *)skyrixValueForOutlookPriority:(int)_pri {
  static NSNumber *priNormal = nil, *priHigh = nil, *priLow = nil;
  if (priNormal == nil) priNormal = [[NSNumber numberWithInt:3] retain];
  if (priHigh   == nil) priHigh   = [[NSNumber numberWithInt:2] retain];
  if (priLow    == nil) priLow    = [[NSNumber numberWithInt:4] retain];
  switch (_pri) {
  case 0: return priNormal;
  case 1: return priHigh;
  case 2: return priLow;
  default:
    [self logWithFormat:@"ERROR: unknown priority code '%i'", _pri];
    return priNormal;
  }
}

/* running */

- (NSException *)runInContext:(id)_ctx {
  [self logWithFormat:@"run not implemented !"];
  return nil;
}

@end /* SxDavAction */
