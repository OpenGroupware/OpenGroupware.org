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

#include "LSGenericSearchRecord.h"
#include "LSExtendedSearch.h"
#include "LSExtendedSearchCommand.h"
#include "LSSearchCommands.h"
#include "common.h"
#include <EOControl/EOControl.h>

@interface LSExtendedSearchCommand(PrivateMethodes)
- (NSNumber *)maxSearchCount;
- (NSArray *)_fetchObjects:(id)_context;
- (NSArray *)_fetchIds:(id)_context;
- (void)setFetchIds:(NSNumber *)_number;
- (NSNumber *)fetchIds;
- (BOOL)fetchGlobalIDs;
- (EOSQLQualifier *)_buildQualifierWithContext:(id)_context;
@end

@implementation LSExtendedSearchCommand

+ (int)version {
  return [super version] + 1; /* v2 */
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->searchKeys);
  RELEASE(self->searchRecordList);
  RELEASE(self->extendedSearch);
  RELEASE(self->operator);
  RELEASE(self->maxSearchCount);
  [super dealloc];
}
#endif

// command methods

- (void)_validateKeysForContext:(id)_context {
}

- (void)_prepareForExecutionInContext:(id)_context {
  NSMutableArray *relatedRecords = nil;
  NSEnumerator   *listEnum       = nil;
  id             record          = nil;
  id             searchRecord    = nil;

  relatedRecords = [[NSMutableArray allocWithZone:[self zone]] init];

  if (self->searchKeys != nil) { // use parameter keys
    searchRecord = [[LSGenericSearchRecord allocWithZone:[self zone]]
                                           initWithEntity:[self entity]];
    [searchRecord takeValuesFromDictionary:self->searchKeys];
  }
  else { // search primary prototype record
    NSString *ename = [self entityName];
    
    listEnum = [self->searchRecordList objectEnumerator];

    while((record = [listEnum nextObject])) {
      if ([ename isEqualToString:[[record entity] name]]) {
        searchRecord = record;
        RETAIN(searchRecord);
        break;
      }
    }
  }
  if (searchRecord != nil) {
    RELEASE(self->extendedSearch); self->extendedSearch = nil;
    self->extendedSearch = [[LSExtendedSearch allocWithZone:[self zone]] init];

    [relatedRecords addObjectsFromArray:self->searchRecordList];
    [relatedRecords removeObject:searchRecord];

    if (self->operator) [self->extendedSearch setOperator:self->operator];
    [self->extendedSearch setSearchRecord:searchRecord];
    [self->extendedSearch setRelatedRecords:relatedRecords];
    [self->extendedSearch setDbAdaptor:[self databaseAdaptor]];
  }
  RELEASE(searchRecord);   searchRecord   = nil;
  RELEASE(relatedRecords); relatedRecords = nil;
}

- (EOSQLQualifier *)extendedSearchQualifier:(void *)_context {
  return [self->extendedSearch qualifier];
}

- (NSArray *)_fetchObjects:(id)_context {
  int maxSearch = 0;
  int cnt       = 0;
  id  result    = nil;
  IMP fetch     = NULL;
  IMP addObj    = NULL;

  EOSQLQualifier    *qualifier = nil;
  NSMutableArray    *results   = nil;
  EODatabaseChannel *channel   = [self databaseChannel];

  if ([self maxSearchCount] != nil) {
    maxSearch = [[self maxSearchCount] intValue];
  }
  else {
    maxSearch =
      [[[_context userDefaults] objectForKey:@"LSMaxSearchCount"] intValue];
  }

  qualifier = [self _buildQualifierWithContext:_context];
  
  results   = [NSMutableArray arrayWithCapacity:(maxSearch > 0) ? maxSearch
                                                                : 512];

  [self assert:[channel selectObjectsDescribedByQualifier:qualifier
                        fetchOrder:nil]];

  fetch  = [channel methodForSelector:@selector(fetchWithZone:)];
  addObj = [results methodForSelector:@selector(addObject:)];
  
  while (((maxSearch == 0 ) || (cnt < maxSearch)) &&
         (result = fetch(channel, @selector(fetchWithZone:), nil))) {
      
    addObj(results, @selector(addObject:), result);
    cnt = [results count];
    if ((maxSearch != 0) && (cnt == maxSearch)) {
      [[self databaseChannel] cancelFetch];
    }
    result = nil;
  }
  return results;
}

