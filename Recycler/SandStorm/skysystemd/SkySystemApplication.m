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

#include "SkySystemApplication.h"
#include "SkySystemAction.h"
#include "TaskComponent.h"
#include "common.h"
#include <NGStreams/NGInternetSocketAddress.h>
#include <NGXmlRpc/NGXmlRpcRequestHandler.h>
#include <SxComponents/SxComponentRegistry.h>
#include <SxComponents/SxComponent.h>
#include <SxComponents/SxBasicAuthCredentials.h>

#include <unistd.h>

@interface SkySystemApplication(PrivateMethods)
- (NSDictionary *)_loadConfigFile;
- (BOOL)registerAtRegistry;
- (NSString *)namespaceWithPrefixForComponentNamed:(NSString *)_name;
@end /* SkySystemApplication(PrivateMethods) */

@interface WOAdaptor(SockAddr)
- (id<NGSocketAddress>)socketAddress;
@end

@implementation SkySystemApplication

+ (NSString *)defaultRequestHandlerClassName {
  return @"NGXmlRpcRequestHandler";
}
- (WORequestHandler *)handlerForRequest:(WORequest *)_request {
  return self->rqHandler;
}

- (NSString *)defaultConfigFileName {
  NSString *configPath;

#if COCOA_Foundation_LIBRARY
  configPath = [[[NSProcessInfo processInfo]
                                environment]
                                objectForKey:@"HOME"];
#else
  configPath = [[[NSProcessInfo processInfo]
                                environment]
                                objectForKey:@"GNUSTEP_USER_ROOT"];
#endif
  configPath = [configPath stringByAppendingPathComponent:@"config"];
  configPath = [configPath stringByAppendingPathComponent:
                           @"skysystemd.plist"];
  return configPath;
}

- (void)addComponent:(TaskComponent *)tc {
  [self logWithFormat:@"add component: %@", tc];
  if (self->components == nil)
    self->components = [[NSMutableDictionary alloc] init];
  [(id)self->components setObject:tc forKey:[tc componentName]];
}

- (void)configureWithDictionary:(NSDictionary *)_dict {
  NSDictionary *d;
  NSEnumerator *keys;
  NSString     *compName;
  
  d = [_dict objectForKey:@"components"];
  keys = [d keyEnumerator];
  while ((compName = [keys nextObject])) {
    TaskComponent *tc;
    
    tc = [[TaskComponent alloc] initWithName:compName 
                                config:[d objectForKey:compName]];
    [self addComponent:tc];
    RELEASE(tc);
  }
}

/* initialization */

- (id)init {
  if ((self = [super init])) {
    NSDictionary *config = nil;
    NSNotificationCenter *nc;
    
    [NGXmlRpcAction registerActionClass:[SkySystemAction class]
                    forURI:@"/RPC2"];
    
    self->rqHandler = [[NGXmlRpcRequestHandler alloc] init];
    
    if((config = [self _loadConfigFile]) == nil) {
      exit(1);
    }

    self->configuration = [config copy];
    [self configureWithDictionary:[self configuration]];
    
    /* autoregister notifications */
    nc = [NSNotificationCenter defaultCenter];
    
    [nc addObserver:self selector:@selector(registerAtRegistry:)
        name:WOApplicationDidFinishLaunchingNotification
        object:self];
    [nc addObserver:self selector:@selector(unregisterFromRegistry:)
        name:WOApplicationWillTerminateNotification
        object:self];
  }
  return self;
}

- (void)dealloc {
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  
  [nc removeObserver:self
      name:WOApplicationDidFinishLaunchingNotification
      object:self];
  [nc removeObserver:self 
      name:WOApplicationWillTerminateNotification
      object:self];

  RELEASE(self->rqHandler);
  RELEASE(self->registry);
  RELEASE(self->components);
  RELEASE(self->configuration);
  [super dealloc];
}

/* accessors */

