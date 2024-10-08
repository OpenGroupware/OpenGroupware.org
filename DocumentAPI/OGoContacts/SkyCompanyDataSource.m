/*
  Copyright (C) 2000-2006 SKYRIX Software AG
  Copyright (C) 2006      Helge Hess

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

#include "SkyCompanyDataSource.h"
#include "SkyCompanyDocument.h"
#include "common.h"

@interface NSObject(SearchDict)
- (NSDictionary *)searchDict;
@end

// #define USE_QSEARCH 1

@implementation SkyCompanyDataSource

static BOOL doExplain = NO;

+ (int)version {
  return [super version] + 0; /* v1 */
}
+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];;
  
  NSAssert2([super version] == 1,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
  
  if ((doExplain = [ud boolForKey:@"OGoCompanyDataSourceExplain"]))
    NSLog(@"Note: OGoCompanyDataSourceExplain is enabled.");
}

- (NSNotificationCenter *)notificationCenter {
  static NSNotificationCenter *nc = nil;
  if (nc == nil) nc = [[NSNotificationCenter defaultCenter] retain];
  return nc;
}

- (void)_registerForChangeNotifications {
  [self errorWithFormat:@"subclasses should override this method!"];
}

- (id)initWithContext:(LSCommandContext *)_context { // designated initializer
  if (_context == nil) {
    [self errorWithFormat:
            @"%s: missing context for datasource creation ..",
	    __PRETTY_FUNCTION__];
    [self release];
    return nil;
  }
  
  if ((self = [super init])) {
    [self _registerForChangeNotifications];
    self->context = [_context retain];
  }
  return self;
}

- (id)init {
  return [self initWithContext:nil];
}

- (void)dealloc {
  [[self notificationCenter] removeObserver:self];
  
  [self->fetchSpecification release];
  [self->context            release];
  [super dealloc];
}

/* accessors */

- (void)setFetchSpecification:(EOFetchSpecification *)_fSpec {
  if ([self->fetchSpecification isEqual:_fSpec])
    return;
  
  ASSIGNCOPY(self->fetchSpecification, _fSpec);
  [self postDataSourceChangedNotification];
}
- (EOFetchSpecification *)fetchSpecification {
  return [[self->fetchSpecification copy] autorelease];
}

- (id)context {
  return self->context;
}

- (Class)documentClass {
  [self errorWithFormat:@"%s: subclasses must override this method!",
	  __PRETTY_FUNCTION__];
  return Nil;
}

- (NSSet *)nativeKeys {
  /* Note: returns the EOModel attribute names */
  [self errorWithFormat:@"%s: subclasses must override this method!",
	  __PRETTY_FUNCTION__];
  return nil;
}

- (NSSet *)arrayKeys {
  /*
    those are keys, where the several values are saved per row,
    separated by a comma
    i.e. keywords = "keyword1, keyword2, keyword3"
   
    those qualifiers, containing an array key are saved in the
    unhandlesQualifiers array
   
    in this case the value '%value%' is searched and after fetching the
    entries they may be filtered implementing the following 2 methods
    in subclasses
  */
  [self errorWithFormat:@"%s: subclasses must override this method!",
	  __PRETTY_FUNCTION__];
  return nil;
}

- (NSArray *)filterFetchEOs:(NSArray *)_eos
  withUnhandledQualifiers:(NSMutableArray *)_qualifiers
  originalQualifier:(EOQualifier *)_qualifier
{
  return _eos;
}

- (NSArray *)filterFetchDocs:(NSArray *)_docs
  withUnhandledQualifiers:(NSMutableArray *)_qualifiers
  originalQualifier:(EOQualifier *)_qualifier
{
  return _docs;
}

/* commands */

- (NSString *)commandDomain {
  return [[self nameOfEntity] lowercaseString];
}

- (NSString *)nameOfEntity {
  [self errorWithFormat:@"(%s): subclasses must override this method!",
	  __PRETTY_FUNCTION__];
  return nil;
}

/* notifications */

- (NSString *)nameOfNewCompanyNotification {
  [self errorWithFormat:@"(%s): subclasses need to override this method!",
	  __PRETTY_FUNCTION__];
  return nil;
}
- (NSString *)nameOfUpdatedCompanyNotification {
  [self errorWithFormat:@"(%s): subclasses need to override this method!",
	  __PRETTY_FUNCTION__];
  return nil;
}
- (NSString *)nameOfDeletedCompanyNotification {
  [self errorWithFormat:@"(%s): subclasses need to override this method!",
	  __PRETTY_FUNCTION__];
  return nil;
}

