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

@interface SkyDocumentAccessHandler : SkyAccessHandler
@end

#include <OGoDatabaseProject/SkyProjectFileManager.h>
#include "common.h"

@interface SkyProjectFileManagerCache
+ (id)cacheWithContext:(id)_context projectGlobalID:(EOGlobalID *)_gid;
- (id)project;
@end

@interface SkyAccessHandler(Internals)
- (BOOL)_checkGIDs:(NSArray *)_ids;
@end /* SkyAccessHandler(Internals) */
@interface SkyDocumentAccessHandler(Internals)
- (BOOL)operation:(NSString *)_operation
  allowedOnObjectIDs:(NSArray *)_oids
  forAccessGlobalID:(EOGlobalID *)_accessGID
  cache:(NSMutableDictionary *)_cache;

@end /* SkyAccessHandler(Internals) */

@implementation SkyDocumentAccessHandler

static NSArray *entityNames = nil;

+ (void)initialize {
  if (entityNames == nil) {
    entityNames = [[NSArray alloc] initWithObjects:
				     @"Doc", @"DocumentEditing",
				     @"DocumentVersion", nil];
  }
}

- (BOOL)_checkAccessMask:(NSString *)_mask with:(NSString *)_operation {
  int maskCnt;
  int opCnt, i;
  
  maskCnt = [_mask length];
  opCnt   = [_operation length];

  if (maskCnt < opCnt)
    return NO;
  
  for (i = 0;  i < opCnt; i++) {
    NSString *subStr;

    subStr = [_operation substringWithRange:NSMakeRange(i,1)];
    if ([_mask rangeOfString:subStr].length == 0)
      return NO;
  }
  return YES;
}

- (NSArray *)_fetchTeamsForPersonID:(NSNumber *)_gid buildGids:(BOOL)_gids {
  NSDictionary *acc;
  NSArray      *teamIds;
  
  acc = [NSDictionary dictionaryWithObject:_gid forKey:@"companyId"];
  
  teamIds = [[self context] runCommand:@"account::teams", @"account", acc,nil];
  teamIds = _gids
    ? [teamIds map:@selector(globalID)]
    : [teamIds map:@selector(valueForKey:) with:@"companyId"];
  return teamIds;
}

- (NSArray *)_fetchTeamsForPersonID:(NSNumber *)_gid {
  return  [self _fetchTeamsForPersonID:_gid buildGids:NO];
}

- (int)_checkAccessForAssigments:(NSArray *)_ass
  companyIds:(NSArray *)_companyIds
  operation:(NSString *)_op
{ /* check whether person id is in assignments */
  NSEnumerator *compEnum;
  NSNumber     *kid;
  int          res;
  
  res = -1;
  compEnum = [_companyIds objectEnumerator];
  while ((kid = [compEnum nextObject])) {
    NSEnumerator *enumerator;
    id           obj;

    enumerator = [_ass objectEnumerator];
    while ((obj = [enumerator nextObject])) {
      if ([[obj valueForKey:@"companyId"] isEqual:kid]) {
        if ([self _checkAccessMask:[obj valueForKey:@"accessRight"]
                  with:_op]) { /* access matched */
          return 1;
        }
        else { /* access doesn`t match/ take a look for other teams */
          res = 0;
        }
      }
    }
  }
  return res;
}

- (BOOL)_checkProjectAccess:(id)_project person:(NSNumber *)personKID
  operation:(NSString *)_operation
{
  id      accessTeamId;
  NSArray *teamIds, *assignments;

  if (![_project isNotNull]) {
    NSLog(@"WARNING[%s]: missing project ");
    return NO;
  }
  
  teamIds      = nil;
  accessTeamId = [_project valueForKey:@"teamId"];
  
  if ([accessTeamId isNotNull]) {
    teamIds = [self _fetchTeamsForPersonID:personKID];
    if ([teamIds containsObject:accessTeamId]) { /* is in accessTeam */
      return YES;
    }
  }
  assignments = [[self context] runCommand:@"project::get-company-assignments",
                                @"object", _project, nil];
  {
    int checkResult;
    checkResult = [self _checkAccessForAssigments:assignments
                        companyIds:[NSArray arrayWithObject:personKID]
                        operation:_operation];
    if (checkResult == 1)
      return YES;
    if (checkResult == 0)
      return  NO;
  }
  { /* now check, whether an team assignment exist */
    int checkResult;

    if (teamIds == nil)
      teamIds = [self _fetchTeamsForPersonID:personKID];
        
    checkResult = [self _checkAccessForAssigments:assignments
                        companyIds:teamIds operation:_operation];
    if (checkResult == 1)
      return YES;
    if (checkResult == 0)
      return  NO;
  }
  return NO;
}

