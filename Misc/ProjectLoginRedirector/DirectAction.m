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

#include <NGObjWeb/WODirectAction.h>

@interface DirectAction : WODirectAction
{
}

@end

#include "WOResponse+ExtractSID.h"
#include "common.h"

@implementation DirectAction

- (void)dealloc {
  [super dealloc];
}

/* responses */

- (id)couldNotConnectInstanceResponse:(NSString *)_url {
  WOResponse *r = [[self context] response];
  
  [self debugWithFormat:@"could not connect instance: %@", _url];
  [r appendContentHTMLString:@"Could not connect groupware instance: "];
  [r appendContentHTMLString:_url];
  return r;
}

- (id)unexpectedInstanceResponse:(WOResponse *)_r {
  WOResponse *r = [[self context] response];
  
  [self debugWithFormat:@"unexpected response from instance: %@", _r];
  [r appendContentHTMLString:@"<h3>Unexpected Response from Groupware</h3>"];
  [r appendContentString:@"<pre>"];
  [r appendContentHTMLString:[_r description]];
  [r appendContentString:@"</pre>"];
  return r;
}

- (id)couldNotLoginIntoInstance:(WOResponse *)_r {
  WOResponse *r = [[self context] response];
  
  // TODO: allow manual logins
  [self debugWithFormat:@"found no session-id in response: %@", _r];
  [r appendContentHTMLString:@"<h3>Could not login into Groupware!</h3>"];
  [r appendContentString:@"<pre>"];
  [r appendContentHTMLString:[_r description]];
  [r appendContentString:@"</pre>"];
  return r;
}

/* actions */

- (id)viewProject:(unsigned int)_oid inInstance:(NSString *)_url
  login:(NSString *)_login password:(NSString *)_pwd
{
  WOHTTPConnection *client;
  WORequest  *rq;
  WOResponse *loginResponse, *r;
  NSString   *s, *loginURI, *jumpTo;
  NSURL      *url;
  NSString   *remoteSessionID;

  url = [NSURL URLWithString:_url];
  
  [self debugWithFormat:@"view project: %i", _oid];
  [self debugWithFormat:@"  URL: %@", url];
  
  if ((client = [[WOHTTPConnection alloc] initWithURL:url]) == nil) {
    [self logWithFormat:@"ERROR: got no HTTP connection for URL: %@", _url];
    return nil;
  }
  client = [client autorelease];

  /* create URI for login-action */
  
  loginURI = [url path];
  if (![loginURI hasSuffix:@"/"]) 
    loginURI = [loginURI stringByAppendingString:@"/"];
  loginURI = [loginURI stringByAppendingString:@"wa/login?login="];
  loginURI = [loginURI stringByAppendingString:[_login stringByEscapingURL]];
  
  /* create request */
  
  rq = [[WORequest alloc] 
         initWithMethod:@"POST" uri:loginURI httpVersion:@"HTTP/1.0"
         headers:nil content:nil userInfo:nil];
  rq = [rq autorelease];

  [rq setHeader:@"application/x-www-form-urlencoded" forKey:@"content-type"];
  
  s = @"browserconfig={isJavaScriptEnabled=YES;}";
  [rq appendContentString:[s stringByEscapingURL]];
  
  [rq appendContentString:@"&login="];
  [rq appendContentString:[_login stringByEscapingURL]];
  [rq appendContentString:@"&password="];
  [rq appendContentString:[_pwd stringByEscapingURL]];
  [rq appendContentString:@"&loginbutton=login"];
  
  /* send request */
  
  [self debugWithFormat:@"send: %@", rq];
  if (![client sendRequest:rq])
    return [self couldNotConnectInstanceResponse:_url];
  
  loginResponse = [client readResponse];
  
  if ([loginResponse status] != 200)
    return [self unexpectedInstanceResponse:loginResponse];
  
  [self debugWithFormat:@"got response: %@", loginResponse];
  
  if ((remoteSessionID = [loginResponse extractSessionID]) == nil)
    return [self couldNotLoginIntoInstance:loginResponse];
  
  [self debugWithFormat:@"session: %@", remoteSessionID];
  
  /* construct activation URL */
  
  jumpTo = [url absoluteString];
  if (![jumpTo hasSuffix:@"/"]) jumpTo = [jumpTo stringByAppendingString:@"/"];
  jumpTo = [jumpTo stringByAppendingFormat:@"wa/activate?oid=%d", _oid];
  jumpTo = [jumpTo stringByAppendingString:@"&wosid="];
  jumpTo = [jumpTo stringByAppendingString:remoteSessionID];
  
  r = [[self context] response];
  [r setHeader:jumpTo forKey:@"location"];
  [r setStatus:302];
  return r;
}

- (id)viewProjectAction {
  unsigned int oid;
  WOSession *sn;
  NSString  *url;
  
  if ((sn = [self existingSession]) == nil) {
    WOResponse *r;
    
    [self debugWithFormat:@"no session, redirecting to login page ..."];
    
    url = [[self context] directActionURLForActionNamed:@"Main/default"
                          queryDictionary:nil];
    r = [[self context] response];
    [r setHeader:url forKey:@"location"];
    [r setStatus:302];
    return r;
  }
  
  oid = [[[self request] formValueForKey:@"oid"] unsignedIntValue];
  if (oid <= 10000) {
    [self debugWithFormat:@"missing/invalid 'oid' in viewProject request ..."];
    return nil;
  }
  
  if ((url = [[self request] formValueForKey:@"url"]) == nil) {
    [self debugWithFormat:@"missing URL in viewProject request ..."];
    return nil;
  }
  
  return [self viewProject:oid inInstance:url
               login:[sn valueForKey:@"login"]
               password:[sn valueForKey:@"password"]];
}

- (id)defaultAction {
  return [self pageWithName:@"Main"];
}

@end /* DirectAction */
