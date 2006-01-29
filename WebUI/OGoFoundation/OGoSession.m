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

#include "OGoSession.h"
#include "OGoClipboard.h"
#include "OGoNavigation.h"
#include "OGoContentPage.h"
#include "LSStringFormatter.h"
#include "LSWNotifications.h"
#include "WOComponent+config.h"
#include "NSObject+LSWPasteboard.h"
#include "LSWMimeContent.h"
#include "OGoResourceManager.h"
#include "OGoStringTableManager.h"
#include "common.h"
#include <LSFoundation/OGoContextSession.h>
#include <LSFoundation/OGoContextManager.h>
#include <NGHttp/NGHttp.h>
#import <EOControl/EOControl.h>

#include "OGoHelpManager.h" // TODO: remove

@interface OGoSession(PrivateMethods)
- (void)loadConfigurationFiles;
@end

@interface WOApplication(RequiredMethods)
- (NSArray *)allTimeZones;
@end

@interface WOComponent(RequiredMethods)

- (id)performActionNamed:(NSString *)_uri parameters:(id)_params
  inContext:(id)_ctx;
- (id)invokeActionForFirstRequest:(id)_request inContext:(id)_ctx;
- (id)invokeActionForExpiredRequest:(id)_request inContext:(id)_ctx;

- (id)activateObject:(id)_object verb:(NSString *)_verb type:(NGMimeType *)_mt;

@end

@interface NSObject(gids)

- (EOGlobalID *)globalID;
- (NSString *)labelForObjectInSession:(id)_sn;

@end

@implementation OGoSession

static NGBundleManager *bm = nil;
static BOOL profileConfig  = NO;
static BOOL profileSleep   = NO;
static BOOL debugConfig    = NO;
static BOOL debugPageCache = NO;
static BOOL forceJavaScript = NO;
static NSString *OGoDateFormat           = nil;
static NSString *OGoAMPMTimeFormat       = nil;
static NSString *OGoTimeFormat           = nil;
static NSString *OGoAMPMDateTimeFormat   = nil;
static NSString *OGoDateTimeFormat       = nil;
static NSString *OGoAMPMDateTimeTZFormat = nil;
static NSString *OGoDateTimeTZFormat     = nil;

