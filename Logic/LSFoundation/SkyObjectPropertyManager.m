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

#include <LSFoundation/SkyObjectPropertyManager.h>
#include "SkyObjectPropertyManager+Internals.h"
#include "SkyObjectPropertyManagerHandler.h"
#include <NGExtensions/NGExtensions.h>
#include <LSFoundation/LSFoundation.h>
#include "LSCommandContext.h"
#include "LSCommandKeys.h"
#include "common.h"

NSString *SkyGlobalIDWasDeleted = @"SkyGlobalIDWasDeletedNotification";
NSString *SkyGlobalIDWasCopied  = @"SkyGlobalIDWasCopiedNotification";

@interface SkyObjectPropertyManager(Private)
- (NSString *)_restEntityPKName;
- (NSString *)_resEntityTableName;
@end

static SkyObjectPropertyManagerHandler *ObjPropManHandler = nil;

static BOOL SkyObjectPropertyManagerDebug = NO;

static Class  NSNumberClass                 = Nil;
static Class  NSStringClass                 = Nil;
static Class  EOKeyGlobalIDClass            = Nil;
static Class  EOGenericRecordClass          = Nil;
static Class  NSCalendarDateClass           = Nil;
static Class  EOAndQualifierClass           = Nil;
static Class  EOOrQualifierClass            = Nil;
static Class  EOKeyValueQualifierClass      = Nil;
static Class  EONotQualifierClass           = Nil;
static Class  EOKeyComparisonQualifierClass = Nil;

static EONull  *SharedEONull       = nil;
static NSArray *AttrsForProperties = nil;
static NSArray *AttrsForAllKeys    = nil;
static NSArray *GIDAttributes      = nil;
static NSArray *AccessAttributes   = nil;

NSString *SkyOPMNoAccessExceptionName        = @"SkyOPMNoAccessException";
NSString *SkyOPMKeyAlreadyExistExceptionName = 
  @"SkyOPMKeyAlreadyExistException";
NSString *SkyOPMNoPrimaryKeyExceptionName    = @"SkyOPMNoPrimaryKeyException";
NSString *SkyOPMCouldntInsertExceptionName   = @"SkyOPMCouldntInsertException";
NSString *SkyOPMCouldntUpdateExceptionName   = @"SkyOPMCouldntUpdateException";
NSString *SkyOPMCouldntDeleteExceptionName   = @"SkyOPMCouldntDeleteException";
NSString *SkyOPMCouldntSelectExceptionName   = @"SkyOPMCouldntSelectException";
NSString *SkyOPMKeyDoesntExistExceptionName  = 
  @"SkyOPMKeyDoesntExistException";
NSString *SkyOPMWrongPropertyKeyExceptionName= 
  @"SkyOPMWrongPropertyKeyException";

@implementation SkyObjectPropertyManager

static NSNumber *YesNumber = nil;
static NSNumber *NoNumber  = nil;
static int PropertyRowBatchSize = 150;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  if (YesNumber == nil)
    YesNumber = [[NSNumber numberWithBool:YES] retain];
  if (NoNumber == nil)
    NoNumber = [[NSNumber numberWithBool:NO] retain];
  
  NSNumberClass        = [NSNumber class];
  NSStringClass        = [NSString class];
  EOKeyGlobalIDClass   = [EOKeyGlobalID class];
  EOGenericRecordClass = [EOGenericRecord class];
  NSCalendarDateClass  = [NSCalendarDate class];
  EOAndQualifierClass  = [EOAndQualifier class];
  EOOrQualifierClass   = [EOOrQualifier class];
  EOKeyValueQualifierClass      = [EOKeyValueQualifier class];
  EONotQualifierClass           = [EONotQualifier class];
  EOKeyComparisonQualifierClass = [EOKeyComparisonQualifier class];

  if (SharedEONull == nil)
    SharedEONull = [NSNull null];
  
  SkyObjectPropertyManagerDebug =
    [ud boolForKey:@"SkyObjectPropertyManagerDebug"];
  [SkyObjectPropertyManager __initialize__Internals__];
}

- (id)initWithContext:(LSCommandContext *)_ctx {
  if ((self = [super init])) {
    void *z = [self zone];
    
    self->context = _ctx; /* not retained */
    NSAssert(self->context != nil, @"###1 couldn`t find command context");
    
    self->typeManager        = [self->context typeManager]; /* not retained */
    self->dbMessages         = 
      [[NSMutableArray allocWithZone:z] initWithCapacity:2];
    self->_maskPropertyCache = 
      [[NSMutableDictionary allocWithZone:z] initWithCapacity:64];
    self->_maskAccessCache   = 
      [[NSMutableDictionary allocWithZone:z] initWithCapacity:64];
    self->_maskObjectCache   =
      [[NSMutableDictionary allocWithZone:z] initWithCapacity:64];
    
    ObjPropManHandler = [[SkyObjectPropertyManagerHandler alloc] init];
    [ObjPropManHandler addManager:self];
  }
  self->identCount = 0;
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];  
  self->context       = nil; /* not retained */
  self->accessManager = nil; /* not retained */
  self->typeManager   = nil; /* not retained */  
  [self->database            release];
  [self->entity              release];
  [self->adChannel           release];
  [self->dbMessages          release];
  [self->_groupIds           release];
  [self->_loginId            release];
  [self->_maskPropertyCache  release];
  [self->_maskAccessCache    release];
  [self->_maskObjectCache    release];
  [self->restQualStr         release];
  [self->restEntityName      release];
  [self->restPKName          release];
  [self->adaptor             release];
  [super dealloc];
}

