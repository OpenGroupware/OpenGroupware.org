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

#include "SkyRegistryApplication.h"
#include "common.h"
#include "SkyRegistryAction.h"
#include "RegistryEntry.h"
#include "SkyRegistryApplication+PrivateMethods.h"

#include <NGXmlRpc/NGXmlRpcClient.h>
#include <NGStreams/NGInternetSocketAddress.h>

@interface DirectAction : SkyRegistryAction
@end /* DirectAction */

@implementation DirectAction
@end /* DirectAction */

@interface WOAdaptor(SockAddr)
- (id<NGSocketAddress>)socketAddress;
@end

@implementation SkyRegistryApplication

+ (NSString *)defaultRequestHandlerClassName {
  return @"NGXmlRpcRequestHandler";
}

- (WORequestHandler *)handlerForRequest:(WORequest *)_request {
  if ([[_request method] isEqualToString:@"POST"])
    return [self defaultRequestHandler];
  else
    return [self requestHandlerForKey:@"wa"];
}

/* accessors */

- (NSString *)defaultConfigFileName {
  NSString *configPath;

  configPath = [[[NSProcessInfo processInfo]
                                environment]
                                objectForKey:@"GNUSTEP_USER_ROOT"];
  configPath = [configPath stringByAppendingPathComponent:@"config"];
  configPath = [configPath stringByAppendingPathComponent:
                           @"skyregistryd.plist"];
  return configPath;
}

- (NSUserDefaults *)userDefaults {
  return [NSUserDefaults standardUserDefaults];
}

- (NSString *)namespacePrefix {
#if 1
  return @"active";
#else
  return [[self userDefaults]
                objectForKey:@"SxDefaultNamespacePrefix"];
#endif
}

- (NSString *)namespaceSuffix {
  return @"registry";
}

- (NSString *)namespace {
  return [[[self namespacePrefix]
                 stringByAppendingString:@"."]
                 stringByAppendingString:[self namespaceSuffix]];
}

- (NSString *)pathForSkyIDLFile {
  return [[NSBundle bundleForClass:[self class]]
                    pathForResource:@"INTERFACE"
                    ofType:@"xml"];
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

- (NSString *)url {
  NGInternetSocketAddress *addr;
  NSString *hostName;
  
  if ((addr = [self applicationListenAddress]) == nil) {
    [self logWithFormat:@"got no HTTP address to register at ..."];
    return nil;
  }
  if (![addr isKindOfClass:[NGInternetSocketAddress class]]) {
    [self logWithFormat:@"app does not listen at an IP address: %@", addr];
    return nil;
  }
  
  if ((hostName = [addr hostName]) == nil) {
#warning bs: register at IP or host??
    //    [self logWithFormat:
    //            @"WARNING: application listens on a wildcard host, "
    //            @"registering component at IP (instead of localhost)."];
    //    hostName = [[NSHost currentHost] address];
    [self logWithFormat:
            @"WARNING: application listens on a wildcard host, "
            @"registering component at hostname (instead of localhost)."];
    hostName = [[NSHost currentHost] name];
  }

  return [NSString stringWithFormat:@"http://%@:%d/RPC2",
                   hostName, [addr port]];
}

- (void)registerRegistry {
  NSString *portURL;

  if ((portURL = [self url]) != nil) {
    NSMutableDictionary *dict;
    
    dict = [NSMutableDictionary dictionaryWithCapacity:4];
    [dict setObject:[self namespace] forKey:@"namespace"];
    [dict setObject:[self pathForSkyIDLFile] forKey:@"idl"];
    [dict setObject:@"NO" forKey:@"check"];
    [dict setObject:portURL forKey:@"url"];

    [self _setComponent:[self namespace] config:dict];
  }
  else
    [self logWithFormat:@"ERROR: Couldn't register registry - invalid URL"];
}

- (id)init {
  [self _setupDefaults];
  if ((self = [super init])) {
    NSString       *masterReg  = nil;
    NSUserDefaults *ud         = nil;
    NSString       *configPath = nil;
    int            interval    = 0;

    ud = [NSUserDefaults standardUserDefaults];
    
    self->registry  = [[NSMutableDictionary alloc] init];
    
    [self _checkDefaultSettings];
    
    configPath = [self defaultConfigFileName];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:configPath]) {
      if (![self initRegistry:[NSArray arrayWithContentsOfFile:configPath]]) {
        [self logWithFormat:@"Error parsing config file %@", configPath];
        RELEASE(self);
        return nil;
      }
    }
    
    [NGXmlRpcAction registerActionClass:[SkyRegistryAction class]
                    forURI:@"/RPC2"];
    [NGXmlRpcAction registerActionClass:[SkyRegistryAction class]
                    forURI:@"/skyregistryd.woa/wa/RPC2"];
    
    [SkyRegistryAction registerMappingsInFile:@"SkyRegistryActionMap"];

    [[NSNotificationCenter defaultCenter]
                           addObserver:self
                           selector:@selector(registerRegistry)
                           name:WOApplicationDidFinishLaunchingNotification
                           object:self];
    
    if ((masterReg = [ud valueForKey:@"SxMasterRegistryURL"]) != nil) {
      NSURL *url;

      if ((url = [NSURL URLWithString:masterReg]) != nil) {
        self->masterRegistry = [[NGXmlRpcClient alloc]
                                                initWithHost:[url host]
                                                uri:[url path]
                                                port:[[url port] intValue]
                                                userName:nil password:nil];
      }
    }

    interval = [[ud valueForKey:@"SxRegistryCheckInterval"] intValue];
    if (interval != 0) {
      [self logWithFormat:@"update interval set to %d seconds", interval];
      self->checkTimer = [[NSTimer scheduledTimerWithTimeInterval:interval
                                   target:self
                                   selector:@selector(checkRunningComponents:)
                                   userInfo:nil repeats:YES] retain];
    }
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter]
                         removeObserver:self
                         name:WOApplicationDidFinishLaunchingNotification
                         object:self];

  RELEASE(self->registry);
  RELEASE(self->masterRegistry);
  RELEASE(self->checkTimer);
  [super dealloc];
}

