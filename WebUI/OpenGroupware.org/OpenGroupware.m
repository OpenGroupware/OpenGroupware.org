/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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

#if GNU_RUNTIME
#  include <objc/sarray.h>
#endif

#include "OpenGroupware.h"
#include "SoOGoAuthenticator.h"
#include <NGObjWeb/SoProductRegistry.h>
#include <OGoFoundation/OGoSession.h>
#include "common.h"
#include <LSFoundation/OGoContextManager.h>
#include <NGObjWeb/OWViewRequestHandler.h>
#include <NGHttp/NGHttp.h>

@interface NSObject(OpenGroupware)
- (void)registerDefaults;
+ (void)printStatistics;
@end

@interface OpenGroupware(CTI)
- (NSArray *)availableCTIDialers;
@end

@interface WOApplication(JS)
- (void)registerClass:(Class)_class forScriptedComponent:(NSString *)_comp;
- (Class)classForScriptedComponent:(NSString *)_comp;
@end

@interface WOComponent(PageRestoration)
- (void)initRestoreWithRequest:(WORequest *)_request;
@end

@implementation OpenGroupware

static BOOL UseRefreshPageForExternalLink = NO;
static BOOL coreOn                    = NO;
static BOOL logBundleLoading          = NO;
static BOOL loadWebUIBundlesOnStartup = YES;
static NSString *FHSOGoBundleDir = @"lib/opengroupware.org-1.0a/";

+ (int)version {
  return [super version];
}

+ (void)initialize {
  static BOOL isInitialized = NO;
  NSUserDefaults *ud;
  NSString *p;

  if (isInitialized)
    return;
  isInitialized = YES;
  
  NSAssert1([super version] == 6,
            @"invalid superclass (WOApplication) version %i !",
            [super version]);
  
  ud = [NSUserDefaults standardUserDefaults];
  
  /* register app defaults */
  
  p = [[NSBundle mainBundle] pathForResource:@"Defaults" ofType:@"plist"];
  if (p) {
    NSDictionary *d;
    
    if ((d = [NSDictionary dictionaryWithContentsOfFile:p]))
      [ud registerDefaults:d];
  }
  
  /* load values of defaults */

  logBundleLoading = [ud boolForKey:@"OGoLogBundleLoading"];
  coreOn           = [ud boolForKey:@"OGoCoreOnException"];
  UseRefreshPageForExternalLink =
    [ud boolForKey:@"UseRefreshPageForExternalLink"];
}

- (void)loadBundlesOfType:(NSString *)_type inPath:(NSString *)_p {
  // TODO: use NGBundleManager+OGo in LSFoundation
  //       => cannot ATM, because we also register in the product registry
  SoProductRegistry *reg;
  NGBundleManager *bm;
  NSFileManager   *fm;
  NSEnumerator *e;
  NSString     *p;
  
  reg = [SoProductRegistry sharedProductRegistry];
  
  if (logBundleLoading)
    NSLog(@"  load bundles of type '%@' in path: '%@'", _type, _p);
  bm = [NGBundleManager defaultBundleManager];
  fm = [NSFileManager defaultManager];
  e  = [[fm directoryContentsAtPath:_p] objectEnumerator];
  
  while ((p = [e nextObject])) {
    NSBundle *bundle;
    
    if (![[p pathExtension] isEqualToString:_type])
      continue;
    p = [_p stringByAppendingPathComponent:p];
    
    if ((bundle = [bm bundleWithPath:p]) == nil)
      continue;
    
    if (![bm loadBundle:bundle]) {
      NSLog(@"could not load bundle: %@", bundle);
      continue;
    }
    
    if (logBundleLoading) {
      NSLog(@"    did load bundle: %@", 
	    [[bundle bundlePath] lastPathComponent]);
    }
    
    [reg registerProductBundle:bundle];
  }
}
- (NSString *)bundlePathSpecifier {
  return [[NSUserDefaults standardUserDefaults]
	                  stringForKey:@"OGoBundlePathSpecifier"];
}
- (void)preloadBundles {
  NGBundleManager *bm;
  NSEnumerator *e;
  NSString     *p;
  NSArray      *pathes;
  NSString     *OGoBundlePathSpecifier;
  NSArray      *oldPathes;
  
  OGoBundlePathSpecifier = [self bundlePathSpecifier];

  /* find pathes */
  
  // TODO: use "Skyrix5" for Skyrix5 (patch in migration script)
  pathes = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
					       NSAllDomainsMask,
					       YES);
  if ([FHSOGoBundleDir length] > 0) {
    // TODO: should be some search path, eg LD_LIBRARY_SEARCHPATH?
    p      = [@"/usr/local/" stringByAppendingPathComponent:FHSOGoBundleDir];
    p      = [p stringByAppendingPathComponent:@"webui/"];
    pathes = [pathes arrayByAddingObject:p];
    p      = [@"/usr/" stringByAppendingString:FHSOGoBundleDir];
    p      = [p stringByAppendingPathComponent:@"webui/"];
    pathes = [pathes arrayByAddingObject:p];
  }
  
  /* temporarily patch bundle search path */
  
  bm = [NGBundleManager defaultBundleManager];
  oldPathes = [[bm bundleSearchPaths] copy];
  if ([pathes count] > 0) {
    /* add default fallback */
    [bm setBundleSearchPaths:[pathes arrayByAddingObjectsFromArray:oldPathes]];
  }
  
  /* load WebUI bundles */
  
  if (loadWebUIBundlesOnStartup) {
    if (logBundleLoading) NSLog(@"load WebUI plugins ...");
    e = [pathes objectEnumerator];
    while ((p = [e nextObject])) {
      p = [p stringByAppendingPathComponent:OGoBundlePathSpecifier];
      [self loadBundlesOfType:@"lso" inPath:p];
      p = [p stringByAppendingPathComponent:@"WebUI"];
      [self loadBundlesOfType:@"lso" inPath:p];
    }
  }
  
  /* unpatch bundle search path */
  
  [bm setBundleSearchPaths:oldPathes];
  [oldPathes release];
  
  /* load SoProducts */
  
  [[SoProductRegistry sharedProductRegistry] loadAllProducts];
}

