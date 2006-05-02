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

@class NSString, NSArray, NSMutableArray;

@interface SkyResourceSelection : OGoComponent
{
  NSMutableArray *resources;
  NSMutableArray *removedResources;
  NSMutableArray *addedResources;
  NSMutableArray *resultList;
  id             item;
  NSString       *searchString;
  BOOL           viewHeadLine;
  BOOL           isClicked;
  NSArray        *categories;
  BOOL           onlyResources;
  id             category;
}

- (id)search;

@end

#include "common.h"

@implementation SkyResourceSelection

static NSArray  *nameSortOrderings = nil;
static NSArray  *nameAttrNames     = nil;
static NSArray  *categoryAttrNames = nil;
static NSNumber *yesNum            = nil;
static NSNumber *maxSearchCount    = nil;

+ (void)initialize {
  if (nameSortOrderings == nil) {
    EOSortOrdering *so;

    so = [EOSortOrdering sortOrderingWithKey:@"name"
			 selector:EOCompareAscending];
    nameSortOrderings = [[NSArray alloc] initWithObjects:&so count:1];
  }
  if (nameAttrNames == nil)
    nameAttrNames = [[NSArray alloc] initWithObjects:@"name", nil];
  if (categoryAttrNames == nil)
    categoryAttrNames = [[NSArray alloc] initWithObjects:@"category", nil];
  if (maxSearchCount == nil)
    maxSearchCount = [[NSNumber numberWithInt:1000] retain];
  
  if (yesNum == nil) yesNum = [[NSNumber numberWithBool:YES] retain];
}

- (id)init {
  if ((self = [super init])) {
    self->resources        = [[NSMutableArray alloc] init];
    self->addedResources   = [[NSMutableArray alloc] init];
    self->removedResources = [[NSMutableArray alloc] init];
    self->resultList       = [[NSMutableArray alloc] init];
    self->viewHeadLine     = YES;
    self->categories       = 
      [[self runCommand:@"appointmentresource::categories", nil] retain];
    
    self->onlyResources = YES;
  }
  return self;
}

- (void)dealloc {
  [self->resources        release];
  [self->removedResources release];
  [self->addedResources   release];
  [self->item             release];
  [self->resultList       release];
  [self->searchString     release];
  [self->categories       release];
  [self->category         release];
  [super dealloc];
}

/* notifications */

- (void)syncAwake {
  [super syncAwake];
  [self->removedResources removeAllObjects];
  [self->addedResources removeAllObjects];
}

- (void)syncSleep {
  [self->removedResources removeAllObjects];
  [self->addedResources removeAllObjects];
  [super syncSleep];
}

/* request processing */

- (void)takeValuesFromRequest:(WORequest *)_req inContext:(WOContext *)_ctx {
  [super takeValuesFromRequest:_req inContext:_ctx];
  if (self->searchString && [self->searchString length] > 0) {
    [self->category release]; 
    self->category = nil;
  }
  if (self->category) {
    [self->searchString release]; 
    self->searchString = nil;
  }  
  [self search];    
  [self->searchString release]; self->searchString = nil;
}

- (NSArray *)distinctCategories:(NSArray *)_items {
  int i, cnt;
  id  obj;
  NSMutableArray *ma;
  NSString *l;

  ma = [NSMutableArray arrayWithCapacity:16];
  l = [[self labels] valueForKey:@"resCategory"];

  if (l == nil) l = @"resCategory";
  
  i = 0; cnt = [_items count];
  
  while (i < cnt) {
    NSMutableDictionary *rD;
    NSString            *s;
    
    obj = [_items objectAtIndex:i++];
    
    s = [[NSString alloc] initWithFormat:@"%@ (%@)",
			    [obj valueForKey:@"category"], l];
    rD = [[NSMutableDictionary alloc] initWithCapacity:1];
    [rD setObject:s forKey:@"name"];
    [s release]; s = nil;
    
    if (![ma containsObject:rD])
      [ma addObject:rD];
    
    [rD release]; rD = nil;
  }
  return ma;
}

/* accessors */