/* commands */

- (NSArray *)_performFullTextSearch:(NSString *)_txt fetchLimit:(int)_limit {
  return [self->context runCommand:
	      [[self commandDomain] stringByAppendingString:@"::full-search"],
              @"maxSearchCount", [NSNumber numberWithInt:_limit],
              @"searchString",   _txt, nil];
}
- (NSArray *)_performFullTextSearches:(NSArray *)_txts
  isAndMode:(BOOL)_isAndMode fetchLimit:(int)_limit 
{
  // TODO: ensure that we have no dups in _txts!
  return [self->context runCommand:
	      [[self commandDomain] stringByAppendingString:@"::full-search"],
              @"maxSearchCount", [NSNumber numberWithInt:_limit],
              @"searchStrings",   _txts, 
              @"isAndMode", [NSNumber numberWithBool:_isAndMode],
              nil];
}

/* fetching */

- (NSArray *)_fetchObjectsWithKeyValueQualifier:(EOKeyValueQualifier *)_q
  fetchLimit:(int)_fetchLimit;
{
  NSString *key;
  id       value = nil;

  if (doExplain) {
    [self logWithFormat:@"EXPLAIN: fetch key/value qualifier (limit %i): %@",
          _fetchLimit, _q];
  }
  
  if ((key = [self _mapKeyFromDocToEO:[_q key]]) == nil) {
    [self errorWithFormat:@"(%s): key '%@' is not available: %@",
          __PRETTY_FUNCTION__, [_q key], _q];
    return nil;
  }
  
  if ((value = [[_q value] stringValue]) == nil) {
    if (doExplain)
      [self logWithFormat:@"EXPLAIN: qualifier has no value => (): %@",_q];
    return [NSArray array];
  }
  
  if ([key isEqualToString:@"fullSearchString"]) {
    if (doExplain)[self logWithFormat:@"EXPLAIN:   full-search qualifier ..."];
    return [self _performFullTextSearch:value fetchLimit:_fetchLimit];
  }
  
  return [self _fetchCompaniesWithQualifier:_q
               operator:@"AND"
               fetchLimit:_fetchLimit];
  // TODO: fetch only the companyIds (fullSearchCommand)
}

- (NSException *)_handleUnsupportedQualifier:(EOQualifier *)qualifier {
  return [NSException exceptionWithName:@"UnsupportedQualifierException"
                      reason:
                 @"SkyCompanyDataSource: only supports following qualifiers: "
                 @" (EOKeyValueQualifier, EOOrQualifier, EOAndQualifier)!"
                      userInfo:nil];
}

- (NSArray *)_pkeyDictsForCompanies:(NSArray *)_companies {
  // make dicts out of this
  NSMutableArray *ma;
  unsigned       i, max;
  
  max = [_companies count];
  ma  = [NSMutableArray arrayWithCapacity:max];
  for (i = 0; i < max; i++) {
    NSDictionary *row;
    id key, value;
          
    key   = @"companyId"; 
    value = [_companies objectAtIndex:i];
    row = [[NSDictionary alloc] initWithObjects:&value forKeys:&key count:1];
    [ma addObject:row];
    [row release];
  }
  return ma;
}

- (NSArray *)_fetchCompaniesForKeyValueQualifier:(EOKeyValueQualifier *)_kvq 
  fetchLimit:(int)fetchLimit
  shouldMakeGidsFromIds:(BOOL *)shouldMakeGidsFromIds_
{
  NSString *qkey;
  NSArray  *companies;
    
  qkey = [_kvq key];
  
  if ([qkey isEqualToString:@"globalID"]) {
    /* return the GID or GIDs as an array */
    companies = [_kvq value];
    if (![companies isKindOfClass:[NSArray class]] && companies != nil)
      companies = [NSArray arrayWithObject:companies];
    if (shouldMakeGidsFromIds_) *shouldMakeGidsFromIds_ = NO;
    return companies;
  }
  
  if ([qkey isEqualToString:@"companyId"]) {
    /* return the pkeys as dictionaries for dict=>GID conversion */
    companies = [_kvq value];
    if (![companies isKindOfClass:[NSArray class]] && companies != nil)
      companies = [NSArray arrayWithObject:companies];
      
    if ([companies isNotEmpty])
      companies = [self _pkeyDictsForCompanies:companies];
      
    if (shouldMakeGidsFromIds_) *shouldMakeGidsFromIds_ = YES;
    return companies;
  }
  
  /* perform a regular fetch */
  companies = [self _fetchObjectsWithKeyValueQualifier:_kvq
                    fetchLimit:fetchLimit];
  return companies;
}

