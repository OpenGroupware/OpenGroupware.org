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
// $Id: SxAuthenticator.m 1 2004-08-20 11:17:52Z znek $

#include "SxAuthenticator.h"
#include "common.h"
#include <LSFoundation/OGoContextManager.h>
#include <LSFoundation/LSCommandContext.h>

@implementation SxAuthenticator

static int debugOn = 0;

+ (void)initialize {
  static BOOL didInit = NO;
  if (!didInit) {
    didInit = YES;
    NSAssert2([super version] == 1,
	      @"invalid superclass (%@) version %i !",
	      NSStringFromClass([self superclass]), [super version]);
    debugOn = [[NSUserDefaults standardUserDefaults]
                               boolForKey:@"SxDebugAuthenticator"];
  }
}

+ (id)sharedAuthenticator {
  static SxAuthenticator *auth = nil; // THREAD
  if (auth == nil) auth = [[self alloc] init];
  return auth;
}

- (id)init {
  if ((self = [super init])) {
    
    if ((self->lso = [[OGoContextManager defaultManager] retain]) == nil) {
      [self release];
      return nil;
    }
    self->managerStore = [[NSMutableDictionary alloc] init];
    
    self->credToContext = [[NSMutableDictionary alloc] init];
  }
  return self;
}
- (void)dealloc {
  [self->credToContext release];
  [self->lso           release];
  [self->managerStore  release];
  [super dealloc];
}

/* authentication */

- (NSMutableDictionary *)managerStore {
  return self->managerStore;
}

- (NSString *)authRealm {
  return @"OpenGroupware.org";
}

- (BOOL)_checkLogin:(NSString *)_login password:(NSString *)_pwd {
  BOOL ok;
  
  [self debugWithFormat:@"authenticate: %@ (%@)", _login,
        _pwd ? ([_pwd length] > 0 ? @"has pwd" : @"empty pwd") : @"no pwd"];
  ok = [self->lso isLoginAuthorized:_login password:_pwd];
  
  if (ok) {
    [self debugWithFormat:@"  authenticated."];
  }
  else {
    [self logWithFormat:@"failed to authenticate: %@.", _login];
    if ([self cantConnectToDatabase])
      [self logWithFormat:@"  cannot connect to database!"];
  }
  return ok;
}
- (BOOL)checkLogin:(NSString *)_login password:(NSString *)_pwd {
  int activeUsers;
  
  activeUsers = [self->credToContext count];
  
  if (activeUsers > 0 && _login != nil && _pwd != nil) {
    /* look in cache */
    NSArray *creds;

    creds = [NSArray arrayWithObjects:_login, _pwd, nil];
    if ([self->credToContext objectForKey:creds]) {
      if (debugOn) {
        [self debugWithFormat:@"authenticated from cache (%i users active).",
                activeUsers];
      }
      return YES;
    }
  }
  
  /* the user is not cached */
  
  if (![self _checkLogin:_login password:_pwd])
    /* not authenticated */
    return NO;
  
  return YES;
}

/* SKYRiX setup queries */

- (BOOL)cantConnectToDatabase {
  return ![self->lso canConnectToDatabase];
}

/* skyrix context cache */

- (void)flushContextForLogin:(NSString *)_login {
  NSEnumerator *e;
  NSArray      *cred;
  
  e = [self->credToContext keyEnumerator];
  while ((cred = [e nextObject])) {
    if (![[cred objectAtIndex:0] isEqualToString:_login])
      continue;
    
    [self flushContextForCredentials:cred];
  }
}

- (void)flushContextForCredentials:(NSArray *)_creds {
  [self->credToContext removeObjectForKey:_creds];
}

- (LSCommandContext *)contextForCredentials:(NSArray *)_creds 
  inContext:(WOContext *)_ctx 
{
  LSCommandContext *context = nil;
  int activeUsers;
  BOOL ok;

  activeUsers = [self->credToContext count];
  
  if ((context = [self->credToContext objectForKey:_creds]) != nil) {
    /* found in cache ... */
    [self debugWithFormat:
            @"found context for credentials in cache (%i users active).",
            activeUsers];
    return context;
  }
  
  if ([_creds count] < 2) {
    [self logWithFormat:@"got passed invalid credentials !"];
    return nil;
  }
  
  [self debugWithFormat:@"check login '%@' ...", [_creds objectAtIndex:0]];
  ok = [self _checkLogin:[_creds objectAtIndex:0] 
             password:[_creds objectAtIndex:1]];
  if (!ok)
    return nil;
  
  context =
    [[[LSCommandContext alloc] initWithManager:self->lso] autorelease];
  
  ok = [context login:[_creds objectAtIndex:0]
		password:[_creds objectAtIndex:1] 
		isSessionLogEnabled:NO];
  if (!ok) {
    [self logWithFormat:@"ERROR: couldn't login into context (user=%@) !",
	    [_creds objectAtIndex:0]];
    [[[context valueForKey:LSDatabaseChannelKey]
               adaptorChannel] closeChannel];
    return nil;
  }
  
  [self->credToContext setObject:context forKey:_creds];
  return context;
}

- (NSArray *)credentialsInContext:(WOContext *)_ctx {
  WORequest *rq;
  NSString  *auth;
  NSArray   *creds;
  
  rq = [_ctx request];
  if ((auth = [rq headerForKey:@"authorization"]) == nil) {
    if (![rq isSoWCAPRequest]) {
      /* no auth supplied */
      if (debugOn) [self debugWithFormat:@"got no credentials ..."];
      return nil;
    }
  }
  
  if ([rq isSoWCAPRequest]) { /* WCAP authentication by session-token */
    id       sn, user;
    NSString *pwd;
    
    sn   = [_ctx hasSession] ? [_ctx session] : nil;
    user = [sn valueForKey:@"SoUser"];
    user = [[user login] stringValue];
    if (user == nil) {
      if (sn)
        [sn logWithFormat:@"WARNING: no user for WCAP authentication !"];
      else
        [self logWithFormat:@"WARNING: no WCAP session is active !"];
      return nil;
    }
    
    pwd = [[sn valueForKey:@"WCAPPassword"] stringValue];
    if (pwd == nil) pwd = @"";
    
    creds = [NSArray arrayWithObjects:user, pwd, nil];
  }
  else if ((creds = [self parseCredentials:auth]) == nil) {
    [self logWithFormat:@"WARNING: could not parse HTTP credentials (%@) !", 
            auth];
    return nil;
  }
  return creds;
}

- (NSString *)checkCredentialsInContext:(WOContext *)_ctx {
  NSArray *creds;
  
  if ((creds = [self credentialsInContext:_ctx]) == nil)
    return nil;

  if (![self checkLogin:[creds objectAtIndex:0] 
             password:[creds objectAtIndex:1]])
    return nil;
  
  return [creds objectAtIndex:0];
}

- (LSCommandContext *)commandContextInContext:(WOContext *)_ctx {
  NSArray *creds;
  
  /* check whether ctx has a session */
  if ([_ctx hasSession]) {
    id cmdctx;
    id sn;
    
    sn = [_ctx session];
    if ((cmdctx = [sn valueForKey:@"commandContext"]))
      /* reuse cmdctx from session ... */
      return cmdctx;
  }
  
  if ((creds = [self credentialsInContext:_ctx]) == nil) {
    [self debugWithFormat:@"could not parse credentials in ctx ..."];
    return nil;
  }
  
  return [self contextForCredentials:creds inContext:_ctx];
}


/* debugging */

- (BOOL)isDebuggingEnabled {
  return debugOn ? YES : NO;
}

@end /* SxAuthenticator */
