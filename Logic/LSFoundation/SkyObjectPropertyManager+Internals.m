/*
  Copyright (C) 2000-2004 SKYRIX Software AG

  This file is part of OGo

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

#include "SkyObjectPropertyManager+Internals.h"
#include <LSFoundation/SkyObjectPropertyManager.h>
#include <LSFoundation/LSTypeManager.h>
#include <LSFoundation/LSFoundation.h>
#include "LSCommandContext.h"
#include "LSCommandKeys.h"
#include "common.h"

#if !GNU_RUNTIME
#  ifndef SEL_EQ
#    define SEL_EQ(__A__,__B__) (__A__==__B__?YES:NO)
#  endif
#else
#  include <objc/objc-api.h>
#  ifndef SEL_EQ
#    define SEL_EQ(__A__,__B__) sel_eq(__A__,__B__)
#  endif
#endif

@interface SkyObjectPropertyManager(InternalsPriv)

- (NSMutableString *)_kVQualExpressionString:(EOQualifier *)_qualifier
  negate:(BOOL)_negate identifier:(NSString *)_ident;
- (NSMutableString *)_buildOrQualifierString:(NSArray *)_kvQualifiers
  qualCnt:(int *)qCnt_ identifier:(NSString *)_ident;
- (NSMutableString *)_buildSQLWithPropQual:(EOQualifier *)_qualifier
  objType:(NSString *)_objType identifier:(NSString *)_ident;
- (NSException *)_updateProperties:(NSDictionary *)_properties 
  globalID:(id)_gid checkExist:(BOOL)_check;
- (NSException *)_addProperties:(NSDictionary *)_properties 
  accessOID:(EOGlobalID *)_access globalID:(id)_gid checkExist:(BOOL)_check;
- (NSDictionary *)_accessOIDsForGIDs:(NSArray *)_gids;
- (void)_postChangeNotificationForGID:(EOGlobalID *)_gid;
- (NSString *)nextIdentifier;
- (NSString *)value:(id)_value forAttr:(EOAttribute *)_attr;
@end

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
static Class  NSDataClass                   = Nil;
static Class  NSURLClass                    = Nil;

static EONull   *SharedEONull = nil;
static NSNumber *YesNumber    = nil;
static NSNumber *NoNumber     = nil;

static NSArray *AttrsForAccessOIDs = nil;

extern NSString *SkyOPMNoAccessExceptionName;
extern NSString *SkyOPMKeyAlreadyExistExceptionName;
extern NSString *SkyOPMNoPrimaryKeyExceptionName;
extern NSString *SkyOPMCouldntInsertExceptionName;
extern NSString *SkyOPMCouldntUpdateExceptionName;
extern NSString *SkyOPMCouldntDeleteExceptionName;
extern NSString *SkyOPMCouldntSelectExceptionName;
extern NSString *SkyOPMKeyDoesntExistExceptionName;
extern NSString *SkyOPMWrongPropertyKeyExceptionName;


@implementation NSString(SkyPropNamespaces)

- (void)_extractSkyPropNamespace:(NSString **)namespace_
  andLocalKey:(NSString **)key_
  withDefaultNamespace:(NSString *)_defns
{
  NSRange r;
  int  i         = 0;
  BOOL missingNS = NO;

  if ([self length] < 2) {
    missingNS = YES;
  }
  if ([self characterAtIndex:0] != '{') {
    missingNS = YES;
  }
  r = [self rangeOfString:@"}"];
  if (r.length == 0)
    missingNS = YES;
  else
    i = r.location;
  if (missingNS) {
    if (_defns) {
      *namespace_ = _defns;
      *key_       = [[self copy] autorelease];
      return;
    }
    else {
      NSDictionary *ui;
      
      ui = [NSDictionary dictionaryWithObjectsAndKeys: self, @"key", nil];
      [[NSException exceptionWithName:SkyOPMWrongPropertyKeyExceptionName
                    reason:@"missing namespace"
                    userInfo:ui] raise];
    }
  }
  else {
    *namespace_ = [self substringWithRange:NSMakeRange(1, i - 1)];
  }
  if (*namespace_ == nil || [*namespace_ length] == 0) {
    NSDictionary *ui;

    ui = [NSDictionary dictionaryWithObjectsAndKeys:self, @"key", nil];
    [[NSException exceptionWithName:SkyOPMWrongPropertyKeyExceptionName
                  reason:@"missing namespace"
                  userInfo:ui] raise];
  }
  *key_ = [self substringFromIndex:(i + 1)];
  if (*key_ == nil || [*key_ length] == 0) {
    NSDictionary *ui;
    
    ui = [NSDictionary dictionaryWithObjectsAndKeys:self, @"key", nil];
    [[NSException exceptionWithName:SkyOPMWrongPropertyKeyExceptionName
                  reason:@"missing key"
                  userInfo:ui] raise];
  }
}

@end /* NSString(SkyPropNamespaces) */

@implementation SkyObjectPropertyManager(Internals)

#define BEGIN_ADAPTOR_TRANS(__adChannel)    \
  {                                         \
    BOOL             __commitTrans = NO;    \
    EOAdaptorContext *__ctx        = nil;   \
    if (![__adChannel isOpen]) {       \
      [__adChannel openChannel];            \
    }                                       \
    __ctx = [__adChannel adaptorContext];   \
    if (![__ctx hasOpenTransaction]) { \
      [__ctx beginTransaction];             \
      __commitTrans = YES;                  \
    }
 
#define CLOSE_ADAPTOR_TRANS(__rollback)    \
    if (__rollback)                 \
      [__ctx rollbackTransaction];         \
    else if (__commitTrans)         \
      [__ctx commitTransaction];           \
  }

+ (void)__initialize__Internals__ {
  if (YesNumber == nil)
    YesNumber = [[NSNumber numberWithBool:YES] retain];
  if (NoNumber == nil)
    NoNumber = [[NSNumber numberWithBool:NO] retain];
  
  NSNumberClass                 = [NSNumber class];
  NSStringClass                 = [NSString class];
  EOKeyGlobalIDClass            = [EOKeyGlobalID class];
  EOGenericRecordClass          = [EOGenericRecord class];
  NSCalendarDateClass           = [NSCalendarDate class];
  EOAndQualifierClass           = [EOAndQualifier class];
  EOOrQualifierClass            = [EOOrQualifier class];
  EOKeyValueQualifierClass      = [EOKeyValueQualifier class];
  EONotQualifierClass           = [EONotQualifier class];
  EOKeyComparisonQualifierClass = [EOKeyComparisonQualifier class];
  NSDataClass                   = [NSData class];
  NSURLClass                    = [NSURLClass class];

  if (SharedEONull == nil)
    SharedEONull = [NSNull null];
}