static NSString *nsCleanup(NSString *nsp) {
  if (nsp == nil)        return nil;
  if (![nsp isNotNull])  return nil;
  if ([nsp length] == 0) return nil;
  return nsp;
}
static NSString *nsString(NSString *ns) {
  if (ns == nil)
    return nil;
  
  return [[@"{" stringByAppendingString:ns] stringByAppendingString:@"}"];
}
static NSString *nsNameString(NSString *ns, NSString *n) {
  if (ns == nil)
    return n;
  if (n == nil)
    return nsString(ns);
  
  return [nsString(ns) stringByAppendingString:n];
}

/* transaction support */

- (void)_ensureOpenTransaction {
  if (![self->context isTransactionInProgress]) {
    NSAssert([self->context begin], @"could not begin transaction");
  }
}

- (NSDictionary *)propertiesForGlobalID:(id)_gid {
  return [self propertiesForGlobalID:_gid namespace:nil];
}

- (NSArray *)attributesForProperties {
  EOEntity *e;
  
  if (AttrsForProperties != nil)
    return AttrsForProperties;

  e = [self entity];
  AttrsForProperties =
    [[NSArray alloc] initWithObjects:
                         [e attributeNamed:@"key"],
                         [e attributeNamed:@"namespacePrefix"],
                         [e attributeNamed:@"preferredType"],
                         [e attributeNamed:@"valueString"],
                         [e attributeNamed:@"valueInt"],
                         [e attributeNamed:@"valueFloat"],
                         [e attributeNamed:@"valueDate"],
                         [e attributeNamed:@"valueOID"],
                         [e attributeNamed:@"valueBlob"],
                         [e attributeNamed:@"blobSize"],
                         [e attributeNamed:@"accessKey"],
                         [e attributeNamed:@"objectId"],
                         [e attributeNamed:@"objectPropertyId"], nil];
  return AttrsForProperties;
}
- (NSArray *)attributesForAllKeys {
  EOEntity *e;
  
  if (AttrsForAllKeys != nil)
    return AttrsForAllKeys;

  e = [self entity];
  AttrsForAllKeys = [[NSArray alloc] initWithObjects:
                                       [e attributeNamed:@"key"],
                                       [e attributeNamed:@"namespacePrefix"],
				     nil];
  return AttrsForAllKeys;
}

- (NSMutableArray *)_fetchPropertyRowsForGlobalIDs:(NSArray *)_gids 
  namespace:(NSString *)_ns 
{
  NSTimeZone       *tz;
  int              batchSize, cnt, gidCnt;
  NSArray          *currBatch;
  EOSQLQualifier   *q;
  EOAdaptorChannel *adc;
  NSMutableArray   *tmp;
  EOEntity         *e;
  NSDictionary     *fetch;

  adc       = [self adaptorChannel];
  batchSize = PropertyRowBatchSize;
  cnt       = 0;
  tz        = [self _defaultTimeZone];
  gidCnt    = [_gids count];
  tmp       = [[NSMutableArray alloc] initWithCapacity:256];
  e         = [self entity];
    
  while (gidCnt > 0) {
    NSException *error;
    NSRange     range;
    NSArray     *attrs;
    
    range     = NSMakeRange(cnt, (gidCnt > batchSize) ? batchSize : gidCnt);
    currBatch = [_gids subarrayWithRange:range];
    gidCnt    = gidCnt - batchSize;
    cnt       += batchSize;

    q = [EOSQLQualifier alloc];
    q = (_ns == nil)
      ? [q initWithEntity:e qualifierFormat:@"objectId IN (%@)",
	   [self _qualifierInStringForGIDs:currBatch]]
      : [q initWithEntity:e qualifierFormat:@"(objectId IN (%@)) AND "
	   @"(namespacePrefix = '%@')",
	   [self _qualifierInStringForGIDs:currBatch],
	   _ns];
    
    attrs = [self attributesForProperties];
    
    error = [adc selectAttributesX:attrs
		 describedByQualifier:q fetchOrder:nil lock:NO];
    if (error != nil) {
      NSLog(@"ERROR[%s]: select for qualifier %@ failed: %@",
            __PRETTY_FUNCTION__, q, error);
      [q release]; q = nil;
      return nil;
    }
    [q release]; q = nil;
    
    while ((fetch = [adc fetchAttributes:attrs withZone:NULL])) {
      /* correct timezone */
      [[fetch valueForKey:@"valueDate"] setTimeZone:tz];
      [tmp addObject:fetch];
    }
  }
  return tmp;
}
- (NSMutableArray *)_fetchProps:(NSArray *)_gids namespace:(NSString *)_ns {
  // DEPRECATED
  return [self _fetchPropertyRowsForGlobalIDs:_gids namespace:_ns];
}

