/*
  Copyright (C) 2000-2003 SKYRIX Software AG

  This file is part of OGo

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

@class NSString;

@interface DirectIcalAction: WODirectAction
@end /* DirectIcalAction */

#import <Foundation/Foundation.h>
#include <NGObjWeb/NGObjWeb.h>
#include <LSFoundation/LSFoundation.h>
#include <OGoDaemon/SDApplication.h>
#include "IcalEvents.h"
#include "IcalPublish.h"
#include "IcaliCalPublish.h"

@interface DirectIcalAction(Auth)
- (BOOL)hasAuthorizationHeader;
- (NSString *)credentials;
- (NSString *)authRealm;
- (id<WOActionResults>)missingAuthAction;
- (id<WOActionResults>)accessDeniedAction;
- (LSCommandContext *)commandContext;
@end /* DirectIcalAction(Auth) */

@implementation DirectIcalAction

- (BOOL)requiresCommandContextForMethod:(NSString *)_method {
  return YES;
}

- (id)performActionNamed:(NSString *)_method {
  LSCommandContext *ctx;

  if ([self requiresCommandContextForMethod:_method]) {
    if (![self hasAuthorizationHeader])
      return [self missingAuthAction];
    if ((ctx = [self commandContext]) == nil)
      return [self accessDeniedAction];
  }
  
  return [super performActionNamed:_method];
}

- (id<WOActionResults>)defaultAction {
  WOResponse *r;
  WORequest  *rq;
  NSString   *content;
  
  rq = [self request];
  NSLog(@"%s: request: %@", __PRETTY_FUNCTION__, rq);

  content = [[NSString alloc] initWithData:[rq content]
                              encoding:[rq contentEncoding]];
  NSLog(@"%s: CONTENT: '%@'", __PRETTY_FUNCTION__, content);
  RELEASE(content);
  
  r = [WOResponse responseWithRequest:rq];
  [r setStatus:200];
  return r;
}

- (id<WOActionResults>)eventsAction {
  WORequest  *rq     = [self request];
  IcalEvents *events;
  WOResponse *r;

  events = [[IcalEvents alloc] initWithRequest:rq
                               commandContext:[self commandContext]];
  
  r = [WOResponse responseWithRequest:rq];
  [r setHeader:@"text/plain" forKey:@"content-type"];

  if (events != nil) [r setStatus:200];

  [r setContent:
     [events contentUsingEncoding:NSISOLatin1StringEncoding]];

  RELEASE(events);

  return r;
}

- (id<WOActionResults>)publishAction {
  WORequest   *rq     = [self request];
  IcalPublish *publish;
  WOResponse  *r;

  publish = [[IcalPublish alloc] initWithRequest:rq
                                 commandContext:[self commandContext]];
  
  r = [WOResponse responseWithRequest:rq];
  [r setHeader:@"text/plain" forKey:@"content-type"];

  if (publish != nil) [r setStatus:200];

  [r setContent:
     [publish contentUsingEncoding:NSISOLatin1StringEncoding]];

  RELEASE(publish);

  return r;
}

- (id<WOActionResults>)icalpublishAction {
  WORequest   *rq     = [self request];
  IcalPublish *publish;
  WOResponse  *r;

  if (![[rq method] isEqualToString:@"PUT"]) {
    r = [WOResponse responseWithRequest:rq];
    [r setHeader:@"text/plain" forKey:@"content-type"];
    [r setStatus:200];
  }

  else {
    publish = [[IcaliCalPublish alloc] initWithRequest:rq
                                       commandContext:[self commandContext]];
  
    r = [WOResponse responseWithRequest:rq];
    [r setHeader:@"text/plain" forKey:@"content-type"];

    if (publish != nil) [r setStatus:200];

    [r setContent:
       [publish contentUsingEncoding:NSISOLatin1StringEncoding]];

    RELEASE(publish);
  }
  return r;
}

@end /* DirectIcalAction */

@implementation DirectIcalAction(Auth)

- (BOOL)hasAuthorizationHeader {
  WORequest *rq;
  NSString  *cred;
  
  if ((rq = [self request]) == nil)
    return NO;

  if ((cred = [rq headerForKey:@"authorization"]) == nil)
    return NO;
  
  return YES;
}

- (NSString *)credentials {
  WORequest *rq;
  NSString  *cred;
  NSRange   r;
  
  if ((rq = [self request]) == nil)
    return nil;
  if ((cred = [rq headerForKey:@"authorization"]) == nil)
    return nil;
  
  r = [cred rangeOfString:@" " options:NSBackwardsSearch];
  if (r.length == 0) {
    NSLog(@"%s: invalid 'authorization' header: '%@'",
          __PRETTY_FUNCTION__, cred);
    return nil;
  }
  return [cred substringFromIndex:(r.location + r.length)];
}

- (NSString *)authRealm {
  return @"SKYRiX";
}
- (id<WOActionResults>)missingAuthAction {
  WOResponse *resp;
  NSString *auth;

  auth = [NSString stringWithFormat:@"basic realm=\"%@\"",[self authRealm]];
  
  resp = [(WOResponse *)[WOResponse alloc] initWithRequest:[self request]];
  [resp setStatus:401 /* unauthorized */];
  [resp setHeader:auth forKey:@"www-authenticate"];
  return AUTORELEASE(resp);
}

- (id<WOActionResults>)accessDeniedAction {
  WOResponse *resp;
  NSString *auth;
  
  auth = [NSString stringWithFormat:@"basic realm=\"%@\"",[self authRealm]];
  
  NSLog(@"%s: access was denied", __PRETTY_FUNCTION__);
  
  resp = [(WOResponse *)[WOResponse alloc] initWithRequest:[self request]];
  [resp setStatus:401 /* unauthorized */];
  [resp setHeader:auth forKey:@"www-authenticate"];
  return AUTORELEASE(resp);
}

- (id)application {
  return [WOCoreApplication application];
}
- (LSCommandContext *)commandContext {
  return [[self application] contextForCredentials:[self credentials]];
}

@end /* DirectIcalAction(Auth) */
