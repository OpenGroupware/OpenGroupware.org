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
// $Id$

#include "OGoContextManager.h"
#include "OGoContextSession.h"
#include "LSBundleCmdFactory.h"
#include "common.h"
#include <NGExtensions/NGBundleManager.h>
#include <LSFoundation/LSFoundation.h>
#include <GDLAccess/EOSQLQualifier.h>

@interface OGoContextManager(FailedLogin)
- (void)handleFailedAuthorization:(NSString *)_login;
@end

@interface LSCommandContext(LDAPSupport)
+ (BOOL)useLDAPAuthorization;
+ (BOOL)isLDAPLoginAuthorized:(NSString *)_login password:(NSString *)_pwd;
@end

@interface OGoContextManager(LDAPSupport)
- (BOOL)isLDAPLoginAuthorized:(NSString *)_login password:(NSString *)_pwd;
@end

@interface OGoContextSession(LoginPrivates)
- (OGoContextSession *)login:(NSString *)_login password:(NSString *)_password
  crypted:(BOOL)_crypted isSessionLogEnabled:(BOOL)_isSessionLogEnabled;
@end

@implementation OGoContextManager

static OGoContextManager *lso = nil;
static int      LSUseLowercaseLogin            = -1;
static int      LSAllowSpacesInLogin           = -1;
static BOOL     logBundleLoading               = NO;
static BOOL     loadCommandBundlesOnStartup    = YES;
static BOOL     loadDataSourceBundlesOnStartup = YES;
static NSString *OGoBundlePathSpecifier        = nil;

+ (void)registerInUserDefaults:(NSUserDefaults *)_defs {
  NSArray *timeZoneNames;
  
  // TODO: why are the timezone names declared in this place? Sounds like
  //       a task for the user-interface?!
  timeZoneNames = [NSArray arrayWithObjects:
			     @"MET", @"GMT", @"PST", @"EST", @"CST", nil];
  [_defs registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
           @"",                           @"LSAuthLDAPServer",
           @"c=DE",                       @"LSAuthLDAPServerRoot",
           [NSNumber numberWithInt:389],  @"LSAuthLDAPServerPort",
           @"uid",                        @"LSLDAPLoginField",
           @"OGoModel",                   @"LSOfficeModel",
           timeZoneNames,                 @"LSTimeZones",
           @"OpenGroupware.org",          @"OGoBundlePathSpecifier",
           [NSNumber numberWithBool:YES], @"LSSessionAccountLogEnabled",
           nil]];
}

+ (void)loadBundlesOfType:(NSString *)_type inPath:(NSString *)_p {
  NGBundleManager *bm;
  NSFileManager   *fm;
  NSEnumerator *e;
  NSString     *p;
  
  if (logBundleLoading)
    NSLog(@"  load bundles of type %@ in path %@", _type, _p);
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
  }
}
+ (void)loadCommandBundles {
  NSEnumerator  *e;
  NSString      *p;
  NSArray       *pathes;
  
  pathes = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
					       NSAllDomainsMask,
					       YES);
  // TODO: use "Skyrix5" for Skyrix5 (patch in migration script)
  
  if (loadCommandBundlesOnStartup) {
    if (logBundleLoading) NSLog(@"load command bundles ...");
    e = [pathes objectEnumerator];
    while ((p = [e nextObject])) {
      p = [p stringByAppendingPathComponent:OGoBundlePathSpecifier];
      [self loadBundlesOfType:@"cmd" inPath:p];
      p = [p stringByAppendingPathComponent:@"Commands"];
      [self loadBundlesOfType:@"cmd" inPath:p];
    }
  }

  if (loadDataSourceBundlesOnStartup) {
    if (logBundleLoading) NSLog(@"load datasource bundles ...");
    e = [pathes objectEnumerator];
    while ((p = [e nextObject])) {
      p = [p stringByAppendingPathComponent:OGoBundlePathSpecifier];
      [self loadBundlesOfType:@"ds" inPath:p];
      p = [p stringByAppendingPathComponent:@"DataSources"];
      [self loadBundlesOfType:@"ds" inPath:p];
    }
  }
}

+ (void)initialize {
  static BOOL isInitialized = NO;
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  if (isInitialized) return;
  isInitialized = YES;
  
  [self registerInUserDefaults:[NSUserDefaults standardUserDefaults]];
  OGoBundlePathSpecifier = [[ud stringForKey:@"OGoBundlePathSpecifier"] copy];
  [self loadCommandBundles];
  
  LSUseLowercaseLogin    = [ud boolForKey:@"LSUseLowercaseLogin"] ? 1 : 0;
  LSAllowSpacesInLogin   = [ud boolForKey:@"AllowSpacesInLogin"] ? 1 : 0;
}