- (void)_setVersion {
  NSString *cvsTag;
  NSArray  *tagComponents;

  cvsTag = [[NSUserDefaults standardUserDefaults] stringForKey:@"CVS-Tag"];
  tagComponents = [cvsTag componentsSeparatedByString:@" "];
  
  if ([tagComponents count] > 1) {
    cvsTag        = [tagComponents objectAtIndex:1];
    tagComponents = [cvsTag componentsSeparatedByString:@"-"];

    if ([tagComponents count] == 3) {
      self->version = [[NSString alloc] initWithFormat:@"%@ %@",
                                [tagComponents objectAtIndex:1],
                                [tagComponents objectAtIndex:2]];
    }
    else if ([tagComponents count] > 6) {
      self->version = [[NSString alloc] initWithFormat:@"%@.%@ %@ (%@-%@-%@)",
                                [tagComponents objectAtIndex:1],
                                [tagComponents objectAtIndex:2],
                                [tagComponents objectAtIndex:3],
                                [tagComponents objectAtIndex:4],
                                [tagComponents objectAtIndex:5],
                                [tagComponents objectAtIndex:6]];
    }
  }
  
  if (self->version == nil)
    self->version = @"5";
}

- (void)_applyMinimumActiveSessionCount {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  id  o;
  int i;

  if ((o = [ud objectForKey:@"OGoMinimumActiveSessionCount"]))
    i = [o intValue];
  else
    i = 1;

  [self setMinimumActiveSessionsCount:i];
}

- (NSNotificationCenter *)notificationCenter {
  return [NSNotificationCenter defaultCenter];
}

- (void)_setupRequestHandlers {
  WORequestHandler *rh;
  
  /* use WODirectActionRequestHandler as default request handler */
  
  rh = [self requestHandlerForKey:
	       [WOApplication directActionRequestHandlerKey]];
  [self setDefaultRequestHandler:rh];
  
  rh = [[NSClassFromString(@"OWViewRequestHandler") alloc] init];
  [self registerRequestHandler:rh
	forKey:[WOApplication componentRequestHandlerKey]];
  [rh release]; rh = nil;
  
  if ((rh = [[NSClassFromString(@"SoObjectRequestHandler") alloc] init])) {
    [self registerRequestHandler:rh forKey:@"so"];
    [self registerRequestHandler:rh forKey:@"dav"];
  }
}

- (void)_setupResourceManager {
  OGoResourceManager *rm;
  
  rm = [OGoResourceManager alloc]; /* seperate line to keep gcc happy */
  rm = [rm initWithPath:[self path]];
  NSAssert(rm, @"could not create resource manager!");
  [self setResourceManager:(WOResourceManager *)rm];
  [rm release]; rm = nil;
}

