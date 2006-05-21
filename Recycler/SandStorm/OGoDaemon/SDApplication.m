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

#include "SDApplication.h"
#include "SDXmlRpcAction.h"
#include "common.h"
#include <NGStreams/NGInternetSocketAddress.h>
#include <SxComponents/SxComponentRegistry.h>
#include <SxComponents/SxComponent.h>
#include <SxComponents/SxBasicAuthCredentials.h>
#include <unistd.h>

@interface OGoContextManager(DatabaseConnect)
- (BOOL)canConnectToDatabase;
@end /* OGoContextManager(DatabaseConnect) */

@interface SDApplication(PrivateMethods)
- (BOOL)_createPIDFile;
@end /* SDApplication(PrivateMethods) */

@interface WOAdaptor(SockAddr)
- (id<NGSocketAddress>)socketAddress;
@end

@interface NSObject(XmlRpcNamespaces)
- (NSArray *)xmlrpcNamespaces;
@end /* NSObject(XmlRpcNamespaces) */

@implementation SDApplication

static NSMutableArray *namespacesToBeRegistered = nil;

+ (BOOL)didLoadDaemonBundle:(NSBundle *)_bundle {
  Class pClass;
  
  if (![super didLoadDaemonBundle:_bundle])
    return NO;

  if ((pClass = [_bundle principalClass]) == Nil) {
    [self logWithFormat:
          @"bundle %@ has no principal class ...", _bundle];
    return NO;
  }

  if (![pClass isKindOfClass:[NGXmlRpcAction class]]) {
    [self logWithFormat:
          @"bundle principal class %@ is not a subclass of NGXmlRpcAction ...",
          NSStringFromClass(pClass)];
    return NO;
  }

  [self logWithFormat:@"processing principal class: %@",
        NSStringFromClass(pClass)];

  [SDXmlRpcAction registerActionClass:pClass forURI:@"/RPC2"];

  [pClass registerMappingsInFile:
          [NSStringFromClass(pClass) stringByAppendingString:@"Map"]];

  if(![pClass respondsToSelector:@selector(xmlrpcNamespaces)]) {
    [self logWithFormat:
          @"class %@ doesnt respond to selector xmlrpcNamespaces"
          @" - automatic registration failed",
          NSStringFromClass(pClass)];
    return NO;
  }

  if (namespacesToBeRegistered == nil)
    namespacesToBeRegistered = [[NSMutableArray alloc] init];
  
  [namespacesToBeRegistered addObjectsFromArray:[pClass xmlrpcNamespaces]];
  
  return YES;
}

+ (int)loadDaemonBundle:(NSString *)_bundleName {
  if ([[_bundleName pathExtension] length] == 0)
    _bundleName = [_bundleName stringByAppendingPathExtension:@"rpcd"];
  
  return [super loadApplicationBundle:_bundleName
                domainPath:@"Skyrix42/XmlRpcServers"];
}

- (id)init {
  if ((self = [super init])) {
    WORequestHandler     *rh;
    NSNotificationCenter *nc;
    NSString             *tmp = nil;
 
    nc = [NSNotificationCenter defaultCenter];

    [nc addObserver:self selector:@selector(registerAtRegistry:)
        name:WOApplicationDidFinishLaunchingNotification
        object:self];

    [nc addObserver:self selector:@selector(unregisterFromRegistry:)
        name:WOApplicationWillTerminateNotification
        object:self];
    
    self->lso = [[OGoContextManager defaultManager] retain];
    self->credToContext = [[NSMutableDictionary alloc] initWithCapacity:64];
    self->loginToCred   = [[NGMutableHashMap alloc] initWithCapacity:64];

    if (![self _createPIDFile]) {
      [self logWithFormat:@"error creating PID file, terminating ..."];
      RELEASE(self);
      return nil;
    }
    
    /* setup request handler */
    rh = [[NSClassFromString([self defaultRequestHandlerClassName])
                            alloc] init];
    [self setDefaultRequestHandler:rh];
    RELEASE(rh); rh = nil;

    tmp = [[NSUserDefaults standardUserDefaults]
                           valueForKey:@"SDRSSLimit"];
    if (tmp != nil) {
      self->rssSizeLimit = [tmp intValue];
      [self logWithFormat:
            @"RSS Size check enabled: shutting down app when RSS > %d MB",
            self->rssSizeLimit];
    }
    else
      self->rssSizeLimit = 0;
  }
  return self;
}

