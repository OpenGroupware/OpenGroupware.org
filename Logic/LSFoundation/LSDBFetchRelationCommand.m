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

#include "LSDBFetchRelationCommand.h"
#include "common.h"
#include <GDLAccess/EOSQLQualifier.h>

@implementation LSDBFetchRelationCommand

static int RelMaxSearchCount = 0;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  RelMaxSearchCount = 
    [ud integerForKey:@"LSDBFetchRelationCommand_MAX_SEARCH_COUNT"];
  if (RelMaxSearchCount < 5)
    RelMaxSearchCount = 200;
}

- (id)initForOperation:(NSString *)_operation inDomain:(NSString *)_domain
  initDictionary:(NSDictionary *)_init
{
  self = [super initForOperation:_operation inDomain:_domain
		initDictionary:_init];
  if (self) {
    self->sourceKey      = [[_init objectForKey:@"sourceKey"] copy];
    self->destinationKey = [[_init objectForKey:@"destinationKey"] copy];
    self->isToMany       = [[_init objectForKey:@"isToMany"] boolValue];
    self->destinationEntityName =
      [[_init objectForKey:@"destinationEntityName"] copy];
  }
  return self;
}

- (void)dealloc {
  [self->currentIds            release];
  [self->relationKey           release];
  [self->sourceKey             release];
  [self->destinationKey        release];
  [self->destinationEntityName release];
  [super dealloc];
}

/* accessors */

- (void)setCurrentIds:(NSArray *)_ids {
  ASSIGN(self->currentIds, _ids);
}
- (NSArray *)currentIds {
  return self->currentIds;
}

/* command methods */

- (NSArray *)_ids {
  NSMutableSet *idSet;
  NSEnumerator *listEnum;
  NSString     *srcKey, *relKey;
  BOOL         isMany;
  id           item;

  idSet    = [NSMutableSet set];
  listEnum = [[self object] objectEnumerator];
  srcKey   = [self sourceKey];
  relKey   = [self relationKey];
  isMany   = [self isToMany];

  while ((item = [listEnum nextObject])) {
    NSNumber *pKey;
    
    pKey = [item valueForKey:srcKey];
    
    if (pKey == nil || ![pKey isNotNull])
      continue;
    
    if (isMany && (relKey != nil)) {
      NSMutableArray *ma;

      ma = [[NSMutableArray alloc] initWithCapacity:8];
      [item takeValue:ma forKey:relKey];
      [ma release];
    }
    
    [idSet addObject:pKey];
  }
  return [idSet allObjects];
}

- (id)_findObjectWithId:(id)_objId {
  NSEnumerator *listEnum;
  NSString     *srcKey;
  id           item;
  
  listEnum = [[self object] objectEnumerator];
  srcKey   = [self sourceKey];
  
  while ((item = [listEnum nextObject])) {
    NSNumber *pKey;
    
    pKey = [item valueForKey:srcKey];
    if ([pKey isEqual:_objId])
      return item;
  }
  return nil;
}

- (EOSQLQualifier *)_qualifier {
  EOSQLQualifier *qualifier;
  NSString       *in;
  
  in        = [self->currentIds componentsJoinedByString:@","];
  qualifier = [EOSQLQualifier alloc];
  
  if ([in length] > 0) {
    qualifier = [qualifier initWithEntity:[self destinationEntity]
                           qualifierFormat:@"%A IN (%@)",
                           [self destinationKey], in];
  }
  else {
    qualifier = [qualifier initWithEntity:[self destinationEntity]
                           qualifierFormat:@"1=0"];
  }
  [qualifier setUsesDistinct:YES];
  return [qualifier autorelease];  
}

- (NSArray *)_fetchRelations {
  // TODO: split up method
  NSZone              *z;
  EODatabaseChannel   *channel;
  NSArray             *allIds;
  int                 allIdsCount;
  NSTimeInterval      st;

  st          = [[NSDate date] timeIntervalSince1970];
  z           = [self zone];
  channel     = [self databaseChannel];
  allIds      = [self _ids];
  allIdsCount = [allIds count];
  
  if (allIdsCount == 0)
    return [NSArray array];
  
  {
    NSMutableDictionary *objDict;
    NSMutableArray      *allRelObjects;
    NSString            *srcKey, *destKey, *relKey;
    BOOL                isMany;
    int                 maxSet, cnt;
    
    objDict = nil;
    maxSet  = RelMaxSearchCount;
    srcKey  = [self sourceKey];
    destKey = [self destinationKey];
    relKey  = [self relationKey];
    isMany  = [self isToMany];
    
    if (isMany && (relKey != nil)) {
      NSArray  *objs;
      unsigned i, count;

      objs    = [self object];
      count   = [objs count];
      objDict = [NSMutableDictionary dictionaryWithCapacity:count];
      
      /* fill dict (map objects to pkeys) */
      for (i = 0; i < count; i++) {
        id o;
        id pkey;

        o    = [objs objectAtIndex:i];
        pkey = [o valueForKey:srcKey];
        
        if (pkey == nil)
          pkey = [NSNull null];
        
        [objDict setObject:o forKey:pkey];
      }
    }
    allRelObjects = [NSMutableArray arrayWithCapacity:512];

    cnt = 0;
    while (cnt < allIdsCount) {
      id  relObj, fKey;
      int step;
      
      step = (allIdsCount-cnt > maxSet) ? maxSet : allIdsCount-cnt;

      ASSIGN(self->currentIds,
             [allIds subarrayWithRange:NSMakeRange(cnt, step)]);
      
      [self assert:[channel selectObjectsDescribedByQualifier:[self _qualifier]
                            fetchOrder:nil]];

      if (isMany && (relKey != nil)) {
        while ((relObj = [channel fetchWithZone:z])) {
          id obj;
          
          fKey = [relObj  valueForKey:destKey];
          obj  = [objDict objectForKey:fKey];
          
          if (obj == nil) {
            /* shouldn't happen anymore */
            obj = [self _findObjectWithId:fKey];
            if (obj != nil)
              [objDict setObject:obj forKey:[obj valueForKey:srcKey]];
          }
          if (obj != nil)
            [[obj valueForKey:relKey] addObject:relObj];
          
          [allRelObjects addObject:relObj];
        }
      }
      else {
        while ((relObj = [channel fetchWithZone:z]))
          [allRelObjects addObject:relObj];
      }
      cnt += step;
    }
    return allRelObjects;
  }
}