- (void)setConfiguration:(NSDictionary *)_configuration {
  ASSIGN(self->configuration, _configuration);
}
- (NSDictionary *)configuration {
  return self->configuration;
}

- (NSDictionary *)components {
  return [[self configuration] objectForKey:@"components"];
}

- (NSUserDefaults *)userDefaults {
  static NSUserDefaults *ud = nil;
  if (ud == nil) ud = [[NSUserDefaults standardUserDefaults] retain];
  return ud;
}

- (NSString *)xmlrpcUser {
  return [[self userDefaults] stringForKey:@"SxRegistryComponentUser"];
}
- (NSString *)xmlrpcPassword {
  return [[self userDefaults] stringForKey:@"SxRegistryComponentPassword"];
}
- (NSString *)namespacePrefix {
  NSString *np;
  
  np = [[self userDefaults] stringForKey:@"SxDefaultNamespacePrefix"];

  if ([np length] > 0)
    return np;

  [self logWithFormat:
          @"WARNING: SxDefaultNamespacePrefix default is not set !"];
  
  np = [(NSHost *)[NSHost currentHost] name];
  if ([np length] > 0) {
    if (!isdigit([np characterAtIndex:0])) {
      NSArray *parts;

      parts = [np componentsSeparatedByString:@"."];
      if ([parts count] == 0) {
      }
      else if ([parts count] == 1)
        return [parts objectAtIndex:0];
      else {
        NSEnumerator *e;
        BOOL     isFirst = YES;
        NSString *s;
        
        e = [parts reverseObjectEnumerator];
        while ((s = [e nextObject])) {
          if (isFirst) {
            isFirst = NO;
            np = s;
          }
          else {
            np = [[np stringByAppendingString:@"."] stringByAppendingString:s];
          }
        }
        return np;
      }
    }
  }
  return @"com.skyrix";
}

- (id<NGSocketAddress>)applicationListenAddress {
  NSArray   *ads = [self adaptors];
  WOAdaptor *adaptor  = nil;
  
  if ([ads count] == 0) return nil;
  adaptor = [ads objectAtIndex:0];
  
  if (![adaptor respondsToSelector:@selector(socketAddress)]) {
    [self logWithFormat:
            @"application adaptor %@ doesn't provide it's "
            @"listening address !",
            adaptor];
    return nil;
  }
  return [adaptor socketAddress];
}

- (NSDictionary *)registerNamespace:(NSString *)_namespace
  withComponent:(SxComponent *)_component
{
  NGInternetSocketAddress *addr;
  NSArray  *arguments;
  NSString *hostName;
  
  if ((addr = [self applicationListenAddress]) == nil) {
    [self logWithFormat:@"got no HTTP address to register at ..."];
    return NO;
  }
  if (![addr isKindOfClass:[NGInternetSocketAddress class]]) {
    [self logWithFormat:@"app does not listen at an IP address: %@", addr];
    return NO;
  }
  
  if ((hostName = [addr hostName]) == nil) {
    [self logWithFormat:
            @"WARNING: application listens on a wildcard host, "
            @"registering component at hostname (instead of localhost)."];
    hostName = [[NSHost currentHost] name];
  }
  
  arguments = [NSArray arrayWithObjects:
                       _namespace,
                       @"/RPC2",
                       hostName,
                       [NSNumber numberWithInt:[addr port]],
                       [NSNumber numberWithBool:YES],
                       nil];
  
  return [_component call:@"setComponent" arguments:arguments];
}

- (BOOL)unregisterNamespace:(NSString *)_namespace
  withComponent:(SxComponent *)_component
{
  id result = nil;
  NSArray *arguments;

  arguments = [NSArray arrayWithObject:_namespace];
  result = [_component call:@"removeComponent"
                       arguments:arguments];
  return [result boolValue];
}

- (NSString *)registryNamespace {
  return @"active.registry";
}

- (SxBasicAuthCredentials *)credentials {
  SxBasicAuthCredentials *creds;

  creds = [[SxBasicAuthCredentials alloc]
                                   initWithRealm:@"SKYRiX"
                                   userName:[self xmlrpcUser]
                                   password:[self xmlrpcPassword]];
  return AUTORELEASE(creds);
}

