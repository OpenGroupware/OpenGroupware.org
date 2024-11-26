/*
  Copyright (C) 2000-2007 SKYRIX Software AG

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

#include "LSCommandContext.h"
#include "LSCommandKeys.h"
#include "common.h"
#include <LSFoundation/OGoAccessHandler.h>
#include <LSFoundation/LSFoundation.h>

#if 0

#define TIME_START(_timeDescription) { struct timeval tv; double ti; NSString *timeDescription = nil; *(&ti) = 0; *(&timeDescription) = nil;timeDescription = [_timeDescription copy]; gettimeofday(&tv, NULL); ti =  (double)tv.tv_sec + ((double)tv.tv_usec / 1000000.0); printf("{\n");

#define TIME_END gettimeofday(&tv, NULL); ti = (double)tv.tv_sec + ((double)tv.tv_usec / 1000000.0) - ti; printf("}\n[%s] <%s> : time needed: %4.4fs\n", __PRETTY_FUNCTION__, [timeDescription cString], ti < 0.0 ? -1.0 : ti); [timeDescription release]; timeDescription = nil;  } 

#else

#define TIME_START(_timeDescription)
#define TIME_END()

#endif

@interface OGoAccessManager(PrivateInt)

- (NSNotificationCenter *)notificationCenter;
- (void)postFlagsDidChange:(EOGlobalID *)_gid;

- (BOOL)_checkBundleForAccessHandlers:(NSBundle *)_bundle;
- (id<OGoAccessHandler>)_accessHandlerForObjectID:(EOGlobalID *)_gid;
- (void)_checkForAccessHandlers;

- (EOEntity *)aclEntity;

- (EOAdaptorChannel *)beginTransaction;
- (void)commitTransaction;
- (void)rollbackTransaction;
- (NSDictionary *)_operationsForObjectIds:(NSArray *)_objIds
  accessGlobalIDs:(NSArray *)_accGids
  allowed:(BOOL)_allowed;
- (EODatabase *)_database;
- (BOOL)updateOperation:(NSString *)_operation
  onObjectID:(EOGlobalID *)_objId
  forAccessGlobalID:(EOGlobalID *)_accessId
  checkAccess:(BOOL)_accessCheck;
- (BOOL)insertOperation:(NSString *)_operation
  onObjectID:(EOGlobalID *)_objId
  forAccessGlobalID:(EOGlobalID *)_accessId
  checkAccess:(BOOL)_accessCheck;
- (BOOL)deleteOperationForObjectID:(EOGlobalID *)_objId
  accessGlobalID:(EOGlobalID *)_accessId
  checkAccess:(BOOL)_accessCheck;
- (BOOL)_checkAccessMask:(NSString *)_mask with:(NSString *)_operation;
@end

static BOOL debugOn = NO;

NSString *SkyAccessFlagsDidChange = @"SkyAccessFlagsDidChangeNotifikation";

@implementation OGoAccessManager

static NSString *CtxCacheID = @"_cache_SkyAccessManager_objectId2AccessCache";
static Class   StrClass = Nil;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  debugOn = [ud boolForKey:@"OGoAccessManagerDebugEnabled"];
  StrClass = [NSString class];
}

- (id)initWithContext:(LSCommandContext *)_ctx {
  if ((self = [super init]) != nil) {
    self->context = _ctx; /* not retained */

    if (self->context == nil) {
      [self errorWithFormat:@"###1 could not find command context"];
      [self release];
      return nil;
    }
  }
  return self;
}

- (void)dealloc {
  [[self notificationCenter] removeObserver:self];
  [self->accessHandlers release];
  [super dealloc];  
}

/* notifications */

- (NSNotificationCenter *)notificationCenter {
  return [NSNotificationCenter defaultCenter];
}

- (void)postFlagsDidChange:(EOGlobalID *)_gid {
  [[self notificationCenter]
         postNotificationName:SkyAccessFlagsDidChange
         object:_gid userInfo:nil];
}

/* operations */

- (NSMutableDictionary *)objectId2AccessCache {
  NSMutableDictionary *d;
  
  if ((d = [self->context valueForKey:CtxCacheID]))
    return d;
  
  d = [NSMutableDictionary dictionaryWithCapacity:511];
  [self->context takeValue:d forKey:CtxCacheID];
  return d;
}

- (BOOL)operation:(NSString *)_operation allowedOnObjectID:(EOGlobalID *)_oid {
  if (![_oid isNotNull])
    return YES;
  
  return [self operation:_operation 
	       allowedOnObjectIDs:[NSArray arrayWithObject:_oid]];
}

- (BOOL)operation:(NSString *)_operation allowedOnObjectIDs:(NSArray *)_oids {
  EOGlobalID *agid;
  
  agid = [[self->context valueForKey:LSAccountKey] valueForKey:@"globalID"];
  return [self operation:_operation allowedOnObjectIDs:_oids
               forAccessGlobalID:agid];
}