- (id)init {
  if ((self = [super init])) {
    NSUserDefaults *ud;
    
    ud = [NSUserDefaults standardUserDefaults];
    
    [[self notificationCenter]
      addObserver:self selector:@selector(scriptClassNeeded:)
      name:@"WOScriptClassNeededForComponent" object:nil];
    
    [self setPageRefreshOnBacktrackEnabled:
            [[ud objectForKey:@"LSPageRefreshOnBacktrack"] boolValue]];

    [self _applyMinimumActiveSessionCount];

    /* setup LSOffice server */
    
    if ((self->lso = [[OGoContextManager defaultManager] retain]) == nil) {
      [self logWithFormat:@"Could not setup OGoContextManager "
            @"(DB probably not yet configured)!"];
    }
    
    [self _setupRequestHandlers];
    [self _setupResourceManager];
    
    /* load configuration */
    
    self->reloadConfig =
      [[ud objectForKey:@"LSReloadConfiguration"] boolValue];
    if (self->reloadConfig)
      [self logWithFormat:@"WARNING: reload-config is turned on."];
    
    [self _setVersion];
    
#if DEBUG
    [self logWithFormat:@"CTI Dialers: %@",
            [[self availableCTIDialers] componentsJoinedByString:@","]];
#endif

    /* load WebUI bundles */
    [self preloadBundles];
    
    /* force initial connect */
    if ([self->lso isLoginAuthorized:@"root" password:@""])
      [self logWithFormat:@"root has no password, you need to assign one!"];
    
    [self logWithFormat:@"OpenGroupware.org instance initialized."];
  }
  return self;
}

- (void)dealloc {
  [[self notificationCenter] removeObserver:self];
  [self->requestDict  release];
  [self->requestStack release];
  [self->version      release];
  [self->lso          release];
  [super dealloc];
}

- (void)sleep {
#if DEBUG && PRINT_NSSTRING_STATISTICS
  if ([NSString respondsToSelector:@selector(printStatistics)])
    [NSString printStatistics];
#endif
  
#if DEBUG && PRINT_OBJC_STATISTICS
extern int __objc_selector_max_index;
  printf("nbuckets=%i, nindices=%i, narrays=%i, idxsize=%i\n",
nbuckets, nindices, narrays, idxsize);
  printf("maxsel=%i\n", __objc_selector_max_index);
#endif
  
  [super sleep];
}

- (void)scriptClassNeeded:(NSNotification *)_notification {
  NSString *componentName;
  
  componentName = [_notification object];
  [self logWithFormat:@"Lookup Component: %@", componentName];
  
  [self registerClass:NSClassFromString(@"SkyJSComponent")
        forScriptedComponent:componentName];
}

- (id)jsContext {
  return nil;
}

- (BOOL)hasLogTab {
  return YES;
}


/* sessions */

- (WOResponse *)handleSessionCreationErrorInContext:(WOContext *)_ctx {
  [self logWithFormat:@"%@: failed to create session, exiting.", self];
  return nil;
}

- (WOResponse *)handlePageRestorationErrorInContext:(WOContext *)_ctx {
  OGoSession    *sn;
  OGoNavigation *nav;
  WOComponent   *component;

  [self logWithFormat:
          @"instance failed to restore page (ctx=%@) ...",
          self, _ctx];
  
  if ((sn = (OGoSession *)[_ctx session]) == nil) {
    [self debugWithFormat:@"couldn't find session .."];
    return [super handlePageRestorationErrorInContext:_ctx];
  }
  if ((nav = [sn navigation]) == nil) {
    [self debugWithFormat:@"couldn't find navigation in session %@ ..", sn];
    return [super handlePageRestorationErrorInContext:_ctx];
  }
  
  if ((component = [nav activePage]) == nil) {
    [self debugWithFormat:@"couldn't find active page in navigation %@ ..",sn];
    return [super handlePageRestorationErrorInContext:_ctx];
  }
  
  [self logWithFormat:@"  delivering last navigation page .."];
  return [component generateResponse];
}

