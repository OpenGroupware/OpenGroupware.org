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

#include "LSFullSearch.h"
#include "LSFullSearchCommand.h"
#include "LSSearchCommands.h"
#include "common.h"

@interface LSFullSearchCommand(Private)
- (EOSQLQualifier *)checkPermissionsFor:(EOSQLQualifier *)qualifier_
  context:(id)_ctx;
- (void)checkReadPermissions:(id)_context;
@end

@implementation LSFullSearchCommand

static BOOL debugOn;

+ (int)version {
  return [super version] + 2; /* v3 */
}
+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  debugOn = [ud boolForKey:@"LSFullSearchDebugEnabled"];
}

- (void)dealloc {
  [self->searches       release];
  [self->searchString   release];
  [self->maxSearchCount release];
  [super dealloc];
}

/* command methods */

- (NSArray *)_singleFullSearchesForEntityNamed:(NSString *)_entityName
  withRelations:(NSArray *)_relations
{
  NSEnumerator   *listEnum;
  NSMutableArray *singleSearches;
  id             relName;
  
  singleSearches = [NSMutableArray arrayWithCapacity:16];
  
  listEnum = [_relations objectEnumerator];
  while ((relName = [listEnum nextObject])) {
    LSFullSearch *search;
    EOEntity     *myEntity;
    
    search   = [[LSFullSearch alloc] init];
    myEntity = [[self databaseModel] entityNamed:relName];
    
    [search initWithEntity:[self entity]
            andEntities:[NSMutableArray arrayWithObject:myEntity]];
    [search setDbAdaptor:[self databaseAdaptor]];
    
    [singleSearches addObject:search];
    [search release]; search = nil;
  }
  
  return singleSearches;
}

- (NSArray *)_dependentFullSearchWithRelations:(NSArray *)_relations {
  NSEnumerator   *listEnum;
  NSMutableArray *fullSearches;
  id             relName;
  
  listEnum     = [_relations objectEnumerator];
  fullSearches = [NSMutableArray arrayWithCapacity:4];

  while ((relName = [listEnum nextObject])) {
    NSMutableArray *entities;
    NSArray        *compoundRelations;
    NSDictionary   *configDict;
    LSFullSearch *search;
    NSEnumerator *relEnum;
    id           compRelName;
    
    configDict        = [self->searchConfig objectForKey:relName];
    compoundRelations = [configDict objectForKey:@"compound"];
    
    if ([compoundRelations count] == 0)
      continue;
    
    entities = [[NSMutableArray alloc] initWithCapacity:16];
    
    relEnum = [compoundRelations objectEnumerator];
    while ((compRelName = [relEnum nextObject]))
      [entities addObject:[[self databaseModel] entityNamed:compRelName]];
      
    search = [[LSFullSearch alloc]
               initWithEntity:[[self databaseModel] entityNamed:relName]
               andEntities:entities];
    [entities release];
    [search setDbAdaptor:[self databaseAdaptor]];
    [fullSearches addObject:search];
    [search release];
  }
  
  return fullSearches;
}

- (NSArray *)_compoundFullSearchForEntityNamed:(NSString *)_entityName
  withRelations:(NSArray *)_relations
{
  NSEnumerator   *listEnum;
  NSMutableArray *entities;
  NSMutableArray *fullSearches;
  LSFullSearch   *search;
  id             relName;

  listEnum     = [_relations objectEnumerator];
  entities     = [[NSMutableArray alloc] init];
  fullSearches = [NSMutableArray array];
  
  while ((relName = [listEnum nextObject]))
    [entities addObject:[[self databaseModel] entityNamed:relName]];
  
  search = [[LSFullSearch alloc]
                          initWithEntity:[self entity] andEntities:entities];
  [search setFurtherSearches:
            [self _dependentFullSearchWithRelations:_relations]];
  [search setDbAdaptor:[self databaseAdaptor]];
  [fullSearches addObject:search];
  
  [search   release]; search = nil;
  [entities release]; entities = nil;
  
  return fullSearches;
}

/* defaults */

- (NSDictionary *)_fullSearchConfigInContext:(id)_context {
  return [[_context userDefaults] dictionaryForKey:@"LSFullSearchConfig"];
}

- (int)_maxSearchCountInContext:(id)_context {
  return [[[_context userDefaults] objectForKey:@"LSMaxSearchCount"] intValue];
}

/* limits */

- (void)resetLimitMarkerInContext:(id)_ctx {
  [_ctx takeValue:[NSNull null] forKey:@"_cache_fullSearchLimited"];
}
- (void)markLimitedTo:(int)_limit inContext:(id)_ctx {
  [_ctx takeValue:[NSNumber numberWithInt:_limit] 
        forKey:@"_cache_fullSearchLimited"];
}

