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
#include "common.h"
#include <EOControl/EOControl.h>
#include <NGObjWeb/WODirectAction.h>
#include <NGXmlRpc/WODirectAction+XmlRpc.h>
#include "Application.h"
#include "Session.h"

@implementation DirectAction

- (NSString *)xmlrpcComponentNamespace {
  return @"com.skyrix.mail";
}

- (LSCommandContext *)_commandContextForAuth:(NSString *)_cred
  inContext:(WOContext *)_ctx
{
  NSAutoreleasePool *p;
  NSString *login = nil;
  NSString *pwd   = nil;
  id       lso    = nil;
  id       ctx    = nil;

  p = [[NSAutoreleasePool alloc] init];
  {
    NSRange r;
    
    r = [_cred rangeOfString:@" " options:NSBackwardsSearch];
    if (r.length == 0) {
      /* invalid _cred */
      NSLog(@"%s: invalid 'authorization' header", __PRETTY_FUNCTION__);
      [p release];
      return nil;
    }
    
    _cred = [_cred substringFromIndex:(r.location + r.length)];
    _cred = [_cred stringByDecodingBase64];
    r     = [_cred rangeOfString:@":"];
    login = [_cred substringToIndex:r.location];
    pwd   = [_cred substringFromIndex:r.location + r.length];
  }
  lso = [OGoContextManager defaultManager];
  ctx = [[LSCommandContext alloc] initWithManager:lso];
  login = [login copy];
  pwd   = [pwd   copy];
  [p release]; p = nil;
  
  if ([(LSCommandContext *)ctx login:login password:pwd] == NO) {
    NSLog(@"%s: login %@ was not authorized !", __PRETTY_FUNCTION__, login);
    [login release];
    [pwd   release];
    [ctx   release];
    return nil;
  }
  [login release];
  [pwd   release];
  return [ctx autorelease];
}

- (id)commandContext {
  return [(Session *)[self session] commandContext];
}

/* actions */

- (id<WOActionResults>)_notAuthenticated {
  WOResponse *resp;
    
  resp = [(WOResponse *)[WOResponse alloc] initWithRequest:[self request]];
  [resp setStatus:401 /* unauthorized */];
  [resp setHeader:@"basic realm=\"SKYRiX\"" forKey:@"www-authenticate"];
  
  return resp;
}

- (id<WOActionResults>)_commitFailed {
  WOResponse *resp;
    
  resp = [(WOResponse *)[WOResponse alloc] initWithRequest:[self request]];
  [resp setStatus:500 /* server error */];
  [resp appendContentString:@"tx commit failed ..."];
  
  return resp;
}

- (id<WOActionResults>)xmlrpcAction {
  Application      *app     = nil;
  NSString         *cred    = nil;
  LSCommandContext *ctx     = nil;
  Session          *session = nil;
  id               result   = nil;

  app  = (Application *)[WOApplication application];
  cred = [[self request] headerForKey:@"authorization"];
  
  if ([cred length] == 0)
    return [self _notAuthenticated];
  
  [app setCredentials:cred]; // is needed for creating the session
  
  session = (Session *)[self session];
  if ((ctx = [session commandContext]) == nil) {
    ctx = [self _commandContextForAuth:cred inContext:context];
    if (ctx)
      [session setCommandContext:ctx];
  }
  
  [app setCredentials:nil];
  
  if (ctx == nil)
    return [self _notAuthenticated];

  result = [super xmlrpcAction];

  if (ctx) {
    if ([ctx isTransactionInProgress]) {
      if (![ctx commit]) {
        [self logWithFormat:@"couldn't commit transaction ..."];
        return [self _commitFailed];
      }
    }
  }
  
  return result;
}

@end /* DirectAction */