- (WOResponse *)_checkForMailPopup:(WOContext *)_ctx {
  WORequest  *req;

  req = [_ctx request];

  if ([[req requestHandlerPath] isEqualToString:@"viewMailsPopUp"]) {
    WOResponse *resp;
    
    resp = [WOResponse responseWithRequest:req];
    [resp appendContentString:
          @"<html><head><title>SKYRiX Mails</title>\n"
          @"<body vlink=\"#000000\" bgcolor=\"#FFECD0\" link=\"#000000\" "
          @"font=\"#000000\">\n"
          @"<center> <b>Your session expired.</b></center>\n"
          @"</body></html>"];

    [resp setHeader:@"text/html; charset=iso-8859-1"
          forKey:@"content-type"];
    
    return resp;
  }
  return nil;
}

- (WOResponse *)sxRestorePageInContext:(WOContext *)_ctx {
  /* activate main page with the given hidden parameters */
  WOComponent *page;
  WOResponse  *response;
  WOCookie    *cookie;
  WORequest   *req;
  NSString    *pageName, *loginName;
  
  req       = [_ctx request];
  pageName  = [req formValueForKey:@"restorePageName"];
  loginName = [req formValueForKey:@"loginName"];
  
  if ([pageName length] == 0 || [loginName length] == 0)
    return nil;
      
  page = [self pageWithName:@"Main"];
  
  [page initRestoreWithRequest:req];
  
  response = [page generateResponse];
  
  cookie = [WOCookie cookieWithName:[self name]
                     value:@"nil"
                     path:[_ctx urlSessionPrefix]
                     domain:nil
                     expires:[NSDate dateWithTimeIntervalSinceNow:(-600.0)]
                     isSecure:NO];
  [response addCookie:cookie];
  [response setHeader:@"text/html; charset=iso-8859-1" forKey:@"content-type"];
  return response;
}

- (NSString *)locationForSessionRedirectInContext:(WOContext *)_ctx {
  /* TODO: split up, maybe make a category on WORequest? */
  WORequest *request;
  NSString  *jumpTo, *rhkey;
  BOOL      keepURL;
  
  request = [_ctx request];
  rhkey   = [request requestHandlerKey];
  keepURL = NO;
  
  if ([[request method] isEqualToString:@"POST"])
    keepURL = NO; // never keep POST links
  else if ([rhkey isEqualToString:
                    [WOApplication directActionRequestHandlerKey]])
    keepURL = YES;
  else if ([rhkey isEqualToString:@"wa"])
    keepURL = YES;
  else
    keepURL = NO;
  
  // TODO: implement keep-url
  //       this needs to strip out the session info (wosid) from the URL
  if (keepURL) {
    NSString *lpath;
    NSString *query;
    NSRange  r;
    
    jumpTo = [request uri];
    r = [jumpTo rangeOfString:@"?"];
    if (r.length > 0) {
      lpath = [jumpTo substringToIndex:r.location];
      query = [jumpTo substringFromIndex:(r.location + r.length)];
    }
    else {
      lpath = jumpTo;
      query = nil;
    }
    
    if ([query length] > 0) {
      NSEnumerator   *e;
      NSMutableArray *t = nil;
      NSString       *kvpair;
      
      e = [[query componentsSeparatedByString:@"&"] objectEnumerator];
      while ((kvpair = [e nextObject])) {
          // TODO: not really correct
          if ([kvpair hasPrefix:WORequestValueSessionID])
            continue;
          if ([kvpair hasPrefix:WORequestValueInstance])
            continue;

          if (t == nil) t = [[NSMutableArray alloc] initWithCapacity:8];
          [t addObject:kvpair];
      }
      query = [t componentsJoinedByString:@"&"];
      [t release]; t = nil;
    }
    
    jumpTo = lpath;
    if ([query length] > 0) {
      jumpTo = [[jumpTo stringByAppendingString:@"?"]
                        stringByAppendingString:query];
    }
  }
  else {
    jumpTo = [[_ctx applicationURL] absoluteString];
    jumpTo = [[request adaptorPrefix] stringByAppendingString:jumpTo];
  }
  return jumpTo;
}

