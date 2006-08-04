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

#include <LSFoundation/OGoAccessHandler.h>

/*
  OGoCompanyAccessHandler
  
  TODO: document
*/

@interface OGoCompanyAccessHandler : OGoAccessHandler
@end

#include "common.h"

@interface NSObject(Private)
- (EOGlobalID *)globalID;
@end

@interface OGoAccessHandler(Internals)
- (BOOL)_checkGIDs:(NSArray *)_ids;
@end

@implementation OGoCompanyAccessHandler

static NSArray *entityNames = nil;
static NSArray *contactPermAttrs = nil;
static BOOL debugOn = YES;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  debugOn = [ud boolForKey:@"SkyAccessManagerDebug"];

  if (contactPermAttrs == nil) {
    contactPermAttrs = [[NSArray alloc] initWithObjects:@"ownerId",
					  @"isPrivate", @"isReadonly",
					  @"companyId", @"globalID", nil];
  }
  if (entityNames == nil) {
    id name[4];

    name[0] = @"Person";
    name[1] = @"Enterprise";
    name[2] = @"Team";
    name[3] = @"Company";
    entityNames = [[NSArray alloc] initWithObjects:name count:4];
  }
}

/* operations */

- (BOOL)_checkAccessMask:(NSString *)_mask with:(NSString *)_operation {
  // TODO: a bit overkill to check for 'r' and 'w'?
  unsigned i, opCnt;
  int maskCnt;
  
  if (debugOn)
    [self debugWithFormat:@"check mask: '%@' with '%@'", _mask, _operation];
  
  if (![_mask isNotEmpty] || ![_operation isNotEmpty]) {
    if (debugOn) [self debugWithFormat:@"  one parameter is empty => NO"];
    return NO;
  }
  
  maskCnt = [_mask length];
  opCnt   = [_operation length];

  if (maskCnt < opCnt) {
    if (debugOn) [self debugWithFormat:@"  op is longer than mask => NO"];
    return NO;
  }
  
  for (i = 0; i < opCnt; i++) {
    NSString *subStr;
    
    subStr = [_operation substringWithRange:NSMakeRange(i, 1)];
    if ([_mask rangeOfString:subStr].length == 0) {
      if (debugOn) {
	[self debugWithFormat:
		@"  mask does not contain op '%@' => NO", subStr];
      }
      return NO;
    }
  }
  if (debugOn) [self debugWithFormat:@"  match => OK."];
  return YES;
}

- (NSArray *)_fetchTeamsForPersonID:(id)_pkeyOrGID buildGids:(BOOL)_gids {
  NSDictionary *acc;
  NSArray      *teamIds;
  
  if (![_pkeyOrGID isNotNull]) 
    return nil;
  
  if ([_pkeyOrGID isKindOfClass:[EOKeyGlobalID class]])
    _pkeyOrGID = [(EOKeyGlobalID *)_pkeyOrGID keyValues][0];
  
  if (debugOn) 
    [self debugWithFormat:@"  fetch teams for person pkey: %@", _pkeyOrGID];
  
  acc = [NSDictionary dictionaryWithObject:_pkeyOrGID forKey:@"companyId"];

  teamIds = [[self context] runCommand:@"account::teams", @"account", acc,nil];
  if (_gids) {
    teamIds = [teamIds map:@selector(globalID)];
  }
  else {
    teamIds = [teamIds map:@selector(valueForKey:)
                       with:@"companyId"];
  }
  if (debugOn) [self debugWithFormat:@"    got %d IDs.", [teamIds count]];
  return teamIds;
}

- (NSArray *)_fetchTeamsForPersonID:(NSNumber *)_gid {
  return  [self _fetchTeamsForPersonID:_gid buildGids:NO];
}

