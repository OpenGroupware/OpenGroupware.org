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
// $Id$

#include "SkyContactAction+Caching.h"
#include "common.h"
#include "SkyContactApplication.h"
#include "SkyContactAction+Conversion.h"
#include "SkyContactAction+PrivateMethods.h"

#include <OGoDaemon/SkyCacheManager.h>
#include <OGoDaemon/SkyCacheResult.h>

@implementation SkyContactAction(Caching)

- (SkyContactApplication *)application {
  static Class AppClass = Nil;
  if (AppClass == Nil) AppClass = [SkyContactApplication class];
  return [AppClass application];
}

/* cache accessors */

- (SkyCacheManager *)listCache {
  static SkyCacheManager *lc = nil;

  if (lc == nil)
    lc = [[[self application] listCache] retain];
  return lc;
}

- (SkyCacheManager *)participantsCache {
  static SkyCacheManager *pc = nil;

  if (pc == nil)
    pc = [[[self application] participantsCache] retain];
  return pc;
}

- (SkyCacheManager *)enterpriseCache {
  static SkyCacheManager *ec = nil;

  if (ec == nil)
    ec = [[[self application] enterpriseCache] retain];
  return ec;
}

/* methods used for cache operations */

- (NSArray *)checkForInvalidatedElementsFromFetch:(NSArray *)_fetch
  inArray:(NSArray *)_cachedElements
{
  NSMutableArray *idsToForget;
  NSEnumerator *cachedElemEnum;
  NSDictionary *cachedElement;

  NSLog(@"--- checking for invalidated elements");
  
  idsToForget = [NSMutableArray arrayWithCapacity:8];

  cachedElemEnum = [_cachedElements objectEnumerator];
  while ((cachedElement = [cachedElemEnum nextObject])) {
    NSEnumerator *fetchElemEnum;
    NSDictionary *fetchElem;
    int cachedVersion;
    EOKeyGlobalID *cachedID;
    
    cachedID = [cachedElement valueForKey:@"gid"];
    cachedVersion = [[cachedElement valueForKey:@"version"] intValue];
    
    fetchElemEnum = [_fetch objectEnumerator];
    while ((fetchElem = [fetchElemEnum nextObject])) {
      if ([[fetchElem valueForKey:@"globalID"] isEqual:cachedID]) {
        int fetchedVersion;

        fetchedVersion = [[fetchElem valueForKey:@"objectVersion"] intValue];

        if (fetchedVersion != cachedVersion) {
          NSLog(@"--- dropping object %@", cachedElement);

          [idsToForget addObject:[cachedElement valueForKey:@"gid"]];
        }
      }
    }
  }
  return idsToForget;
}

- (NSArray *)_fetchContactsWithGlobalIds:(NSArray *)_ids
  withEnterprises:(BOOL)_withEnterprises
{
  LSCommandContext *ctx;

  if (_ids == nil) {
    [self debugWithFormat:@"Invalid IDs...returning nil"];
    return nil;
  }
   
  if ((ctx = [self commandContext]) != nil) {
    NSArray *result;

    NSLog(@"-- executing command person::get-by-globalid");
    result = [ctx runCommand:@"person::get-by-globalid",
                  @"gids", _ids,
                  nil];

    NSLog(@"--- got %d results for %d GIDs", [_ids count], [result count]);
    
    [self _ensureCurrentTransactionIsCommitted];

    result = [self dictionariesForContactRecords:result
                   withEnterprises:_withEnterprises];
    
    return result;
  }
  [self logWithFormat:@"no valid context found"];
  return nil;
}

- (NSArray *)_fetchEnterprisesWithGlobalIds:(NSArray *)_ids {
  LSCommandContext *ctx;

  if (_ids == nil) {
    [self debugWithFormat:@"Invalid IDs...returning nil"];
    return nil;
  }
    
  if ((ctx = [self commandContext]) != nil) {
    NSArray *result;

    NSLog(@"-- executing command enterprise::get-by-globalid");
    result = [ctx runCommand:@"enterprise::get-by-globalid",
                  @"gids", _ids,
                  nil];
    
    NSLog(@"--- got %d results for %d GIDs", [_ids count], [result count]);

    [self _ensureCurrentTransactionIsCommitted];

    result = [self dictionariesForEnterpriseRecords:result];
    
    return result;
  }
  [self logWithFormat:@"no valid context found"];
  return nil;
}

