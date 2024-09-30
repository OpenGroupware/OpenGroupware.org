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

#include <OGoFoundation/LSWEditorPage.h>

@class NSArray, NSString;

@interface LSWEnterpriseSearchPage : LSWEditorPage
{
@protected
  NSArray  *searchResult;
  id       item;
  NSString *searchString;
  int      idx;
}

@end /* LSWEnterpriseSearchPage */

#include "common.h"

NSComparisonResult compareEnterprises(id e1, id e2, void* context) {
  return [[e1 valueForKey:@"description"]
	   caseInsensitiveCompare:[e2 valueForKey:@"description"]];
}

@implementation LSWEnterpriseSearchPage

- (void)dealloc {
  [self->searchResult release];
  [self->item         release];
  [self->searchString release];
  [super dealloc];
}

/* accessors */

- (BOOL)isEditorPage {
  return YES;
}

/* actions */

- (id)search {
  NSMutableArray *result;
  [self->searchResult release]; self->searchResult = nil;

  result = [self runCommand:@"enterprise::full-search",
                 @"searchString", self->searchString,
                 nil];

  self->searchResult = [[result sortedArrayUsingFunction:compareEnterprises
                               context:NULL] retain];

  if ([self->searchResult count]>0) 
    [self setSnapshot:[self->searchResult objectAtIndex:0]];
  
  return nil;
}

- (BOOL)isWizardFinish {
  // TODO: is this still required? (it is supported in the template)
  return (([super isWizardFinish]) && ([self->searchResult count]>0));
}

/* accessors */

- (void)setSearchResult:(id)_res {
  ASSIGN(self->searchResult, _res);
}
- (id)searchResult {
  return self->searchResult;
}

- (void)setItem:(id)_item {
  ASSIGN(self->item, _item);
}
- (id)item {
  return self->item;
}

- (void)setIdx:(int)_idx {
  self->idx = _idx;
}
- (int)idx {
  return self->idx;
}

- (void)setSearchString:(id)_searchString {
  ASSIGN(self->searchString, _searchString);
}
- (id)searchString {
  return self->searchString;
}

- (BOOL)hasEnterprises {
  return ([self->searchResult count] > 0) ? YES : NO;
}

- (NSString *)wizardObjectType {
  return @"enterprise";
}

- (NSString *)enterpriseName {
  NSString *s = nil;

  if (self->item != nil) {
    s = [self->item valueForKey:@"description"];
  }
  if (s == nil)
    s = @"";

  return [s stringByAppendingString:@"</td></tr>"];
}

@end /* LSWEnterpriseSearchPage */
