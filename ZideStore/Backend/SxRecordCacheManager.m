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
// $Id$

#include "SxRecordCacheManager.h"
#include "common.h"

@implementation SxRecordCacheManager

static NSString            *CachePath      = nil;
static BOOL                DebugOn         = NO;
static NSMutableDictionary *TypeToCache    = nil;
static NSDictionary        *MemCacheConfig = nil;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  DebugOn = [ud boolForKey:@"SxDebugCache"];
  
  if (CachePath == nil)
    CachePath = [[ud objectForKey:@"SxCachePath"] copy];
  if (CachePath == nil)
    CachePath = @"/var/cache/zidestore";
  
  [self logWithFormat:@"caching ZideStore objects in: '%@'", CachePath];

  if (MemCacheConfig == nil) {
    MemCacheConfig = [ud dictionaryForKey:@"SxMemoryCacheConfig"];
  }
}

+ (id)recordCacheForType:(NSString *)_type dateAttributes:(NSArray *)_attrs {
  SxRecordCacheManager *cm;
  
  if (_type == nil)
    return [[[self alloc] init] autorelease];

  if ((cm = [TypeToCache objectForKey:_type]))
    return cm;
  
  if (TypeToCache == nil)
    TypeToCache = [[NSMutableDictionary alloc] initWithCapacity:64];
  
  if ((cm = [[[self alloc] initWithType:_type] autorelease]) == nil)
    return nil;
  if (_attrs) [cm setDateAttributes:_attrs];
  
  if (DebugOn)
    [self logWithFormat:@"registered cache-manager for key %@", _type];
  [TypeToCache setObject:cm forKey:_type];
  return cm;
}
+ (id)recordCacheForType:(NSString *)_type {
  return [self recordCacheForType:_type dateAttributes:nil];
}

- (id)initWithType:(NSString *)_type {
  if ((self = [super init])) {
    self->memCache        = [[NSMutableDictionary alloc] init];
    self->fm              = [[NSFileManager defaultManager] retain];
    self->type            = [_type copy];
    self->objCacheCnt     = -1;
    self->doMemCache      = NO;

    if (self->type) {
      NSNumber *n;
      
      if ((n = [MemCacheConfig objectForKey:_type])) {
        self->objCacheCnt = [n intValue];
        self->doMemCache  = YES;

        if (DebugOn) [self debugWithFormat:@"mem cache for %@ objCacheCnt %d",
                           self->type, self->objCacheCnt];
      }
    }
  }
  return self;
}
- (id)init {
  return [self initWithType:nil];
}
- (void)dealloc {
  [self->dateAttributes release];
  [self->type           release];
  [self->fm             release];
  [super dealloc];
}

- (BOOL)isDebugEnabled {
  return DebugOn;
}

- (BOOL)doMemCache {
  return self->doMemCache;
}
- (void)setDoMemCache:(BOOL)_memCache {
  self->doMemCache = _memCache;
}

- (int)objCacheCnt {
  return self->objCacheCnt;
}
- (void)setObjCacheCnt:(int)_cnt {
  self->objCacheCnt = _cnt;
}

/* pathes */

- (NSString *)path {
  return [CachePath stringByAppendingPathComponent:self->type];}

- (NSArray *)dateAttributes {
  return self->dateAttributes;
}

- (void)setDateAttributes:(NSArray *)_date {
  ASSIGN(self->dateAttributes, _date);
}

- (BOOL)checkPath:(NSString *)_path {
  BOOL isDir;
  
  if (![self->fm fileExistsAtPath:_path isDirectory:&isDir]) {
    if (![self->fm createDirectoryAtPath:_path attributes:nil]) {
      [self logWithFormat:@"ERROR: couldn`t create directory: '%@'", _path];
      return NO;
    }
  }
  else if (!isDir) {
    [self logWithFormat:@"ERROR: path is no directory: '%@'", _path];
    return NO;
  }
  return YES;
}

- (NSString *)pathForKey:(int)_pkey inVersion:(int)_version {
  int      pre, suf;
  NSString *p;
  
  if (_pkey == 0) {
    [self logWithFormat:@"WARNING: got no primary key to calculate path !"];
    return nil;
  }
  pre = _pkey / 1000;
  suf = _pkey - (pre * 1000);
  
  if (![self checkPath:[self path]])
    return nil;
  
  p = [NSString stringWithFormat:@"%@/%04i", [self path], pre];
  
  if (![self checkPath:p])
    return nil;

  return [NSString stringWithFormat:@"%@/%04i-%04i.plist", p, suf,
                   _version];
}

/* entries */