- (NSArray *)personsForGlobalIDsAndVersions:(NSArray *)_gids
  withEnterprises:(BOOL)_withEnterprises
{
  SkyCacheResult *cr;
  NSArray *uncachedIds;
  NSArray *cachedElements;
  NSArray *idsToForget;
  SkyCacheManager *cm;

  if (_gids == nil) {
    [self debugWithFormat:@"Invalid IDs...returning nil"];
    return nil;
  }
  
  if (_withEnterprises)
    cm = [self participantsCache];
  else
    cm = [self listCache];

  cr = [cm cacheResultForGIDs:[_gids valueForKey:@"globalID"]];

  NSLog(@"--- cache result: %@", cr);
  
  cachedElements = [cr cachedElements];
  idsToForget = [self checkForInvalidatedElementsFromFetch:_gids
                      inArray:cachedElements];
  [cr forgetIds:idsToForget];

  NSLog(@"--- cache result after invalidating: %@", cr);
  
  uncachedIds = [cr uncachedIds];
  if ([uncachedIds count] > 0) {
    NSArray *fetchedElements;
    NSArray *ids;

    [self debugWithFormat:@"--- fetching %d uncached elements",
          [uncachedIds count]];
    
    fetchedElements = [self _fetchContactsWithGlobalIds:uncachedIds
                            withEnterprises:_withEnterprises];
    
    ids = [fetchedElements map:@selector(valueForKey:)
                           with:@"globalID"];

    [cr cacheObjects:fetchedElements
        forGlobalIDs:ids];
  }

  NSLog(@"--- returning %d objects", [[cr allObjects] count]);
  return [cr allObjects];
}

- (NSArray *)enterprisesForGlobalIDsAndVersions:(NSArray *)_gids
{
  SkyCacheResult *cr;
  NSArray *uncachedIds;
  NSArray *cachedElements;
  NSArray *idsToForget;

  if (_gids == nil) {
    [self debugWithFormat:@"Invalid IDs...returning nil"];
    return nil;
  }
  
  cr = [[self enterpriseCache]
              cacheResultForGIDs:[_gids valueForKey:@"globalID"]];

  cachedElements = [cr cachedElements];
  idsToForget = [self checkForInvalidatedElementsFromFetch:_gids
                      inArray:cachedElements];

  [cr forgetIds:idsToForget];
    
  uncachedIds = [cr uncachedIds];
  if ([uncachedIds count] > 0) {
    NSArray *fetchedElements;
    NSArray *ids;

    [self debugWithFormat:@"fetching %d uncached elements",
          [uncachedIds count]];
      
    fetchedElements = [self _fetchEnterprisesWithGlobalIds:uncachedIds];

    ids = [fetchedElements valueForKey:@"globalID"];
    [cr cacheObjects:fetchedElements
        forGlobalIDs:ids];
  }
  return [cr allObjects];
}

- (NSArray *)_idsForSearchCommand:(NSString *)_command
  arguments:(NSDictionary *)_arguments
{
  LSCommandContext *ctx;
  
  if ((ctx = [self commandContext])!= nil) {
    NSArray *gids;
    NSNumber *maxSearchCnt;

    NSLog(@"-- executing command %@", _command);
    gids = [ctx runCommand:_command
                arguments:_arguments];
     
    [self _ensureCurrentTransactionIsCommitted];
     
    if ((maxSearchCnt = [_arguments valueForKey:@"maxSearchCount"]) != nil) {
      if ([gids count] > [maxSearchCnt intValue]) {
        NSRange range;

        range.location = 0;
        range.length = [maxSearchCnt intValue];
        
        [self logWithFormat:@"WARNING: reached maxSearchCount (%@)",
              maxSearchCnt];

        return [gids subarrayWithRange:range];
      }
    }
    return gids;
  }
  [self logWithFormat:@"no valid context found"];
  return nil;
}

- (NSArray *)enterprisesForSearchCommand:(NSString *)_command
  arguments:(NSDictionary *)_arguments
{
  NSArray *gids;

  if (_arguments == nil) {
    [self debugWithFormat:@"Invalid arguments...returning nil"];
    return nil;
  }

  gids = [self _idsForSearchCommand:_command arguments:_arguments];
  if (gids != nil)
    return [self enterprisesForGlobalIDsAndVersions:gids];
  return nil;
}

- (NSArray *)personsForSearchCommand:(NSString *)_command
  arguments:(NSDictionary *)_arguments
  withEnterprises:(BOOL)_withEnterprises
{
  NSArray *gids;

  if (_arguments == nil) {
    [self debugWithFormat:@"Invalid arguments...returning nil"];
    return nil;
  }
  
  gids = [self _idsForSearchCommand:_command arguments:_arguments];

  if (gids != nil)
    return [self personsForGlobalIDsAndVersions:gids
                 withEnterprises:_withEnterprises];
  return nil;
}

@end /* SkyContactAction(Caching) */