- (void)_executeInContext:(id)_context {
  NSString          *relKey;
  NSArray           *rels;
  NSAutoreleasePool *pool;

  pool   = [[NSAutoreleasePool alloc] init];
  relKey = [self relationKey];
  rels   = [self _fetchRelations];
  
  // TODO: move section to an own method
  if (![self isToMany] && (relKey != nil)) {
    NSString *srcKey, *destKey, *relKey;
    NSArray  *objs;
    int      i, cnt;
    
    srcKey  = [self sourceKey];
    destKey = [self destinationKey];
    relKey  = [self relationKey];
    objs    = [self object];
    
    for (i = 0, cnt = [objs count]; i < cnt; i++) {
      id  obj, pKey;
      int j, cnt2;

      obj  = [objs objectAtIndex:i];
      pKey = [obj valueForKey:srcKey];
      
      for (j = 0, cnt2 = [rels count]; j < cnt2; j++) {
	NSNumber *fKey;
        id       relObj;
        
        relObj = [rels objectAtIndex:j];
        fKey   = [relObj valueForKey:destKey];
        
        if (![pKey isEqual:fKey])
	  continue;
	
	[obj takeValue:relObj forKey:relKey];
      }
    }
  }
  if (relKey == nil)
    [self setReturnValue:rels];
  
  [pool release]; pool = nil;
}

// accessors

- (void)setRelationKey:(NSString *)_key {
  ASSIGN(self->relationKey, _key);
}
- (NSString *)relationKey {
  return self->relationKey;
}

- (void)setDestinationEntityName:(NSString *)_entityName {
  ASSIGN(self->destinationEntityName, _entityName);
}
- (NSString *)destinationEntityName {
  return self->destinationEntityName;
}
- (EOEntity *)destinationEntity {
  return [[self databaseModel] entityNamed:[self destinationEntityName]];
}

- (void)setIsToMany:(BOOL)_isToMany {
  self->isToMany = _isToMany; 
}
- (BOOL)isToMany {
  return self->isToMany; 
}

- (void)setSourceKey:(NSString *)_key {
  ASSIGN(self->sourceKey, _key);
}
- (NSString *)sourceKey {
  return self->sourceKey;
}

- (void)setDestinationKey:(NSString *)_key {
  ASSIGN(self->destinationKey, _key);
}
- (NSString *)destinationKey {
  return self->destinationKey;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"objects"]) {
    NSArray *array;

    if ([_value isKindOfClass:[NSArray class]])
      array = _value;
    else if ([_value isNotNull])
      array = [NSArray arrayWithObject:_value];
    else
      array = nil;
    
    [self setObject:array];
  }
  else if ([_key isEqualToString:@"object"])
    [self setObject:[NSArray arrayWithObject:_value]];
  else if ([_key isEqualToString:@"relationKey"]) 
    [self setRelationKey:_value];
  else if ([_key isEqualToString:@"destinationEntityName"])
    [self setDestinationEntityName:_value];
  else if ([_key isEqualToString:@"sourceKey"])
    [self setSourceKey:_value];
  else if ([_key isEqualToString:@"destinationKey"])
    [self setDestinationKey:_value];
  else if ([_key isEqualToString:@"isToMany"])
    [self setIsToMany:[_value boolValue]];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"objects"])
    return [self object];
  if ([_key isEqualToString:@"object"])
    return [[self object] lastObject];
  if ([_key isEqualToString:@"relationKey"])
    return [self relationKey];
  if ([_key isEqualToString:@"destinationEntityName"])
    return [self destinationEntityName];
  if ([_key isEqualToString:@"sourceKey"])
    return [self sourceKey];
  if ([_key isEqualToString:@"destinationKey"])
    return [self destinationKey];
  if ([_key isEqualToString:@"isToMany"])
    return [NSNumber numberWithBool:[self isToMany]];
  
  return [super valueForKey:_key];
}

@end /* LSDBFetchRelationCommand */
