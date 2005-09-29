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

#include "SkyAttributeDataSource.h"
#include <LSFoundation/LSFoundation.h>
#include "common.h"

@interface NSObject(Private)
- (EOGlobalID *)globalID;
@end

@interface SkyAttributeDataSource(Internals)
- (BOOL)_hasOnlyDBKeys:(EOQualifier *)_qual;
- (BOOL)_hasOnlyAttrKeys:(EOQualifier *)_qual;
- (BOOL)_hasAttributeKey:(EOQualifier *)_qual;
- (NSSet *)_getGidsFromArray:(NSArray *)_array objectsAreDics:(BOOL)_isDict;
- (NSSet *)_handleQualifier:(EOQualifier *)_qual;
- (NSSet *)_evaluateQualifier:(EOQualifier *)_qual;
- (EOGlobalID *)_gidForObj:(id)_obj;
- (NSArray *)_buildObjects:(NSArray *)_gids;
- (void)_freeCaches;
@end /* SkyAttributeDataSource(Internals) */

@implementation SkyAttributeDataSource(Internals)

static NSString *pkeyFetchHintName = @"fetch_primary_key_qualifier";

static inline BOOL _keyHasNamespace(SkyAttributeDataSource *self,
                                    NSString *_str)
{
  if ([_str length] > 1) {
    if ([_str characterAtIndex:0] == '{' &&
        [_str rangeOfString:@"}"].length > 0)
      return YES;
  }
  if (self->dbKeys != nil) {
    if (![self->dbKeys containsObject:_str])
      return YES;
  }
  return NO;
}

- (BOOL)_hasOnlyDBKeys:(EOQualifier *)_qual {
  NSEnumerator *enumerator = nil;
  id           key         = nil;
  
  enumerator = [[_qual allQualifierKeys] objectEnumerator];
  while ((key = [enumerator nextObject])) {
    if (_keyHasNamespace(self, key))
      return NO;
  }
  return YES;
}

- (BOOL)_hasOnlyAttrKeys:(EOQualifier *)_qual {
  NSEnumerator *enumerator = nil;
  id           key         = nil;
  
  enumerator = [[_qual allQualifierKeys] objectEnumerator];
  while ((key = [enumerator nextObject])) {
    if (!_keyHasNamespace(self, key))
      return NO;
  }
  return YES;
}

- (BOOL)_hasAttributeKey:(EOQualifier *)_qual {
  NSEnumerator *enumerator = nil;
  id           key         = nil;
  
  enumerator = [[_qual allQualifierKeys] objectEnumerator];
  while ((key = [enumerator nextObject])) {
    if (_keyHasNamespace(self, key))
      return YES;
  }
  return NO;
}

/*
  dictionary with gid`s -> objects
*/

- (NSSet *)_getGidsFromArray:(NSArray *)_array objectsAreDics:(BOOL)_isDict {
  NSEnumerator *enumerator = nil;
  id           *objs       = NULL;
  int          objCnt      = 0;
  NSSet        *res        = nil;
  id           obj         = nil;
          
  if (self->_gid2ObjCache == nil) {
    self->_gid2ObjCache = [[NSMutableDictionary alloc] initWithCapacity:64];
  }
  objCnt     = [_array count];
  objs       = calloc(objCnt + 1, sizeof(id));
  enumerator = [_array objectEnumerator];
  objCnt     = 0;
  while ((obj = [enumerator nextObject])) {
    if (_isDict)
      objs[objCnt] = [obj valueForKey:@"globalID"];
    else
      objs[objCnt] = [obj globalID];
    [self->_gid2ObjCache setObject:obj forKey:objs[objCnt]];
    objCnt++;
  }
  res = [NSSet setWithObjects:objs count:objCnt];
  free(objs); objs = NULL;
  return res;
}

/*
  - returns only gids, build keys->objects dictionary
*/