- (void)_setObjectValue:(NSDictionary *)_obj
  mapping:(NSDictionary *)_mapping
  key:(NSString *)_key
  properties:(NSMutableDictionary *)_props
  preferredType:(NSString *)_pt
{
  NSMutableDictionary *dict;
  id                  object;
  EOKeyGlobalID       *kgid;

  object = nil;
  kgid   = [_mapping objectForKey:[_obj objectForKey:@"objectId"]];

  if (!kgid) {
    NSLog(@"WARNING: missing globalID for obj %@ mapOIDsWithGIDs %@",
          _obj, _mapping);
    return;
  }
  if (!(dict = [_props objectForKey:kgid])) {
    dict = [NSMutableDictionary dictionaryWithCapacity:64];
    [_props setObject:dict forKey:kgid];
  }
  if ([_pt isEqualToString:@"valueString"]) {
    NSData *blob;
          
    if ([blob = [_obj objectForKey:@"valueBlob"] isNotNull]) {
      object = [[[NSString alloc]
                           initWithData:blob
                           encoding:[NSString defaultCStringEncoding]]
                           autorelease];
    }
  }
  else if ([_pt isEqualToString:@"url"]) {
    NSString *urlStr;

    if (([urlStr = [_obj objectForKey:@"valueString"] isNotNull])) {
      object = [NSURL URLWithString:urlStr];
    }
    else {
      NSLog(@"WARNING[%s]: missing string for url-type",
            __PRETTY_FUNCTION__);
      object = [NSNull null];
    }
  }
  if (object == nil) 
    object = [_obj objectForKey:_pt];
  
  if (object != nil)
    [dict setObject:object forKey:_key];
}  

- (BOOL)isReadAccessAllowedOnProperty:(id)obj {
  NSArray *objArray;
  BOOL    hasAccess;
  
  if (obj == nil) return NO;
  
  objArray = [[NSArray alloc] initWithObjects:&obj count:1];
  hasAccess = [self _operation:@"r" allowedOnProperties:objArray];
  [objArray release]; objArray = nil;
  return hasAccess;
}

/*
  returns a dictionary with gids as keys and dictionaries of properties as 
  value
*/
- (NSDictionary *)propertiesForGlobalIDs:(NSArray *)_gids
  namespace:(NSString *)_namespace
{
  NSMutableDictionary *props;
  NSString            *ns;
  NSMutableArray      *tmp;
  NSEnumerator        *enumerator;
  NSDictionary        *mapOIDsWithGIDs;
  NSMutableDictionary *obj;

  _gids = [[self->context accessManager] objects:_gids forOperation:@"r"];

  if ([_gids count] == 0)
    return nil;
  
  mapOIDsWithGIDs = [self mapOIDsWithGIDs:_gids];
  
  if (![_namespace isNotNull])
    ns = nil;
  else if ([_namespace length] == 0)
    ns = nil;
  else
    ns = _namespace;
  
  [self _ensureOpenTransaction];

  tmp = [self _fetchPropertyRowsForGlobalIDs:_gids namespace:ns];
  
  if (ns != nil)
    ns = [[@"{" stringByAppendingString:ns] stringByAppendingString:@"}"];
  
  props      = [[NSMutableDictionary alloc] initWithCapacity:64];
  enumerator = [tmp objectEnumerator];
  
  while ((obj = [enumerator nextObject]) != nil) {
    NSString *pt, *k;
    
    if (![self isReadAccessAllowedOnProperty:obj])
      continue;
    
    pt = [obj objectForKey:@"preferredType"];
    if (![pt isNotNull])
      pt = @"valueString";

    k = [obj objectForKey:@"key"];
    
    if (ns != nil)
      k = [ns stringByAppendingString:k];
    else {
      NSString *nsp;

      nsp = [obj objectForKey:@"namespacePrefix"];
      if (![nsp isNotNull])
	nsp = nil;
      else if ([nsp length] == 0)
	nsp = nil;
      
      if (nsp != nil)
	k = nsNameString(nsp, k);
    }
    
    [self _setObjectValue:obj
	  mapping:mapOIDsWithGIDs
	  key:k
	  properties:props
	  preferredType:pt];
  }
  ASSIGN(tmp, props);
  props = [props copy];
  [tmp release]; tmp = nil;
  return [props autorelease];
}

- (NSDictionary *)propertiesForGlobalID:(id)_gid
  namespace:(NSString *)_namespace
{
  NSDictionary *result;
  NSArray *gidArray;
  
  if (_gid == nil)
    return nil;
  
  gidArray = [[NSArray alloc] initWithObjects:&_gid count:1];
  
  result = [[[self propertiesForGlobalIDs:gidArray
		   namespace:_namespace]
	           objectEnumerator]
                   nextObject];
  [gidArray release];
  return result;
}

- (NSArray *)allKeysForGlobalID:(id)_gid {
  return [self allKeysForGlobalID:_gid namespace:nil];
}

- (NSArray *)allKeysForGlobalID:(id)_gid
  namespace:(NSString *)_namespace
{
  EOEntity         *e;
  EOAdaptorChannel *adc;
  EOSQLQualifier   *qualifier;
  NSNumber         *oid;
  NSString         *type, *ns;
  NSMutableArray   *keys;
  NSDictionary     *fetch;
  NSException      *error;
  id               tmp;
  NSArray          *attrs;
  
  e    = [self entity];
  adc  = [self adaptorChannel];
  oid  = nil;
  type = nil;

