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

#include <LSFoundation/SkyAccessHandler.h>

// TODO: this belongs into Logic/LSAddress

@interface SkyContactsAccessHandler : SkyAccessHandler
@end

#include "common.h"
#include "timing.h"

@interface NSObject(Private)
- (EOGlobalID *)globalID;
@end

@interface SkyAccessHandler(Internals)
- (BOOL)_checkGIDs:(NSArray *)_ids;
@end /* SkyAccessHandler(Internals) */

@implementation SkyContactsAccessHandler

static NSArray *entityNames = nil;
static NSArray *contactPermAttrs = nil;
static BOOL debugOn = YES;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  debugOn = [ud boolForKey:@"SkyAccessManagerDebug"];

  if (contactPermAttrs == nil) {
    contactPermAttrs = [[NSArray alloc] initWithObjects:@"ownerId",
					  @"isPrivate", @"isReadonly",
					  @"globalID", nil];
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

- (BOOL)_checkAccess:(NSString *)_operation
  forCompanyPermRecord:(id)_permInfos
  accessGID:(EOKeyGlobalID *)_accessGID
  teamGIds:(NSArray *)_teamsGIDs
  cache:(NSDictionary *)_cache
{
  /* called by -objects:forOperation:forAccessGlobalID:searchAll: */
  NSString     *accessStr;
  NSEnumerator *enumerator;
  id           teamID;
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
         processing. TODO: check that
    */
    NSString *perm;
    
    perm = [self _calculateReadOnlyAndPrivateForCompanyPermRecord:_permInfos
                 accessGID:_accessGID];
    [self cacheOperation:perm for:gidId];
    
    return [perm rangeOfString:_operation].length > 0 ? YES : NO;
  }
  
  accessStr = [_cache objectForKey:_accessGID];
  /* cache access */
  {
    int      bitmap;
    NSString *str;

    bitmap = 0;
    
    if ([accessStr isNotEmpty] && 
	([accessStr rangeOfString:@"r"].length > 0)) {
      bitmap |= 1;
    }
    
    if ([accessStr isNotEmpty] && 
	([accessStr rangeOfString:@"w"].length > 0))
      bitmap |= 2;

    enumerator = [_teamsGIDs objectEnumerator];

    /* 2^0 -> r 2^1 ->w */    
    while ((bitmap < 3) && ((teamID = [enumerator nextObject]))) {
      str = [_cache objectForKey:teamID];

      if ([str length] && ([str rangeOfString:@"r"].length > 0))
        bitmap |= 1;

      if ([str length] && ([str rangeOfString:@"w"].length > 0))
        bitmap |= 2;
    }
    str = @"";
    switch (bitmap) {
      case 0: str = @"";   break;
      case 1: str = @"r";  break;
      case 2: str = @"w";  break;
      case 3: str = @"rw"; break;
    }
    [self cacheOperation:str for:gidId];
    
    if ([self _checkAccessMask:str with:_operation])
      return YES;
  }
  return NO;
}

- (BOOL)isAccessGIDRoot:(EOGlobalID *)_accessGID {
  // TODO: root role
  if (_accessGID == nil)
    return NO;
  return ([[(EOKeyGlobalID *)_accessGID keyValues][0] intValue] == 10000)
    ? YES : NO;
}

- (NSArray *)removeDuplicatesInArray:(NSArray *)_array {
  // TODO: should be an NSArray category
  NSSet *set;
  
  set = _array != nil ? [NSSet setWithArray:_array] : nil;
  return [set allObjects];
}

- (NSArray *)filterOutTeamGIDsFromArray:(NSArray *)_oids
  addTeamsToArray:(NSMutableArray *)result
{
  NSEnumerator *enumerator;
  id           obj, *objs;
  int          cnt;

  cnt  = 0;
  objs = calloc([_oids count] + 2, sizeof(id));
  
  enumerator = [_oids objectEnumerator];
  while ((obj = [enumerator nextObject]) != nil) {
    if ([[obj entityName] isEqualToString:@"Team"])
      [result addObject:obj];
    else {
      objs[cnt] = obj;
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
	      @"s: could not fetch all persons oids[%d] objects[%d]",
              __PRETTY_FUNCTION__, [_oids count], [objects count]];
  }
  return objects;
}

- (NSDictionary *)accessCacheForObjects:(id)objects {
  // TODO: explain what this method does
  OGoAccessManager *manager;
  NSArray *oids;
      
  manager = [[self context] accessManager];
  oids    = [objects valueForKey:@"globalID"];
  return [manager allowedOperationsForObjectIds:oids
                  accessGlobalIDs:nil];
}

- (NSArray *)objects:(NSArray *)_oids
  forOperation:(NSString *)_operation
  forAccessGlobalID:(EOGlobalID *)_accessGID
  searchAll:(BOOL)_all
{
  // TODO: split up
  // TODO: document what '_all' does
  NSMutableArray   *result;
  NSEnumerator     *enumerator;
  
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
  
  if ([self isAccessGIDRoot:_accessGID]) { /* root sees everything */
    if (debugOn) [self debugWithFormat:@"  allowed all for root ..."];
    return _oids;
  }
  
  /* process Teams */
  
  result  = [NSMutableArray arrayWithCapacity:[_oids count]];
  
  _oids = [self filterOutTeamGIDsFromArray:_oids
                addTeamsToArray:result];
  
  if (![_oids isNotEmpty]) /* found only teams */
    return result;
  
  {
    NSArray      *objects, *teams;
    NSDictionary *accessCache;
    id           obj;
    
    objects = [self fetchCompanyPermAttrsForGIDs:_oids];
    TIME_END();
    
    // TODO: explain that section
    
    accessCache = [self accessCacheForObjects:objects];
    
    teams = [self _fetchTeamsForPersonID:_accessGID buildGids:YES];
    
    enumerator = [objects objectEnumerator];
    while ((obj = [enumerator nextObject]) != nil) {
      NSDictionary *cache;
      
      cache = [accessCache objectForKey:[obj valueForKey:@"globalID"]];
      if ([self _checkAccess:_operation forCompanyPermRecord:obj
                accessGID:(EOKeyGlobalID *)_accessGID
                teamGIds:teams
                cache:cache]) {
        [result addObject:[obj valueForKey:@"globalID"]];
      }
      else if (!_all) // TODO: explain
	break;
    }
  }
  return result;
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
  
  if ([self isAccessGIDRoot:_accessGID]) {
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

@end /* SkyContactsAccessHandler */