+ (id)defaultManager {
  if (lso == nil)
    lso = [[OGoContextManager alloc] init];
  return lso;
}

- (NSException *)_logSetupConnectException:(NSException *)_exception {
  NSLog(@"connect failed: %@", _exception);
  return nil;
}

- (NSString *)_fetchModelNameFromDatabase:(BOOL *)_canConnect_ {
  NSString *modelName = nil;
  
  NS_DURING {
    if (![self->adChannel isOpen]) {
        if (![self->adChannel openChannel]) {
          modelName = nil;
          *_canConnect_ = NO;
        }
    }
    if (*_canConnect_) {
      if ([self->adChannel evaluateExpression:
                 @"SELECT model_name FROM object_model"]) {
	NSArray      *attrs;
	NSDictionary *record;

	attrs = [self->adChannel describeResults];
	record = [self->adChannel fetchAttributes:attrs withZone:NULL];
	[self->adChannel cancelFetch];

	modelName = [record objectForKey:@"modelName"];
	[self->adContext commitTransaction];
      }
      [self->adChannel closeChannel];
    }
    else {
      [self logWithFormat:@"could not begin transaction."];
      modelName = nil;
    }
  }
  NS_HANDLER {
    [[self _logSetupConnectException:localException] raise];
    *_canConnect_ = NO;
  }
  NS_ENDHANDLER;
  
  return modelName;
}

- (BOOL)processModelWithName:(NSString *)modelName 
  connectionDictionary:(NSDictionary *)conDict
{
  NGBundleManager *bm;
  NSString        *modelPath;
  NSBundle        *modelBundle;

  if ([modelName length] == 0) {
    [self logWithFormat:@"ERROR: missing model name."];
    return NO;
  }
  
  if ((bm = [NGBundleManager defaultBundleManager]) == nil)
    [self logWithFormat:@"ERROR: could not instantiate bundle manager !"];
  
  modelBundle = [bm bundleProvidingResource:modelName ofType:@"EOModels"];
  if (modelBundle == nil) {
    [self logWithFormat:
	    @"ERROR: did not find bundle for model '%@' (type=EOModels)",
            modelName];
    modelPath = nil;
    return NO;
  }

  modelPath = [modelBundle pathForResource:modelName ofType:@"eomodel"];
  if (modelPath == nil) {
    NSLog(@"ERROR: did not find path for model %@ (type=eomodel) in bundle %@",
	  modelName, modelBundle);
    return NO;
  }
    
  if ([[NSFileManager defaultManager] fileExistsAtPath:modelPath])
    self->model = [[EOModel alloc] initWithContentsOfFile:modelPath];
    
  if (self->model == nil) {
    NSString *path;
  
    path = [[NGBundle mainBundle]
                      pathForResource:modelName
                      ofType:@"eomodel"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path])
      self->model = [[EOModel alloc] initWithContentsOfFile:path];
  }
  if (self->model == nil) {
    [self logWithFormat:@"ERROR(%s): could not load model: '%@'",
            __PRETTY_FUNCTION__, modelName];
    return NO;
  }
  
  self->personEntity = [[self->model entityNamed:@"Person"] retain];
  
  self->authAttributes =
      [[NSArray arrayWithObjects:
                [self->personEntity attributeNamed:@"login"],
                [self->personEntity attributeNamed:@"isLocked"],
                [self->personEntity attributeNamed:@"password"], nil] retain];
  
  [adaptor setModel:model];
  if (conDict) [adaptor setConnectionDictionary:conDict];
  
  return YES;
}