- (NSTimeZone *)_defaultTimeZone {
  NSTimeZone *tz;
  NSString *tzname;
  
  tzname = [[self->context userDefaults] objectForKey:@"timezone"];
  if ([tzname length] == 0) tzname = @"GMT";
  
  tz = [NSTimeZone timeZoneWithAbbreviation:tzname];
  return tz;
}

- (NSString *)_qualifierInStringForGIDs:(NSArray *)_gids {
  NSEnumerator    *enumerator;
  EOKeyGlobalID   *gid;
  NSMutableString *str;

  enumerator = [_gids objectEnumerator];
  str        = nil;
  
  while ((gid = [enumerator nextObject])) {
    if (str == nil)
      str = [NSMutableString stringWithCapacity:256];
    else
      [str appendString:@","];
    
    [str appendString:[[gid keyValues][0] stringValue]];
  }
  return str;
}

- (void)_objectId:(id)_obj
  objectId:(id *)objectId_
  objectType:(id *)objectType_
{
  _obj = [_obj isNotNull] ? _obj : nil;

  NSAssert(_obj != nil, @"missing global id");
  NSAssert([_obj isKindOfClass:EOKeyGlobalIDClass],
           @"expected EOKeyGlobalIDClass");
  
  *objectId_   = [_obj keyValues][0];
  *objectType_ = [_obj entityName];    
}

- (void)_buildValues:(id)_value
  pType:(NSString **)pType_   
  vString:(NSString **)vString_
  vInt:(NSNumber **)vInt_
  vFloat:(NSNumber **)vFloat_
  vDate:(NSCalendarDate **)vDate_
  vOID:(NSNumber **)vOID_
  blobSize:(NSNumber **)bSize_
  vBlob:(NSData **)vBlob_
{
  SkyPropValues vals;
  
  /* clear value structure */
  memset(&vals, 0, sizeof(vals));

  /* fill values */
  [_value _buildSkyPropValues:&vals];
  
  /* transfer results */
  *pType_   = vals.pType;
  *vString_ = vals.vString;
  *vInt_    = vals.vInt;
  *vFloat_  = vals.vFloat;
  *vDate_   = vals.vDate;
  *vOID_    = vals.vOID;
  *vBlob_   = vals.vBlob;
  *bSize_   = vals.bSize;
}

- (BOOL)_keyAlreadyExist:(NSString *)_key
  namespace:(NSString *)_namespace
  objectId:(NSNumber *)_oid 
{
  EOSQLQualifier   *qualifier;
  EOEntity         *e;
  NSArray          *attrs;
  BOOL             result;
  EOAdaptorChannel *adc;
  NSString         *format;

  result = NO;
  adc    = [self adaptorChannel];
  e      = [self entity];
  attrs  = [e primaryKeyAttributes];
  
  BEGIN_ADAPTOR_TRANS(adc) {
    format = (_namespace == nil)
      ? @"objectId = %@ AND key = '%@' AND namespacePrefix IS NULL"
      : @"objectId = %@ AND key = '%@' AND namespacePrefix = '%@'";
  
    qualifier = [[EOSQLQualifier alloc]
                                 initWithEntity:e
                                 qualifierFormat:format,
                                 _oid, _key, _namespace];
    [self->dbMessages removeAllObjects];
    if (![adc selectAttributes:attrs
             describedByQualifier:qualifier
             fetchOrder:nil
             lock:NO]) {
      NSDictionary *ui;

      ui = [NSDictionary dictionaryWithObjectsAndKeys:
			   qualifier, @"qualifier",
			   self->dbMessages, @"dbMessages",
			 nil];
      [[NSException exceptionWithName:SkyOPMCouldntSelectExceptionName
                    reason:@"couldn`t select"
                    userInfo:ui] raise];
    }
    [qualifier release]; qualifier = nil;
    if ([adc fetchAttributes:attrs withZone:NULL] != nil)
      result = YES;
    [adc cancelFetch];
  }
  CLOSE_ADAPTOR_TRANS(NO);
  return result;
}

- (NSString *)_buildKeyQualifier:(NSArray *)_keys
  objectId:(NSNumber *)_objId
{
  NSMutableString *str;
  NSEnumerator    *enumerator;
  id              key;
  BOOL            isFirst;

  isFirst = YES;
  str     = [NSMutableString stringWithCapacity:512];
  
  if ([_keys count] == 0) {
    NSLog(@"WARNING: no keys to delete");
    return nil;
  }
  enumerator = [_keys objectEnumerator];

  [str appendString:@"objectId = "];
  [str appendString:[_objId stringValue]];
  [str appendString:@" AND ("];
  while ((key = [enumerator nextObject])) {
    NSString *k, *ns;

    k  = nil;
    ns = nil;
    
    [key _extractSkyPropNamespace:&ns andLocalKey:&k
         withDefaultNamespace:self->defaultNamespace];
    
    if (isFirst)
      isFirst = NO;
    else
      [str appendString:@" OR "];

    [str appendString:@"((key = '"];
    [str appendString:k];
    [str appendString:@"') AND "];
    if (ns != nil) {
      [str appendString:@"(namespacePrefix = '"];
      [str appendString:ns];
      [str appendString:@"'))"];
    }
    else {
      [str appendString:@"(namespacePrefix IS NULL))"];      
    }
  }
  [str appendString:@")"];
  [self debugWithFormat:@"keyQual %@", str];
  return str;
}