- (void)dealloc {
  NSNotificationCenter *nc;

  nc = [NSNotificationCenter defaultCenter];
  
  [nc removeObserver:self
      name:WOApplicationDidFinishLaunchingNotification
      object:self];

  [nc removeObserver:self 
      name:WOApplicationWillTerminateNotification
      object:self];
  
  RELEASE(self->lso);
  RELEASE(self->credToContext);
  RELEASE(self->loginToCred);
  RELEASE(self->registry);
  RELEASE(self->namespaces);
  [super dealloc];
}

/* accessors */

- (int)rssSizeLimit {
  return self->rssSizeLimit;
}

- (NSString *)defaultRequestHandlerClassName {
  return @"NGXmlRpcRequestHandler";
}

- (Class)defaultActionClassForRequest:(WORequest *)_request {
  return [SDXmlRpcAction class];
}

- (WORequestHandler *)handlerForRequest:(WORequest *)_request {
  if ([[_request method] isEqualToString:@"POST"])
    return [self defaultRequestHandler];
  else
    return [self requestHandlerForKey:@"wa"];
}

- (BOOL)hasNoLicenseKey {
  return NO;
}

- (BOOL)cantConnectToDatabase {
  return ![self->lso canConnectToDatabase];
}

/* context cache methods */

- (void)flushContextForLogin:(NSString *)_login {
  NSEnumerator *enumerator;
  NSString     *cred;
  
  enumerator = [[self->loginToCred objectsForKey:_login] objectEnumerator];

  while ((cred = [enumerator nextObject])) {
    [self flushContextForCredentials:cred];
  }
}

- (void)flushContextForCredentials:(NSString *)_creds {
  [self->credToContext removeObjectForKey:_creds];
}

- (LSCommandContext *)contextForCredentials:(NSString *)_creds {
  LSCommandContext *context = nil;
  NSArray          *creds   = nil;

  if ((context = [self->credToContext objectForKey:_creds]) != nil)
    /* found in cache ... */
    return context;
  
  /* assuming basic authentication ... */
  creds  = [[_creds stringByDecodingBase64] componentsSeparatedByString:@":"];
  
  if ([creds count] < 2) {
    [self logWithFormat:@"invalid credentials %@", _creds];
    return nil;
  }
  
  context =
    [[[LSCommandContext alloc] initWithManager:self->lso] autorelease];
  
  if ([context login:[creds objectAtIndex:0]
               password:[creds objectAtIndex:1] isSessionLogEnabled:NO] == NO) {
    [self logWithFormat:@"%s: error during login", __PRETTY_FUNCTION__];
    return nil;
  }
  [self->loginToCred setObject:_creds forKey:[creds objectAtIndex:0]];
  [self->credToContext setObject:context forKey:_creds];
  
  return context;
}

- (OGoContextManager *)lso {
  return self->lso;
}

@end /* SDApplication */

@implementation SDApplication(PrivateMethods)

- (BOOL)_createPIDFile {
  NSProcessInfo *pInfo;
  NSString      *pathName, *fileName, *pid;
  NSFileManager *fm;
  BOOL          isDir;
  
  pInfo = [NSProcessInfo processInfo];
  fm = [NSFileManager defaultManager];
  
  pathName = [[pInfo environment] objectForKey:@"GNUSTEP_USER_ROOT"];
  pathName = [pathName stringByAppendingPathComponent:@"run"];

  if (![fm fileExistsAtPath:pathName isDirectory:&isDir]) {
    [fm createDirectoryAtPath:pathName attributes:nil];
  }
    
  fileName = [NSString stringWithFormat:@"%@.pid",[pInfo processName]];
  fileName = [pathName stringByAppendingPathComponent:fileName];
    
  pid = [NSString stringWithFormat:@"%d", getpid()];

  if (pid) {
    if(![pid writeToFile:fileName atomically:NO]) {
      [self logWithFormat:@"ERROR: couldn't write PID file '%@'",
            fileName];
      return NO;
    }
  }
  return YES;
}

@end /* SDApplication(PrivateMethods) */

