/*
  Copyright (C) 2006 Helge Hess

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

#ifndef __OGoFoundation_OGoListComponent_H__
#define __OGoFoundation_OGoListComponent_H__

#include <OGoFoundation/OGoComponent.h>

/*
  OGoListComponent

  Abstract superclass for components which display a tableview.
  
  TODO: document what it exactly does/provides.

  Known subclasses:
    SkyPersonList
    SkyEnterpriseList
*/

@class NSString, NSArray, NSDictionary;
@class EODataSource;

@interface OGoListComponent : OGoComponent
{
  EODataSource *dataSource;
  id           item;
  NSString     *favoritesKey;
  NSArray      *favoriteIds;
  NSString     *currentColumn;
}

/* accessors */

- (void)setDataSource:(EODataSource *)_dataSource;
- (EODataSource *)dataSource;

- (void)setItem:(id)_item;
- (id)item;

/* columns */

- (void)setCurrentColumn:(NSString *)_s;
- (NSString *)currentColumn;

- (NSString *)columnType;
- (NSString *)currentColumnLabel;
- (id)currentColumnValue;

- (NSDictionary *)mailColumnDict;

/* favorites */

- (void)setFavoritesKey:(NSString *)_key;
- (NSString *)favoritesKey;
- (NSString *)defaultFavoritesKey;

- (NSArray *)favoriteIds;

/* actions */

- (id)viewItem;

@end

#endif /* __OGoFoundation_OGoListComponent_H__ */
