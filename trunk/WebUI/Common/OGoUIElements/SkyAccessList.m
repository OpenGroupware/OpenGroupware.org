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

/*
  >  searchPopupTitle     default = nil
  >  accesslistTitle      default =
  <> accessList           default = nil

  {
    personGID = 'rwx';
    teamGID   = 'i';
  }
*/

#include <OGoFoundation/OGoComponent.h>

@class NSString, NSArray, NSMutableArray, NSMutableDictionary;

@interface SkyAccessList : OGoComponent
{
  id                  team;
  id                  item;
  NSMutableDictionary *accessList;
  NSString            *searchString;
  BOOL                syncState;
  NSMutableArray      *companies;
  NSArray             *accessChecks;
  BOOL                isInTable;
  BOOL                isViewerMode;
  id                  accessItem;
  id                  myLabels;
}

@end

#include "common.h"
#include <OGoFoundation/OGoFoundation.h>
#include <LSFoundation/LSFoundation.h>
#include <WEExtensions/WEContextConditional.h>
#include <EOControl/EOControl.h>

@interface NSObject(Private)
- (EOGlobalID *)globalID;
@end /* NSObject(Private) */

@implementation SkyAccessList

static NSArray  *companySortOrderings    = nil;
static NSArray  *personCoreInfoAttrNames = nil;
static NSNumber *yesNum = nil;

+ (void)initialize {
  static BOOL didInit = NO;
  EOSortOrdering *so1, *so2, *so3;
  if (didInit) return;
  didInit = YES;
  
  so1 = [EOSortOrdering sortOrderingWithKey:@"login"
                        selector:EOCompareAscending];
  so2 = [EOSortOrdering sortOrderingWithKey:@"name"
                        selector:EOCompareAscending];
  so3 = [EOSortOrdering sortOrderingWithKey:@"firstname"
                        selector:EOCompareAscending];
  companySortOrderings = [[NSArray alloc] initWithObjects:so1, so2, so3, nil];

  personCoreInfoAttrNames = 
    [[NSArray alloc] initWithObjects:@"name", @"firstname", @"login", nil];
  
  yesNum = [[NSNumber numberWithBool:YES] retain];
}

- (void)dealloc {
  [self->team         release];
  [self->item         release];
  [self->accessItem   release];
  [self->searchString release];
  [self->accessList   release];
  [self->companies    release];
  [self->myLabels     release];
  [super dealloc];
}

/* operation */

static EOGlobalID *_globalID(id _obj) {
  return [_obj isKindOfClass:[NSDictionary class]]
    ? [(NSDictionary *)_obj objectForKey:@"globalID"]
    : [_obj globalID];
}

- (void)_addObj:(id)_obj toCompanies:(NSMutableArray *)_companies {
  /* 
     Check whether an object with the same GID is already in the array,
     if not, add _obj.
  */
  NSEnumerator *companiesEnum;
  id           obj;
  EOGlobalID   *gid;
  
  gid           = _globalID(_obj);
  companiesEnum = [_companies objectEnumerator];
  while ((obj = [companiesEnum nextObject])) {
    if (obj == _obj)
      return; /* exact match, found */
    if ([_globalID(obj) isEqual:gid])
      return; /* GID match, found */
  }
  [_companies addObject:_obj];
}

/* commands */

- (NSArray *)_fetchAccountGIDsMatching:(NSString *)_str {
  return [self runCommand:@"account::extended-search",
                 @"fetchGlobalIDs", yesNum,
                 @"operator",       @"OR",
                 @"name",           self->searchString,
                 @"firstname",      self->searchString,
                 @"description",    self->searchString,
                 @"login",          self->searchString,
                 @"keywords",       self->searchString,
               nil];
}
- (NSArray *)_fetchMemberGIDsForTeamGID:(EOGlobalID *)_gid {
  return [self runCommand:@"team::members",
                 @"fetchGlobalIDs", yesNum,
                 @"team",           _gid, nil];
}

