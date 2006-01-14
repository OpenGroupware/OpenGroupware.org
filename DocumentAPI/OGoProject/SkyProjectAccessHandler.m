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

@interface SkyProjectAccessHandler : OGoAccessHandler
@end

#include "common.h"

@interface OGoAccessHandler(Internals)
- (BOOL)_checkGIDs:(NSArray *)_ids;
@end

@implementation SkyProjectAccessHandler

- (NSArray *)getProjectsForGIDs:(NSArray *)_gids {
  id                  *projs, *gids, obj;
  int                 gidCnt, projCnt;
  NSMutableDictionary *projCache;
  NSEnumerator        *enumerator;
  NSArray             *array;

  projCache = [[self context] valueForKey:@"_cache_project_access"];
  if (projCache == nil) {
    projCache = [NSMutableDictionary dictionaryWithCapacity:64];
    [[self context] takeValue:projCache forKey:@"_cache_project_access"];
  }
  projs = calloc([_gids count] + 1, sizeof(id));
  gids  = calloc([_gids count] + 1, sizeof(id));

  gidCnt  = 0;
  projCnt = 0;

  enumerator = [_gids objectEnumerator];

  while ((obj = [enumerator nextObject]) != nil) {
    id proj;
    
    if ((proj = [projCache objectForKey:[obj keyValues][0]])) {
      projs[projCnt] = proj;
      projCnt++;
    }
    else {
      gids[gidCnt] = obj;
      gidCnt++;
    }
  }
  if (gidCnt > 0) {
    array = [NSArray arrayWithObjects:gids count:gidCnt];
    array = [[self context] runCommand:@"project::get-by-globalid",
                            @"noAccessCheck", [NSNumber numberWithBool:YES],
                            @"gids", array, nil];

    [[self context] runCommand:@"project::get-company-assignments",
                @"objects",     array,
                @"relationKey", @"companyAssignments", nil];
    [[self context] runCommand:@"project::get-team",
                  @"objects", array, @"relationKey", @"team", nil];
    [[self context] runCommand:@"project::get-owner",
                  @"objects", array, @"relationKey", @"owner", nil];
    
    enumerator = [array objectEnumerator];

    while ((obj = [enumerator nextObject]) != nil) {
      EOKeyGlobalID *kid;

      kid = [obj valueForKey:@"globalID"];
      
      [projCache setObject:obj forKey:[kid keyValues][0]];
      projs[projCnt] = obj;
      projCnt++;
    }
  }
  array = [NSArray arrayWithObjects:projs count:projCnt];
  if (projs != NULL) free(projs); projs = NULL;
  if (gids  != NULL) free(gids);  gids  = NULL;
  return array;
}

static BOOL IgnoreAccess = NO;

+ (void)setIgnoreAccess:(BOOL)_b {
  IgnoreAccess = _b;
}

- (BOOL)operation:(NSString *)_operation
  allowedOnObjectIDs:(NSArray *)_oids
  forAccessGlobalID:(EOGlobalID *)_accessGID
{

  if (IgnoreAccess)
    return YES;
  
  if ([self _checkGIDs:_oids] == NO)
    return NO;
  
  if ([_operation isEqualToString:@"r"]) {
    NSArray *projs;
    NSArray *accProjs;

    projs    = [self getProjectsForGIDs:_oids];
    accProjs = [[self context] runCommand:@"project::check-get-permission",
                               @"object", projs, nil];

    if ([projs count] != [accProjs count]) {
      return NO;
    }
  }
  else if ([_operation isEqualToString:@"m"]  ||
           [_operation isEqualToString:@"w"]) {
    NSArray *projs;
    NSArray *accProjs;

    projs    = [self getProjectsForGIDs:_oids];
    accProjs = [[self context] runCommand:@"project::check-write-permission",
                               @"object", projs, nil];
    if ([projs count] != [accProjs count]) {
      return NO;
    }
  }
  else {
    NSLog(@"WARNING[%s]: operation %@ is not definded in %@",
          __PRETTY_FUNCTION__, _operation, self);
    return NO;
  }
  return YES;
}

- (NSArray *)_entityNames {
  static NSArray *entityNames = nil;

  if (entityNames == nil) {
    id name;

    name        = @"Project";
    entityNames = [[NSArray alloc] initWithObjects:&name count:1];
  }
  return entityNames;
}

@end


