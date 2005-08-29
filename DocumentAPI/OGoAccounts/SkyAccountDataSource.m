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

#include "SkyAccountDataSource.h"
#include "SkyAccountDocument.h"
#include "common.h"

#define SkyUpdatedPersonNotification @"SkyUpdatedPersonNotification"

@interface NSObject(SearchRecord)
- (NSDictionary *)searchDict;
- (NSDictionary *)asDict;
- (void)_setGlobalID:(EOGlobalID *)_gid;
@end

@interface SkyAccountDataSource(PrivateMethodes)

- (NSArray *)_morphEOsToDocuments:(NSArray *)_eos;
- (NSArray *)_fetchObjectsForGlobalIDs:(NSArray *)_gids;
- (NSArray *)_fetchAccountsWithQualifier:(EOQualifier *)_qual
  operator:(NSString *)_operator fetchLimit:(unsigned int)_fetchLimit
  fetchIDs:(BOOL)_fetchIDs;
- (NSArray *) _fetchAccountsByGlobalIdQualifier:(EOQualifier *)_qualifier
  fetchLimit:(unsigned int)_fetchLimit fetchIDs:(BOOL)_fetchIDs;

@end /* SkyAccountDataSource(PrivateMethodes) */

@implementation SkyAccountDataSource

static NSSet *NativeKeys = nil;

+ (int)version {
  return [super version] + 0; /* v1 */
}