- (NSDictionary *)_fetchCoreInfoForPersonGIDs:(NSArray *)_gids {
  return [self runCommand:@"person::get-by-globalid",
                 @"gids",       _gids,
                 @"groupBy",    @"globalID",
                 @"attributes", personCoreInfoAttrNames,
               nil];
}
- (NSArray *)_fetchPersonEOsForGIDs:(NSArray *)_gids {
  return [self runCommand:@"person::get-by-globalID", @"gids", _gids, nil];
}
- (NSArray *)_fetchTeamEOsForGIDs:(NSArray *)_gids {
  return [self runCommand:@"team::get-by-globalID", @"gids", _gids, nil];
}

static int compareTeams(id team1, id team2, void *context) {
  static EONull *null = nil;
  NSString *name1 = [team1 valueForKey:@"description"];
  NSString *name2 = [team2 valueForKey:@"description"];
  if (null == nil) null = [[EONull null] retain];
  
  if (name1 == (id)null) name1 = @"";
  if (name2 == (id)null) name2 = @"";
  return [(NSString *)name1 compare:name2];
}
- (NSArray *)fetchTeamEOs {
  NSArray *t;
  
  t = [self runCommand:@"team::get",
              @"returnType", intObj(LSDBReturnType_ManyObjects), nil];
  t = [t sortedArrayUsingFunction:compareTeams context:self];
  return t;
}

/* sync */

- (void)_sortCompanies {
  NSArray *sA; 
  
  sA = self->companies;
  sA = [[sA sortedArrayUsingKeyOrderArray:companySortOrderings] mutableCopy];
  [self->companies release]; self->companies = nil;
  self->companies = (NSMutableArray *)sA;
}

- (void)_syncFirstLoop { /* whatever 'first loop' means ... :-| */
  // TODO: clean up this mess
  NSEnumerator *enumerator;
  NSArray      *tmpArray;
  id           *agids, *tgids;
  int          aCnt, tCnt;
  id           obj;
      
  self->companies = [[NSMutableArray alloc] initWithCapacity:64];
  aCnt            = [self->accessList count];
  agids           = calloc(aCnt + 1, sizeof(id));
  tgids           = calloc(aCnt + 1, sizeof(id));
  aCnt            = 0;
  tCnt            = 0;
  enumerator      = [self->accessList keyEnumerator];
        
  while ((obj = [enumerator nextObject])) {
    if ([[obj entityName] isEqualToString:@"Team"])
      tgids[tCnt++] = obj;
    else if ([[obj entityName] isEqualToString:@"Person"])
      agids[aCnt++] = obj;
    else
      NSLog(@"WARNING[%s]: unexpected gid %@", __PRETTY_FUNCTION__, obj);
  }
  if (tCnt > 0) {
    NSArray *a;
        
    tmpArray = [[NSArray alloc] initWithObjects:tgids count:tCnt];
    a        = [self _fetchTeamEOsForGIDs:tmpArray];
    [tmpArray release]; tmpArray = nil;
        
    [self->companies addObjectsFromArray:a];
  }
  if (aCnt > 0) {
    NSArray *a;
        
    tmpArray = [[NSArray alloc] initWithObjects:agids count:aCnt];
    a = [self _fetchPersonEOsForGIDs:tmpArray];
    [tmpArray release]; tmpArray = nil;
        
    [self->companies addObjectsFromArray:a];
  }
  enumerator = [self->companies objectEnumerator];
  while ((obj = [enumerator nextObject])) {
    NSMutableDictionary *dict;
    NSString            *right;
    int                 rCnt, i;
        
    dict = [NSMutableDictionary dictionaryWithCapacity:16];
    [(NSMutableDictionary *)obj setObject:dict forKey:@"accessRights"];

    right = [self->accessList objectForKey:[obj globalID]];
    for (i = 0, rCnt = [right cStringLength]; i < rCnt; i++) {
      NSString *k;

      k = [right substringWithRange:NSMakeRange(i, 1)];
      [dict setObject:yesNum forKey:k];
    }
  }
  if (tgids) free(tgids); tgids = NULL;
  if (agids) free(agids); agids = NULL;
}