- (BOOL)operation:(NSString *)_operation
  allowedOnObjectID:(EOGlobalID *)_oid
  forAccessGlobalID:(EOGlobalID *)_accountID
{
  if (![_oid isNotNull])
    return YES;
  
  return [self operation:_operation
	       allowedOnObjectIDs:[NSArray arrayWithObject:_oid]
	       forAccessGlobalID:_accountID];
}


- (BOOL)operation:(NSString *)_operation
  allowedOnObjectIDs:(NSArray *)_oids
  forAccessGlobalID:(EOGlobalID *)_accountID
{
  id<OGoAccessHandler> handler  = nil;
  BOOL                 result;
  NSArray              *oids;

  TIME_START(@"operation:allowedOnObjectIDs:forAccessGlobalID:");

  result  = YES;
  // unused: login   = [self->context valueForKey:LSAccountKey];
  // unused: loginID = [login valueForKey:@"globalID"];
  
  if (![_accountID isNotNull]) {
    [self warnWithFormat:@"%s: missing _accountID", __PRETTY_FUNCTION__];
    return NO;
  }
  if (![_oids isNotEmpty])      return NO;
  if (![_operation isNotEmpty]) return YES;
  
  oids = nil;
  { /* use cache */
    NSDictionary *cache;
    id           *unknown, obj;
    int          cnt, unCnt;
    NSEnumerator *enumerator;

    cnt     = [_oids count];
    cache   = [self objectId2AccessCache];
    unCnt   = 0;
    unknown  = calloc(cnt + 1, sizeof(id));
    oids    = nil;

    enumerator = [_oids objectEnumerator];
    
    while ((obj = [enumerator nextObject]) != nil) {
      NSString *access;
      
      if ((access = [cache objectForKey:[obj keyValues][0]])) {
        if (![self _checkAccessMask:access with:_operation])
          break;
      }
      else {
        unknown[unCnt] = obj;
	unCnt++;
      }
    }
    if (!obj && unCnt) {
      oids = [NSArray arrayWithObjects:unknown count:unCnt];
    }
    if (unknown != NULL) free(unknown);  unknown  = NULL;
    if (obj != nil) /* access was denied */
      result = NO;
  }
  
  if (result && [oids isNotEmpty]) {
    handler = [self _accessHandlerForObjectID:[_oids lastObject]];
      
    if (handler != nil) {
      result = [handler operation:_operation
			allowedOnObjectIDs:oids 
			forAccessGlobalID:_accountID];
	
      if (debugOn) {
	[self debugWithFormat:
		@"%s\n  operation: %@\n  check on: %@\n  access-gid: %@\n"
		@"  handler: %@\n  => %@",
		__PRETTY_FUNCTION__, _operation, oids, _accountID,
		handler, result ? @"allowed" : @"denied"];
      }
    }
    else {
      /* 
	 We default to access-allowed (permissions will usually get checked 
	 later in the commands).
      */
      result = YES;
    }
  }
  TIME_END();
  return result;
}
         
- (NSArray *)objects:(NSArray *)_oids forOperation:(NSString *)_str {
  /* 
     filters the given OIDs for those OIDs where the login account has
     the permissions given in _str.
  */
  EOGlobalID *agid;
  NSArray    *oids;

  agid = [[self->context valueForKey:LSAccountKey] valueForKey:@"globalID"];
  
  if (debugOn) {
    [self logWithFormat:@"CHECK permission '%@' against %@ on IDs (#%d): %@", 
	  _str, agid, [_oids count], _oids];
  }
  
  oids = [self objects:_oids forOperation:_str forAccessGlobalID:agid];
  
  if (debugOn)
    [self logWithFormat:@"  filtered %d: %@", [oids count], oids];
  return oids;
}

- (NSArray *)_checkCachedOIDs:(NSArray *)_oids forOperation:(NSString *)_str
  addToAllowedCArray:(id *)allowed allowedCount:(unsigned *)allowCnt
{
  NSDictionary  *cache;
  EOKeyGlobalID *gid;
  id            *unknown;
  int           unCnt;
  NSEnumerator  *enumerator;
  NSArray       *oids;
  
  cache   = [self objectId2AccessCache];
  unCnt   = 0;
  unknown = calloc([_oids count] + 1, sizeof(id));
  oids    = nil;
  
  enumerator = [_oids objectEnumerator];
  while ([(gid = [enumerator nextObject]) isNotNull]) {
    NSString *access;
    
    if ((access = [cache objectForKey:[gid keyValues][0]]) == nil) {
      /* permissions not cached yet */
      unknown[unCnt] = gid;
      unCnt++;
      continue;
    }
    
    if (![self _checkAccessMask:access with:_str])
      /* access denied */
      continue;
    
    allowed[*allowCnt] = gid;
    (*allowCnt)++;
  }
  
  if (unCnt > 0) oids = [NSArray arrayWithObjects:unknown count:unCnt];
  if (unknown != NULL) free(unknown); unknown  = NULL;
  return oids;
}
- (void)_checkOIDs:(NSArray *)_oids forOperation:(NSString *)_str
  forAccessGlobalID:(EOGlobalID *)_accountID
  addToAllowedCArray:(id *)allowed allowedCount:(unsigned *)allowCnt
{
  /* let handler filters OIDs and add the result set to the allowed array */
  id<OGoAccessHandler> handler;
  NSEnumerator  *enumerator;
  EOKeyGlobalID *gid;
  NSArray       *oids;
  
  if (![_oids isNotEmpty]) /* nothing to check */
    return;
  
  if ((handler = [self _accessHandlerForObjectID:[_oids lastObject]]) == nil) {
    /* not necessarily a problem, eg called on CompanyValue entities */
    [self debugWithFormat:@"found no access handler for OID: %@",
	    [_oids lastObject]];
  }
  
  if (debugOn) {
    [self debugWithFormat:@"  check op '%@' account %@: %@",
	    _str, _accountID, _oids];
  }
  
  /* ask handler to restrict the set of OIDs */
  
  oids = [handler objects:_oids forOperation:_str
		  forAccessGlobalID:_accountID];
  
  // TODO: this information needs to get cached?!
  
  enumerator = [oids objectEnumerator];
  while ((gid = [enumerator nextObject]) != nil) {
    allowed[*allowCnt] = gid;
    (*allowCnt)++;
  }
}