+ (int)version {
  return [super version] + 12; /* v17 */
}
+ (void)initialize {
  static BOOL didInit = NO;
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  NSDictionary *defs;
  
  if (didInit) return;
  NSAssert2([super version] == 5,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
  didInit = YES;

  // TODO: move this to a resource file
  defs = [NSDictionary dictionaryWithObjectsAndKeys:
                         [NSNumber numberWithInt:5],  
		         @"SkyMaxFavoritesCount",
                         [NSNumber numberWithInt:32], 
		         @"SkyMaxNavLabelLength",
		         @"%Y-%m-%d",             @"OGoDateFormat",
		         @"%I:%M %p %Z",          @"OGoAMPMTimeFormat",
   		         @"%H:%M %Z",             @"OGoTimeFormat",
		         @"%Y-%m-%d %I:%M %p",    @"OGoAMPMDateTimeFormat",
		         @"%Y-%m-%d %H:%M",       @"OGoDateTimeFormat",
		         @"%Y-%m-%d %I:%M %p %Z", @"OGoAMPMDateTimeTZFormat",
		         @"%Y-%m-%d %H:%M %Z",    @"OGoDateTimeTZFormat",
                         nil];
  [ud registerDefaults:defs];
  
  profileConfig  = [ud boolForKey:@"OGoProfileConfig"];
  profileSleep   = [ud boolForKey:@"OGoProfileSleep"];
  debugConfig    = [ud boolForKey:@"OGoDebugConfig"];
  debugPageCache = [ud boolForKey:@"OGoDebugPageCache"];
  
  OGoDateFormat           = [ud stringForKey:@"OGoDateFormat"];
  OGoTimeFormat           = [ud stringForKey:@"OGoTimeFormat"];
  OGoDateTimeFormat       = [ud stringForKey:@"OGoDateTimeFormat"];
  OGoDateTimeTZFormat     = [ud stringForKey:@"OGoDateTimeTZFormat"];
  OGoAMPMTimeFormat       = [ud stringForKey:@"OGoAMPMTimeFormat"];
  OGoAMPMDateTimeFormat   = [ud stringForKey:@"OGoAMPMDateTimeFormat"];
  OGoAMPMDateTimeTZFormat = [ud stringForKey:@"OGoAMPMDateTimeTZFormat"];
  
  if ((forceJavaScript = [ud boolForKey:@"OGoAlwaysEnableJavaScript"]))
    NSLog(@"Note: WebUI configured to always use JavaScript.");

  bm = [[NGBundleManager defaultBundleManager] retain];
}

- (void)_registerForNotifications {
  [self addObserver:self selector:@selector(_refetchAccountInfo:)
        name:LSWNewTeamNotificationName object:nil];
  [self addObserver:self selector:@selector(_refetchAccountInfo:)
        name:LSWDeletedTeamNotificationName object:nil];
  [self addObserver:self selector:@selector(_refetchAccountInfo:)
        name:LSWUpdatedTeamNotificationName object:nil];

#if 0 
  [self addObserver:self selector:@selector(_refetchAccountInfo:)
        name:LSWNewAccountNotificationName object:nil];
  [self addObserver:self selector:@selector(_refetchAccountInfo:)
        name:LSWDeletedAccountNotificationName object:nil];
  [self addObserver:self selector:@selector(_refetchAccountInfo:)
        name:LSWUpdatedAccountNotificationName object:nil];
#endif
  
  [self addObserver:self selector:@selector(accountPWWasUpdated:)
        name:LSWUpdatedPasswordNotificationName object:nil];
    
  [self addObserver:self selector:@selector(accountPreferenceWasUpdated:)
        name:LSWUpdatedAccountPreferenceNotificationName object:nil];
}

- (NSFormatter *)_createDateFormatter:(NSString *)_fmt {
  return [[NSDateFormatter alloc] 
	   initWithDateFormat:_fmt allowNaturalLanguage:NO];
}

- (void)initDateFormatters {
  BOOL   showAMPMDates;
  NSZone *z;
  
  [self->formatDate       release];
  [self->formatTime       release];
  [self->formatDateTime   release];
  [self->formatDateTimeTZ release];
  
  showAMPMDates = [self->userDefaults boolForKey:@"scheduler_AMPM_dates"];
  z             = [self zone];
  
  self->formatDate = [self _createDateFormatter:OGoDateFormat];
  if (showAMPMDates) {
    self->formatTime     = [self _createDateFormatter:OGoAMPMTimeFormat];
    self->formatDateTime = [self _createDateFormatter:OGoAMPMDateTimeFormat];
    self->formatDateTimeTZ = 
      [self _createDateFormatter:OGoAMPMDateTimeTZFormat];
  }
  else {
    self->formatTime       = [self _createDateFormatter:OGoTimeFormat];
    self->formatDateTime   = [self _createDateFormatter:OGoDateTimeFormat];
    self->formatDateTimeTZ = [self _createDateFormatter:OGoDateTimeTZFormat];
  }
}

- (NSArray *)availableOGoLanguages {
  static NSArray *llangs = nil;
  NSMutableArray *langs;
  NSEnumerator *e;
  NSString     *s;

  if (llangs != nil) return llangs;
  
  langs = [NSMutableArray arrayWithCapacity:32];
  
  /* first add themes */
  
  e = [[OGoResourceManager availableOGoThemes] objectEnumerator];
  while ((s = [e nextObject]) != nil) {
    s = [@"English_" stringByAppendingString:s];
    if ([langs containsObject:s]) continue;
    [langs addObject:s];
  }

  /* then add translations */
  
  e = [[OGoStringTableManager availableOGoTranslations] objectEnumerator];
  while ((s = [e nextObject]) != nil) {
    if ([langs containsObject:s]) continue;
    [langs addObject:s];
  }
  
  llangs = [langs copy];
  return llangs;
}

- (BOOL)configureForLSOfficeSession:(OGoContextSession *)_sn {
  NSString *language;
  
  if (self->lso) {
    [self logWithFormat:@"WARNING: session was already initialized."];
    return YES;
  }
  
  self->lso = [_sn retain];
  
  [[self commandContext] pushContext];
  
  self->activeLogin = 
    [[self runCommand:@"account::get-by-login",
	     @"login", [self->lso activeLoginName], nil] retain];
  
  NSAssert(self->activeLogin, @"could not determine active login");
  NSAssert2([[self->activeLogin valueForKey:@"login"]
                               isEqual:[self->lso activeLoginName]],
            @"got invalid login record %@ (expected %@)",
            self->activeLogin,
            [self->lso activeLoginName]);

  [self logWithFormat:@"user %@ logged in.",
        [self->activeLogin valueForKey:@"login"]];

  // set userDefaults

  {
    id tmp;

    tmp = [[self->lso commandContext] valueForKey:LSUserDefaultsKey];
    ASSIGN(self->userDefaults, tmp);
  }
  // add SkyLanguages
  {
    NSArray *skyLangs = nil;
    
    skyLangs = [self availableOGoLanguages];

    if ([skyLangs count] > 0) {
      NSMutableArray *l;

      l = [NSMutableArray arrayWithCapacity:6];

      [l addObjectsFromArray:[self languages]];
      [l addObjectsFromArray:skyLangs];
      [self setLanguages:l];
    }
  }
  
  /* set language from account preferences */
  
  language = [self->userDefaults objectForKey:@"language"];
  
  if ([language isNotNull])
    [self setPrimaryLanguage:language];

  /* only for profiling memory-usage */
#if 0
  [self fetchAccounts];
  [self fetchTeams];
#endif
       
  [self fetchCategories];

  // last check whether login is really available
  
  NSAssert(self->activeLogin, @"no active account is set !");
  [self loadConfigurationFiles];
  
  [self initDateFormatters];

#if 0  
  [[[[self->lso commandContext]
                valueForKey:LSDatabaseChannelKey] adaptorChannel]
                setDebugEnabled:YES];
#endif  
  
  return YES;
}

- (id)init {
  [OGoHelpManager sharedHelpManager];
  
  if ((self = [super init])) {
    /* setup pasteboard mapping */

    self->name2pb =
      NSCreateMapTable(NSObjectMapKeyCallBacks, NSObjectMapValueCallBacks, 8);
    
    /* setup session notifications */
    
    self->notificationCenter = [[NSNotificationCenter alloc] init];
    [self _registerForNotifications];
    
    self->navigation = [[LSWNavigation alloc] initWithSession:self];
    
    self->formatString = [[LSStringFormatter alloc] init];
    [self initDateFormatters];
    self->activationCommandToConfig =
      NSCreateMapTable(NSObjectMapKeyCallBacks,
                       NSObjectMapValueCallBacks,
                       120);
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter]
                         postNotificationName:@"OGoSessionFinalizing"
                         object:self];
  [self removeObserver:self];
  
  if (self->activationCommandToConfig)
    NSFreeMapTable(self->activationCommandToConfig);

  if (self->name2pb)
    NSFreeMapTable(self->name2pb);
  
  [self->pComponents        release];
  [self->lastContextId      release];
  [self->lso                release];
  [self->navigation         release];
  [self->formatDate         release];
  [self->formatTime         release];
  [self->formatString       release];
  [self->activeLogin        release];
  [self->componentsConfig   release];
  [self->eoSorter           release];
  [self->accounts           release];
  [self->teams              release];
  [self->categories         release];
  [self->categoryNames      release];
  [self->notificationCenter release];
  [self->favorites          release];
  [self->choosenFavorite    release];
  [self->userDefaults       release];
  [self->dockedProjectInfos release];
  [super dealloc];
}

