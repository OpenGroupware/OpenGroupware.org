/*
  Copyright (C) 2000-2006 SKYRIX Software AG
  Copyright (C) 2006      Helge Hess

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

#include <OGoFoundation/SkyEditorComponent.h>

@class NSString, NSMutableSet, NSMutableArray;

@interface SkyCategorySubEditor : SkyEditorComponent
{
  NSMutableArray *categories;
  NSMutableSet   *addedCategories;
  NSString       *category;
  id             item;
  unsigned       categoryIndex;
}
@end

#include "common.h"
#include <OGoContacts/SkyCompanyDocument.h>

@implementation SkyCategorySubEditor

- (id)init {
  if ((self = [super init]) != nil) {
    self->addedCategories = [[NSMutableSet   alloc] initWithCapacity:4];
    self->categories      = [[NSMutableArray alloc] initWithCapacity:4];
  }
  return self;
}

- (void)dealloc {
  [self->categories      release];
  [self->addedCategories release];
  [self->category        release];
  [self->item            release];
  [super dealloc];
}

/* accessors */

- (NSArray *)categories {
  return self->categories;
}

- (void)setCategoryIndex:(unsigned)_idx {
  self->categoryIndex = _idx;
}
- (unsigned)categoryIndex {
  return self->categoryIndex;
}

- (void)setCategory:(id)_category {
  ASSIGN(self->category,_category);
}
- (id)category {
  return self->category;
}

- (void)setItem:(id)_item {
  ASSIGN(self->item,_item);
}
- (id)item {
  return self->item;
}

- (void)setSelectedCategory:(NSString *)_category {
  NSString *c;

  c = [self->categories objectAtIndex:self->categoryIndex];
  
  if ([_category isNotEmpty]) {
    if (![_category isEqualToString:c])
      [self->addedCategories removeObject:c];
    [self->addedCategories addObject:_category];
  }
  else {
    [self->addedCategories removeObject:c];
  }
}
- (NSString *)selectedCategory {
  return [self->categories objectAtIndex:self->categoryIndex];
}


/* keywords handling */

static NSString *KeywordSplitString = @", ";

- (void)prepareEditor {
  id k = [(SkyCompanyDocument *)[self document] keywords];

  if ([k isNotNull]) {
    NSArray *c;
    int i, cnt;
    
    c = [k componentsSeparatedByString:KeywordSplitString];
    for (i = 0, cnt = [c count]; i < cnt; i++) {
      NSString *cName;
      
      cName = [[c objectAtIndex:i] copy];
      [self->categories      addObject:cName];
      [self->addedCategories addObject:cName];
      [cName release];
    }
  }
  [self->categories addObject:@""];
  [self->categories addObject:@""];
}


- (NSString *)_categoryString {
  NSMutableString *str  = nil;
  NSArray         *cats = [self->addedCategories allObjects];
  int i, count = [cats count];

  str = [NSMutableString stringWithCapacity:64];

  for (i = 0; i < count; i++) {
    if (i > 0) [str appendString:KeywordSplitString];
    [str appendString:[cats objectAtIndex:i]];
  }
  return str;
}


/* actions */

- (BOOL)save {
  [(SkyCompanyDocument *)[self document] setKeywords:[self _categoryString]];
  // the parent editor page is responsible for saving!!!
  return YES;
}


@end /* SkyCategorySubEditor */
