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

#ifndef __SkyJobDaemon_ObjectPool_H__
#define __SkyJobDaemon_ObjectPool_H__

#import <Foundation/NSObject.h>

@class NSMutableArray, NSString, NSArray;

@interface ObjectPool : NSObject
{
  id context;
}

+ (id)poolWithContext:(id)_ctx;

/* accessors */

- (id)commandContext;

- (void)fillArray:(NSMutableArray *)_array
  withRole:(NSString *)_role forGlobalIDs:(NSArray *)_gids
  usingListAttributes:(BOOL)_listAttrs;
- (NSString *)currentCompanyId;

@end /* ObjectPool */

#endif /* __SkyJobDaemon_ObjectPool_H__ */
