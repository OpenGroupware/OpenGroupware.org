/*
  Copyright (C) 2000-2006 SKYRIX Software AG
  Copyright (C) 2006      Helge Hess

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

#include "OpenGroupware.h"
#include "OGoWebBundleLoader.h"
#include "SoOGoAuthenticator.h"
#include <OGoFoundation/OGoSession.h>
#include "common.h"
#include <LSFoundation/OGoContextManager.h>
#include <OGoFoundation/OGoStringTableManager.h>
#include <NGObjWeb/OWViewRequestHandler.h>
#include <NGHttp/NGHttp.h>

@interface NSObject(OpenGroupware)
- (void)registerDefaults;
@end

@interface OpenGroupware(CTI)
- (NSArray *)availableCTIDialers;
@end

@interface OpenGroupware(Defaults)
+ (NSDictionary *)defaultOGoDefaults;
@end

@interface WOComponent(PageRestoration)
- (void)initRestoreWithRequest:(WORequest *)_request;
@end

@implementation OpenGroupware

static BOOL UseRefreshPageForExternalLink = NO;
static BOOL coreOn                    = NO;
static BOOL logBundleLoading          = NO;

+ (NSArray *)defaultOGoAppointmentTypes {
  // labels for these defined in string files
  // this is in this main defaults, to ensure it is loaded when loading either
  // SkyScheduler *or* LSWScheduler
  NSMutableArray *ma;
  NSDictionary   *d;
  
  ma = [[NSMutableArray alloc] initWithCapacity:16];
  
  // TODO: this is really, well, weird ;->
  d = [[NSDictionary alloc] initWithObjectsAndKeys:@"none", @"type",
                              @"apt_icon_default.gif", @"icon",nil];
  [ma addObject:d]; [d release]; d = nil;
  d = [[NSDictionary alloc] initWithObjectsAndKeys:@"birthday", @"type",
                              @"apt_icon_birthday.gif", @"icon", nil];
  [ma addObject:d]; [d release]; d = nil;
  d = [[NSDictionary alloc] initWithObjectsAndKeys:@"tradeshow", @"type",
                              @"apt_icon_tradeshow.gif", @"icon", nil];
  [ma addObject:d]; [d release]; d = nil;
  d = [[NSDictionary alloc] initWithObjectsAndKeys:@"meeting", @"type",
                              @"apt_icon_meeting.gif", @"icon", nil];
  [ma addObject:d]; [d release]; d = nil;
  d = [[NSDictionary alloc] initWithObjectsAndKeys:@"holiday", @"type",
                              @"apt_icon_holiday.gif", @"icon", nil];
  [ma addObject:d]; [d release]; d = nil;
  d = [[NSDictionary alloc] initWithObjectsAndKeys:@"duedate", @"type",
                              @"apt_icon_duedate.gif", @"icon", nil];
  [ma addObject:d]; [d release]; d = nil;
  d = [[NSDictionary alloc] initWithObjectsAndKeys:@"outward", @"type",
                              @"apt_icon_outwards.gif", @"icon", nil];
  [ma addObject:d]; [d release]; d = nil;
  d = [[NSDictionary alloc] initWithObjectsAndKeys:@"home", @"type",
                              @"apt_icon_home.gif", @"icon", nil];
  [ma addObject:d]; [d release]; d = nil;
  d = [[NSDictionary alloc] initWithObjectsAndKeys:@"call", @"type",
                              @"apt_icon_call.gif", @"icon", nil];
  [ma addObject:d]; [d release]; d = nil;
  d = [[NSDictionary alloc] initWithObjectsAndKeys:@"ill", @"type",
                              @"apt_icon_ill.gif", @"icon", nil];
  [ma addObject:d]; [d release]; d = nil;
  
  d = [ma copy];
  [ma release];
  return [d autorelease];
}
+ (NSArray *)defaultOGoLanguages {
  // TODO: is this necessary? We should locate the themes by scanning the
  //       Themes directory (OGo bug #1112)
  return [NSArray arrayWithObjects:
                    @"English_OOo", @"English_blue", @"English_orange",
                    @"English_kde",
                  nil];
}

+ (NSDictionary *)defaultOGoDefaults {
  NSDictionary *defs;
  
  defs = [NSDictionary dictionaryWithObjectsAndKeys:
                       [NSNumber numberWithBool:YES], 
                       @"LSPageRefreshOnBacktrack",
                       [NSNumber numberWithInt:1200], 
                       @"LSLoginPageExpireTimeout",
                       [NSNumber numberWithInt:300], 
                       @"SkyProjectFileManagerClickTimeout",
                       @"", @"SkyLogoutURL",
                       [self defaultOGoAppointmentTypes],
                       @"SkyScheduler_defaultAppointmentTypes",
                       nil];
  return defs;
}

+ (int)version {
  return [super version] + 0; /* v6 */
}

