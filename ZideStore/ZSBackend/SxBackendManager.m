/*
  Copyright (C) 2002-2004 SKYRIX Software AG

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

#include "SxBackendManager.h"
#include "SxSetCacheManager.h"
#include "common.h"
#include <EOControl/EOControl.h>

@interface NSObject(GID)
- (EOGlobalID *)globalID;
@end

@implementation SxBackendManager

static NSArray *accountKeys = nil;

+ (void)initialize {
  if (accountKeys == nil) {
    accountKeys = [[NSArray alloc] initWithObjects:
                         @"companyId", @"globalID",
                         @"firstname", @"middlename",
                         @"login", @"name",
                         @"email1",
                         @"isPerson", @"isAccount",
                         nil];
  }
}

+ (id)managerWithContext:(LSCommandContext *)_ctx {
  return [[(SxBackendManager *)[self alloc] initWithContext:_ctx] autorelease];
}
- (id)initWithContext:(LSCommandContext *)_ctx {
  if (_ctx == nil) {
    [self logWithFormat:@"ERROR: could not create backend manager, "
            @"missing OGo command context object!"];
    [self release];
    return nil;
  }
  if ((self = [super init])) {
    self->cmdctx = _ctx;
  }
  return self;
}
- (void)dealloc {
  [super dealloc];
}

/* accessors */

- (LSCommandContext *)commandContext {
  return self->cmdctx;
}

- (NSString *)modelName {
  static NSString *modelName = nil;
  if (modelName == nil) {
    modelName = [[[NSUserDefaults standardUserDefaults]
		   stringForKey:@"LSModelName"] copy];
  }
  return modelName;
}

/* transaction support */

- (BOOL)isTransactionInProgress {
  return [self->cmdctx isTransactionInProgress];
}

- (BOOL)commit {
  if (![self->cmdctx isTransactionInProgress])
    return YES;
  return [self->cmdctx commit];
}

- (BOOL)rollback {
  if (![self->cmdctx isTransactionInProgress])
    return YES;
  return [self->cmdctx rollback];
}

/* common */

- (EOKeyGlobalID *)globalIDForLoginAccount {
  EOKeyGlobalID *gid;
  
  gid = (id)[[[self commandContext] valueForKey:LSAccountKey] globalID];
  return gid;
}

- (EOKeyGlobalID *)globalIDForGroupWithPrimaryKey:(NSNumber *)_group {
  id gid;

  gid = [EOKeyGlobalID globalIDWithEntityName:@"Date"
			 keys:&_group keyCount:1
			 zone:NULL];
  return gid;
}

- (EOKeyGlobalID *)globalIDForGroupWithName:(NSString *)_group {
  id groups, group;
  
  if ([_group length] == 0)
    return nil;  
  
  groups = [self->cmdctx runCommand:@"team::get-by-login",
		@"login", _group, nil];
  
  if ([groups isKindOfClass:[NSArray class]]) {
    group = [groups objectAtIndex:0];
    [self logWithFormat:@"found no group named '%@'", _group];
    return nil;
  }
  else
    group = groups;
  return (id)[group globalID];
}

- (id)accountForGlobalID:(EOGlobalID *)_gid {
  // TODO: expiration timer for account cache
  static NSDictionary *accountInfo = nil;
  static NSNumber *manyObjs = nil;
  NSMutableDictionary *md;
  NSEnumerator        *allE;
  id                  one, gid;
  
  if (_gid == nil)
    return nil;
  if (accountInfo)
    return [accountInfo objectForKey:_gid];
  
  if (manyObjs == nil) 
    manyObjs = [[NSNumber numberWithInt:LSDBReturnType_ManyObjects] retain];
  
  allE = [[[self commandContext] 
                 runCommand:@"account::get", @"returnType", manyObjs, nil]
                 objectEnumerator];
  
  md = [[NSMutableDictionary alloc] initWithCapacity:32];
  
  while ((one = [allE nextObject])) {
    gid = [one globalID];
    if (gid != nil) {
      one = [one valuesForKeys:accountKeys];
      [one setObject:gid forKey:@"globalID"];
      [md setObject:one forKey:gid];
    }
  }
  accountInfo = [md copy];
  [md release];
  
  return [accountInfo objectForKey:_gid];
}

@end /* SxBackendManager */
