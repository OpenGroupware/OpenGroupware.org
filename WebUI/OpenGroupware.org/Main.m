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

#include "Main.h"
#include "OpenGroupware.h"
#include "common.h"
#include <LSFoundation/OGoContextSession.h>
#include <LSFoundation/OGoContextManager.h>
#include <WEExtensions/WEClientCapabilities.h>

@interface Main(PrivateMethods)
- (id)login;
- (BOOL)isSkyrixUp;

- (void)setUser:(NSString *)_user;
- (NSString *)user;
- (void)setPassword:(NSString *)_pwd;
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
    id lso = [(OpenGroupware *)[WOApplication application] lsoServer];
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

  lso  = [(OpenGroupware *)[WOApplication application] lsoServer];
  
  if ([lso isLoginAuthorized:[self rootLogin] password:@""])
    return [self login];
  
  return nil;
}

- (id)invokeActionForExpiredRequest:(WORequest *)_request
  inContext:(WOContext *)_ctx
{
  id lso;

  lso  = [(OpenGroupware *)[WOApplication application] lsoServer];

  if ([lso isLoginAuthorized:[self rootLogin] password:@""]) {
    return  [[[self session] navigation] activePage];
  }
  return nil;
}

- (void)sleep {
  if (![self isSkyrixUp]) {
    if ([self hasSession])
      [[self session] terminate];
  }
  [super sleep];
}

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  if ([self->user length] == 0) {
    NSString *authType;
    NSString *authUser;
    
    authType = [[_ctx request] headerForKey:@"x-webobjects-auth-type"];
    authUser = [[authType lowercaseString] isEqualToString:@"basic"]
      ? [[_ctx request] headerForKey:@"x-webobjects-remote-user"]
      : nil;
    
    if ([authUser length] > 0) {
      NSString *auth;
      
      [self setUser:authUser];

      if (LSUseBasicAuth) {
        if ((auth = [[_ctx request] headerForKey:@"authorization"])) {
          NSRange r;
          
          r = [auth rangeOfString:@" " options:NSBackwardsSearch];
          if (r.length > 0) {
            auth = [auth substringFromIndex:(r.location + r.length)];
            auth = [auth stringByDecodingBase64];
          }
          else
            auth = nil;
        }
        if (auth) {
          NSRange r;
  
          r = [auth rangeOfString:@":"];
          auth = (r.length > 0)
            ? [auth substringFromIndex:(r.location + r.length)]
            : nil;
        }
        
        if ([auth length] > 0) {
          id lso;
          
          lso = [(OpenGroupware *)[WOApplication application] lsoServer];
          
          if ([lso isLoginAuthorized:[self user] password:auth]) {
            [self setPassword:auth];
            [self takeValue:[NSNumber numberWithBool:YES]
                  forKey:@"autologin"];
          }
        }
      }
    }
    else {
      if (LSUseBasicAuth) {
        [_response setHeader:@"basic realm=\"OpenGroupware\""
                   forKey:@"www-authenticate"];
        [_response setStatus:401];
        return;
      }
    }
  }
  [super appendToResponse:_response inContext:_ctx];
}

/* accessors */

- (BOOL)hasRestrictedLicense { // TODO: remove
  return NO;
}
- (int)daysLeftForLicense { // TODO: remove
  return -1;
}

- (BOOL)isSkyrixUp {
  return [[[self application] lsoServer] canConnectToDatabase];
}
- (BOOL)hasLicense { // TODO: remove
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

  while ((key = [enumerator nextObject])) {
    if ([key isEqualToString:@"restorePageName"])
      continue;
    if ([key isEqualToString:@"restorePageLabel"])
      continue;
    if ([key isEqualToString:@"loginName"])
      continue;
    if ([key isEqualToString:@"button"])
      continue;
    if ([key isEqualToString:@"da"])
      continue;
    if ([key isEqualToString:@"o"])
      continue;
    if ([key isEqualToString:@"password"])
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
  return [[[[self context] request] adaptorPrefix] 
	          stringByAppendingString:s];  
}

@end /* Main */
