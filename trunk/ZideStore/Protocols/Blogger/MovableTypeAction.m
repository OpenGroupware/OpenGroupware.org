/*
  Copyright (C) 2004-2005 SKYRIX Software AG

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

#include "MovableTypeAction.h"
#include "common.h"

@implementation MovableTypeAction

- (void)dealloc {
  [super dealloc];
}

/* categories */

- (NSDictionary *)defaultCategoryInfo {
  NSDictionary *defCat;
  
  defCat = [NSDictionary dictionaryWithObjectsAndKeys:
			   @"default", @"categoryName",
			   @"0",       @"categoryId",
			   [NSNumber numberWithBool:NO], @"isPrimary",
			 nil];
  return defCat;
}

/* actions */

- (id)supportedTextFiltersAction {
  /*
    array of structs, keys: key, label
    - key is identifying a text formatting plugin
  */
  [self logWithFormat:@"TODO: implement supported text filters!"];
  return [NSArray array];
}

- (id)getCategoryListAction {
  /* array of structs, keys: categoryId, categoryName */
  [self logWithFormat:@"TODO: implement get-categories action!"];
  return [NSArray arrayWithObject:[self defaultCategoryInfo]];
}

- (id)getPostCategoriesAction {
  /* array of structs, keys: categoryName, categoryId, isPrimary */
  [self logWithFormat:@"TODO: implement get-post-categories action!"];
  return [NSArray arrayWithObject:[self defaultCategoryInfo]];
}

@end /* MovableTypeAction */