/* execution */

- (void)_prepareForExecutionInContext:(id)_context {
  NSArray      *singleRelations;
  NSArray      *compoundRelations;
  NSArray      *tmp;
  NSDictionary *configDict;
  
  self->searches     = [[NSMutableArray alloc] init];
  self->searchConfig = [self _fullSearchConfigInContext:_context];
  configDict         = [self->searchConfig objectForKey:[self entityName]];
  
  singleRelations   = [configDict objectForKey:@"single"];
  compoundRelations = [configDict objectForKey:@"compound"];

  if ([singleRelations count] > 0) {
    tmp = [self _singleFullSearchesForEntityNamed:[self entityName]
                withRelations:singleRelations];
    [self->searches addObjectsFromArray:tmp];
  }
  
  if ([compoundRelations count] > 0) {
    tmp = [self _compoundFullSearchForEntityNamed:[self entityName]
                withRelations:compoundRelations];
    [self->searches addObjectsFromArray:tmp];
  }
}

- (EOSQLQualifier *)trueQualifier {
  return [[[EOSQLQualifier alloc] initWithEntity:[self entity]
                                  qualifierFormat:@"1=1"] autorelease];
}

- (id)_fetchCompleteEntityInContext:(id)_context fetchLimit:(int)maxSearch {
  /* no search string was specified, query complete entity */
  EODatabaseChannel *dbChannel;
  NSMutableArray *results   = nil;
  EOSQLQualifier *qualifier = nil;
  id             result     = nil;
  int            cnt        = 0;
  BOOL isOk, searchLimited;
  void (*addObj)(id, SEL, id) = NULL;
  
  dbChannel = [self databaseChannel];
  results   = [NSMutableArray arrayWithCapacity:maxSearch];

  qualifier = [self trueQualifier];

  /* add permission qualifier */
  
  qualifier = [self checkPermissionsFor:qualifier context:_context];

  /* perform fetch */
  
  searchLimited = NO;
  // TODO: use adaptor, only fetch IDs
  isOk = [dbChannel selectObjectsDescribedByQualifier:qualifier
                    fetchOrder:nil];
  if (!isOk) return sybaseMessages;
  qualifier = nil;
  
  cnt = 0;
  addObj = (void(*)(id, SEL, id))
    [results methodForSelector:@selector(addObject:)];
  while ((result = [dbChannel fetchWithZone:NULL])) {
    addObj(results, @selector(addObject:), result);
    cnt++;
    if (cnt >= maxSearch) { // TODO: set a marker
      [self debugWithFormat:@"the search was canceled (limit=%d)", maxSearch];
      [dbChannel cancelFetch];
      searchLimited = YES;
      break;
    }
    result = nil;
  }
  [self setReturnValue:results];
  if (searchLimited) [self markLimitedTo:maxSearch inContext:_context];
  return nil;
}

- (id)_fetchEntitySubset:(NSString *)_str inContext:(id)_context 
  fetchLimit:(int)maxSearch 
{
  // Note: this returns the error object, not the result set!
  /* search string was specified */
  EODatabaseChannel *dbChannel;
  NSEnumerator *searchEnum = nil;
  NSMutableSet *results    = nil;
  int          cnt, idx;
  void (*addObj)(id, SEL, id) = NULL;
  BOOL searchLimited;
  
  if ([_str length] == 0)
    return nil;
  
  if (debugOn) [self debugWithFormat:@"fullsearch: '%@'", _str];
  
  dbChannel = [self databaseChannel];
  
  results = [NSMutableSet setWithCapacity:maxSearch];
  addObj  = (void(*)(id, SEL, id))
    [results methodForSelector:@selector(addObject:)];
  
  searchLimited = NO;
  searchEnum = [self->searches objectEnumerator];
  for (idx = 0, cnt = 0; cnt < maxSearch && !searchLimited; idx++) {
    EOSQLQualifier *qualifier;
    id   result, fullSearch;
    BOOL isOk;

    /* setup qualifier generator (LSFullSearch) */
    
    if ((fullSearch = [searchEnum nextObject]) == nil)
      break;
    
    [fullSearch setSearchString:_str];
    if (idx != 0) [fullSearch setIncludesOwnAttributes:NO];
    
    if (debugOn) [self debugWithFormat:@"  subsearch: '%@'", fullSearch];

    /* generate qualifier */
    
    qualifier = [(LSFullSearch *)fullSearch qualifier];
    if (debugOn) [self debugWithFormat:@"    qualifier: 0x%p", qualifier];

    /* add permission check qualifier to 'qualifier' */
    
    qualifier = [self checkPermissionsFor:qualifier context:_context];
    
    /* perform fetch */
    
    // TODO: use adaptor, only fetch IDs
    isOk = [dbChannel selectObjectsDescribedByQualifier:qualifier
                      fetchOrder:nil];
    if (!isOk) return sybaseMessages;
    
    while ((cnt < maxSearch) && (result = [dbChannel fetchWithZone:NULL])) {
      addObj(results, @selector(addObject:), result);
      
      cnt = [results count];
      if (cnt >= maxSearch) {
        [self debugWithFormat:@"the search was canceled (limit=%d)",maxSearch];
        [[self databaseChannel] cancelFetch];
        searchLimited = YES;
        break;
      }
      result = nil;
    }
    
    // TODO: is this required to be in the loop? eg for access check?
    [self setReturnValue:[results allObjects]];
  }
  
  if (searchLimited) 
    [self markLimitedTo:maxSearch inContext:_context];
  
  // TODO: check limit (whether "searchEnum" contains more objects!) !
  
  if (debugOn) [self debugWithFormat:@"fullsearch done."];
  return nil;
}

