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

#include "SkyTeamDataSource.h"
#include "SkyTeamDocument.h"
#include "common.h"

@interface SkyTeamDataSource(NSObject)
- (Class)documentClass;
- (NSDictionary*)searchDict;
@end

@interface SkyTeamDataSource(PrivateMethodes)

- (NSArray *)_morphEOsToDocuments:(NSArray *)_eos;
- (NSArray *)_fetchObjectsForGlobalIDs:(NSArray *)_gids;
- (NSArray *)_fetchTeamsWithQualifier:(EOQualifier *)_qual
                               operator:(NSString *)_operator
                             fetchLimit:(unsigned int)_fetchLimit
                               fetchIDs:(BOOL)_fetchIDs;
@end /* SkyTeamDataSource(PrivateMethodes) */

@implementation SkyTeamDataSource

+ (int)version {
  return [super version] + 0; /* v1 */
}

+ (void)initialize {
  NSAssert2([super version] == 1,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
}

static NSSet *nativeKeys = nil;

- (id)initWithContext:(id)_context { // designated initializer
  if (_context == nil) {
#if DEBUG
    NSLog(@"WARNING(%s): missing context for datasource creation ..",
          __PRETTY_FUNCTION__);
#endif
    RELEASE(self);
    return nil;
  }
  
  if ((self = [super init])) {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    [nc addObserver:self
        selector:@selector(teamWasChanged:)
        name:SkyNewTeamNotification
        object:nil];

    [nc addObserver:self
        selector:@selector(teamWasChanged:)
        name:SkyUpdatedTeamNotification
        object:nil];

    [nc addObserver:self
        selector:@selector(teamWasChanged:)
        name:SkyDeletedTeamNotification
        object:nil];
    
    ASSIGN(self->context, _context);

    if (nativeKeys == nil) {
      EOModel *model;
      
      model = [[[self->context valueForKey:LSDatabaseKey] adaptor] model];
      
      nativeKeys = [[NSSet allocWithZone:[self zone]] initWithArray:
                           [[[model entityNamed:@"Team"] attributes]
                           map:@selector(name)]];
    }
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  RELEASE(self->context);
  RELEASE(self->fetchSpecification);
  
  [super dealloc];
}
#endif

- (void)teamWasChanged:(id)_obj {
  [self postDataSourceChangedNotification];
}

- (NSSet *)nativeKeys {
  return nativeKeys;
}

- (void)setFetchSpecification:(EOFetchSpecification *)_fSpec {
  if (![self->fetchSpecification isEqual:_fSpec]) {
    ASSIGNCOPY(self->fetchSpecification, _fSpec);
    [self postDataSourceChangedNotification];
  }
}

- (EOFetchSpecification *)fetchSpecification {
  return AUTORELEASE([self->fetchSpecification copy]);
}

- (id)context {
  return self->context;
}

- (NSArray *)fetchObjects {
  EOQualifier  *qualifier = nil;
  NSArray      *teams     = nil;
  NSDictionary *hints     = nil;
  BOOL         fetchIds   = NO;
  int          fetchLimit = 0;

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
    
    NSAssert2(fetchIds == NO,
              @"%s: does not support fetchIds=YES fir qualifier (%@)!",
              __PRETTY_FUNCTION__,
              qualifier);
    
    teams = [(EOKeyValueQualifier *)qualifier value];
    if (![teams isKindOfClass:[NSArray class]])
      teams = [NSArray arrayWithObject:teams];

    if (fetchLimit > 0 && [teams count] > fetchLimit)
      teams = [teams subarrayWithRange:NSMakeRange(0, fetchLimit)];

    teams = [self _fetchObjectsForGlobalIDs:teams]; // already docs ..
    {
      NSArray *sortOrderings;
      if ((sortOrderings = [self->fetchSpecification sortOrderings]) != nil)
        teams = [teams sortedArrayUsingKeyOrderArray:sortOrderings];

    }
    return teams;
  }
  else if ([qualifier isKindOfClass:[EOKeyValueQualifier class]] ||
           [qualifier isKindOfClass:[EOAndQualifier class]]) {
    teams = [self _fetchTeamsWithQualifier:qualifier
                  operator:@"AND"
                  fetchLimit:fetchLimit
                  fetchIDs:fetchIds];
  }
  else if ([qualifier isKindOfClass:[EOOrQualifier class]]) {
    teams = [self _fetchTeamsWithQualifier:qualifier
                  operator:@"OR"
                  fetchLimit:fetchLimit
                  fetchIDs:fetchIds];
  }
  else {
    NSException *exception;
    NSString    *hint;

    hint = @"SkyTeamDataSource: only supports following qualifiers: "
           @" (EOKeyValueQualifier, EOOrQualifier, EOAndQualifier )!";
    
    exception = [[NSException alloc] initWithFormat:hint];
    [exception raise];
  }

  if (teams == nil)
    teams = [NSArray array];
  
  if (fetchIds)
    return teams; // return ids

  {
    NSArray *result;
    NSArray *sortOrderings;
    
    result = [self _morphEOsToDocuments:teams];
    
    if ((sortOrderings = [self->fetchSpecification sortOrderings]) != nil)
      result = [result sortedArrayUsingKeyOrderArray:sortOrderings];

    return result;
  }
}

- (void)updateObject:(id)_obj {
  [self->context runCommand:@"team::set",
       @"object", [_obj asEO],
       nil];
  [self postDataSourceChangedNotification];
}

- (Class)documentClass {
  static Class docClass = nil;
  if (docClass == nil)
    docClass = [SkyTeamDocument class];
  return docClass;
}

@end /* SkyTeamDataSource */


@implementation SkyTeamDataSource(PrivateMethodes)

- (NSArray *)_morphEOsToDocuments:(NSArray *)_eos {
  unsigned i, count;
  NSMutableArray *result;

  if (_eos == nil)                 return nil;
  if ((count = [_eos count]) == 0) return [NSArray array];

  result = [NSMutableArray arrayWithCapacity:(count + 1)];
  
  for (i = 0; i < count; i++) {
    id doc;
    id team;
    
    team = [_eos objectAtIndex:i];
    
    doc = [[[self documentClass] alloc] initWithTeam:team dataSource:self];
    [result addObject:doc];
    RELEASE(doc);
  }
  return result;
}

- (NSArray *)searchRecordsFromQualifier:(EOQualifier *)_qualifier {
  NSMutableArray *result   = nil;
  NSArray        *quals    = nil;
  BOOL    checkForAsterisk = YES;
  NSString       *cmp      = @"LIKE";
  int     i, cnt;
  id      company;
  id      address;
  id      info;
  id      pValue;
  id      phone;

  if ([_qualifier isKindOfClass:[EOKeyValueQualifier class]] &&
      !SEL_EQ([(id)_qualifier selector], EOQualifierOperatorLike) &&
      !SEL_EQ([(id)_qualifier selector], EOQualifierOperatorEqual)) {
    NSException *exception;
    NSString    *hint;
    
    hint = @"SkyTeamDataSource: EOKeyValueQualifers are only supported by "
           @"following operators: "
           @"( EOQualifierOperatorLike, EOQualifierOperatorEqual)";
    
    exception = [[NSException alloc] initWithFormat:hint];
    [exception raise];
  }

  quals = ([_qualifier respondsToSelector:@selector(qualifiers)])
    ? [(id)_qualifier qualifiers]
    : (NSArray *)[NSArray arrayWithObject:_qualifier];

  cnt    = [quals count];

  company  = [self->context runCommand:@"search::newrecord",
                 @"entity", @"Team",  nil];
  address = [self->context runCommand:@"search::newrecord",
                 @"entity", @"Address", nil];
  pValue  = [self->context runCommand:@"search::newrecord",
                  @"entity", @"CompanyValue", nil];
  info    = [self->context runCommand:@"search::newrecord",
                  @"entity", @"CompanyInfo", nil];
  phone   = [self->context runCommand:@"search::newrecord",
                  @"entity", @"Telephone", nil];

  if ([_qualifier isKindOfClass:[EOKeyValueQualifier class]]) {
    cmp = (SEL_EQ([(id)_qualifier selector], EOQualifierOperatorEqual))
      ? @"EQUAL"
      : @"LIKE";
           
    checkForAsterisk = NO;
  }
  
  [company setComparator:cmp];
  [address setComparator:cmp];
  [pValue  setComparator:cmp];
  [info    setComparator:cmp];
  [phone   setComparator:cmp];
  
  for (i = 0; i < cnt; i++) {
    NSException         *exception = nil;
    NSString            *hint      = nil;
    EOKeyValueQualifier *qual      = nil;
    NSString            *key       = nil;
    NSString            *value     = nil;
    NSArray             *fragments = nil;

    qual = [quals objectAtIndex:i];

    if (![qual isKindOfClass:[EOKeyValueQualifier class]]) {
      hint = @"SkyTeamDataSource: only supports EOKeyValueQualifier's "
             @"(possibly wrapped by an EOOrQualifier or EOAndQualifier)!";
    }
    else if ([_qualifier isKindOfClass:[EOOrQualifier class]] &&
             !SEL_EQ([qual selector], EOQualifierOperatorLike)) {
      hint = @"SkyTeamDataSource: EOOrQualifers are only supported by "
             @"following operators: "
             @"( EOQualifierOperatorLike)";
    }
    else if ([_qualifier isKindOfClass:[EOAndQualifier class]] &&
             !SEL_EQ([qual selector], EOQualifierOperatorLike)) {
      hint = @"SkyTeamDataSource: EOAndQualifers are only supported by "
             @"following operators: "
             @"( EOQualifierOperatorLike)";
    }
    
    key   = [qual key];
    value = [[qual value] stringValue];

    if (checkForAsterisk && ![value hasSuffix:@"*"]) {
      hint = [NSString stringWithFormat:
              @"SkyTeamDataSource: qualifier: asterisk "
              @"at end of value expeceted. e.g.: \"attr like '*value*'\" "
              @"(you did: \"%@ like '%@'\")", key, value];
    }
    
    if (hint != nil) {
      exception = [[NSException alloc] initWithFormat:hint];
      [exception raise];
    }
    
    NSAssert1((key != nil), @"%s: key is nil", __PRETTY_FUNCTION__);

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
      else
        NSLog(@"Warning! %s: does not support '%@'", __PRETTY_FUNCTION__, key);
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
  
  return result;
}

- (NSArray *)_fetchTeamsWithQualifier:(EOQualifier *)_qual
                               operator:(NSString *)_operator
                             fetchLimit:(unsigned int)_fetchLimit
                               fetchIDs:(BOOL)_fetchIDs
{
  NSMutableArray *gids       = nil;
  NSArray        *ids        = nil;
  int            i, cnt;

  ids = [self->context runCommand:@"team::extended-search",
             @"operator", _operator,
             @"searchRecords",  [self searchRecordsFromQualifier:_qual],
             @"fetchIds",       [NSNumber numberWithBool:YES],
             @"maxSearchCount", [NSNumber numberWithInt:_fetchLimit],
             nil];

  if (_fetchIDs) return ids;

  cnt  = [ids count];
  gids = [[NSMutableArray alloc] initWithCapacity:cnt];
  
  for (i = 0; i < cnt; i++) {
    id obj;
    id pk;
    EOGlobalID *gid;
    
    obj = [ids objectAtIndex:i];
    pk  = [obj valueForKey:@"companyId"];
    gid = [[self->context typeManager] globalIDForPrimaryKey:pk];
    
    if (gid)
      [gids addObject:gid];
    else
      NSLog(@"%s: couldn't get gid for pkey %@", __PRETTY_FUNCTION__, pk);
  }
  AUTORELEASE(gids);
  return [self->context runCommand:@"team::get-by-globalid",
              @"gids", gids,
              nil];
}

- (NSArray *)_fetchObjectsForGlobalIDs:(NSArray *)_gids {
  /* used by resolver */
  NSArray *teams;

  teams = [self->context runCommand:@"team::get-by-globalid",
                   @"gids", _gids, nil];
  
  return [self _morphEOsToDocuments:teams];
}

@end /* SkyTeamDataSource(PrivateMethodes) */

@implementation SkyTeamDocumentGlobalIDResolver

- (BOOL)canResolveGlobalID:(EOGlobalID *)_gid
  withDocumentManager:(id<SkyDocumentManager>)_dm
{
  static Class EOKeyGlobalIDClass = Nil;

  if (EOKeyGlobalIDClass == Nil)
    EOKeyGlobalIDClass = [EOKeyGlobalID class];

  if ([_gid class] != EOKeyGlobalIDClass)
    return NO;
  
  if (![[_gid entityName] isEqualToString:@"Team"])
    return NO;
  
  return YES;
}

- (NSArray *)resolveGlobalIDs:(NSArray *)_gids
  withDocumentManager:(id<SkyDocumentManager>)_dm
{
  SkyTeamDataSource *ds;
  NSArray *results;
  
  if (_gids == nil)
    return nil;
  if ([_gids count] == 0)
    return [NSArray array];
  
  ds = [(SkyTeamDataSource *)[SkyTeamDataSource alloc] 
			     initWithContext:[_dm context]];
  if (ds == nil)
    return nil;
  
  results = [[ds _fetchObjectsForGlobalIDs:_gids] retain];
  [ds release]; ds = nil;
  return results;
}

@end /* SkyTeamDocumentGlobalIDResolver */