- (NSSet *)_evaluateAttributeQualifier:(EOQualifier *)_qual {
  SkyObjectPropertyManager *objPropMan = nil;
  NSString                 *oldNS      = nil;
  NSArray                  *objects    = nil;
  NSSet                    *result     = nil;
  NSDictionary             *fetchHints = nil;

  if (self->_evaluateAttributeQualifierCache == nil) {
    self->_evaluateAttributeQualifierCache =
      [[NSMutableDictionary alloc] initWithCapacity:8];
  }
  else {
    NSSet *set = nil;
    if ((set = [self->_evaluateAttributeQualifierCache objectForKey:_qual]))
      return set;
  }
  
  objPropMan = [self->context propertyManager];
  oldNS      = [objPropMan defaultNamespace];
  
  [objPropMan setDefaultNamespace:self->defaultNamespace];

  if ((fetchHints = [self->fetchSpecification hints])) {
    id tmp = nil;

    if ((tmp = [fetchHints objectForKey:@"restrictionQualifierString"])) {
      [objPropMan setRestrictionQualifierString:tmp];
    }
    if ((tmp = [fetchHints objectForKey:@"restrictionEntityName"])) {
      [objPropMan setRestrictionEntityName:tmp];
    }
  }
  objects = [objPropMan globalIDsForQualifier:_qual
                        entityName:[self->fetchSpecification entityName]];
  
  [objPropMan setRestrictionEntityName:nil];
  [objPropMan setRestrictionQualifierString:nil];
  
  [objPropMan setDefaultNamespace:oldNS];
  
  if (self->verifyIds) {
    objects = [self _buildObjects:(id)objects];
    result = [self _getGidsFromArray:objects objectsAreDics:YES];
  }
  else
    result = [NSSet setWithArray:objects];

  [self->_evaluateAttributeQualifierCache setObject:result forKey:_qual];
  
  return result;
}
- (NSSet *)_evaluateAttributeQualifiers:(NSArray *)_quals
  qualifierClass:(Class)_class
{
  unsigned count;
  
  if ((count = [_quals count]) == 0)
    return nil;
  else if (count == 1)
    return [self _evaluateAttributeQualifier:[_quals objectAtIndex:0]];
  else {
    EOQualifier *sq;
    sq = [[[_class alloc] initWithQualifierArray:_quals] autorelease];
    return [self _evaluateAttributeQualifier:sq];
  }
}

- (NSSet *)_evaluateDBQualifier:(EOQualifier *)_qual {
  EOFetchSpecification *fSpec   = nil;
  NSArray              *objects = nil;
  NSSet                *result  = nil;

  if (self->_evaluateDBQualifierCache == nil) {
    self->_evaluateDBQualifierCache =
      [[NSMutableDictionary alloc] initWithCapacity:8];
  }
  else {
    NSSet *set = nil;
    if ((set = [self->_evaluateDBQualifierCache objectForKey:_qual]))
      if (![set isNotNull])
        set = nil;
      return set;
  }
  /* create fetchspecification */
  
  fSpec = [[EOFetchSpecification alloc]
                                 initWithEntityName:
                                   [self->fetchSpecification entityName]
                                 qualifier:_qual
                                 sortOrderings:
                                   [self->fetchSpecification sortOrderings]
                                 usesDistinct:NO isDeep:NO hints:nil];
  [self->source setFetchSpecification:fSpec];
  [fSpec release]; fSpec = nil;
  
  /* fetch objects */
  
  objects = [self->source fetchObjects];
  
  if ([objects count] > 0) {
    id obj = nil;
    
    obj = [objects lastObject];
    NSAssert1(obj, @"missing object in fetch result: %@", objects);
    
    if ([obj isKindOfClass:[NSDictionary class]]) {
      result = [self _getGidsFromArray:objects objectsAreDics:YES];
    }
    else if ([obj isKindOfClass:[EOGenericRecord class]]) {
      result = [self _getGidsFromArray:objects objectsAreDics:NO];
    }
    else if ([obj isKindOfClass:[EOGlobalID class]]) {
      result = obj;
    }
    else {
      [self warnWithFormat:
              @"%s: Unknown result class for"
              @" SkyAttributeDataSource obj[%@] %@", __PRETTY_FUNCTION__,
              NSStringFromClass([obj class]), obj];
    }
  }
  [fSpec release];

  if (!result)
    result = (id)[NSNull null];
  
  [self->_evaluateDBQualifierCache setObject:result forKey:_qual];
  
  return result;
}
- (NSSet *)_evaluateDBQualifiers:(NSArray *)_quals
  qualifierClass:(Class)_class
{
  unsigned count;
  
  if ((count = [_quals count]) == 0)
    return nil;
  else if (count == 1)
    return [self _evaluateDBQualifier:[_quals objectAtIndex:0]];
  else {
    EOQualifier *sq;
    sq = [[[_class alloc] initWithQualifierArray:_quals] autorelease];
    return [self _evaluateDBQualifier:sq];
  }
}