+ (void)initialize {
  static BOOL isInitialized = NO;
  NSUserDefaults    *ud;
  NSAutoreleasePool *pool;

  if (isInitialized)
    return;
  isInitialized = YES;
  
  NSAssert1([super version] == 6,
            @"invalid superclass (WOApplication) version %i !",
            [super version]);

  pool = [[NSAutoreleasePool alloc] init];
  
  ud = [NSUserDefaults standardUserDefaults];
  
  /* register app defaults */
  
  [ud registerDefaults:[self defaultOGoDefaults]];
  
  /* load values of defaults */
  
  logBundleLoading = [ud boolForKey:@"OGoLogBundleLoading"];
  coreOn           = [ud boolForKey:@"OGoCoreOnException"];
  UseRefreshPageForExternalLink =
    [ud boolForKey:@"UseRefreshPageForExternalLink"];
  
  [pool release];
}

#if 1 // hh(2024-09-26): use hardcoded name OpenGroupware (vs ogo-webui-5.5)
// because this affects links and such. Stick to just OGo.
// Note:
// - Changing the name affects resource pathes, specifically components.cfg
//   lookup in WebUI/Templates (e.g. Themes/blue/ogo-webui-5.5)
- (NSString *)name {
  return @"OpenGroupware";
}
#else
- (NSString *)name {
  /* override to avoid clashes with "." processing */
  static NSString *cName = nil;
  if (cName != nil)
    return cName;
  cName = [[[[[NSProcessInfo processInfo] arguments] objectAtIndex:0] 
	                     lastPathComponent] copy];
  return cName;
}
#endif

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
  NSString *k;
  
  /* use WODirectActionRequestHandler as default request handler */
  
  k  = [WOApplication directActionRequestHandlerKey];
  rh = [self requestHandlerForKey:k];
  [self setDefaultRequestHandler:rh];
  
  k  = [WOApplication componentRequestHandlerKey];
  rh = [[NSClassFromString(@"OWViewRequestHandler") alloc] init];
  [self registerRequestHandler:rh forKey:k];
  [rh release]; rh = nil;
}

- (void)_setupResourceManager {
  OGoResourceManager *rm;
  
  /* force the setup of some statics */
  [OGoResourceManager    availableOGoThemes];
  [OGoStringTableManager availableOGoTranslations];
  
  rm = [OGoResourceManager alloc]; /* seperate line to keep gcc happy */
  rm = [rm initWithPath:[self path]];
  NSAssert(rm, @"could not create resource manager!");
  [self setResourceManager:(WOResourceManager *)rm];
  [rm release]; rm = nil;
}

