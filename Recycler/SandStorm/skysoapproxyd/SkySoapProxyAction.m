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

#include "SkySoapProxyAction.h"
#include <NGXmlRpc/WODirectAction+XmlRpc.h>
#include <NGXmlRpc/WODirectAction+XmlRpcIntrospection.h>
#include "common.h"
#include "Application.h"
#include <NGSoap/NGSoapClient.h>
#include <SOAP/SOAP.h>

@interface SkySoapProxyAction(PrivateMethods)
- (NSArray *)_cleanedActionNameFragments:(NSString *)_name;
- (NSArray *)_listMethods;
- (NSArray *)_methodSignatureForFragments:(NSArray *)_frags;
- (id)_performFragments:(NSArray *)_frags parameters:(NSArray *)_params;
@end /* SkySoapProxyAction(PrivateMethods) */

@implementation SkySoapProxyAction

- (NSString *)xmlrpcComponentName {
  return @"soapproxy";
}

- (BOOL)requiresCommandContextForMethodCall:(id)_call {
  return YES;
}

- (id)performActionNamed:(NSString *)_name parameters:(NSArray *)_params {
  NSArray  *frags = nil;

  frags = [self _cleanedActionNameFragments:_name];

  if ([frags count] > 1)
    return ([[frags objectAtIndex:0] isEqualToString:@"system"])
      ? [super performActionNamed:_name parameters:_params]
      : [self _performFragments:frags parameters:_params];
  else
    return [super performActionNamed:_name parameters:_params];
}

- (NSArray *)system_listMethodsAction {
  NSArray *tmp;

  if (!(tmp = [[self application] methods]))
    tmp = [self _listMethods];

  tmp = [tmp arrayByAddingObjectsFromArray:[super system_listMethodsAction]];

  return tmp;
}

- (NSArray *)system_methodSignatureAction:(NSString *)_xmlrpcMethod {
  NSArray *frags = nil;

  frags = [self _cleanedActionNameFragments:_xmlrpcMethod];
  
  if ([frags count] > 1) {
    return ([[frags objectAtIndex:0] isEqualToString:@"system"])
      ? [super system_methodSignatureAction:_xmlrpcMethod]
      : [self _methodSignatureForFragments:frags];
  }
  else
    return [super system_methodSignatureAction:_xmlrpcMethod];
}

- (id)testAction {
  return @"dies ist ein test";
}

@end /* SkySoapProxyAction */

@implementation SkySoapProxyAction(PrivateMethods)

- (NSArray *)_cleanedActionNameFragments:(NSString *)_name {
  NSString *name;
  NSString *p;

  /* check component namespace and strip it ;-) */

  name = _name;
  p    = [self xmlrpcComponentNamespace];
  
  if ([p length] > 0) {
    if ([name hasPrefix:p]) {
      name = [name substringFromIndex:[p length]];
      if ([name length] > 0) {
        if ([name characterAtIndex:0] == '.')
          name = [name substringFromIndex:1];
      }
    }
  }
  return [name componentsSeparatedByString:@"."];
}

- (id)_performFragments:(NSArray *)_frags parameters:(NSArray *)_params
{
  NSDictionary *config      = nil;
  NGSoapClient *client      = nil;
  NSArray      *frags       = nil;
  NSString     *location    = nil;
  NSString     *serviceName = nil;
  NSString     *methodName  = nil;
  id           result       = nil;

  frags       = [_frags subarrayWithRange:NSMakeRange(0, [_frags count] - 1)];
  location    = [frags componentsJoinedByString:@"."];
  config      = [[self application] configForKey:location];
  location    = [config objectForKey:@"wsdl"];
  serviceName = [config objectForKey:@"service"];
  methodName  = [_frags lastObject];  
  client      = [[self application] clientForLocation:location];
  
  if (config == nil) {
    return [NSException exceptionWithName:@"NoSuchProxyService"
                        reason:@"non config entry for service"
                        userInfo:nil];
  }
  else if (serviceName == nil) {
    return [NSException exceptionWithName:@"MissingServiceNameMapping"
                        reason:@"service name is not configured"
                        userInfo:nil];
  }
  else if (client == nil) {
    return [NSException exceptionWithName:@"NoSoapClientAvailable"
                        reason:@"could not instantiate soapclient"
                        userInfo:nil];
  }

  result = [client invokeMethodNamed:methodName
                   serviceName:serviceName
                   parameters:_params];

  return result;
}

- (NSArray *)_listMethods {
  Application    *app       = nil;
  NSEnumerator   *keyEnum   = nil;
  NSString       *key       = nil;
  NSString       *namespace = nil;
  NSMutableArray *result    = nil;

  app       = [self application];
  keyEnum   = [[app keys] objectEnumerator];
  namespace = [self xmlrpcComponentNamespace];
  result    = [[NSMutableArray alloc] initWithCapacity:32];
  
  while ((key = [keyEnum nextObject])) {
    NSDictionary      *config   = nil;
    NSString          *location = nil;
    NGSoapClient      *client   = nil;
    SOAPWSDLService   *service  = nil;
    NSEnumerator      *opEnum   = nil;
    SOAPWSDLOperation *op;
    
    config   = [app configForKey:key];
    location = [config objectForKey:@"wsdl"];
    client   = [app clientForLocation:location];
    service  = [client serviceWithName:[config objectForKey:@"service"]];
    opEnum   = [[service operations] objectEnumerator];

    while ((op = [opEnum nextObject])) {
      NSString *actionName;

      actionName = [NSString stringWithFormat:@"%@.%@.%@",
                             namespace, key, [op name]];
      [result addObject:actionName];
    }
  }
  [app setMethods:result];
  return AUTORELEASE(result);
}

- (NSArray *)_methodSignatureForFragments:(NSArray *)_frags {
  SOAPWSDLOperation *op          = nil;
  NSDictionary      *config      = nil;
  NSMutableArray    *signature   = nil;
  Application       *app         = nil;
  NSArray           *frags       = nil;
  unsigned          i, cnt       = 0;
  NGSoapClient      *client      = nil;
  NSString          *location    = nil;
  NSString          *serviceName = nil;
  NSString          *methodName  = nil;
  NSArray           *parts       = nil;
  NSString          *type        = nil;

  app         = [self application];
  cnt         = [_frags count];
  frags       = [_frags subarrayWithRange:NSMakeRange(0, cnt - 1)];
  location    = [frags componentsJoinedByString:@"."];
  config      = [app configForKey:location];
  location    = [config objectForKey:@"wsdl"];
  serviceName = [config objectForKey:@"service"];
  methodName  = [_frags lastObject];
  client      = [app clientForLocation:location];
  
  op = [[client serviceWithName:serviceName] operationWithName:methodName];
  signature = [NSMutableArray arrayWithCapacity:cnt+1];
    
  parts = [[op outputMessage] parts];
  if ([parts count] > 0)
    type = [[[parts objectAtIndex:0] type] valueFromQName];
  if (type == nil)
    type = @"string";

  [signature addObject:type];
    
  parts = [[op inputMessage] parts];
  cnt   = [parts count];

  for (i = 0; i < cnt; i++) {
    type = [[[parts objectAtIndex:i] type] valueFromQName];

    if (type == nil) type = @"string";
      
    [signature addObject:type];
  }
  return [NSArray arrayWithObject:signature];
}

@end /* SkySoapProxyAction(PrivateMethods) */