- (NSSet *)_handleQualifier:(EOQualifier *)_qual {
  NSEnumerator *enumerator = nil;
  id           key         = nil;
  BOOL         hasAttr     = NO;
  BOOL         hasDB       = NO;
  NSSet        *result     = nil;
  
  enumerator = [[_qual allQualifierKeys] objectEnumerator];
  
  while ((key = [enumerator nextObject])) {
    if (!_keyHasNamespace(self, key))
      hasDB = YES;
    else
      hasAttr = YES;
  }
  
  if (hasDB && hasAttr) {
    [self warnWithFormat:
            @"%s: got mixed qualifier %@", __PRETTY_FUNCTION__,_qual];
    return nil;
  }
  else if (hasDB)
    result = [self _evaluateDBQualifier:_qual];
  else if (hasAttr)
    result = [self _evaluateAttributeQualifier:_qual];
  else
    result = nil;
  
  return result;
}

/*
  This method should be named 'splitQualifierAndEvaluate' or sth like this.
  
  - looks for qualifier-handler who could evaluate the qualifier
  - if necessary evaluate qualifier in memory with ids
  - jr!: hh??: NOT constructions which include DBQual _and_ AttributeQual
    couldn`t be evaluate
*/

- (NSSet *)_evaluateAndOrQualifier:(EOQualifier *)_qual
  qualifierClass:(Class)qualClass
{
  /* TODO: split up this HUGE method! */
  NSSet          *result = nil;
  NSMutableArray *attrQuals;
  NSMutableArray *dbQuals;
  NSMutableArray *mixedQuals;
  NSArray      *quals     = nil;
  int          qualCnt    = 0;
  NSSet        *attrIds   = nil;
  NSSet        *dbIds     = nil;
  NSMutableSet *mixedIds  = nil;
  
#if DEBUG
  NSAssert(qualClass, @"missing qualifier class ..");
#endif
  
  quals   = [(EOAndQualifier *)_qual qualifiers];
  qualCnt = [quals count];
  
  if (qualCnt == 0) {
    [self warnWithFormat:@"%s: AND/OR qualifier without subqualifiers !",
          __PRETTY_FUNCTION__];
    return [NSSet set];
  }

  attrQuals  = [NSMutableArray arrayWithCapacity:qualCnt];
  dbQuals    = [NSMutableArray arrayWithCapacity:qualCnt];
  mixedQuals = [NSMutableArray arrayWithCapacity:qualCnt];
  
  /* categorize qualifiers */
  {
    NSEnumerator *qualEnum;
    EOQualifier  *qual;
    
    qualEnum = [quals objectEnumerator];
    
    while ((qual = [qualEnum nextObject])) {
      if ([self _hasOnlyAttrKeys:qual])
        [attrQuals addObject:qual];
      else if ([self _hasOnlyDBKeys:qual])
        [dbQuals addObject:qual];
      else
        [mixedQuals addObject:qual];
    }
  }
  
  /* process extended attribute qualifier */
  attrIds = [self _evaluateAttributeQualifiers:attrQuals
                  qualifierClass:qualClass];
  
  /* process database qualifiers */
  dbIds = [self _evaluateDBQualifiers:dbQuals qualifierClass:qualClass];
  
  /* process mixed qualifiers */
  
  if ([mixedQuals count] > 0) {
    int i = 0, count;
      
    mixedIds = [NSMutableSet set];
      
    for (i = 0, count = [mixedQuals count]; i < count; i++) {
      NSSet       *mix;
      EOQualifier *mixQ;
      
      mixQ = [mixedQuals objectAtIndex:i];
      mix  = [self _evaluateQualifier:mixQ];
      
#if DEBUG
      NSAssert1(![mixQ isEqual:_qual],
                @"qualifier evaluation cycle (mix) (qualifier %@)",
                _qual);
#endif
      
      [mixedIds unionSet:mix];
    }
  }

  /* collect results */
  
  {
    NSMutableSet *objs;
    id  obj    = nil;
    int dCnt = 0, aCnt = 0, mCnt = 0;

    objs = nil;
    dCnt = [dbIds    count];
    aCnt = [attrIds  count];
    mCnt = [mixedIds count];
    
    if ([_qual isKindOfClass:[EOAndQualifier class]]) {
      NSEnumerator *enumerator = nil;
      NSSet        *compSet[3];
      int          minCnt      = 0;
      int          setCnt      = 0;

#if 0      
      if ([attrQuals count] > 0) {
        minCnt = [attrQuals count];
        compSet[setCnt] = attrIds;
        setCnt++;
      }
      if ([mixedQuals count] > 0) {
        compSet[setCnt] = mixedIds;
        setCnt++;
        minCnt = (minCnt > [mixedQuals count])
          ? [mixedQuals count]
          : minCnt;
      }
      if ([dbQuals count] > 0) {
        compSet[setCnt] = dbIds;
        setCnt++;
        minCnt = (minCnt > [dbQuals count])
          ? [dbQuals count]
          : minCnt;
      }
#else
      if (aCnt > 0) {
        minCnt = aCnt;
        compSet[setCnt] = attrIds;
        setCnt++;
      }
      if (mCnt > 0) {
        compSet[setCnt] = mixedIds;
        setCnt++;
        minCnt = (minCnt > mCnt)
          ? mCnt
          : minCnt;
      }
      if (dCnt > 0) {
        compSet[setCnt] = dbIds;
        setCnt++;
        minCnt = (minCnt > dCnt)
          ? dCnt
          : minCnt;
      }
#endif
      if (minCnt > 0) {
        objs = [NSMutableSet setWithCapacity:minCnt];
        
        if (setCnt == 1) {
          enumerator = [compSet[0] objectEnumerator];
          while ((obj = [enumerator nextObject])) {
            [objs addObject:obj];
          }
        }
        else if (setCnt == 2) {
          int comp = 0;

          if ([compSet[0] count] > [compSet[1] count]) {
            enumerator = [compSet[1] objectEnumerator];
            comp       = 0;
          }
          else {
            enumerator = [compSet[0] objectEnumerator];
            comp       = 1;
          }
          while ((obj = [enumerator nextObject])) {
            if ([compSet[comp] containsObject:obj])
              [objs addObject:obj];
          }
        }
        else {
          id    *tmpObj = NULL;
          int   tmpCnt  = 0;
          NSSet *tmpSet = nil;
          NSSet *compar = nil;
            
          tmpObj = calloc(minCnt + 1, sizeof(id));
            
          if ([compSet[0] count] > [compSet[1] count]) {
            enumerator = [compSet[1] objectEnumerator];
            compar     = compSet[0];
          }
          else {
            enumerator = [compSet[0] objectEnumerator];
            compar     = compSet[1];
          }
          while ((obj = [enumerator nextObject])) {
            if ([compar containsObject:obj]) {
              tmpObj[tmpCnt++] = obj;
            }
          }
          tmpSet = [NSSet setWithObjects:tmpObj count:tmpCnt];
          if ([compSet[2] count] > [tmpSet count]) {
            enumerator = [tmpSet objectEnumerator];
            compar     = compSet[2];
          }
          else {
            enumerator = [compSet[2] objectEnumerator];
            compar     = tmpSet;
          }
          while ((obj = [enumerator nextObject])) {
            if ([compar containsObject:obj])
              [objs addObject:obj];
          }
          if (tmpObj) free(tmpObj);
          tmpObj = NULL;
        }
      }
    }
    else { /* !isAndQual */
      NSEnumerator *enumerator = nil;

      objs = [NSMutableSet setWithCapacity:(dCnt + aCnt + mCnt)];
      
      enumerator = [attrIds objectEnumerator];
      while ((obj = [enumerator nextObject]))
        [objs addObject:obj];
      
      enumerator = [dbIds objectEnumerator];
      while ((obj = [enumerator nextObject]))
        [objs addObject:obj];
      
      enumerator = [mixedIds objectEnumerator];
      while ((obj = [enumerator nextObject]))
        [objs addObject:obj];
    }

    result = [[objs copy] autorelease];
  }
  
  return result;
}