- (int)_checkAccessFor:(EOGlobalID *)_gid withCache:(NSDictionary *)_dgids
  account:(EOGlobalID *)_account teamIds:(NSArray *)_teams
  operation:(NSString *)_operation
{
  // TODO: document method
  NSDictionary *dict;
  int          result;
  NSString     *access;
  NSEnumerator *enumerator;
  id           teamObj;

  result = 1;
  
  if ((dict = [_dgids objectForKey:_gid]) == nil)
    return -1;

  result = 0;
  
  if ((access = [dict objectForKey:_account])) /* account was set */
    result = [self _checkAccessMask:access with:_operation] ? 1 : 0;
  
  if (result != 0)
    return result;
  
  /* now check teams */
  
  enumerator = [_teams objectEnumerator];
  while ((teamObj = [enumerator nextObject])) {
    if ((access = [dict objectForKey:teamObj]) == nil)
      continue;

    /* team was set */
    if ([self _checkAccessMask:access with:_operation]) {
      result = 1;
      break;
    }
    
    result = 0;
  }
  return result;  
}


- (BOOL)operation:(NSString *)_operation
  allowedOnObjectIDs:(NSArray *)_oids
  forAccessGlobalID:(EOGlobalID *)_accessGID
{
  return [self operation:_operation allowedOnObjectIDs:_oids
               forAccessGlobalID:_accessGID cache:nil];
}

- (BOOL)isRootPrimaryKey:(NSNumber *)_pkey {
  if (_pkey == nil) 
    return NO;
  
  return [_pkey intValue] == 10000 ? YES : NO;
}