  [self _objectId:_gid objectId:&oid objectType:&type];
  
  ns = nsCleanup(_namespace);
  
  qualifier = [EOSQLQualifier alloc];
  qualifier = (ns == nil)
    ? [qualifier initWithEntity:e qualifierFormat:@"objectId = %@", oid]
    : [qualifier initWithEntity:e 
		 qualifierFormat:@"objectId = %@ AND namespacePrefix = '%@'", 
		   oid, ns];
  
  [self _ensureOpenTransaction];
  
  attrs = [self attributesForProperties];
  
  error = [adc selectAttributesX:attrs describedByQualifier:qualifier
	       fetchOrder:nil lock:NO];
  if (error != nil) {
    NSLog(@"ERROR[%s]: select for qualifier %@ failed: %@", 
	  __PRETTY_FUNCTION__, qualifier, error);
    [qualifier release]; qualifier = nil;
    return [NSArray array];
  }
  [qualifier release]; qualifier = nil;

  keys = [[NSMutableArray alloc] initWithCapacity:16];
  
  ns = nsString(ns);
  
  while ((fetch = [adc fetchAttributes:attrs withZone:NULL])) {
    NSString *k;
    
    if (ns != nil) {
      k = [ns stringByAppendingString:[fetch objectForKey:@"key"]];
    }
    else {
      NSString *nsp;      
      
      nsp = nsCleanup([fetch objectForKey:@"namespacePrefix"]);
      k   = nsNameString(nsp, [fetch objectForKey:@"key"]);
    }
    if (k == nil) {
      [self logWithFormat:@"WARNING(%s): missing key for globalID %@", 
	    __PRETTY_FUNCTION__, _gid];
      k = @"";
    }
    [keys addObject:k];
  }
  
  tmp = [keys copy];
  [keys release]; keys = nil;
  return [tmp autorelease];
}

/* accessors */

- (void)setRestrictionEntityName:(NSString *)_entity {
  ASSIGN(self->restEntityName, _entity);
}
- (NSString *)restrictionEntityName {
  return self->restEntityName;
}

- (void)setRestrictionPrimaryKeyName:(NSString *)_entity {
  ASSIGN(self->restPKName, _entity);
}
- (NSString *)restrictionPrimaryKeyName {
  return self->restPKName;
}

- (void)setRestrictionQualifierString:(NSString *)_str {
  ASSIGN(self->restQualStr, _str);
}
- (NSString *)restrictionQualifierString {
  return self->restQualStr;
}

/* property row */

- (EOGlobalID *)_processPropertyGlobalIDRow:(NSDictionary *)row {
  NSString   *en;
  id         pk;
  EOGlobalID *gid;
	
  if ((pk = [row objectForKey:@"objectId"]) == nil)
    pk = [row objectForKey:@"objId"];
  
  [self debugWithFormat:@"got row while qualifierfetch %@", row];
  
  if ((en = [row objectForKey:@"objectType"]) == nil)
    en = [row objectForKey:@"objType"];
  
  if (en == nil)
    return [[self->context typeManager] globalIDForPrimaryKey:pk];
  
  [self debugWithFormat:@"got entity name from objectType %@", entity];
    
  gid = [EOKeyGlobalID globalIDWithEntityName:en
		       keys:&pk keyCount:1 zone:NULL];
  return gid;
}