- (NSSet *)_evaluateQualifier:(EOQualifier *)_qual {
  NSSet *result   = nil;
  BOOL  isOrQual  = NO;
  BOOL  isAndQual = NO;
  
  if (_qual == nil)
    return nil;
  
  if (self->_evaluateQualifierCache == nil) {
    self->_evaluateQualifierCache =
      [[NSMutableDictionary alloc] initWithCapacity:8];
  }
  else {
    NSSet *set = nil;
    
    if ((set = [self->_evaluateQualifierCache objectForKey:_qual]))
      return set;
  }
  
  /* check qualifier type */
  
  if ([_qual isKindOfClass:[EOAndQualifier class]]) {
    isAndQual = YES;
  }
  else if ([_qual isKindOfClass:[EOOrQualifier class]]) {
    isOrQual = YES;
  }
  else {
    /* neither AND nor OR qualifier */
    
    result = [self _handleQualifier:_qual];
    if (result != nil && _qual != nil)
      [self->_evaluateQualifierCache setObject:result forKey:_qual];
    return result;
  }
  
  /* continue processing of AND and OR qualifiers */

  result = [self _evaluateAndOrQualifier:_qual
                 qualifierClass:(isAndQual)
                   ? [EOAndQualifier class]
                   : [EOOrQualifier class]];
  
  if (result)
    [self->_evaluateQualifierCache setObject:result forKey:_qual];
  
  return result;
}