- (SxComponentRegistry *)componentRegistry {
  return [SxComponentRegistry defaultComponentRegistry];
}

- (SxComponent *)registryComponent {
  if (self->registry)
    return self->registry;
  
  self->registry =
    [[self componentRegistry] getComponent:[self registryNamespace]];
  
  if (self->registry) {
    [[self componentRegistry] addCredentials:[self credentials]];
    self->registry = RETAIN(self->registry);
  }
  
  return self->registry;
}

- (NSArray *)componentNamespacesWithPrefix {
  NSArray        *componentNames;
  NSMutableArray *result;
  NSEnumerator   *compNameEnum;
  NSString       *compName;
  
  componentNames = [[self components] allKeys];

  result = [NSMutableArray arrayWithCapacity:[componentNames count]];

  compNameEnum = [componentNames objectEnumerator];
  while ((compName = [compNameEnum nextObject])) {
    NSString *nsPrefix;

    nsPrefix = [self namespaceWithPrefixForComponentNamed:compName];
    
    if (nsPrefix == nil) {
      [self logWithFormat:@"got no prefix for component %@", compName];
      continue;
    }
  
    [result addObject:nsPrefix];
  }
  return result;
}

- (void)handleRegistrationResult:(NSDictionary *)_result {
  NSString *timeout;

  if (_result == nil)
    return;

  if ((timeout = [_result objectForKey:@"timeout"]) != nil) {
    NSTimeInterval ti;
    
    if ((ti = [timeout intValue]) < 1) {
      ti = 180.0;
      [self debugWithFormat:
	      @"got invalid re-registration delay value ('%@' seconds)",
              timeout];
    }
    
    [self debugWithFormat:
	    @"setting re-registration delay to %.2g seconds",
	    ti];

    [NSTimer scheduledTimerWithTimeInterval:ti
             target:self
             selector:@selector(registerAtRegistry:)
             userInfo:nil repeats:NO];
  }
}

- (void)registerAtRegistry:(NSTimer *)_timer {
  SxComponent *component;
  BOOL timerIsInitialized = NO;
  int i, retries = 10;

  component = [self registryComponent];
  
  if (component != nil) {
    NSEnumerator *compNameEnum;
    NSString     *compName;
    
    compNameEnum = [[self componentNamespacesWithPrefix] objectEnumerator];
    while ((compName = [compNameEnum nextObject])) {
      for (i = 0; i < retries; i++) {  
        id result;

        [self debugWithFormat:
                @"registering component '%@' at registry", compName];
      
        result = [self registerNamespace:compName
                       withComponent:component];

        if (result == nil || [result isKindOfClass:[NSException class]]) {
          if (i < retries) {
            [self logWithFormat:
                  @"ERROR: registering namespace '%@' failed, retrying.",
                  compName];
          }
          else {
            [self logWithFormat:
                  @"ERROR: registering namespace '%@' failed, giving up.",
                  compName];
            [self terminate];
            return;
          }
        }
        else {
          if (!timerIsInitialized) {
            timerIsInitialized = YES;
            [self handleRegistrationResult:result];
          }
          break;
        }
        sleep(1);
      }
    }
  }
  else if ([self componentRegistry]) {
    [self logWithFormat:@"ERROR: no registry component found !"];
    [self terminate];
  }
  else {
    [self logWithFormat:@"no component registry found. running standalone."];
  }
}

- (void)unregisterFromRegistry:(NSNotification *)_notification {
  SxComponent *component;
  
  component = [self registryComponent];
  
  if (component != nil) {
    NSEnumerator *compNameEnum;
    NSString     *compName;

    compNameEnum = [[self componentNamespacesWithPrefix] objectEnumerator];
    while ((compName = [compNameEnum nextObject])) {
      [self debugWithFormat:
            @"unregistering namespace '%@' from registry",
            compName];
      if (![self unregisterNamespace:compName withComponent:component]) {
        [self logWithFormat:@"ERROR: unregistering namespace '%@' failed.",
              compName];
        break;
      }
    }
  }
  else {
    [self logWithFormat:@"ERROR: no registry component found !"];
  }
}

