/*
  Copyright (C) 2002-2004 SKYRIX Software AG

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

#include "ZideStore.h"
#include "SxAuthenticator.h"

#include <ZSFrontend/SxUserFolder.h>
#include <ZSFrontend/SxPublicFolder.h>

#include <LSFoundation/OGoContextManager.h>
#include <NGObjWeb/SoProductRegistry.h>
#include <NGObjWeb/SoObjectRequestHandler.h>
#include <EOControl/EOQualifier.h>
#include "common.h"

@interface ZideStore(WCAP)
- (id)lookupWCAPCommand:(NSString *)_key inContext:(id)_ctx;
- (id)wcapCheckIDInContext:(id)_ctx;
@end

@implementation ZideStore

- (NSArray *)zsProductSearchPathes {
  static NSArray *searchPathes = nil;
  NSMutableArray *ma;
  NSDictionary   *env;
  id tmp;
  
  if (searchPathes != nil)
    return searchPathes;
  
  env = [[NSProcessInfo processInfo] environment];
  ma  = [NSMutableArray arrayWithCapacity:6];

#if COCOA_Foundation_LIBRARY
  tmp = NSSearchPathForDirectoriesInDomains(NSAllLibrariesDirectory,
                                            NSAllDomainsMask,
                                            YES);
  if ([tmp count] > 0) {
    NSEnumerator *e;
      
    e = [tmp objectEnumerator];
    while ((tmp = [e nextObject])) {
      tmp = [tmp stringByAppendingPathComponent:@"ZideStore-1.3"];
      if (![ma containsObject:tmp])
        [ma addObject:tmp];
    }
  }
#else
  if ((tmp = [env objectForKey:@"GNUSTEP_PATHPREFIX_LIST"]) == nil)
    tmp = [env objectForKey:@"GNUSTEP_PATHLIST"];
  
  tmp = [tmp componentsSeparatedByString:@":"];
  if ([tmp count] > 0) {
    NSEnumerator *e;
      
    e = [tmp objectEnumerator];
    while ((tmp = [e nextObject])) {
      tmp = [tmp stringByAppendingPathComponent:@"Library/ZideStore-1.3"];
      if (![ma containsObject:tmp])
        [ma addObject:tmp];
    }
  }
#endif
  
  [ma addObject:@"/usr/local/lib/zidestore-1.3/"];
  [ma addObject:@"/usr/lib/zidestore-1.3/"];
  
  searchPathes = [ma copy];
    
  if ([searchPathes count] == 0)
    NSLog(@"%s: no search pathes were found !", __PRETTY_FUNCTION__);
  
  return searchPathes;
}

- (void)loadZideStoreProducts {
  SoProductRegistry *registry = nil;
  NSFileManager *fm;
  NSEnumerator  *pathes;
  NSString      *lpath;
  
  registry = [SoProductRegistry sharedProductRegistry];
  fm       = [NSFileManager defaultManager];
  
  pathes = [[self zsProductSearchPathes] objectEnumerator];
  while ((lpath = [pathes nextObject])) {
    NSEnumerator *productNames;
    NSString *productName;

    productNames = [[fm directoryContentsAtPath:lpath] objectEnumerator];
    
    while ((productName = [productNames nextObject])) {
      NSString *bpath;
      
      bpath = [lpath stringByAppendingPathComponent:productName];
      [self logWithFormat:@"register ZideStore product: %@", 
              [bpath lastPathComponent]];
      [registry registerProductAtPath:bpath];
    }
  }
  
  if (![registry loadAllProducts])
    [self logWithFormat:@"WARNING: could not load all products !"];
}

- (id)init {
  if ((self = [super init])) {
    WORequestHandler *rh;
    NSString *tmp;
    
    [self loadZideStoreProducts];

    /* setup request handlers */
    
    rh = [[NSClassFromString(@"OWViewRequestHandler") alloc] init];
    [self registerRequestHandler:rh
          forKey:[WOApplication componentRequestHandlerKey]];
    [rh release];
    
    rh = [self requestHandlerForKey:
		 [WOApplication directActionRequestHandlerKey]];
    [self setDefaultRequestHandler:rh];
    
    /* Object Publishing */
    rh = [[SoObjectRequestHandler alloc] init];
    [self setDefaultRequestHandler:rh];
    [rh release];

    /* setup some WebDAV type mappings required for Evolution */
    
    if ([EOQualifier respondsToSelector:
                       @selector(registerValueClass:forTypeName:)]) {
      [EOQualifier registerValueClass:NSClassFromString(@"dateTime")
                   forTypeName:@"dateTime"];
      [EOQualifier registerValueClass:NSClassFromString(@"dateTime")
                   forTypeName:@"dateTime.tz"];
    }
    else
      [self logWithFormat:@"WARNING: you should update your libEOControl!"];
    
    /* vMem size check - default is 200MB */
    
    tmp = [[NSUserDefaults standardUserDefaults] valueForKey:@"SxVMemLimit"];
    self->vMemSizeLimit = (tmp != nil)
      ? [tmp intValue]
      : 200;
    if (self->vMemSizeLimit > 0) {
      [self logWithFormat:
            @"vMem Size check enabled: shutting down app when vMem > %d MB",
            self->vMemSizeLimit];
    }
  }
  return self;
}