- (BOOL)setupAdaptor {
  /* TODO: clean up, split up */
  NSUserDefaults *defs;
  NSDictionary   *conDict;
  BOOL           canConnect = YES;
  NSString       *adaptorName;
  NSString       *modelName = nil;

  NSAssert1(self->adaptor == nil, @"adaptor already setup (%@) ..", self);
  
  defs = [NSUserDefaults standardUserDefaults];
  
  adaptorName = [defs stringForKey:@"LSAdaptor"];
  if (adaptorName == nil)
    adaptorName = @"PostgreSQL72";
  
  self->adaptor = [[EOAdaptor adaptorWithName:adaptorName] retain];
  
  if (self->adaptor == nil) {
    NSLog(@"ERROR(%s): could not instantiate adaptor for model %@ !",
          __PRETTY_FUNCTION__, [defs stringForKey:@"LSOfficeModel"]);
    return NO;
  }
  
  /* check connection dictionary availability */

  if ((conDict = [self->adaptor connectionDictionary]) == nil) {
    /* no connection dictionary set in adaptor .. */
    *(&conDict) = [defs dictionaryForKey:@"LSConnectionDictionary"];
      
    if (conDict)
      [self->adaptor setConnectionDictionary:conDict];
    else
      return NO;
  }
  
  self->adContext = [[self->adaptor   createAdaptorContext] retain];
  self->adChannel = [[self->adContext createAdaptorChannel] retain];
  
  /* check whether we can connect the database */
  
  *(&modelName) = /* eg OpenGroupware.org_PostgreSQL or Skyrix5_PostgreSQL */
    [OGoBundlePathSpecifier stringByAppendingString:@"_PostgreSQL"];
  
  if ([defs objectForKey:@"LSModelName"]) {
    *(&modelName) = [defs objectForKey:@"LSModelName"];
    
    [self debugWithFormat:@"using configured model name %@", modelName];
  }
  else
    modelName = [self _fetchModelNameFromDatabase:&canConnect];
  
  if (modelName) {
    canConnect = [self processModelWithName:modelName
		       connectionDictionary:conDict];
  }
  
  return canConnect;
}

- (id)init {
  if ((self = [super init])) {
    NSNotificationCenter *nc;

    self->cmdFactory = [[LSBundleCmdFactory alloc] init];

    nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
        selector:@selector(_requireClassDescriptionForClass:)
        name:@"EOClassDescriptionNeededForClassNotification"
        object:nil];

    if (![self setupAdaptor]) {
      [self release];
      return nil;
    }
  }
  return self;
}

- (void)dealloc {
  [self->lastAuthorized release];
  [self->adChannel      release];
  [self->adContext      release];
  [self->cmdFactory     release];
  [self->adaptor        release];
  [self->authAttributes release];
  [self->personEntity   release];
  [self->model          release];
  [super dealloc];
}

/* notifications */

- (void)_requireClassDescriptionForEntityName:(NSNotification *)_notification {
  NSString *entityName;
  EOEntity *entity;

  entityName = [_notification object];
  entity     = [self->model entityNamed:entityName];

  if (entity) {
    EOClassDescription *d;

    d = [[EOEntityClassDescription alloc] initWithEntity:entity];
    [EOClassDescription registerClassDescription:d
                        forClass:NSClassFromString([entity className])];
    [d release]; d = nil;
  }
}
- (void)_requireClassDescriptionForClass:(NSNotification *)_notification {
  EOClassDescription *d;
  NSString *entityName;
  EOEntity *entity;
  Class    c;
  NSString *className;

  c = [_notification object];
  className = NSStringFromClass(c);

  if (![className hasPrefix:@"LS"])
    return;

  entityName = [className substringFromIndex:2];
  entity     = [self->model entityNamed:entityName];

  if (entity == nil)
    return;

  d = [[EOEntityClassDescription alloc] initWithEntity:entity];
  [EOClassDescription registerClassDescription:d
                      forClass:NSClassFromString([entity className])];
  [d release]; d = nil;
}

/* accessors */

- (EOModel *)model {
  return self->model;
}
- (EOAdaptor *)adaptor {
  return self->adaptor;
}

- (id)commandFactory {
  return self->cmdFactory;
}

/* authorization */

static NSString *fmt = @"%@..-/.%@";

- (void)_expireCache:(NSTimer *)_timer {
  [self->lastAuthorized release];
  self->lastAuthorized = nil;
  [_timer invalidate];
}

- (BOOL)isLoginAuthorized:(NSString *)_login password:(NSString *)_pwd {
  return [self isLoginAuthorized:_login password:_pwd isCrypted:NO];
}