/* notifications */

- (void)takeValuesFromRequest:(WORequest *)_req inContext:(WOContext *)_ctx {
  if ([[_ctx senderID] isNotEmpty]) { /* only run for WO actions */
    if (self->lastContextId == nil) {
      [self debugWithFormat:@"first request, skipping -takeValues.."];
      return;
    }
    if (![[_ctx currentElementID] isEqualToString:self->lastContextId]) {
      [self debugWithFormat:
  	    @"old request (wrong context), skipping -takeValues.."];
      return;
    }
  }
  
  [super takeValuesFromRequest:_req inContext:_ctx];
}

- (id)invokeActionForRequest:(WORequest *)_req inContext:(WOContext *)_ctx {
  /* favicon.ico handling */

  if ([[_req uri] isEqualToString:@"favicon.ico"]) {
    [self debugWithFormat:@"request for favicon.ico .."];
    return nil;
  }
  if ([[_req uri] isEqualToString:@"_vti_inf.html"]) {
    [self debugWithFormat:@"request for _vti_inf.html .."];
    return nil;
  }
  
  /* usual component action handling .. */

  if (self->lastContextId == nil) {
    id page;

    [self debugWithFormat:@"first request, skipping -invoke.."];

    page = ([_ctx page] == nil)
      ? [[WOApplication application] pageWithName:@"Main" inContext:_ctx]
      : [_ctx page];
    
    if ([page respondsToSelector:
              @selector(invokeActionForFirstRequest:inContext:)]) {
      return [page invokeActionForFirstRequest:_req inContext:_ctx];
    }
    return nil;
  }
  else if (![[_ctx currentElementID] isEqualToString:self->lastContextId]) {
    id page;

    [self debugWithFormat:@"old request (wrong context), skipping -invoke.."];
    
    page = ([_ctx page] == nil)
      ? [[WOApplication application] pageWithName:@"Main" inContext:_ctx]
      : [_ctx page];
    
    if ([page respondsToSelector:
              @selector(invokeActionForFirstRequest:inContext:)]) {
      return [page invokeActionForExpiredRequest:_req inContext:_ctx];
    }
    return nil;
  }
  else {
    OGoContentPage *oldActive, *newActive, *reqPage;
    id result;

    reqPage = [context page];
    if ((oldActive = [[self navigation] activePage])) {
      if (oldActive != reqPage && (reqPage != nil)) {
        [self debugWithFormat:
                @"WARNING: active page != request page (%@ vs %@)",
                [oldActive name], [reqPage name]];
      }
    }
    result = [super invokeActionForRequest:_req inContext:_ctx];
    
    if (result == nil) result = [context page];
    
    newActive = [[self navigation] activePage];
    
    if (result == nil) /* return the active page */
      return newActive;

    if ((result != newActive) && (newActive!=nil) && [result isContentPage]) {
      if (newActive != oldActive) {
            /* replace LSWContentPage's with the real active page */
            result = newActive;
      }
      else {
            /* autoadd content-pages to the navigation */
            newActive = result;
            [[self navigation] enterPage:result];
      }
    }
    return result;
  }
}

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  /* 
     commit before appendToResponse, so that possible errors can be displayed
  */
  NSUserDefaults *ud;
  
  if ([[self commandContext] isTransactionInProgress]) {
    [self debugWithFormat:@"lso: %@, committing", self->lso];
    if (![[self commandContext] commit]) {
      [self logWithFormat:@"lso: %@: commit failed.", self->lso];
      [[[self navigation] activePage] setErrorString:@"tx commit failed."];
    }
  }

  if ((ud = [self userDefaults]) == nil)
    [self logWithFormat:@"WARNING: missing defaults object in session!"];
  else if (![ud synchronize])
    [self logWithFormat:@"WARNING: could not synchronize defaults: %@", ud];
  
  [super appendToResponse:_response inContext:_ctx];
}