- (BOOL)isRootLoginID:(id)_loginID {
  return [_loginID intValue] == 10000 ? YES : NO;
}

- (BOOL)hasAccessHandlersForGlobalIDs:(NSArray *)_oids {
  return [self _accessHandlerForObjectID:[_oids lastObject]] != nil ? YES : NO;
}

- (NSArray *)objects:(NSArray *)_oids
  forOperation:(NSString *)_str
  forAccessGlobalID:(EOGlobalID *)_accountID
{
  /* 
     filters the given OIDs for those OIDs where the account identified by
     _accountID has the permissions given in _str.
     
     Note: only seems to work on a set of OIDs of the same entity! (the handler
           is retrieved from the last OID's entity)
  */
  // TODO: this does not cache results!
  EOGlobalID   *loginID;
  id           *allowed;
  unsigned int allowCnt, cnt;
  NSArray      *oids;
  
  loginID = [[self->context valueForKey:LSAccountKey] valueForKey:@"globalID"];
  
  if (debugOn) {
    [self logWithFormat:
	    @"CHECK permission '%@' against %@ (login=%@) on IDs (%d): %@", 
	  _str, _accountID, loginID, [_oids count], _oids];
  }
  
  if (![_oids isNotNull]) {
    [self warnWithFormat:@"%s: no oids passed in.", __PRETTY_FUNCTION__];
    return nil;
  }
  if (![_oids isNotEmpty]) {
    [self debugWithFormat:@"  no IDs to check ..."];
    return [NSArray array];
  }
  
  if (![_str isNotNull])
    _str = nil;
  if (![_str isNotEmpty]) {
    [self debugWithFormat:@"  no permission to check ..."];
    return _oids;
  }
  
  if (![_accountID isNotNull]) {
    [self errorWithFormat:@"%s: missing access id", __PRETTY_FUNCTION__];
    return [NSArray array];
  }

  /* start real processing */
  
  if (![loginID isEqual:_accountID]) {
    NSAssert([self isRootLoginID:loginID],
             @"only root can use check access of other account-ids");
  }
  
  TIME_START(@"get access");
  
  if (![self hasAccessHandlersForGlobalIDs:_oids]) {
    [self debugWithFormat:@"  found no access handler ..."];
    return _oids;
  }
  
  cnt      = [_oids count];
  allowCnt = 0;
  allowed  = calloc(cnt + 4, sizeof(id));
  oids     = nil;
  
  /* first check cached OID permissions */
  
  oids = [self _checkCachedOIDs:_oids forOperation:_str
	       addToAllowedCArray:allowed allowedCount:&allowCnt];
  
  /* fetch remaining OIDs */
  
  [self _checkOIDs:oids forOperation:_str forAccessGlobalID:_accountID
	addToAllowedCArray:allowed allowedCount:&allowCnt];
  
  /* construct result set */
  
  oids = [NSArray arrayWithObjects:allowed count:allowCnt];
  if (allowed != NULL) free(allowed); allowed = NULL;
  TIME_END();
  return oids;
}

- (NSString *)operationsForObjectId:(EOGlobalID *)_objId
  accessGlobalID:(EOGlobalID *)_accessId
  queryAllowed:(BOOL)_allowed
{
  // TODO: that somewhat weird ...
  NSDictionary *ops;

  ops = [self _operationsForObjectIds:[NSArray arrayWithObject:_objId]
	      accessGlobalIDs:[NSArray arrayWithObject:_accessId]
	      allowed:YES];
  return [[[[ops objectEnumerator] nextObject] objectEnumerator] nextObject];
}
- (NSString *)allowedOperationsForObjectId:(EOGlobalID *)_objId
  accessGlobalID:(EOGlobalID *)_accessId
{
  return [self operationsForObjectId:_objId accessGlobalID:_accessId 
	       queryAllowed:YES];
}

