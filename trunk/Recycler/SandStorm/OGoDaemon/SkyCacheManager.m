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

#include "SkyCacheManager.h"
#include "common.h"
#include "SkyCacheResult.h"
#include <EOControl/EOKeyGlobalID.h>

@interface SkyCacheManager(PrivateMethods)
- (void)_checkIfCacheDirExists:(NSString *)_cacheDir;
- (NSMutableArray *)_getCachedElementIdsFromDirectory:(NSString *)_directory;
- (EOKeyGlobalID *)_globalIDForFileName:(NSString *)_fileName;
- (NSString *)_fileNameForGlobalID:(EOKeyGlobalID *)_gid;
@end /* SkyCacheManager(PrivateMethods( */

@implementation SkyCacheManager

/* initialization */

- (id)initWithDirectory:(NSString *)_directory {
  if ((self = [super init])) {
    NSUserDefaults *ud;
    NSString       *debug;

    ud = [NSUserDefaults standardUserDefaults];

    self->cacheDirectory = [_directory copy];
    [self _checkIfCacheDirExists:self->cacheDirectory];
    self->versionsForIds = [[NSMutableDictionary alloc] initWithCapacity:16];
    self->containedIds = [self _getCachedElementIdsFromDirectory:
                               self->cacheDirectory];
    self->debugMode =
      ((debug = [ud valueForKey:@"SkyCacheManagerDebugEnabled"]) != nil)
      ? [debug boolValue]
      : YES;

    if (self->debugMode)
      NSLog(@"--- got %d precached entries from directory %@",
            [self->containedIds count], _directory);
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->cacheDirectory);
  RELEASE(self->containedIds);
  [super dealloc];
}

/* accessors */

- (NSString *)cacheDirectory {
  return self->cacheDirectory;
}

- (NSArray *)containedIds {
  return self->containedIds;
}

/* methods */

- (NSDictionary *)versionElementForGID:(EOKeyGlobalID *)_gid {
  NSMutableDictionary *result;
  NSNumber *version;
  id object;
  NSArray *containedOIDs;
  NSString *fileName;
  NSFileManager *fm;

  fm = [NSFileManager defaultManager];

  object = [self->versionsForIds valueForKey:
                [[_gid keyValuesArray] objectAtIndex:0]];

  version = [object valueForKey:@"version"];

  if ((fileName = [object valueForKey:@"fileName"]) != nil) {
    if (![fm fileExistsAtPath:fileName])
      return nil;
  }
  
  result = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                _gid,    @"gid",
                                version, @"version",
                                nil];

  if ((containedOIDs = [object valueForKey:@"containedOIDs"]) != nil) {
    [result setObject:containedOIDs forKey:@"containedOIDs"];
  }

  return result;
}

- (SkyCacheResult *)cacheResultForGIDs:(NSArray *)_globalIDs {
  NSMutableArray *cachedGids;
  NSMutableArray *uncachedGids;
  NSEnumerator   *gidEnum;
  id gid;
  int cachedCount, allCount;
  
  cachedGids = [NSMutableArray arrayWithCapacity:8];
  uncachedGids = [NSMutableArray arrayWithCapacity:8];
  
  gidEnum = [_globalIDs objectEnumerator];
  while ((gid = [gidEnum nextObject])) {
    if ([self->containedIds containsObject:gid]) {
      NSDictionary *dict;

      if ((dict = [self versionElementForGID:gid]) != nil)
        [cachedGids addObject:dict];
      else {
        [uncachedGids addObject:gid];
      }
    }
    else {
      [uncachedGids addObject:gid];
    }
  }

  cachedCount = [cachedGids count];
  allCount    = [_globalIDs count];

  NSLog(@"--- cacheResult - cached #: %d  uncached #: %d",
        cachedCount, allCount - cachedCount);

  return [SkyCacheResult resultWithCacheManager:self
                         cachedElements:cachedGids
                         uncachedIDs:uncachedGids];
}

- (void)forgetIds:(NSArray *)_ids {
  NSEnumerator *idEnum;
  EOKeyGlobalID *gid;

  idEnum = [_ids objectEnumerator];
  while ((gid = [idEnum nextObject])) {
    if (self->debugMode)
      [self debugWithFormat:@"--- forgetting ID '%@'", gid];
    [self->containedIds removeObject:gid];
    [self->versionsForIds removeObjectForKey:[[gid keyValuesArray]
                                                   objectAtIndex:0]];
  }
}

- (NSArray *)objectsForGIDs:(NSArray *)_gids {
  NSMutableArray *result;
  NSEnumerator *gidEnum;
  EOKeyGlobalID *gid;
  
  result = [NSMutableArray arrayWithCapacity:[_gids count]];
  gidEnum = [_gids objectEnumerator];
  while ((gid = [gidEnum nextObject])) {
    NSString *fileName;
    NSDictionary *fileContents;
    id key;

    key = [[gid keyValuesArray] objectAtIndex:0];

    fileName = [[self->versionsForIds valueForKey:key]
                                      valueForKey:@"fileName"];
    fileContents = [NSDictionary dictionaryWithContentsOfFile:fileName];
    if (fileContents != nil)
      [result addObject:fileContents];
  }
  return result;
}

