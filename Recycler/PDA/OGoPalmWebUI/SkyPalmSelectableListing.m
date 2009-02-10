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

#include "SkyPalmSelectableListing.h"
#include <Foundation/Foundation.h>

@implementation SkyPalmSelectableListing

- (id)init {
  if ((self = [super init])) {
    self->item    = nil;
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->item);
  [super dealloc];
}
#endif

- (BOOL)synchronizesVariablesWithBindings {
  return NO;
}

// accessors

- (NSArray *)list {
  return [self valueForBinding:@"list"];
}

- (void)setItem:(id)_item {
  ASSIGN(self->item,_item);
  [self setValue:_item forBinding:@"item"];
}
- (id)item {
  return self->item;
}
- (NSString *)title {
  return [self valueForBinding:@"title"];
}

- (NSMutableArray *)selections {
  return [self valueForBinding:@"selections"];
}
- (void)setSelections:(NSMutableArray *)_sels {
  [self setValue:_sels forBinding:@"selections"];
}

// actions

- (id)selectItem {
  return [self valueForBinding:@"selectItem"];
}
- (id)selectItems {
  return [self valueForBinding:@"selectItems"];
}

@end /* SkyPalmSelectableListing */
