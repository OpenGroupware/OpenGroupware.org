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

#include "OGoContextManager.h"
#include "OGoContextSession.h"
#include "LSBundleCmdFactory.h"
#include "NGBundleManager+OGo.h"
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
static BOOL     loadCommandBundlesOnStartup    = YES;
static BOOL     loadDataSourceBundlesOnStartup = YES;
static NSString *OGoBundlePathSpecifier        = nil;
static NSString *FHSOGoBundleDir = @"lib/opengroupware.org-1.1/";

+ (void)registerInUserDefaults:(NSUserDefaults *)_defs {
  NSArray      *timeZoneNames;
  NSDictionary *defs;
  NSDictionary *condict;
  
  // TODO: why are the timezone names declared in this place? Sounds like
  //       a task for the user-interface?!
  
  condict = [NSDictionary dictionaryWithObjectsAndKeys:
			    @"OGo",       @"userName",
			    @"OGo",       @"databaseName",
  			    @"5432",      @"port",
			    @"127.0.0.1", @"hostName",
			  nil];
  
  timeZoneNames = [NSArray arrayWithObjects:
			     @"MET", @"GMT", @"PST", @"EST", @"CST", nil];
  defs = [NSDictionary dictionaryWithObjectsAndKeys:
           @"",                            @"LSAuthLDAPServer",
           @"c=DE",                        @"LSAuthLDAPServerRoot",
           [NSNumber numberWithInt:389],   @"LSAuthLDAPServerPort",
           @"uid",                         @"LSLDAPLoginField",
           @"OGoModel",                    @"LSOfficeModel",
           @"PostgreSQL",                  @"LSAdaptor",
           timeZoneNames,                  @"LSTimeZones",
	   condict,                        @"LSConnectionDictionary",
           @"OpenGroupware.org-1.1",      @"OGoBundlePathSpecifier",
           @"lib/opengroupware.org-1.1/", @"OGoFHSBundleSubPath",
           [NSNumber numberWithBool:YES],  @"LSSessionAccountLogEnabled",
          nil];
  [_defs registerDefaults:defs];
}

+ (void)loadCommandBundles {
  NGBundleManager *bm;
  NSString     *p;
  NSArray      *pathes;
  NSArray      *oldPathes;

  /* find pathes */
  
  // TODO: use "Skyrix5" for Skyrix5 (patch in migration script)
  pathes = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
					       NSAllDomainsMask,
					       YES);
  if ([FHSOGoBundleDir length] > 0) {
    // TODO: should be some search path, eg LD_LIBRARY_SEARCHPATH?
    NSString *bp;
    
    bp     = [@"/usr/local/" stringByAppendingPathComponent:FHSOGoBundleDir];
    p      = [bp stringByAppendingPathComponent:@"commands"];
    pathes = [pathes arrayByAddingObject:p];
    p      = [bp stringByAppendingPathComponent:@"datasources"];
    pathes = [pathes arrayByAddingObject:p];
    
    bp     = [@"/usr/" stringByAppendingPathComponent:FHSOGoBundleDir];
    p      = [bp stringByAppendingPathComponent:@"commands"];
    pathes = [pathes arrayByAddingObject:p];
    p      = [bp stringByAppendingPathComponent:@"datasources"];
    pathes = [pathes arrayByAddingObject:p];
  }

  /* temporarily patch bundle search path */
  
  bm = [NGBundleManager defaultBundleManager];
  oldPathes = [[bm bundleSearchPaths] copy];
  if ([pathes count] > 0) {
    /* add default fallback */
    [bm setBundleSearchPaths:[pathes arrayByAddingObjectsFromArray:oldPathes]];
  }
  
  /* load bundles */
  
  if (loadCommandBundlesOnStartup) {
    [bm loadBundlesOfType:@"model" typeDirectory:@"Models"   inPaths:pathes];
    [bm loadBundlesOfType:@"cmd"   typeDirectory:@"Commands" inPaths:pathes];
  }
  if (loadDataSourceBundlesOnStartup)
    [bm loadBundlesOfType:@"ds" typeDirectory:@"DataSources" inPaths:pathes];
  
  /* unpatch bundle search path */
  
  [bm setBundleSearchPaths:oldPathes];
  [oldPathes release];
}