- (BOOL)isFullSearchQualifier:(EOQualifier *)_q {
  /*
    We currently handle fulltext searches with a different command. This
    should be changed in the future (OGoSQLGenerator should be able to
    generate full searches).
  */
  
  if (_q == nil)
    return NO;
  
  /* if we have a compound qualifier, check one of the subqualifiers */
  if ([_q isKindOfClass:[EOAndQualifier class]])
    _q = [[_q subqualifiers] lastObject];
  else if ([_q isKindOfClass:[EOOrQualifier class]])
    _q = [[_q subqualifiers] lastObject];
  
  if (![_q isKindOfClass:[EOKeyValueQualifier class]])
    return NO;
  
  return [[(EOKeyValueQualifier *)_q key] isEqualToString:@"fullSearchString"];
}

- (NSArray *)_primaryFetchCompaniesForQualifier:(EOQualifier *)_qualifier 
  fetchLimit:(int)_limit
  shouldMakeGidsFromIds:(BOOL *)shouldMakeGidsFromIds_
{
  if (_qualifier == nil)
    return nil;
  
#if USE_QSEARCH
  if (![self isFullSearchQualifier:_qualifier]) {
    NSArray  *results;
    
    if (doExplain)
      [self logWithFormat:@"EXPLAIN: using qsearch command: %@", _qualifier];
    
    if (shouldMakeGidsFromIds_ != NULL)
      *shouldMakeGidsFromIds_ = NO;
    
    results = [self->context runCommand:
		   [[self commandDomain] stringByAppendingString:@"::qsearch"],
		   @"qualifier",      _qualifier,
		   @"maxSearchCount", [NSNumber numberWithInt:_limit],
		   @"fetchGlobalIDs", [NSNumber numberWithBool:YES],
		   nil];

#warning DEBUG LOG
    [self logWithFormat:@"FETCHED: %@ (limit=%i)", results, _limit];
    
    return results;
  }
#endif
  
  if ([_qualifier isKindOfClass:[EOKeyValueQualifier class]]) {
    return [self _fetchCompaniesForKeyValueQualifier:(id)_qualifier
                 fetchLimit:_limit
                 shouldMakeGidsFromIds:shouldMakeGidsFromIds_];
  }
  
  if ([_qualifier isKindOfClass:[EOOrQualifier class]]) {
    return [self _fetchCompaniesWithQualifier:_qualifier
                 operator:@"OR" fetchLimit:_limit];
  }
  if ([_qualifier isKindOfClass:[EOAndQualifier class]]) {
    return [self _fetchCompaniesWithQualifier:_qualifier
                 operator:@"AND" fetchLimit:_limit];
  }
  
  /* return an exception */
  return (id)[self _handleUnsupportedQualifier:_qualifier];
}

- (NSArray *)_sortResultDocuments:(NSArray *)result {
  NSArray *sortOrderings;
  
  if ((sortOrderings = [self->fetchSpecification sortOrderings]) != nil)
    result = [result sortedArrayUsingKeyOrderArray:sortOrderings];
  
  return result;
}

/* primary datasource entry function */