- (NSArray *)globalIDsForQualifier:(EOQualifier *)_pQual
  entityName:(NSString *)_name
{
  /* TODO: split up this huge method ... */
  NSMutableString  *qualifier;
  EOEntity         *e;
  EOAdaptorChannel *adc;
  NSDictionary     *row;
  NSMutableArray   *result;
  NSArray          *tmp;
  
  NSString    *oidName, *nsName, *tName, *kName, *typeName;
  EOAttribute *oidAttr, *nsAttr, *keyAttr, *typeAttr;

  e   = [self entity];
  adc = [self adaptorChannel];

  tName   = [e externalName];
  oidAttr = [e attributeNamed:@"objectId"];
  oidName = [oidAttr columnName];

  nsAttr = [e attributeNamed:@"namespacePrefix"];
  nsName = [nsAttr columnName];
    
  keyAttr = [e attributeNamed:@"key"];
  kName   =  [keyAttr columnName];

  typeAttr = [e attributeNamed:@"objectType"];
  typeName =  [typeAttr columnName];

    
  if (![_name isNotNull])
    _name = nil;
  if ([_name length] == 0)
    _name = nil;

  if (_pQual == nil || (![_pQual isNotNull])) {
    NSLog(@"WARNING[%s]: missing qualifier entityName %@",
          __PRETTY_FUNCTION__, _name);
    return [NSArray array];
  }
  
  [self debugWithFormat:@"########## got _propertyQualifier %@ entityName %@ ",
        _pQual, _name];

  /* because of rest qualifier string */
  qualifier = (self->restEntityName == nil)
            ? [self _buildSQLWithPropQual:_pQual objType:_name identifier:@""]
            : [self _buildSQLWithPropQual:_pQual objType:_name
                    identifier:@"t1."];
    
  NSAssert(qualifier != nil, @"###1.7 missing qualifier string");
    
  if (_name != nil && [_pQual isKindOfClass:EOKeyValueQualifierClass]) {
    [qualifier insertString:@"(" atIndex:0];
    [qualifier appendFormat:@") AND (%@%@ = %@)",
               self->restEntityName == nil ? @"" : @"t1.",
               typeName, [self value:_name forAttr:typeAttr]];
  }
  if (self->restQualStr != nil) {
    /* append qual format (like 'object_id IN (1234, 2345)' */
    [qualifier insertString:@"(" atIndex:0];
    [qualifier appendString:@") AND "];
    [qualifier appendString:self->restQualStr];
    if (self->restEntityName != nil) { /* append join query */
      [qualifier insertString:@"(" atIndex:0];
      [qualifier appendFormat:@") AND (%@%@ = %@)",
                 @"t1.", oidName, [self _restEntityPKName]];
    }
  }
  if (self->restEntityName == nil) {
    NSString *s;
    s = [[NSString alloc] initWithFormat:
			    @"SELECT DISTINCT %@, %@ FROM %@ WHERE ",
			    oidName, typeName, tName];
    [qualifier insertString:s atIndex:0];
    [s release];
  }
  else {
    NSString *s;
    s = [[NSString alloc] initWithFormat:
			    @"SELECT DISTINCT t1.%@, t1.%@ FROM %@ t1,"
			    @" %@ WHERE ",
			    oidName, typeName, tName, 
			    [self _resEntityTableName]];
    [qualifier insertString:s atIndex:0];
    [s release];
  }
  [self _ensureOpenTransaction];
  {
    if (![adc evaluateExpression:qualifier]) {
      NSLog(@"ERROR[%s]: evaluation of %@ failed",
            __PRETTY_FUNCTION__, qualifier);
      return [NSArray array];
    }
    result = [[NSMutableArray alloc] initWithCapacity:255];

    if (GIDAttributes == nil) {
      GIDAttributes = [[NSArray alloc]
                                initWithObjects:@"objectId",
                                @"objectType", nil];
    }
    {
      NSMutableArray *array;
      NSEnumerator   *enumerator;

      array = [[NSMutableArray alloc] initWithCapacity:128];

      while ((row = [adc fetchAttributes:GIDAttributes withZone:NULL])) {
        [array addObject:row];
      }
      [adc cancelFetch];
      
      enumerator = [array objectEnumerator];
      while ((row = [enumerator nextObject]) != nil) {
	EOGlobalID *gid;
	
	if ((gid = [self _processPropertyGlobalIDRow:row]) == nil) {
	  [self logWithFormat:
		  @"WARNING: got not global-id for property row: %@",
		  row];
	  continue;
	}
	
	[result addObject:gid];
      }
      [array release]; array = nil;
    }
  }
  tmp = [result copy];
  [result release]; result = nil;
  
  return [tmp autorelease];
}
/*
  speed optimization:
  shared mutable dictionary
*/

- (NSException *)addProperties:(NSDictionary *)_properties 
  accessOID:(EOGlobalID *)_access globalID:(id)_gid
{
  return [self _addProperties:_properties accessOID:_access globalID:_gid
               checkExist:YES];
}


- (NSException *)takeProperties:(NSDictionary *)_properties 
  globalID:(EOGlobalID *)_gid
{
  return [self takeProperties:_properties namespace:nil globalID:_gid];
}

- (NSException *)takeProperties:(NSDictionary *)_properties
  namespace:(NSString *)_namespace
  globalID:(EOGlobalID *)_gid
{
  /* TODO: clean up / split up */
  id *propKeysForUpdate, *propKeysForDel;
  id *propValuesForUpdate, *propKeysForAdd;
  id *propValuesForAdd, obj, objId, type;
  int propCnt;
  int updPropCnt, addPropCnt, delPropCnt;
  
  NSException    *exception;
  NSEnumerator   *keyEnum;
  NSMutableArray *allKeys;

  allKeys = (_namespace == nil)
    ? (id)[self allKeysForGlobalID:_gid]
    : (id)[self allKeysForGlobalID:_gid namespace:_namespace];

  allKeys   = [allKeys mutableCopy];
  propCnt   = [_properties count];
  exception = nil;
  
  propValuesForAdd    = calloc(propCnt+1,       sizeof(id));
  propValuesForUpdate = calloc(propCnt+1,       sizeof(id));
  propKeysForAdd      = calloc(propCnt+1,       sizeof(id));
  propKeysForUpdate   = calloc(propCnt+1,       sizeof(id));
  propKeysForDel      = calloc([allKeys count], sizeof(id));
  
  updPropCnt = 0;
  addPropCnt = 0;
  delPropCnt = 0;
  
  objId = nil;
  type  = nil;
  
  [self _objectId:_gid objectId:&objId objectType:&type];  
  keyEnum = [_properties keyEnumerator];

  while ((obj = [keyEnum nextObject])) {
    NSString *key, *ns;
    id       o;

    key = nil;
    ns  = nil;
    [obj _extractSkyPropNamespace:&ns andLocalKey:&key
         withDefaultNamespace:self->defaultNamespace];
    
    o = [_properties objectForKey:obj];

    if (![o isNotNull]) {
      if ([allKeys containsObject:obj])
        propKeysForDel[delPropCnt++] = obj;
    }
    else if ([self _keyAlreadyExist:key namespace:ns objectId:objId]) {
      propKeysForUpdate[updPropCnt]   = obj;
      propValuesForUpdate[updPropCnt] = [_properties objectForKey:obj];
      updPropCnt++;
    }
    else {
      propKeysForAdd[addPropCnt]   = obj;
      propValuesForAdd[addPropCnt] = [_properties objectForKey:obj];
      addPropCnt++;
    }
    [allKeys removeObject:obj];
  }
  keyEnum = [allKeys objectEnumerator];

  while ((obj = [keyEnum nextObject])) {
    propKeysForDel[delPropCnt++] = obj;
  }
  if (updPropCnt > 0) {
    id tmp;
    
    tmp = [[NSDictionary alloc] initWithObjects:propValuesForUpdate
                                  forKeys:propKeysForUpdate count:updPropCnt];
    exception = [self _updateProperties:tmp globalID:_gid checkExist:NO];
    ASSIGN(tmp, nil);
  }
  if (addPropCnt > 0 && exception == nil) {
    id tmp;
    
    tmp = [[NSDictionary alloc] initWithObjects:propValuesForAdd
                                  forKeys:propKeysForAdd count:addPropCnt];
    exception = [self _addProperties:tmp accessOID:nil
                      globalID:_gid checkExist:NO];
    [tmp release]; tmp = nil;
  }
  if (delPropCnt > 0 && exception == nil) {
    NSArray *keys;
    
    keys = [[NSArray alloc] initWithObjects:propKeysForDel count:delPropCnt];

    exception = [self removeProperties:keys globalID:_gid];
    [keys release]; keys = nil;
  }
  [allKeys release]; allKeys = nil;
  free(propValuesForAdd);    propValuesForAdd    = NULL;
  free(propValuesForUpdate); propValuesForUpdate = NULL;
  free(propKeysForAdd);      propKeysForAdd      = NULL;
  free(propKeysForUpdate);   propKeysForUpdate   = NULL;
  free(propKeysForDel);      propKeysForDel      = NULL;
  return exception;
}

