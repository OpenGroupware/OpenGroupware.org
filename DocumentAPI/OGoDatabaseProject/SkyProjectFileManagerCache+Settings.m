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

#include <OGoDatabaseProject/SkyProjectFileManagerCache.h>
#include "common.h"

@implementation SkyProjectFileManagerCache(Settings)

- (BOOL)useSessionCache {
  return self->useSessionCache;
}

- (void)setUseSessionCache:(BOOL)_cache {
  if (_cache != self->useSessionCache) {
    [self flush];
    self->useSessionCache = _cache;
    [self initSessionCache];
  }
}

- (NSTimeInterval)flushTimeout {
  return self->flushTimeout;
}
- (void)setFlushTimeout:(NSTimeInterval)_timeInt {
  self->flushTimeout = _timeInt;
}

- (NSTimeInterval)clickTimeout {
  return self->clickTimeout;
}
- (void)setClickTimeout:(NSTimeInterval)_timeInt {
  if (_timeInt != self->clickTimeout) {
    self->clickTimeout = _timeInt;
    [self initClickTimer];
  }
}

- (NSTimeInterval)cacheTimeout {
  return self->cacheTimeout;
}
- (void)setCacheTimeout:(NSTimeInterval)_timeInt {
  self->cacheTimeout = _timeInt;
}

static NSNotificationCenter *nc = nil;

- (void)initSessionCache {
  if (nc == nil)
    nc = [NSNotificationCenter defaultCenter];

  if (self->useSessionCache) {
    [nc addObserver:self selector:@selector(flush)
        name:@"LSCommandContextFlush" object:self->context];
  }
  else {
    [nc removeObserver:self name:@"LSCommandContextFlush" object:nil];
  }
}

- (void)rejectClickTimer {
  [self->clickTimer invalidate];
  RELEASE(self->clickTimer); self->clickTimer = nil;
}

- (void)startClickTimer {
  [self rejectClickTimer];
  if (self->clickTimeout > 0) {
    self->clickTimer = [NSTimer scheduledTimerWithTimeInterval:self->clickTimeout
                                target:self
                                selector:@selector(flush)
                                userInfo:@"click timer" repeats:NO];
    RETAIN(self->clickTimer);
  }
}

- (void)initClickTimer { /* fires after n seconds of inactivity */
  if (nc == nil)
    nc = [NSNotificationCenter defaultCenter];
  
  [self rejectClickTimer];
  if (!self->useSessionCache && self->clickTimeout > 0) {

    [nc addObserver:self selector:@selector(startClickTimer)
        name:@"LSWSessionSleep" object:nil];
    [nc addObserver:self selector:@selector(rejectClickTimer)
        name:@"LSWSessionAwake" object:nil];
  }
  else {
    [nc removeObserver:self name:@"LSWSessionAwake" object:nil];
    [nc removeObserver:self name:@"LSWSessionSleep" object:nil];
  }
}

- (void)initFlushTimer { /* fires after n seconds after the last flush */
  [self->flushTimer invalidate];
  RELEASE(self->flushTimer); self->flushTimer = nil;
  
  if (!self->useSessionCache && self->flushTimeout > 0) {
    self->flushTimer = [NSTimer scheduledTimerWithTimeInterval:
				  self->flushTimeout
                                target:self
                                selector:@selector(flush)
                                userInfo:@"flush timer" repeats:NO];
    [self->flushTimer retain];
  }
}

- (void)initCacheTimer { 
  /* fires after n seconds after the last filemanager expires */
  [self->cacheTimer invalidate];
  [self->cacheTimer release]; self->cacheTimer = nil;
  
  if (!self->useSessionCache && self->cacheTimeout > 0) {
    self->cacheTimer = [NSTimer scheduledTimerWithTimeInterval:
				  self->cacheTimeout
                                target:self
                                selector:@selector(flush)
                                userInfo:@"cache timer" repeats:NO];
    [self->cacheTimer retain];
  }
#if 0 // TODO: why disabled? what sideeffects?
  else {
    [self flush];
  }
#endif
}


#if 0
static int CACHE_COUNT = -1;
#endif

- (void)flush {
#if 0  
  if (CACHE_COUNT == -1) {
    CACHE_COUNT = [[NSUserDefaults standardUserDefaults] integerForKey:@"FLUSH_ABORT_CNT"];
  }
  if (CACHE_COUNT)
    CACHE_COUNT--;
  else
    abort();
#endif
  
  if (self->flushTimer) {
    [self->flushTimer invalidate];
    RELEASE(self->flushTimer); self->flushTimer = nil;
  }
  /* remove global did -> pid cache in context */

  [self->context takeValue:[NSMutableDictionary dictionaryWithCapacity:256]
       forKey:@"docToProjectCache"];
  
  
  [self->fileManagerCache removeAllObjects];
  [self initFlushTimer];
}

@end /* SkyProjectFileManagerCache(Timeout) */
