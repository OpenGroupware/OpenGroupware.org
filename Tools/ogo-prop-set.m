/*
  Copyright (C) 2000-2006 SKYRIX Software AG

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
  ogo-prop-set
  
  A small sample program that sets a property for a given object id.
*/

@class NSArray;
@class OGoContextManager, LSCommandContext;

@interface SetProp : NSObject
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
#include <LSFoundation/SkyObjectPropertyManager.h>

@implementation SetProp

- (void)usage {
  NSLog(@"ogo-prop-set -login <login> -password <pwd> <propname> <propval> "
	@"<object-id>");
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

- (int)run:(NSArray *)_args onContext:(LSCommandContext *)_ctx {
  SkyObjectPropertyManager *pm;
  NSDictionary *propDict;
  EOGlobalID   *gid;
  NSString     *propName, *propValue;
  NSNumber     *pkey;
  NSException  *error;
  
  if ([_args count] < 4) {
    [self usage];
    return 1;
  }

  propName  = [_args objectAtIndex:1];
  propValue = [_args objectAtIndex:2];
  pkey      = [NSNumber numberWithInt:[[_args objectAtIndex:3] intValue]];
  
  /* convert primary key array into EOGlobalID array */
  
  gid = [[_ctx typeManager] globalIDForPrimaryKey:pkey];
  [self logWithFormat:@"global-id: %@", gid];
  if (gid == nil) {
    [self errorWithFormat:@"did not find gid for primary key: %@", pkey];
    return 2;
  }
  
  /* first retrieve properties, then set properties */

  pm = [_ctx propertyManager];
  
  if ((propDict = [pm propertiesForGlobalID:gid]) != nil) {
    NSMutableDictionary *md;
    
    md = [propDict mutableCopy];
    [md takeValue:propValue forKey:propName];
    propDict = [[md copy] autorelease];
    [md release];
  }
  else /* object had no properties */
    propDict  = [NSDictionary dictionaryWithObject:propValue forKey:propName];
  
  if ((error = [pm takeProperties:propDict globalID:gid]) != nil) {
    [self errorWithFormat:@"failed: %@", error];
    return 5;
  }
  
  if ([_ctx isTransactionInProgress]) {
    if (![_ctx commit]) {
      [self errorWithFormat:@"failed to commit changed to database!"];
      return 3;
    }
  }

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

@end /* SetProp */

int main(int argc, char **argv, char **env) {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  int rc;
#if LIB_FOUNDATION_LIBRARY
  [NSProcessInfo initializeWithArguments:argv count:argc environment:env];
#endif
  
  rc = [SetProp run:[[NSProcessInfo processInfo] argumentsWithoutDefaults]];
  [pool release];
  return rc;
}