- (void)storeMemCacheEntry:(id)_entry forKey:(int)_pkey {
  NSString *key;

  if ((int)[self->memCache count] >= self->objCacheCnt) {
    if (DebugOn) [self debugWithFormat:@"couldn`t cache obj %i in mem,"
                       @"objCacheCnt %d is reached (type %@)", _pkey,
                       self->objCacheCnt, self->type];
    return;
  }

  if (!_entry)
    return;
  
  key = [[NSNumber numberWithInt:_pkey] stringValue];

  if (key) {
    if (DebugOn) [self debugWithFormat:@"store entry in mem cache %i/%@",
                       _pkey, [_entry objectForKey:@"version"]];

    [self->memCache setObject:_entry forKey:key];
  }
}

- (id)memCacheEntryForKey:(int)_pkey inVersion:(int)_version {
  NSString *key;

  key = [[NSNumber numberWithInt:_pkey] stringValue];

  if (key) {
    id obj;

    obj = [self->memCache objectForKey:key];

    if ([[obj objectForKey:@"version"] intValue] == _version) {
    if (DebugOn) [self debugWithFormat:@"memCache hit %i/%i",
                       _pkey, _version];
      return obj;
    }
  }
  if (DebugOn) [self debugWithFormat:@"memCache miss %i/%i",
                     _pkey, _version];
  
  return nil;
}

- (id)cacheEntryForKey:(int)_pkey inVersion:(int)_version {
  NSMutableDictionary *dict;
  NSEnumerator        *enumerator;
  id                  key;
  NSString *p;

  if (self->doMemCache) {
    if ((dict = [self memCacheEntryForKey:_pkey inVersion:_version]))
      return dict;
  }
  
  p = [self pathForKey:_pkey inVersion:_version];

  if ([p length] == 0) return nil;
  
  if (![self->fm fileExistsAtPath:p isDirectory:NULL]) {
    if (DebugOn) [self debugWithFormat:@"cache miss: %i/%i", _pkey, _version];
    return nil;
  }
  if (DebugOn) [self debugWithFormat:@"cache hit: %i/%i", _pkey, _version];
  
  if (!(dict = [[NSMutableDictionary alloc] initWithContentsOfFile:p])) {
    [self logWithFormat:@"ERROR: failed to restore cache record: '%@'", p];
    
    /* delete broken cache entry */
    [self->fm removeFileAtPath:p handler:nil];
    return nil;
  }
  
  /* fixup date attributes */
  enumerator = [self->dateAttributes objectEnumerator];
  while ((key = [enumerator nextObject])) {
    id obj;
    
    obj = [dict objectForKey:key];
    
    /* what about nested plists ? */
    if ([obj length] > 0) {
      NSCalendarDate *date;
      
      if ((date = [[NSCalendarDate alloc] initWithString:obj])) {
        [dict setObject:date forKey:key];
        [date release];
      }
      else
        [dict removeObjectForKey:key];
    }
    else {
      [dict removeObjectForKey:key];
    }
  }
  if (self->doMemCache && dict) {
    NSDictionary *d;

    d = [[dict copy] autorelease];
    [dict release]; dict = nil;
    [self storeMemCacheEntry:d forKey:_pkey];
    return d;
  }
  else
    return [dict autorelease];
}

- (NSException *)handleStoreException:(NSException *)_exception
  onEntry:(id)_entry atPath:(NSString *)_path
{
  [self logWithFormat:
          @"ERROR[storeCacheEntry] got exception during store of cache entry "
          @"at path '%@': %@", _path, _exception];
  return [[_exception retain] autorelease];
}

- (NSException *)handleWriteErrorAtPath:(NSString *)_path onEntry:(id)_entry {
  [self logWithFormat:@"ERROR: could not write cache entry: '%@'", _path];
  return nil; // TODO: return an exception explaining the problem !
}

- (NSException *)storeCacheEntry:(id)_entry
  forKey:(int)_pkey inVersion:(int)_version
{
  NSString    *p;
  NSException *exc;
  
  p = [self pathForKey:_pkey inVersion:_version];
 
  if ([self->fm fileExistsAtPath:p isDirectory:NULL]) {
    [self logWithFormat:
            @"WARNING: cache entry at path '%@' already exists, "
            @"keeping old."];
    return nil; /* nil says OK */
  }
  if (DebugOn)
    [self logWithFormat:@"writing new cache entry %i/%i.", _pkey, _version];
  
  exc = nil;
  NS_DURING {
    if (![_entry writeToFile:p atomically:YES])
      exc = [self handleWriteErrorAtPath:p onEntry:_entry];
  }
  NS_HANDLER
    exc = [self handleStoreException:localException onEntry:_entry atPath:p];
  NS_ENDHANDLER;
  
  return exc; /* nil says OK */;
}

@end /* SxRecordCacheManager */