- (NSString *)_calculateReadOnlyAndPrivateForCompanyPermRecord:(id)_permInfos
  accessGID:(EOKeyGlobalID *)_accessGID
{
  NSNumber *ownerId;
  
  /* always full read/write access for owner to ensure no mixups */
  ownerId = [_permInfos valueForKey:@"ownerId"];
  if ([ownerId isEqual:[_accessGID keyValues][0]])
    return @"rw";
  
  if ([[_permInfos valueForKey:@"isPrivate"] boolValue])
    /* we are not the owner, the object is private => no access at all */
    return @"";
  
  /* 
     We are not the owner, if 'isReadOnly' is on, we have read-access,
     otherwise the record is public (full read/write).
  */
  return [[_permInfos valueForKey:@"isReadonly"] boolValue] ? @"r" : @"rw";
}

- (NSString *)_permMaskFromAccessCache:(NSDictionary *)_cache
  forAccessGID:(EOKeyGlobalID *)_accessGID withTeamGIDs:(NSArray **)_teamsGIDs
{
  /*
    Explanation:
    If we have an ACL the ACL contains entries for accounts *and* for teams
    of this account.
    We just have two permissions for company records 'r' for read and 'w' for
    write. This methods calculates a union of the configured fields, that is,
    if the user ACL entry has just 'r' but some team the user is a member of
    has 'rw', the result will be 'rw'.
  */
  NSString *accessStr;
  int      bitmap;
  
  bitmap = 0;
  
  /* first check account */
  
  accessStr = [_cache objectForKey:_accessGID];
  if ([accessStr isNotEmpty] && 
      ([accessStr rangeOfString:@"r"].length > 0)) {
    bitmap |= 1;
  }
    
  if ([accessStr isNotEmpty] && 
      ([accessStr rangeOfString:@"w"].length > 0))
    bitmap |= 2;
  
  /* then check all teams (unless we already have full access) */
  if (bitmap < 3) {
    NSEnumerator *enumerator;
    EOGlobalID   *teamID;
    
    if (*_teamsGIDs == nil)
      *_teamsGIDs = [self _fetchTeamsForPersonID:_accessGID buildGids:YES];
    
    enumerator = [*_teamsGIDs objectEnumerator];
    
    /* 2^0 -> r 2^1 ->w */
    while ((teamID = [enumerator nextObject]) != nil) {
      NSString *str;
      
      if ((str = [_cache objectForKey:teamID]) == nil)
        continue;
      
      if ([str isNotEmpty] && ([str rangeOfString:@"r"].length > 0))
        bitmap |= 1;
      
      if ([str isNotEmpty] && ([str rangeOfString:@"w"].length > 0))
        bitmap |= 2;
      
      if (bitmap > 2) /* we have reached full access */
        break;
    }
  }
  
  switch (bitmap) {
  case 0: return @"";
  case 1: return @"r"; 
  case 2: return @"w";
  case 3: return @"rw"; 
  default: return nil;
  }
}

- (BOOL)_checkAccess:(NSString *)_operation
  forCompanyPermRecord:(id)_permInfos
  accessGID:(EOKeyGlobalID *)_accessGID
  teamGIds:(NSArray **)_teamsGIDs
  cache:(NSDictionary *)_cache
{
  /* called by -objects:forOperation:forAccessGlobalID:searchAll: */
  /*
    The cache contains a mapping of an access-global-id to a permission string,
    eg Person<10000> to 'rw'.
  */
  NSString     *perm;
  EOGlobalID   *gid;
  NSNumber     *gidId;
  
  /* check whether the access-id is the owner if the record */
  
  if ([[_permInfos valueForKey:@"ownerId"] isEqual:[_accessGID keyValues][0]]){
    // TODO: need to / should call -cacheOperation:?
    if (debugOn) {
      [self debugWithFormat:@"  allowed full access for owner (%@): '%@'",
              [_permInfos valueForKey:@"ownerId"], _operation];
    }
    return YES;
  }
  
  if ([[_permInfos entityName] isEqualToString:@"Team"]) {
    // TODO: always allows access to teams?!
    if (debugOn) 
      [self debugWithFormat:@"  allowed access to team, op %@", _operation];
    
    return YES;
  }
  
  gid   = [_permInfos valueForKey:@"globalID"];
  gidId = [[(EOKeyGlobalID *)gid keyValuesArray] lastObject];
  
  /* the access 'account' is the same like the object */
  
  if ([_accessGID isEqual:gid] && [_operation isEqualToString:@"r"])
    // TODO: need to / should call -cacheOperation:?
    return YES;
  
  
  if (![_cache isNotEmpty]) { /* no access was set */
    /*
      => I think this "means" that no separate ACL was set on the record.
         Apparently an ACL will supercede 'isPrivate' and 'isReadOnly'
         processing. TODO: check that.
    */
    perm = [self _calculateReadOnlyAndPrivateForCompanyPermRecord:_permInfos
                 accessGID:_accessGID];
  }
  else {
    perm = [self _permMaskFromAccessCache:_cache forAccessGID:_accessGID
                 withTeamGIDs:_teamsGIDs];
  }
  
  [self cacheOperation:perm for:gidId];
  return [self _checkAccessMask:perm with:_operation];
}