+ (void)initialize {
  static BOOL isInitialized = NO;
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  if (isInitialized) return;
  isInitialized = YES;
  
  [self registerInUserDefaults:[NSUserDefaults standardUserDefaults]];
  OGoBundlePathSpecifier = [[ud stringForKey:@"OGoBundlePathSpecifier"] copy];
  FHSOGoBundleDir        = [[ud stringForKey:@"OGoFHSBundleSubPath"]    copy];
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
  
  /* locate model using bundle manager */
  
  if ((bm = [NGBundleManager defaultBundleManager]) == nil) {
    [self logWithFormat:@"ERROR: could not instantiate bundle manager !"];
    return NO;
  }
  
  modelBundle = [bm bundleProvidingResource:modelName ofType:@"EOModels"];
  if (modelBundle == nil) {
    [self logWithFormat:
	    @"ERROR: did not find bundle for model '%@' (type=EOModels)",
            modelName];
    modelPath = nil;
    return NO;
  }
  
  /* load model resources from bundle */
  
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
  if (self->personEntity == nil) {
    [self logWithFormat:
	      @"ERROR(%s): did not find 'Person' entity in model: '%@'",
            __PRETTY_FUNCTION__, modelName];
    return NO;
  }
  
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
    adaptorName = @"PostgreSQL";
  
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
  
  *(&modelName) = [defs stringForKey:@"LSModelName"];
  if (modelName != nil) {
    [self debugWithFormat:@"using configured model name %@", modelName];
  }
  else {
    /* eg OpenGroupware.org_PostgreSQL or Skyrix5_PostgreSQL */
    NSString *p;
    NSRange  r;
    
    p = OGoBundlePathSpecifier;
    r = [p rangeOfString:@"-"];
    if (r.length > 0) /* strip off version, like in "OpenGroupware.org-1.1" */
      p = [p substringToIndex:r.location];
    *(&modelName) = [p stringByAppendingString:@"_PostgreSQL"];
  }
  if (modelName != nil) {
    canConnect = [self processModelWithName:modelName
		       connectionDictionary:conDict];
  }
  else {
    [self logWithFormat:@"ERROR: got no name for model?"];
    canConnect = NO;
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
  
  if (self->authAttributes == nil) {
    [self logWithFormat:@"ERROR(%s): auth attributes are not set up!",
	    __PRETTY_FUNCTION__];
    return NO;
  }
  
  if (_crypted) {
    NSLog(@"ERROR(%s): cannot not perform LDAP-Login with crypted password",
	  __PRETTY_FUNCTION__);
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
    NSException *error;
    
    error = [self->adChannel selectAttributesX:self->authAttributes
		 describedByQualifier:qualifier
		 fetchOrder:nil
		 lock:NO];
    isOk = error == nil ? YES : NO;
    if (error == nil) {
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
      [self logWithFormat:@"could not fetch login information: %@", error];
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
  NSException    *error;
  
  if (rootLogin != nil)
    return rootLogin;

  /* check preconditions */

  if (self->adContext == nil) {
    [self logWithFormat:@"ERROR: no adaptor context available!"];
    return nil;
  }
  if (self->adChannel == nil) {
    [self logWithFormat:@"ERROR: no adaptor channel available!"];
    return nil;
  }
  if (self->personEntity == nil) {
    [self logWithFormat:@"ERROR: no person entity available!"];
    return nil;
  }
  
  /* fetch name of root */
  
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
  error = [self->adChannel selectAttributesX:attributes
	       describedByQualifier:qualifier
	       fetchOrder:nil
	       lock:NO];
  isOk = error == nil ? YES : NO;
  if (error == nil) {
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