- (void)_processSearchString {
  /* add search accounts to companies; set accessRights */
  NSEnumerator *enumerator;
  NSDictionary *obj;
  id searchResult;

  searchResult = [self _fetchAccountGIDsMatching:self->searchString];
  searchResult = [self _fetchCoreInfoForPersonGIDs:searchResult];
        
  enumerator = [searchResult objectEnumerator];
  while ((obj = [enumerator nextObject])) {
    NSMutableDictionary *md;
          
    md = [obj mutableCopy];
    [md setObject:[NSMutableDictionary dictionaryWithCapacity:4]
	forKey:@"accessRights"];
    [self _addObj:md toCompanies:self->companies];
    [md release];
  }
  [self _sortCompanies];
}

- (void)_addTeamEntries {
  /* add team entries to companies; set accessRights */
  NSEnumerator *enumerator;
  NSDictionary *pCoreInfo;
  id searchResult;

  if (![[self->team valueForKey:@"accessRights"] isNotNull]) {
    [self->team
	 takeValue:[NSMutableDictionary dictionaryWithCapacity:4]
         forKey:@"accessRights"];
  }
  
  if (![self->companies containsObject:self->team])
    [self->companies addObject:self->team];
        
  searchResult = [self _fetchMemberGIDsForTeamGID:_globalID(self->team)];
  searchResult = [self _fetchCoreInfoForPersonGIDs:searchResult];

  enumerator = [searchResult objectEnumerator];
  while ((pCoreInfo = [enumerator nextObject])) {
    NSMutableDictionary *md;
      
    md = [pCoreInfo mutableCopy];
    [md setObject:[NSMutableDictionary dictionaryWithCapacity:4]
        forKey:@"accessRights"];
    [self _addObj:md toCompanies:self->companies];
    [md release];
  }
  [self _sortCompanies];
}

- (void)_cleanupCompanyRecords {
  /* remove empty entries from companies remove accessRights and sort */
  // TODO: clean up this mess
  NSArray *tmpArray;
  id      *teams, *persons, obj;
  int     cCnt, i,tCnt, pCnt;
  
  tCnt    = [self->companies count];
  teams   = calloc(tCnt + 1, sizeof(id));
  persons = calloc(tCnt + 1, sizeof(id));
  tCnt    = 0;
  pCnt    = 0;
      
  for (i = 0,  cCnt = [self->companies count]; i < cCnt; i++) {
    NSMutableDictionary *dict;
    NSEnumerator        *keyEnum;
    id                  key;
    NSMutableString     *str;

    obj     = [self->companies objectAtIndex:i];
    dict    = [(NSDictionary *)obj objectForKey:@"accessRights"];
    keyEnum = nil;
        
    if ([dict isNotNull])
      keyEnum = [dict keyEnumerator];
        
    str = nil;
    while ((key = [keyEnum nextObject]) != nil) {
      id o;
      
      o = [dict objectForKey:key];
      if (![o boolValue])
        continue;
      
      if (str == nil)
        str = [NSMutableString stringWithCapacity:16];
      [str appendString:key];
    }
    if (str == nil) {
      [obj takeValue:[EONull null] forKey:@"accessRights"];
      [self->accessList removeObjectForKey:_globalID(obj)];
    }
    else { /* start sort and set obj in accessList */
      if ([[obj valueForKey:@"isTeam"] boolValue])
        teams[tCnt++] = obj;
      else
        persons[pCnt++] = obj;
          
      [self->accessList setObject:str forKey:_globalID(obj)];
    }
  }
  [self->companies removeAllObjects];
      
  tmpArray = [[NSArray alloc] initWithObjects:teams count:tCnt];
  [self->companies addObjectsFromArray:tmpArray];
  [tmpArray release];
  tmpArray = [[NSArray alloc] initWithObjects:persons count:pCnt];
  [self->companies addObjectsFromArray:tmpArray];
  [tmpArray release]; tmpArray = NULL;
      
  if (teams)   free(teams);   teams   = NULL;
  if (persons) free(persons); persons = NULL;
  
  if (![self->searchString isNotNull])
    self->searchString = @"";
  
  if ([self->searchString length] > 0) {
    /* add search accounts to companies; set accessRights */
    [self _processSearchString];
  }
  else if (self->team) {
    /* add team entries to companies; set accessRights */
    [self _addTeamEntries];
  }
}