- (void)dealloc {
  [self->knownLogins release];
  [self->lso         release];
  [super dealloc];
}

/* lookup the SKYRiX entry point */

- (id)lso {
  if (self->lso == nil)
    self->lso = [[OGoContextManager defaultManager] retain];
  return self->lso;
}
- (id)lsoInContext:(WOContext *)_ctx {
  return [self lso];
}

/* authenticator */

- (id)authenticatorInContext:(WOContext *)_ctx {
  return [SxAuthenticator sharedAuthenticator];
}

/* login info */

- (BOOL)_refetchLoginsInContext:(id)_ctx {
  LSCommandContext *cmdctx;
  SxAuthenticator  *auth;
  NSArray *accounts;
  NSArray *logins;
  
  if (_ctx == nil) 
    _ctx = [(WOApplication *)[WOApplication application] context];
  
  if ((auth = [self authenticatorInContext:_ctx]) == nil) {
    [self logWithFormat:@"ERROR: got no authenticator for context: %@", _ctx];
    return NO;
  }
  if ((cmdctx = [auth commandContextInContext:_ctx]) == nil) {
    [self logWithFormat:@"ERROR: cannot fetch logins, no cmdctx!"];
    return NO;
  }
  
  [self debugWithFormat:@"refetching logins ..."];
  
  // TODO: this fetches all attrs of the account, need to support attributes!
  accounts = [cmdctx runCommand:@"account::get", 
                       @"returnType", 
                       [NSNumber numberWithInt:LSDBReturnType_ManyObjects],
                       nil];
  
  logins   = [accounts valueForKey:@"login"];
  [self debugWithFormat:@"  fetched %d known logins ...", [logins count]];
  
  if (self->knownLogins == nil)
    self->knownLogins = [[NSMutableSet alloc] initWithCapacity:1024];
  
  if (logins)
    [self->knownLogins addObjectsFromArray:logins];
  
  return YES;
}

/* folder creation */

- (SxUserFolder *)userFolderForKey:(NSString *)_login inContext:(id)_ctx {
  SxUserFolder *home;
  
  if ([_login length] == 0)
    return nil;
  if ((home = [[SxUserFolder alloc] initWithLogin:_login]) == nil) {
    [self debugWithFormat:@"did not create userfolder for key: '%@'", _login];
    return nil;
  }
  
  if (![self->knownLogins containsObject:_login]) {
    BOOL ok;

    ok = [self _refetchLoginsInContext:_ctx];
    
    // TODO: if we have not authenticated, we cannot get a context ...
    if (![self->knownLogins containsObject:_login] && ok) {
      [self logWithFormat:@"cannot create userfolder, not a login name: '%@'"
              , _login];
      return nil;
    }
  }
  
  //[self logWithFormat:@"made user folder: %@", home];
  return [home autorelease];
}
- (SxUserFolder *)userFolderForKey:(NSString *)_login {
  // DEPRECATED
  return [self userFolderForKey:_login inContext:nil];
}

- (SxPublicFolder *)publicFolder:(NSString *)_name container:(id)_c {
  return [[[SxPublicFolder alloc] initWithName:_name inContainer:_c]
           autorelease];
}
- (id)freeBusyInContext:(id)_ctx {
  id cmd = [[NSClassFromString(@"SxFreeBusy") alloc] init];
  return [cmd autorelease];
}
- (id)images:(NSString *)_name container:(id)_c {
  return [[[NSClassFromString(@"SxImageHandler") alloc] 
            initWithName:_name inContainer:_c]
            autorelease];
}

/* define the root SoObject */

// TODO: should scan for valid usernames periodically and cache them
//       rescan on miss (but avoid DOS)

- (BOOL)hasName:(NSString *)_key inContext:(id)_ctx {
  if ([super hasName:_key inContext:_ctx])
    return YES;
  if ([[_key lowercaseString] isEqualToString:@"public"])
    return YES;

  if ([_key hasSuffix:@".wcap"])
    return YES;
  
  // TODO: should check valid usernames
  return NO;
}

