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

#include "common.h"
#include "ComponentElement.h"

@implementation ComponentElement

/* initialization */

- (id)init {
  return [self initWithKey:nil name:nil];
}

- (id)initWithKey:(NSString *)_key name:(NSString *)_name {
  if ((self = [super init])) {
    self->key = [_key copy];
    self->name = [_name copy];
    self->subComponents = [[NSMutableArray arrayWithCapacity:2] retain];
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->key);
  RELEASE(self->name);
  RELEASE(self->subComponents);
  [super dealloc];
}

/* accessors */

- (NSString *)key {
  return self->key;
}

- (NSString *)name {
  return self->name;
}

- (NSArray *)subComponents {
  return self->subComponents;
}
@end /* ComponentElement */