- (NSString *)deniedOperationsForObjectId:(EOGlobalID *)_objId
  accessGlobalID:(EOGlobalID *)_accessId
{
  return [self operationsForObjectId:_objId accessGlobalID:_accessId 
	       queryAllowed:NO];
}

/* returns a dictionary with accessGIDs as keys and operation as values */

- (NSDictionary *)allowedOperationsForObjectIds:(NSArray *)_objIds {
  return [self _operationsForObjectIds:_objIds accessGlobalIDs:nil 
	       allowed:YES];
}
- (NSDictionary *)deniedOperationsForObjectIds:(NSArray *)_objIds {
  return [self _operationsForObjectIds:_objIds accessGlobalIDs:nil 
	       allowed:NO];  
}

- (NSDictionary *)allowedOperationsForObjectIds:(NSArray *)_objIds
  accessGlobalIDs:(NSArray *)_accessIds
{
  return [self _operationsForObjectIds:_objIds accessGlobalIDs:_accessIds
               allowed:YES];
}
- (NSDictionary *)deniedOperationsForObjectIds:(NSArray *)_objIds
  accessGlobalIDs:(NSArray *)_accessIds
{
  return [self _operationsForObjectIds:_objIds accessGlobalIDs:_accessIds
               allowed:NO];
}


- (NSDictionary *)allowedOperationsForObjectId:(EOGlobalID *)_objId {
  return [[[self _operationsForObjectIds:[NSArray arrayWithObject:_objId]
                 accessGlobalIDs:nil allowed:YES] objectEnumerator] nextObject];
}
- (NSDictionary *)deniedOperationsForObjectId:(EOGlobalID *)_objId {
  return [[[self _operationsForObjectIds:[NSArray arrayWithObject:_objId]
                 accessGlobalIDs:nil allowed:NO] objectEnumerator] nextObject];
}


- (BOOL)updateOperation:(NSString *)_operation
  onObjectID:(EOGlobalID *)_objId
  forAccessGlobalID:(EOGlobalID *)_accessId
{
  return [self updateOperation:_operation onObjectID:_objId
               forAccessGlobalID:_accessId checkAccess:YES];
}

- (BOOL)insertOperation:(NSString *)_operation
  onObjectID:(EOGlobalID *)_objId
  forAccessGlobalID:(EOGlobalID *)_accessId
{
  return [self insertOperation:_operation onObjectID:_objId
               forAccessGlobalID:_accessId checkAccess:YES];
}

- (BOOL)deleteOperationForObjectID:(EOGlobalID *)_objId
  accessGlobalID:(EOGlobalID *)_accessId
{
  return [self deleteOperationForObjectID:_objId
               accessGlobalID:_accessId checkAccess:YES];
}

- (BOOL)setOperation:(NSString *)_operation
  onObjectID:(EOGlobalID *)_objId
  forAccessGlobalID:(EOGlobalID *)_accessId
{
  if (![_objId isNotNull]) {
    [self warnWithFormat:@"%s: got no object id", __PRETTY_FUNCTION__];
    return NO;
  }
  
  if (![self operation:@"w" allowedOnObjectID:_objId]) {
    [self warnWithFormat:@"%s: setOperation not allowed for %@",
          __PRETTY_FUNCTION__, _objId];
    return NO;
  }
  
  if (![_operation isNotEmpty]) {
    return [self deleteOperationForObjectID:_objId accessGlobalID:_accessId
                 checkAccess:NO];
  }
  
  if ([self allowedOperationsForObjectId:_objId accessGlobalID:_accessId]) {
    return [self updateOperation:_operation onObjectID:_objId
                 forAccessGlobalID:_accessId checkAccess:NO];
  }
  
  return [self insertOperation:_operation onObjectID:_objId
	       forAccessGlobalID:_accessId checkAccess:NO];
}

/* _operation is a dictionary with globalid as key and operation as value */

- (BOOL)setOperations:(NSDictionary *)_operations
  onObjectID:(EOGlobalID *)_objId
{
  NSEnumerator *enumerator;
  id           gid;
  BOOL         result;

  result = YES;

  if (![_objId isNotNull]) {
    [self warnWithFormat:@"%s: got no object id", __PRETTY_FUNCTION__];
    return NO;
  }
  
  if (![self operation:@"w" allowedOnObjectID:_objId]) {
    [self warnWithFormat:@"%s: setOperation not allowed for %@",
          __PRETTY_FUNCTION__, _objId];
    return NO;
  }
  
  enumerator = [_operations keyEnumerator];
  while ((gid = [enumerator nextObject]) != nil) {
    NSString *value;

    value  = [_operations objectForKey:gid];
    
    if (![value isNotEmpty]) {
      result = [self deleteOperationForObjectID:_objId accessGlobalID:gid
                     checkAccess:NO];
    }
    else if ([self allowedOperationsForObjectId:_objId accessGlobalID:gid]) {
      result = [self updateOperation:value onObjectID:_objId
                     forAccessGlobalID:gid checkAccess:NO];
    }
    else {
      result = [self insertOperation:value onObjectID:_objId
                     forAccessGlobalID:gid checkAccess:NO];
    }
    if (!result)
      break;
  }
  return result;
}