- (WOResponse *)handleSessionRestorationErrorInContext:(WOContext *)_ctx {
  WOResponse *response;
  WOCookie   *cookie;
  NSString   *jumpTo;
  
  if ((response = [self _checkForMailPopup:_ctx]))
    return response;
  
  if ((response = [self sxRestorePageInContext:_ctx]))
    return response;
  
  jumpTo = [self locationForSessionRedirectInContext:_ctx];
  [self logWithFormat:
          @"%@ instance failed to restore session (ctx=%@):\n"
          @"  redirecting to: %@",
          self, _ctx, jumpTo];
  
  if ((response = [_ctx response]) == nil)
    response = [WOResponse responseWithRequest:[_ctx request]];
  
  [response setStatus:302];
  [response setHeader:jumpTo forKey:@"location"];
  
  [response appendContentString:
              @"<html><head><title>Session Restoration Error</title></head>"
              @"<script>"
              @"  function timer() {\n setTimeout(\"gotoPage()\", 2);\n }\n"
              @"  function gotoPage() {\n location.href='"];
  [response appendContentString:jumpTo];
  [response appendContentString:@"'; }\n"];

  [response appendContentString:
              @"</script>"
              @"<body onLoad='timer()'>"
              @"Session restoration failed: "];

  [response appendContentHTMLString:
              [[_ctx request] cookieValueForKey:[self name]]];
  [response appendContentString:
              @"  <br />\n"
              @"  Page is going to be reloaded in some seconds ..\n"
              @"</body>"];
  
  cookie = [WOCookie cookieWithName:[self name]
                     value:@"nil"
                     path:[_ctx urlSessionPrefix]
                     domain:nil
                     expires:[NSDate dateWithTimeIntervalSinceNow:(-600.0)]
                     isSecure:NO];
  [response addCookie:cookie];
  
  return response;
}

- (BOOL)isRefusingNewSessions {
  return (self->sessionCount > 0) ? YES : NO;
}

- (WOSession *)_createSession {
  OGoSession *session = nil;

  /* Note: DO NOT AUTORELEASE the session !!! */
  /* 
     TODO: if all references to LSWSession are removed, replace that call
           with OGoSession.
  */
  if ((session = [[LSWSession alloc] init]) == nil)
    return nil;
  
  [self logWithFormat:@"%@: created session: %@", self, session];
  self->sessionCount++;
  return session;
}

- (WOSession *)createSessionForRequest:(WORequest *)_request {
  return [self _createSession];
}

- (BOOL)reloadConfigurations {
  return self->reloadConfig;
}

#if WITH_URL_COMPONENTS
- (WOComponent *)pageWithURL:(NSURL *)_url inContext:(WOContext *)_ctx {
  return nil;
}
#endif

- (WOComponent *)pageWithName:(NSString *)_name inContext:(WOContext *)_ctx {
  OGoSession *sn        = nil;
  id         p          = nil;
#if WITH_URL_COMPONENTS
  NSURL      *url;
#endif
  
  if (![_ctx hasSession])
    return [super pageWithName:_name inContext:_ctx];
    
  /* lookup persistent components */
    
  if ((sn = (OGoSession *)[_ctx session]) != nil) {
    if ((p = [[sn pComponents] valueForKey:_name]) != nil)
      return p;
  }
    
#if WITH_URL_COMPONENTS
  /* lookup URL components */

  if ((url = [NSURL URLWithString:_name])) {
    [self debugWithFormat:@"Lookup component for URL (str=%@): %@",
	    _name, url];
    return [self pageWithURL:url inContext:_ctx];
  }
#endif
  return [super pageWithName:_name inContext:_ctx];
}

- (OGoContextManager *)lsoServer {
  return self->lso;
}

/* validation */

- (BOOL)hideValidationIssue:(NSException *)_issue {
  /* hacks to filter out 'expected' validation issues */
  NSString *r;
  
  r = [_issue reason];
  if ([r hasPrefix:@"Unexpected"]) {
    /* Unexpected end tag : nobr */
    if ([r rangeOfString:@"nobr"].length > 0)
      return YES;
  }
  return NO;
}

/* timezones */

- (NSArray *)allTimeZones {
  static NSArray *zones = nil;
  NSArray *zoneNames;
  int     i, count;
  
  if (zones)
    return zones;
    
  zoneNames = [[NSUserDefaults standardUserDefaults]
                               arrayForKey:@"LSTimeZones"];
  if ([zoneNames count] == 0) {
    zoneNames = [NSArray arrayWithObject:@"GMT"];
    [self logWithFormat:@"Note: no LSTimeZones default set, using just GMT!"];
  }

  count = [zoneNames count];
  zones = [[NSMutableArray alloc] initWithCapacity:count];
  for (i = 0; i < count; i++) {
    NSTimeZone *tzone;
    
    tzone = [NSTimeZone timeZoneWithAbbreviation:[zoneNames objectAtIndex:i]];
    if (tzone)
      [(NSMutableArray *)zones addObject:tzone];
  }
  zones = [[zones autorelease] copy];
  return zones;
}