- (void)setSearchString:(NSString *)_txt {
  ASSIGNCOPY(self->searchString, _txt);
}
- (id)searchString {
  return self->searchString;
}

- (void)setItem:(id)_item {
  ASSIGN(self->item, _item);
}
- (id)item {
  return self->item;
}

- (void)setRemovedResources:(id)_res {
  ASSIGN(self->removedResources, _res);
}
- (id)removedResources {
  return self->removedResources;
}

- (void)setAddedResources:(id)_res {
  ASSIGN(self->addedResources, _res);
}
- (id)addedResources {
  return self->addedResources;
}

- (void)setResultList:(id)_res {
  ASSIGN(self->resultList, _res);
}
- (id)resultList {
  return self->resultList;
}

- (BOOL)viewHeadLine {
  return self->viewHeadLine;
}
- (void)setViewHeadLine:(BOOL)_view {
  self->viewHeadLine = _view;
}

- (int)noOfCols {
  id  d;
  int n;
  
  d = [[[self session] userDefaults] objectForKey:@"scheduler_no_of_cols"];
  n = [d intValue];
  return (n > 0) ? n : 2;
}


- (void)initializeResources {
  int i, count;

  // participants selected in resultList
  if ((count = [self->addedResources count]) > 0) {
    for (i = 0; i < count; i++) {
      id  resource = [self->addedResources objectAtIndex:i];
      if (![self->resources containsObject:resource]) {
        [self->resources addObject:resource];
        [self->resultList removeObject:resource];
      }
    }
    [self->addedResources removeAllObjects];
  }

  // participants not selected in participants list
  if ((count = [self->removedResources count]) > 0) {
    for (i = 0, count = [self->removedResources count]; i < count; i++) {
      id  resource = [self->removedResources objectAtIndex:i];
      if ([self->resources containsObject:resource]) {
        [self->resources removeObject:resource];
        [self->resultList addObject:resource];
      }
    }
    [self->removedResources removeAllObjects];
  }
}

- (NSArray *)resources {
  [self initializeResources];
  return self->resources;
}

- (void)setResources:(id)_res {
  if (_res == nil) 
    return;
  
  ASSIGN(self->resources, _res);
}

/* commands */

- (NSArray *)_fetchResourceNamesForGlobalIDs:(NSArray *)_gids {
  if ([_gids count] == 0) 
    return [NSArray array];
  
  return [self runCommand:@"appointmentresource::get-by-globalid",
                 @"gids", _gids, @"attributes", nameAttrNames, nil];
}
- (NSArray *)_fetchResourceCategoriesForGlobalIDs:(NSArray *)_gids {
  if ([_gids count] == 0) 
    return [NSArray array];
  
  // TODO: cache category names
  return [self runCommand:@"appointmentresource::get-by-globalid",
                 @"gids", _gids, @"attributes", categoryAttrNames, nil];
}

- (NSArray *)_fetchGlobalIDsOfCategory:(id)_category {
  NSArray *result;
  
  result = [self runCommand:@"appointmentresource::extended-search",
                   @"fetchGlobalIDs", yesNum,
                   @"operator",       @"OR",
                   @"category",       _category,
                   @"maxSearchCount", maxSearchCount, nil];
  return [result isNotNull] ? result : (NSArray *)nil;
}
- (NSArray *)_fetchGlobalIDsMatchingSubstring:(NSString *)_token
  doSearchCategory:(BOOL)_searchCategory
  doSearchName:(BOOL)_searchName
{
  NSArray *gids;
  
  // TODO: change to use a single runcommand
  if (!_searchCategory && _searchName) {
    gids = [self runCommand:@"appointmentresource::extended-search",
                  @"fetchGlobalIDs", yesNum,
                  @"operator",       @"OR",
                  @"name",           _token,
                  @"maxSearchCount", maxSearchCount, nil];
  }
  else if (_searchCategory && _searchName) {
    // no categories fetched -> search for matching name or category
    gids = [self runCommand:@"appointmentresource::extended-search",
                  @"fetchGlobalIDs", yesNum,
                  @"operator",       @"OR",
                  @"name",           _token,
                  @"category",       _token,
                  @"maxSearchCount", maxSearchCount, nil];
  }
  else if (_searchCategory && !_searchName) {
    gids = [self runCommand:@"appointmentresource::extended-search",
                  @"fetchGlobalIDs", yesNum,
                  @"operator",       @"OR",
                  @"category",       _token,
                  @"maxSearchCount", maxSearchCount, nil];
  }
  else
    gids = nil;
  return gids;
}