- (id)_fetchEntitySubsets:(NSArray *)_strs inContext:(id)_context 
  fetchLimit:(int)maxSearch 
{
  NSMutableSet *results;
  unsigned i, count;
  id   error = nil;
  
  if ((count = [_strs count]) == 0)
    return [self _fetchCompleteEntityInContext:_context fetchLimit:maxSearch];
  if (count == 1) {
    return [self _fetchEntitySubset:[_strs lastObject] inContext:_context
                 fetchLimit:maxSearch];
  }
  
  if (debugOn) {
    [self debugWithFormat:@"fullsearch for %@", 
            [_strs componentsJoinedByString:@","]];
  }
  
  // Note: we intentionally do not touch the restriction marker (for now)
  
  results = [NSMutableSet setWithCapacity:256];
  for (i = 0; i < count; i++) {
    NSString *str;
    NSArray  *partResult;
    
    str   = [_strs objectAtIndex:i];
    error = [self _fetchEntitySubset:str inContext:_context 
                  fetchLimit:maxSearch];
    if (error) break;
    
    partResult = [self returnValue];
    
    if (i == 0) {
      [results addObjectsFromArray:partResult];
      continue;
    }
    
    /* merge */
    if (self->isAndMode) {
      NSSet *set;
      
      set = [[NSSet alloc] initWithArray:partResult];
      [results intersectSet:set];
      [set release];
    }
    else { /* or-mode, just add up everything ... */
      [results addObjectsFromArray:[self returnValue]];
    }
  }
  
  [self setReturnValue:[results allObjects]];
  
  return error;
}

- (void)_executeInContext:(id)_context {
  int  maxSearch;
  id   error;
  BOOL doUnrestrictedSearch;
  
  [self resetLimitMarkerInContext:_context];
  
  maxSearch = [self _maxSearchCountInContext:_context];
  if ([self->maxSearchCount intValue] > 0)
    maxSearch = [self->maxSearchCount intValue];

  /* select search method depending on query string[s] */
  
  doUnrestrictedSearch = NO;
  if (self->searchString == nil) {
    doUnrestrictedSearch = YES;
  }
  else if ([self->searchString isKindOfClass:[NSArray class]]) {
    error = [self _fetchEntitySubsets:self->searchString
                  inContext:_context fetchLimit:maxSearch];
  }
  else {
    if ([self->searchString length] == 0)
      doUnrestrictedSearch = YES;
    else {
      error = [self _fetchEntitySubset:self->searchString
                    inContext:_context fetchLimit:maxSearch];
    }
  }
  if (doUnrestrictedSearch)
    error = [self _fetchCompleteEntityInContext:_context fetchLimit:maxSearch];
  
  /* process results */
  
  if (error) {
    [self logWithFormat:@"fullsearch failed: %@", error];
    [self setReturnValue:error];
    return;
  }
  
  // TODO: we need to set a max-search count reached marker prior narrowing
  //       the search in the permission check!
  
  if (debugOn) [self debugWithFormat:@"fullsearch: check permissions ..."];
  [self checkReadPermissions:_context];
  if (debugOn) [self debugWithFormat:@"fullsearch: checked permissions."];
}

/* permissions */

