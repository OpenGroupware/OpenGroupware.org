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

#ifndef __SkyPalmSelectableListing_H__
#define __SkyPalmSelectableListing_H__

#include <OGoFoundation/LSWComponent.h>

/*
 * bindings:
 *    > list         - all items
 *   <  item         - single item
 *   <> selection    - selected items
 *
 *    > selectItem   - select single item
 *    > selectItems  - select all items
 *
 *    > title        - title to display
 */

@class NSMutableArray;

@interface SkyPalmSelectableListing : LSWComponent
{
  id item;
}

- (NSArray *)list;

- (void)setItem:(id)_item;
- (id)item;

- (void)setSelections:(NSMutableArray *)_selections;
- (NSMutableArray *)selections;

- (NSString *)title;

// actions
- (id)selectItem;
- (id)selectItems;

@end /* SkyPalmSelectableListing */

#endif /* __SkyPalmSelectableListing_H__ */