- (BOOL)_operation:(NSString *)_operation allowedOnProperties:(NSArray *)_prop {
  id           *access_ids, *object_ids, *property_ids, login;
  NSEnumerator *enumerator;
  NSDictionary *dict;
  NSString     *l;
  
  NSMutableDictionary *maskProperty, *maskAccess, *maskObject;
  
  int  propCnt;
  int  propArrayCnt;  
  int  cnt, i;
  BOOL result, checkMaskP;

  result = 0;
  cnt    = [_prop count];

  [self debugWithFormat:@"_operation:<%@> allowedOnProperties:<%@>",
        _operation, _prop];
  
  maskProperty = [self->_maskPropertyCache objectForKey:_operation];
  
  if (maskProperty == nil) {
    maskProperty = (NSMutableDictionary *)[NSMutableDictionary dictionary];
    [self->_maskPropertyCache setObject:maskProperty forKey:_operation];
    checkMaskP = NO;
  }
  else
    checkMaskP = YES;

  login = [self->context valueForKey:LSAccountKey];
  l     =  [login valueForKey:@"companyId"];
  
  if ([l intValue] == 10000)
    return YES;

  if (self->_loginId == nil) {
    self->_loginId  = [[login valueForKey:@"companyId"] retain];
  }
  if (self->_groupIds == nil) {
    NSAssert(l != nil, @"missing login");
    self->_groupIds = [[[self->context runCommand:@"account::teams",
                             @"account", login, nil] 
			 map:@selector(valueForKey:)
			 with:@"companyId"] retain];
  }
  
  property_ids = calloc(cnt + 2, sizeof(id));
  access_ids   = calloc(cnt + 2, sizeof(id));
  object_ids   = calloc(cnt + 2, sizeof(id));
  enumerator   = [_prop objectEnumerator];

  propCnt      = 0;
  propArrayCnt = 0;
  
  while ((dict = [enumerator nextObject])) {
    id aid, pid;

    pid = [dict objectForKey:@"objectPropertyId"];

    if (checkMaskP) {
      NSNumber *n;
      
      if ((n = [maskProperty objectForKey:pid]) != nil) {
        if (n == YesNumber) {
          property_ids[propArrayCnt] = nil;
          object_ids[propArrayCnt]   = nil;    
          access_ids[propArrayCnt]   = nil;
          propArrayCnt++;
          continue;
        }
        else {
          result = NO;
          goto FREE_ARRAYS;
        }
      }
    }
    property_ids[propArrayCnt] = pid;
    object_ids[propArrayCnt]   = [dict objectForKey:@"objectId"];    
    access_ids[propArrayCnt]   =
      ([aid = [dict objectForKey:@"accessKey"] isNotNull]) ? aid : nil;
    propArrayCnt++;
    propCnt++;
  }
  if (propCnt == 0) {
    result = YES;
    goto FREE_ARRAYS;
  }

  maskAccess = [self->_maskAccessCache objectForKey:_operation];
  if (maskAccess == nil) {
    maskAccess = (NSMutableDictionary *)[NSMutableDictionary dictionary];
    [self->_maskAccessCache setObject:maskAccess forKey:_operation];
  }

  maskObject = [self->_maskObjectCache objectForKey:_operation];
  if (maskObject == nil) {
    maskObject = (NSMutableDictionary *)[NSMutableDictionary dictionary];
    [self->_maskObjectCache setObject:maskObject forKey:_operation];
  }
  
  for (i = 0; i < propArrayCnt && propCnt > 0; i++) {
    if (property_ids[i] == nil)
      continue;

    if (access_ids[i] != nil) {
      NSNumber *n = nil;
      
      if ((n = [maskAccess objectForKey:access_ids[i]]) != nil) {
        if (n == YesNumber) {
          propCnt--;
          continue;
        }
        else {
          result = NO;
          goto FREE_ARRAYS;
        }
      }
      if ([self->_loginId isEqual:access_ids[i]] ||
          [self->_groupIds containsObject:access_ids[i]]) {
        [maskAccess setObject:YesNumber forKey:access_ids[i]];
        [maskProperty setObject:YesNumber forKey:property_ids[i]];
        propCnt--;
        continue;
      }
      else {
        [maskAccess setObject:NoNumber forKey:access_ids[i]];
        [maskProperty setObject:NoNumber forKey:property_ids[i]];
        result = NO;
        goto FREE_ARRAYS;
      }
    }
    else if (object_ids[i] != nil) {
      NSNumber *n = nil;

      if ((n = [maskObject objectForKey:object_ids[i]]) != nil) {
        if (n == YesNumber) {
          propCnt--;
          continue;
        }
        else {
          result = NO;
          goto FREE_ARRAYS;
        }
      }
      else {
#if 0 /* here should be inserted an access manager for the objects */
        EOKeyGlobalID *gid = nil;

        gid = (EOKeyGlobalID *)
          [self->typeManager globalIDForPrimaryKey:object_ids[i]];
        if ([self->accessManager operation:_operation allowedOnObjectID:gid]) {
          [maskObject setObject:YesNumber forKey:object_ids[i]];
          [maskObject setObject:YesNumber forKey:property_ids[i]];
          propCnt--;
          continue;
        }
        else {
          [maskObject setObject:NoNumber forKey:object_ids[i]];
          [maskObject setObject:NoNumber forKey:property_ids[i]];
          result = NO;
          goto FREE_ARRAYS;
        }
#else
        [maskObject setObject:YesNumber forKey:object_ids[i]];
        [maskObject setObject:YesNumber forKey:property_ids[i]];
        propCnt--;
#endif        
      }
    }
    else {
      NSAssert(NO, @"missing object id");
    }
  }
  if (propCnt == 0)
    result = YES;
  
FREE_ARRAYS:
  free(property_ids); property_ids = NULL;
  free(access_ids);   access_ids   = NULL;
  free(object_ids);   object_ids   = NULL;
  [self debugWithFormat:@"%s: returns %@", __PRETTY_FUNCTION__,
        result ? @"YES":@"NO"];
  return result;
}

- (void)_disassembleContainerQualifer:(EOQualifier *)_qualifier
  kvQuals:(NSMutableArray *)kvQualifiers_
  notQuals:(NSMutableArray *)notQualifiers_
  orQuals:(NSMutableArray *)orQualifiers_
  andQuals:(NSMutableArray *)andQualifiers_ 
{
  NSEnumerator *enumerator;
  EOQualifier  *qual;
  BOOL         resAnd;

  if ([_qualifier isKindOfClass:EOAndQualifierClass])
    resAnd = YES;
  else if ([_qualifier isKindOfClass:EOOrQualifierClass])
    resAnd = NO;
  else {
    resAnd = NO;
    NSCAssert(NO, @"expected AND or OR Qualifier");
  }

  enumerator = [[(EOAndQualifier *)_qualifier qualifiers] objectEnumerator];

  while ((qual = [enumerator nextObject])) {
    // TODO: can't that be moved to appropriate EOQualifier categories?
    
    if ([qual isKindOfClass:EOAndQualifierClass]) {
      if (resAnd)
        [self _disassembleContainerQualifer:qual kvQuals:kvQualifiers_
              notQuals:notQualifiers_ orQuals:orQualifiers_
              andQuals:andQualifiers_];
      else
        [andQualifiers_ addObject:qual];
    }
    else if ([qual isKindOfClass:EOOrQualifierClass]) {
      if (!resAnd)
        [self _disassembleContainerQualifer:qual kvQuals:kvQualifiers_
              notQuals:notQualifiers_ orQuals:orQualifiers_
              andQuals:andQualifiers_];
      else
        [orQualifiers_ addObject:qual];
    }
    else if ([qual isKindOfClass:EOKeyValueQualifierClass]) {
      [kvQualifiers_ addObject:qual];
    }
    else if ([qual isKindOfClass:EONotQualifierClass]) {
      [notQualifiers_ addObject:qual];
    }
    else {
      NSCAssert(NO, @"wrong qualifier");
    }
  }
}