- (NSArray *)fetchObjects {
  EOQualifier  *qualifier;
  NSArray      *companies;
  NSDictionary *hints;
  BOOL         fetchIds;
  BOOL         fetchGids;
  int          fetchLimit;
  BOOL         shouldMakeGidsFromIds;
  NSArray      *result;
  
  qualifier  = [self->fetchSpecification qualifier];
  fetchLimit = [self->fetchSpecification fetchLimit];
  
  if (doExplain)
    [self logWithFormat:@"EXPLAIN: fetchObjects: %@", qualifier];
  
  if (fetchLimit <= 0) {
    fetchLimit =
      [[self->context userDefaults] integerForKey:@"LSMaxSearchCount"];
  }
  
  hints      = [self->fetchSpecification hints];
  fetchIds   = [[hints objectForKey:@"fetchIds"] boolValue];
  fetchGids  = [[hints objectForKey:@"fetchGlobalIDs"] boolValue];
  
  shouldMakeGidsFromIds = YES;
  companies = [self _primaryFetchCompaniesForQualifier:qualifier
                    fetchLimit:fetchLimit
                    shouldMakeGidsFromIds:&shouldMakeGidsFromIds];
  if (companies == nil) companies = [NSArray array];
  if ([companies isKindOfClass:[NSException class]]) return companies;
  
  if (fetchIds)
    return companies; // return NSDictionary incl. the companyId

  if (shouldMakeGidsFromIds)
    companies = [self _makeGIDsFromIDs:companies];
  
  if (fetchGids)
    return companies; // return globalIDs
  
  companies = [self _getEOsFromGIDs:companies attributes:[self _attributes]];
  result    = [self _morphEOsToDocuments:companies];
  result    = [self _sortResultDocuments:result];
  
  return result ? result : (NSArray *)[NSArray array];
}

/* datasource operations */

- (id)createObject {
  // TODO: should rather set -lastException?
  [self errorWithFormat:@"(%s): subclasses must override this method!",
	  __PRETTY_FUNCTION__];
  return nil;
}

- (void)insertObject:(id)_obj {
  id  dict = [_obj asDict];

  dict = [self->context runCommand:
		[[self commandDomain] stringByAppendingString:@"::new"]
	      arguments:dict];

  [_obj _setGlobalID:[dict valueForKey:@"globalID"]];
  [_obj takeValue:[dict valueForKey:@"number"] forKey:@"number"];

  [self postDataSourceChangedNotification];
  [[self notificationCenter] 
         postNotificationName:[self nameOfNewCompanyNotification]
         object:_obj];
}

- (void)updateObject:(id)_obj {
  NSDictionary *args;
  
  if (![_obj isComplete]) // TODO: should give some feedback!
    return;

  args = [_obj asDict];

#if 0
#warning DEBUG LOG, REMOVE ME
  [self logWithFormat:@"saving using %@: %@", 
	  [self nameOfSetCommand], args];
#endif
  
  [self->context runCommand:
	 [[self commandDomain] stringByAppendingString:@"::set"]
       arguments:args];
  
  [self postDataSourceChangedNotification];
  [[self notificationCenter]
         postNotificationName:[self nameOfUpdatedCompanyNotification]
         object:_obj];
}

- (void)deleteObject:(id)_obj {
  NSDictionary *dict;
  
  dict = [_obj asDict];
#if 0 // TODO: explain this
  [dict takeValue:[NSNumber numberWithBool:YES] forKey:@"reallyDelete"];
#endif
  [self->context runCommand:
	 [[self commandDomain] stringByAppendingString:@"::delete"]
       arguments:dict];
  [self postDataSourceChangedNotification];
  
  [[self notificationCenter]
         postNotificationName:[self nameOfDeletedCompanyNotification]
         object:_obj];
}

/* PrivateMethodes */

- (NSArray *)_attributes {
  NSArray        *attributes;
  NSMutableArray *fSpecAttrs;
  BOOL           didChangeFSpec = NO;
  
  attributes = [[self->fetchSpecification hints] objectForKey:@"attributes"];
  fSpecAttrs = [[NSMutableArray alloc] initWithArray:attributes];

  if (attributes == nil)
    return nil;

  {
    NSEnumerator *attrEnum;
    NSArray      *attrs;
    NSString     *attr;

    attrs      = attributes;
    attrEnum   = [attrs objectEnumerator];
    attributes = [NSMutableArray arrayWithCapacity:([attrs count] + 1)];
    
    while ((attr = [attrEnum nextObject]) != nil)
      [(NSMutableArray *)attributes addObject:[self _mapKeyFromDocToEO:attr]];
  }
  
  if (![attributes containsObject:@"objectVersion"]) {
    attributes = [attributes arrayByAddingObject:@"objectVersion"];
    [fSpecAttrs addObject:@"objectVersion"];
    didChangeFSpec = YES;
  }
  if (![attributes containsObject:@"globalID"]) {
    attributes = [attributes arrayByAddingObject:@"globalID"];
    [fSpecAttrs addObject:@"globalID"];
    didChangeFSpec = YES;
  }
  if ([attributes containsObject:@"owner"] &&
      ![attributes containsObject:@"ownerId"])
    attributes = [attributes arrayByAddingObject:@"ownerId"];

  if ([attributes containsObject:@"contact"] &&
      ![attributes containsObject:@"contactId"])
    attributes = [attributes arrayByAddingObject:@"contactId"];
  
  if (didChangeFSpec) {
    NSMutableDictionary *hints;

    hints = [[NSMutableDictionary alloc] initWithDictionary:
                                           [self->fetchSpecification hints]];
    [hints setObject:fSpecAttrs forKey:@"attributes"];
    [hints release];
  }
  [fSpecAttrs release];
  
  return attributes;
}

