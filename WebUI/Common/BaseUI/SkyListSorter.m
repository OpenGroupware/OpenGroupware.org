/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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
   > list
  <> item
  <> selection
   > selectionTitle
   > nonSelectionTitle

   // ---

   Sorter: SkyListSorter {
     list      = list;
     selection = selection;
     item      = item;
     selectionTitle    = "selection title";
     nonSelectionTitle = "non selection title";
   }
   SorterItem: WOString {
     value = item.name;
   }

   // ---

   <#Sorter><#SorterItem/></#Sorter>
*/

@class NSArray, NSMutableArray;

@interface SkyListSorter: OGoComponent
{
  NSArray        *list;
  id             item;
  NSMutableArray *selection;

  NSMutableArray *nonSelection;
  id             droppedObject;
  unsigned       sortIdx;

  NSString       *nonSelectionTitle;
  NSString       *selectionTitle;
  
}
- (void)setDroppedObject:(id)_o;

- (void)setNonSelectionTitle:(NSString *)_title;
- (NSString *)nonSelectionTitle;
- (void)setSelectionTitle:(NSString *)_title;
- (NSString *)selectionTitle; 

@end

#include <NGObjWeb/WEClientCapabilities.h>
#include <NGObjWeb/NGObjWeb.h>
#include "common.h"

static int compareElements(id obj1, id obj2, void *context) {
  int index1, index2;
  
  index1 = [(NSArray *)context indexOfObject:obj1];
  index2 = [(NSArray *)context indexOfObject:obj2];
  
  return (index1 > index2) ? 1 : -1;
}

@implementation SkyListSorter

- (id)init {
  if ((self = [super init])) {
    self->nonSelection = [[NSMutableArray alloc] init];
    self->selection    = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void)dealloc {
  [self->list      release];
  [self->selection release];
  [self->item      release];
  [self->nonSelectionTitle release];
  [self->selectionTitle    release];
  
  [self->nonSelection  release];
  [self->droppedObject release];
  [super dealloc];
}

- (void)sortNonSelection {
  NSArray *tmp;

  tmp = [self->nonSelection sortedArrayUsingFunction:compareElements
             context:self->list];
  [self->nonSelection removeAllObjects];
  [self->nonSelection addObjectsFromArray:tmp];
}


- (void)syncAwake {
  [super syncAwake];
}

- (void)syncSleep {
  [self setDroppedObject:nil];
  [super syncSleep];
}

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  [self->nonSelection removeAllObjects];
  [self->nonSelection addObjectsFromArray:self->list];
  [self->nonSelection removeObjectsInArray:self->selection];
  [super appendToResponse:_response inContext:_ctx];
}

// accessors

- (void)setList:(NSArray *)_list {
  ASSIGN(self->list, _list);
}

- (void)setItem:(id)_item {
  ASSIGN(self->item, _item);
}
- (id)item {
  return self->item;
}

- (void)setSelection:(NSMutableArray *)_selection {
  if (self->selection != _selection && self->selection != nil) {
    id tmp;

    tmp = self->selection;
    
    if (_selection == nil)
      self->selection = [[NSMutableArray alloc] init];
    else if ([_selection isKindOfClass:[NSMutableArray class]])
      self->selection = [_selection retain];
    else
      self->selection = [_selection mutableCopy];

    ASSIGN(tmp, nil);
  }
}
- (NSMutableArray *)selection {
  return self->selection;
}

- (void)setNonSelectionTitle:(NSString *)_title {
  ASSIGNCOPY(self->nonSelectionTitle, _title);
}
- (NSString *)nonSelectionTitle {
  return self->nonSelectionTitle;
}

- (void)setSelectionTitle:(NSString *)_title {
  ASSIGNCOPY(self->selectionTitle, _title);
}
- (NSString *)selectionTitle {
  return self->selectionTitle;
}

// --- private accessors

- (void)setDroppedObject:(id)_o {
  ASSIGN(self->droppedObject,_o);
}
- (id)droppedObject {
  return self->droppedObject;
}

- (void)setSortIdx:(int)_i {
  self->sortIdx = _i;
}
- (int)sortIdx {
  return self->sortIdx;
}

- (void)setNonSelection:(NSMutableArray *)_nonSelection {
  ASSIGN(self->nonSelection, _nonSelection);
}
- (NSMutableArray *)nonSelection {
  return self->nonSelection;
}


/* conditionals */

- (BOOL)isSelectionEmpty {
  return ([self->selection count] == 0) ? YES : NO;
}

- (BOOL)isNonJS {
  WEClientCapabilities *ccaps;
  
  if ([[self context] isInForm])
    return YES;

  if (![[[self session] valueForKey:@"isJavaScriptEnabled"] boolValue])
    return YES;
  
  ccaps = [[[self context] request] clientCapabilities];
  
  return ![ccaps isInternetExplorer];
}

- (BOOL)isFirstElementInSelection {
  return (self->sortIdx == 0) ? YES : NO;
}

- (BOOL)isLastElementInSelection {
  return (self->sortIdx == [self->selection count]-1) ? YES : NO;
} 

/* layout */

- (NSString *)swapBGColor {
  return (self->sortIdx % 2 == 0) ? @"#D0D0D0" : @"#E0E0E0";
}


/* javascript actions */

- (id)addObject {
  // action of "SelectionRepDrop"

  if (self->droppedObject) {

    if ([self->selection containsObject:self->droppedObject]) {
      // sort
      [self->selection removeObject:self->droppedObject];
      [self->selection insertObject:self->droppedObject atIndex:self->sortIdx];
    }
    else {
      // add from list
      if (self->sortIdx+1 > [self->selection count])
        [self->selection addObject:self->droppedObject];
      else
        [self->selection insertObject:self->droppedObject
                              atIndex:self->sortIdx];
      
      [self->nonSelection removeObject:self->droppedObject];
    }
    
  }
  
  return nil;
}

- (id)removeObject {
  // action of "ListRepDrop"

  if (self->droppedObject) {
    // remove from selection
    [self->selection removeObject:self->droppedObject];
    if (![self->nonSelection containsObject:self->droppedObject]) {
      [self->nonSelection addObject:self->droppedObject];
      [self sortNonSelection];
    }
  }
  return nil;
}


/* non-javascript actions */

- (id)nonJSSortUp {
  if (self->item) {
    int idx;
    
    idx = [self->selection indexOfObject: self->item];
    if (idx > 0) {
      [self->selection removeObject:self->item];
      [self->selection insertObject:self->item atIndex:idx-1];
    }
  }
  return nil;
}

- (id)nonJSSortDown {
  if (self->item) {
    int idx;

    idx = [self->selection indexOfObject: self->item];
    if (idx < (((int)[self->selection count]) - 1)) {
      [self->selection removeObject:self->item];
      [self->selection insertObject:self->item atIndex:idx+1];
    }
  }
  return nil;
}

- (id)nonJSRemove {
  if (self->item) {
    [self->selection removeObject:self->item];
    [self->nonSelection addObject:self->item];
    [self sortNonSelection];
  }
  return nil;
}

- (id)nonJSAdd {
  if (self->item) {
    [self->nonSelection removeObject:self->item];
    [self->selection addObject:self->item];
  }
  return nil;
}

@end /* SkyListSorter */