- (NSString *)cvsVersion {
  return self->version;
}
- (NSString *)version {
  return [self cvsVersion];
}

/* tracking bundles */

- (void)bundleDidLoad:(NSNotification *)_notification {
  NSBundle *bundle;
  if (!logBundleLoading) return;
  
  bundle = [_notification object];
  [self logWithFormat:@"loaded bundle %@.", [bundle bundlePath]];
}

/* exception handling */

- (WOResponse *)handleException:(NSException *)_exc 
  inContext:(WOContext *)_ctx 
{
  WORequest  *rq = [_ctx request];
  WOResponse *r  = nil;
  
  if (_ctx == nil) {
    [self logWithFormat:@"%@: caught (without context):\n  %@.", self, _exc];
    if (coreOn) abort();
    r = [super handleException:_exc inContext:_ctx];
  }
  else if (rq == nil) {
    [self logWithFormat:@"%@: caught (without request):\n  %@.", self, _exc];
    if (coreOn) abort();
    r = [super handleException:_exc inContext:_ctx];
  }
  else {
    [self logWithFormat:@"%@: caught:\n  %@\nin context:\n  %@.",
            self, _exc, _ctx];
    if (coreOn) abort();
    
    r = [[(WOResponse *)[WOResponse alloc] initWithRequest:rq] autorelease];
    if (r == nil)
      NSLog(@"%@: could not create response !", self);
    
    [r setHeader:@"no-cache"  forKey:@"cache-control"];
    [r setHeader:@"text/html" forKey:@"content-type"];
    
    [r appendContentString:@"<pre>\n"];
    [r appendContentHTMLString:@"Application Server caught exception:\n\n"];
    [r appendContentHTMLString:@"  session: "];
    [r appendContentHTMLString:[[_ctx session] sessionID]];
    [r appendContentHTMLString:@"\n"];
    [r appendContentHTMLString:@"  element: "];
    [r appendContentHTMLString:[_ctx elementID]];
    [r appendContentHTMLString:@"\n"];
    [r appendContentHTMLString:@"  context: "];
    [r appendContentHTMLString:[_ctx description]];
    [r appendContentHTMLString:@"\n"];
    [r appendContentHTMLString:@"  request: "];
    [r appendContentHTMLString:[rq description]];
    [r appendContentHTMLString:@"\n\n"];
    [r appendContentHTMLString:@"  class:   "];
    [r appendContentHTMLString:NSStringFromClass([_exc class])];
    [r appendContentHTMLString:@"\n"];
    [r appendContentHTMLString:@"  name:    "];
    [r appendContentHTMLString:[_exc name]];
    [r appendContentHTMLString:@"\n"];
    [r appendContentHTMLString:@"  reason:  "];
    [r appendContentHTMLString:[_exc reason]];
    [r appendContentHTMLString:@"\n"];
    [r appendContentHTMLString:@"  info:\n    "];
    [r appendContentHTMLString:[[_exc userInfo] description]];
    [r appendContentHTMLString:@"\n"];
    [r appendContentString:@"</pre>\n"];
  }
  
  if ([_ctx hasSession]) {
    WOSession *sn;
    
    sn = [_ctx session];
    [self logWithFormat:@"terminating session due to exception: %@", 
            [sn sessionID]];
    [sn terminate];
    
    /* ensure that session is removed, -terminate sometimes isn't sufficient */
    [[self sessionStore] sessionTerminated:sn];
  }
  return r;
}

/* external links */

- (WOResponse *)_checkForExternalLinkRedirect:(WORequest *)_request {
  WOResponse *resp;
  NSString   *url;
  
  if (![[_request requestHandlerPath] isEqualToString:@"viewExternalLink"])
    return nil;

  url  = [_request formValueForKey:@"url"];
  resp = [WOResponse responseWithRequest:_request];

  if (UseRefreshPageForExternalLink) {
      [resp appendContentString:
            @"<html><head><title>OpenGroupware.org External Link</title>"];
      [resp appendContentString:
            @"<meta http-equiv=\"refresh\" content=\"0; url="];
      [resp appendContentString:url];
      [resp appendContentString:@"\">\n"];
      [resp appendContentString:@"</head>"];
      
      [resp appendContentString:@"<body><a href=\""];
      [resp appendContentString:url];
      [resp appendContentString:@"\">"];
      [resp appendContentString:url];
      [resp appendContentString:@"</a>"];
      [resp appendContentString:@"</body></html>"];

      [resp setHeader:@"text/html; charset=iso-8859-1"
            forKey:@"content-type"];
  }
  else {
    [resp setHeader:url forKey:@"location"];
    [resp setStatus:301 /* hh asks: is this correct?? */];
  }
  return resp;
}