- (NSArray *)_makeGIDsFromIDs:(NSArray *)_ids {
  static Class gidClass = nil;
  static Class numClass = nil;
  NSMutableArray *gids;
  unsigned       i, cnt;

  if (gidClass == nil) gidClass = [EOGlobalID class];
  if (numClass == nil) numClass = [NSNumber class];
  
  cnt  = [_ids count];
  gids = [NSMutableArray arrayWithCapacity:(cnt + 1)];
  
  for (i = 0; i < cnt; i++) {
    id obj;
    EOGlobalID *gid;
    
    if ([(obj = [_ids objectAtIndex:i]) isKindOfClass:gidClass]) {
      [gids addObject:obj];
      continue;
    }
    
    obj = [obj valueForKey:@"companyId"];
    if (![obj isKindOfClass:numClass])
      obj = [NSNumber numberWithInt:[obj intValue]];
      
    gid = [EOKeyGlobalID globalIDWithEntityName:[self nameOfEntity]
			 keys:&obj keyCount:1 zone:NULL];
    [gids addObject:gid];
  }
  return gids;  
}

- (NSArray *)_getEOsFromGIDs:(NSArray *)_gids attributes:(NSArray *)_attrs {
  NSArray *result;
  
  if (_attrs == nil) {
    result = [self->context runCommand:
		    [[self commandDomain] 
		      stringByAppendingString:@"::get-by-globalid"],
                  @"gids", _gids, nil];
  }
  else {
    result = [self->context runCommand:
		    [[self commandDomain] 
		      stringByAppendingString:@"::get-by-globalid"],
                  @"gids",       _gids,
                  @"attributes", _attrs,
                  nil];
  }
  return result;
}

- (NSArray *)_morphEOsToDocuments:(NSArray *)_eos {
  BOOL           addAsObserver = YES;
  unsigned       i, count;
  NSDictionary   *hints;
  NSMutableArray *result;

  if (_eos == nil)                 return [NSArray array];
  if ((count = [_eos count]) == 0) return [NSArray array];

  result = [NSMutableArray arrayWithCapacity:(count + 1)];

  hints  = [self->fetchSpecification hints];

  if ([hints objectForKey:@"addDocumentsAsObserver"] != nil)
    addAsObserver = [[hints objectForKey:@"addDocumentsAsObserver"] boolValue];
  
  for (i = 0; i < count; i++) {
    id doc;
    id company;
    
    company = [_eos objectAtIndex:i];

    /*
      the dataSource's fetchSpecification is responsible for the supported
      attributes in the document!!!
    */
    doc = [[[self documentClass] alloc]
                  initWithCompany:company
                  globalID:[company valueForKey:@"globalID"]
                  dataSource:self
                  addAsObserver:addAsObserver];

    
    [result addObject:doc];
    [doc release];
  }
  return result;
}

- (NSString *)_mapKeyFromEOToDoc:(NSString *)_key {
  return _key;
}
- (NSString *)_mapKeyFromDocToEO:(NSString *)_key {
  return _key;
}