- (void)syncVars {
  if (self->syncState)
    return;
    
  if (self->isViewerMode) {
    [self->companies release];
    self->companies = nil;
  }
  if (self->accessList == nil)
    self->accessList = [[NSMutableDictionary alloc] init];
    
  self->syncState = YES;
      
  if (self->companies == nil) /* first loop, TODO: what is that? */
    [self _syncFirstLoop];
  else
    [self _cleanupCompanyRecords];
}

- (void)syncSleep {
  self->syncState = NO;
  [self->searchString release]; self->searchString = nil;
  [super syncSleep];
}

/* processing requests */

- (void)takeValuesFromRequest:(WORequest *)_rq inContext:(WOContext *)_ctx {
  [super takeValuesFromRequest:_rq inContext:_ctx];
  [self syncVars];
}

/* generating response */

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  [self syncVars];
  [super appendToResponse:_response inContext:_ctx];
}

/* actions */

- (id)search {
  return nil;
}

/* /actions */

- (BOOL)hasAccountSelection {
  return [self->companies count];
}

- (BOOL)isTeam {
  return [[self->item valueForKey:@"isTeam"] boolValue];
}

/* accessors */

- (void)setCompanies:(id)_com {
  ASSIGN(self->companies, _com);
}
- (id)companies {
  return self->companies;
}

- (void)setTeam:(id)_team {
  ASSIGN(self->team, _team);
}
- (id)team {
  return self->team;
}

- (void)setIsViewerMode:(BOOL)_b {
  self->isViewerMode = _b;
}
- (BOOL)isViewerMode {
  return self->isViewerMode;
}

- (void)setItem:(id)_item {
  ASSIGN(self->item, _item);
}
- (id)item {
  return self->item;
}

- (void)setAccessItem:(id)_accessItem {
  ASSIGN(self->accessItem, _accessItem);
}
- (id)accessItem {
  return self->accessItem;
}
- (NSString *)accessImageName {
  return [NSString stringWithFormat:self->isViewerMode
                     ? @"icon_permissions_viewer_%@.gif"
                     : @"icon_permissions_%@.gif",
                   self->accessItem];
}
- (NSString *)accessAlternateText {
  NSString *s;

  s = [@"permissions_" stringByAppendingString:[self->accessItem stringValue]];
  return [[self labels] valueForKey:s];
}

- (id)_itemAccessRights {
  return [self->item valueForKey:@"accessRights"];
}
- (void)setCurrentAccessRight:(BOOL)_right {
  [[self _itemAccessRights] takeValue:[NSNumber numberWithBool:_right]
                            forKey:self->accessItem];
}
- (BOOL)currentAccessRight {
  return [[[self _itemAccessRights] valueForKey:self->accessItem] boolValue];
}
- (int)accessListCount {
  return [self->accessChecks count] + 1;
}

- (void)setSearchString:(NSString *)_str {
  ASSIGNCOPY(self->searchString, _str);
}
- (NSString *)searchString {
  return self->searchString;
}

- (void)setAccessList:(NSMutableDictionary *)_accessList {
  if ([_accessList isNotNull]) {
    NSAssert1([_accessList isKindOfClass:[NSMutableDictionary class]],
              @"accessList should be a mutable Dicionary <%@>", _accessList);
    ASSIGN(self->accessList, _accessList);
  }
  else {
    [self->accessList release]; self->accessList = nil;
  }
}

- (void)setAccessChecks:(NSArray *)_a {
  ASSIGN(self->accessChecks, _a);
}
- (NSArray *)accessChecks {
  return self->accessChecks;
}

- (id)accessList {
  return self->accessList;
}

- (void)setIsInTable:(BOOL)_b {
  self->isInTable = _b;
}
- (BOOL)isInTable {
  return self->isInTable;
}

- (void)setLabels:(id)_id {
  ASSIGN(self->myLabels, _id);
}
- (id)labels {
  return self->myLabels;
}

@end /* SkyAccessList */