@implementation SDApplication(Registration)

/* accessors */

- (NSUserDefaults *)userDefaults {
  return [NSUserDefaults standardUserDefaults];
}

- (NSString *)xmlrpcComponentNamespacePrefix {
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

- (NSString *)xmlrpcUser {
  NSString *userName;

  userName = [[self userDefaults] objectForKey:@"SxRegistryComponentUser"];

  if (userName == nil)
    [self logWithFormat:@"Default 'SxRegistryComponentUser' is not set"];
  return userName;
}

- (NSString *)xmlrpcPassword {
  NSString *password;
  
  password = [[self userDefaults] objectForKey:@"SxRegistryComponentPassword"];

  if (password == nil)
    [self logWithFormat:@"Default 'SxRegistryComponentPassword' is not set"];
  return password;
}

- (NSString *)registryNamespace {
  return @"active.registry";
}

- (SxComponentRegistry *)componentRegistry {
  return [SxComponentRegistry defaultComponentRegistry];
}
  
- (SxBasicAuthCredentials *)credentials {
  SxBasicAuthCredentials *creds;

  creds = [[SxBasicAuthCredentials alloc]
                                   initWithRealm:@"SKYRiX"
                                   userName:[self xmlrpcUser]
                                   password:[self xmlrpcPassword]];
  return AUTORELEASE(creds);
}

- (SxComponent *)registryComponent {
  if (self->registry)
    return self->registry;
  
  self->registry = [[self componentRegistry]
                          getComponent:[self registryNamespace]];
  
  if (self->registry) {
    [[self componentRegistry] addCredentials:[self credentials]];
    self->registry = RETAIN(self->registry);
  }
  return self->registry;
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
                       [[_namespace componentsSeparatedByString:@"."]
                                    lastObject],
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

- (NSString *)_namespaceWithComponentPrefix:(NSString *)_namespace {
  return [[[self xmlrpcComponentNamespacePrefix]
                 stringByAppendingString:@"."]
                 stringByAppendingString:_namespace];
}

- (void)registerAtRegistry:(NSTimer *)_timer {
  SxComponent *component;
  static BOOL reRegistrationIsInitialized = NO;
  int i, retries = 10;

  if ((component = [self registryComponent]) != nil) {
    id result;

    NSEnumerator *namespaceEnum;
    NSString     *namespace;
    
    namespaceEnum = [namespacesToBeRegistered objectEnumerator];
    while((namespace = [namespaceEnum nextObject])) {
      NSString *namespaceToBeRegistered;

      namespaceToBeRegistered = [self _namespaceWithComponentPrefix:namespace];
      
      for (i = 0; i < retries; i++) {  
        [self debugWithFormat:
              @"registering component '%@' at registry",
              namespaceToBeRegistered];
      
        result = [self registerNamespace:namespaceToBeRegistered
                       withComponent:component];
                  
        if (result == nil || [result isKindOfClass:[NSException class]]) {
          if (i < retries) {
            [self logWithFormat:
                  @"ERROR: registering namespace '%@' failed, retrying.",
                  namespaceToBeRegistered];
          }
          else {
            [self logWithFormat:
                  @"ERROR: registering namespace '%@' failed, giving up.",
                  namespaceToBeRegistered];
            [self terminate];
            return;
          }
        }
        else {
          if (!reRegistrationIsInitialized) {
            reRegistrationIsInitialized = YES;
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
    NSEnumerator *namespaceEnum;
    NSString     *namespace;
    
    namespaceEnum = [namespacesToBeRegistered objectEnumerator];
    while((namespace = [namespaceEnum nextObject])) {
      NSString *namespaceToBeRegistered;
      
      namespaceToBeRegistered = [self _namespaceWithComponentPrefix:namespace];
    
      [self debugWithFormat:
            @"unregistering namespace '%@' from registry",
            namespaceToBeRegistered];
      if (![self unregisterNamespace:namespaceToBeRegistered
                 withComponent:component]) {
        [self logWithFormat:@"ERROR: unregistering namespace '%@' failed.",
              namespaceToBeRegistered];
      }
    }
  }
  else {
    [self logWithFormat:@"ERROR: no registry component found !"];
  }
}
  
@end /* SDApplication(Registration) */
 