- (BOOL)operation:(NSString *)_operation
  allowedOnObjectIDs:(NSArray *)_oids
  forAccessGlobalID:(EOGlobalID *)_accessGID
  cache:(NSMutableDictionary *)_cache
{
  // TODO: split up this huge method!
  NSString         *accessEntity;
  EOKeyGlobalID    *keyGID;
  SkyAccessManager *manager;
  EOGlobalID       *pGID;
  BOOL             result;
  id               project = nil;
  NSArray          *teamIds;

  result  = YES;
  manager = [[self context] accessManager];

  if ([_oids count] == 0)
    return YES;

  NSAssert1([_accessGID isKindOfClass:[EOKeyGlobalID class]],
            @"unsupported gid %@", _accessGID);
  
  keyGID       = (EOKeyGlobalID *)_accessGID;
  accessEntity = [keyGID entityName];
  
  if ([accessEntity isEqualToString:@"Person"]) {
    NSNumber *personKID;
    id obj;

    personKID = [keyGID keyValues][0];
    
    if ([self isRootPrimaryKey:personKID])
      return YES;
    
    /* all objects must have the same project */
    teamIds = [self _fetchTeamsForPersonID:personKID buildGids:YES];      
    obj     = [_oids objectAtIndex:0];
    pGID    = [SkyProjectFileManager projectGlobalIDForDocumentGlobalID:obj
				     context:[self context]];
    if (pGID == nil) {
        NSLog(@"ERROR[%s]: missing project id for doc %@", __PRETTY_FUNCTION__,
              obj);
    }
    else {
        if (_cache) {
          NSNumber            *access, *pid;
          NSMutableDictionary *dict;

          dict   = [_cache objectForKey:@"managerProjects"];
          if (!dict) {
            dict = [NSMutableDictionary dictionaryWithCapacity:8];
            [_cache setObject:dict forKey:@"managerProjects"];
          }
          pid    = [[(EOKeyGlobalID *)pGID keyValuesArray] lastObject];
          access = [dict objectForKey:pid];

          if (access == nil) {
            if ([manager operation:@"m" allowedOnObjectID:pGID
                         forAccessGlobalID:_accessGID]) {
              access = [NSNumber numberWithBool:YES];
            }
            else {
              access = [NSNumber numberWithBool:NO];
            }
            [dict setObject:access forKey:pid];
          }
          if ([access  boolValue]) /* found project manager */
            return YES;
        }
        else {
          if ([manager operation:@"m" allowedOnObjectID:pGID
                       forAccessGlobalID:_accessGID]) {
            return YES;
          }
        }
        project = [[SkyProjectFileManagerCache cacheWithContext:[self context]
                                               projectGlobalID:pGID] project];

        if ([[project valueForKey:@"ownerId"] isEqual:personKID])
          /* is owner */
          return YES;

        if ([_operation rangeOfString:@"r"].length > 0) {
          if (![self _checkProjectAccess:project person:personKID
                     operation:@"r"]) {
            return NO;
          }
        }
    }
    
    /* now check document and parents */
    {
      NSDictionary          *dgids;
      SkyProjectFileManager *fm;
      NSEnumerator          *enumerator;
      id                    obj;
      NSMutableSet          *gids;

      fm         = [[SkyProjectFileManager alloc] initWithContext:[self context]
                                                  projectGlobalID:pGID];
      gids       = [[NSMutableSet alloc] initWithCapacity:64];
      enumerator = [_oids objectEnumerator];
      
      while ((obj = [enumerator nextObject])) {
        NSString *path;

        path = [fm pathForGlobalID:obj];
        while (path) {
          EOGlobalID *gid;

          gid = [fm globalIDForPath:path];
          NSAssert1(gid, @"missing globalIDForPath %@", path);
          
          [gids addObject:gid];

          path = ([path isEqualToString:@"/"])
            ? nil : [path stringByDeletingLastPathComponent];
        }
      }
      {
        /* fetch cache */
        dgids = [manager allowedOperationsForObjectIds:[gids allObjects]
                         accessGlobalIDs:nil];

        /* now go throw the tree */
        enumerator = [_oids objectEnumerator]; 

        result = YES; /* access for project is allowed */
        
        while ((obj = [enumerator nextObject])) { /* go throw documents */
          NSString *path;

          path = [fm pathForGlobalID:obj]; /* got start path */
          while (path) {
            int        res;
            EOGlobalID *gid;
            
            gid = [fm globalIDForPath:path]; /* got gid for path */
            NSAssert1(gid, @"missing globalIDForPath %@", path);

            if ((res = [self _checkAccessFor:gid withCache:dgids
                             account:_accessGID
                             teamIds:teamIds operation:_operation]) != -1) {
              result = (res == 1) ? YES : NO;

              if ([_operation rangeOfString:@"r"].length > 0) { /* r == x */
                if (!result)
                  break;
              } 
              else {
                break;
              }
            }
            /* next path */
            if ([path isEqualToString:@"/"])
              path = nil;
            else
              path = [path stringByDeletingLastPathComponent];
          }
          if (!result)
            break;
        }
        if (obj == nil && ([_operation rangeOfString:@"r"].length == 0)) {
          /* found no access */
          result = [self _checkProjectAccess:project person:personKID
                         operation:_operation];
        }
      }
      [fm   release]; fm   = nil;
      [gids release]; gids = nil;
    }
  }
  return result;
}

- (NSArray *)objects:(NSArray *)_oids
  forOperation:(NSString *)_str
  forAccessGlobalID:(EOGlobalID *)_accessGID
{
  NSMutableArray      *a;
  NSEnumerator        *enumerator;
  id                  obj;
  NSMutableDictionary *cache;
  EOKeyGlobalID       *keyGID;
  NSString            *accessEntity;
  
  keyGID       = (EOKeyGlobalID *)_accessGID;
  accessEntity = [keyGID entityName];

  if ([accessEntity isEqualToString:@"Person"]) {
    NSNumber *personKID;

    personKID = [keyGID keyValues][0];
    
    if ([self isRootPrimaryKey:personKID])
      return _oids;
  }
  
  cache      = [[NSMutableDictionary alloc] initWithCapacity:64];
  a          = [NSMutableArray array];
  enumerator = [_oids objectEnumerator];

  while ((obj = [enumerator nextObject])) {
    if ([self operation:_str allowedOnObjectIDs:[NSArray arrayWithObject:obj]
              forAccessGlobalID:_accessGID cache:cache])
      [a addObject:obj];
  }
  [cache release]; cache = nil;
  return a;
}

- (NSArray *)_entityNames {
  return entityNames;
}

@end /* SkyDocumentAccessHandler */