- (NSArray *)cacheObjects:(NSArray *)_objects forGlobalIDs:(NSArray *)_gids {
  int i;
  NSMutableArray *cacheElements;

  if (self->debugMode)
    NSLog(@"--- caching %d entries", [_gids count]);
  
  if ([_objects count] != [_gids count]) {
    [self logWithFormat:@"error: sizes of objects and gids array don't match"];
    return nil;
  }
  
  cacheElements = [NSMutableArray arrayWithCapacity:[_gids count]];
  
  for (i = 0; i < [_objects count]; i++) {
    NSMutableDictionary *object;
    EOKeyGlobalID *gid;
    NSMutableDictionary *versionStruct;
    NSString *fileName;
    NSArray *containedOIDs;
    
    object = [[_objects objectAtIndex:i] mutableCopy];
    gid = [_gids objectAtIndex:i];

    [object removeObjectForKey:@"globalID"];
    
    fileName = [self _fileNameForGlobalID:gid];
    
    // write to file
    [object writeToFile:fileName atomically:YES];
    
    // add to index structure
    [self->containedIds addObject:gid];

    versionStruct = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                         [object valueForKey:@"objectVersion"],
                                         @"version",
                                         fileName, @"fileName",
                                         nil];

    if ((containedOIDs = [object valueForKey:@"containedOIDs"]) != nil) {
      [versionStruct setObject:containedOIDs forKey:@"containedOIDs"];
    }

    [self->versionsForIds setObject:versionStruct forKey:
         [[gid keyValuesArray] objectAtIndex:0]];

    [cacheElements addObject:[self versionElementForGID:gid]];

    RELEASE(object); object = nil;
  }
  return cacheElements;
}

/* description */

- (NSString *)description {
  return [NSString stringWithFormat:@"<0x%08X[%@]: count: %d>",
                   self, NSStringFromClass([self class]),
                   [[self containedIds] count]];
}

@end /* SkyCacheManager */

@implementation SkyCacheManager(PrivateMethods)

- (NSFileManager *)fileManager {
  return [NSFileManager defaultManager];
}

- (void)_checkIfCacheDirExists:(NSString *)_cacheDir {
  NSFileManager *fm;
  BOOL isDir;
  
  fm = [self fileManager];

  if (([fm fileExistsAtPath:_cacheDir isDirectory:&isDir]) && isDir) {
    return;
  }
  else if (!isDir) {
    [self logWithFormat:@"Couldn't create cache directory"];
  }
  else {
    [self debugWithFormat:@"creating cache directory"];
    [fm createDirectoryAtPath:_cacheDir attributes:nil];
  }
}

- (NSMutableArray *)_getCachedElementIdsFromDirectory:(NSString *)_directory {
  NSArray *files;
  NSMutableArray *ids;

  files = [[self fileManager] directoryContentsAtPath:[self cacheDirectory]];

  ids = [NSMutableArray arrayWithCapacity:[files count]];

  NSLog(@"--- initializing cache with %d files", [files count]);
  
  if ([files count] > 0) {
    NSEnumerator *fileEnum;
    NSString     *file;
    NSString     *cacheDir;

    cacheDir = [self cacheDirectory];
    
    fileEnum = [files objectEnumerator];
    while ((file = [fileEnum nextObject])) {
      [ids addObject:[self _globalIDForFileName:
                           [cacheDir stringByAppendingPathComponent:file]]];
    }
  }
  return ids;
}

- (NSURL *)_skyrixBaseURL {
  static NSURL *skybase = nil;

  if (skybase == nil) {
    NSString *skyid;
    NSString *urlstr;
    
    skyid = [[NSUserDefaults standardUserDefaults] stringForKey:@"skyrix_id"];
    
    NSAssert([skyid length] > 0,
             @"missing SKYRiX ID (skyrix_id default) !");
    
    urlstr  = [NSString stringWithFormat:@"skyrix://%@/%@/",
                          [[NSHost currentHost] name],
                          skyid];
    
    skybase = [[NSURL alloc] initWithString:urlstr relativeToURL:nil];
  }
  return skybase;
}

- (EOKeyGlobalID *)_globalIDForObjectId:(NSString *)_objectId {
  NSNumber *oidNumber;

  oidNumber = [NSNumber numberWithInt:[_objectId intValue]];
  
  return [EOKeyGlobalID globalIDWithEntityName:@"Person"
                        keys:&oidNumber
                        keyCount:1
                        zone:nil];
}

- (NSString *)_fileNameForGlobalID:(EOKeyGlobalID *)_gid {
  if (_gid != nil) {
    NSString *fileName;

    fileName = [self cacheDirectory];
    fileName = [fileName stringByAppendingPathComponent:
                                  [[[_gid keyValuesArray] objectAtIndex:0]
                                          stringValue]];
    return [fileName stringByAppendingPathExtension:@"plist"];
  }
  [self logWithFormat:@"ERROR: no global ID specified"];
  return nil;
}

- (EOKeyGlobalID *)_globalIDForFileName:(NSString *)_fileName {
  NSString *objectId;
  NSDictionary *file;
  EOKeyGlobalID *gid;
  
  file = [NSDictionary dictionaryWithContentsOfFile:_fileName];
  
  objectId = [[_fileName lastPathComponent] stringByDeletingPathExtension];
  gid = [self _globalIDForObjectId:objectId];

  if (gid != nil) {
    NSMutableDictionary *dict;
    NSArray *containedOIDs;

    dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                [file valueForKey:@"objectVersion"],
                                @"version",
                                _fileName, @"fileName",
                                nil];

    if ((containedOIDs = [file valueForKey:@"containedOIDs"]) != nil) {
      [dict setObject:containedOIDs forKey:@"containedOIDs"];
    }
                               
    [self->versionsForIds takeValue:dict
         forKey:[[gid keyValuesArray] objectAtIndex:0]];
  }
  return gid;
}
 
@end /* CacheManager(PrivateMethods) */
