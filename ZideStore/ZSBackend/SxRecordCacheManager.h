/*
  Copyright (C) 2000-2003 SKYRIX Software AG

  This file is part of OGo

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
// $Id: SxRecordCacheManager.h 1 2004-08-20 11:17:52Z znek $

#ifndef __Backend_SxRecordCacheManager_H__
#define __Backend_SxRecordCacheManager_H__

#import <Foundation/NSObject.h>

/*
  SxRecordCacheManager
  
  This class is intended to manage a cache of individual, versioned records
  stored as a property list. A single cache can be used for a user for all
  OGo objects since OGo primary keys are unique across the database.
  
  Eg:
    /var/cache/zidestore/donald/10000-9-full.plist
  
  Could cache all attributes of the "root" person in object-version 9. Note
  that concurrency is no big problem because we write a new cache entry for
  each new version :-)
  
  Note: the pkey must be split up in subdirectories, since a filesystem can't
  deal with 1000000 records in a single directory ...

  Defaults:

    SxCachePath  (/var/cache/zidestore) - path for cache files
    SxDebugCache (NO)                   - a lot of cache debug infos
    SxMemoryCacheConfig                 - a dictionary to configure mem-cache
         {
            __type__ = __number_of_stored_entries__;
         }

         If __number_of_stored_entries__ equals -1 all objects will be stored.
         This default values can be modified with doMemCache and objCacheCnt
         accessors.
*/

@class NSString, NSException, NSFileManager, NSArray, NSMutableDictionary;

@interface SxRecordCacheManager : NSObject
{
  NSFileManager       *fm;
  NSString            *type; /* cache-type eg "full", "core" */
  NSArray             *dateAttributes;
  NSMutableDictionary *memCache;
  BOOL                doMemCache;
  int                 objCacheCnt;
}

+ (id)recordCacheForType:(NSString *)_type;
+ (id)recordCacheForType:(NSString *)_type dateAttributes:(NSArray *)_attrs;
- (id)initWithType:(NSString *)_type;

/* entries */

- (id)cacheEntryForKey:(int)_pkey inVersion:(int)_version;

- (NSException *)storeCacheEntry:(id)_entry 
  forKey:(int)_pkey inVersion:(int)_version;

- (NSArray *)dateAttributes;
- (void)setDateAttributes:(NSArray *)_date;

- (BOOL)doMemCache;
- (void)setDoMemCache:(BOOL)_memCache;
- (int)objCacheCnt;
- (void)setObjCacheCnt:(int)_cnt;

@end

#endif /* __Backend_SxRecordCacheManager_H__ */