- (NSException *)updateProperties:(NSDictionary *)_properties 
  globalID:(id)_gid
{
  return [self _updateProperties:_properties globalID:_gid checkExist:YES];
}

- (NSException *)removeAllPropertiesForGlobalID:(EOGlobalID *)_gid
  checkAccess:(BOOL)_access
{
  return [self removeProperties:[self allKeysForGlobalID:_gid] globalID:_gid
               checkAccess:_access];
}

- (NSException *)removeAllPropertiesForGlobalID:(EOGlobalID *)_gid {
  return [self removeProperties:[self allKeysForGlobalID:_gid] globalID:_gid];
}

- (NSException *)removeProperties:(NSArray *)_keys 
  globalID:(id)_gid
{
  return [self removeProperties:_keys globalID:_gid checkAccess:YES];
}

- (NSException *)removeProperties:(NSArray *)_keys 
  globalID:(id)_gid
  checkAccess:(BOOL)_check
{
  EOEntity         *e;
  EOAdaptorChannel *adc;
  NSNumber         *objId;
  NSString         *type;
  EOSQLQualifier   *qualifier;
  NSArray          *keysToDelete;
  id               result;
  int              i, cnt;
  
  if (_check) {
    if (![[self->context accessManager] operation:@"w"
                                        allowedOnObjectID:_gid]) {
      NSLog(@"WARNING[%s] no write acccess for gid ", __PRETTY_FUNCTION__,
            _gid);
      return nil;
    }
  }

  result = nil;
  e      = [self entity];
  adc    = [self adaptorChannel];
  _keys  = [_keys isNotNull] ? _keys : nil;
  cnt    = [_keys count];
  objId  = nil;
  type   = nil;
  i      = 0; 
 
  [self _objectId:_gid objectId:&objId objectType:&type];

  NSAssert(objId, @"missing objId");
  
  [self _ensureOpenTransaction];

  while (cnt > 0) {
    NSString *qf = nil;
      
    keysToDelete = [_keys subarrayWithRange:
                          NSMakeRange(i, (cnt < 50) ? cnt : 50)];

    qf   = [self _buildKeyQualifier:keysToDelete objectId:objId];
    i   += 50;
    cnt -= 50;

    qualifier = [[EOSQLQualifier alloc] initWithEntity:e qualifierFormat:qf];
    [self->dbMessages removeAllObjects];
    if (![adc deleteRowsDescribedByQualifier:qualifier]) {
      NSDictionary *ui;
      
      [self debugWithFormat:@"qualifier %@", qualifier];
      [self logWithFormat:@"DB-Messages: %@", self->dbMessages];
      
      ui = [NSDictionary dictionaryWithObjectsAndKeys:
                                          qualifier, @"qualifier", 
                                          self->dbMessages,
			 @"dbMessages",nil];
      result = [NSException exceptionWithName:
                            SkyOPMCouldntDeleteExceptionName
                            reason:@"couldn`t delete row"
                            userInfo:ui];
      [qualifier release]; qualifier = nil;
      break;
    }
    [qualifier release]; qualifier = nil;
  }
  [self _postChangeNotificationForGID:_gid];
  return result;
}