- (void)awake {
  [[NSNotificationCenter defaultCenter]
                         postNotificationName:@"OGoSessionAwake"
                         object:nil];
  
  [[self commandContext] pushContext];
  
  if (!self->isAwake && (self->activeLogin != nil)) {
    self->isAwake = YES;
    [self loadConfigurationFiles];
  }
  [self->lso activate];
  [super awake];
}

- (void)sleep {
  NSTimeInterval sleepStart = 0, ownSleepStart = 0;
  NSUserDefaults *ud;
  
  if (profileSleep)
    sleepStart = [[NSDate date] timeIntervalSince1970];
  
  [super sleep];
  
  if (profileSleep)
    ownSleepStart = [[NSDate date] timeIntervalSince1970];
  
  if ((ud = [self userDefaults]) == nil)
    [self logWithFormat:@"WARNING: missing defaults object in session!"];
  else if (![ud synchronize])
    [self logWithFormat:@"WARNING: could not synchronize defaults: %@", ud];
  
  if (profileSleep) {
    NSTimeInterval endTime;
    
    endTime = [[NSDate date] timeIntervalSince1970];
    
    [self logWithFormat:@"  defaults sync took %4.3fs (own=%4.3f).",
            (endTime - sleepStart),
            (endTime - ownSleepStart)];
  }
  
  if ([[self commandContext] isTransactionInProgress]) {
    [self debugWithFormat:@"sleep: lso %@ commit.", self->lso];
    
    if (![[self commandContext] commit]) {
      [self logWithFormat:@"lso: %@: last commit failed.", self->lso];
      [[[self navigation] activePage] setErrorString:@"tx commit failed."];
    }
  }
  
  [self->lso deactivate];
  self->isAwake = NO;
  
  [[self commandContext] popContext];
  
  if (profileSleep) {
    NSTimeInterval endTime;
    
    endTime = [[NSDate date] timeIntervalSince1970];
    
    [self logWithFormat:@"  sleep took %4.3fs (own=%4.3f).",
            (endTime - sleepStart),
            (endTime - ownSleepStart)];
  }
  
  if (profileSleep) {
    NSTimeInterval endTime;
    
    endTime = [[NSDate date] timeIntervalSince1970];
    
    [self logWithFormat:@"  sleep(with js collect) took %4.3fs (own=%4.3f).",
            (endTime - sleepStart),
            (endTime - ownSleepStart)];
  }
  [[NSNotificationCenter defaultCenter]
                         postNotificationName:@"OGoSessionSleep"
                         object:nil];
}

/* accessors */

- (id)activeAccount {
  NSAssert(self->activeLogin, @"no active account is set !");
  return self->activeLogin;
}

- (NSString *)activeLogin {
  return [self->lso activeLoginName];
}

- (BOOL)activeAccountIsRoot {
  return ([[[self activeAccount] valueForKey:@"companyId"] intValue] == 10000)
    ? YES
    : NO;
}

- (void)setIsJavaScriptEnabled:(BOOL)_flag {
  self->isJavaScriptEnabled = _flag;
}
- (BOOL)isJavaScriptEnabled {
  return forceJavaScript || self->isJavaScriptEnabled ? YES : NO;
}

/* configuration */

// TODO: should move the session startup methods to a "OGoSessionBootProcess"
//       object

- (id)_activateFirstDockedProject {
  NSString      *projectId;
  EOKeyGlobalID *gid;
  NSArray *projectIds;

  projectIds = [[self userDefaults] arrayForKey:@"docked_projects"];
  if ([projectIds count] == 0)
    return nil;

  projectId = [projectIds objectAtIndex:0];
  gid       = [EOKeyGlobalID globalIDWithEntityName:@"Project"
			     keys: &projectId keyCount:1
			     zone:[self zone]];
  return [[self navigation] activateObject:gid withVerb:@"view"];
}

- (id)_finalFallbackMethodForNewSession {
  return [[WOApplication application]
	   pageWithName:@"LSWPreferencesViewer" inContext:[self context]];
}

- (NSDictionary *)_configForDockablePage:(NSString *)pageName {
  NGBundleManager *bm = [NGBundleManager defaultBundleManager];
  NSBundle     *bundle;
  NSDictionary *cfgEntry;
  
  bundle = [bm bundleProvidingResource:pageName ofType:@"DockablePages"];
  if (bundle == nil) {
    [self logWithFormat:@"ERROR: did not find dockable page: '%@'", pageName];
    return nil;
  }

  cfgEntry = [bundle configForResource:pageName ofType:@"DockablePages"];
  if (cfgEntry == nil) {
    [self logWithFormat:@"ERROR: missing configuration of dockable page: '%@'",
	  pageName];
    return nil;
  }
  
  return cfgEntry;
}
- (BOOL)shouldShowDockablePage:(NSDictionary *)cfgEntry
  isExtraAccount:(BOOL)isExtraAccount isRootAccount:(BOOL)isRootAccount
{
  /* check whether page is visible for root only */
  if ([[cfgEntry objectForKey:@"onlyRoot"] boolValue]) {
    if (!isRootAccount)
      return NO;
  }

  /* check whether the page is visible for extra accounts */
  if (isExtraAccount) {
    if (![[cfgEntry objectForKey:@"allowedForExtraAccounts"] boolValue])
      return NO;
  }
  
  return YES;
}