- (BOOL)isContactPKeyRoot:(NSNumber *)_pkey {
  // TODO: root role
  return [_pkey intValue] == 10000 ? YES : NO;
}
- (BOOL)isContactGIDRoot:(EOGlobalID *)_accessGID {
  if (_accessGID == nil)
    return NO;
  return [self isContactPKeyRoot:[(EOKeyGlobalID *)_accessGID keyValues][0]];
}

- (NSArray *)removeDuplicatesInArray:(NSArray *)_array {
  // TODO: should be an NSArray category
  NSSet *set;
  
  set = _array != nil ? [NSSet setWithArray:_array] : nil;
  return [set allObjects];
}

- (NSArray *)filterOutTeamGIDsFromArray:(NSArray *)_oids
  addTeamGIDsToArray:(NSMutableArray *)_teamGIDs
{
  NSEnumerator  *enumerator;
  EOKeyGlobalID *oid;
  id            *objs;
  int           cnt;
  
  objs = calloc([_oids count] + 2, sizeof(id));
  
  enumerator = [_oids objectEnumerator];
  for (cnt = 0; (oid = [enumerator nextObject]) != nil; ) {
    if ([[oid entityName] isEqualToString:@"Team"])
      [_teamGIDs addObject:oid];
    else {
      objs[cnt] = oid;
      cnt++;
    }
  }
  _oids = [NSArray arrayWithObjects:objs count:cnt];
  if (objs != NULL) free(objs); objs = NULL;
  return _oids;
}

- (NSArray *)fetchCompanyPermAttrsForGIDs:(NSArray *)_oids {
  NSArray *objects;

  objects = [[self context] runCommand:@"object::get-by-globalID",
                       @"gids",          _oids,
                       @"noAccessCheck", [NSNumber numberWithBool:YES],
                       @"attributes",    contactPermAttrs, nil];
    
  if ([objects count] != [_oids count]) {
    [self errorWithFormat:
	    @"%s: could not fetch all persons oids[%d] objects[%d]",
            __PRETTY_FUNCTION__, [_oids count], [objects count]];
  }
  return objects;
}

- (NSDictionary *)accessCacheForObjects:(id)objects {
  // TODO: explain what this method does
  // I think it retrieves the objects' ACL w/o the object stuff
  OGoAccessManager *manager;
  NSArray *oids;
  
  manager = [[self context] accessManager];
  oids    = [objects valueForKey:@"globalID"];
  return [manager allowedOperationsForObjectIds:oids accessGlobalIDs:nil];
}