- (NSMutableString *)_kVQualExpressionString:(EOQualifier *)_qualifier
  negate:(BOOL)_negate identifier:(NSString *)_ident
{
  NSMutableString *result;
  id              value;
  NSString        *nsp, *key, *oidName, *nsName, *tName, *kName;
  EOAttribute     *oidAttr, *nsAttr, *keyAttr;

  tName   = [[self entity] externalName];
  oidAttr = [[self entity] attributeNamed:@"objectId"];
  oidName = [oidAttr columnName];

  nsAttr = [[self entity] attributeNamed:@"namespacePrefix"];
  nsName = [nsAttr columnName];
    
  keyAttr = [[self entity] attributeNamed:@"key"];
  kName   =  [keyAttr columnName];

  nsp = nil;
  key = nil;
  
  NSAssert([_qualifier isKindOfClass:EOKeyValueQualifierClass],
           @"wrong qualifier, expected EOKeyValueQualifier");

  result = [[NSMutableString alloc] initWithCapacity:512];

  NSAssert(result != nil, @"string allocation failed");

  NSAssert(_qualifier != nil, @"missing qualifier");
  NSAssert1([(EOKeyValueQualifier *)_qualifier key] != nil,
            @"missing qualifier key for qual %@", _qualifier);


  [[(EOKeyValueQualifier *)_qualifier key]
                         _extractSkyPropNamespace:&nsp andLocalKey:&key
                         withDefaultNamespace:self->defaultNamespace];
  NSAssert1(key != nil, @"missing key for qual %@", _qualifier);

  value = [(EOKeyValueQualifier *)_qualifier value];

  if (![value isNotNull]) {
    BOOL     isNull = NO;
    NSString *ident;
    SEL      op;
    
    op = [(id)_qualifier selector];

    if (SEL_EQ(op, EOQualifierOperatorEqual)) {
      isNull = YES;
    }
    else if (SEL_EQ(op, EOQualifierOperatorNotEqual)) {
      isNull = NO;
    }
    else {
      NSAssert1(NO, @"wrong operator for is null qualifier %@", _qualifier);
    }
    if (_negate) {
      isNull = (isNull) ? NO : YES;
    }
    if (isNull) {
      ident = [self nextIdentifier];

      [result appendFormat:
                @"%@ NOT IN (SELECT DISTINCT %@%@ FROM %@ %@ WHERE ",
                oidName, ident, oidName, tName,
                [ident substringToIndex:([ident length] - 1)]];
    }
    else {
      ident = _ident;
    }
    [result appendFormat:@"(%@%@ = %@) AND (%@%@ = %@)",
            ident, nsName, [self value:nsp forAttr:nsAttr],
            ident, kName,  [self value:key forAttr:keyAttr]];
    
    if (isNull) [result appendString:@")"];
  }
  else {
    NSString *kind, *opSel;
    
    [result appendFormat:@"(%@%@ = %@) AND (%@%@",
            _ident, kName, [self value:key forAttr:keyAttr], _ident, nsName];
    if (nsp != nil) {
      [result appendString:@" = "];
      [result appendString:[self value:nsp forAttr:nsAttr]];
    }
    else {
      [result appendString:@" IS NULL"];
    }
    [result appendString:@") AND "];
      
    kind  = [value _skyPropValueKind];
    value = [self value:value forAttr:[[self entity] attributeNamed:kind]];
    opSel = [EOQualifier stringForOperatorSelector:
                         [(EOKeyValueQualifier *)_qualifier selector]];

    if (_negate)
      [result appendString:@"NOT ("];

    [result appendFormat:@"%@%@ %@ %@",
            _ident, [[[self entity] attributeNamed:kind] columnName], opSel,
            value];

    if (_negate)
      [result appendString:@")"];
  }
  [self debugWithFormat:
        @"got sql-string <%@> for qualifier <%@>", result, _qualifier];
  
  return [result autorelease];
}

- (NSMutableString *)_buildOrQualifierString:(NSArray *)_kvQualifiers
  qualCnt:(int *)qCnt_ identifier:(NSString *)_ident
{
  NSEnumerator     *enumerator;
  NSMutableString  *result;
  int              i, cnt;
  NSMutableArray   *readyQuals;

  cnt        = [_kvQualifiers count];
  result     = [NSMutableString stringWithCapacity:cnt * 40];
  readyQuals = [[NSMutableArray alloc] initWithCapacity:cnt];
  enumerator = [_kvQualifiers objectEnumerator];

  for (i = 0; i < cnt; i++) {
    EOQualifier *qual;

    qual = [_kvQualifiers objectAtIndex:i];    

    if ([readyQuals containsObject:qual])
      continue;
    else
      [readyQuals addObject:qual];
    
    NSCAssert([qual isKindOfClass:EOKeyValueQualifierClass],
              @"wrong qualifierclass, expected EOKeyValueQualifierClass");

    if (i > 0)
      [result appendString:@" OR "];
    if (cnt > 1)
      [result appendString:@"("];
    [result appendString:[self _kVQualExpressionString:qual negate:NO
                               identifier:_ident]];

    if (cnt > 1)
      [result appendString:@")"];
  }
  [self debugWithFormat:
        @"_buildOrQualifier returns <%@> for <%@>", result, _kvQualifiers];

  *qCnt_ = [readyQuals count];
  [readyQuals release]; readyQuals = nil;
  
  return result;
}

