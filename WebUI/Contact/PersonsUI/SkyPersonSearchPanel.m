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
// $Id$

#include <OGoFoundation/LSWComponent.h>

@class NSString, NSArray, NSDictionary;

@interface SkyPersonSearchPanel : LSWComponent
{
  NSString     *searchString;
  NSArray      *searchResults;
  NSDictionary *searchRow;
  BOOL         searchDone;
  BOOL         displayPanel;
  int          searchIdx;
}
@end

#include "common.h"

@implementation SkyPersonSearchPanel

static NSArray  *sortOrderings  = nil;
static NSNumber *maxSearchCount = nil;

+ (void)initialize {
  if (sortOrderings == nil) {
    sortOrderings = 
      [[NSArray alloc] initWithObjects:
                         [EOSortOrdering sortOrderingWithKey:@"name"
                                         selector:EOCompareAscending],
                         [EOSortOrdering sortOrderingWithKey:@"firstname"
                                         selector:EOCompareAscending],
                       nil];
  }

  if (maxSearchCount == nil)
    maxSearchCount = [[NSNumber numberWithInt:30] retain];
}

- (id)init {
  if ((self = [super init])) {
    self->searchString  = @"";
    self->searchResults = [[NSArray      alloc] init];
    self->searchRow     = [[NSDictionary alloc] init];
  }
  return self;
}

- (void)dealloc {
  [self->searchString  release];
  [self->searchResults release];
  [self->searchRow     release];
  [super dealloc];
}

/* notifications */

- (void)syncAwake {
  // panel is only displayed once, i.e. directly after search
  [super syncAwake];
  self->displayPanel = NO;
}

/* handling requests */

- (void)takeValuesFromRequest:(WORequest *)_request
  inContext:(WOContext *)_ctx
{
  [_ctx removeObjectForKey:@"IsPanelScriptSet"];
  [super takeValuesFromRequest:_request inContext:_ctx];
}

/* accessors */

- (void)setSearchResults:(NSArray *)_result {
  ASSIGN(self->searchResults,_result);
}
- (NSArray *)searchResults {
  return self->searchResults;
}

- (void)setSearchRow:(NSDictionary *)_row {
  ASSIGN(self->searchRow,_row);
}
- (NSDictionary *)searchRow {
  return self->searchRow;
}

- (void)setSearchString:(NSString *)_s {
  ASSIGN(self->searchString, _s);
}
- (NSString *)searchString{
  return self->searchString;
}

- (void)setSearchDone:(BOOL)_b {
  self->searchDone = _b;
}
- (BOOL)searchDone {
  return self->searchDone;
}

- (void)setDisplayPanel:(BOOL)_b {
  self->displayPanel = _b;
}
- (BOOL)displayPanel {
  return self->displayPanel;
}

- (void)setSearchIdx:(int)_i {
  self->searchIdx = _i;
}
- (int)searchIdx {
  return self->searchIdx;
}

- (NSString *)rowColor {
  return (self->searchIdx % 2 == 0)
    ? [[self config] valueForKey:@"colors_evenRow"]
    : [[self config] valueForKey:@"colors_oddRow"];
}

/* actions */

- (id)personSearchSubmit {
  NSArray *a;
  
  self->searchDone   = YES;
  self->displayPanel = YES;
  
  a = [self runCommand:
              @"person::extended-search",
              @"maxSearchCount", maxSearchCount,
              @"operator",    @"OR",
              @"name",        self->searchString,
              @"firstname",   self->searchString,
              @"description", self->searchString,
              @"login",       self->searchString,
              nil];

  a = [a sortedArrayUsingKeyOrderArray:sortOrderings];
  [self setSearchResults:a];
  return nil;
}

@end /* SkyPersonSearchPanel */