- (NSArray *)_fetchIds:(id)_context {
  int maxSearch = 0;
  int cnt       = 0;
  BOOL fetchGids;
  EOSQLQualifier   *qualifier  = nil;
  NSMutableArray   *results    = nil;
  EOAdaptorChannel *channel    = nil;
  NSArray          *attributes = nil;
  EOEntity         *entity     = nil;
  
  channel    = [[self databaseChannel] adaptorChannel];
  results    = [NSMutableArray arrayWithCapacity:512];
  qualifier  = [self _buildQualifierWithContext:_context];
  entity     = [qualifier entity];
  attributes = [entity primaryKeyAttributes];
  
  [self assert:[channel selectAttributes:attributes
                        describedByQualifier:qualifier
                        fetchOrder:nil lock:YES]];
  
  fetchGids = [self fetchGlobalIDs];

  if ([self maxSearchCount] != nil) {
    maxSearch = [[self maxSearchCount] intValue];
  }
  else {
    maxSearch =
      [[[_context userDefaults] objectForKey:@"LSMaxSearchCount"] intValue];
  }

  while ((maxSearch == 0) || (cnt < maxSearch)) {
    NSDictionary *row;
    
    if ((row = [channel fetchAttributes:attributes withZone:NULL]) == nil)
      break;
    
    if (fetchGids) {
      EOGlobalID *gid;

      gid = [entity globalIDForRow:row];
      [results addObject:gid];
    }
    else {
      NSMutableDictionary *result;
      
      result = [row mutableCopy];
      [result setObject:entity forKey:@"entity"];
      [results addObject:result];
      [result release]; result = nil;
    }
    
    cnt = [results count];
    if ((maxSearch != 0) && (cnt == maxSearch)) {
      [[self databaseChannel] cancelFetch];
      break;
    }
  }
  return results;
}

- (EOSQLQualifier *)_buildQualifierWithContext:(id)_context {
  EOSQLQualifier *qualifier = nil;
  EOEntity       *entity    = nil;

  qualifier = [self extendedSearchQualifier:_context];
  entity    = [qualifier entity];

  if ([entity attributeNamed:@"isPrivate"] &&
      ![[entity name] isEqualToString:@"Person"]) {
    EOSQLQualifier *privQual = nil;
    id             accountId = nil;
    
    accountId = [[_context valueForKey:LSAccountKey] valueForKey:@"companyId"];

    if (accountId == nil)
      accountId = [NSNumber numberWithInt:0];

    privQual  = [[EOSQLQualifier alloc] initWithEntity:entity
                                        qualifierFormat:
                                        @"(isPrivate = 0) OR "
                                        @"(isPrivate is NULL) OR (ownerId = %@)",
                                        accountId];
    [qualifier conjoinWithQualifier:privQual];
    RELEASE(privQual); privQual = nil;
  }
  if ([entity attributeNamed:@"isFake"] != nil) {
    EOSQLQualifier *fakeQual = nil;

    fakeQual  = [[EOSQLQualifier alloc] initWithEntity:entity
                                        qualifierFormat:
                                        @"(isFake = 0) OR "
                                        @"(isFake is NULL)"];
    [qualifier conjoinWithQualifier:fakeQual];
    RELEASE(fakeQual); fakeQual = nil;
  }
  return qualifier;
}


- (void)_executeInContext:(id)_context {
  NSAutoreleasePool *pool;
  NSArray *r;

  pool = [[NSAutoreleasePool alloc] init];

  r = ([[self fetchIds] boolValue])
    ? [self _fetchIds:_context]
    :  [self _fetchObjects:_context];
  
  r = [r copy];
  
  AUTORELEASE(r);
  {
    NSArray *access;

    if ([self fetchGlobalIDs]) {
      access = r;
    }
    else if ([[self fetchIds] boolValue]) { /* got dict with pk and entity */
      NSEnumerator   *enumerator;
      NSDictionary   *obj;
      NSString       *keyName, *en;
      NSMutableArray *a;
      
      enumerator = [r objectEnumerator];
      keyName    = nil;
      en         = nil;      
      a          = [NSMutableArray arrayWithCapacity:[r count]];
      while ((obj = [enumerator nextObject])) {
        id k;
        
        if (keyName == nil) {
          keyName = [(EOAttribute *)[[[obj valueForKey:@"entity"] 
				       primaryKeyAttributes] lastObject] name];
          en = [(EOEntity *)[obj valueForKey:@"entity"] name];
          NSAssert1(keyName, @"missing key name for %@", obj);
        }
        k = [obj objectForKey:keyName];
        [a addObject:[EOKeyGlobalID globalIDWithEntityName:en
                                    keys:&k keyCount:1 zone:NULL]];
      }
      access = a;
    }
    else {
      access = [r map:@selector(valueForKey:) with:@"globalID"];
    }
    access = [[_context accessManager] objects:access forOperation:@"r"];

    if ([self fetchGlobalIDs]) {
      NSMutableArray *a;
      NSEnumerator   *enumerator;
      id             obj;

      a = [NSMutableArray arrayWithCapacity:[access count]];
      enumerator = [r objectEnumerator];
      while ((obj = [enumerator nextObject])) {
        if ([access containsObject:obj])
          [a addObject:obj];
      }
      access = a;
    }
    else if ([[self fetchIds] boolValue]) {
      NSMutableArray *a;
      NSEnumerator   *enumerator;
      NSDictionary   *obj;
      NSString       *keyName, *en;

      a = [NSMutableArray arrayWithCapacity:[access count]];
      enumerator = [r objectEnumerator];
      keyName    = nil;
      en = nil;      
      
      while ((obj = [enumerator nextObject])) {
        id k, o;
        
        if (keyName == nil) {
          keyName = [(EOAttribute *)[[[obj valueForKey:@"entity"] 
				       primaryKeyAttributes] lastObject] name];
          en = [(EOEntity *)[obj valueForKey:@"entity"] name];
          NSAssert(keyName, @"missing key name");
        }
        k = [obj objectForKey:keyName];
        o = [EOKeyGlobalID globalIDWithEntityName:en
                           keys:&k keyCount:1 zone:NULL];
        if ([access containsObject:o])
          [a addObject:obj];
      }
      access = a;
    }
    else {
      NSMutableArray *a;
      NSEnumerator   *enumerator;
      id             obj;

      a = [NSMutableArray arrayWithCapacity:[access count]];
      enumerator = [r objectEnumerator];
      while ((obj = [enumerator nextObject])) {
        if ([access containsObject:[obj valueForKey:@"globalID"]])
          [a addObject:obj];
      }
      access = a;
    }
    r = access;
  }
  [self setReturnValue:r];

  RELEASE(pool);
}