- (NSMutableString *)_buildSQLWithPropQual:(EOQualifier *)_qualifier
  objType:(NSString *)_objType identifier:(NSString *)_ident
{
  // TODO: split up this huge method!
  NSMutableString *result = nil;
  
  NSString    *oidName, *nsName, *tName, *kName, *typeName;
  EOEntity    *e;
  EOAttribute *oidAttr, *nsAttr, *keyAttr, *typeAttr;

  e        = [self entity];
  result   = nil;
  tName    = [e externalName];
  oidAttr  = [e attributeNamed:@"objectId"];
  oidName  = [oidAttr columnName];
  nsAttr   = [e attributeNamed:@"namespacePrefix"];
  nsName   = [nsAttr columnName];
  keyAttr  = [e attributeNamed:@"key"];
  kName    =  [keyAttr columnName];
  typeAttr = [e attributeNamed:@"objectType"];
  typeName =  [typeAttr columnName];
  
  if ([_qualifier isKindOfClass:EOAndQualifierClass]) {
    BOOL           isFirst;
    NSMutableArray *kvQuals, *notQuals, *orQuals;

    isFirst  = YES;
    kvQuals  = [[NSMutableArray alloc] initWithCapacity:64];
    notQuals = [[NSMutableArray alloc] initWithCapacity:64];
    orQuals  = [[NSMutableArray alloc] initWithCapacity:64];

    [self _disassembleContainerQualifer:_qualifier
          kvQuals:kvQuals notQuals:notQuals orQuals:orQuals andQuals:nil];

    result = [NSMutableString stringWithCapacity:512];

    if ([kvQuals count] > 0) {
      NSString *identifier;
      int      cnt;

      cnt        = 0;
      identifier = [self nextIdentifier];
      
      [result appendFormat:@" %@%@ IN (SELECT %@%@ FROM %@ %@ WHERE ",
              _ident, oidName,
              identifier, oidName,
              tName, [identifier substringToIndex:[identifier length] - 1]];
      [result appendString:[self _buildOrQualifierString:kvQuals qualCnt:&cnt
                                 identifier:identifier]];
      if (_objType == nil) {
        if (cnt > 1) {
          [result appendFormat:@" GROUP BY %@%@ HAVING COUNT(*) = %d",
                  identifier, oidName, cnt];
        }
      }
      else {
        [result appendFormat:@" AND %@%@ = %@",
                identifier, typeName, [self value:_objType forAttr:typeAttr]];
        if (cnt > 1) {
          [result appendFormat:@" GROUP BY %@%@ HAVING COUNT(*) = %d",
                  identifier, oidName, cnt];
        }
      }
      [result appendString:@")"];
      isFirst = NO;
    }
    if ([notQuals count] > 0 || [orQuals count] > 0) {
      if ([notQuals count] > 0) {
        NSString    *identifier;
        EOQualifier *qualifier;

        identifier = [self nextIdentifier];
        
        qualifier = ([notQuals count] > 1)
          ? [[EOAndQualifier alloc] initWithQualifierArray:
				      [notQuals map:@selector(qualifier)]]
          : [[(EONotQualifier *)[notQuals lastObject] qualifier] retain];

        if (isFirst)
          isFirst = NO;
        else
          [result appendString:@" AND "];

        if (_objType == nil) {
          [result appendFormat:@"%@%@ NOT IN (SELECT %@%@ FROM %@ %@ "
                  @"WHERE %@)", _ident, oidName, identifier, oidName,
                  tName, [identifier substringToIndex:[identifier length] - 1],
                  [self _buildSQLWithPropQual:qualifier
                        objType:_objType identifier:identifier]];
        }
        else {
          [result appendFormat:@"(%@%@ NOT IN (SELECT %@%@ FROM %@ %@ WHERE "
                  @"%@ )) AND %@%@ = %@",
                  _ident, oidName, identifier, oidName, tName,
                  [identifier substringToIndex:[identifier length] - 1],
                  [self _buildSQLWithPropQual:qualifier
                        objType:_objType identifier:identifier], _ident,
                  typeName, [self value:_objType forAttr:typeAttr]];
        }
        [qualifier release]; qualifier = nil;
      }
      if ([orQuals count] > 0) {
        NSString     *identifier;
        NSEnumerator *enumerator;
        EOQualifier  *orq;

        identifier = [self nextIdentifier];
        enumerator = [orQuals objectEnumerator];

        if (_objType != nil)
          [result appendString:@"("];
        
        while ((orq = [enumerator nextObject])) {
          if (isFirst)
            isFirst = NO;
          else
            [result appendString:@" AND "];

          [result appendFormat:@"%@%@ IN (SELECT %@%@ FROM %@ %@ WHERE %@)",
                  _ident, oidName, identifier, oidName, tName,
                  [identifier substringToIndex:[identifier length] - 1],
                  [self _buildSQLWithPropQual:orq objType:_objType
                        identifier:identifier]];
        }
        if (_objType != nil) {
          [result appendFormat:@") AND %@%@ = %@",
                  _ident, typeName, [self value:_objType forAttr:typeAttr]];
        }
      }
    }
    [kvQuals  release]; kvQuals  = nil;
    [notQuals release]; notQuals = nil;
    [orQuals  release]; orQuals  = nil;
  }
  else if ([_qualifier isKindOfClass:EOOrQualifierClass]) {
    BOOL            isFirst;
    NSMutableArray  *kvQuals, *notQuals, *andQuals;

    isFirst   = YES;
    kvQuals  = [[NSMutableArray alloc] initWithCapacity:64];
    notQuals = [[NSMutableArray alloc] initWithCapacity:64];
    andQuals = [[NSMutableArray alloc] initWithCapacity:64];

    [self _disassembleContainerQualifer:_qualifier
          kvQuals:kvQuals notQuals:notQuals orQuals:nil andQuals:andQuals];
    result = [NSMutableString stringWithCapacity:512];

    if (_objType != nil) {
      [result appendString:@"("];
    } 
    if ([kvQuals count] > 0) {
      int cnt = 0;
      [result appendString:@"("];
      [result appendString:[self _buildOrQualifierString:kvQuals qualCnt:&cnt
                                 identifier:_ident]];
      isFirst = NO;
      [result appendString:@")"];      
    }
    if ([notQuals count] > 0) {
      EOQualifier  *qualifier;
      NSEnumerator *enumerator;

      enumerator = [notQuals objectEnumerator];
      while ((qualifier = [enumerator nextObject])) {
        if (isFirst)
          isFirst = NO;
        else
          [result appendString:@" OR "];
        
        [result appendString:@"("];
        [result appendString:[self _buildSQLWithPropQual:qualifier
                                   objType:_objType identifier:_ident]];
        [result appendString:@")"];      
      }
    }
    if ([andQuals count] > 0) {
      NSEnumerator *enumerator;
      EOQualifier  *andq;
      NSString     *identifier;

      identifier = [self nextIdentifier];
      enumerator = [andQuals objectEnumerator];
      
      while ((andq = [enumerator nextObject])) {
        if (isFirst)
          isFirst = NO;
        else
          [result appendString:@" OR "];

        [result appendFormat:@"(%@%@ IN (SELECT %@%@ FROM %@ %@ WHERE %@))",
                _ident, oidName, identifier, oidName, tName,
                [identifier substringToIndex:[identifier length] - 1],
                [self _buildSQLWithPropQual:andq objType:_objType
                      identifier:identifier]];
      }
    }
    ASSIGN(kvQuals, nil);
    ASSIGN(notQuals, nil);
    ASSIGN(andQuals, nil);
    if (_objType != nil) {
      [result appendFormat:@") AND %@%@ = %@", _ident, typeName,
              [self value:_objType forAttr:typeAttr]];
    }
  }
  else if ([_qualifier isKindOfClass:EONotQualifierClass]) {
    EOQualifier *qualifier;

    qualifier = [(EONotQualifier *)_qualifier qualifier];

    result = [NSMutableString stringWithCapacity:512];    

    if ([qualifier isKindOfClass:EOAndQualifierClass] ||
        [qualifier isKindOfClass:EOOrQualifierClass]) {
      NSString *identifier = nil;

      identifier = [self nextIdentifier];

      [result appendFormat:@"%@%@ NOT IN (SELECT %@%@ FROM %@ %@ WHERE %@)",
              _ident, oidName, identifier, oidName, tName,
              [identifier substringToIndex:[identifier length] - 1],
              [self _buildSQLWithPropQual:qualifier
                    objType:_objType identifier:identifier]];
    }
    else if ([qualifier isKindOfClass:EONotQualifierClass]) {
      [result appendString:
              [self _buildSQLWithPropQual:[(EONotQualifier *)qualifier qualifier]
                    objType:_objType identifier:_ident]];
    }
    else if ([qualifier isKindOfClass:EOKeyValueQualifierClass]) {
      result = [self _kVQualExpressionString:qualifier negate:YES
                     identifier:_ident];
    }
  }
  else if ([_qualifier isKindOfClass:EOKeyValueQualifierClass]) {
    result = [self _kVQualExpressionString:_qualifier negate:NO
                   identifier:_ident];
  }
  else {
    NSCAssert(NO, @"###1.55 unknown qualifier");
  }
  return result;
}