- (WOComponent *)_instantiateInitialPage {
  /* find a start page */
  NSEnumerator    *dockedPageNames;
  BOOL            isExtraAccount, isRootAccount;
  NSString        *pageName;
  WOComponent     *page;
  id              tmp;

  /* get type of current account */

  isRootAccount = [self activeAccountIsRoot];
  isExtraAccount =
    [[[self activeAccount] valueForKey:@"isExtraAccount"] boolValue];

  /* determine docked pages from NSUserDefaults */

  page = nil;
  tmp  = [[self userDefaults] arrayForKey:@"SkyDockablePagesOrdering"];
      
  dockedPageNames = [tmp objectEnumerator];

  /* find first matching page .. */
      
  while ((page == nil) && (pageName = [dockedPageNames nextObject])) {
    NSDictionary *cfgEntry;
    NSString     *componentName;
    
    if ((cfgEntry = [self _configForDockablePage:pageName]) == nil)
      continue;
    
    if ((componentName = [cfgEntry objectForKey:@"component"]) == nil) {
      [self logWithFormat:
	      @"ERROR: missing component-name of page: '%@'", pageName];
      continue;
    }
	
    if (![self shouldShowDockablePage:cfgEntry 
	       isExtraAccount:isExtraAccount isRootAccount:isRootAccount])
      continue;
	
    /* check whether there is a bundle providing the required component */

    if (![bm bundleProvidingResource:componentName ofType:@"WOComponents"]) {
      [self logWithFormat:@"module providing %@ is missing !", componentName];
      continue;
    }
    
    /* found a matching page */
    page = [[WOApplication application] pageWithName:componentName
					inContext:[self context]];
  }

  if (page == nil)
    page = [self _activateFirstDockedProject];
  if (page == nil)
    page = [self _finalFallbackMethodForNewSession];
  
  return page;
}

- (void)loadConfigurationFiles {
  /* TODO: split up this huge method! */
  NSAutoreleasePool *pool;
  WOResourceManager *resMan;
  NSArray           *langs;
  NSString          *lang;
  
  pool = [[NSAutoreleasePool alloc] init];
  resMan = [[self application] resourceManager];
    
  lang = [self primaryLanguage];
  if ([lang isEqualToString:@"English"] || [lang hasPrefix:@"English_"])
    langs = [NSArray arrayWithObject:lang];
  else
    /* include fallback to "English_theme" */
    langs = [self languages];
    
  /* load LSWBase */

  NSClassFromString(@"LSWBaseModule");

  /* find startpage */

  if (![self->navigation containsPages]) {
      id page;
      
      if ((page = [self _instantiateInitialPage]))
	[self->navigation enterPage:page];
  }
    
  /* component configurations */
    
  if (self->componentsConfig == nil) {
      id       plist;
      NSString *path;
      
      path = [resMan pathForResourceNamed:@"components.cfg" inFramework:nil
                     languages:langs];
      if (path == nil) {
        [self logWithFormat:
                @"ERROR: did not find components.cfg for languages: %@",
                [langs componentsJoinedByString:@", "]];
      }
      else {
        plist = [[NSString stringWithContentsOfFile:path] propertyList];
        if ([plist isKindOfClass:[NSDictionary class]]) {
          id tmp;
	  
          tmp = self->componentsConfig;
          self->componentsConfig = [plist mutableCopy];
          [tmp release];
        }
        else {
          [self logWithFormat:
                  @"ERROR: file is not in dictionary plist format: '%@'", 
                  path];
        }
      }
  }
  [pool release]; pool = nil;
}

- (NSDictionary *)componentConfig {
  NSDictionary *cfg;
  
  if (((cfg = self->componentsConfig) == nil) && (self->lso != nil)) {
    [self debugWithFormat:@"WARNING: no component config loaded! "
            @"(probably an unavailable theme is selected in the prefs)"];
  }
  return cfg;
}

- (LSCommandContext *)commandContext {
  return [self->lso commandContext];
}
- (OGoContextSession *)skyrixContext {
  return self->lso;
}

- (NSDictionary *)configurationOfComponentNamed:(NSString *)_componentName {
  NSDictionary *cfg;
  
  if ((cfg = [self componentConfig]) == nil)
    return nil;
  
  return [cfg valueForKey:_componentName];
}

