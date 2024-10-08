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

#include "OpenGroupware.h"
#include <LSFoundation/OGoContextManager.h>
#include <LSFoundation/OGoContextSession.h>
#include <LSFoundation/LSCommandContext.h>
#include <NGExtensions/NSString+Ext.h>
#include "common.h"

#if !LIB_FOUNDATION_LIBRARY  
#  include <NGExtensions/NGPropertyListParser.h>
#endif

@interface LSCommandContext(LDAPSupport)
+ (BOOL)useLDAPAuthorization;
@end

@interface OGoSession(ConfigLogin)
- (BOOL)configureForLSOfficeSession:(OGoContextSession *)_sn;
- (void)setIsJavaScriptEnabled:(BOOL)_flag;
@end

@protocol WOComponentRestore
- (void)initRestoreWithRequest:(WORequest *)_req;
- (void)setIsLoginNotAuthorized:(BOOL)_flag;
@end

@interface NSObject(RestorePageDefinitions)
- (void)verifyDataForRestorePage;
- (void)prepareForRestorePage;
@end /* NSObject(RestorePageDefinitions) */

@implementation WODirectAction(LoginAction)

static BOOL debugOn = NO;
static NSNumber *nYes = nil;
static int LSUseLowercaseLogin  = -1;
static int LSAllowSpacesInLogin = -1;

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

- (void)handleLoginFailed:(id)_page {
  WORequest *req;
  NSString  *pageName, *loginName;

  req = [[(id)self context] request];

  pageName  = [req formValueForKey:@"restorePageName"];
  loginName = [req formValueForKey:@"loginName"];
  
  if (pageName != nil && loginName != nil) {
    /* activate main page with the given hiden parameters */
    [_page initRestoreWithRequest:req];
  }
}

- (void)_applyDebuggingDefaultsOnSession:(OGoContextSession *)sn {
  /* apply debugging defaults */
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  if ([[ud objectForKey:@"s"] boolValue])
    [sn enableAdaptorDebugging];
  if ([[ud objectForKey:@"sa"] boolValue])
    [LSBaseCommand setDebuggingEnabled:YES];
}

- (id)_attachOGoSession:(OGoContextSession *)sn {
  if ([(OGoSession *)[self session] configureForLSOfficeSession:sn])
    /* successful */
    return nil;

  [[self session] terminate];
  [self logWithFormat:@"failed to configure session !"];
  return [self pageWithName:@"OGoLogoutPage"];
}

- (id)_processRedirectURL:(NSString *)_url {
  WOResponse *r;
  
  if ([_url length] == 0)
    return nil;
  
  _url = ([_url rangeOfString:@"?"].length == 0)
    ? [_url stringByAppendingString:@"?wosid="]
    : [_url stringByAppendingString:@"&wosid="];
  _url = [_url stringByAppendingString:[[self session] sessionID]];
  
  [self logWithFormat:@"redirect to: %@", _url];
  
  r = [[self context] response];
  [r setStatus:302 /* redirect */];
  [r setHeader:_url forKey:@"location"];
  return r;
}

- (id)_processLoginActionInSession {
  WODirectAction *da;
  OGoNavigation  *nav;
  WOComponent *page = nil;
  
  da = [(NSDictionary *)[self session] objectForKey:@"LoginAction"];
  if (da == nil)
    da = [(NSDictionary *)[self session] objectForKey:@"directActionObject"];
  if (da == nil) {
    if (debugOn) {
      [self logWithFormat:@"found no 'LoginAction' in session: %@", 
	      [self session]];
    }
    return nil;
  }
  
  da = [[da retain] autorelease];
  [(NSMutableDictionary *)[self session] removeObjectForKey:@"LoginAction"];
  
  page = (id)[da performActionNamed:[[self request] formValueForKey:@"da"]];

  if (debugOn)
    [self logWithFormat:@"executing direct action, page is: %@", [page name]];
  
  if (![page isContentPage])
    return page;
  
  // TODO: add a method to replace the complete navigation with page?
  nav = [[self session] navigation];
  while ([nav containsPages]) {
    if ([nav leavePage] == nil)
      break;
  }
  [nav enterPage:page];
  return page;
}

