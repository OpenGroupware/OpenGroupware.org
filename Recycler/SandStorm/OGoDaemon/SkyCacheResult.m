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

#include "SkyCacheResult.h"
#include "common.h"
#include "SkyCacheManager.h"

@implementation SkyCacheResult

/* initialization */

- (id)initWithCacheManager:(SkyCacheManager *)_cm
  cachedElements:(NSArray *)_cachedElements
  uncachedIDs:(NSArray *)_uncachedIds
{
  if ((self = [super init])) {
    self->cacheManager = [_cm retain];
    self->cachedElements = [_cachedElements mutableCopy];
    self->uncachedIds = [_uncachedIds mutableCopy];
  }
  return self;
}

+ (SkyCacheResult *)resultWithCacheManager:(SkyCacheManager *)_cm
  cachedElements:(NSArray *)_cachedElements
  uncachedIDs:(NSArray *)_uncachedIds
{ 
  id result;

  result = [[self alloc] initWithCacheManager:_cm
                         cachedElements:_cachedElements
                         uncachedIDs:_uncachedIds];
  return AUTORELEASE(result);
}

- (id)init {
  return [self initWithCacheManager:nil
               cachedElements:nil
               uncachedIDs:nil];
}

- (void)dealloc {
  RELEASE(self->cacheManager);
  RELEASE(self->cachedElements);
  RELEASE(self->uncachedIds);

  [super dealloc];
}

/* accessors */

- (SkyCacheManager *)cacheManager {
  return self->cacheManager;
}

- (NSArray *)cachedElements {
  return self->cachedElements;
}

- (NSArray *)uncachedIds {
  return self->uncachedIds;
}

- (NSArray *)allObjects {
  NSMutableArray *gids;
  NSArray *result;

  gids = [NSMutableArray arrayWithArray:self->uncachedIds];
  [gids addObjectsFromArray:[[self cachedElements] valueForKey:@"gid"]];
  result = [self->cacheManager objectsForGIDs:gids];
  return result;
}

/* actions */

- (void)forgetIds:(NSArray *)_ids {
  NSEnumerator *idEnum;
  EOKeyGlobalID *gid;
  NSMutableArray *objectsToRemove;


  NSLog(@"--- forgetting %d IDs", [_ids count]);
  
  objectsToRemove = [NSMutableArray arrayWithCapacity:[_ids count]];
  
  // tell the cache manager to forget the IDs aswell
  [[self cacheManager] forgetIds:_ids];
  
  idEnum = [_ids objectEnumerator];
  while ((gid = [idEnum nextObject])) {
    NSEnumerator *elemEnum;
    NSDictionary *elem;

    elemEnum = [[self cachedElements] objectEnumerator];
    while ((elem = [elemEnum nextObject])) {
      if ([[elem objectForKey:@"gid"] isEqual:gid]) {
        [objectsToRemove addObject:elem];
        [self->uncachedIds addObject:gid];
       }
    }
  }
  [self->cachedElements removeObjectsInArray:objectsToRemove];
}

- (void)cacheObjects:(NSArray *)_objects forGlobalIDs:(NSArray *)_gids {
  NSArray *cacheElements;

  NSLog(@"--- caching %d objects for %d GIDs",
        [_objects count], [_gids count]);
  
  cacheElements = [[self cacheManager] cacheObjects:_objects
                                       forGlobalIDs:_gids];

  // add cached elements to cachedElements array and delete
  // the corresponding GIDs from the uncachedIds array
  [self->cachedElements addObjectsFromArray:cacheElements];

  [self->uncachedIds removeAllObjects];
  //[self->uncachedIds removeObjectsInArray:_gids];
}

/* description */

- (NSString *)description {
  return [NSString stringWithFormat:@"<0x%08X[%@]: cached#: %d uncached#: %d>",
                   self, NSStringFromClass([self class]),
                   [[self cachedElements] count],
                   [[self uncachedIds] count]];
}

@end /* SkyCacheResult */
