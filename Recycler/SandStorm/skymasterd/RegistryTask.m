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

#include "RegistryTask.h"
#include "SkyMasterApplication.h"
#include "common.h"
#include <SxComponents/SxComponent.h>
#include <SxComponents/SxComponentRegistry.h>
#include <SxComponents/SxBasicAuthCredentials.h>
#include <NGStreams/NGInternetSocketAddress.h>
#include <unistd.h>

@interface WOAdaptor(SockAddr)
- (id<NGSocketAddress>)socketAddress;
@end

@implementation RegistryTask

- (NSUserDefaults *)userDefaults {
  return [NSUserDefaults standardUserDefaults];
}

- (NSString *)xmlrpcUser {
  return [[self userDefaults] objectForKey:@"SxRegistryComponentUser"];
}
- (NSString *)xmlrpcPassword {
  return [[self userDefaults] objectForKey:@"SxRegistryComponentPassword"];
}

- (NSString *)masterComponentName {
  return @"master";
}

- (NSString *)namespace {
  NSString *prefix;
  
  prefix = [[self userDefaults]
                  objectForKey:@"SxDefaultNamespacePrefix"];

  return [[prefix stringByAppendingString:@"."]
                  stringByAppendingString:[self masterComponentName]];
}

- (SxBasicAuthCredentials *)credentials {
  SxBasicAuthCredentials *creds;

  creds = [[SxBasicAuthCredentials alloc]
                                   initWithRealm:@"SKYRiX"
                                   userName:[self xmlrpcUser]
                                   password:[self xmlrpcPassword]];
  return AUTORELEASE(creds);
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
	    @"setting re-registration delay to %.2f seconds",
	    ti];

    [NSTimer scheduledTimerWithTimeInterval:ti
             target:self
             selector:@selector(registerAtRegistry:)
             userInfo:nil repeats:NO];
  }
}

- (id<NGSocketAddress>)applicationListenAddress {
  SkyMasterApplication *app;
  NSArray   *ads;
  WOAdaptor *adaptor  = nil;

  app = (SkyMasterApplication *)[WOApplication application];
  ads = [app adaptors];
  
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

- (SxComponent *)registryComponent {
  SxComponentRegistry *registry;
  SxComponent         *component;
  
  registry = [SxComponentRegistry defaultComponentRegistry];

  component = [registry getComponent:@"active.registry"];
  if (component != nil)
    [registry addCredentials:[self credentials]];
  
  return component;
}

- (NSDictionary *)registerNamespace:(NSString *)_namespace
  withComponent:(SxComponent *)_component
{
  NGInternetSocketAddress *addr;
  NSArray  *args;
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
  
  args = [NSArray arrayWithObjects:
                  _namespace,
                  @"/RPC2", /* this must match the registerActionClass:: */
                  hostName,
                  [NSNumber numberWithInt:[addr port]],
                  [NSNumber numberWithBool:YES],
                  [self masterComponentName],
                  nil];
  
  return [_component call:@"setComponent" arguments:args];
}

- (BOOL)unregisterNamespace:(NSString *)_namespace
  withComponent:(SxComponent *)_component
{
  id result = nil;
  NSArray *args;

  args = [NSArray arrayWithObject:_namespace];
  result = [_component call:@"removeComponent"
                       arguments:args];
  return [result boolValue];
}

- (NSNumber *)registryPort {
  NSUserDefaults *ud;
  NSString       *registryURL;
  
  ud = [self userDefaults];
  
  if ((registryURL = [ud objectForKey:@"SxComponentRegistryURL"]) != nil) {
    NSURL *url;

    if ((url = [NSURL URLWithString:registryURL]) == nil) {
      [self debugWithFormat:
            @"invalid URL format for default 'SxComponentRegistryURL'"];
      return nil;
    }
    else {
      return [url port];
    }
  }
  else {
    [self debugWithFormat:
            @"Default 'SxComponentRegistryURL' is not set."];
    return nil;
  }
}

- (BOOL)registerAtRegistry:(NSTimer *)_timer {
  SxComponent *component;
  int i, retries = 10;

  for (i = 0; i < retries; i++) {  
    if ((component = [self registryComponent]) != nil) {
      id result;

      [self debugWithFormat:
          @"registering component '%@' at registry", [self namespace]];
      
      result = [self registerNamespace:[self namespace]
                     withComponent:component];
      
      if (result == nil || [result isKindOfClass:[NSException class]]) {
        if (i < retries) {
          [self logWithFormat:
                @"ERROR: registering namespace '%@' failed, retrying.",
                [self namespace]];
        }
        else {
          [self logWithFormat:
                @"ERROR: registering namespace '%@' failed, giving up.",
                [self namespace]];
          return NO;
        }
      }
      else {
        [self handleRegistrationResult:result];
        return YES;
      }
    }
    sleep(1);
  }
  return NO;
}

- (void)unregisterFromRegistry:(NSNotification *)_notification {
  SxComponent *component;
  
  component = [self registryComponent];
  
  if (component != nil) {
    [self debugWithFormat:
          @"unregistering namespace '%@' from registry",
          [self namespace]];
    if (![self unregisterNamespace:[self namespace] withComponent:component]) {
      [self logWithFormat:@"ERROR: unregistering namespace '%@' failed.",
            [self namespace]];
    }
  }
  else {
    [self logWithFormat:@"ERROR: no registry component found !"];
  }
}

- (id)start:(id)_arguments {
  NSNumber       *port;
  NSMutableArray *args;
  BOOL           hasPort = NO;
  NSEnumerator  *argEnum;
  NSString      *argName;
  id result;

  args = [NSMutableArray arrayWithCapacity:2];
  argEnum = [_arguments keyEnumerator];

  while ((argName = [argEnum nextObject])) {
    [args addObject:[NSString stringWithFormat:@"-%@", argName]];
    [args addObject:[[_arguments objectForKey:argName] stringValue]];

    if ([argName isEqualToString:@"WOPort"]) {
      hasPort = YES;
    }
  }

  if (!hasPort) {
    if ((port = [self registryPort]) != nil) {
      [args addObject:@"-WOPort"];
      [args addObject:[port stringValue]];
    }
  }

  result = [super start:args];

  if (result != nil) {
    if (![self registerAtRegistry:nil]) {
      [self logWithFormat:@"Registration at registry failed..."];
      [self stop];
      RELEASE(self);
      return nil;
    }
  }
  return result;
}

@end /* RegistryTask */