- (id)_processPageRestorationWithRequest:(WORequest *)_rq {
  NSEnumerator *enumerator;
  NSString     *key;
  NSString *pageName;
  id page;
  
  if ((pageName = [_rq formValueForKey:@"restorePageName"]) == nil)
    return nil;
  
  /* activate mail editor */
  
  if ((page = [self pageWithName:pageName]) == nil) {
    [self logWithFormat:@"could not restore page with name %@", pageName];
    return nil;
  }
  
  if ([page respondsToSelector:@selector(prepareForRestorePage)])
    [page prepareForRestorePage];
  
  enumerator = [[_rq formValueKeys] objectEnumerator];
  while ((key = [enumerator nextObject])) {
    id v;
    
    if ([key isEqualToString:@"restorePageName"]) continue;
    if ([key isEqualToString:@"loginName"])       continue;
    if ([key isEqualToString:@"button"])          continue;
    if ([key isEqualToString:@"browserconfig"])   continue;
    if ([key isEqualToString:@"password"])        continue;
    if ([key isEqualToString:@"o"])               continue;
    if ([key isEqualToString:@"da"])              continue;
          
    if ([key rangeOfString:@"."].length != 0)
      continue;
    
    if ((v = [_rq formValueForKey:key]))
      [page takeValue:v forKey:key];
  }
  if ([page respondsToSelector:@selector(verifyDataForRestorePage)])
    [page verifyDataForRestorePage];
          
  [[[self session] navigation] enterPage:page];
  return page;
}

- (void)_applyBrowserConfigurationFromRequest:(WORequest *)req {
  id         browserConfig;
  OGoSession *s;
  
  browserConfig = [req formValueForKey:@"browserconfig"];
  if (![browserConfig isNotEmpty])
    return;
  
#if LIB_FOUNDATION_LIBRARY  
  browserConfig = [browserConfig propertyList];
#else
  browserConfig = NGParsePropertyListFromString(browserConfig);
#endif
  if (![browserConfig respondsToSelector:@selector(keyEnumerator)]) {
    [self errorWithFormat:@"could not parse browser config string ..."];
    return;
  }
  
  s = (OGoSession *)[self session];

  [s setIsJavaScriptEnabled:
       [[browserConfig objectForKey:@"isJavaScriptEnabled"] boolValue]];
}

- (void)_configureUserAgentFromRequest:(WORequest *)req {
  WEClientCapabilities *ccaps;
  WOSession *s;
    
  s = [self session];
  if ((ccaps = [req clientCapabilities])) {
    NSLog(@"ccaps: %@", ccaps);
    [s takeValue:ccaps forKey:@"clientCapabilities"];
  }
        
  if ([ccaps isFastTableBrowser])
    [s takeValue:nYes forKey:@"isFastTableBrowser"];
  if ([ccaps isCSS1Browser])  [s takeValue:nYes forKey:@"isCSS1Browser"];
  if ([ccaps isCSS2Browser])  [s takeValue:nYes forKey:@"isCSS2Browser"];
  if ([ccaps isLinuxBrowser]) [s takeValue:nYes forKey:@"isLinuxBrowser"];
  if ([ccaps isX11Browser])   [s takeValue:nYes forKey:@"isX11Browser"];
  if ([ccaps isTextModeBrowser])
    [s takeValue:nYes forKey:@"isTextModeBrowser"];
}

- (void)_ensureLoginActionDefaults {
  if (LSUseLowercaseLogin == -1) {
    LSUseLowercaseLogin = 
      [[NSUserDefaults standardUserDefaults] 
        boolForKey:@"LSUseLowercaseLogin"] ? 1 : 0;
  }
  if (LSAllowSpacesInLogin == -1) {
    LSAllowSpacesInLogin = 
      [[NSUserDefaults standardUserDefaults] 
        boolForKey:@"AllowSpacesInLogin"] ? 1 : 0;
  }
  if (nYes == nil)
    nYes = [[NSNumber numberWithBool:YES] retain];
}

- (NSString *)_cleanUpLoginActionLogin:(NSString *)login {
  if (LSAllowSpacesInLogin == 0)
    login = [login stringByTrimmingSpaces];
  
  if (LSUseLowercaseLogin)
    login = [login lowercaseString];
  
  if ([login length] == 0)
    login = nil;
  
  return login;
}

