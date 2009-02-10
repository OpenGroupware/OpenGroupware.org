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

#include <OGoFoundation/OGoComponent.h>

/*
 *  mappings:
 *      > palmDataSource     the palmDocumentDataSource
 *     <> selectedCategory   the selected category index
 *     <> selectedDevice     the selected device
 *      > onChange           onChange for popup
 *
 */

@class SkyPalmDocumentDataSource;
@class NSNumber, NSNumber, NSArray, NSDictionary;

@interface SkyPalmCategoryPopUp : OGoComponent
{
  NSArray                   *categories;
  NSDictionary              *mappedCategories;
  NSNumber                  *selectedCategory;
  NSString                  *selectedDevice;
  id                        onChange;
  id                        item;
  SkyPalmDocumentDataSource *dataSource;
}

@end /* SkyPalmCategoryPopUp */

#include "common.h"
#include <OGoPalm/SkyPalmDocumentDataSource.h>
#include <OGoPalm/SkyPalmCategoryDocument.h>

@implementation SkyPalmCategoryPopUp

- (void)dealloc {
  RELEASE(self->categories);
  RELEASE(self->mappedCategories);
  RELEASE(self->selectedCategory);
  RELEASE(self->selectedDevice);
  RELEASE(self->onChange);
  RELEASE(self->item);
  RELEASE(self->dataSource);
  [super dealloc];
}

/* awake */

- (void)sleep {
  [super sleep];
  [self->categories       release]; self->categories       = nil;
  [self->mappedCategories release]; self->mappedCategories = nil;
}

/* accessors */

- (void)setSelectedCategory:(NSNumber *)_cat {
  ASSIGN(self->selectedCategory,_cat);
}
- (NSNumber *)selectedCategory {
  return self->selectedCategory;
}
- (void)setSelectedDevice:(NSString *)_dev {
  ASSIGN(self->selectedDevice,_dev);
}
- (NSString *)selectedDevice {
  return self->selectedDevice;
}
- (void)setPalmDataSource:(SkyPalmDocumentDataSource *)_dataSource {
  ASSIGN(self->dataSource,_dataSource);
}
- (SkyPalmDocumentDataSource *)palmDataSource {
  return self->dataSource;
}

/* wo bindings */

- (void)setItem:(id)_item {
  ASSIGN(self->item, _item); 
}
- (id)item {
  return self;
}

- (void)setOnChange:(id)_oc {
  ASSIGN(self->onChange, _oc);
}
- (id)onChange {
  return self->onChange;
}

- (NSArray *)categories {
  SkyPalmDocumentDataSource *ds;
  NSEnumerator              *e;
  id                        one;
  NSMutableArray            *ma;
  
  if (self->categories != nil)
    return self->categories;
  
  ds = [self palmDataSource];
  e  = [[ds devices] objectEnumerator];
  ma = [NSMutableArray array];
  while ((one = [e nextObject]) != nil) {
    NSEnumerator *e2;
    id           tmp;

    e2 = [[ds categoriesForDevice:one] objectEnumerator];
    [ma addObject:[NSDictionary dictionaryWithObject:one
                                  forKey:@"device_id"]];
    while ((tmp = [e2 nextObject]) != nil) {
      tmp = [NSDictionary dictionaryWithObjectsAndKeys:
                            one, @"device_id",
                            tmp, @"category", nil];
      [ma addObject:tmp];
    }
  }
  self->categories = [ma copy];
  return self->categories;
}
- (NSDictionary *)mappedCategories {
  NSArray             *ar;
  NSEnumerator        *e;
  id                  one;
  NSMutableDictionary *md;
  
  if (self->mappedCategories != nil)
    return self->mappedCategories;
  
  ar = [self categories];
  e  = [ar objectEnumerator];
  md = [NSMutableDictionary dictionaryWithCapacity:[ar count]];
  
  while ((one = [e nextObject]) != nil) {
    id dev, cat;

    cat = [one valueForKey:@"category"];
    dev = [one valueForKey:@"device_id"];
    cat = (cat == nil)
      ? dev : (id)[dev stringByAppendingFormat:@"__%i", [cat categoryIndex]];
    [md setObject:one forKey:cat];
  }
  self->mappedCategories = [md copy];
  return self->mappedCategories;
}

- (void)setSelection:(id)_sel {
  id cat;

  cat = [_sel valueForKey:@"category"];
  [self setSelectedDevice:[_sel valueForKey:@"device_id"]];
  if (cat == nil)
    [self setSelectedCategory:[NSNumber numberWithInt:-1]];
  else
    [self setSelectedCategory:[NSNumber numberWithInt:[cat categoryIndex]]];
}
- (id)selection {
  NSString *key;
  NSNumber *cat;

  key = [self selectedDevice];
  cat = [self selectedCategory];
  if ([key length] == 0) return nil;
  if ((cat != nil) && ([cat intValue] != -1))
    key = [key stringByAppendingFormat:@"__%@", cat];
  return [[self mappedCategories] valueForKey:key];
}

- (NSString *)categoryLabel {
  static NSString *allLabel = nil;
  id cat;
  
  if (allLabel == nil) // ??? TODO: this is mixed up!
    allLabel = [[[self labels] valueForKey:@"label_popup_all"] copy];
  
  if (self->item == nil)
    return allLabel;
  cat = [self->item valueForKey:@"category"];
  if (cat == nil)
    return [NSString stringWithFormat:@"%@: %@",
                     [self->item valueForKey:@"device_id"], allLabel];
  return [NSString stringWithFormat:@"%@: %@",
                   [self->item valueForKey:@"device_id"],
                   [cat categoryName]];
}

@end /* SkyPalmCategoryPopUp */
