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

#include "Main.h"
#include "common.h"
#include <LSFoundation/OGoContextSession.h>
#include <LSFoundation/OGoContextManager.h>
#include <NGObjWeb/WEClientCapabilities.h>

@interface Main(PrivateMethods)
- (id)login;
- (BOOL)isSkyrixUp;

- (void)setUser:(NSString *)_user;
- (NSString *)user;
- (void)setPassword:(NSString *)_pwd;
@end

@interface WOApplication(OGoApp)
- (id)lsoServer; // TODO: proper return type
@end

@implementation Main 

static int  LSLoginPageExpireTimeout = 300;
static BOOL LSUseBasicAuth           = NO;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

  LSLoginPageExpireTimeout = 
    [[ud objectForKey:@"LSLoginPageExpireTimeout"] intValue];
  LSUseBasicAuth = [ud boolForKey:@"LSUseBasicAuthentication"];
}

- (void)dealloc {
  [self->directAction       release];
  [self->directActionObject release];
  [self->user               release];
  [self->password           release];
  [self->restorePageName    release];
  [self->restoreParameters  release];
  [self->item               release];
  [self->loginName          release];
  [self->restorePageLabel   release];
  
  [super dealloc];
}

/* URLs */

- (NSString *)urlForResourceNamed:(NSString *)_name {
  WOResourceManager *rm;
  NSString *url;
  NSArray  *langs;
  
  langs = [self hasSession]
    ? [[self session] languages]
    : [[[self context] request] browserLanguages];
  
  rm = [self resourceManager];
  url = [rm urlForResourceNamed:_name inFramework:nil
	    languages:langs request:[[self context] request]];
  return url;
}
- (NSString *)stylesheetURL {
  return [self urlForResourceNamed:@"OGo.css"];
}

/* accessors */

- (NSString *)rootLogin {
  static NSString *rootLogin = nil;
  if (rootLogin == nil) {
    id lso;

    lso = [[WOApplication application] lsoServer];
    rootLogin = [lso loginOfRoot];
    if (rootLogin == nil) rootLogin = @"root";
    rootLogin = [rootLogin retain];
  }
  return rootLogin;
}

- (NSString *)cycleId {
  return [NSString stringWithFormat:@"%d",
                     (unsigned)[[NSDate date] timeIntervalSince1970]];
}

- (id)invokeActionForFirstRequest:(WORequest *)_request
  inContext:(WOContext *)_ctx
{
  id lso;

  lso  = [[WOApplication application] lsoServer];
  
  if ([lso isLoginAuthorized:[self rootLogin] password:@""])
    return [self login];
  
  return nil;
}

- (id)invokeActionForExpiredRequest:(WORequest *)_request
  inContext:(WOContext *)_ctx
{
  id lso;

  lso  = [[WOApplication application] lsoServer];
  
  if ([lso isLoginAuthorized:[self rootLogin] password:@""])
    return  [[[self session] navigation] activePage];
  
  return nil;
}

- (void)sleep {
  if (![self isSkyrixUp]) {
    if ([self hasSession])
      [[self session] terminate];
  }
  [super sleep];
}

/* response generation */

- (void)_setAuthRequiredInResponse:(WOResponse *)_response {
  [_response setStatus:401 /* Auth Required */];
  [_response setHeader:@"basic realm=\"OpenGroupware\""
	     forKey:@"www-authenticate"];
}

- (BOOL)_basicAuthWithResponse:(WOResponse *)_r inContext:(WOContext *)_ctx {
  NSString *auth;
  id lso;
  
  if (!LSUseBasicAuth)
    return YES;

  if ((auth = [[_ctx request] headerForKey:@"authorization"]) != nil) {
    NSRange r;
    
    r = [auth rangeOfString:@" " options:NSBackwardsSearch];
    if (r.length == 0)
      return NO; /* abort */
    
    auth = [auth substringFromIndex:(r.location + r.length)];
    auth = [auth stringByDecodingBase64];
  }
  if (auth != nil) {
    NSRange r;
    
    r = [auth rangeOfString:@":"];
    auth = (r.length > 0)
      ? [auth substringFromIndex:(r.location + r.length)]
      : nil;
  }
        
  if ([auth length] == 0)
    return NO;
  
  lso = [[WOApplication application] lsoServer];
  if (![lso isLoginAuthorized:[self user] password:auth])
    return NO;

  [self setPassword:auth];
  [self takeValue:[NSNumber numberWithBool:YES] forKey:@"autologin"];
  return YES;
}