- (NSString *)namespaceWithPrefixForComponentNamed:(NSString *)_name {
  NSString *result;
  
  result = [[self namespacePrefix] stringByAppendingString:@"."];
  result = [result stringByAppendingString:_name];
  return result;
}

- (TaskComponent *)componentNamed:(NSString *)_name {
  if ([_name length] == 0) return nil;
  return [self->components objectForKey:_name];
}

- (NSDictionary *)_loadConfigFile {
  NSString *configFile = nil;

  configFile = [[NSUserDefaults standardUserDefaults] objectForKey:@"f"];

  if(configFile == nil)
    configFile = [self defaultConfigFileName];

  if(![[NSFileManager defaultManager] fileExistsAtPath:configFile]) {
    [self logWithFormat:@"ERROR: invalid config file path %@", configFile];
    return nil;
  }
    
  return [NSDictionary dictionaryWithContentsOfFile:configFile];
}

- (NSArray *)listMethods:(NSString *)_namespace {
  NSMutableArray *result;
  NSDictionary   *d;
  NSEnumerator   *compEnum;
  id             compKey;
  
  result = [NSMutableArray arrayWithCapacity:16];
  
  d = [[self configuration] objectForKey:@"components"];
  
  compEnum = [d keyEnumerator];
  while ((compKey = [compEnum nextObject])) {
    NSDictionary *comp;
    NSEnumerator *methodEnum;
    id method;

    comp = [d objectForKey:compKey];
    methodEnum = [[comp objectForKey:@"methods"] keyEnumerator];

    while((method = [methodEnum nextObject])) {
      [result addObject:[NSString stringWithFormat:@"%@.%@.%@",
                                  _namespace, compKey, method]];
    }
  }
  NSLog(@"%s: %@", __PRETTY_FUNCTION__, result);
  return result;
}

- (NSArray *)methodSignature:(NSString *)_method {
  NSMutableArray *elements;
  NSMutableArray *result;
  NSDictionary   *signatures;
  NSString       *namespace;
  NSString       *methodName;
  NSEnumerator   *sigEnum;
  id             sig;
  
  result = [NSMutableArray arrayWithCapacity:16];
  elements = [[_method componentsSeparatedByString:@"."] mutableCopy];

  methodName = [elements objectAtIndex:[elements count] -1];

  [elements removeObjectAtIndex:[elements count] -1];
  namespace = [elements componentsJoinedByString:@"."];
  
  signatures = [[[[[[self configuration]
                          objectForKey:@"components"]
                          objectForKey:namespace]
                          objectForKey:@"methods"]
                          objectForKey:methodName]
                          objectForKey:@"signatures"];

  if (signatures == nil) {
    return nil;
  }
    
  sigEnum = [signatures keyEnumerator];
  while ((sig = [sigEnum nextObject])) {
    NSArray *sigArray;

    sigArray = [sig componentsSeparatedByString:@","];
    [result addObject:sigArray];
  }
  return result;  
}

- (NSString *)methodHelp:(NSString *)_method {
  NSMutableArray *elements   = nil;
  NSString       *namespace  = nil;
  NSString       *methodName = nil;
  
  elements = [[_method componentsSeparatedByString:@"."] mutableCopy];

  methodName = [elements objectAtIndex:[elements count] -1];

  [elements removeObjectAtIndex:[elements count] -1];
  namespace = [elements componentsJoinedByString:@"."];
  
  return [[[[[[self configuration]
                    objectForKey:@"components"]
                    objectForKey:namespace]
                    objectForKey:@"methods"]
                    objectForKey:methodName]
                    objectForKey:@"help"];
}

@end /* Application */