- (NSString *)_calculateReadOnlyAndPrivateForTeamPermRecord:(id)_permInfos
  accessGID:(EOKeyGlobalID *)_accessGID
{
  /*
    Rules for teams:
    - all teams owned by root or none are treated as read/only for everyone
      (compatibility rule, we probably want to mark all default teams readOnly)
    - if the _accessGID is the owner, he has full read/write access
    - otherwise:
      - if the team is isPrivate
        - members get read permission
          - if the team is not isReadOnly they get write access
        - none-members get no access at all
      - if the team is not isPrivate
        - everyone gets read permission
        - if the team is not isReadOnly everyone get write access?
          - TODO: should be limited to members? => no not really I guess
  */
  NSNumber *ownerId;
  NSArray  *memberGIDs;
  
  /* check root */
  
  if ([self isContactGIDRoot:_accessGID]) /* root has full access */
    return @"rw";
  
  /* check owner-id */
  
  ownerId = [_permInfos valueForKey:@"ownerId"];
  
  if (![ownerId isNotNull]) { /* treat unassigned IDs as pub/r */
    if (debugOn) [self debugWithFormat:@"  team is not owned => r"];
    return @"r";
  }
  
  if ([self isContactPKeyRoot:ownerId]) { /* treat root owned as pub/r */
    if (debugOn) [self debugWithFormat:@"  team is owned by root => r"];
    return @"r";
  }
  
  if ([ownerId isEqual:[_accessGID keyValues][0]]) {
    if (debugOn) [self debugWithFormat:@"  team is owned by access-id => rw"];
    return @"rw";
  }
  
  /* owner is neither accessor nor root or empty */
  
  if (![[_permInfos valueForKey:@"isPrivate"] boolValue]) {
    /* item is public */
    if (debugOn) [self debugWithFormat:@"  team is public => r or rw"];
    return [[_permInfos valueForKey:@"isReadonly"] boolValue] ? @"r" : @"rw";
  }
  
  /* the item is private, check whether we are a member */
  
  memberGIDs = [[self context] runCommand:@"team::members",
			       @"group", [_permInfos valueForKey:@"globalID"],
			       @"fetchGlobalIDs",[NSNumber numberWithBool:YES],
			       nil];

  if (![memberGIDs containsObject:_accessGID]) {
    /* access-id is not a member, so no access at all to private team */
    if (debugOn) [self debugWithFormat:@"  not a member, private team."];
    return @"";
  }
  
  if (debugOn) [self debugWithFormat:@"  we are a member => r or rw"];
  return [[_permInfos valueForKey:@"isReadonly"] boolValue] ? @"r" : @"rw";
}

- (void)addAllowedTeamGIDs:(NSArray *)_oids toArray:(NSMutableArray *)result
  forOperation:(NSString *)_operation
  forAccessGlobalID:(EOGlobalID *)_accessGID
  searchAll:(BOOL)_all
{
  /*
    Note: we do not check ACLs for teams. Might be too slow or then maybe not.
    
    Note: root is already catched, so this method doesn't need to care about
          that.
  */
  NSArray      *permInfos;
  NSDictionary *permInfoRec;
  NSEnumerator *enumerator;
  
  if (![_oids isNotEmpty])
    return;
  
  /* we first add all GIDs and then remove them when necessary */
  [result addObjectsFromArray:_oids];
  
  permInfos = [self fetchCompanyPermAttrsForGIDs:_oids];

  enumerator = [permInfos objectEnumerator];
  while ((permInfoRec = [enumerator nextObject]) != nil) {
    NSString *perm;
    
    perm = [self _calculateReadOnlyAndPrivateForTeamPermRecord:permInfoRec
		 accessGID:(EOKeyGlobalID *)_accessGID];
    [self cacheOperation:perm for:[permInfoRec valueForKey:@"globalID"]];
    
    if (debugOn) {
      [self debugWithFormat:@"access on team %@: '%@'", 
	      [permInfoRec valueForKey:@"companyId"], perm];
    }
    
    if (![self _checkAccessMask:perm with:_operation])
      [result removeObject:[permInfoRec valueForKey:@"globalID"]];
  }
}

