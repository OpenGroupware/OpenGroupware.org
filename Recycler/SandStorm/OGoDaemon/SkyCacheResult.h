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

#ifndef __SkyContactDaemon_SkyCacheResult_H__
#define __SkyContactDaemon_SkyCacheResult_H__

#import <Foundation/NSObject.h>

@class NSArray, NSMutableArray;
@class SkyCacheManager;

@interface SkyCacheResult : NSObject
{
  SkyCacheManager *cacheManager;
  NSMutableArray  *cachedElements;
  NSMutableArray  *uncachedIds;
}

+ (SkyCacheResult *)resultWithCacheManager:(SkyCacheManager *)_cm
  cachedElements:(NSArray *)_cachedIDs
  uncachedIDs:(NSArray *)_uncachedIds;

/* accessors */

- (NSArray *)cachedElements;
- (NSArray *)uncachedIds;
- (NSArray *)allObjects;

/* methods */

- (void)forgetIds:(NSArray *)_ids;
- (void)cacheObjects:(NSArray *)_objects forGlobalIDs:(NSArray *)_gids;

@end /* SkyCacheResult */

#endif /* __SkyContactDaemon_SkyCacheResult_H__ */