- (NSException *)_addProperties:(NSDictionary *)_properties 
  accessOID:(EOGlobalID *)_access globalID:(id)_gid checkExist:(BOOL)_check
{
  NSException      *result;
  NSEnumerator     *enumerator;
  NSString         *key;
  EOAdaptorChannel *adc;
  EOEntity         *e;
  BOOL             rollback;
  int              valueCount;
  id               *objs, *keys;

#if 1
  if (![[self->context accessManager] operation:@"w" allowedOnObjectID:_gid]) {
    NSLog(@"WARNING[%s] no write acccess for gid ", __PRETTY_FUNCTION__, _gid);
    return nil;
  }
#endif  
  
  result   = nil;
  rollback = NO;
  adc      = [self adaptorChannel];
  e        = [self entity];
  keys     = malloc(sizeof(id) * 14);
  objs     = malloc(sizeof(id) * 14);

  keys[0]  = @"objectPropertyId";
  keys[1]  = @"objectId";
  keys[2]  = @"objectType";
  keys[3]  = @"key";
  keys[4]  = @"preferredType";
  keys[5]  = @"namespacePrefix";  
  keys[6]  = @"accessKey";    
  keys[7]  = @"valueString";  
  keys[8]  = @"valueInt";
  keys[9]  = @"valueFloat";
  keys[10] = @"valueDate";
  keys[11] = @"valueOID";  
  keys[12] = @"blobSize";  
  keys[13] = @"valueBlob";  

  _access     = [_access isNotNull]     ? _access     : nil;
  _properties = [_properties isNotNull] ? _properties : nil;

  NSAssert(_access == nil || [_access isKindOfClass:EOKeyGlobalIDClass],
           @"expected EOKeyGlobalIDClass for accessOID");
    
  if ([_properties count] == 0)
    return nil;
    
  [self _objectId:_gid objectId:&objs[1] objectType:&objs[2]];

#if DEBUG
  NSAssert(objs[1] != nil, @"###6 missing object id");
  NSAssert(objs[2] != nil, @"###7 missing object type"); 
#endif  

  if (_access != nil) {
#if DEBUG
    NSAssert([(EOKeyGlobalID *)_access keyCount] == 1,
             @"###8 [_access keyCount] != 1");
#endif
    objs[6] = [(EOKeyGlobalID *)_access keyValues][0];
  }
  else
    objs[6] = nil;
  
  enumerator = [[_properties allKeys] objectEnumerator];
  while ((key = [enumerator nextObject])) {
    NSDictionary *row;

    /* key & namespacePrefix */
    [key _extractSkyPropNamespace:&objs[5] andLocalKey:&objs[3]
         withDefaultNamespace:self->defaultNamespace];
    
    if (_check) {
      if ([self _keyAlreadyExist:objs[3] namespace:objs[5]
                objectId:objs[1]]) {
        return
          [NSException exceptionWithName:SkyOPMKeyAlreadyExistExceptionName
                       reason:@"{namespace}key already exist while new"
                       userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                              objs[3], @"key",
                                              objs[5], @"namespace", nil]];
      }
    }    
#if DEBUG
    NSAssert(objs[3] != nil, @"###9 missing key after seperating");
#endif
    [self _buildValues:[_properties objectForKey:key]
          pType:&objs[4]   
          vString:&objs[7]
          vInt:&objs[8]
          vFloat:&objs[9]
          vDate:&objs[10]
          vOID:&objs[11]
          blobSize:&objs[12]
          vBlob:&objs[13]];
#if DEBUG
    NSAssert(objs[4] != nil, @"###10 got no preferred type");
#endif
      
    [self->dbMessages removeAllObjects];
    BEGIN_ADAPTOR_TRANS(adc) {
     
      objs[0] = [[adc primaryKeyForNewRowWithEntity:e]
                      objectForKey:@"objectPropertyId"];
      if (objs[0] == nil) {
        return [NSException exceptionWithName:SkyOPMNoPrimaryKeyExceptionName
                            reason:@"got no primary key"
                            userInfo:(id)self->dbMessages];
      }
      valueCount = (objs[12] == nil) ? 12 : 14;
      {
        int i;
        for (i = 5; i < valueCount; i++) {
          if (objs[i] == nil)
            objs[i] = SharedEONull;
        }
      }
      
      row = [[NSDictionary alloc] initWithObjects:objs
                                  forKeys:keys count:valueCount];
      [self debugWithFormat:@"row to insert: %@", row];
      [self->dbMessages removeAllObjects];
      
      if (![adc insertRow:row forEntity:e]) {
        result = [NSException exceptionWithName:SkyOPMCouldntInsertExceptionName
                              reason:@"couldn`t insert row"
                              userInfo:
                              [NSDictionary dictionaryWithObjectsAndKeys:
                                            row, @"row", 
                                            e,   @"entity",
                                            self->dbMessages,
                                            @"dbMessages",nil]];
        rollback = YES;
      }
    }
    CLOSE_ADAPTOR_TRANS(rollback);
    ASSIGN(row, nil);
  }
  free(objs); objs = NULL;
  free(keys); keys = NULL;
  [self _postChangeNotificationForGID:(EOGlobalID *)_gid];
  return result;
}