- (NSArray *)_fetchCompaniesWithQualifier:(EOQualifier *)_qual
  operator:(NSString *)_operator
  fetchLimit:(unsigned int)_fetchLimit
{
  /* a primary fetch method called for EOAndQualifier/EOOrQualifier's */
  NSArray *searchRecords;
  NSArray *result = nil;
  NSArray *fullResults = nil;
  NSArray *fullSearchStrings;
  
  if (doExplain) {
    [self logWithFormat:@"EXPLAIN: fetch op=%@,limit=%d: '%@'",
            _operator, _fetchLimit, _qual];
  }
  
  /* split qualifiers */
  
  fullSearchStrings = nil;
  searchRecords = [self searchRecordsFromQualifier:_qual
                        fullTextSearchValues:&fullSearchStrings];
  if ([searchRecords isKindOfClass:[NSException class]]) {
    if (doExplain) {
      [self logWithFormat:@"EXPLAIN:   failed to create search recs: %@",
              searchRecords];
    }
    return searchRecords;
  }

  if (doExplain) {
    [self logWithFormat:
            @"EXPLAIN:   created search records:\n%@\n  full-searches: %@",
            searchRecords, fullSearchStrings];
  }
  
  /* perform searches */
  
  if ([fullSearchStrings count] == 1) {
    /* a single fulltext search */
    if (doExplain)
      [self logWithFormat:@"EXPLAIN:   run a single fullsearch .."];
    fullResults = [self _performFullTextSearch:
                          [fullSearchStrings objectAtIndex:0]
                        fetchLimit:_fetchLimit];
  }
  else if ([fullSearchStrings isNotEmpty]) {
    /* multiple fulltext keys */
    if (doExplain) {
      [self logWithFormat:@"EXPLAIN:   run multiple fullsearches: %@",
              fullSearchStrings];
    }
    fullResults = [self _performFullTextSearches:fullSearchStrings
                        isAndMode:[_qual isKindOfClass:[EOAndQualifier class]]
                        fetchLimit:_fetchLimit];
  }
  else if ([searchRecords isNotEmpty]) {
    if (doExplain) {
      [self logWithFormat:@"EXPLAIN:   run regular ext search (op %@) ..",
              _operator];
    }
    result = [self->context runCommand:
		  [[self commandDomain] 
		      stringByAppendingString:@"::extended-search"],
                  @"operator",       _operator,
                  @"searchRecords",  searchRecords,
                  @"fetchIds",       [NSNumber numberWithBool:YES],
                  @"maxSearchCount", [NSNumber numberWithInt:_fetchLimit],
                  nil];
  }
  
  // TODO: process context restrictions

  if (result != nil && fullResults != nil) {
    [self errorWithFormat:
            @"cannot do fulltext search at the same time "
            @"with a regular search!"];
  }
  else if (fullResults)
    result = fullResults;
  
  return result;
}

- (BOOL)isLikeOrEqualKeyValueQualifier:(EOKeyValueQualifier *)_qualifier {
  SEL op;
  
  if (![_qualifier isKindOfClass:[EOKeyValueQualifier class]])
    return NO;
  
  op = [_qualifier selector];
  if (SEL_EQ(op, EOQualifierOperatorLike))  return YES;
  if (SEL_EQ(op, EOQualifierOperatorEqual)) return YES;
  return NO;
}

- (NSException *)_unsupportedKeyValueQualifierError:(EOQualifier *)_qual {
  NSString     *reason;
  NSDictionary *ui = nil;
  
  reason = 
    @"SkyPersonDataSource: EOKeyValueQualifers are only supported with the "
    @"following operators: "
    @"(EOQualifierOperatorLike, EOQualifierOperatorEqual): ";
  reason = [reason stringByAppendingString:[_qual description]];
  
  return [NSException exceptionWithName:@"UnsupportedQualifierException"
                      reason:reason userInfo:ui];
}

- (NSException *)_unsupportedLikeQualifier:(EOKeyValueQualifier *)_qualifier {
  NSString     *reason;
  NSDictionary *ui = nil;
  
  reason = [NSString stringWithFormat:
              @"SkyCompanyDataSource: qualifier: asterisk "
              @"at end of value expected. e.g.: \"attr like '*value*'\" "
              @"(got: \"%@ like '%@'\")", 
              [_qualifier key], [_qualifier value]];
  return [NSException exceptionWithName:@"UnsupportedQualifierException"
                      reason:reason userInfo:ui];
}

- (id)_searchRecordForEntityNamed:(NSString *)_ename op:(NSString *)_cmp {
  id record;
  
  if (_ename == nil) return nil;
  record = [self->context runCommand:@"search::newrecord", 
                @"entity", _ename, nil];
  if ([_cmp isNotNull]) [record setComparator:_cmp];
  return record;
}