- (id)init {
  if ((self = [super init]) != nil) {
    NSUserDefaults *ud;
    
    ud = [NSUserDefaults standardUserDefaults];

    if ([ud boolForKey:@"OGoLogNotifications"]) {
      [[NSNotificationCenter defaultCenter] 
	addObserver:self selector:@selector(logNotification:)
	name:nil object:nil];
      [self logWithFormat:@"Note: will log all notifications!"];
    }
    
    if ([ud boolForKey:@"LSCoreOnCommandException"]) {
      [self logWithFormat:@"Note: LSCoreOnCommandException=YES, "
              @"OGo will dump core on uncatched exceptions!"];
    }
    
    [self setPageRefreshOnBacktrackEnabled:
            [[ud objectForKey:@"LSPageRefreshOnBacktrack"] boolValue]];

    [self _applyMinimumActiveSessionCount];
    
    /* start OGo Logic session factory */
    
    if ((self->lso = [[OGoContextManager defaultManager] retain]) == nil) {
      [self logWithFormat:@"Could not setup OGoContextManager "
            @"(DB probably not yet configured)!"];
    }
    
    [self _setupRequestHandlers];
    [self _setupResourceManager];
    
    [self _setVersion];
    
#if DEBUG
    [self logWithFormat:@"CTI Dialers: %@",
            [[self availableCTIDialers] componentsJoinedByString:@","]];
#endif

    /* enforce init of some classes */
    [NSClassFromString(@"WOCompoundElement") class];
    
    /* load WebUI bundles */
    [[OGoWebBundleLoader bundleLoader] loadBundles];
    
    /* force initial database connect */
    if ([self->lso isLoginAuthorized:@"root" password:@""])
      [self logWithFormat:@"root has no password, you need to assign one!"];
    
    [self logWithFormat:@"OpenGroupware.org instance initialized."];
  }
  return self;
}

- (void)dealloc {
  [[self notificationCenter] removeObserver:self];
  [self->version release];
  [self->lso     release];
  [super dealloc];
}

/* notifications */

- (void)logNotification:(NSNotification *)_notification {
  NSString *d;
  id obj;
  
  obj = [_notification object];
  d   = [obj description];

  if ([d length] > 40)
    d = [[d substringToIndex:28] stringByAppendingString:@".."];
  
  [self logWithFormat:@"notification %@ object %p(%@): %@",
	  [_notification name], obj, NSStringFromClass([obj class]), d];
}

/* deprecated */

- (BOOL)hasLogTab {
  // TODO: remove
  [self warnWithFormat:@"%s: called deprecated method.", __PRETTY_FUNCTION__];
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
          @"failed to restore page, ctx: %@",
          self, _ctx];
  
  if ((sn = (OGoSession *)[_ctx session]) == nil) {
    [self debugWithFormat:@"did not find session .."];
    return [super handlePageRestorationErrorInContext:_ctx];
  }
  if ((nav = [sn navigation]) == nil) {
    [self debugWithFormat:@"did not find navigation in session: %@", sn];
    return [super handlePageRestorationErrorInContext:_ctx];
  }
  
  if ((component = [nav activePage]) == nil) {
    [self debugWithFormat:@"did not find active page in navigation: %@",sn];
    return [super handlePageRestorationErrorInContext:_ctx];
  }
  
  [self logWithFormat:@"  delivering last navigation page .."];
  return [component generateResponse];
}

- (WOResponse *)_checkForMailPopup:(WOContext *)_ctx {
  WORequest  *req;
  WOResponse *resp;

  req = [_ctx request];
  if (![[req requestHandlerPath] isEqualToString:@"viewMailsPopUp"])
    return nil;
    
  resp = [WOResponse responseWithRequest:req];
  [resp appendContentString:
          @"<html><head><title>OGo Mails</title>\n"
          @"<body vlink=\"#000000\" bgcolor=\"#FFECD0\" link=\"#000000\" "
          @"font=\"#000000\">\n"
          @"<center> <b>Your session expired.</b></center>\n"
          @"</body></html>"];
  
  [resp setHeader:@"text/html; charset=iso-8859-1" forKey:@"content-type"];
  return resp;
}