- (NSException *)setAccessOID:(EOGlobalID *)_access
  propertyKeys:(NSArray *)_keys 
  globalID:(id)_gid
{
  EOEntity         *e;
  EOAdaptorChannel *adc;
  EOSQLQualifier   *qualifier;
  NSArray          *keysToUpdate;
  int              i, cnt;
  NSNumber         *objId;
  NSString         *type;
  id               result;
  NSDictionary     *accessId;

  static NSString *AccessKey = @"accessKey";

  if (![[self->context accessManager] operation:@"w" allowedOnObjectID:_gid]) {
    NSLog(@"WARNING[%s] no read acccess for gid ", __PRETTY_FUNCTION__, _gid);
    return nil;
  }
  e      = [self entity];
  adc    = [self adaptorChannel];
  result = nil;
    
  NSAssert(_access, @"missing access");
  NSAssert([_access isKindOfClass:EOKeyGlobalIDClass],
           @"expected EOKeyGlobalIDClass for _access");
    
  _access = [(EOKeyGlobalID *)_access isNotNull] ? _access : nil;
  _keys   = [_keys isNotNull] ? _keys : nil;

  if ([_keys count] == 0)
    return nil;

  if ([self operation:@"e" allowedOnObjectID:_gid forPropertyKeys:_keys]) {
    NSDictionary *ui;

    ui = [NSDictionary dictionaryWithObjectsAndKeys:
			 @"properties", _keys, nil];
    return [NSException exceptionWithName:SkyOPMNoAccessExceptionName
                        reason:@"no access to edit properties"
                        userInfo:ui];
  }
  accessId = [[NSDictionary alloc] initWithObjects:
                                     &[(EOKeyGlobalID *)_access keyValues][0]
                                   forKeys:&AccessKey count:1];

  objId = nil;
  type  = nil;
  [self _objectId:_gid objectId:&objId objectType:&type];
  NSAssert(objId, @"missing object id");

  [self _ensureOpenTransaction];

  cnt = [_keys count];
  i   = 0;
  while (cnt > 0) {
    NSString *qf;
      
    keysToUpdate = [_keys subarrayWithRange:
                          NSMakeRange(i, (cnt < 50) ? cnt : 50)];

    qf   = [self _buildKeyQualifier:keysToUpdate objectId:objId];
    i   += 50;
    cnt -= 50;

    qualifier = [[EOSQLQualifier alloc] initWithEntity:e qualifierFormat:qf];
    [self->dbMessages removeAllObjects];
    if (![adc updateRow:accessId describedByQualifier:qualifier]) {
      NSDictionary *ui;

      ui = [NSDictionary dictionaryWithObjectsAndKeys:
			   qualifier, @"qualifier", 
			   self->dbMessages, @"dbMessages",nil];
      result = [NSException exceptionWithName:SkyOPMCouldntUpdateExceptionName
                            reason:@"couldn`t update row"
                            userInfo:ui];
      [qualifier release]; qualifier = nil;
      break;
    }
    [qualifier release]; qualifier = nil;
  }
  [accessId release]; accessId = nil;
  
  if (result == nil) {
    [self->_maskPropertyCache removeAllObjects];
    [self->_maskObjectCache   removeAllObjects];
    [self->_maskAccessCache   removeAllObjects];
  }
  return result;
}

- (BOOL)operation:(NSString *)_mask
  allowedOnObjectID:(EOGlobalID *)_objID
  forPropertyKeys:(NSArray *)_keys
{
  EOEntity         *e;
  EOAdaptorChannel *adc;
  EOSQLQualifier   *qualifier;
  BOOL             result;
  NSMutableArray   *properties;
  int              i, cnt;

  e     = [self entity];
  adc   = [self adaptorChannel];
  _mask = [_mask isNotNull] ? _mask : nil;
  _keys = [_keys isNotNull] ? _keys : nil;
    
  if (_mask == nil)
    return YES;
  
  if (_keys == nil || [_keys count] == 0)
    return YES;
  
  NSAssert([_objID isKindOfClass:EOKeyGlobalIDClass],
           @"expected EOKeyGlobalIDClass for _objID");
  NSAssert(_objID, @"missing object id");

  properties = [[NSMutableArray alloc] initWithCapacity:[_keys count]];
  cnt        = [_keys count];

  if (AccessAttributes == nil) {
    AccessAttributes = [[NSArray alloc]
                                 initWithObjects:
                                 [e attributeNamed:@"objectPropertyId"],
                                 [e attributeNamed:@"accessKey"],
                                 [e attributeNamed:@"objectId"], nil];
  }

  [self _ensureOpenTransaction];

  i = 0;
  
  while (cnt > 0) {
    NSString     *qf;
    NSArray      *keysToSelect;
    NSDictionary *dict;
    NSException  *error;
      
    keysToSelect = [_keys subarrayWithRange:
                          NSMakeRange(i, (cnt < 50) ? cnt : 50)];

    qf   = [self _buildKeyQualifier:keysToSelect
                 objectId:[(EOKeyGlobalID *)_objID keyValues][0]];
    i   += 50;
    cnt -= 50;

    qualifier = [[EOSQLQualifier alloc] initWithEntity:e qualifierFormat:qf];
    [self->dbMessages removeAllObjects];

    error = [adc selectAttributesX:AccessAttributes
		 describedByQualifier:qualifier fetchOrder:nil lock:NO];
    if (error != nil) {
      NSDictionary *ui;
      NSException  *exc;
      
      ui = [NSDictionary dictionaryWithObjectsAndKeys:
                           qualifier,        @"qualifier", 
                           self->dbMessages, @"dbMessages",
			   error,            @"channelError",
			 nil];
      exc = [NSException exceptionWithName:SkyOPMCouldntSelectExceptionName
                         reason:@"could not select row"
                         userInfo:ui];
      [qualifier release]; qualifier = nil;
      [exc raise];
      break;
    }
    [qualifier release]; qualifier = nil;
    
    while ((dict = [adc fetchAttributes:AccessAttributes withZone:NULL]))
      [properties addObject:dict];
  }
  result = [self _operation:_mask allowedOnProperties:properties];
  [properties release]; properties = nil;
  return result;
}