- (EOGlobalID *)_gidForObj:(id)_obj {
  if ([_obj isKindOfClass:[NSDictionary class]])
    return [_obj valueForKey:@"globalID"];
  
  if ([_obj isKindOfClass:[EOGenericRecord class]])
    return [_obj globalID];

  if ([_obj isKindOfClass:[EOGlobalID class]])
    return _obj;
  
  [self warnWithFormat:@"%s: could not determine global id for obj[%@] %@",
        __PRETTY_FUNCTION__, NSStringFromClass([_obj class]), _obj];
  return _obj;
}

- (NSArray *)_buildObjects:(NSArray *)_gids {
  id             *allObjs       = NULL;
  int            allObjsCnt     = 0;
  id             *toFetchGIDs   = NULL;
  int            toFetchGIDsCnt = 0;
  int            cnt            = 0;
  NSSet          *set           = nil;
  NSEnumerator   *enumerator    = nil;
  id             gid            = nil;
  NSMutableArray *result        = nil;

  set = [NSSet setWithArray:_gids];
  cnt = [set count];
  
  if (cnt == [self->_gid2ObjCache count])
    return [self->_gid2ObjCache allValues];

  allObjs     = calloc(cnt + 3, sizeof(id));
  toFetchGIDs = calloc(cnt + 3, sizeof(id));  
  enumerator  = [set objectEnumerator];

  while ((gid = [enumerator nextObject])) {
    id obj = nil;
    
    if ((obj = [self->_gid2ObjCache objectForKey:gid]) != nil)
      allObjs[allObjsCnt++] = obj;
    else
      toFetchGIDs[toFetchGIDsCnt++] = gid;
  }
  result = [NSMutableArray arrayWithObjects:allObjs count:allObjsCnt];

  if (toFetchGIDsCnt > 0) {
    EOQualifier *qual      = nil;
    int         batchSize  = 100;
    int         cnt        = 0;
    int         gidCnt     = 0;
    id          *kvQuals   = NULL;
    int         kvQualsCnt = 0;
    NSString    *keyName   = 0;
    SEL         opSel      = NULL;

    keyName = [self globalIDKey];
    gidCnt  = toFetchGIDsCnt;
    kvQuals = calloc(batchSize + 1, sizeof(id));
    opSel   = [EOQualifier operatorSelectorForString:@"="];
    
    while (gidCnt > 0) {
      int nextBatch = 0;
      id tmp;
      
      nextBatch = (gidCnt > batchSize) ? batchSize : gidCnt;

      for (kvQualsCnt = 0; kvQualsCnt < nextBatch; kvQualsCnt++) {
        kvQuals[kvQualsCnt] =
          [[EOKeyValueQualifier alloc]
                                initWithKey:keyName operatorSelector:opSel
                                value:[toFetchGIDs[cnt++] keyValues][0]];
        [kvQuals[kvQualsCnt] autorelease];
      }
      
      gidCnt  = gidCnt - batchSize;
      tmp     = [[NSArray alloc] initWithObjects:kvQuals count:kvQualsCnt];
      qual    = [[EOOrQualifier alloc] initWithQualifierArray:tmp];
      [tmp release];
      
      {
        EOFetchSpecification *fSpec   = nil;
        NSArray              *addObjs = nil;
        NSDictionary         *hints   = nil;
        
        hints = [[NSDictionary alloc] initWithObjects:&qual
                                      forKeys:&pkeyFetchHintName
                                      count:1];
        fSpec = [[EOFetchSpecification alloc] init];
        [fSpec setHints:hints];
        [hints release];
        [self->source setFetchSpecification:fSpec];
        
        addObjs = [self->source fetchObjects];
        [result addObjectsFromArray:addObjs];
        
        [fSpec release]; fSpec = nil;
      }
      [qual release]; qual = nil;
    }
    if (kvQuals) free(kvQuals); kvQuals = NULL;
  }
  
  if (toFetchGIDs) free(toFetchGIDs); toFetchGIDs = NULL;
  if (allObjs)     free(allObjs);     allObjs     = NULL;
  
  return result;
}

- (void)_freeCaches {
  [self->_evaluateQualifierCache          removeAllObjects];
  [self->_evaluateDBQualifierCache        removeAllObjects];
  [self->_evaluateAttributeQualifierCache removeAllObjects];
}

@end /* SkyAttributeDataSource+Internals */