- (id)configValueForKey:(NSString *)_key inComponent:(WOComponent *)_component{
  /* TODO: split this big method */
  NSTimeInterval st;
  id             cConfig, result;
  WOComponent    *comp = nil;

  st     = 0.0;
  result = nil;
  
  if (profileConfig)
    st = [[NSDate date] timeIntervalSince1970];
  
  /* go up the component hierachy */
  for (comp = _component; comp; comp = [(WOComponent *)comp parent]) {
    NSString *componentName;
    id value;
    
    if (![comp isComponent])
      continue;
      
    componentName = [comp name];
      
    /* look into global components cfg */
    cConfig = [self configurationOfComponentNamed:componentName];
    value   = [cConfig valueForKey:_key];
      
    if (value == nil)
      continue;
    
    /* found a value for the component */
    if (debugConfig) {
      if (comp != _component) {
        /* the value is inherited */
        [self debugWithFormat:
		    @"inherited value for config key %@ on %@ from %@",
		    _key, [_component name], [comp name]];
      }
    }
    result = value;
    goto done;
  }
  
  /* check in LSWMasterComponent config */
  if ((cConfig = [self configurationOfComponentNamed:@"master"]) != nil) {
    id value;
    
    if ((value = [cConfig valueForKey:_key])) {
      /* found a value in the components section */
      if (debugConfig) {
	if (comp != _component) {
	  [self debugWithFormat:
		  @"inherited value for config key %@ on %@ from global cfg",
		  _key, [_component name]];
	}
      }
      result = value;
      goto done;
    }
  }
 done:
  if (profileConfig) {
    st = [[NSDate date] timeIntervalSince1970] - st;
    printf("-configValueForKey:@\"%s\" inComponent:%s: %.3fs\n",
           [_key cString],
           [[_component name] cString],
           st);
  }
  return result;
}

- (LSSort *)eoSorter {
  if (self->eoSorter == nil)
    self->eoSorter = [[LSSort alloc] init];
  return self->eoSorter;
}

- (NSString *)labelForGlobalID:(EOGlobalID *)_gid {
  return (_gid == nil) 
    ? (id)@"empty"
    : [_gid labelForObjectInSession:self];
}
- (NSString *)labelForObject:(id)_object {
  return (_object == nil) 
    ? (id)@"empty"
    : [_object labelForObjectInSession:self];
}

- (NSDate *)timeOutDate {
  return [NSDate dateWithTimeIntervalSinceNow:[self timeOut]];
}

- (NSTimeZone *)timeZone {
  NSTimeZone *tzone;
  NSString   *abbrev;
  
  if (self->userDefaults == nil)
    [self logWithFormat:@"WARNING: user-defaults not yet set in session!"];
  
  abbrev = [self->userDefaults objectForKey:@"timezone"];
  tzone  = nil;
  
  if (abbrev != nil)
    tzone = [NSTimeZone timeZoneWithAbbreviation:abbrev];
  
#if LIB_FOUNDATION_LIBRARY
  // TODO: check whether we support CET with libFoundation/gstep-base
  if (tzone == nil)
    tzone = [NSTimeZone timeZoneWithAbbreviation:@"MET"];
#else
  if (tzone == nil)
    tzone = [NSTimeZone timeZoneWithAbbreviation:@"CET"];
#endif

  if (tzone == nil)
    [self logWithFormat:@"ERROR: got not timezone for session!"];
  
  return tzone;
}
- (NSArray *)timeZones {
  return [[self application] allTimeZones];
}

- (OGoNavigation *)navigation {
  NSAssert(self->navigation, @"no navigation object is set !");
  return self->navigation;
}
- (OGoClipboard *)favorites {
  if (self->favorites == nil) {
    self->favorites =
      [[OGoClipboard alloc] initWithUserDefaults:[self userDefaults]];
  }
  return self->favorites;
}

/* defaults */

- (NSUserDefaults *)userDefaults {
  return self->userDefaults;
}

/* localization */

- (void)setPrimaryLanguage:(NSString *)_language {
  /*
    This set the session language array of the user based on _language, which
    is a string in the form "Language_theme". For proper lookup the required
    sequence is:
      Language_theme
      English_theme
      Language
      English
      <all the other lprojs>
    Note that we always inherit from English, first from the theme, then from
    the default theme.
    
    TODO: I think we should only generate the relevant languages, but this
          might break existing code (eg SkyDisplayPreferences). Need to check.
  */
  NSString *langkey, *theme;
  id       langs;
  NSRange  r;
  
  langs = [self languages];
  
  if ([langs count] == 0) {
    [self setLanguages:[NSArray arrayWithObject:_language]];
    return;
  }
  
  langs = [langs mutableCopy];
  [langs removeObject:_language];
  [langs removeObject:@"English"];
  
  r = [_language rangeOfString:@"_"];
  if (r.length == 0) {
    langkey = _language;
    theme   = nil;
  }
  else {
    langkey = [_language substringToIndex:r.location];
    theme   = [_language substringFromIndex:(r.location + r.length)];
  }
  
  /* first check English special case (just English_theme,English) */
  
  if ([langkey isEqualToString:@"English"]) {
    if ([theme length] > 0) {
      /* first insert theme, then English */
      [langs insertObject:langkey   atIndex:0]; /* reverse order! */
      [langs insertObject:_language atIndex:0];
    }
    else { /* English, default theme, just insert English at top ... */
      [langs insertObject:langkey atIndex:0];
    }
    goto done; /* oh well, a goto ;-) */
  }
  
  /* next, check default theme (just Language,English) */
  
  if ([theme length] == 0) {
    [langs insertObject:@"English" atIndex:0]; /* reverse order! */
    [langs insertObject:_language  atIndex:0];
    goto done;
  }
  
  /* and finally, the complex case (not English, different theme) ... */
  
  [langs insertObject:@"English" atIndex:0]; /* reverse order! */
  [langs insertObject:langkey    atIndex:0];
  [langs insertObject:[@"English_" stringByAppendingString:theme] atIndex:0];
  [langs insertObject:_language  atIndex:0];
  
 done:
  [self setLanguages:langs];
  [langs release]; langs = nil;
}
- (NSString *)primaryLanguage {
  NSArray *langs;

  langs = [self languages];
  return ([langs count] == 0) ? @"English" : [langs objectAtIndex:0];
}