/* debugging */

- (BOOL)isDebuggingEnabled {
  return debugOn;
}

/* ******************** private ******************** */

/* entity */

- (EOEntity *)aclEntity {
  static EOEntity *entity = nil; /* assumes only one model per application */
  if (entity) return entity;
  entity = [[[[[self _database] adaptor] model] 
	             entityNamed:@"ObjectAcl"] retain];
  return entity;
}

// more

- (NSString *)_stringGIDInQualFor:(NSArray *)_array {
  NSMutableString *str;
  NSEnumerator    *enumerator;
  EOKeyGlobalID   *gid;

  if (![_array isNotNull])
    return nil;
  
  enumerator = [_array objectEnumerator];
  str        = nil;
  while ((gid = [enumerator nextObject]) != nil) {
    if (![gid isNotNull]) /* skip nulls */
      continue;
    
    if (str)
      [str appendString:@", "];
    else
      str = [NSMutableString stringWithCapacity:32];
    
    if (![gid isKindOfClass:[EOKeyGlobalID class]]) {
      [self warnWithFormat:@"got passed a non EOKeyGlobalID gid: %@", gid];
      [str appendFormat:@"'%@'", [gid stringValue]];
      continue;
    }
    
    [str appendFormat:@"'%@'", [[gid keyValues][0] stringValue]];
  }
  return str;
}

- (NSDictionary *)_operationsForObjectIds:(NSArray *)_objIds
  accessGlobalIDs:(NSArray *)_accGids
  allowed:(BOOL)_allowed
{
  EOAdaptorChannel    *channel;
  EOSQLQualifier      *qual;
  NSMutableDictionary *result;
  NSMutableArray      *array;
  id                  obj;
  int                 idx, cnt, maxCount;
  static NSArray  *attrs  = nil;
  
  if (![_objIds isNotNull]) {
    [self warnWithFormat:@"%s: missing object ids",__PRETTY_FUNCTION__];
    return nil;
  }
  if (![_objIds isNotEmpty])
    return nil;

  if (![_accGids isNotNull])
    _accGids = nil;
  
  if ([_accGids count] > 250) { // TODO: make configurable?
    [self warnWithFormat:@"%s: to many ids for sql qualifier", 
	  __PRETTY_FUNCTION__];
    return nil;
  }
  
  array = [[NSMutableArray alloc] initWithCapacity:64];
  
  if (attrs == nil) {
    EOEntity *entity = [self aclEntity];
    
    attrs = [[NSArray alloc] initWithObjects:
                             [entity attributeNamed:@"objectId"],
                             [entity attributeNamed:@"authId"],
                             [entity attributeNamed:@"permissions"], nil];
  }
  maxCount = [_objIds count];
  idx      = 0;
  cnt      = (maxCount > 200) ? 200 : maxCount;
  
  while (cnt > 0) {
    NSArray     *tmp;
    NSException *error;

    tmp = [_objIds subarrayWithRange:NSMakeRange(idx, cnt)];

    idx += cnt;
    cnt  = maxCount - idx;
    cnt  = (cnt > 200) ? 200 : cnt;
    
    qual = [EOSQLQualifier alloc];
    if ([_accGids count] > 0) {
      qual = [qual initWithEntity:[self aclEntity]
		               qualifierFormat:@"(%A IN (%@)) AND (%A IN (%@))",
		                 @"objectId", [self _stringGIDInQualFor:tmp],
		                 @"authId",   [self _stringGIDInQualFor:_accGids],
		   nil];
    }
    else {
      qual = [qual initWithEntity:[self aclEntity]
		               qualifierFormat:@"%A IN (%@)",
		                 @"objectId", [self _stringGIDInQualFor:tmp]];
    }
    
    channel = [self beginTransaction];
    
    error = [channel selectAttributesX:attrs describedByQualifier:qual
		                 fetchOrder:nil lock:NO];
    if (error != nil) {
      [self errorWithFormat:@"%s: evaluation of qualifier %@ failed: %@",
            __PRETTY_FUNCTION__, qual, error];
      [self rollbackTransaction];
      return nil;
    }
    while ((obj = [channel fetchAttributes:attrs withZone:NULL]))
      [array addObject:obj];
    
    [qual release]; qual = nil;
  }
  {
    NSEnumerator *enumerator;
    id           obj, tm;

    result     = [NSMutableDictionary dictionaryWithCapacity:16];
    tm         = [self->context typeManager];
    enumerator = [array objectEnumerator];
    while ((obj = [enumerator nextObject])) {
      NSMutableDictionary *dict;
      EOGlobalID          *ogid, *agid;

      ogid = [tm globalIDForPrimaryKey:[obj valueForKey:@"objectId"]];

      NSAssert1(ogid, @"missing objectGID for %@", obj);

      if (!(dict = [result objectForKey:ogid])) {
        dict = [NSMutableDictionary dictionaryWithCapacity:8];
        [result setObject:dict forKey:ogid];
      }
      agid = [tm globalIDForPrimaryKey:[obj valueForKey:@"authId"]];
      [dict setObject:[obj valueForKey:@"permissions"] forKey:agid];
    }
  }
  [array release]; array = nil;
  [self commitTransaction];
  return result;
}