/* accessors */

- (int)checkInterval {
  return self->checkInterval;
}
- (void)setCheckInterval:(int)_checkInterval {
  self->checkInterval = _checkInterval;
}

- (NGXmlRpcClient *)masterRegistry {
  return self->masterRegistry;
}

- (NSMutableDictionary *)registry {
  return self->registry;
}

- (BOOL)initRegistry:(NSArray *)_registry {
  NSEnumerator *configEnum;
  id           configEntry;
  int          checkInt;

  checkInt = [[[self userDefaults]
                     objectForKey:@"SRNamespaceTimeout"]
                     intValue];

  if (checkInt == 0)
    checkInt = 300;

  [self logWithFormat:@"setting check interval to %d seconds", checkInt];
  [self setCheckInterval:checkInt];

  if (_registry == nil)
    return NO;

  [self debugWithFormat:@"loading entries from config file"];
  configEnum = [_registry objectEnumerator];

  while((configEntry = [configEnum nextObject])) {
    NSString *entryName;

    if ((entryName = [configEntry objectForKey:@"name"]) != nil)
      [self _setComponent:entryName config:configEntry];
    else {
      [self logWithFormat:@"ERROR: Your configfile seems to be outdated."];
      return NO;
    }
  }

  return YES;
}

- (void)checkRunningComponents:(NSTimer *)_timer {
  NSEnumerator  *registryEnum;
  NSString      *registryKey;
  NSMutableArray *deletedKeys;
  int i;
  
  deletedKeys = [NSMutableArray arrayWithCapacity:4];
  
  [self debugWithFormat:@"checking running components"];
  
  registryEnum = [self->registry keyEnumerator];
  while ((registryKey = [registryEnum nextObject])) {
    RegistryEntry *entry;

    entry = [self->registry objectForKey:registryKey];
    if ([entry entryTimedOut]) {
      [self logWithFormat:
            @"component for namespace '%@' timed out, removing...",
            registryKey];
      [deletedKeys addObject:registryKey];
    }
  }

  for (i = 0; i < [deletedKeys count]; i++) {
    [self->registry removeObjectForKey:[deletedKeys objectAtIndex:i]];
  }
}

@end /* SkyRegistryApplication */