- (BOOL)_userAuthWithResponse:(WOResponse *)_r inContext:(WOContext *)_ctx {
  NSString *authType;
  NSString *authUser;

  if ([self->user length] > 0)
    return YES;
  
  authType = [[_ctx request] headerForKey:@"x-webobjects-auth-type"];
  authUser = [[authType lowercaseString] isEqualToString:@"basic"]
    ? [[_ctx request] headerForKey:@"x-webobjects-remote-user"]
    : nil;
  
  if ([authUser length] > 0) {
    [self setUser:authUser];
    
    if (LSUseBasicAuth)
      [self _basicAuthWithResponse:_r inContext:_ctx];
  }
  else if (LSUseBasicAuth) { /* basic-auth is on, but no 'remote user' */
    [self _setAuthRequiredInResponse:_r];
    return NO;
  }
  return YES;
}

- (void)appendMissingContentErrorToResponse:(WOResponse *)_response {
  [_response appendContentString:@"<h3>Missing Loginpage Content</h3>"];
  [_response appendContentString:@"<p>"
	       @"This is probably due to a setup problem of your OGo server, "
	       @"most likely OGo could not find the template files."];
  [_response appendContentString:@"</p>"];
  [_response appendContentString:
	       @"<p>Contact your system administrator to resolve the "
	       @"issue</p>"];
}

- (void)sanityCheckOnMainResponse:(WOResponse *)_response {
  /* check for setup issues like missing templates */
  
  if ([_response status] != 200)
    return;
  
  if ([[_response content] length] > 0)
    return;

  [self appendMissingContentErrorToResponse:_response];
}

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  if (![self _userAuthWithResponse:_response inContext:_ctx])
    return;
  
  [super appendToResponse:_response inContext:_ctx];
  [self sanityCheckOnMainResponse:_response];
}

/* accessors */

- (BOOL)hasRestrictedLicense { // TODO: remove
  [self logWithFormat:@"WARNING(%s): used deprecated method!",
	  __PRETTY_FUNCTION__];
  return NO;
}
- (int)daysLeftForLicense { // TODO: remove
  [self logWithFormat:@"WARNING(%s): used deprecated method!",
	  __PRETTY_FUNCTION__];
  return -1;
}

- (BOOL)isSkyrixUp {
  id app;
  
  app = [self application];
  if (![app respondsToSelector:@selector(lsoServer)]) {
    [self logWithFormat:
	    @"ERROR: application object doesn't match BaseUI Main component!"];
    return NO;
  }
  return [[app lsoServer] canConnectToDatabase];
}
- (BOOL)hasLicense { // TODO: remove
  [self logWithFormat:@"WARNING(%s): used deprecated method!",
	  __PRETTY_FUNCTION__];
  return YES;
}

- (BOOL)hasDirectAction {
  return self->directActionObject != nil ? YES : NO;
}

- (void)setIsLoginNotAuthorized:(BOOL)_flag {
  self->isLoginNotAuthorized = _flag;
}
- (BOOL)isLoginNotAuthorized {
  return self->isLoginNotAuthorized;
}

- (void)setDirectAction:(NSString *)_da {
  id tmp;
  if (self->directAction == _da)
    return;
  
  tmp = self->directAction;
  self->directAction = [_da copy];
  [tmp release];
}
- (NSString *)directAction {
  return self->directAction;
}

- (void)setDirectActionObject:(WODirectAction *)_dap {
  NSMutableDictionary *cache; // TODO: fix type
  
  ASSIGN(self->directActionObject, _dap);
  
  cache = (NSMutableDictionary *)[self session];
  if (_dap == nil)
    [cache removeObjectForKey:@"LoginAction"];
  else
    [cache setObject:_dap forKey:@"LoginAction"];
}
- (WODirectAction *)directActionObject {
  return self->directActionObject;
}