/* description */

- (NSString *)description {
  NSMutableString *desc;
  OWPasteboard    *pb;

  desc = [[NSMutableString alloc] init];
  pb   = [self transferPasteboard];

  [desc appendFormat:@"<%@[0x%08X]: id=%@",
          NSStringFromClass([self class]), self,
          [self sessionID]];

  if ([[pb types] count] > 0) {
    [desc appendFormat:@" pasteboard=%@",
          [pb objectForType:[pb availableTypeFromArray:[pb types]]]];
  }

  [desc appendString:@">"];
  return [desc autorelease];
}

/* Pasteboard */

- (OWPasteboard *)pasteboardWithName:(NSString *)_name {
  OWPasteboard *pb;
  *(&pb) = nil;
  
  SYNCHRONIZED(self) {
    pb = NSMapGet(self->name2pb, _name);
    if (pb == nil) {
      pb = [[OWPasteboard alloc] initWithName:_name];
      if (pb) {
        NSMapInsert(self->name2pb, _name, pb);
        RELEASE(pb);
        //[self logWithFormat:@"new pasteboard created %@", _name];
      }
      else
        [self logWithFormat:@"could not create pasteboard %@", _name];
    }
  }
  END_SYNCHRONIZED;

  return pb;
}

- (OWPasteboard *)transferPasteboard {
  return [self pasteboardWithName:LSWTransferPasteboardName];
}
- (void)transferObject:(id)_object owner:(WOComponent *)_owner {
  OWPasteboard *pb;
  NGMimeType   *type;

  if (_object == nil) {
    [self logWithFormat:
            @"tried to put nil object into transfer pasteboard (owner=%@)",
            _owner];
    return;
  }
  if ((type = [_object lswPasteboardType]) == nil) {
    [self logWithFormat:
            @"object to be transfered into pasteboard has no type "
            @"(object=%@, owner=%@)",
            _object, _owner];
    return;
  }
  
  pb = [self transferPasteboard];
  NSAssert(pb, @"no transfer pasteboard available ..");
  
  [pb declareTypes:[NSArray arrayWithObjects:&type count:1] owner:_owner];
  
  if (![pb setObject:_object forType:type]) {
    [self logWithFormat:@"couldn't set object %@ (type=%@) in pasteboard %@",
            _object, type, pb];
    return;
  }
}

- (NGMimeType *)preferredTransferObjectType {
  OWPasteboard *pb;
  
  pb = [self transferPasteboard];
  return [pb availableTypeFromArray:[pb types]];
}
- (id)getTransferObject {
  OWPasteboard *pb;
  
  pb = [self transferPasteboard];
  return [pb objectForType:[self preferredTransferObjectType]];
}
- (id)removeTransferObject {
  OWPasteboard *pb;
  id           object;
  
  pb     = [self transferPasteboard];
  object = [[pb objectForType:[self preferredTransferObjectType]] retain];
  [pb clear]; // remove all pasteboard contents
  return [object autorelease];
}

/* Activation */

- (WOComponent *)instantiateComponentForCommand:(NSString *)_command
  type:(NGMimeType *)_type
{
  return [self instantiateComponentForCommand:_command type:_type object:nil];
}

- (WOComponent *)instantiateComponentForCommand:(NSString *)_command
  type:(NGMimeType *)_type
  object:(id)_object
{
  NSString    *typeStr, *key, *componentName;
  WOComponent *component;
  
  typeStr = [NSString stringWithFormat:@"%@/%@", [_type type],[_type subType]];
  key     = [NSString stringWithFormat:@"%@ on %@", _command, typeStr];

  if ((componentName = NSMapGet(self->activationCommandToConfig, key))== nil) {
    NSBundle        *bundle;
    NSDictionary    *resourceQualifier;

    /* first check via NGBundleManager */

    resourceQualifier =
      [NSDictionary dictionaryWithObjectsAndKeys:
                      _command, @"verb",
                      typeStr,  @"type",
                      nil];

    bundle = [bm bundleProvidingResource:resourceQualifier
                 ofType:@"LSWCommands"];
    if (bundle) {
      NSDictionary *cmdCfg;
      
      cmdCfg = [bm configForResource:resourceQualifier ofType:@"LSWCommands"
                   providedByBundle:bundle];
      componentName = [cmdCfg objectForKey:@"component"];
    }

    if (componentName)
      NSMapInsert(self->activationCommandToConfig, key, componentName);
    else
      return nil;
  }
  
  component = [[self application] pageWithName:componentName 
				  inContext:[self context]];
  
  if (component == nil) {
    [self logWithFormat:@"couldn't load component %@ activated by %@ on %@",
            componentName, _command, _type];
    return nil;
  }
  
