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

#include "DirectAction.h"
#include <LSFoundation/OGoContextManager.h>
#include "OpenGroupware.h"
#include "common.h"

@interface WODirectAction(LoginAction)

- (id<WOActionResults>)loginActionWithLogin:(NSString *)login
  password:(NSString *)pwd
  request:(WORequest *)req;

@end

@implementation DirectAction

static NGMimeType *textPlainType = nil;
static NGMimeType *textHtmlType  = nil;

+ (void)initialize {
  if (textPlainType == nil)
    textPlainType = [[NGMimeType mimeType:@"text/plain"] retain];
  if (textHtmlType == nil)
    textHtmlType = [[NGMimeType mimeType:@"text/html"] retain];
}

- (NSString *)rootLogin {
  static NSString *rootLogin = nil;
  if (rootLogin == nil) {
    id lso = [(OpenGroupware *)[WOApplication application] lsoServer];
    rootLogin = [lso loginOfRoot];
    if (rootLogin == nil) rootLogin = @"root";
    rootLogin = [rootLogin retain];
  }
  return rootLogin;
}

/* accessors */

- (void)setPkey:(int)_key {
  self->pkey = _key;
}
- (int)pkey {
  return self->pkey;
}

/* actions */

- (id<WOActionResults>)logoutAction {
  [[self existingSession] terminate];
  return [self pageWithName:@"OGoLogoutPage"];
}

- (id<WOActionResults>)_vti_rpcAction {
  WOResponse *r;
  NSString *s;
  NSEnumerator *headerKeys;
  NSString *vtiMethod;

  vtiMethod = [[self request] formValueForKey:@"method"];
  
  [self logWithFormat:@"vti rpc was requested."];
#if DEBUG
  [self logWithFormat:@"  vti-method: %@", vtiMethod];
  [self logWithFormat:@"  request:    %@", [self request]];
  headerKeys = [[[self request] headerKeys] objectEnumerator];
  while ((s = [headerKeys nextObject]) != nil) {
    [self debugWithFormat:@"  header %@: %@",
            s,
            [[self request] headerForKey:s]];
  }

  headerKeys = [[[self request] formValueKeys] objectEnumerator];
  while ((s = [headerKeys nextObject]) != nil) {
    [self debugWithFormat:@"  form   %@: %@",
            s,
            [[self request] formValueForKey:s]];
  }
#endif
  r = [[[WOResponse alloc] init] autorelease];
  [r setStatus:404];
  [r setHTTPVersion:@"1.0"];
  [r appendContentString:@"vti rpc not supported."];
  return r;
}

- (id<WOActionResults>)defaultAction {
  WOSession *session;
  
  if ((session = [self existingSession]) != nil) {
    WOComponent *page;
    
    [self logWithFormat:@"triggered default action, session available .."];
    
    if ((page = [[session navigation] activePage]))
      return page;
    
    [self logWithFormat:@"  no active page, jump to Main."];
  }
  
  [self logWithFormat:@"default direct action (return Main ..) .."];
  
  return [self pageWithName:@"Main"];
}

- (id<WOActionResults>)performActionNamed:(NSString *)_actionName {
  /* this one basically ensures that access to da's is protected */
  OGoContextManager   *lso;
  WOSession *sn;
  
#if 0 /* enable this if you want to logout even if no session was active */
  if ([_actionName isEqualToString:@"logout"])
    return [self logoutAction];
#endif
  
  [self debugWithFormat:@"perform action: %@", _actionName];
  
  /* run all actions if we have a session */
  
  if ((sn = [self existingSession]) != nil) {
    id<WOActionResults> result;
    
    if ((result = [super performActionNamed:_actionName]) == nil)
      result = [self defaultAction];

    return result;
  }
  
  /* some actions with special treatment */
  
  if ([_actionName isEqualToString:@"login"]) 
    return [super performActionNamed:@"login"];
  
  if ([_actionName isEqualToString:@"_vti_rpc"])
    return [super performActionNamed:@"_vti_rpc"];
  
  /* automatic login if 'root' has no password */
  
  lso  = [(OpenGroupware *)[WOApplication application] lsoServer];
  if ([lso isLoginAuthorized:[self rootLogin] password:@""]) {
    return [self loginActionWithLogin:[self rootLogin] password:@""
		 request:[self request]];
  }
  
  /* show main page when we have no session */
  
  // TODO: should perform redirect?
  return [self pageWithName:@"Main"];
}

@end /* DirectAction */
