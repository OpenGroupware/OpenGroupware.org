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

#import <Foundation/NSObject.h>

/*
  ogo-acl-list

  A small sample program that fetches access control information of an object.
*/

@class NSArray;
@class OGoContextManager, LSCommandContext;

@interface ListACLs : NSObject
{
  OGoContextManager *lso;
  LSCommandContext  *ctx;
  NSString          *sxid;
  NSString          *login;
  NSString          *password;
}

+ (int)run:(NSArray *)_args;

@end

#include "common.h"
#include <LSFoundation/OGoContextManager.h>
#include <LSFoundation/OGoContextSession.h>
#include <LSFoundation/LSCommandContext.h>
#include <LSFoundation/LSCommandKeys.h>
#include <LSFoundation/LSTypeManager.h>
#include <LSFoundation/SkyAccessManager.h>

#if 0
- (id)accessIds {
  return [[[(id)[self session] commandContext] accessManager]
                      allowedOperationsForObjectId:[[self person] globalID]];
}

- (id)eoForPerson {
  return [[self runCommand:@"object::get-by-globalID",
                @"gid", [[self object] globalID], nil] lastObject];
}

- (BOOL)isEditDisabled {
  id am;
  
  am = [[[self session] valueForKey:@"commandContext"] accessManager];
  return ![am operation:@"w" 
              allowedOnObjectID:[[self object] valueForKey:@"globalID"]];
  
}
#endif

@implementation ListACLs

- (void)usage {
  NSLog(@"ogo-acl-list -login <login> -password <pwd> [object-id]+");
}

- (id)init {
  if ((self = [super init]) != nil) {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    
    if ((self->lso = [[OGoContextManager defaultManager] retain]) == nil) {
      [self errorWithFormat:@"could not create OGo context manager."];
      [self release];
      return nil;
    }
    
    self->login    = [[ud stringForKey:@"login"]     copy];
    self->password = [[ud stringForKey:@"password"]  copy];
    self->sxid     = [[ud stringForKey:@"skyrix_id"] copy];
    
    if (![self->login isNotEmpty]) {
      [self usage];
      [self release];
      return nil;
    }
  }
  return self;
}
- (void)dealloc {
  [self->sxid     release];
  [self->login    release];
  [self->password release];
  [self->lso      release];
  [super dealloc];
}

/* process */

- (NSArray *)primaryKeysForStringsAndSkipFirst:(NSArray *)_args {
  NSMutableArray *ma = nil;
  NSEnumerator   *e;
  NSString       *s;

  e = [_args objectEnumerator];
  [e nextObject]; // skip first ;-)
  while ((s = [e nextObject])) {
    NSNumber *n;
    
    n = [NSNumber numberWithUnsignedInt:[s unsignedIntValue]];
    if (ma == nil) ma = [NSMutableArray arrayWithCapacity:16];
    [ma addObject:n];
  }
  return ma;
}

- (int)run:(NSArray *)_args onContext:(LSCommandContext *)_ctx {
  id<LSTypeManager> tm;
  SkyAccessManager  *am;
  NSArray *gids, *pkeys;
  
  [self logWithFormat:@"Args: %@", _args];
  if ([_args count] < 2) {
    [self usage];
    return 1;
  }
  pkeys = [self primaryKeysForStringsAndSkipFirst:_args];
  [self logWithFormat:@"pkeys: %@", [pkeys componentsJoinedByString:@","]];
  
  /* convert primary key array into EOGlobalID array */
  
  tm = [_ctx typeManager];
  [self logWithFormat:@"type manager: %@", tm];
  gids = [tm globalIDsForPrimaryKeys:pkeys];
  [self logWithFormat:@"global-ids: %@", gids];
  
  /* 
     retrieve ACL info on the objects ...
     
     Note: this does not return implicit access rights! It only lists explicit
           ACL entries.
  */
  am = [_ctx accessManager];
  [self logWithFormat:@"allowed operations: %@", 
	  [am allowedOperationsForObjectIds:gids]];
  
  return 0;
}

- (int)run:(NSArray *)_args {
  // TODO: this is weird, the context-manager should be able to return
  //       authenticated LSCommandContext objects!
  OGoContextSession *sn;
  
  sn = [self->lso login:self->login password:self->password
                  isSessionLogEnabled:NO];
  if (sn == nil) {
    [self logWithFormat:@"could not login user '%@'", self->login];
    return 1;
  }
  ASSIGN(self->ctx, [sn commandContext]);
  
  return [self run:_args onContext:self->ctx];
}

- (BOOL)isDebuggingEnabled {
  return [[NSUserDefaults standardUserDefaults] boolForKey:@"debug"];
}

+ (int)run:(NSArray *)_args {
  return [[[[self alloc] init] autorelease] run:_args];
}

@end /* ListACLs */

int main(int argc, char **argv, char **env) {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  int rc;
#if LIB_FOUNDATION_LIBRARY
  [NSProcessInfo initializeWithArguments:argv count:argc environment:env];
#endif
  
  rc = [ListACLs run:[[NSProcessInfo processInfo] argumentsWithoutDefaults]];
  [pool release];
  return rc;
}