- (EOAdaptorChannel *)beginTransaction {
  if (![self->context isTransactionInProgress]) {
    self->commitTransaction = YES;
    [self->context begin];
  }
  else {
    self->commitTransaction = NO;
  }
  return [[self->context valueForKey:LSDatabaseChannelKey] adaptorChannel];
}

- (void)commitTransaction {
  if (!self->commitTransaction)
    return;
  self->commitTransaction = NO;
  [self->context commit];
}

- (void)rollbackTransaction {
  [self->context rollback];
  self->commitTransaction = NO;
}

- (EODatabase *)_database {
  return [self->context valueForKey:LSDatabaseKey];
}

/*
  OGoAccessHandlers = (
    {
      ObjectIdentifier = "Person";
      AccessHandler    = "SkyPersonAccessHandler";
    },
  );
*/
  
- (BOOL)_checkBundleForAccessHandlers:(NSBundle *)_bundle {
  /* Note: this fills the 'accessHandlers' ivar */
  NSDictionary *handlers, *bundleInfo;
  NSString     *path;
  NSEnumerator *keyEnumerator;
  id           key;
  
  if (_bundle == nil)
    return NO;
  
  if (debugOn)
    [self debugWithFormat:@"check access handler bundle: %@", _bundle];
  
  if ((path = [_bundle pathForResource:@"bundle-info" ofType:@"plist"])==nil) {
    static NSFileManager *fm = nil; // THREAD
    
    /* the following is required on OSX 10.3 with gstep-make */
    if (fm == nil) fm = [[NSFileManager defaultManager] retain];
    path = [_bundle bundlePath];
    path = [path stringByAppendingPathComponent:@"bundle-info.plist"];
    if (![fm isReadableFileAtPath:path]) {
      [self warnWithFormat:@"did not find bundle-info.plist in bundle: %@",
	      _bundle];
      return NO;
    }
  }
  
  if ((bundleInfo = [NSDictionary dictionaryWithContentsOfFile:path]) == nil) {
    [self errorWithFormat:@"could not load bundle-info.plist: %@", path];
    return NO;
  }

  if (![_bundle load]) {
    [self errorWithFormat:@"could not load access handler bundle: %@",_bundle];
    return NO;
  }
  
  // TODO: thats not particulary beautiful. We should use just one entry.
  if ((handlers = [bundleInfo objectForKey:@"OGoAccessHandlers"]) == nil)
    handlers = [bundleInfo objectForKey:@"SkyAccessHandlers"];
  
  /* register handlers found in bundle */
  
  keyEnumerator = [handlers keyEnumerator];
  while ((key = [keyEnumerator nextObject]) != nil) {
    Class handlerClass;
    id    handler;
    
    handlerClass = [_bundle classNamed:[handlers objectForKey:key]];
    if (handlerClass == Nil) {
      [self errorWithFormat:
	      @"did not find class '%@' for key '%@'\n"
              @"  in bundle: %@\n  handlers: %@",
	      [handlers objectForKey:key], key, _bundle, handlers];
      continue;
    }
    
    handler = [handlerClass accessHandlerWithContext:self->context];
    if (handler == nil) {
      [self errorWithFormat:
	      @"could not instantiate class '%@' for key '%@'\n"
              @"  in bundle: %@\n  handlers: %@",
	      [handlers objectForKey:key], key, _bundle, handlers];
      continue;
    }
    
    if (debugOn)
      [self debugWithFormat:@"  found handler for key '%@': %@", key, handler];
    [self->accessHandlers setObject:handler forKey:key];
  }
  return YES;
}

- (id<OGoAccessHandler>)_accessHandlerForObjectID:(EOGlobalID *)_gid {
  NSString             *entityName;
  NSBundle             *bundle;
  id<OGoAccessHandler> handler;

  if (![_gid isNotNull])
     return nil;
  if (![_gid isKindOfClass:[EOKeyGlobalID class]]) {
    [self errorWithFormat:@"%s: got invalid global-id %@: %@",
	  __PRETTY_FUNCTION__, _gid, [_gid class]];
    return nil;
  }

  entityName = [(EOKeyGlobalID *)_gid entityName];
  
  /* setup / check  cache */
  
  if ((handler = [self->accessHandlers objectForKey:entityName]) != nil) {
    [self debugWithFormat:@"found cached access handler for entity %@: %@",
            entityName, handler];
    return handler;
  }
  
  if (self->accessHandlers == nil)
    self->accessHandlers = [[NSMutableDictionary alloc] initWithCapacity:16];
  
  /* lookup with bundle manager */
  
  bundle = [[NGBundleManager defaultBundleManager] 
	                     bundleProvidingResource:entityName
	                     ofType:@"SkyAccessHandlers"];
  if (bundle == nil) {
    static NSMutableSet *warnedEntities = nil;
    
    if (warnedEntities == nil) {
      warnedEntities = [[NSMutableSet alloc] initWithCapacity:16];

      /* otherwise we get a lot of warnings ... */
      [warnedEntities addObject:@"Telephone"];
      [warnedEntities addObject:@"Address"];
    }
    
    if (![warnedEntities containsObject:entityName]) {
      [self errorWithFormat:
	      @"found no access handler for entity %@ GID %@: %@", 
	      entityName, _gid, self->accessHandlers];
      [warnedEntities addObject:entityName];
    }
  }
  
  /* this fills the cache */
  [self _checkBundleForAccessHandlers:bundle];

  /* retry cache */
  
  if ((handler = [self->accessHandlers objectForKey:entityName]) != nil) {
    [self debugWithFormat:@"found access handler for entity %@: %@",
            entityName, handler];
    return handler;
  }
  
  return nil;
}