/* actions */

- (void)_addNamesOfObjectsToResultListIfMissing:(NSArray *)_objects {
  NSEnumerator *enumerator;
  id           obj;
  
  if ([_objects count] == 0) /* no objects to add */
    return;
  
  enumerator = [_objects objectEnumerator];
  while ((obj = [enumerator nextObject])) {
    NSString *n;
    
    n = [obj valueForKey:@"name"];
    if (![self->resources containsObject:n])
      [self->resultList addObject:n];
  }
}
                   
- (id)search {
  // TODO: split up this huge method!
  NSArray  *tmp = nil;
  NSString *l   = nil;
  
  l = [[self labels] valueForKey:@"resCategory"];

  if (l == nil) l = @"resCategory";
  
  l = [NSString stringWithFormat:@"(%@)", l];
  
  [self initializeResources];
  
  [self->resultList removeAllObjects];

  if (self->category != nil) {
    if (!self->onlyResources) {
      NSString *n;

      n = [NSString stringWithFormat:@"%@ %@", self->category, l];
      
      if (![self->resources containsObject:n])
        [self->resultList addObject:n];
    }
    tmp = [self _fetchGlobalIDsOfCategory:self->category];
    tmp = [self _fetchResourceNamesForGlobalIDs:tmp];
  }
  else if (self->searchString) {
    NSMutableArray *res;

    res = [NSMutableArray arrayWithCapacity:16];
    
    if (!self->onlyResources) {
      tmp = [self _fetchGlobalIDsMatchingSubstring:self->searchString
                  doSearchCategory:YES doSearchName:NO];
      tmp = [self _fetchResourceCategoriesForGlobalIDs:tmp];
      
      if (tmp != nil) {
        // adding categories of found resources
        [res addObjectsFromArray:[self distinctCategories:tmp]];
      }
      // now search for matching names
      tmp = [self _fetchGlobalIDsMatchingSubstring:self->searchString
                  doSearchCategory:NO doSearchName:YES];
    }
    else {
      // no categories fetched -> search for matching name or category
      tmp = [self _fetchGlobalIDsMatchingSubstring:self->searchString
                  doSearchCategory:YES doSearchName:YES];
    }
    if ([tmp count] > 0)
      tmp = [self _fetchResourceNamesForGlobalIDs:tmp];
    
    if ([tmp count] > 0 )
      [res addObjectsFromArray:tmp];
    tmp = [res sortedArrayUsingKeyOrderArray:nameSortOrderings];
  }

  [self _addNamesOfObjectsToResultListIfMissing:tmp];
  return nil;
}

- (id)searchAction {
  self->isClicked = YES;
  return nil;
}

/* accessors */

- (BOOL)hasResources {
  if (([self->resultList count] > 0) || ([self->resources count] > 0))
    return YES;
  return NO;
}

- (NSArray *)attributesList {
  return nil;
}

- (NSArray *)categories {
  return self->categories;
}

- (NSString *)noSelectionString {
  return [[self labels] valueForKey:@"resourceSelection"];
}

- (void)setOnlyResources:(NSNumber *)_n {
  self->onlyResources = [_n boolValue];
}
- (NSNumber *)onlyResources {
  return [NSNumber numberWithBool:self->onlyResources];
}

- (void)setCategory:(id)_c {
  if (_c != nil && ![self->category isEqual:_c])
     self->isClicked = YES;
  ASSIGN(self->category, _c);
}
- (id)category {
  return self->category;
}

- (void)setIsClicked:(BOOL)_flag {
  self->isClicked = _flag;
}
- (BOOL)isClicked {
  return self->isClicked;
}

@end /* SkyResourceSelection */