- (NSException *)_updateProperties:(NSDictionary *)_properties 
  globalID:(id)_gid checkExist:(BOOL)_check
{
  NSException      *result;
  NSEnumerator     *enumerator;
  EOAdaptorChannel *adc;
  EOEntity         *e;
  NSNumber         *objId;
  NSString         *key, *type;
  id               *objs, *keys;
  BOOL             rollback;

  result      = nil;
  adc         = [self adaptorChannel];
  e           = [self entity];
  _properties = [_properties isNotNull] ? _properties : nil;
  objId       = nil;
  type        = nil;
  rollback    = NO;
  
  if (![[self->context accessManager] operation:@"w" allowedOnObjectID:_gid]) {
    NSLog(@"WARNING[%s] no write acccess for gid ", __PRETTY_FUNCTION__, _gid);
    return nil;
  }

  if ([_properties count] == 0)
    return nil;
    
  keys = malloc(sizeof(id) * 8);
  objs = malloc(sizeof(id) * 8);

  keys[0] = @"preferredType";
  keys[1] = @"valueString";  
  keys[2] = @"valueInt";
  keys[3] = @"valueFloat";
  keys[4] = @"valueDate";
  keys[5] = @"valueOID";  
  keys[6] = @"blobSize";  
  keys[7] = @"valueBlob";  
  
  [self _objectId:_gid objectId:&objId objectType:&type];
    
  NSAssert(objId, @"missing object id");

  BEGIN_ADAPTOR_TRANS(adc) {
    enumerator = [[_properties allKeys] objectEnumerator];
    while ((key = [enumerator nextObject])) {
      NSDictionary   *row;
      NSString       *k, *ns;
      EOSQLQualifier *qualifier;
      int            i, valueCount;
      BOOL           res;
      
      /* key & namespacePrefix */
      k  = nil;
      ns = nil;
      [key _extractSkyPropNamespace:&ns andLocalKey:&k
           withDefaultNamespace:self->defaultNamespace];
      
      if (_check) {
        if (![self _keyAlreadyExist:k namespace:ns objectId:objId]) {
	  NSDictionary *ui;
	  
	  ui = [NSDictionary dictionaryWithObjectsAndKeys:
			       k, @"key",
  			       ns != nil ? ns : (id)SharedEONull,
			       @"namespace", nil];
          return [NSException exceptionWithName:
                                SkyOPMKeyDoesntExistExceptionName
                              reason:
                                @"{namespace}key doesn`t exist while update"
                              userInfo:ui];
        }
      }

      qualifier = [EOSQLQualifier alloc];
      qualifier = (ns == nil)
        ? [qualifier initWithEntity:e
                     qualifierFormat:@"objectId = %@ AND "
                       @"key = '%@' AND namespacePrefix IS NULL",
                       objId, k]
        : [qualifier initWithEntity:e
                     qualifierFormat:@"objectId = %@ AND "
                       @"key = '%@' AND namespacePrefix = '%@'",
                       objId, k, ns];
      
      [self _buildValues:[_properties objectForKey:key]
            pType:&objs[0]   
            vString:&objs[1]
            vInt:&objs[2]
            vFloat:&objs[3]
            vDate:&objs[4]
            vOID:&objs[5]
            blobSize:&objs[6]
            vBlob:&objs[7]];
      
      valueCount = (objs[6] == nil) ? 6 : 8;
      for (i = 0; i < valueCount; i++) {
        if (objs[i] == nil)
          objs[i] = SharedEONull;
      }
      row = [[NSDictionary alloc]
                           initWithObjects:objs forKeys:keys count:valueCount];
      [self debugWithFormat:@"row to update: %@", row];
      [self->dbMessages removeAllObjects];

      res = NO;
      NS_DURING {
        res = [adc updateRow:row describedByQualifier:qualifier];
      }
      NS_HANDLER {
        printf("_updateProperties: got unexpected exception %s\n",
               [[localException description] cString]);
        res = NO;
      }
      NS_ENDHANDLER;
      if (!res) {
        NSDictionary *info;

        info = [NSDictionary dictionaryWithObjectsAndKeys:
                             row, @"row", 
                             e, @"entity",
                             self->dbMessages, @"dbessages", nil];
        result = [NSException exceptionWithName:
                              SkyOPMCouldntUpdateExceptionName
                              reason:@"couldn`t update row"
                              userInfo:info];
        rollback = YES;
      }
      [qualifier release]; qualifier = nil;
      [row       release]; row       = nil;
    }
  }
  CLOSE_ADAPTOR_TRANS(rollback);
  if (objs) free(objs); objs = NULL;
  if (keys) free(keys); keys = NULL;
  [self _postChangeNotificationForGID:(EOGlobalID *)_gid];
  return result;
}

