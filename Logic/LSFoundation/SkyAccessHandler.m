/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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
// $Id$

#include <LSFoundation/SkyAccessHandler.h>
#include "common.h"
#include <LSFoundation/LSCommandContext.h>
#include <LSFoundation/SkyAccessManager.h>

@interface SkyAccessHandler(Internals)
- (BOOL)_checkGIDs:(NSArray *)_ids;
- (NSArray *)_entityNames;
@end /* SkyAccessHandler(Internals) */

@interface NSObject(Private)
- (SkyAccessManager *)accessManager;
@end
@implementation SkyAccessHandler

static BOOL debugOn = NO;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  debugOn = [ud boolForKey:@"SkyAccessManagerDebug"];
}

+ (id)accessHandlerWithContext:(id)_ctx {
  if (_ctx == nil) {
    NSLog(@"ERROR(%s): could not create handler due to invalid context!",_ctx);
    return nil;
  }
  return [[[self alloc] initWithContext:_ctx] autorelease];
}

- (id)initWithContext:(LSCommandContext *)_ctx {
  if (_ctx == nil) {
    [self logWithFormat:
	    @"ERROR(%s): could not create handler due to a missing context!",
	    __PRETTY_FUNCTION__, _ctx];
    [self release];
    return nil;
  }
  if ((self = [super init])) {
    self->context = [_ctx retain]; // does this produce a cycle?
  }
  return self;
}

- (void)dealloc {
  [self->context release];
  [super dealloc];
}

/* access manager */

- (SkyAccessManager *)accessManager {
  return [[self context] accessManager];
}
- (NSMutableDictionary *)accessManagerCache {
  return [[self accessManager] objectId2AccessCache];
}

/* operations */

- (void)cacheOperation:(NSString *)_str for:(NSNumber *)_id {
  [[self accessManagerCache] setObject:_str forKey:_id];
}

- (BOOL)operation:(NSString *)_operation
  allowedOnObjectIDs:(NSArray *)_oids
  forAccessGlobalID:(EOGlobalID *)_accessGID
{
  if (debugOn) {
    [self debugWithFormat:
	    @"%s: subclass does not override this method "
	    @"(op=%@, oids=%@, principal=%@) => NO",
	    __PRETTY_FUNCTION__, _operation, _oids, _accessGID];
  }
  return NO;
}

- (NSArray *)objects:(NSArray *)_oids
  forOperation:(NSString *)_str
  forAccessGlobalID:(EOGlobalID *)_pgid
{
  NSMutableArray *a;
  NSEnumerator   *enumerator;
  id             obj;

  if (debugOn) {
    [self debugWithFormat:
	    @"%s: subclass does not override this method - inefficient!",
	    __PRETTY_FUNCTION__];
  }
  
  a          = [NSMutableArray array];
  enumerator = [_oids objectEnumerator];

  while ((obj = [enumerator nextObject])) {
    NSArray *oids;
    
    oids = [NSArray arrayWithObject:obj];
    if (![self operation:_str allowedOnObjectIDs:oids forAccessGlobalID:_pgid])
      continue;
    
    [a addObject:obj];
  }
  return a;
}

/* accessors */

- (LSCommandContext *)context {
  return self->context;
}

/* operations */

- (BOOL)_checkGIDs:(NSArray *)_ids {
  NSEnumerator *enumerator;
  id           gid;

  if (debugOn) 
    [self debugWithFormat:@"%s: %@", __PRETTY_FUNCTION__, _ids];
  
  enumerator = [_ids objectEnumerator];
  while ((gid = [enumerator nextObject])) {
    if (![gid isKindOfClass:[EOKeyGlobalID class]]) {
      [self logWithFormat:@"ERROR[%s]: wrong gid %@ for accessHandler %@",
            __PRETTY_FUNCTION__, gid, self];
      return NO;
    }
    if (![[self _entityNames] containsObject:[gid entityName]]) {
      [self logWithFormat:
	      @"ERROR[%s]: wrong entity in gid %@ for accessHandler %@",
              __PRETTY_FUNCTION__, gid, self];
      return NO;
    }
  }
  return YES;
}

- (NSArray *)_entityNames {
  if (debugOn) {
    [self debugWithFormat:@"%s: should be overridden by subclass!",
	    __PRETTY_FUNCTION__];
  }
  return nil;
}

/* debugging */

- (BOOL)isDebuggingEnabled {
  return debugOn;
}

@end /* SkyAccessHandler(Internals) */
