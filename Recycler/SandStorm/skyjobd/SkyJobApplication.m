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

#include "SkyJobApplication.h"
#include "common.h"
#include <OGoDaemon/SkyCacheManager.h>

@implementation SkyJobApplication

/* initialization */

- (id)init {
  if ((self = [super init])) {
    self->listCache =
      [[SkyCacheManager alloc] initWithDirectory:
                               [self listCacheDirectory]];
    self->jobCache =
      [[SkyCacheManager alloc] initWithDirectory:
                               [self jobCacheDirectory]];
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->listCache);
  RELEASE(self->jobCache);
  [super dealloc];
}

/* accessors */

- (SkyCacheManager *)listCache {
  return self->listCache;
}

- (SkyCacheManager *)jobCache {
  return self->jobCache;
}

- (NSString *)cacheRoot {
  NSDictionary *environment;
  NSString     *cachePath;

  environment = [[NSProcessInfo processInfo] environment];

#if COCOA_Foundation_LIBRARY
  cachePath = [environment objectForKey:@"HOME"];
#else
  cachePath = [environment objectForKey:@"GNUSTEP_USER_ROOT"];
#endif

  return [cachePath stringByAppendingPathComponent:@"cache"];
}

- (NSString *)cacheDirectory {
  return [[self cacheRoot]
                stringByAppendingPathComponent:@"job"];
}

- (NSString *)listCacheDirectory {
  return [[self cacheDirectory]
                stringByAppendingPathComponent:@"list"];
}

- (NSString *)jobCacheDirectory {
  return [[self cacheDirectory]
                stringByAppendingPathComponent:@"job"];
}

@end /* Application */
