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

#include "SoOGoAuthenticator.h"
#include <NGObjWeb/SoUser.h>
#include <NGObjWeb/SoPermissions.h>
#include <NGObjWeb/NSException+HTTP.h>
#include "common.h"

@interface WOApplication(UsedPrivates)
- (NSString *)locationForSessionRedirectInContext:(WOContext *)_ctx;
- (WOCookie *)expireCookieInContext:(WOContext *)_ctx;
@end

@implementation SoOGoAuthenticator

static SoUser *anonymous = nil;

+ (void)initialize {
  if (anonymous == nil) {
    NSArray *ar = [NSArray arrayWithObject:SoRole_Anonymous];
    anonymous = [[SoUser alloc] initWithLogin:@"anonymous" roles:ar];
  }
}

/* password checker (override in subclasses !) */

- (BOOL)checkLogin:(NSString *)_login password:(NSString *)_pwd {
  [self logWithFormat:@"ERROR: asked OGo authenticator to check login: '%@'",
	  _login];
  return NO;
}

/* user management */

- (SoUser *)userInContext:(WOContext *)_ctx {
  NSString   *login;
  NSArray    *uroles;
  OGoSession *sn;
  
  if (![_ctx hasSession]) {
    [self debugWithFormat:@"context has no session!"];
    return nil;
  }
  sn = [_ctx session];
  
  login = [sn activeLogin];
  if ([login length] == 0) {
    /* some error (otherwise result would have been anonymous */
    [self debugWithFormat:@"no active OGo login set in session!"];
    return nil;
  }

  [self debugWithFormat:@"get user for login: %@", login];
  
  if ([login isEqualToString:@"anonymous"])
    return anonymous;
  
  uroles = [self rolesForLogin:login];
  return [[[SoUser alloc] initWithLogin:login roles:uroles] autorelease];
}

- (NSArray *)rolesForLogin:(NSString *)_login {
  NSArray *uroles = nil;
  
  // TODO: add manager of login=root
  // TODO: add usermanager?
  [self debugWithFormat:@"check roles for login: %@", _login];
  
  uroles = [NSArray arrayWithObjects:
		      SoRole_Authenticated,
		      SoRole_Anonymous,
		    nil];
  return uroles;
}

- (NSString *)removeSessionIDFromURI:(NSString *)_uri {
  NSRange  r;
  NSString *p, *q;
  
  r = [_uri rangeOfString:@"?"];
  if (r.length == 0) return _uri;
  
  r = [_uri rangeOfString:@"wosid="];
  if (r.length == 0) return _uri;
  
  // TODO: replace is easier than parsing ...
  //       the query parsing must move to some NGExtensions NSString category
  p = [_uri substringToIndex:r.location];
  q = [_uri substringFromIndex:(r.location + r.length)];
  return [[p stringByAppendingString:@"oldwosid="] stringByAppendingString:q];
}

- (WOResponse *)unauthorized:(NSString *)_reason inContext:(WOContext *)_ctx {
  /* Note: not setting expire-cookie, should not be required */
  WOApplication *app;
  WOResponse *response;
  NSString   *jumpTo, *s;
  WOCookie   *cookie;
  
  app    = [WOApplication application];
  jumpTo = [app locationForSessionRedirectInContext:_ctx];
  
  /* add URL which triggered the issue */
  
  s      = ([jumpTo rangeOfString:@"?"].length == 0) ? @"?url=" : @"&url=";
  jumpTo = [jumpTo stringByAppendingString:s];
  s      = [self removeSessionIDFromURI:[[_ctx request] uri]];
  jumpTo = [jumpTo stringByAppendingString:[s stringByEscapingURL]];
  
  /* generate response */
  
  if ((response = [_ctx response]) == nil)
    response = [WOResponse responseWithRequest:[_ctx request]];
  
  if ((cookie = [[WOApplication application] expireCookieInContext:_ctx])!=nil)
    [response addCookie:cookie];
  
  [response setStatus:302];
  [response setHeader:jumpTo forKey:@"location"];
  [response appendContentString:@"redirecting to login page ..."];
  return response;
}

- (WOResponse *)preprocessCredentialsInContext:(WOContext *)_ctx {
  [self debugWithFormat:@"preprocess credentials in context ..."];
  
  if (![_ctx hasSession]) {
    /* no authentication provided */
    static NSArray *anon = nil;
    if (anon == nil)
      anon = [[NSArray alloc] initWithObjects:SoRole_Anonymous, nil];
    
    [_ctx setObject:anon forKey:@"SoAuthenticatedRoles"];
    [self debugWithFormat:
	    @"Login not yet authorized, session is missing in context: %@", 
	    _ctx];
    return [self unauthorized:@"missing session" inContext:_ctx];
  }
  
  return nil;
}

/* render auth exceptions of SoSecurityManager */

- (BOOL)renderException:(NSException *)_e inContext:(WOContext *)_ctx {
  WOResponse *r;
  NSString   *jumpTo;
  
  if (!([_e httpStatus] == 401 /* Not Authenticated */ || ![_ctx hasSession]))
    return NO;

  jumpTo = [[WOApplication application] 
	                   locationForSessionRedirectInContext:_ctx];
  [self debugWithFormat:@"redirect to: %@", jumpTo];
  r = [_ctx response];
  [r setStatus:302 /* redirect */];
  [r setHeader:jumpTo forKey:@"location"];
  return YES;
}

/* debugging */

- (BOOL)isDebuggingEnabled {
  return YES;
}

@end /* SoOGoAuthenticator */