- (NSMutableDictionary *)_createRowForUpdateOfPermission:(NSString *)_op {
  if (_op == nil) return nil;
  return [[NSMutableDictionary alloc] 
	   initWithObjectsAndKeys: _op, @"permissions", nil];
}

- (EOSQLQualifier *)_updateQualifierForAclID:(id)_accessId
  andObjectID:(EOGlobalID *)_objId
{
  EOSQLQualifier *qual;

  qual = [EOSQLQualifier alloc];
  qual = [qual initWithEntity:[self aclEntity]
	       qualifierFormat:@"%A = '%@' AND %A = '%@'",
	         @"authId",   [[(id)_accessId keyValues][0] stringValue],
	         @"objectId", [[(id)_objId    keyValues][0] stringValue],
	       nil];
  return qual;
}

- (BOOL)updateOperation:(NSString *)_operation
  onObjectID:(EOGlobalID *)_objId
  forAccessGlobalID:(EOGlobalID *)_accessId
  checkAccess:(BOOL)_accessCheck
{
  NSDictionary     *row;
  EOAdaptorChannel *channel;
  EOSQLQualifier   *qual;

  if (![_operation isNotNull]) {
    [self warnWithFormat:@"%s: missing operation", __PRETTY_FUNCTION__];
    return NO;
  }
  if (![_operation isNotEmpty]) {
    [self warnWithFormat:@"%s: missing operation", __PRETTY_FUNCTION__];
    return NO;
  }
  if (![_objId isNotNull]) {
    [self warnWithFormat:@"%s: missing objec id", __PRETTY_FUNCTION__];
    return NO;
  }
  if (![_accessId isNotNull]) {
    [self warnWithFormat:@"%s: missing access id", __PRETTY_FUNCTION__];
    return NO;
  }
  
  if (_accessCheck) {
    if (![self operation:@"w" allowedOnObjectID:_objId]) {
      [self warnWithFormat:@"%s: insertOperation not allowed for %@",
            __PRETTY_FUNCTION__, _objId];
      return NO;
    }
  }

  channel = [self beginTransaction];
  qual = [self _updateQualifierForAclID:_accessId andObjectID:_objId];
  
  row = [self _createRowForUpdateOfPermission:_operation];
  if (![channel updateRow:row describedByQualifier:qual]) {
    [self errorWithFormat:@"%s: update for row %@, qualifier %@, failed",
          __PRETTY_FUNCTION__, row, qual];
    [self rollbackTransaction];
    return NO;
  }
  [self commitTransaction];
  [row  release]; row  = nil;
  [qual release]; qual = nil;
  [self commitTransaction];
  
  [self postFlagsDidChange:_objId];
  return YES;
}

- (NSMutableDictionary *)_createRowForAclID:(id)_aclId
  permissions:(NSString *)_operation
  accessID:(id)_accessId
  objectID:(id)_objId
{
  NSMutableDictionary *row;

  row = [NSMutableDictionary alloc];
  row = [row initWithObjectsAndKeys:
	       _aclId,                       @"objectAclId",
	       @"allowed",                   @"action",  
	       [NSNumber numberWithInt:0],   @"sortKey", 
	       _operation,                   @"permissions",
	       [[(id)_accessId keyValues][0] stringValue], @"authId",
	       [[(id)_objId keyValues][0] stringValue],    @"objectId",
	     nil];
  return row;
}