// accessors

- (void)setSearchRecordList:(NSArray *)_searchRecordList {
  ASSIGN(self->searchRecordList, _searchRecordList);
}
- (NSArray *)searchRecordList {
  return self->searchRecordList;
}

- (void)setOperator:(NSString *)_op {
  if (self->operator != _op) {
    RELEASE(self->operator); self->operator = nil;
    self->operator = [_op copyWithZone:[self zone]];
  }
}
- (NSString *)operator {
  return self->operator;
}

- (LSExtendedSearch *)extendedSearch {
  return self->extendedSearch;
}

- (void)setMaxSearchCount:(NSNumber *)_maxSearchCount {
  ASSIGN(self->maxSearchCount, _maxSearchCount);
}
- (NSNumber *)maxSearchCount {
  return self->maxSearchCount;
}

- (void)setFetchGlobalIDs:(BOOL)_flag {
  self->fetchGlobalIDs = _flag;
}
- (BOOL)fetchGlobalIDs {
  return self->fetchGlobalIDs;
}

- (void)setFetchIds:(NSNumber *)_number {
  ASSIGN(self->fetchIds, _number);
}
- (NSNumber *)fetchIds {
  if (self->fetchGlobalIDs)
    return [NSNumber numberWithBool:YES];
  
  return (self->fetchIds != nil)
    ? self->fetchIds
    : [NSNumber numberWithBool:NO];
}

// key/value coding

- (void)takeValue:(id)_value forKey:(id)_key {
  [self assert:(_key != nil)
        reason:@"passed invalid key to -takeValue:forKey: .."];

  if (_value == nil) _value = [EONull null];
  
  if ([_key isEqualToString:@"entity"]) {
    [self setEntityName:[_value stringValue]];
  }
  else if ([_key isEqualToString:@"searchRecords"] ||
           [_key isEqualToString:@"object"]) {
    [self setSearchRecordList:_value];
  }
  else if ([_key isEqualToString:@"operator"]) {
    [self setOperator:[_value stringValue]];
  }
  else if ([_key isEqualToString:@"fetchIds"]) {
    [self setFetchIds:_value];
  }
  else if ([_key isEqualToString:@"fetchGlobalIDs"]) {
    [self setFetchGlobalIDs:[_value boolValue]];
  }
  else if ([_key isEqualToString:@"maxSearchCount"]) {
    [self setMaxSearchCount:_value];
  }
  else {
    if (self->searchKeys == nil)
      self->searchKeys = [[NSMutableDictionary allocWithZone:[self zone]] init];

    [self->searchKeys setObject:_value forKey:_key];
  }
  return;
}

- (id)valueForKey:(id)_key {
  [self assert:(_key != nil) reason:@"passed invalid key to -valueForKey: .."];
  
  if ([_key isEqualToString:@"entity"])
    return [self entityName];
  else if ([_key isEqualToString:@"searchRecords"] ||
           [_key isEqualToString:@"object"])
    return [self searchRecordList];
  else if ([_key isEqualToString:@"operator"])
    return [self operator];
  else if ([_key isEqualToString:@"fetchIds"])
    return [self fetchIds];
  else if ([_key isEqualToString:@"fetchGlobalIDs"])
    return [NSNumber numberWithBool:[self fetchGlobalIDs]];
  else
    return [self->searchKeys objectForKey:_key];
  return [super valueForKey:_key];
}

@end