- (BOOL)isRootKey:(NSString *)_key {
  if ([_key isEqualToString:@"exchange"])  return YES;
  if ([_key isEqualToString:@"zidestore"]) return YES;
  return NO;
}
- (id)lookupName:(NSString *)_key inContext:(id)_ctx acquire:(BOOL)_flag {
  id obj;
  
  if ([_key isEqualToString:@"check_id.wcap"])
    return [self wcapCheckIDInContext:_ctx];
  
  if ([_key hasSuffix:@".wcap"]) {
    NSString *sid;
    
    sid = [[(WOContext *)_ctx request] formValueForKey:@"id"];
    if ([sid length] > 0) {
      /* need to forward command to appropriate user-folder */
      return [self lookupWCAPCommand:_key inContext:_ctx];
    }
  }
  
  /* first check attributes directly bound to the application */
  if ((obj = [super lookupName:_key inContext:_ctx acquire:_flag]))
    return obj;
  
  if ([[_key lowercaseString] isEqualToString:@"public"])
    return [self publicFolder:_key container:self];
  
  if ([self isRootKey:_key])
    return self;
  
  if ([_key isEqualToString:@"images"])
    return [self images:_key container:self];

  if ([_key isEqualToString:@"freebusy"])
    return [self freeBusyInContext:_ctx];
  
  return [self userFolderForKey:_key inContext:_ctx];
}

- (id)rootObjectInContext:(id)_ctx {
  return self;
}

/* root actions */

- (id)GETAction:(id)_ctx {
  return [self pageWithName:@"SxRootPage" inContext:_ctx];
}

/* renderer */

- (id)rendererForObject:(id)_obj inContext:(WOContext *)_ctx {
  NSString *uri;
  NSRange r;
  
  if ([_obj isKindOfClass:[NSException class]])
    return [super rendererForObject:_obj inContext:_ctx];

  if (![[[_ctx request] method] isEqualToString:@"GET"])
    return [super rendererForObject:_obj inContext:_ctx];
  
  uri = [[_ctx request] uri];
  
  /* cut off query parameters */
  
  r = [uri rangeOfString:@"?"];
  if (r.length > 0) 
    uri = [uri substringToIndex:r.location];
  else {
    /* OSX passes the "?" escaped */
    r = [uri rangeOfString:@"%3f"];
    if (r.length > 0) 
      uri = [uri substringToIndex:r.location];
  }
  
  /* check fixed extensions */
  
  if ([[_ctx request] isSoWCAPRequest]) {
    static id r = nil;
    if (r == nil) r = [[NSClassFromString(@"SoWCAPRenderer") alloc] init];
    return r;
  }
  if ([uri hasSuffix:@".vcf"]) {
    static id r = nil;
    if (r == nil) r = [[NSClassFromString(@"OLVCardRenderer") alloc] init];
    return r;
  }
  if ([uri hasSuffix:@".EML"]) {
    static id r = nil;
    if (r == nil) r = [[NSClassFromString(@"OLMailRenderer") alloc] init];
    return r;
  }
  return [super rendererForObject:_obj inContext:_ctx];
}

/* exception handling */

- (WOResponse *)handleException:(NSException *)_exc
  inContext:(WOContext *)_ctx
{
  printf("EXCEPTION: %s\n", [[_exc description] cString]);
  abort();
}

- (void)checkIfDaemonHasToBeShutdown {
  unsigned int limit, vmem;
  
  if ((limit = self->vMemSizeLimit) == 0)
    return;

  vmem = [[NSProcessInfo processInfo] virtualMemorySize]/1048576;

  if (vmem > limit) {
    [self logWithFormat:
          @"terminating app, vMem size limit (%d MB) has been reached"
          @" (currently %d MB)",
          limit, vmem];
    [self terminate];
  }
}

- (BOOL)shouldUseSimpleHTTPParserForTransaction:(id)_tx {
  /* 
     Always use the simple parser for ZideStore, ignore
     WOHttpTransactionUseSimpleParser default.
  */
  return YES;
}

- (WOResponse *)dispatchRequest:(WORequest *)_request {
  WOResponse *resp;

  resp = [super dispatchRequest:_request];

  if (![self isTerminating]) {
    [[NSRunLoop currentRunLoop] performSelector:
                                @selector(checkIfDaemonHasToBeShutdown)
                                target:self
                                argument:nil
                                order:1
                                modes:[NSArray arrayWithObject:
                                               NSDefaultRunLoopMode]];
  }
  return resp;
}

@end /* ZideStore */

int main(int argc, char **argv, char **env) {
  NSAutoreleasePool *pool;

  pool = [[NSAutoreleasePool alloc] init];
#if LIB_FOUNDATION_LIBRARY
  [NSProcessInfo initializeWithArguments:argv count:argc environment:env];
#endif
  [NGBundleManager defaultBundleManager];
  
  WOWatchDogApplicationMain(@"ZideStore", argc, (void*)argv);

  [pool release];
  return 0;
}
