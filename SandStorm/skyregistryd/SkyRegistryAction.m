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

#include "SkyRegistryAction.h"
#include "common.h"
#include "SkyRegistryAction+Authorization.h"
#include "SkyRegistryAction+PrivateMethods.h"
#include "SkyRegistryApplication.h"
#include "RegistryEntry.h"
#include "NSObject+URLConversion.h"
#include <OGoDaemon/SDXmlRpcFault.h>

#include <OGoIDL/NGXmlRpcAction+Introspection.h>
#include <NGXmlRpc/NGXmlRpcClient.h>

@implementation SkyRegistryAction

/* initialization */

- (NSBundle *)bundle {
  return [NSBundle bundleForClass:[self class]];
}

- (id)initWithContext:(WOContext *)_ctx {
  if ((self = [super initWithContext:_ctx])) {
    NSString *path;

    path = [[self bundle] pathForResource:@"INTERFACE" ofType:@"xml"];
    if (path != nil)
      [self registerInterfaceAtPath:path];
    else
      [self logWithFormat:@"INTERFACE.xml not found in bundle path"];
  }
  return self;
}

/* component information */

- (NSString *)xmlrpcComponentNamespacePrefix {
  return @"active.registry";
}
- (NSString *)xmlrpcComponentName {
  return @"";
}
- (NSString *)xmlrpcComponentNamespace {
  return @"active.registry";
}

/* accessors */

- (SkyRegistryApplication *)application {
  static Class AppClass = Nil;
  if (AppClass == Nil) AppClass = [SkyRegistryApplication class];
  return [AppClass application];
}

- (NGXmlRpcClient *)masterRegistry {
  return [[self application] masterRegistry];
}

- (NSMutableDictionary *)registry {
  return [[self application] registry];
} 

/* component actions */

- (id)setComponentAction:(NSString *)_component
                        :(NSString *)_uri
                        :(NSString *)_host
                        :(NSString *)_port
                        :(NSNumber *)_sendTimeoutInformation
                        :(NSString *)_namespace
{
  if ([self isAuthorized] && _component != nil) {
    NSURL    *url;
    NSString *urlString;
    RegistryEntry* regEntry;

    urlString = [NSString stringWithFormat:@"http://%@:%@%@",
                          _host, _port, _uri];

    if ((url = [NSURL URLWithString:urlString]) == nil) {
      [self logWithFormat:@"ERROR: component '%@' has invalid URL!",
            _component];
      return [SDXmlRpcFault invalidValueFaultForArgument:@"url"
                            ofComponent:_component];
    } 
    else {
      BOOL                result;
      NSMutableDictionary *dict;

      dict = [NSMutableDictionary dictionaryWithObject:[url absoluteString]
                                  forKey:@"url"];
      if (_namespace != nil)
        [dict setObject:_namespace forKey:@"namespace"];

      regEntry = [[RegistryEntry alloc] initWithName:_component
                                        dictionary:dict];

      [self logWithFormat:@"registering namespace '%@' for '%@'",
            _component, [dict objectForKey:@"url"]];

      [[self registry] setObject:regEntry forKey:_component];
      RELEASE(regEntry);

      if ([_sendTimeoutInformation boolValue]) {
        NSNumber *timeout;

        timeout = [NSNumber numberWithInt:[[self application] checkInterval]];

        return [NSDictionary dictionaryWithObjectsAndKeys:
                             timeout, @"timeout",
                             nil];
      }
      return [NSNumber numberWithBool:result];
    }
  }
  else
    return [self missingAuthAction];
}

- (id)removeComponentAction:(NSString *)_component {
  if([self isAuthorized]) {
    [self logWithFormat:@"removing component for namespace '%@'",_component];
    [[self registry] removeObjectForKey:_component];
    return [NSNumber numberWithBool:YES];
  }
  return [self missingAuthAction];
}

- (id)getComponentsAction {
  NSArray *currentKeys = nil;
  NSArray *masterKeys  = nil;

  [self debugWithFormat:@"getting all registered components"];

  currentKeys = [[self registry] allKeys];
  
  if ([self masterRegistry] != nil) {
    [self debugWithFormat:
          @"getting registered components from master registry"];
    masterKeys = [self _fetchMasterKeys];
  }

  if (masterKeys == nil || [masterKeys isKindOfClass:[NSException class]])
    return currentKeys;
  else {
    NSMutableSet *keySet;
    keySet = [NSMutableSet setWithCapacity:[currentKeys count]];
    [keySet addObjectsFromArray:masterKeys];
    [keySet addObjectsFromArray:currentKeys];

    return keySet;
  }
}

- (id)getComponentAction:(NSString *)_component {
  RegistryEntry *registryEntry = nil;
  NSURL *url;

  url = nil;
  [self debugWithFormat:@"getting component for namespace '%@'", _component];
  
  if ((registryEntry = [[self registry] objectForKey:_component]) != nil)
    url = [registryEntry url];
  else {
    if ([self masterRegistry] != nil) {
      id tmp;
      
      tmp = [[self masterRegistry] call:
                 @"active.registry.getComponent", _component, nil];

      /* ignore exceptions from the master component */
      if ([tmp isKindOfClass:[NSException class]])
        return nil;

      url = [tmp asURL];

      if (url == nil)
        [self logWithFormat:@"couldn't morph string '%@' into URL ..",
              tmp];
    }
  }

  if ([url isKindOfClass:[NSException class]])
    return url;
  
  else if (url != nil) {
    NSMutableDictionary *result;
    id tmp;

    if ([[url class] isKindOfClass:[NSDictionary class]]) {
      return (NSDictionary *)url;
    }
    
    result = [NSMutableDictionary dictionaryWithCapacity:3];
    if ((tmp = [url host])) [result setObject:tmp forKey:@"host"];
    if ((tmp = [url port])) [result setObject:tmp forKey:@"port"];
    if ((tmp = [url path])) [result setObject:tmp forKey:@"uri"];
    
    return result;
  }
  else {
    return [NSException exceptionWithName:@"SkyRegistryComponentException"
                        reason:@"found no component for namespace"
                        userInfo:nil];
  }
}

- (id)getComponentAndNamespaceAction:(NSString *)_component {
  id result;
  NSString *ns = nil;
  RegistryEntry *registryEntry = nil;
  
  result = [self getComponentAction:_component];

  if ([result isKindOfClass:[NSException class]]) {
    return result;
  }

  registryEntry = [[self registry] objectForKey:_component];
  
  if (registryEntry != nil)
    ns = [registryEntry namespace];
  
  if (ns != nil)
    [result setObject:ns forKey:@"namespace"];

  return result;
}

@end /* SkyRegistryAction */
