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

- (void)dealloc {
  [self->searchKeys       release];
  [self->searchRecordList release];
  [self->extendedSearch   release];
  [self->operator         release];
  [self->maxSearchCount   release];
  [super dealloc];
}

/* command methods */

- (void)_validateKeysForContext:(id)_context {
}

- (void)_prepareForExecutionInContext:(id)_context {
  NSMutableArray *relatedRecords = nil;
  NSEnumerator   *listEnum       = nil;
  id             record          = nil;
  id             searchRecord    = nil;

  relatedRecords = [[NSMutableArray alloc] initWithCapacity:4];

  if (self->searchKeys != nil) { // use parameter keys
    searchRecord = [[LSGenericSearchRecord alloc]initWithEntity:[self entity]];
    [searchRecord takeValuesFromDictionary:self->searchKeys];
  }
  else { // search primary prototype record
    NSString *ename = [self entityName];
    
    listEnum = [self->searchRecordList objectEnumerator];
    while ((record = [listEnum nextObject]) != nil) {
      if ([ename isEqualToString:[[record entity] name]]) {
        searchRecord = [record retain];
        break;
      }
    }
  }
  if (searchRecord != nil) {
    [self->extendedSearch release]; self->extendedSearch = nil;
    self->extendedSearch = [[LSExtendedSearch alloc] init];

    [relatedRecords addObjectsFromArray:self->searchRecordList];
    [relatedRecords removeObject:searchRecord];

    if (self->operator) [self->extendedSearch setOperator:self->operator];
    [self->extendedSearch setSearchRecord:searchRecord];
    [self->extendedSearch setRelatedRecords:relatedRecords];
    [self->extendedSearch setDbAdaptor:[self databaseAdaptor]];
  }
  [searchRecord   release]; searchRecord   = nil;
  [relatedRecords release]; relatedRecords = nil;
}

- (EOSQLQualifier *)extendedSearchQualifier:(void *)_context {
  return [self->extendedSearch qualifier];
}

- (BOOL)isNoMatchSQLQualifier:(EOSQLQualifier *)_q {
  // quite hackish, 1=2 is returned by the LSExtendedSearch
  NSString *s;
  
  s = [_q expressionValueForContext:nil];
  return [s isEqualToString:@"1=2"];
}

- (int)lesMaxSearchCountInContext:(id)_context {
  if ([self maxSearchCount] != nil)
    return [[self maxSearchCount] intValue];

  return [[[_context userDefaults] objectForKey:@"LSMaxSearchCount"] intValue];
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

  maxSearch = [self lesMaxSearchCountInContext:_context];
  qualifier = [self _buildQualifierWithContext:_context];
  
  results   = [NSMutableArray arrayWithCapacity:
				(maxSearch > 0) ? maxSearch : 512];
  
  [self assert:[channel selectObjectsDescribedByQualifier:qualifier
                        fetchOrder:nil]];
  
  fetch  = [channel methodForSelector:@selector(fetchWithZone:)];
  addObj = [results methodForSelector:@selector(addObject:)];
  
  while (((maxSearch == 0 ) || (cnt < maxSearch)) &&
         (result = fetch(channel, @selector(fetchWithZone:), nil))) {
      
    addObj(results, @selector(addObject:), result);
    cnt = [results count];
    
    if ((maxSearch != 0) && (cnt == maxSearch))
      [[self databaseChannel] cancelFetch];
    result = nil;
  }
  return results;
}