- (void)setUser:(NSString *)_user {
  ASSIGNCOPY(self->user, _user);
}
- (NSString *)user {
  return self->user;
}

- (void)setPassword:(NSString *)_password {
  ASSIGNCOPY(self->password, _password);
}
- (NSString *)password {
  return self->password ? self->password : @"";
}

- (int)pageExpireTimeout {
  return LSLoginPageExpireTimeout;
}

- (NSDictionary *)restoreParameters {
  return self->restoreParameters;
}
- (void)setRestoreParameters:(NSDictionary *)_para {
  ASSIGN(self->restoreParameters, _para);
}

- (NSString *)restorePageName {
  return self->restorePageName;
}
- (void)setRestorePageName:(NSString *)_pn {
  ASSIGN(self->restorePageName, _pn);
}

- (NSString *)loginName {
  return self->loginName;
}
- (void)setLoginName:(NSString *)_ln {
  ASSIGN(self->loginName, _ln);
}

- (id)item {
  return self->item;
}
- (void)setItem:(id)_i {
  ASSIGN(self->item, _i);
}

/* server is down */

- (NSDictionary *)connectionDictionary {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  return [ud dictionaryForKey:@"LSConnectionDictionary"];
}

- (NSString *)databaseName {
  NSString *v = [[self connectionDictionary] objectForKey:@"databaseName"];
  return [v length] > 0 ? v : @"missing";
}
- (NSString *)databaseServer {
  NSString *v = [[self connectionDictionary] objectForKey:@"hostName"];
  return [v length] > 0 ? v : @"missing";
}
- (NSString *)databaseUser {
  NSString *v = [[self connectionDictionary] objectForKey:@"userName"];
  return [v length] > 0 ? v : @"missing";
}

/* form restore functionality */

- (BOOL)restorePageMode {
  return [self restorePageName]?YES:NO;
}

- (NSArray *)parameterKeys {
  return [self->restoreParameters allKeys];
}

- (id)parameterValue {
  if (self->item)
    return [self->restoreParameters objectForKey:self->item];
  return nil;
}

- (NSString *)restorePageLabel {
  return self->restorePageLabel;
}
- (void)setRestorePageLabel:(NSString *)_pl {
  ASSIGN(self->restorePageLabel, _pl);;
}

- (BOOL)isRestoreKey:(NSString *)_key {
  if ([_key isEqualToString:@"restorePageName"])  return YES;
  if ([_key isEqualToString:@"restorePageLabel"]) return YES;
  if ([_key isEqualToString:@"loginName"])        return YES;
  if ([_key isEqualToString:@"button"])           return YES;
  if ([_key isEqualToString:@"da"])               return YES;
  if ([_key isEqualToString:@"o"])                return YES;
  if ([_key isEqualToString:@"password"])         return YES;
  return NO;
}

- (void)initRestoreWithRequest:(WORequest *)_req {
  NSEnumerator        *enumerator;
  NSString            *key;
  NSMutableDictionary *parameters;

  [self takeValue:[_req formValueForKey:@"restorePageName"]
        forKey:@"restorePageName"];
  [self takeValue:[_req formValueForKey:@"loginName"]
        forKey:@"loginName"];
  [self takeValue:[_req formValueForKey:@"restorePageLabel"]
        forKey:@"restorePageLabel"];
        
  parameters = [NSMutableDictionary dictionaryWithCapacity:16];
  enumerator = [[_req formValueKeys] objectEnumerator];
  
  while ((key = [enumerator nextObject]) != nil) {
    if ([self isRestoreKey:key])
      continue;

    if ([key rangeOfString:@"."].length == 0) {
      id v;
      
      if ((v = [_req formValueForKey:key]))
        [parameters setObject:v forKey:key];
    }
  }
  [self takeValue:parameters forKey:@"restoreParameters"];
}

- (NSString *)loginLink {
  NSString *s;
  
  s = [[[self application] baseURL] absoluteString];
  s = [[[[self context] request] adaptorPrefix] stringByAppendingString:s];
  return s;
}

@end /* Main */
