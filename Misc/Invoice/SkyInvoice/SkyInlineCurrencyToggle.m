/*
  Copyright (C) 2000-2003 SKYRIX Software AG

  This file is part of OGo

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

// little inline panel for currency changing
// change from DEM to EUR

/*
 * binding:
 *
 * <> currency     the currency string DEM(Default) or EUR
 *
 */


#include <OGoFoundation/LSWComponent.h>

@interface SkyInlineCurrencyToggle : LSWComponent
{

  NSString *selected;

  id item;
}

- (NSString *)currency;
@end /* SkyInlineCurrencyToggle */

#import <Foundation/Foundation.h>

@implementation SkyInlineCurrencyToggle

- (id)init {
  if ((self = [super init])) {
    self->selected = nil;
    self->item     = nil;
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->selected);
  RELEASE(self->item);
  [super dealloc];
}
#endif

// accessors
- (NSArray*)availableCurrencys {
  static NSArray *all = nil;
  if (all == nil) {
    all = [[NSArray alloc] initWithObjects:@"DEM", @"EUR", nil];
  }
  return all;
}

- (void)setItem:(id)_item {
  ASSIGN(self->item,_item);
}
- (id)item {
  return self->item;
}

- (BOOL)isItemSelected {
  return [self->item isEqualToString:[self currency]];
}

- (NSString *)itemFormatted {
  return [NSString stringWithFormat:@"[%@]", self->item];
}

// bindings
- (void)setCurrency:(NSString *)_cur {
  if (![[self availableCurrencys] containsObject:_cur]) {
    NSLog(@"WARNING[%s]: currency %@ is unknown",
          __PRETTY_FUNCTION__, _cur);
    return;
  }
  ASSIGN(self->selected,_cur);
}
- (NSString *)currency {
  if (self->selected == nil)
    [self setCurrency:@"DEM"];
  return self->selected;
}

// action
- (id)toggleSelected {
  [self setCurrency:self->item];
  return nil;
}

@end /* SkyInlineCurrencyToggle */
