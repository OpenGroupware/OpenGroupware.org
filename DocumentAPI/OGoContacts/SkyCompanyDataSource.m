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

#include "SkyCompanyDataSource.h"
#include "SkyCompanyDocument.h"
#include "common.h"

@interface NSObject(SearchDict)
- (NSDictionary *)searchDict;
@end

@implementation SkyCompanyDataSource

+ (int)version {
  return [super version] + 0; /* v1 */
}
+ (void)initialize {
  NSAssert2([super version] == 1,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
}

- (NSNotificationCenter *)notificationCenter {
  static NSNotificationCenter *nc = nil;
  if (nc == nil) nc = [[NSNotificationCenter defaultCenter] retain];
  return nc;
}

- (void)_registerForChangeNotifications {
  [self logWithFormat:@"ERROR: subclasses should override this method!"];
}

- (id)initWithContext:(id)_context { // designated initializer
  if (_context == nil) {
#if DEBUG
    NSLog(@"WARNING(%s): missing context for datasource creation ..",
          __PRETTY_FUNCTION__);
#endif
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
  [self logWithFormat:@"ERROR(%s): subclasses must override this method!",
	  __PRETTY_FUNCTION__];
  return Nil;
}

- (NSSet *)nativeKeys {
  [self logWithFormat:@"ERROR(%s): subclasses must override this method!",
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
  [self logWithFormat:@"ERROR(%s): subclasses must override this method!",
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

- (NSString *)nameOfFullSearchCommand {
  [self logWithFormat:@"ERROR(%s): subclasses must override this method!",
	  __PRETTY_FUNCTION__];
  return nil;
}
- (NSString *)nameOfExtSearchCommand {
  [self logWithFormat:@"ERROR(%s): subclasses must override this method!",
	  __PRETTY_FUNCTION__];
  return nil;
}
- (NSString *)nameOfGetCommand {
  [self logWithFormat:@"ERROR(%s): subclasses must override this method!",
	  __PRETTY_FUNCTION__];
  return nil;
}
- (NSString *)nameOfDeleteCommand {
  [self logWithFormat:@"ERROR(%s): subclasses must override this method!",
	  __PRETTY_FUNCTION__];
  return nil;
}
- (NSString *)nameOfSetCommand {
  [self logWithFormat:@"ERROR(%s): subclasses must override this method!",
	  __PRETTY_FUNCTION__];
  return nil;
}
- (NSString *)nameOfNewCommand {
  [self logWithFormat:@"ERROR(%s): subclasses must override this method!",
	  __PRETTY_FUNCTION__];
  return nil;
}
- (NSString *)nameOfGetByGIDCommand {
  [self logWithFormat:@"ERROR(%s): subclasses must override this method!",
	  __PRETTY_FUNCTION__];
  return nil;
}
- (NSString *)nameOfEntity {
  [self logWithFormat:@"ERROR(%s): subclasses must override this method!",
	  __PRETTY_FUNCTION__];
  return nil;
}

/* notifications */

- (NSString *)nameOfNewCompanyNotification {
  [self logWithFormat:@"ERROR(%s): subclasses need to override this method!",
	  __PRETTY_FUNCTION__];
  return nil;
}
- (NSString *)nameOfUpdatedCompanyNotification {
  [self logWithFormat:@"ERROR(%s): subclasses need to override this method!",
	  __PRETTY_FUNCTION__];
  return nil;
}
- (NSString *)nameOfDeletedCompanyNotification {
  [self logWithFormat:@"ERROR(%s): subclasses need to override this method!",
	  __PRETTY_FUNCTION__];
  return nil;
}

/* commands */

- (NSArray *)_performFullTextSearch:(NSString *)_txt fetchLimit:(int)_limit {
  return [self->context runCommand:[self nameOfFullSearchCommand],
              @"maxSearchCount", [NSNumber numberWithInt:_limit],
              @"searchString",   _txt, nil];
}
- (NSArray *)_performFullTextSearches:(NSArray *)_txts
  isAndMode:(BOOL)_isAndMode fetchLimit:(int)_limit 
{
  // TODO: ensure that we have no dups in _txts!
  return [self->context runCommand:[self nameOfFullSearchCommand],
              @"maxSearchCount", [NSNumber numberWithInt:_limit],
              @"searchStrings",   _txts, 
              @"isAndMode", [NSNumber numberWithBool:_isAndMode],
              nil];
}

/* fetching */

- (NSArray *)_fetchObjectsWithKeyValueQualifier:(EOKeyValueQualifier *)_q
  fetchLimit:(int)_fetchLimit;
{
  NSString *key  = nil;
  id       value = nil;
  
  if ((key = [self _mapKeyFromDocToEO:[_q key]]) == nil) {
    [self logWithFormat:@"ERROR(%s): key is nil!", __PRETTY_FUNCTION__];
    return nil;
  }
  
  if ((value = [[_q value] stringValue]) == nil)
    return [NSArray array];
  
  if ([key isEqualToString:@"fullSearchString"])
    return [self _performFullTextSearch:value fetchLimit:_fetchLimit];
  
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
      
    if ([companies count] > 0)
      companies = [self _pkeyDictsForCompanies:companies];
      
    if (shouldMakeGidsFromIds_) *shouldMakeGidsFromIds_ = YES;
    return companies;
  }
  
  /* perform a regular fetch */
  companies = [self _fetchObjectsWithKeyValueQualifier:_kvq
                    fetchLimit:fetchLimit];
  return companies;
}

- (NSArray *)_primaryFetchCompaniesForQualifier:(EOQualifier *)qualifier 
  fetchLimit:(int)fetchLimit
  shouldMakeGidsFromIds:(BOOL *)shouldMakeGidsFromIds_
{
  if (qualifier == nil)
    return nil;
  
  if ([qualifier isKindOfClass:[EOKeyValueQualifier class]]) {
    return [self _fetchCompaniesForKeyValueQualifier:(id)qualifier
                 fetchLimit:fetchLimit
                 shouldMakeGidsFromIds:shouldMakeGidsFromIds_];
  }
  
  if ([qualifier isKindOfClass:[EOOrQualifier class]]) {
    return [self _fetchCompaniesWithQualifier:qualifier
                 operator:@"OR" fetchLimit:fetchLimit];
  }
  if ([qualifier isKindOfClass:[EOAndQualifier class]]) {
    return [self _fetchCompaniesWithQualifier:qualifier
                 operator:@"AND" fetchLimit:fetchLimit];
  }
  
  // returns the exception
  return (id)[self _handleUnsupportedQualifier:qualifier];
}

- (NSArray *)_sortResultDocuments:(NSArray *)result {
  NSArray *sortOrderings;
  
  if ((sortOrderings = [self->fetchSpecification sortOrderings]) != nil)
    result = [result sortedArrayUsingKeyOrderArray:sortOrderings];
  
  return result;
}

- (NSArray *)fetchObjects {
  // TODO: split up method
  EOQualifier  *qualifier  = nil;
  NSArray      *companies  = nil;
  NSDictionary *hints      = nil;
  BOOL         fetchIds    = NO;
  BOOL         fetchGids   = NO;
  int          fetchLimit  = 0;
  BOOL         shouldMakeGidsFromIds = YES;
  NSArray      *result;
  
  qualifier  = [self->fetchSpecification qualifier];
  fetchLimit = [self->fetchSpecification fetchLimit];

  if (fetchLimit <= 0) {
    fetchLimit =
      [[self->context userDefaults] integerForKey:@"LSMaxSearchCount"];
  }
  
  hints      = [self->fetchSpecification hints];
  fetchIds   = [[hints objectForKey:@"fetchIds"] boolValue];
  fetchGids  = [[hints objectForKey:@"fetchGlobalIDs"] boolValue];
  
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
  
  return result ? result : [NSArray array];
}

- (id)createObject {
  // TODO: should rather set -lastException?
  [self logWithFormat:@"ERROR(%s): subclasses must override this method!",
	  __PRETTY_FUNCTION__];
  return nil;
}

- (void)insertObject:(id)_obj {
  id  dict = [_obj asDict];

  dict = [self->context runCommand:[self nameOfNewCommand] arguments:dict];

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
  [self->context runCommand:[self nameOfSetCommand] arguments:args];
  
  [self postDataSourceChangedNotification];
  [[self notificationCenter]
         postNotificationName:[self nameOfUpdatedCompanyNotification]
         object:_obj];
}

- (void)deleteObject:(id)_obj {
  NSDictionary *dict = [_obj asDict];
  
  //[dict takeValue:[NSNumber numberWithBool:YES] forKey:@"reallyDelete"];
  [self->context runCommand:[self nameOfDeleteCommand] arguments:dict];
  [self postDataSourceChangedNotification];
  
  [[self notificationCenter]
         postNotificationName:[self nameOfDeletedCompanyNotification]
         object:_obj];
}

@end /* SkyCompanyDataSource */

@implementation SkyCompanyDataSource(PrivateMethodes)

- (NSArray *)_attributes {
  NSArray        *attributes    = nil;
  NSMutableArray *fSpecAttrs    = nil;
  BOOL           didChangeFSpec = NO;

  attributes = [[self->fetchSpecification hints] objectForKey:@"attributes"];
  fSpecAttrs = [[NSMutableArray alloc] initWithArray:attributes];

  if (attributes == nil)
    return nil;
  else {
    NSEnumerator *attrEnum;
    NSArray      *attrs;
    NSString     *attr;

    attrs      = attributes;
    attrEnum   = [attrs objectEnumerator];
    attributes = [NSMutableArray arrayWithCapacity:([attrs count] + 1)];
    
    while ((attr = [attrEnum nextObject]))
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
  NSMutableArray *gids;
  int            i, cnt;
  
  cnt  = [_ids count];
  gids = [NSMutableArray arrayWithCapacity:(cnt + 1)];
  
  for (i = 0; i < cnt; i++) {
    id obj;
    id values[1];
    EOGlobalID *gid;
    
    obj       = [_ids objectAtIndex:i];
    values[0] = [NSNumber numberWithInt:
                          [[obj valueForKey:@"companyId"] intValue]];
    gid = [EOKeyGlobalID globalIDWithEntityName:[self nameOfEntity]
                         keys:values keyCount:1 zone:NULL];
    [gids addObject:gid];
  }
  return gids;  
}

- (NSArray *)_getEOsFromGIDs:(NSArray *)_gids attributes:(NSArray *)_attrs {
  NSArray *result;
  
  if (_attrs == nil) {
    result = [self->context runCommand:[self nameOfGetByGIDCommand],
                  @"gids", _gids, nil];
  }
  else {
    result = [self->context runCommand:[self nameOfGetByGIDCommand],
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
  NSArray *searchRecords;
  NSArray *result = nil, *fullResults = nil;
  NSArray *fullSearchStrings = nil;
  
  searchRecords = [self searchRecordsFromQualifier:_qual
                        fullTextSearchValues:&fullSearchStrings];
  if ([searchRecords isKindOfClass:[NSException class]])
    return searchRecords;
  
  if ([fullSearchStrings count] == 1) {
    /* a single fulltext search */
    fullResults = [self _performFullTextSearch:
                          [fullSearchStrings objectAtIndex:0]
                        fetchLimit:_fetchLimit];
  }
  else if ([fullSearchStrings count] > 0) {
    /* multiple fulltext keys */
#if 0
    [self debugWithFormat:@"searching for multiple fulltext keys: %@ (%@)", 
            fullSearchStrings, _qual];
#endif
    fullResults = [self _performFullTextSearches:fullSearchStrings
                        isAndMode:[_qual isKindOfClass:[EOAndQualifier class]]
                        fetchLimit:_fetchLimit];
  }
  else if ([searchRecords count] > 0) {
    result = [self->context runCommand:[self nameOfExtSearchCommand],
                  @"operator",       _operator,
                  @"searchRecords",  searchRecords,
                  @"fetchIds",       [NSNumber numberWithBool:YES],
                  @"maxSearchCount", [NSNumber numberWithInt:_fetchLimit],
                  nil];
  }
  
  // TODO: process context restrictions

  if (result != nil && fullResults != nil) {
    [self logWithFormat:
            @"ERROR: cannot do fulltext search at the same time "
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
    @"SkyPersonDataSource: EOKeyValueQualifers are only supported by "
    @"following operators: "
    @"(EOQualifierOperatorLike, EOQualifierOperatorEqual)";
  
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
  else if ([_qualifier isKindOfClass:[EOOrQualifier class]] &&
           !SEL_EQ([qual selector], EOQualifierOperatorLike)) {
    hint = 
      @"EOOrQualifers are only supported with the following operators: "
      @"( EOQualifierOperatorLike )";
  }
  else if ([_qualifier isKindOfClass:[EOAndQualifier class]] &&
             !SEL_EQ([qual selector], EOQualifierOperatorLike)) {
    hint = 
      @"EOAndQualifers are only supported with the following operators: "
      @"( EOQualifierOperatorLike )";
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
    : [NSArray arrayWithObject:_qualifier];
  
  cnt = [quals count];

  if ([_qualifier isKindOfClass:[EOKeyValueQualifier class]]) {
    cmp = (SEL_EQ([(id)_qualifier selector], EOQualifierOperatorEqual))
      ? @"EQUAL"
      : @"LIKE";
    checkForAsterisk = NO;
  }
  
  company = [self _searchRecordForEntityNamed:[self nameOfEntity] op:cmp];
  address = [self _searchRecordForEntityNamed:@"Address"          op:cmp];
  pValue  = [self _searchRecordForEntityNamed:@"CompanyValue"     op:cmp];
  info    = [self _searchRecordForEntityNamed:@"CompanyInfo"      op:cmp];
  phone   = [self _searchRecordForEntityNamed:@"Telephone"        op:cmp];
  
  for (i = 0; i < cnt; i++) {
    NSException         *exception;
    EOKeyValueQualifier *qual;
    NSString            *key;
    NSString            *value;
    NSArray             *fragments = nil;
    
    qual = [quals objectAtIndex:i];
    
    /* validate qualifier */
    
    exception = [self _validateSearchRecordQualifier:qual 
                      rootQualifier:_qualifier];
    if (exception) [exception raise]; // TODO: do not raise
    
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
      exception = [self _unsupportedKeyValueQualifierError:(id)qual];
      [exception raise];
    }
    
    NSAssert1((key != nil), @"%s: key is nil", __PRETTY_FUNCTION__);
    
    /* process key fragments */

    fragments = [key componentsSeparatedByString:@"."];
    
    if ([fragments count] == 1) {
      if ([key isEqualToString:@"comment"])
        [info takeValue:value forKey:@"comment"];
      else if (([[self nativeKeys] member:key]))
        [company takeValue:value forKey:key];
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
       [self logWithFormat:@"ERROR(%s): does not support key '%@'", 
               __PRETTY_FUNCTION__, key];
      }
    }
  }

  result = [NSMutableArray arrayWithCapacity:5];
  [result addObject:company];
  
  if ([[[info searchDict] allKeys] count] > 0)
    [result addObject:info];
  if ([[[address searchDict] allKeys] count] > 0)
    [result addObject:address];
  if ([[[pValue searchDict] allKeys] count] > 0)
    [result addObject:pValue];
  if ([[[phone searchDict] allKeys] count] > 0)
    [result addObject:phone];
  
  if (fullText_) {
    *fullText_ = [[fullSearchKeys copy] autorelease];
  }
  else if ([fullSearchKeys count] > 0) {
    [self logWithFormat:@"WARNING: not processing fulltext searches: %@",
            fullSearchKeys];
  }
  return result;
}

- (NSArray *)_fetchObjectsForGlobalIDs:(NSArray *)_gids {
  /* used by resolver */
  NSArray *companies;

  companies = [self->context runCommand:[self nameOfGetByGIDCommand],
                   @"gids", _gids, nil];
  
  return [self _morphEOsToDocuments:companies];
}

@end /* SkyCompanyDataSource(PrivateMethodes) */