/* SOPE */

- (id)authenticatorInContext:(id)_ctx {
  static SoOGoAuthenticator *auth = nil;
  
  if (auth) return auth;
  auth = [[SoOGoAuthenticator alloc] init];
  return auth;
}

/* a hack to avoid magic reloads */

- (WOResponse *)dispatchRequest:(WORequest *)_request {
  WOResponse *response;
  NSString   *uri = nil;
  BOOL       doCheck;

  if ((response = [self _checkForExternalLinkRedirect:_request]))
    return response;
  
  doCheck = NO;
  {
    NSString             *ua;
    WEClientCapabilities *cb;
    
    cb = [_request clientCapabilities];
    ua = [cb userAgentType];
    
    if ([ua isEqualToString:@"Konqueror"])
      doCheck = YES;
    else if ([ua isEqualToString:@"IE"])
      doCheck = [[cb os] isEqualToString:@"MacOS"];
    else
      doCheck = NO;
  }
#if 0
  if (doCheck) {
    uri = [_request uri];
    if (uri) {
      if ((response = [self->requestDict objectForKey:uri])) {
        NSLog(@"%s: take response from stack ...", __PRETTY_FUNCTION__);
        return response;
      }
    }
  }
#endif
  response = [super dispatchRequest:_request];
  
  if (response == nil)
    return nil;
  if (!(doCheck && ([uri length] > 0)))
    return response;
  
  /* missing FiFo stack */
  if (self->requestStack == nil)
    self->requestStack = [[NSMutableArray alloc] initWithCapacity:10];
  if (self->requestDict == nil)
    self->requestDict = [[NSMutableDictionary alloc] initWithCapacity:10];
      
  if ([requestDict count] >= 10) {
    id obj;

    obj = [self->requestStack objectAtIndex:0];
    [self->requestDict removeObjectForKey:obj];
    [self->requestStack removeObjectAtIndex:0];
  }
  if (![self->requestDict objectForKey:uri]) {
    [self->requestStack addObject:uri];
    [self->requestDict setObject:response forKey:uri];
  }
  return response;
}

@end /* OpenGroupware */

@implementation OpenGroupware(Scripting)

- (Class)classForScriptedComponent:(NSString *)_name {
  return [super classForScriptedComponent:_name];
}

@end /* OpenGroupware(Scripting) */

// ******************** main ********************

int main(int argc, const char **argv, char **env) {
  NSAutoreleasePool *pool;
  NSString *s;
  int result;

  pool = [[NSAutoreleasePool alloc] init];
#if LIB_FOUNDATION_LIBRARY
  [NSProcessInfo initializeWithArguments:(void*)argv count:argc 
		 environment:env];

  // The following can be useful to detect memory leaks due to invalid
  // release/autorelease calls. Enabling this options makes the application
  // *very* slow.
  [NSAutoreleasePool enableDoubleReleaseCheck:NO];
#endif
  
  NGInitTextStdio();
  
  if ([[NSUserDefaults standardUserDefaults]
                       boolForKey:@"LSCoreOnCommandException"]) {
    NSLog(@"note: LSCoreOnCommandException=YES "
          @"(skyrix will dump core on exception) !");
  }

  s = [[NSUserDefaults standardUserDefaults]
                       stringForKey:@"SkyPreloadBundles"];

  if ([s length] > 0) {
    NGBundleManager *bm;
    NSArray *a;
    unsigned i, count;
    
    bm = [NGBundleManager defaultBundleManager];
    
    a = [s componentsSeparatedByString:@","];
    
    for (i = 0, count = [a count]; i < count; i++) {
      NSString *b;
      NSBundle *bo;
      
      b = [a objectAtIndex:i];
      bo = [bm bundleWithName:b type:@"cmd"];
      if (bo == nil) bo = [bm bundleWithName:b type:@"lso"];
      NSLog(@"preload %@: %@", b, [bo bundlePath]);
      [bo load];
    }
  }
  result = WOWatchDogApplicationMain(@"OpenGroupware", argc, argv);
  [pool release];
  exit(result);
  return result;
}