- (NSDictionary *)_accessOIDsForGIDs:(NSArray *)_gids {
  // TODO: cleanups / split up
  EOEntity            *e;
  EOAdaptorChannel    *adc;
  NSMutableDictionary *props;
  NSMutableArray      *tmp;
  NSEnumerator        *enumerator;
  NSDictionary        *mapOIDsWithGIDs, *mapAccessIds, *fetch;

  if (![[self->context accessManager] operation:@"r"
                                      allowedOnObjectIDs:_gids]) {
    NSLog(@"WARNING[%s] no r acccess for gid ", __PRETTY_FUNCTION__, _gids);
    return nil;
  }
  if ([_gids count] == 0) {
    return nil;
  }
  mapOIDsWithGIDs = [self mapOIDsWithGIDs:_gids];
  e               = [self entity];
  adc             = [self adaptorChannel];
  mapAccessIds    = nil;
  
  if (AttrsForAccessOIDs == nil) {
    AttrsForAccessOIDs = [[NSArray alloc]
                                   initWithObjects:
                                   [e attributeNamed:@"key"],
                                   [e attributeNamed:@"namespacePrefix"],
                                   [e attributeNamed:@"accessKey"], nil];
  }
  BEGIN_ADAPTOR_TRANS(adc) {
    int     batchSize, cnt, gidCnt;
    NSArray *currBatch       = nil;
    
    batchSize = 100;
    cnt       = 0;
    gidCnt    = [_gids count];
    tmp       = [[NSMutableArray alloc] initWithCapacity:256];
    
    while (gidCnt > 0) {
      EOSQLQualifier *q;
      
      currBatch = [_gids subarrayWithRange:
                         NSMakeRange(cnt, (gidCnt > batchSize)
                                     ? batchSize : gidCnt)];
      gidCnt    = gidCnt - batchSize;
      cnt      += batchSize;
      q         = [[EOSQLQualifier alloc]
                                   initWithEntity:e
                                   qualifierFormat:@"objectId in (%@)",
                                   [self _qualifierInStringForGIDs:currBatch]];
      [adc selectAttributes:AttrsForAccessOIDs
           describedByQualifier:q
           fetchOrder:nil
           lock:NO];

      ASSIGN(q, nil);

      while ((fetch = [adc fetchAttributes:AttrsForAccessOIDs
                           withZone:NULL])) {
        [tmp addObject:fetch];
      }
    }
  }
  CLOSE_ADAPTOR_TRANS(NO);
  props       = [[NSMutableDictionary alloc] init];
  enumerator  = [tmp objectEnumerator];

  if ([tmp count] > 0) {
    NSArray       *keys        = nil;
    NSEnumerator  *keyEnum     = nil;
    id            k            = nil;
    id            *vs          = NULL;
    id            *ks          = NULL;
    int           kCnt         = 0;

    ks      = malloc(sizeof(id) * [tmp count]);
    keyEnum = [tmp objectEnumerator];
    while ((k = [keyEnum nextObject])) {
      id o = nil;

      o = [k valueForKey:@"accessKey"];
      if ([o isNotNull])
        ks[kCnt++] = o;
    }
    keys = [NSArray arrayWithObjects:ks count:kCnt];
    free(ks); ks = NULL;
    if ((kCnt = [keys count]) > 0) {
      [self->typeManager globalIDsForPrimaryKeys:keys]; /* fill cache */
      keyEnum     = [keys objectEnumerator];
      kCnt        = [keys count];
      vs          = malloc(sizeof(id) * kCnt);
      ks          = malloc(sizeof(id) * kCnt);
      kCnt        = 0;
      while ((k = [keyEnum nextObject])) {
        vs[kCnt] = [self->typeManager globalIDForPrimaryKey:k];
        ks[kCnt] = k;
        kCnt++;
      }
      mapAccessIds = [[NSDictionary alloc] initWithObjects:vs forKeys:ks
                                           count:kCnt];
      free(vs); vs = NULL;
      free(ks); ks = NULL;
    }
  }
  
  while ((fetch = [enumerator nextObject])) {
    NSString *k    = nil;
    {
      NSString *nsp = nil;      

      nsp = [fetch objectForKey:@"namespacePrefix"];
      if (![nsp isNotNull])
        nsp = nil;
      else if ([nsp length] == 0)
        nsp = nil;
      
      k = (nsp != nil) 
	? [[[@"{" stringByAppendingString:nsp]
	          stringByAppendingString:@"}"]
	          stringByAppendingString:[fetch objectForKey:@"key"]]
        : [fetch objectForKey:@"key"];
    }
    {
      EOKeyGlobalID    *kgid = nil;
      NGMutableHashMap *map  = nil;
      id               aid   = nil;

      kgid = [mapOIDsWithGIDs objectForKey:[fetch objectForKey:@"objectId"]];

      if (kgid == nil) {
        NSLog(@"WARNING: missing globalID for fetch %@ mapOIDsWithGIDs %@",
              fetch, mapOIDsWithGIDs);
        continue;
      }
      aid = [mapAccessIds objectForKey:[fetch objectForKey:@"accessKey"]];
      if ((map = [props objectForKey:kgid]) == nil) {
        map = [NGMutableHashMap hashMapWithCapacity:64];
        [props setObject:map forKey:kgid];
      }
      if ((aid = [mapAccessIds objectForKey:[fetch objectForKey:@"accessKey"]])
          != nil) {
        [map addObject:k forKey:aid];
      }
    }
  }
  [tmp release]; tmp = nil;
  {
    id tmp = props;
    props = [props copy];
    [tmp release]; tmp = nil;
  }
  [mapAccessIds release];    mapAccessIds    = nil;
  return [props autorelease];
}

- (void)_postChangeNotificationForGID:(EOGlobalID *)_gid {
  NSNotificationCenter *nc = nil;

  nc = [NSNotificationCenter defaultCenter];

  [nc postNotificationName:[self modifyPropertiesForGIDNotificationName]
      object:_gid];  
}

- (NSString *)nextIdentifier {
  self->identCount++;
  return [NSString stringWithFormat:@"tp%d.", self->identCount];
}

- (NSString *)value:(id)_value forAttr:(EOAttribute *)_attr {
  if (self->adaptor == nil) {
    self->adaptor = [self->database adaptor];
    RETAIN(self->adaptor);
  }
  return [self->adaptor formatValue:_value forAttribute:_attr];
}

- (NSDictionary *)mapOIDsWithGIDs:(NSArray *)_gids {
  id            *oids, *gids;
  int           cnt;
  NSEnumerator  *gidEnum;
  EOKeyGlobalID *kgid;
  NSDictionary  *mapOIDsWithGIDs;

  cnt     = [_gids count];
  oids    = calloc(cnt + 1, sizeof(id));
  gids    = calloc(cnt + 1, sizeof(id));
  cnt     = 0;
    
  gidEnum = [_gids objectEnumerator];
  while ((kgid = [gidEnum nextObject])) {
    oids[cnt] = [kgid keyValues][0];
    gids[cnt] = kgid;
    cnt++;
  }
  mapOIDsWithGIDs = [NSDictionary dictionaryWithObjects:gids forKeys:oids
                                  count:cnt];
  free(oids); oids = NULL;
  free(gids); gids = NULL;

  return mapOIDsWithGIDs;
}

@end /* SkyObjectPropertyManager(Internals) */
