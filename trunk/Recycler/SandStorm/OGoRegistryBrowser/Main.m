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

#include "common.h"
#include "Main.h"
#include "RunMethod.h"
#include "ComponentList.h"
#include <SxComponents/SxComponentException.h>
#include <SxComponents/SxBasicAuthCredentials.h>
#include <SxComponents/SxComponentRegistry.h>
#include <SxComponents/SxXmlRpcComponent.h>

@implementation Main

/* initialization */

- (id)init {
  if ((self = [super init])) {

    self->registry       = [[[self session] registry] retain];
    self->gotComponent   = NO;
    self->addMode        = NO;
    self->hasError       = NO;
    self->component      = @"";
    self->componentInfo  = [[SxXmlRpcComponent alloc] init];
    self->state          = [[NSMutableDictionary alloc] init];

    self->componentNames = [[self->registry listComponents] retain];
    
    if (self->componentNames == nil) {
      NSLog(@"%s: no components received, seems your local registry is down.",
            __PRETTY_FUNCTION__);
      self->errorMessage = @"Can't contact your local registry daemon.";
      self->hasError = YES;
    }
    self->componentList =
      [[ComponentList alloc] initWithArray:self->componentNames];
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->registry);
  RELEASE(self->componentInfo);
  RELEASE(self->methods);
  RELEASE(self->component);
  RELEASE(self->newComponentName);
  RELEASE(self->newComponentURL);
  RELEASE(self->components);
  RELEASE(self->currentPath);
  RELEASE(self->currentPathString);
  RELEASE(self->componentList);
  RELEASE(self->state);
  RELEASE(self->componentNames);
  RELEASE(self->errorMessage);
  [super dealloc];
}

/* accessors */

- (BOOL)hasError {
  return self->hasError;
}

- (void)setErrorMessage:(NSString *)_message {
  ASSIGNCOPY(self->errorMessage, _message);
}
- (NSString *)errorMessage {
  return self->errorMessage;
}

- (NSString *)keyPath {
  return [[self->currentPath lastObject] key];
}

- (BOOL)isEndpoint {
  NSEnumerator *listEnum;
  id listEntry;
  NSString *objectKey;

  objectKey = [[self objectForKey:@"item"] key];

  listEnum = [self->componentNames objectEnumerator];

  while((listEntry = [listEnum nextObject])) {
    if ([listEntry isEqualToString:objectKey])
      return YES;
  }
  return NO;
}

- (void)setIsZoom:(BOOL)_flag {
  NSString *key;

  key = [self keyPath];

  if (key)
    [self->state setObject:[NSNumber numberWithBool:!_flag] forKey:key];
}
- (BOOL)isZoom {
  NSString *key;

  key = [self keyPath];

  if (key == nil)
    return YES;
    
  return ![[self->state objectForKey:key] boolValue];
}

- (void)setCurrentPath:(NSArray *)_p {
  if (_p == nil)
    _p = [NSArray array];
  
  ASSIGN(self->currentPath, _p);
  
  RELEASE(self->currentPathString); self->currentPathString = nil;
  self->currentPathString = [[_p componentsJoinedByString:@"."] copy];
}
- (NSArray *)currentPath {
  return self->currentPath;
}

- (NSString *)currentPathString {
  return self->currentPathString;
}

- (void)setRegistry:(SxComponentRegistry *)_registry {
  ASSIGN(self->registry, _registry);
}
- (SxComponentRegistry *)registry {
  return self->registry;
}

- (void)setComponentInfo:(SxXmlRpcComponent *)_info {
  ASSIGN(self->componentInfo, _info);
}
- (SxXmlRpcComponent *)componentInfo {
  return self->componentInfo;
}

- (void)setMethods:(NSArray *)_methods {
  if (self->methods == nil) {
    self->methods = [[NSArray alloc] init];
  }
  ASSIGN(self->methods, _methods);
}
- (NSArray *)methods {
  return self->methods;
}

- (void)setComponent:(NSString *)_component {
  ASSIGNCOPY(self->component, _component);
}
- (NSString *)component {
  return self->component;
}

- (void)setNewComponentName:(NSString *)_name {
  if (self->newComponentName == nil) {
    self->newComponentName = [[NSString alloc] init];
  }
  ASSIGNCOPY(self->newComponentName, _name);
}
- (NSString *)newComponentName {
  return self->newComponentName;
}

