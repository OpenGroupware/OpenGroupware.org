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

#include <NGObjWeb/NGObjWeb.h>

/*
  UIxMailSortableTableHeader

  TODO: document.
*/

@interface UIxMailSortableTableHeader : WOComponent
{
  NSString     *label;
  NSString     *sortKey;
  NSString     *href;
  NSDictionary *queryDictionary;
  BOOL         isDefault;
}

@end

#include "common.h"

@implementation UIxMailSortableTableHeader

- (void)dealloc {
  [self->label           release];
  [self->sortKey         release];
  [self->href            release];
  [self->queryDictionary release];
  [super dealloc];
}

/* Accessors */

- (void)setLabel:(NSString *)_label {
  ASSIGNCOPY(self->label, _label);
}
- (NSString *)label {
  return self->label;
}

- (void)setSortKey:(NSString *)_sortKey {
  ASSIGNCOPY(self->sortKey, _sortKey);
}
- (NSString *)sortKey {
  return self->sortKey;
}

- (void)setHref:(NSString *)_href {
  ASSIGNCOPY(self->href, _href);
}
- (NSString *)href {
  return self->href;
}

- (void)setQueryDictionary:(NSDictionary *)_queryDictionary {
  ASSIGN(self->queryDictionary, _queryDictionary);
}
- (NSDictionary *)queryDictionary {
  return self->queryDictionary;
}

- (void)setIsDefault:(BOOL)_isDefault {
  self->isDefault = _isDefault;
}
- (BOOL)isDefault {
  return self->isDefault;
}

- (BOOL)isSelected {
  NSString *so;
  
  so = [self->queryDictionary objectForKey:@"sort"];
  if (![so isNotNull])
    return self->isDefault;
  
  return [so isEqualToString:self->sortKey];
}

- (BOOL)isSortedDescending {
  NSString *desc;
  
  desc = [self->queryDictionary objectForKey:@"desc"];
  if (desc == nil)
    return NO;
  return [desc boolValue];
}

@end /* UIxMailSortableTableHeader */
