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

#include <LSFoundation/SkyAccessHandler.h>

@interface SkyContactsAccessHandler : SkyAccessHandler
@end

#include "common.h"
#include "timing.h"
#include <EOControl/EOControl.h>
#include <LSFoundation/LSFoundation.h>
#include <OGoContacts/SkyPersonDataSource.h>
#include <OGoContacts/SkyEnterpriseDataSource.h>

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
  int maskCnt;
  int opCnt;
  int i;
  
  if (debugOn)
    [self debugWithFormat:@"check mask: '%@' with '%@'", _mask, _operation];

  if ([_mask length] == 0 || [_operation length] == 0) {
    if (debugOn) [self debugWithFormat:@"  one parameter is empty => NO"];
    return NO;
  }
  
  maskCnt = [_mask length];
  opCnt   = [_operation length];

  if (maskCnt < opCnt) {
    if (debugOn) [self debugWithFormat:@"  op is longer than mask => NO"];
    return NO;
  }

  for (i = 0;  i < opCnt; i++) {
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

- (NSArray *)_fetchTeamsForPersonID:(NSNumber *)_gid buildGids:(BOOL)_gids {
  NSDictionary *acc;
  NSArray      *teamIds;
  
  if (_gid == nil) return nil;
  
  if (debugOn) 
    [self debugWithFormat:@"  fetch teams for person gid: %@", _gid];
  
  acc = [NSDictionary dictionaryWithObject:_gid forKey:@"companyId"];

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

- (BOOL)_checkAccess:(NSString *)_operation
  forObj:(id)_obj
  accessGID:(EOKeyGlobalID *)_accessGID
  teamGIds:(NSArray *)_teamsGIDs
  cache:(NSDictionary *)_cache
{
  NSNumber     *accessID, *ownerID;
  NSString     *accessStr;
  NSEnumerator *enumerator;
  id           teamID;
  EOGlobalID   *gid;
  NSNumber     *gidId;


  if ([[_obj entityName] isEqualToString:@"Team"])
    return YES;
  
  gid      = [_obj valueForKey:@"globalID"];
  gidId    = [[(EOKeyGlobalID *)gid keyValuesArray] lastObject];
  accessID = [_accessGID keyValues][0];
  ownerID  = [_obj valueForKey:@"ownerId"];
  
  if ([ownerID isEqual:accessID]) {
    return YES;
  }

  if ([_accessGID isEqual:gid] && [_operation isEqualToString:@"r"])
    return YES;
  

  if (![_cache count]) { /* no access was set */
    if ([[_obj valueForKey:@"isPrivate"] boolValue]) {
      [self cacheOperation:@"" for:gidId];
      return NO;
    }

    if ([[_obj valueForKey:@"isReadonly"] boolValue] &&
        [_operation isEqualToString:@"w"]) {
      [self cacheOperation:@"r" for:gidId];
      return NO;
    }
    [self cacheOperation:@"rw" for:gidId];
    return YES;
  }

  accessStr = [_cache objectForKey:_accessGID];
  /* cache access */
  {
    int      bitmap;
    NSString *str;

    bitmap = 0;

    if ([accessStr length] > 0 && 
	([accessStr rangeOfString:@"r"].length > 0)) {
      bitmap |= 1;
    }

    if ([accessStr length] > 0 && 
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

- (NSArray *)objects:(NSArray *)_oids
  forOperation:(NSString *)_operation
  forAccessGlobalID:(EOGlobalID *)_accessGID
  searchAll:(BOOL)_all
{
  SkyAccessManager *manager;
  NSMutableArray   *result;
  NSEnumerator     *enumerator;
  id               obj, *objs;
  int              cnt;

  if ([_oids count] == 0)
    return _oids;

  if ([[(EOKeyGlobalID *)_accessGID keyValues][0] intValue] == 10000)
    return _oids;
  
  /* make gids set distinct */
  {
    NSSet *set;
    
    set = _oids ? [NSSet setWithArray:_oids] : nil;
    _oids = [set allObjects];
  }
  
  manager    = [[self context] accessManager];
  result     = [NSMutableArray arrayWithCapacity:[_oids count]];
  enumerator = [_oids objectEnumerator];

  cnt  = 0;
  objs = calloc([_oids count] + 2, sizeof(id));

  while ((obj = [enumerator nextObject])) {
    if ([[obj entityName] isEqualToString:@"Team"])
      [result addObject:obj];
    else {
      objs[cnt] = obj;
      cnt++;
    }
  }
  _oids = [NSArray arrayWithObjects:objs count:cnt];

  if (objs) free(objs); objs = NULL;

  if ([_oids count] == 0)
    return result;

  
  {
    NSArray      *objects, *teams;
    NSDictionary *accessCache;
    NSNumber     *ppkey;
    id           obj;
    
    objects = [[self context] runCommand:@"object::get-by-globalID",
                       @"gids",          _oids,
                       @"noAccessCheck", [NSNumber numberWithBool:YES],
                       @"attributes",    contactPermAttrs, nil];
    TIME_END();
    
    if ([objects count] != [_oids count]) {
      [self logWithFormat:
	      @"ERROR[%s] could not fetch all persons oids[%d] objects[%d]",
              __PRETTY_FUNCTION__, [_oids count], [objects count]];
    }
    ppkey = _accessGID ? [(EOKeyGlobalID *)_accessGID keyValues][0] : nil;
    teams = [self _fetchTeamsForPersonID:ppkey buildGids:YES];
    {
      NSArray *oids;

      oids        = [objects map:@selector(valueForKey:) with:@"globalID"];
      accessCache = [manager allowedOperationsForObjectIds:oids
                             accessGlobalIDs:nil];
    }
    
    enumerator = [objects objectEnumerator];
    while ((obj = [enumerator nextObject])) {
      id cache;
      
      cache = [accessCache objectForKey:
			     (EOGlobalID *)[obj valueForKey:@"globalID"]];
      if ([self _checkAccess:_operation forObj:obj
                accessGID:(EOKeyGlobalID *)_accessGID
                teamGIds:teams
                cache:cache]) {
        [result addObject:[obj valueForKey:@"globalID"]];
      }
      else if (!_all)
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

  if ([[(EOKeyGlobalID *)_accessGID keyValues][0] intValue] == 10000)
    return YES;

  res = [self objects:_oids forOperation:_operation 
	      forAccessGlobalID:_accessGID
              searchAll:NO];

  return (BOOL)([res count] == [_oids count]);
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