- (void)addAllowedContactGIDs:(NSArray *)_oids toArray:(NSMutableArray *)result
  forOperation:(NSString *)_operation
  forAccessGlobalID:(EOGlobalID *)_accessGID
  searchAll:(BOOL)_all
{
  /*
    Note: root is already catched, so this method doesn't need to care about
          that.
  */
  NSArray      *permInfos, *teams;
  NSDictionary *accessCache;
  NSDictionary *permInfoRec;
  NSEnumerator *enumerator;
  
  if (![_oids isNotEmpty])
    return;
  
  permInfos = [self fetchCompanyPermAttrsForGIDs:_oids];
  
  // TODO: explain that section
  
  accessCache = [self accessCacheForObjects:permInfos];
  
  /* fetched on-demand (required for resolving team ACLs entries) */
  teams = nil;
  
  enumerator = [permInfos objectEnumerator];
  while ((permInfoRec = [enumerator nextObject]) != nil) {
    NSDictionary *cache;
    
    cache = [accessCache objectForKey:[permInfoRec valueForKey:@"globalID"]];
    
    if ([self _checkAccess:_operation forCompanyPermRecord:permInfoRec
	      accessGID:(EOKeyGlobalID *)_accessGID
	      teamGIds:&teams
	      cache:cache]) {
      [result addObject:[permInfoRec valueForKey:@"globalID"]];
    }
    else if (!_all) // TODO: explain (I think this aborts all if one fails)
      break;
  }
}

- (NSArray *)objects:(NSArray *)_oids
  forOperation:(NSString *)_operation
  forAccessGlobalID:(EOGlobalID *)_accessGID
  searchAll:(BOOL)_all
{
  // TODO: split up
  // TODO: document what '_all' does
  NSMutableArray *resultGIDs, *teamGIDs;
  NSArray        *contactGIDs;
  
  if (debugOn) {
    [self debugWithFormat:@"filter op '%@' on %d gids for %@ (all=%s)",
          _operation, [_oids count], _accessGID, _all?"yes":"no"];
  }
  
  /* check operation */
  
  if ([_operation length] != 1) {
    [self warnWithFormat:@"operation should be a single char, got: '%@'", 
            _operation];
  }
  else if ([_operation characterAtIndex:0] != 'r' &&
           [_operation characterAtIndex:0] != 'w') {
    [self warnWithFormat:@"operation should be either 'r' or 'w', got: '%@'", 
            _operation];
  }
  
  /* clean up oids array */
  
  if (![_oids isNotEmpty])
    return _oids;
  _oids = [self removeDuplicatesInArray:_oids];

  /* first allow everything for root */
  
  if ([self isContactGIDRoot:_accessGID]) { /* root sees everything */
    if (debugOn) [self debugWithFormat:@"  allowed all for root ..."];
    return _oids;
  }

  resultGIDs = [NSMutableArray arrayWithCapacity:[_oids count]];
  teamGIDs   = [NSMutableArray arrayWithCapacity:[_oids count]];
  
  /* process Teams */
  
  contactGIDs = [self filterOutTeamGIDsFromArray:_oids
		      addTeamGIDsToArray:teamGIDs];
  
  [self addAllowedTeamGIDs:teamGIDs toArray:resultGIDs
	forOperation:_operation forAccessGlobalID:_accessGID
	searchAll:_all];
  
  [self addAllowedContactGIDs:contactGIDs toArray:resultGIDs
	forOperation:_operation forAccessGlobalID:_accessGID
	searchAll:_all];
  
  return resultGIDs;
}

- (BOOL)operation:(NSString *)_operation
  allowedOnObjectIDs:(NSArray *)_oids
  forAccessGlobalID:(EOGlobalID *)_accessGID
{
  NSArray *res;

  if (debugOn) {
    [self debugWithFormat:@"check op '%@' on %d gids for %@",
          _operation, [_oids count], _accessGID];
  }
  
  if ([self isContactGIDRoot:_accessGID]) {
    if (debugOn) [self debugWithFormat:@"  allowed all for root ..."];
    return YES;
  }
  
  res = [self objects:_oids forOperation:_operation 
	      forAccessGlobalID:_accessGID
              searchAll:NO];
  
  return ([res count] == [_oids count]) ? YES : NO;
}

- (NSArray *)objects:(NSArray *)_oids
  forOperation:(NSString *)_operation
  forAccessGlobalID:(EOGlobalID *)_accessGID
{
  return [self objects:_oids forOperation:_operation
               forAccessGlobalID:_accessGID
               searchAll:YES];
}

- (NSArray *)_entityNames {
  return entityNames;
}

@end /* OGoCompanyAccessHandler */
