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

@class NSArray;

@interface SkyNavigation : OGoComponent
{
  NSArray *pages;
  BOOL    isClickable;
  id      item;
  int     index;
  int     maxNavLabelLength;
}

- (void)setIndex:(int)_idx;
- (int)index;
- (void)setItem:(id)_item;
- (id)item;

@end

#include <NGObjWeb/WEClientCapabilities.h>
#include <OGoFoundation/OGoSession.h>
#include <OGoFoundation/OGoNavigation.h>
#include <NGObjWeb/NGObjWeb.h>
#import <Foundation/Foundation.h>

@implementation SkyNavigation

- (void)dealloc {
  [self->item  release];
  [self->pages release];
  [super dealloc];
}

/* notifications */

- (void)awake {
  NSUserDefaults *ud;

  [super awake];
  
  ud = [(id)[self existingSession] userDefaults] ;
  self->maxNavLabelLength = 
    [[ud objectForKey:@"SkyMaxNavLabelLength"] intValue];
}

- (void)sleep {
  [self setItem:nil];
  [super sleep];
}

/* accessors */

- (NSString *)itemLabel {
  // TODO: this should retrieve a label formatter from the item instead of
  //       querying the label KVC key
  NSString *label;
  
  label = [[self item] valueForKey:@"label"];
  if ((int)[label length] > self->maxNavLabelLength) {
    label = [label substringToIndex:(self->maxNavLabelLength - 3)];
    label = [label stringByAppendingString:@"..."];
  }
  return label;
}

- (void)setIndex:(int)_idx {
  self->index = _idx;
}
- (int)index {
  return self->index;
}

- (void)setItem:(id)_item {
  ASSIGN(self->item, _item);
}
- (id)item {
  return self->item;
}

- (void)setLinksDisabled:(BOOL)_flag {
  self->isClickable = !_flag;
}
- (BOOL)linksDisabled {
  return self->isClickable ? NO : YES;
}

- (void)setPages:(NSArray *)_pages {
  ASSIGN(self->pages, _pages);
}
- (NSArray *)pages {
  return self->pages;
}

- (BOOL)isNavLinkClickable {
  int count;

  if (!self->isClickable)
    return NO;
  
  count = [[self pages] count];
  
  return ([self index] == (count - 1)) ? NO : YES;
}

- (BOOL)smallFont {
  WEClientCapabilities *ccaps;
  
  if ((ccaps = [[[self context] request] clientCapabilities]) == nil)
    return NO;
  
  if ([ccaps isX11Browser]) {
    if ([ccaps isNetscape])
      return NO;
    if ([ccaps isMozilla])
      return NO;
  }
  return YES;
}

/* actions */

- (id)navigate { // a navigation link was clicked
  id page;
  
  if ((page = [[self pages] objectAtIndex:[self index]]))
    [[(OGoSession *)[self session] navigation] enterPage:page];
  
  return page;
}

/* WO rr cycle */

- (void)takeValuesFromRequest:(WORequest *)_req inContext:(WOContext *)_ctx {
  /* no takevalues required for content */
}

@end /* SkyNavigation */