+ (void)initialize {
  NSAssert2([super version] == 1,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
}

- (void)_registerForNotifications {
  NSNotificationCenter *nc;

  nc = [NSNotificationCenter defaultCenter];      
    
  [nc addObserver:self selector:@selector(accountWasChanged:)
      name:SkyNewAccountNotification object:nil];
  [nc addObserver:self selector:@selector(accountWasChanged:)
      name:SkyUpdatedAccountNotification object:nil];
  [nc addObserver:self selector:@selector(accountWasChanged:)
      name:SkyDeletedAccountNotification object:nil];
}

- (void)_setupNativeKeys {
  EOModel *model;
  
  if (NativeKeys != nil)
    return;

  model      = [[[self->context valueForKey:LSDatabaseKey] adaptor] model];
  NativeKeys = [[NSSet alloc] initWithArray:
                           [[[model entityNamed:@"Person"] attributes]
                           map:@selector(name)]];
}

- (id)initWithContext:(LSCommandContext *)_context { // designated initializer
  if (_context == nil) {
#if DEBUG
    [self logWithFormat:
	    @"WARNING(%s): missing context for datasource creation ..",
          __PRETTY_FUNCTION__];
#endif
    [self release];
    return nil;
  }
  
  if ((self = [super init]) != nil) {
    ASSIGN(self->context, _context);
    
    [self _registerForNotifications];
    [self _setupNativeKeys];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self->context            release];
  [self->fetchSpecification release];
  [super dealloc];
}

/* notifications */

- (void)accountWasChanged:(id)_obj {
  [self postDataSourceChangedNotification];
}

/* keys */

- (NSSet *)nativeKeys {
  return NativeKeys;
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

/* operation */

- (NSArray *)fetchObjects {
  EOQualifier  *qualifier;
  NSArray      *accounts;
  NSDictionary *hints;
  BOOL         fetchIds;
  int          fetchLimit;

  accounts   = nil;
  qualifier  = [self->fetchSpecification qualifier];
  fetchLimit = [self->fetchSpecification fetchLimit];

  if (fetchLimit <= 0) {
    fetchLimit =
      [[self->context userDefaults] integerForKey:@"LSMaxSearchCount"];
  }
  
  hints      = [self->fetchSpecification hints];
  fetchIds   = [[hints objectForKey:@"fetchIds"] boolValue];

  if (qualifier == nil)
    ; // do nothing
  else if ([qualifier isKindOfClass:[EOKeyValueQualifier class]] &&
           [[(id)qualifier key] isEqualToString:@"globalID"]) {
    accounts = [self _fetchAccountsByGlobalIdQualifier:qualifier
                     fetchLimit:fetchLimit
                     fetchIDs:fetchIds];
  }
  else if ([qualifier isKindOfClass:[EOKeyValueQualifier class]] ||
           [qualifier isKindOfClass:[EOAndQualifier class]]) {
    accounts = [self _fetchAccountsWithQualifier:qualifier
                    operator:@"AND"
                    fetchLimit:fetchLimit
                    fetchIDs:fetchIds];
  }
  else if ([qualifier isKindOfClass:[EOOrQualifier class]]) {
    accounts = [self _fetchAccountsWithQualifier:qualifier
                    operator:@"OR"
                    fetchLimit:fetchLimit
                    fetchIDs:fetchIds];
  }
  else {
    NSException *exception;
    NSString    *hint;

    hint = @"SkyAccountDataSource: only supports following qualifiers: "
           @" (EOKeyValueQualifier, EOOrQualifier, EOAndQualifier )!";
    
    exception = [[NSException alloc] initWithFormat:hint];
    [exception raise];
  }

  if (accounts == nil)
    accounts = [NSArray array];
  
  if (fetchIds)
    return accounts; // return ids
  
  {
    NSArray *result;
    NSArray *sortOrderings;
    
    result = [self _morphEOsToDocuments:accounts];
    
    if ((sortOrderings = [self->fetchSpecification sortOrderings]) != nil)
      result = [result sortedArrayUsingKeyOrderArray:sortOrderings];

    return result;
  }
}

- (id)createObject {
  return [[[SkyAccountDocument alloc] initWithContext:self->context]
                               autorelease];
}

- (void)insertObject:(id)_obj {
  NSDictionary *dict;
  
  if (_obj == nil)
    return;
  
  dict = [self->context runCommand:@"account::new" arguments:[_obj asDict]];

  [_obj _setGlobalID:[dict valueForKey:@"globalID"]];
  [_obj takeValue:[dict valueForKey:@"number"] forKey:@"number"];
  
  [self postDataSourceChangedNotification];
}

- (void)updateObject:(id)_obj {
  NSDictionary *args;
  
  if (_obj == nil)
    return;
  
  if (![_obj isComplete]) {
    // TODO: throw exception? or complete object?
    [self debugWithFormat:@"object to be updated is not complete: %@", _obj];
    return;
  }
  
  args = [_obj asDict];

  [self->context runCommand:@"account::set" arguments:args];

  [self postDataSourceChangedNotification];
  [[NSNotificationCenter defaultCenter]
                         postNotificationName:SkyUpdatedPersonNotification
                         object:_obj];
}

/* PrivateMethodes */

- (NSArray *)_morphEOsToDocuments:(NSArray *)_eos {
  unsigned       i, count;
  NSMutableArray *result;

  if (_eos == nil)                 return nil;
  if ((count = [_eos count]) == 0) return [NSArray array];

  result = [NSMutableArray arrayWithCapacity:(count + 1)];
  
  for (i = 0; i < count; i++) {
    id doc, account;
    
    account = [_eos objectAtIndex:i];
    doc     = [[SkyAccountDocument alloc] initWithAccount:account
                                          dataSource:self];
    [result addObject:doc];
    ASSIGN(doc, nil);
  }
  return result;
}

- (id)_newSearchRecordForEntityNamed:(NSString *)_ename op:(NSString *)_op {
  id rec;
  
  rec = [self->context runCommand:@"search::newrecord", @"entity",_ename,nil];
  [rec setComparator:_op];
  return rec;
}

- (NSString *)_canHandleSubQualifier:(EOKeyValueQualifier *)qual 
  qualifier:(EOQualifier *)_qualifier
{
  if (![qual isKindOfClass:[EOKeyValueQualifier class]]) {
    return @"SkyAccountDataSource: only supports EOKeyValueQualifier's "
           @"(possibly wrapped by an EOOrQualifier or EOAndQualifier)!";
  }
  
  if ([_qualifier isKindOfClass:[EOOrQualifier class]] &&
      !SEL_EQ([qual selector], EOQualifierOperatorLike)) {
    return @"SkyAccountDataSource: EOOrQualifers are only supported by "
           @"following operators: "
           @"( EOQualifierOperatorLike)";
  }
  if ([_qualifier isKindOfClass:[EOAndQualifier class]] &&
      !SEL_EQ([qual selector], EOQualifierOperatorLike)) {
    return @"SkyAccountDataSource: EOAndQualifers are only supported by "
           @"following operators: "
           @"( EOQualifierOperatorLike)";
  }
  return nil;
}

- (NSArray *)searchRecordsFromQualifier:(EOQualifier *)_qualifier {
  NSMutableArray *result;
  NSArray        *quals;
  NSString       *cmp;
  BOOL           checkForAsterisk;
  int            i, cnt;
  id      company, address, info, pValue, phone;

  checkForAsterisk = YES;
  cmp              = @"LIKE";
  
  if ([_qualifier isKindOfClass:[EOKeyValueQualifier class]] &&
      !SEL_EQ([(id)_qualifier selector], EOQualifierOperatorLike) &&
      !SEL_EQ([(id)_qualifier selector], EOQualifierOperatorEqual)) {
    NSException *exception;
    NSString    *hint;
    
    hint = @"SkyAccountDataSource: EOKeyValueQualifers are only supported by "
           @"following operators: "
           @"( EOQualifierOperatorLike, EOQualifierOperatorEqual)";
    
    exception = [[NSException alloc] initWithFormat:hint];
    [exception raise];
  }

  quals = ([_qualifier respondsToSelector:@selector(qualifiers)])
    ? [(id)_qualifier qualifiers]
    : [NSArray arrayWithObject:_qualifier];

  if ([_qualifier isKindOfClass:[EOKeyValueQualifier class]]) {
    cmp = (SEL_EQ([(id)_qualifier selector], EOQualifierOperatorEqual))
      ? @"EQUAL"
      : @"LIKE";
           
    checkForAsterisk = NO;
  }
  
  cnt      = [quals count];
  company  = [self _newSearchRecordForEntityNamed:@"Person"       op:cmp];
  address  = [self _newSearchRecordForEntityNamed:@"Address"      op:cmp];
  pValue   = [self _newSearchRecordForEntityNamed:@"CompanyValue" op:cmp];
  info     = [self _newSearchRecordForEntityNamed:@"CompanyInfo"  op:cmp];
  phone    = [self _newSearchRecordForEntityNamed:@"Telephone"    op:cmp];
  
  for (i = 0; i < cnt; i++) {
    NSException         *exception;
    EOKeyValueQualifier *qual;
    NSString            *errorString, *key, *value;
    NSArray             *fragments;

    exception = nil;
    errorString      = nil;
    qual = [quals objectAtIndex:i];

    errorString = [self _canHandleSubQualifier:qual qualifier:_qualifier];
    
    key   = [qual key];
    value = [[qual value] stringValue];

    if (checkForAsterisk && ![value hasSuffix:@"*"]) {
      errorString = [NSString stringWithFormat:
              @"SkyAccountDataSource: qualifier: asterisk "
              @"at end of value expeceted. e.g.: \"attr like '*value*'\" "
              @"(you did: \"%@ like '%@'\")", key, value];
    }
    
    if (errorString != nil) {
      exception = [[NSException alloc] initWithFormat:errorString];
      [exception raise];
    }
    
    NSAssert1((key != nil), @"%s: key is nil", __PRETTY_FUNCTION__);
    
    fragments = [key componentsSeparatedByString:@"."];
    if ([fragments count] == 0)
      continue;
    
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
      NSString *firstFrag, *secondFrag;
      
      firstFrag  = [fragments objectAtIndex:0];
      secondFrag = [fragments objectAtIndex:1];
      
      if ([firstFrag isEqualToString:@"address"])
        [address takeValue:value forKey:secondFrag];
      else if ([firstFrag isEqualToString:@"phone"])
        [phone takeValue:value forKey:secondFrag];
      else
        NSLog(@"Warning! %s: does not support '%@'", __PRETTY_FUNCTION__, key);
    }
  }
  
  result = [NSMutableArray arrayWithCapacity:5];
  [result addObject:company];
  if ([[[info    searchDict] allKeys] count] > 0) [result addObject:info];
  if ([[[address searchDict] allKeys] count] > 0) [result addObject:address];
  if ([[[pValue  searchDict] allKeys] count] > 0) [result addObject:pValue];
  if ([[[phone   searchDict] allKeys] count] > 0) [result addObject:phone];
  return result;
}

- (NSArray *)_fetchAccountsByGlobalIdQualifier:(EOQualifier *)_qualifier
  fetchLimit:(unsigned int)_fetchLimit
  fetchIDs:(BOOL)_fetchIDs
{
  id value;
  
  if (_fetchIDs) {
    NSLog(@"WARNING(%s): _fetchIds is not supported (qualifier is '%@')",
          __PRETTY_FUNCTION__,
          _qualifier);
          
    return [NSArray array];
  }

  value = [(EOKeyValueQualifier *)_qualifier value];
    
  if (![value isKindOfClass:[NSArray class]])
    value = [NSArray arrayWithObject:value];
  
  return [self->context runCommand:@"person::get-by-globalid", 
	      @"gids", value, nil];
}


- (NSArray *)_fetchAccountsWithQualifier:(EOQualifier *)_qual
  operator:(NSString *)_operator
  fetchLimit:(unsigned int)_fetchLimit
  fetchIDs:(BOOL)_fetchIDs
{
  NSMutableArray *gids;
  NSArray        *ids;
  int            i, cnt;

  ids = [self->context runCommand:@"account::extended-search",
             @"operator", _operator,
             @"searchRecords",  [self searchRecordsFromQualifier:_qual],
             @"fetchIds",       [NSNumber numberWithBool:YES],
             @"maxSearchCount", [NSNumber numberWithInt:_fetchLimit],
             nil];

  if (_fetchIDs) return ids;
  
  cnt  = [ids count];
  gids = [[NSMutableArray alloc] initWithCapacity:cnt];
  
  for (i = 0; i < cnt; i++) {
    id         obj, values[1];
    EOGlobalID *gid;

    obj       = [ids objectAtIndex:i];
    values[0] = [obj valueForKey:@"companyId"];
    gid       = [EOKeyGlobalID globalIDWithEntityName:@"Person"
                               keys:values keyCount:1 zone:NULL];
    [gids addObject:gid];
  }
  [gids autorelease];
  
  return [self->context runCommand:@"person::get-by-globalid",
              @"gids", gids,
              nil];
}

- (NSArray *)_repairGlobalIDs:(NSArray *)_gids {
  NSMutableArray *gids;
  NSEnumerator   *e;
  id             one;

  gids = [NSMutableArray array];
  e    = [_gids objectEnumerator];

  while ((one = [e nextObject])) {
    if ([[one entityName] isEqualToString:@"Account"]) {
      one = [EOKeyGlobalID globalIDWithEntityName:@"Person"
                           keys:[one keyValues] keyCount:[one keyCount]
                           zone:NULL];
    }
    [gids addObject:one];
  }
  return [[gids copy] autorelease];
}

- (NSArray *)_fetchObjectsForGlobalIDs:(NSArray *)_gids {
  /* used by resolver */
  NSArray *account;
  NSArray *gids;

  gids    = [self _repairGlobalIDs:_gids];
  account = [self->context runCommand:@"person::get-by-globalid",
                   @"gids", gids, nil];
  
  return [self _morphEOsToDocuments:account];
}

@end /* SkyAccountDataSource */

#include <EOControl/EOKeyGlobalID.h>

@implementation SkyAccountDocumentGlobalIDResolver

- (BOOL)canResolveGlobalID:(EOGlobalID *)_gid
  withDocumentManager:(id<SkyDocumentManager>)_dm
{
  static Class EOKeyGlobalIDClass = Nil;

  if (EOKeyGlobalIDClass == Nil)
    EOKeyGlobalIDClass = [EOKeyGlobalID class];

  if ([_gid class] != EOKeyGlobalIDClass)
    return NO;
  
  if (![[_gid entityName] isEqualToString:@"Account"])
    return NO;
  
  return YES;
}

- (NSArray *)resolveGlobalIDs:(NSArray *)_gids
  withDocumentManager:(id<SkyDocumentManager>)_dm
{
  SkyAccountDataSource *ds;
  
  if (_gids == nil)
    return nil;

  if ([_gids count] == 0)
    return [NSArray array];
  
  ds = [[SkyAccountDataSource alloc] initWithContext:[_dm context]];

  if (ds == nil)
    return nil;

  [ds autorelease];

  return [ds _fetchObjectsForGlobalIDs:_gids];
}

@end /* SkyAccountDocumentGlobalIDResolver */
