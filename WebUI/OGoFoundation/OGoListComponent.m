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

#include "OGoListComponent.h"
#include "WOComponent+Navigation.h"
#include "common.h"

@implementation OGoListComponent

+ (int)version {
  return [super version] + 0 /* v2 */;
}
+ (void)initialize {
  NSAssert2([super version] == 2,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
}

- (void)dealloc {
  [self->currentColumn release];
  [self->dataSource    release];
  [self->item          release];
  [self->favoritesKey  release];
  [self->favoriteIds   release];
  [super dealloc];
}

/* notifications */

- (void)sleep {
  [self->item          release]; self->item          = nil;
  [self->favoriteIds   release]; self->favoriteIds   = nil;
  [self->currentColumn release]; self->currentColumn = nil;
  [super sleep];
}

/* accessors */

- (void)setDataSource:(EODataSource *)_dataSource {
  ASSIGN(self->dataSource, _dataSource);
}
- (EODataSource *)dataSource {
  return self->dataSource;
}

- (void)setItem:(id)_item {
  ASSIGN(self->item, _item);
}
- (id)item {
  return self->item;
}

- (NSString *)itemIdString {
  [self errorWithFormat:@"%s: subclass must override this method!",
	  __PRETTY_FUNCTION__];
  return nil;
}

/* custom columns */

- (void)setCurrentColumn:(NSString *)_s {
  ASSIGNCOPY(self->currentColumn, _s);
}
- (NSString *)currentColumn {
  return self->currentColumn;
}

- (NSString *)currentColumnLabel {
  return [[self labels] valueForKey:[self currentColumn]];
}
- (id)currentColumnValue {
  return [[self item] valueForKey:[self currentColumn]];
}

- (BOOL)isMailColumn {
  return [[self currentColumn] hasPrefix:@"email"];
}
- (BOOL)isPhoneColumn {
  NSString *s = [self currentColumn];
  if ([s hasSuffix:@"tel"]) return YES;
  if ([s hasSuffix:@"fax"]) return YES;
  return NO;
}
- (BOOL)isRegularColumn {
  if ([self isMailColumn])  return NO;
  if ([self isPhoneColumn]) return NO;
  return YES;
}

- (NSDictionary *)mailColumnDict {
  return [NSDictionary dictionaryWithObjectsAndKeys:
			 [self currentColumn], @"key",
		         @"3", @"type", /* email */
		       nil];
}

/* actions */

- (id)viewItem {
  return [self activateObject:[self item] withVerb:@"view"];
}

/* favorites */

- (NSString *)defaultFavoritesKey {
  return nil; /* override in subclasses */
}
- (void)setFavoritesKey:(NSString *)_key {
  ASSIGN(self->favoritesKey, _key);
}
- (NSString *)favoritesKey {
  return [self->favoritesKey isNotEmpty] 
    ? self->favoritesKey : [self defaultFavoritesKey];
}

- (NSArray *)favoriteIds {
  if (self->favoriteIds == nil) {
    self->favoriteIds =
      [[[[self session] userDefaults] arrayForKey:[self favoritesKey]] copy];
  }
  return self->favoriteIds;
}

- (BOOL)isInFavorites {
  return [[self favoriteIds] containsObject:[self itemIdString]];
}

- (BOOL)_modifyFavorites:(BOOL)_doRemove {
  NSMutableArray *favIds;
  NSUserDefaults *ud;
    
  if (_doRemove && ![self isInFavorites])
    return NO; /* not in favorites */
  if (!_doRemove && [self isInFavorites])
    return NO; /* already in favorites */
  
  favIds = [[self favoriteIds] mutableCopy];
    
  if (_doRemove)
    [favIds removeObject:[self itemIdString]];
  else
    [favIds addObject:[self itemIdString]];

  ud = [[self session] userDefaults];
  [ud setObject:favIds forKey:[self favoritesKey]];
  [ud synchronize];
  
  [self->favoriteIds release]; self->favoriteIds = nil;
  [favIds release]; favIds = nil;
  return YES;
}

/* actions */

- (id)updateFavoritesAction {
  if ([self hasBinding:@"onFavoritesChange"])
    return [self valueForBinding:@"onFavoritesChange"];
  return nil /* stay on page */;
}

- (id)addToFavorites {
  [self _modifyFavorites:NO /* NO means "add favorite" */];
  return [self updateFavoritesAction];
}
- (id)removeFromFavorites {
  [self _modifyFavorites:YES /* YES means "remove favorite" */];
  return [self updateFavoritesAction]; 
}

@end /* OGoListComponent */