- (BOOL)isLoginAuthorized:(NSString *)_login password:(NSString *)_pwd
  isCrypted:(BOOL)_crypted
{
  /* TODO: split up this method */
  NSString            *key        = nil;
  NSMutableDictionary *row        = nil;
  NSString            *password   = nil;
  NSString            *cryptedPwd = nil;
  EOSQLQualifier      *qualifier  = nil;
  BOOL                isOk        = NO;
  
  if (_crypted) {
    NSLog(@"couldn`t perform LDAP-Login with crypted password");
    return NO;
  }
  
#if !LIB_FOUNDATION_LIBRARY
#  warning TODO: login space removal processing disabled on this platform
  if (LSAllowSpacesInLogin == 0) {
    NSLog(@"WARNING: disabled login spaces which are unsupported on this "
	  @"Foundation library.");
  }
#else
  if (LSAllowSpacesInLogin == 0)
    _login = [_login stringByTrimmingSpaces];
#endif
  
  if (LSUseLowercaseLogin)
    _login = [_login lowercaseString];

  key = [NSString stringWithFormat:fmt, _login, _pwd];
  
  if ([self->lastAuthorized isEqualToString:key])
    return YES;
  
  if ([_login length] == 0) {
    [self logWithFormat:@"no login name provided for authorization check"];
    return NO;
  }
  
  NSAssert(self->adContext, @"no adaptor context available");
  NSAssert(self->adChannel, @"no adaptor channel available");

  if (![self->adChannel isOpen]) {
    if (![self->adChannel openChannel]) {
      [self logWithFormat:@"could not open adaptor channel"];
      return NO;
    }
  }

  {
    EOAttribute *attr;
    NSString    *s;

    attr      = [self->personEntity attributeNamed:@"login"];
    s         = [[self adaptor] formatValue:_login forAttribute:attr];
    qualifier = [[EOSQLQualifier alloc]
                                 initWithEntity:self->personEntity
                                 qualifierFormat:@"(login = %@) AND"
                                 @" (isAccount=1)", s];
    qualifier = [qualifier autorelease];
  }

  if ([self->adContext beginTransaction]) {
    isOk = [self->adChannel selectAttributes:self->authAttributes
                describedByQualifier:qualifier
                fetchOrder:nil
                lock:NO];
    if (isOk) {
      id obj;

      while ((obj = [self->adChannel fetchAttributes:authAttributes
                         withZone:NULL]))
        row = obj;
        
      if (!(isOk = [self->adContext commitTransaction]))
        [self->adContext rollbackTransaction];
    }
    else
      [self->adContext rollbackTransaction];
      
    [self->adChannel closeChannel];

    if (!isOk) {
      [self logWithFormat:@"could not fetch login information .."];
      return NO;
    }
  }
  else {
    [self logWithFormat:@"could not begin database transaction"];
    [self->adChannel closeChannel];
    return NO;
  }
  
  if (row != nil && [[row valueForKey:@"isLocked"] boolValue]) {
    [self logWithFormat:@"Account '%@' is locked. Did deny login.", _login];
    return NO;
  }
  
  if ([LSCommandContext useLDAPAuthorization])
    return [self isLDAPLoginAuthorized:_login password:_pwd];

  if (row == nil) {
    [self logWithFormat:@"no user with login: %@", _login];
    return NO;
  }
  
  NSAssert(row, @"no row is set ..");

  password = [row objectForKey:@"password"];
  if (![password isNotNull]) {
    [self debugWithFormat:@"no password set for login %@.", _login];
    return ([_pwd length] == 0) ? YES : NO;
  }

  /* run crypt command */
  if (!_crypted) {
    id cryptCmd;

    cryptCmd = [self->cmdFactory command:@"crypt" inDomain:@"system"];
    NSAssert(cryptCmd, @"could not lookup crypt command !");
    
    [cryptCmd takeValue:_pwd     forKey:@"password"];
    [cryptCmd takeValue:password forKey:@"salt"];
    cryptedPwd = [cryptCmd runInContext:nil];
  }
  else {
    cryptedPwd = _pwd;
  }
  if ([cryptedPwd isEqualToString:password]) {
    ASSIGN(self->lastAuthorized, key);
    [NSTimer scheduledTimerWithTimeInterval:600
             target:self selector:@selector(_expireCache:)
             userInfo:nil repeats:NO];
    return YES;
  }
  else {
    [self handleFailedAuthorization:_login];
#if 0
    [self logWithFormat:@" pwd '%s' != '%s' (len=%i vs len=%i)",
            [cryptedPwd cString],
            [password cString],
            [cryptedPwd cStringLength],
            [password cStringLength]];
#endif
    if (!([_pwd length] == 0 && [_login isEqualToString:[self loginOfRoot]]))
      /* avoid log if we do the "automatic login with empty pwd" check */
      [self logWithFormat:@"login for user %@ wasn't authorized.", _login];
    return NO;
  }
}

// opening session

- (OGoContextSession *)login:(NSString *)_login password:(NSString *)_password {
  return [self login:_login password:_password crypted:NO
               isSessionLogEnabled:YES];
}