- (BOOL)insertOperation:(NSString *)_operation
  onObjectID:(EOGlobalID *)_objId
  forAccessGlobalID:(EOGlobalID *)_accessId
  checkAccess:(BOOL)_accessCheck
{
  NSDictionary     *row;
  EOAdaptorChannel *channel;
  NSNumber         *aclId;


  if (![_operation isNotNull]) {
    [self warnWithFormat:@"%s: missing operation", __PRETTY_FUNCTION__];
    return NO;
  }
  if (![_operation isNotEmpty]) {
    [self warnWithFormat:@"%s: missing operation", __PRETTY_FUNCTION__];
    return NO;
  }
  if (![_objId isNotNull]) {
    [self warnWithFormat:@"%s: missing objec id", __PRETTY_FUNCTION__];
    return NO;
  }
  if (![_accessId isNotNull]) {
    [self warnWithFormat:@"%s: missing access id", __PRETTY_FUNCTION__];
    return NO;
  }
  
  if (_accessCheck) {
    if (![self operation:@"w" allowedOnObjectID:_objId]) {
      [self warnWithFormat:@"%s: insertOperation not allowed for %@",
            __PRETTY_FUNCTION__, _objId];
      return NO;
    }
  }

  channel = [self beginTransaction];
  aclId   = [[channel primaryKeyForNewRowWithEntity:[self aclEntity]]
                      valueForKey:@"objectAclId"]; 
  row = [self _createRowForAclID:aclId permissions:_operation
	      accessID:_accessId objectID:_objId];
  if (![channel insertRow:row forEntity:[self aclEntity]]) {
    [self errorWithFormat:@"%s: insert for row %@ and entity %@ failed",
          __PRETTY_FUNCTION__, row, [self aclEntity]];
    [self rollbackTransaction];
    [row release];
    return NO;
  }
  
  [row release]; row = nil;
  [self commitTransaction];

  [self postFlagsDidChange:_objId];
  return YES;
}

- (BOOL)_checkDelOpOnObjectID:(EOGlobalID *)_objId 
  accessGlobalID:(EOGlobalID *)_accessId
{
  /* TODO: what exactly does that do? */
  NSArray *a1, *a2;

  a1 = [NSArray arrayWithObject:_objId];
  a2 = _accessId ? [NSArray arrayWithObject:_accessId] : nil; 
  
  a1 = (id)[self _operationsForObjectIds:a1 accessGlobalIDs:a2 allowed:YES];
  return [a1 count] == 0 ? YES : NO;
}

- (EOSQLQualifier *)_delQualifierForObjectID:(EOGlobalID *)_objId
  accessGlobalID:(EOGlobalID *)_accessId
{
  EOSQLQualifier *qual;
  
  qual = [EOSQLQualifier alloc];
  if ([_accessId isNotNull]) {
    qual = [qual initWithEntity:[self aclEntity]
		 qualifierFormat:@"(%A = '%@') AND (%A = '%@')",
		   @"authId", [[(id)_accessId keyValues][0] stringValue],
		   @"objectId", [[(id)_objId keyValues][0] stringValue],
		 nil];
  }
  else {
    qual = [qual initWithEntity:[self aclEntity]
		 qualifierFormat:@"%A = '%@'",
		   @"objectId", [[(id)_objId keyValues][0] stringValue],
		 nil];
  }
  return qual;
}

- (BOOL)deleteOperationForObjectID:(EOGlobalID *)_objId
  accessGlobalID:(EOGlobalID *)_accessId
  checkAccess:(BOOL)_accessCheck
{
  EOAdaptorChannel *channel;
  EOSQLQualifier   *qual;
  
  if (![_objId isNotNull]) {
    [self warnWithFormat:@"%s: missing object id", __PRETTY_FUNCTION__];
    return NO;
  }
  
  if (_accessCheck) {
    if (![self operation:@"w" allowedOnObjectID:_objId]) {
      [self warnWithFormat:
	      @"%s: deleteOperationForObjectID not allowed for %@",
            __PRETTY_FUNCTION__, _objId];
      return NO;
    }
  }
  
  if ([self _checkDelOpOnObjectID:_objId accessGlobalID:_accessId])
    return YES;
  
  channel = [self beginTransaction];
  
  qual = [self _delQualifierForObjectID:_objId accessGlobalID:_accessId];
  if (![channel deleteRowsDescribedByQualifier:qual]) {
    [self errorWithFormat:@"%s: delete for ACL qualifier %@ failed",
          __PRETTY_FUNCTION__, qual];
    [self rollbackTransaction];
    [qual release]; qual = nil;
    return NO;
  }
  [self commitTransaction];
  [qual release]; qual = nil;
  [self commitTransaction]; // TODO: why two commits?
  
  [self postFlagsDidChange:_objId];
  return YES;
}

- (BOOL)_checkAccessMask:(NSString *)_mask with:(NSString *)_operation {
  /*
    TODO: this could probably be optimized to use a charset for the mask
          and single characters for permissions instead of all the string
	  operations.
  */
  int maskCnt;
  int opCnt;
  int i;

  maskCnt   = [_mask length];
  opCnt = [_operation length];

  if (maskCnt < opCnt)
    return NO;

  for (i = 0;  i < opCnt; i++) {
    NSString *subStr;
    NSRange  r;
    
    r = NSMakeRange(i, 1);
    subStr = [_operation substringWithRange:r];
    if ([_mask rangeOfString:subStr].length == 0)
      return NO;
  }
  return YES;
}

/* description */

- (NSString *)description {
  NSMutableString *ms;

  ms = [NSMutableString stringWithCapacity:128];
  [ms appendFormat:@"<%p[%@]:", self, NSStringFromClass([self class])];
  
  [ms appendFormat:@" ctx=%p",   self->context];
  [ms appendFormat:@" #handlers=%d", [self->accessHandlers count]];
  
  [ms appendString:@">"];
  return ms;
}

@end /* OGoAccessManager */

@implementation SkyAccessManager // DEPRECATED
@end /* SkyAccessManager */