- (EOSQLQualifier *)checkPermissionsFor:(EOSQLQualifier *)qualifier_ 
  context:(id)_ctx 
{
  /*
    This adds a qualifier which checks for the 'isPrivate' and 'owner'
    combination to the 'qualifier_' passed in.
  */
  EOEntity       *entity;  
  EOSQLQualifier *privQual;
  NSNumber       *accountId;
  
  entity = [qualifier_ entity];
  if ([entity attributeNamed:@"isPrivate"] == nil)
    return qualifier_;
  if ([[entity name] isEqualToString:@"Person"])
    // TODO: why don't we check Persons?
    return qualifier_;
  
  accountId = [[_ctx valueForKey:LSAccountKey] valueForKey:@"companyId"];
  privQual  = [[EOSQLQualifier alloc] initWithEntity:entity
                                      qualifierFormat:
                                        @"(isPrivate = 0) OR "
                                        @"(isPrivate IS NULL) OR "
                                        @"(ownerId = %@)",
                                        accountId];
  if (debugOn) [self debugWithFormat:@"  add access check qual: %@", privQual];
  [qualifier_ conjoinWithQualifier:privQual];
  [privQual release];
  return qualifier_;
}

- (void)checkReadPermissions:(id)_context {
  NSArray        *r;
  NSArray        *access;
  NSMutableArray *a;
  NSEnumerator   *enumerator;
  id             obj;

  r = [self returnValue];
  
  access = [r map:@selector(valueForKey:) with:@"globalID"];
  
  if (debugOn) {
    [self debugWithFormat:@"  check read-access of %d gids ...", 
            [access count]];
  }
  
  access = [[_context accessManager] objects:access forOperation:@"r"];
  
  a = [NSMutableArray arrayWithCapacity:[access count]];
  
  enumerator = [r objectEnumerator];
  while ((obj = [enumerator nextObject])) {
    if ([access containsObject:[obj valueForKey:@"globalID"]])
      [a addObject:obj];
  }
  access = a;
  [self setReturnValue:access];
}
                              
/* accessors */

- (void)setSearchString:(NSString *)_searchString {
  ASSIGN(self->searchString, _searchString);
}
- (NSString *)searchString {
  if (![self->searchString isNotNull])
    return nil;
  
  if (![self->searchString isKindOfClass:[NSArray class]])
    return self->searchString;
  
  if ([self->searchString count] == 0)
    return nil;
  if ([self->searchString count] == 1)
    return [self->searchString lastObject];
    
  [self logWithFormat:
          @"WARNING: queried '-searchString' which is a collection, "
          @"returning first."];
  return [self->searchString objectAtIndex:0];
}
- (void)setSearchStrings:(NSArray *)_searchStrings {
  ASSIGN(self->searchString, _searchStrings);
}
- (NSArray *)searchStrings {
  if (![self->searchString isNotNull])
    return nil;
  if (![self->searchString isKindOfClass:[NSArray class]])
    return [NSArray arrayWithObject:self->searchString];
  return self->searchString;
}

- (void)setMaxSearchCount:(NSNumber *)_maxSearchCount {
  ASSIGN(self->maxSearchCount, _maxSearchCount);
}
- (NSNumber *)maxSearchCount {
  return self->maxSearchCount;
}

- (void)setIsAndMode:(BOOL)_andMode {
  self->isAndMode = _andMode;
}
- (BOOL)isAndMode {
  return self->isAndMode;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  NSString *s;
  
  if ([_key isEqualToString:@"entity"]) {
    [self setEntityName:_value];
    return;
  }
  if ([_key isEqualToString:@"searchString"]) {
    [self setSearchString:_value];
    return;
  }
  if ([_key isEqualToString:@"searchStrings"]) {
    [self setSearchStrings:_value];
    return;
  }
  if ([_key isEqualToString:@"maxSearchCount"]) {
    [self setMaxSearchCount:_value];
    return;
  }
  if ([_key isEqualToString:@"isAndMode"]) {
    [self setIsAndMode:[_value boolValue]];
    return;
  }
  
  s = [NSString stringWithFormat:
                  @"key '%@' is not valid in domain '%@' for operation '%@'.",
                  _key, [self domain], [self operation]];
  [LSDBObjectCommandException raiseOnFail:NO object:self reason:s];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"entity"])
    return [self entityName];
  if ([_key isEqualToString:@"searchString"])
    return [self searchString];
  if ([_key isEqualToString:@"searchStrings"])
    return [self searchStrings];
  if ([_key isEqualToString:@"maxSearchCount"])
    return [self maxSearchCount];
  if ([_key isEqualToString:@"isAndMode"])
    return [NSNumber numberWithBool:[self isAndMode]];
  
  return [super valueForKey:_key];
}

/* debugging */

- (BOOL)isDebuggingEnabled {
  return debugOn;
}

@end /* LSFullSearchCommand */