- (void)setNewComponentURL:(NSString *)_url {
  if (self->newComponentURL == nil) {
    self->newComponentURL = [[NSString alloc] init];
  }
  ASSIGNCOPY(self->newComponentURL, _url);
}
- (NSString *)newComponentURL {
  return self->newComponentURL;
}

- (void)setComponents:(NSArray *)_components {
  if (self->components == nil) {
    self->components = [[NSArray alloc] init];
  }
  ASSIGN(self->components, _components);  
}

- (NSArray *)rootElements {
  NSMutableSet *result;
  NSEnumerator *compEnum;
  id comp;

  result = [NSMutableSet setWithCapacity:[self->components count]];
   
  compEnum = [self->components objectEnumerator];
  while((comp = [compEnum nextObject])) {
    [result addObject:[[comp componentsSeparatedByString:@"."]
            objectAtIndex:0]];
  }
  return [result allObjects];
}

- (NSArray *)components {
  return [self->componentList components];
}

- (NSString *)componentURL {
  return [NSString stringWithFormat:@"http://%@:%@%@",
                   [[self->componentInfo url] host],
                   [[self->componentInfo url] port],
                   [[self->componentInfo url] path]];
}

- (BOOL)addMode {
  return self->addMode;
}

- (BOOL)gotComponent {
  return self->gotComponent;
}

/* actions */

- (id)getComponent {
  SxXmlRpcComponent *sxComponent = nil;
  id                methodNames  = nil;
  
  [self setComponent:[[self objectForKey:@"item"] key]];
  
  if ([self component] != nil)
    sxComponent = (id)[self->registry getComponent:[self component]];
  
  if (sxComponent != nil) {
    self->gotComponent = YES;
    
    [self setComponentInfo:sxComponent];
    
    methodNames = [sxComponent listMethods];
    methodNames = [methodNames sortedArrayUsingSelector:@selector(compare:)];
    
    if ([sxComponent lastCallFailed]) {
      NSException *e;

      e = [sxComponent lastException];

      if ([e isCredentialsRequiredException]) {
        SxBasicAuthCredentials *creds;
        
        creds = [[SxBasicAuthCredentials alloc] initWithRealm:@""
                                                userName:@"bjoern"
                                                password:@"bjoern"];

        NSLog(@"%s: Basic authentication failed", __PRETTY_FUNCTION__);
        
        [(id)e setCredentials:creds];
        
        [self->registry addCredentials:creds];

        RELEASE(creds);

        return [self getComponent];
      }
    }
    
    if ([methodNames isKindOfClass:[NSArray class]]) {
      [self setMethods:methodNames];
    }
    else if ([methodNames isKindOfClass:[NSDictionary class]]) {
      NSLog(@"%s: XML-RPC Fault(%@): %@",
            __PRETTY_FUNCTION__,
            [methodNames objectForKey:@"faultCode"],
            [methodNames objectForKey:@"faultString"]);
    }
    else if (methodNames == nil) {
      NSLog(@"%s: getComponent failed, no result ...", __PRETTY_FUNCTION__);
    }
    else {
      NSLog(@"%s: XML-RPC Fault : %@",__PRETTY_FUNCTION__, methodNames);
    }
  }
  return self;
}

- (id)addComponent {
  self->addMode = YES;
  return self;
}

- (id)addNewComponent {
  // currently not working (disabled on server side)
  SxXmlRpcComponent   *comp;
  NSURL               *url;

  url = [NSURL URLWithString:[self newComponentURL]];
  comp = [[SxXmlRpcComponent alloc] initWithName:[self newComponentName]
                                    namespace:[self newComponentName]
                                    registry:[self registry]
                                    url:url];
  
  [self->registry registerComponent:comp];
  self->addMode = NO;
  RELEASE(comp);
  return self;
}

- (id)removeComponent {
  // currently not working (disabled on server side)
  [self->registry unregisterComponent:[self componentInfo]];
  return self;
}

- (id)runMethod {
  RunMethod *page;
  
  [[self session] setObject:self forKey:@"mainPage"];
  
  page = [self pageWithName:@"RunMethod"];
  [page setMethodName:[self valueForKey:@"method"]];
  [page setComponent:[self componentInfo]];
  
  return page;
}

@end /* Main */