/* sybase error messages */

- (void)gotDBMessage:(NSNotification *)_notification {
  NSException *msg;
  
  msg = [[_notification userInfo] objectForKey:@"message"];
  [self->dbMessages addObject:[msg reason]]; 
}

/* accessors */

- (EODatabase *)database {
  if (self->database == nil) {
    NSAssert(self->context, @"####2.5 missing context");
    self->database = [[self->context valueForKey:LSDatabaseKey] retain];
    NSAssert(self->database != nil, @"###2 couldn`t find database");
    [[NSNotificationCenter defaultCenter]  addObserver:self
                                           selector:@selector(gotDBMessage:)
                                           name:@"Sybase10Notification"
                                           object:[self->database adaptor]];
  }
  return self->database;
}

- (EOEntity *)entity {
  if (self->entity == nil) {
    EODatabase *db = [self database];
    NSAssert(db, @"###3.4 missing database");
    self->entity = [[db entityNamed:@"ObjectProperty"] retain];
    NSAssert(self->entity != nil, @"###3 couldn`t find entity "
             @"named ObjectProperty ");
  }
  return self->entity;
}
  
- (EOAdaptorChannel *)adaptorChannel {
  if (self->adChannel == nil) {
    NSAssert(self->context, @"###4.5 missing context");
    
    self->adChannel = [[[self->context valueForKey:LSDatabaseChannelKey]
                                       adaptorChannel] retain];
    NSAssert(self->adChannel != nil, @"###4 couldn`t find adaptor channel");
  }
  return self->adChannel;
}

- (NSString *)defaultNamespace {
  return self->defaultNamespace;
}

- (void)setDefaultNamespace:(NSString *)_str {
  ASSIGN(self->defaultNamespace, _str);
}

- (NSString *)modifyPropertiesForGIDNotificationName {
  return @"SkyModifyPropertiesForGIDNotification";
}

- (NSString *)_restEntityPKName {
  if (self->restPKName == nil) {
    EOEntity *e;

    if ((e = [[self database] entityNamed:self->restEntityName])) {
      self->restPKName = [[[e attributeNamed:
                              [[e primaryKeyAttributeNames] lastObject]]
                              columnName] copy];
    }
  }
  return self->restPKName;
}

- (NSString *)_resEntityTableName {
  EOEntity *e = nil;
  
  if ((e = [[self database] entityNamed:self->restEntityName])) {
    return [e externalName];
  }
  return self->restEntityName;
}

/*
  got 2 arrays of GID lists, and copy properties from _source[n] -> _dest[n]
*/

- (BOOL)copyPropertiesFrom:(NSArray *)_source to:(NSArray *)_dest
{
  NSEnumerator *sourceEnum, *destEnum;
  EOGlobalID   *source, *dest;
  NSDictionary *props;
  
  if ([_source count] != [_dest count]) {
    NSLog(@"WARNING[%s]: unbalanced source/destination _source %@ _dest %@",
          __PRETTY_FUNCTION__, _source, _dest);
    return NO;
  }
  if (![_source count])
    return YES;

  sourceEnum = [_source objectEnumerator];
  destEnum   = [_dest objectEnumerator];
  props      = [self propertiesForGlobalIDs:_source namespace:nil];

  while ((source = [sourceEnum nextObject]) && (dest = [destEnum nextObject])) {
    NSMutableDictionary *keys;
    NGHashMap           *access;
    id                  obj;
    NSEnumerator        *enumerator;

    keys       = [[props objectForKey:source] mutableCopy];
    access     = [[[self _accessOIDsForGIDs:[NSArray arrayWithObject:source]]
                            objectEnumerator] nextObject];
    enumerator = [access keyEnumerator];
    while ((obj = [enumerator nextObject])) {
      NSEnumerator        *props;
      NSMutableDictionary *dict;
      id                  prop;

      dict = [[NSMutableDictionary alloc] initWithCapacity:64];
      props = [[access objectsForKey:obj] objectEnumerator];
      while ((prop = [props nextObject])) {
        [dict setObject:[keys objectForKey:prop] forKey:prop];
        [keys removeObjectForKey:prop];
      }
      [self addProperties:dict accessOID:obj globalID:dest];
      [dict release]; dict = nil;
    }
    if ([keys count] > 0)
      [self addProperties:keys accessOID:nil globalID:dest];
    
    [keys release]; keys = nil;
  }
  return YES;
}

/* debugging */

- (BOOL)isDebuggingEnabled {
  return SkyObjectPropertyManagerDebug;
}

@end /* SkyObjectPropertyManager */