- (NSArray *)_fetchIds:(id)_context {
  // TODO: in this case we could fetch all and filter access afterwards?!
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
  
  maxSearch = [self lesMaxSearchCountInContext:_context];
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

- (EOSQLQualifier *)newPrivateQualifierForCompanyId:(NSNumber *)_cid
  entity:(EOEntity *)_entity
{
  if (_cid == nil) _cid = [NSNumber numberWithInt:0];
  return [[EOSQLQualifier alloc] initWithEntity:_entity
				 qualifierFormat:
				   @"(isPrivate = 0) OR "
				   @"(isPrivate IS NULL) OR (ownerId = %@)",
                                   _cid];
}

- (EOSQLQualifier *)newNoFakeQualifierWithEntity:(EOEntity *)_entity {
  return [[EOSQLQualifier alloc] initWithEntity:_entity
				 qualifierFormat:
				   @"(isFake = 0) OR (isFake IS NULL)"];
}

- (EOSQLQualifier *)_buildQualifierWithContext:(id)_context {
  EOSQLQualifier *qualifier;
  EOEntity       *entity;

  qualifier = [self extendedSearchQualifier:_context];
  entity    = [qualifier entity];
  
  if ([entity attributeNamed:@"isPrivate"] &&
      ![[entity name] isEqualToString:@"Person"]) {
    EOSQLQualifier *privQual;
    id             accountId;
    
    accountId = [[_context valueForKey:LSAccountKey] valueForKey:@"companyId"];
    privQual = [self newPrivateQualifierForCompanyId:accountId entity:entity];
    [qualifier conjoinWithQualifier:privQual];
    [privQual release]; privQual = nil;
  }
  if ([entity attributeNamed:@"isFake"] != nil) {
    EOSQLQualifier *fakeQual = nil;
    
    fakeQual  = [self newNoFakeQualifierWithEntity:entity];
    [qualifier conjoinWithQualifier:fakeQual];
    [fakeQual release]; fakeQual = nil;
  }
  return qualifier;
}

- (NSArray *)_determineAccessGIDsFromResults:(NSArray *)r {
  if ([self fetchGlobalIDs])
    return r;

  if ([[self fetchIds] boolValue]) { /* got dict with pk and entity */
      NSEnumerator   *enumerator;
      NSDictionary   *obj;
      NSString       *keyName, *en;
      NSMutableArray *a;
      
      enumerator = [r objectEnumerator];
      keyName    = nil;
      en         = nil;      
      a          = [NSMutableArray arrayWithCapacity:[r count]];
      while ((obj = [enumerator nextObject]) != nil) {
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
      return a;
  }
  
  return [r map:@selector(valueForKey:) with:@"globalID"];
}

- (NSArray *)filterResults:(NSArray *)r fromAccess:(NSArray *)access {
  NSMutableArray *a;
  NSEnumerator   *enumerator;
  id obj;

  a = [NSMutableArray arrayWithCapacity:[access count]];
  enumerator = [r objectEnumerator];
  
  if ([self fetchGlobalIDs]) {
    NSMutableArray *a;
    
    /* 
       Why can't we just return 'access'? I suppose because the 'r' might
       be sorted.
    */
    while ((obj = [enumerator nextObject]) != nil) {
      if ([access containsObject:obj])
	[a addObject:obj];
    }
  }
  else if ([[self fetchIds] boolValue]) {
    NSString *keyName, *en;
    
    keyName = nil;
    en      = nil;      
    while ((obj = [enumerator nextObject]) != nil) {
      id k, o;
	
      if (keyName == nil) {
	NSArray *pkeys;
	
	pkeys   = [[obj valueForKey:@"entity"] primaryKeyAttributes];
	keyName = [(EOAttribute *)[pkeys lastObject] name];
	en      = [(EOEntity *)[obj valueForKey:@"entity"] name];
	NSAssert(keyName, @"missing key name");
      }
      
      k = [(NSDictionary *)obj objectForKey:keyName];
      o = [EOKeyGlobalID globalIDWithEntityName:en
			 keys:&k keyCount:1 zone:NULL];
      if ([access containsObject:o])
	[a addObject:obj];
    }
  }
  else {
    while ((obj = [enumerator nextObject]) != nil) {
        if ([access containsObject:[obj valueForKey:@"globalID"]])
          [a addObject:obj];
    }
  }
  return a;
}

- (void)_executeInContext:(id)_context {
  NSAutoreleasePool *pool;
  NSArray *access;
  NSArray *r;

  pool = [[NSAutoreleasePool alloc] init];
  
  /* primary fetch */

  r = ([[self fetchIds] boolValue])
    ? [self _fetchIds:_context]
    : [self _fetchObjects:_context];
  
  r = [[r copy] autorelease];

  /* check permissions */
  
  access = [self _determineAccessGIDsFromResults:r];
  access = [[_context accessManager] objects:access forOperation:@"r"];
  r      = [self filterResults:r fromAccess:access];
  
  /* set return value to permission-checked objects */
  [self setReturnValue:r];
  [pool release];
}

/* support for person/enterprise */

- (id)_checkRecordsForCSVAttribute:(NSString *)_attrName {
  NSArray               *records;
  LSGenericSearchRecord *record;
  unsigned max, i;
  id lKeyWord = nil;
  
  records = [self searchRecordList];
  for (i = 0, max = [records count]; i < max; i++) {
    id keyw;
    
    record = [records objectAtIndex:i];
    
    if (![[[record entity] name] isEqualToString:[self entityName]])
      continue;
    
    if ((keyw = [record valueForKey:_attrName]) == nil)
      continue;
    if ([keyw isKindOfClass:[NSString class]] && [keyw length] == 0)
      continue;
    if ([keyw isKindOfClass:[NSArray class]] && [keyw count] == 0)
      continue;
    
    /* found a keyword, this terminates the loop */
    
    //if (debugOn) [self logWithFormat:@"  found %@: '%@'", _attrNamekeyw];

    if ([keyw isKindOfClass:[NSArray class]])
      lKeyWord = [keyw valueForKey:@"stringByDeletingSQLKeywordPatterns"];
    else
      lKeyWord = [[keyw stringValue] stringByDeletingSQLKeywordPatterns];
    
    /* remove from record */
    
    if ([[self operator] isEqualToString:@"OR"])
      [record removeObjectForKey:_attrName];
    else {
#if 0
      // TODO: please explain that, doesn't seem to make sense?
      [record takeValue:@"*" forKey:_attrName];
#else
      // hh: I don't think the above is necessary, the keywords are appended
      //     as a separate qualifier.
      [record removeObjectForKey:_attrName];
#endif
    }
    
    break;
  }
  return lKeyWord;
}

/* accessors */

- (void)setSearchRecordList:(NSArray *)_searchRecordList {
  ASSIGN(self->searchRecordList, _searchRecordList);
}
- (NSArray *)searchRecordList {
  return self->searchRecordList;
}

- (void)setOperator:(NSString *)_op {
  ASSIGNCOPY(self->operator, _op);
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

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  [self assert:(_key != nil)
        reason:@"passed invalid key to -takeValue:forKey: .."];

  if (_value == nil) _value = [EONull null];
  
  if ([_key isEqualToString:@"entity"])
    [self setEntityName:[_value stringValue]];
  else if ([_key isEqualToString:@"searchRecords"] ||
           [_key isEqualToString:@"object"]) {
    [self setSearchRecordList:_value];
  }
  else if ([_key isEqualToString:@"operator"])
    [self setOperator:[_value stringValue]];
  else if ([_key isEqualToString:@"fetchIds"])
    [self setFetchIds:_value];
  else if ([_key isEqualToString:@"fetchGlobalIDs"]) {
    [self setFetchGlobalIDs:[_value boolValue]];
  }
  else if ([_key isEqualToString:@"maxSearchCount"]) {
    [self setMaxSearchCount:_value];
  }
  else {
    if (self->searchKeys == nil)
      self->searchKeys = [[NSMutableDictionary alloc] initWithCapacity:4];

    [self->searchKeys setObject:_value forKey:_key];
  }
}

- (id)valueForKey:(NSString *)_key {
  [self assert:(_key != nil) reason:@"passed invalid key to -valueForKey: .."];
  
  if ([_key isEqualToString:@"entity"])
    return [self entityName];
  if ([_key isEqualToString:@"searchRecords"] ||
      [_key isEqualToString:@"object"])
    return [self searchRecordList];
  if ([_key isEqualToString:@"operator"])
    return [self operator];
  if ([_key isEqualToString:@"fetchIds"])
    return [self fetchIds];
  if ([_key isEqualToString:@"fetchGlobalIDs"])
    return [NSNumber numberWithBool:[self fetchGlobalIDs]];
  
  return [self->searchKeys objectForKey:_key];
}

@end /* LSExtendedSearchCommand */


@implementation NSString(SQLPatterns)

- (NSString *)stringByDeletingSQLKeywordPatterns {
  if (NO /* keywordsWithPatterns */)
    self = [self stringByReplacingString:@"*" withString:@"%"];
  else {
    self = [self stringByReplacingString:@"*" withString:@""];
    self = [self stringByReplacingString:@"%" withString:@""];
  }
  return self;
}

@end /* NSString(SQLPatterns) */