- (NSException *)_validateSearchRecordQualifier:(EOKeyValueQualifier *)qual
  rootQualifier:(EOQualifier *)_qualifier
{
  NSDictionary *ui   = nil;
  NSString     *hint = nil;
  
  if (![qual isKindOfClass:[EOKeyValueQualifier class]]) {
    hint = @"only supports EOKeyValueQualifiers "
      @"(optionally wrapped by an EOOrQualifier or EOAndQualifier)!";
  }
  else if ([_qualifier isKindOfClass:[EOOrQualifier class]] ||
           [_qualifier isKindOfClass:[EOAndQualifier class]]) {
    if (!SEL_EQ([qual selector], EOQualifierOperatorLike)) {
      hint = 
        @"EOAnd/OrQualifers are only supported with the following operators: "
        @"( EOQualifierOperatorLike )";
    }
  }
  if (hint == nil) return nil;
  
  hint = [NSString stringWithFormat:@"%@: %@", NSStringFromClass([self class]),
                     hint];
  return [NSException exceptionWithName:@"UnsupportedQualifierException"
                      reason:hint userInfo:ui];
}

- (NSArray *)searchRecordsFromQualifier:(EOQualifier *)_qualifier 
  fullTextSearchValues:(NSArray **)fullText_
{
  // TODO: split up this huge method!, needs serious cleanup
  NSMutableDictionary *valueToCompanyRecord;
  NSMutableArray *result         = nil;
  NSMutableArray *fullSearchKeys = nil;
  NSArray        *quals          = nil;
  BOOL           checkForAsterisk;
  NSString       *cmp;
  unsigned i, cnt;
  id company, address, info, pValue, phone;
  
  checkForAsterisk = YES;
  cmp = @"LIKE";
  
  if ([_qualifier isKindOfClass:[EOKeyValueQualifier class]] &&
      ![self isLikeOrEqualKeyValueQualifier:(id)_qualifier]) {
    return (id)[self _unsupportedKeyValueQualifierError:_qualifier];
  }
  
  quals = ([_qualifier respondsToSelector:@selector(qualifiers)])
    ? [(id)_qualifier qualifiers]
    : (NSArray *)[NSArray arrayWithObject:_qualifier];
  
  if ([_qualifier isKindOfClass:[EOKeyValueQualifier class]]) {
    cmp = (SEL_EQ([(id)_qualifier selector], EOQualifierOperatorEqual))
      ? @"EQUAL"
      : @"LIKE";
    checkForAsterisk = NO;
  }

  valueToCompanyRecord = nil;
  company = [self _searchRecordForEntityNamed:[self nameOfEntity] op:cmp];
  address = [self _searchRecordForEntityNamed:@"Address"          op:cmp];
  pValue  = [self _searchRecordForEntityNamed:@"CompanyValue"     op:cmp];
  info    = [self _searchRecordForEntityNamed:@"CompanyInfo"      op:cmp];
  phone   = [self _searchRecordForEntityNamed:@"Telephone"        op:cmp];
  
  for (i = 0, cnt = [quals count]; i < cnt; i++) {
    NSException         *exception;
    EOKeyValueQualifier *qual;
    NSString            *key;
    NSString            *value;
    NSArray             *fragments = nil;
    
    qual = [quals objectAtIndex:i];
    
    /* validate qualifier */
    
    exception = [self _validateSearchRecordQualifier:qual 
                      rootQualifier:_qualifier];
    if (exception != nil) [exception raise]; // TODO: do not raise
    
    key   = [self _mapKeyFromDocToEO:[qual key]];
    value = [[qual value] stringValue];
    
    /* check for fulltext search */
    
    if ([key isEqualToString:@"fullSearchString"]) {
      // TODO: check for just 'caseInsensitiveLike'! (or support non-lower)
      // TODO: check for '*x*'
      if (fullSearchKeys == nil) 
        fullSearchKeys = [[NSMutableArray alloc] initWithCapacity:8];
      if (value) [fullSearchKeys addObject:value];
      continue;
    }
    
    /* check for valid like searches */
    
    if (checkForAsterisk && ![value hasSuffix:@"*"]) {
      // TODO: do not raise
      [self errorWithFormat:@": value has no star-suffix: '%@'", value];
      exception = [self _unsupportedKeyValueQualifierError:(id)qual];
      [exception raise];
    }
    
    NSAssert1((key != nil), @"%s: key is nil", __PRETTY_FUNCTION__);
    
    /* process key fragments */

    fragments = [key componentsSeparatedByString:@"."];
    
    if ([fragments count] == 1) {
      if ([key isEqualToString:@"comment"]) {
        [info takeValue:value forKey:@"comment"];
      }
      else if (([[self nativeKeys] member:key])) {
	if ((company != nil) && ([company valueForKey:key] == nil)) {
	  /* everything is fine, key is not yet set */
	  [company takeValue:value forKey:key];
	}
        else if (company != nil && [key isEqualToString:@"keywords"]) {
          /* key is set, but its a 'keywords' CSV key => special handling */
          NSString *kw;
          
          kw = [company valueForKey:key];
          kw = [kw stringByAppendingString:@", "]; // MUST BE this separator
          kw = [kw stringByAppendingString:value];
          [company takeValue:kw forKey:key];
        }
	else {
	  /* key has already been set, need special treatment */
	  if (valueToCompanyRecord == nil) {
	    valueToCompanyRecord = 
	      [[NSMutableDictionary alloc] initWithCapacity:4];
	    
	    /* remember existing record, the key must be impossible */
	    [valueToCompanyRecord setObject:company forKey:@"\n\t\n"];
	    company = nil;
	  }
	  
	  /* now we group by value to ensure that we don't get DUPs */
	  
	  if ((company = [valueToCompanyRecord objectForKey:value]) == nil) {
	    /* create new search record */
	    company = [self _searchRecordForEntityNamed:[self nameOfEntity] 
			    op:cmp];
	    [valueToCompanyRecord setObject:company forKey:value];
	  }
	  [company takeValue:value forKey:key];
	  company = nil;
	}
      }
      else {
        [pValue takeValue:key   forKey:@"attribute"];
        [pValue takeValue:value forKey:@"value"];
      }
    }
    else if ([fragments count] > 1) {
      NSString *firstFrag;
      NSString *secondFrag;
      
      firstFrag  = [fragments objectAtIndex:0];
      secondFrag = [fragments objectAtIndex:1];

      if ([firstFrag isEqualToString:@"address"])
        [address takeValue:value forKey:secondFrag];
      else if ([firstFrag isEqualToString:@"phone"])
        [phone takeValue:value forKey:secondFrag];
      else {
       [self errorWithFormat:@"(%s): does not support key '%@'", 
               __PRETTY_FUNCTION__, key];
      }
    }
  }

  result = [NSMutableArray arrayWithCapacity:5];
  
  if (valueToCompanyRecord != nil) {
    [result addObjectsFromArray:[valueToCompanyRecord allValues]];
    [valueToCompanyRecord release]; valueToCompanyRecord = nil;
  }
  
  if (company != nil && ![result containsObject:company])
    [result addObject:company];
  
  if ([[[info searchDict] allKeys] isNotEmpty])
    [result addObject:info];
  if ([[[address searchDict] allKeys] isNotEmpty])
    [result addObject:address];
  if ([[[pValue searchDict] allKeys] isNotEmpty])
    [result addObject:pValue];
  if ([[[phone searchDict] allKeys] isNotEmpty])
    [result addObject:phone];
  
  if (fullText_ != NULL) {
    *fullText_ = [[fullSearchKeys copy] autorelease];
  }
  else if ([fullSearchKeys isNotEmpty]) {
    [self warnWithFormat:@"not processing fulltext searches: %@",
            fullSearchKeys];
  }

#if 0  
  [self logWithFormat:@"Converted qualifier %@ to search records: %@", 
	  _qualifier, result];
#endif
  
  return result;
}

- (NSArray *)_fetchObjectsForGlobalIDs:(NSArray *)_gids {
  /* used by resolver */
  NSArray *companies;

  companies = [self->context runCommand:
		    [[self commandDomain] 
		      stringByAppendingString:@"::get-by-globalid"],
                   @"gids", _gids, nil];
  
  return [self _morphEOsToDocuments:companies];
}

@end /* SkyCompanyDataSource */