- (WOComponent *)_ldapPageForLogin:(NSString *)login password:(NSString *)pwd {
  WOComponent *page;
  
  if (![LSCommandContext useLDAPAuthorization])
    return nil;
  if ([login isEqualToString:[self rootLogin]])
    return nil;

  /* create account from LDAP */
  
  if ((page = [self pageWithName:@"WelcomeNewLDAPAccount"]) == nil) {
    [self logWithFormat:@"Note: missing LDAP account welcome page!"];
    return nil;
  }
  [self logWithFormat:@"Note: welcome new LDAP account '%@' ...", login];
  [page takeValue:login forKey:@"login"];
  [page takeValue:pwd   forKey:@"password"];
  return page;
}

- (id<WOActionResults>)loginActionWithLogin:(NSString *)login
  password:(NSString *)pwd
  request:(WORequest *)req
{
  /* TODO: split up this huge mehtod */
  OGoContextManager *lso;
  OGoContextSession  *sn;
  id                page, tpage;
  [self _ensureLoginActionDefaults];
  
  lso = [(OpenGroupware *)[WOApplication application] lsoServer];
  if (lso == nil) {
    [self logWithFormat:@"did not find OpenGroupware.org server .."];
    return [self pageWithName:@"Main"];
  }
  
  if ((login = [self _cleanUpLoginActionLogin:login]) == nil) {
    [self debugWithFormat:@"No login name was specified."];
    return [self pageWithName:@"Main"];
  }
  
  if (![lso isLoginAuthorized:login password:pwd]) {
    [self logWithFormat:@"access denied for user %@.", login];
    
    page = [self pageWithName:@"Main"];
    [page setIsLoginNotAuthorized:YES];
    [page takeValue:login forKey:@"user"];
    [self handleLoginFailed:page];
    return page;
  }
  
  /* get browser configuration */
  [self _applyBrowserConfigurationFromRequest:req];
  
  /* configure user-agent */
  [self _configureUserAgentFromRequest:req];

#if DEBUG && 0
  [self logWithFormat:@"session cfg %@", [[self session] variableDictionary]];
#endif
  
  /* get OGo session */
  
  if ((sn = [lso login:login password:pwd]) == nil) {
    /* couldn't login */
    WOComponent *ldapPage;

    if ((ldapPage = [self _ldapPageForLogin:login password:pwd]))
      /* create account from LDAP */
      return ldapPage;
    
    [self debugWithFormat:@"Note: failed to login into OpenGroupware.org!"];
    
    page = [self pageWithName:@"Main"];
    [page takeValue:login forKey:@"user"];
    [self handleLoginFailed:page];
    return page;
  }
  
  [sn activate];
  
  [self _applyDebuggingDefaultsOnSession:sn];
  
  if ((page = [self _attachOGoSession:sn]) != nil) /* returns error page */
    return page;
  
  /* start page */
  
  if ((page = [[[self session] navigation] activePage]) == nil) {
    [self logWithFormat:@"failed to load start page !"];
    [[WOApplication application] terminate];
    return [self pageWithName:@"OGoLogoutPage"];
  }
  
  /* reset to default session timeout */
  
  [[self session] setTimeOut:[[WOApplication sessionTimeOut] intValue]];
  
  /* check direct action hooks */
  
  if ((tpage = [self _processRedirectURL:[req formValueForKey:@"url"]]) !=nil){
    if (debugOn) [self logWithFormat:@"redirect to URL: %@", tpage];
    page = tpage;
  }
  else if ((tpage = [self _processLoginActionInSession]) != nil) {
    if (debugOn) [self logWithFormat:@"used login action: %@", tpage];
    page = tpage;
  }
  else if ((tpage = [self _processPageRestorationWithRequest:req]) != nil) {
    if (debugOn) [self logWithFormat:@"page restoration: %@", tpage];
    page = tpage;
  }
  else if (debugOn) 
    [self logWithFormat:@"default page: %@", tpage];
  
  return page;
}

- (id<WOActionResults>)loginAction {
  WORequest *req;
  
  req = [self request];
  
  return [self loginActionWithLogin:[req formValueForKey:@"login"]
               password:[req formValueForKey:@"password"]
               request:req];
}

@end /* WODirectAction(LoginAction) */