  if ([component respondsToSelector:
                 @selector(activateObject:verb:type:)]) {
    component = [component activateObject:_object verb:_command type:_type];
  }
  else if ([component respondsToSelector:
                      @selector(prepareForActivationCommand:type:object:)]) {
    if (![component prepareForActivationCommand:_command
                    type:_type
                    object:_object])
      component = nil;
  }
  else if ([component respondsToSelector:
                   @selector(prepareForActivationCommand:type:)]) {
    if (![component prepareForActivationCommand:_command type:_type])
      component = nil;
  }
  else if ([component respondsToSelector:
         @selector(prepareForActivationCommand:type:configuration:)]) {
    if (![component prepareForActivationCommand:_command
                    type:_type configuration:nil]) {
      component = nil;
    }
  }

  /* check whether activation returned an exception */
  
  if ([component isKindOfClass:[NSException class]]) {
    NSException *exception;
    NSString    *error;

    exception = (NSException *)component;
    component = nil;

    error = [NSString stringWithFormat:
			@"Could not activate type %@ with %@:\n%@: %@",
		        _type, _command, [exception name], [exception reason]];
    [[[self navigation] activePage] setErrorString:error];
  }
  
  return component;
}

/* Formatters */

- (NSFormatter *)formatString {
  return self->formatString;
}
- (NSFormatter *)formatDate {
  return self->formatDate;
}
- (NSFormatter *)formatTime {
  return self->formatTime;
}
- (NSFormatter *)formatDateTime {
#ifdef DEBUG
  NSAssert([self->formatDateTime isKindOfClass:[NSFormatter class]],
           @"formatDateTime is invalid !");
#endif
  return self->formatDateTime;
}
- (NSFormatter *)formatDateTimeTZ {
  return self->formatDateTimeTZ;
}

- (NSFormatter *)formatterForValue:(id)_value { // guess formatter
  if ([_value isKindOfClass:[NSDate class]])
    return [self formatDate];
  else
    return [self formatString];
}

/* Notifications */

- (NSNotificationCenter *)notificationCenter {
  return self->notificationCenter;
}

- (void)postChange:(NSString *)_cn onObject:(id)_object {
  [self->notificationCenter postNotificationName:_cn object:_object];
}

- (void)addObserver:(id)_observer selector:(SEL)_sel
  name:(NSString*)_notificationName object:(id)_object
{
  [self->notificationCenter addObserver:_observer selector:_sel
                            name:_notificationName object:_object];
}
- (void)removeObserver:(id)_observer name:(NSString*)_notiName object:_obj {
  [self->notificationCenter removeObserver:_observer name:_notiName object:_obj];
}
- (void)removeObserver:(id)_observer {
  [self->notificationCenter removeObserver:_observer];
}

/* Favorites */

- (void)addFavorite:(id)_fav {
  // DEPRECATED
  [[self favorites] addObject:_fav];
}
- (void)removeFavorite:(id)_fav {
  // DEPRECATED
  [[self favorites] removeObject:_fav];
}
- (BOOL)containsFavorites {
  // DEPRECATED
  return [self->favorites isNotEmpty];
}

- (void)setChoosenFavorite:(id)_fav { // TODO: what does that do?
  ASSIGN(self->choosenFavorite, _fav);
}
- (id)choosenFavorite {
  return self->choosenFavorite;
}

- (NSString *)labelForChoosenFavorite {
  return [self labelForObject:self->choosenFavorite];
}

/* PageManagement */

- (id)restorePageForContextID:(NSString *)_cid {
  WOComponent *p;

  if ((p = [super restorePageForContextID:_cid]) != nil) {
    if (debugPageCache)
      [self debugWithFormat:@"page was restored from cache .."];
    return p;
  }

  if (debugPageCache)
    [self debugWithFormat:@"page was restored from navigation .."];
  return [[self navigation] activePage];
}

- (void)savePage:(WOComponent *)_page {
  OGoNavigation *nav;
  WOComponent   *p;
  NSString      *cid;

  cid = [[self context] contextID];
  
  if (self->lastContextId != cid)
    ASSIGNCOPY(self->lastContextId, cid);
  
  if (![_page isContentPage]) {
    [super savePage:_page];
    return;
  }
  
  /* if page is a content page, it is managed by OGoNavigation */

  if (debugPageCache)
    [self debugWithFormat:@"page is stored in navigation .."];

  if ((nav = [self navigation]) == nil) {
    [super savePage:_page];
    return;
  }
  
  p = [nav activePage];

  /* check whether the page is already set as the last active page */
  if (_page != p) {
    if (debugPageCache) {
      [self debugWithFormat:
	      @"storing page %@ by placing on top of navigation.",
	      [_page name]];
    }
    [nav enterPage:_page];
  }
}

/* PersistentComponents */

- (NSMutableDictionary *)pComponents {
  if (self->pComponents == nil)
    self->pComponents = [[NSMutableDictionary alloc] init];
  return self->pComponents;
}

@end /* OGoSession */


@implementation WOComponent(PersistentComponents2)

- (id)persistentInstance {
  NSString  *className;
  WOSession *sn;
  id p;

  if ((sn = [self session]) == nil)
    return nil;
  
  className = NSStringFromClass([self class]);

  if ((p = [[sn pComponents] valueForKey:className]) != nil)
    return p;
  
  return nil;
}

- (void)registerAsPersistentInstance {
  NSString  *className;
  WOSession *sn;
  
  if ((sn = [self session]) == nil)
    return;

  className = NSStringFromClass([self class]);

  [[sn pComponents] takeValue:self forKey:className];
}

@end /* WOComponent(PersistentComponents) */