- (WOCookie *)expireCookieInContext:(WOContext *)_ctx {
  // TODO: fix this hack
  static BOOL doNotSetCookiePath    = NO;
  static BOOL didCheckCookieDefault = NO;
  WOCookie *cookie;
  NSString *uri;
  
  if (!didCheckCookieDefault) {
    doNotSetCookiePath = [[NSUserDefaults standardUserDefaults] 
			   boolForKey:@"WOUseGlobalCookiePath"];
    didCheckCookieDefault = YES;
    if (doNotSetCookiePath)
      [self debugWithFormat:@"Note: using global cookie path!"];
  }
  
  /* Note: section copied from WORequestHandler */
  if (!doNotSetCookiePath) {
    NSString *tmp;
      
    if ((uri = [[_ctx request] applicationName]) == nil)
      uri = [self name];
    uri = [@"/" stringByAppendingString:uri];
    if ((tmp = [[_ctx request] adaptorPrefix]))
      uri = [tmp stringByAppendingString:uri];
  }
  else
    uri = @"/";

  cookie = [WOCookie cookieWithName:[self name]
                     value:@"nil" path:uri domain:nil
                     expires:[NSDate dateWithTimeIntervalSinceNow:(-600.0)]
                     isSecure:NO];
  return cookie;
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
  
  if (![pageName isNotEmpty] || ![loginName isNotEmpty])
    return nil;
  
  page = [self pageWithName:@"Main"];
  
  [page initRestoreWithRequest:req];
  
  response = [page generateResponse];
  
  // TODO: the cookie should be set by SOPE?!
  
  if ((cookie = [self expireCookieInContext:_ctx]) != nil)
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
  else if ([rhkey isEqualToString:@"so"])
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
    
    if ([query isNotEmpty]) {
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
    if ([query isNotEmpty]) {
      jumpTo = [[jumpTo stringByAppendingString:@"?"]
                        stringByAppendingString:query];
    }
  }
  else {
    jumpTo = [[_ctx applicationURL] absoluteString];
    jumpTo = [[request adaptorPrefix] stringByAppendingString:jumpTo];
    if (![jumpTo hasSuffix:@"/"])
      jumpTo = [jumpTo stringByAppendingString:@"/"];
  }
  return jumpTo;
}

- (WOResponse *)handleSessionRestorationErrorInContext:(WOContext *)_ctx {
  WOResponse *response;
  WOCookie   *cookie;
  NSString   *jumpTo;
  
  if ((response = [self _checkForMailPopup:_ctx]) != nil)
    return response;
  
  if ((response = [self sxRestorePageInContext:_ctx]) != nil)
    return response;
  
  jumpTo = [self locationForSessionRedirectInContext:_ctx];
  [self logWithFormat:
          @"failed to restore session %@:\n"
          @"  ctx:            %@\n"
          @"  redirecting to: %@",
          [[_ctx request] sessionID], _ctx, jumpTo];
  
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
  
  if ((cookie = [self expireCookieInContext:_ctx]) != nil)
    [response addCookie:cookie];
  
  return response;
}

- (BOOL)isRefusingNewSessions {
  return (self->sessionCount > 0) ? YES : NO;
}

- (WOSession *)_createSession {
  OGoSession *session = nil;

  /* Note: DO NOT AUTORELEASE the session !!! */
  if ((session = [[OGoSession alloc] init]) == nil)
    return nil;
  
  [self logWithFormat:@"%@: created session: %@", self, session];
  self->sessionCount++;
  return session;
}

- (id)createSessionForRequest:(WORequest *)_request {
  return [self _createSession];
}

#if WITH_URL_COMPONENTS
- (WOComponent *)pageWithURL:(NSURL *)_url inContext:(WOContext *)_ctx {
  return nil;
}
#endif

- (id)pageWithName:(NSString *)_name inContext:(WOContext *)_ctx {
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
  if (![zoneNames isNotEmpty]) {
    zoneNames = [NSArray arrayWithObject:@"GMT"];
    [self logWithFormat:@"Note: no LSTimeZones default set, using just GMT!"];
  }

  count = [zoneNames count];
  zones = [[NSMutableArray alloc] initWithCapacity:count];
  for (i = 0; i < count; i++) {
    NSTimeZone *tzone;
    
    tzone = [NSTimeZone timeZoneWithAbbreviation:[zoneNames objectAtIndex:i]];
    if (tzone != nil)
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
      [self logWithFormat:@"could not create response!"];
    
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

      [resp setHeader:@"text/html; charset=\"iso-8859-1\""
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
  
  if ((response = [self _checkForExternalLinkRedirect:_request]) != nil)
    return response;
  
  return [super dispatchRequest:_request];
}

@end /* OpenGroupware */