- (OGoContextSession *)login:(NSString *)_login password:(NSString *)_password
  crypted:(BOOL)_crypted
{
  return [self login:_login password:_password crypted:_crypted
               isSessionLogEnabled:YES];
}

- (OGoContextSession *)login:(NSString *)_login password:(NSString *)_password
  isSessionLogEnabled:(BOOL)_isSessionLogEnabled
{
  return [self login:_login password:_password crypted:NO
               isSessionLogEnabled:_isSessionLogEnabled];
}

- (OGoContextSession *)login:(NSString *)_login password:(NSString *)_password
  crypted:(BOOL)_crypted isSessionLogEnabled:(BOOL)_isSessionLogEnabled
{
  OGoContextSession *sn = nil;
  
  [self debugWithFormat:@"login user %@ ..", _login];
  if (![self isLoginAuthorized:_login password:_password isCrypted:_crypted]) {
    return nil;
  }

  sn = [[[OGoContextSession alloc] initWithManager:self] autorelease];
  
  return [sn login:_login
             password:_password
             crypted:_crypted
             isSessionLogEnabled:_isSessionLogEnabled] ? sn:nil;
}

/* logging */

- (void)logWithFormat:(NSString *)_format, ... {
  NSString *value = nil;
  va_list  ap;

  va_start(ap, _format);
  value = [[NSString alloc] initWithFormat:_format arguments:ap];
  va_end(ap);

  NSLog(@"OGoContextManager: %@", value);
  [value release];
}
- (void)debugWithFormat:(NSString *)_format, ... {
  static char showDebug = 2;
  NSString *value = nil;
  va_list  ap;

  if (showDebug == 2) {
    showDebug = [[[NSUserDefaults standardUserDefaults]
                                  objectForKey:@"LSDebuggingEnabled"]
                                  boolValue] ? 1 : 0;
  }

  if (showDebug) {
    va_start(ap, _format);
    value = [[NSString alloc] initWithFormat:_format arguments:ap];
    va_end(ap);

    NSLog(@"OGoContextManager(d): %@", value);
    [value release];
  }
}

/* description */

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@[0x08%X]: model=%@ adaptor=%@>",
                     NSStringFromClass([self class]), self,
                     [self model], [self adaptor]];
}

/* startup */

- (BOOL)canConnectToDatabase {
  if (![self->adChannel isOpen])
    return [self->adChannel openChannel];
  return YES;
}

- (NSString *)loginOfRoot { // the login-name of root account (id=10000)
  static NSString *rootLogin = nil;
  EOSQLQualifier *qualifier;
  NSArray        *attributes;
  BOOL           isOk;
  
  if (rootLogin)
    return rootLogin;
  
  NSAssert(self->adContext, @"no adaptor context available");
  NSAssert(self->adChannel, @"no adaptor channel available");
  
  qualifier = [[EOSQLQualifier alloc]
                                 initWithEntity:self->personEntity
                                 qualifierFormat:@"companyId = 10000"];
  qualifier = [qualifier autorelease];
    
  attributes = [NSArray arrayWithObjects:
                          [self->personEntity attributeNamed:@"login"],
                          [self->personEntity attributeNamed:@"companyId"],
                          nil];

  if (![self->adChannel isOpen]) {
    if (![self->adChannel openChannel]) {
      [self logWithFormat:@"could not open adaptor channel"];
      return nil;
    }
  }  
  
  if (![self->adContext beginTransaction]) {
    [self logWithFormat:@"could not begin database transaction"];
    [self->adChannel closeChannel];
    return nil;
  }
  isOk = [self->adChannel selectAttributes:attributes
              describedByQualifier:qualifier
              fetchOrder:nil
              lock:NO];
  if (isOk) {
    NSDictionary *obj;
    
    while ((obj = [self->adChannel fetchAttributes:attributes withZone:NULL]))
      rootLogin = [obj objectForKey:@"login"];

    if (rootLogin)
      rootLogin = [rootLogin copy];
    else
      [self logWithFormat:@"could not find root login (id=10000)"];
    
    if (!(isOk = [self->adContext commitTransaction])) 
      [self->adContext rollbackTransaction];        
  }
  else {
    [self->adContext rollbackTransaction];
  }
  [self->adChannel closeChannel];
  
  if (!isOk) {
    [self logWithFormat:@"could not fetch root login .."];
    rootLogin = nil;
  }
  return rootLogin;
}

@end /* OGoContextManager */
