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

#include "ShowValue.h"

@interface ShowStructValue : ShowValue
{
  id item;
  id key;
}
@end

#include "common.h"
#include "RunMethod.h"
#include <SxComponents/SxXmlRpcComponent.h>
#include <SxComponents/SxComponentMethodSignature.h>

@implementation ShowStructValue

- (void)dealloc {
  RELEASE(self->item);
  RELEASE(self->key);
  [super dealloc];
}

/* accessors */

- (void)setItem:(id)_val {
  ASSIGN(self->item, _val);
}
- (id)item {
  return self->item;
}
- (void)setKey:(id)_val {
  if (_val != self->key) {
    ASSIGN(self->key, _val);
    [self setItem:[(id)self->value objectForKey:_val]];
  }
}
- (id)key {
  return self->key;
}

- (NSArray *)allKeys {
  return [self->value allKeys];
}

- (NSString *)valueType {
  return @"struct";
}

- (BOOL)isItemSimpleType {
  return [self isSimpleType:[self item]];
}

/* notifications */

- (void)sleep {
  ASSIGN(self->item, nil);
  ASSIGN(self->key,  nil);
  [super sleep];
}

@end /* ShowStructValue */
