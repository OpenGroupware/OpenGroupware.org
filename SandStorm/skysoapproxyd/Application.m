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

#include "Application.h"
#include "common.h"
#include "SkySoapProxyAction.h"
#include <NGSoap/NGSoapClient.h>

@interface DirectAction : SkySoapProxyAction
@end

@implementation DirectAction
@end /* DirectAction */

@interface Application(PrivateMethods)
- (void)configureWithDictionary:(NSDictionary *)_dict;
@end /* Application(PrivateMethods) */


@implementation Application

+ (NSString *)defaultRequestHandlerClassName {
  return @"NGXmlRpcRequestHandler";
}
- (WORequestHandler *)handlerForRequest:(WORequest *)_request {
  if ([[_request method] isEqualToString:@"POST"])
    return [self defaultRequestHandler];
  else
    return [self requestHandlerForKey:@"wa"];
}

- (id)init {
  if ((self = [super init])) {
    NSDictionary *dict    = nil;
    NSString     *cfgPath = nil;
    
    cfgPath = [[[NSProcessInfo processInfo]
                               environment]
                               objectForKey:@"GNUSTEP_USER_ROOT"];
    cfgPath = [cfgPath stringByAppendingPathComponent:@"config"];
    cfgPath = [cfgPath stringByAppendingPathComponent:@"skysoapproxyd.plist"];

    self->clientCache   = [[NSMutableDictionary alloc] initWithCapacity:8];
    self->configs       = [[NSMutableDictionary alloc] initWithCapacity:8];
    
    if ((dict = [NSDictionary dictionaryWithContentsOfFile:cfgPath]) != nil) {
      [self configureWithDictionary:dict];
    }
    else {
      NSLog(@"%s: invalid configfile", __PRETTY_FUNCTION__);
    }
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->clientCache);
  RELEASE(self->configs);
  RELEASE(self->methods);
  [super dealloc];
}
#endif

- (void)removeClientForLocation:(NSString *)_location {
  if (_location != nil)
    [self->clientCache removeObjectForKey:_location];
}
- (void)setClient:(NGSoapClient *)_client forLocation:(NSString *)_location {
  if ((_location != nil) && (_client != nil))
    [self->clientCache setObject:_client forKey:_location];
}
- (NGSoapClient *)clientForLocation:(NSString *)_location {
  id tmp = nil;

  if (_location == nil)
    return nil;
  else if ((tmp = [self->clientCache objectForKey:_location]))
    return tmp;
  else {
    NGSoapClient *client = [[NGSoapClient alloc] initWithLocation:_location];
    if (client)
      [self->clientCache setObject:client forKey:_location];
    return AUTORELEASE(client);
  }
}

- (void)removeConfigForKey:(NSString *)_key {
  if (_key != nil)
    [self->configs removeObjectForKey:_key];
}
- (void)setConfig:(NSDictionary *)_config forKey:(NSString *)_key {
  if ((_key != nil) && (_key != nil))
    [self->configs setObject:_config forKey:_key];
}
- (NSDictionary *)configForKey:(NSString *)_key {
  return (_key != nil)
    ? [self->configs objectForKey:_key]
    : nil;
}

- (NSArray *)keys {
  return [self->configs allKeys];
}

- (void)setMethods:(NSArray *)_methods {
  ASSIGN(self->methods, _methods);
}
- (NSArray *)methods {
  return self->methods;
}

@end /* Application */

@implementation Application(PrivateMethods)

- (void)configureWithDictionary:(NSDictionary *)_dict {
  [self->configs addEntriesFromDictionary:_dict];
}

@end /* Application(PrivateMethods) */
