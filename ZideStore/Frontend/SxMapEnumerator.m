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

#include "SxMapEnumerator.h"
#include "common.h"

@implementation SxMapEnumerator

+ (id)enumeratorWithSource:(NSEnumerator *)_source 
  object:(id)_object selector:(SEL)_sel
{
  return [[[self alloc] initWithSource:_source object:_object selector:_sel]
	   autorelease];
}

- (id)initWithSource:(NSEnumerator *)_source
  object:(id)_object selector:(SEL)_sel
{
  if (_source == nil) {
    [self release];
    return nil;
  }
  NSAssert2([_source respondsToSelector:@selector(nextObject)],
	    @"object '%@'(%@) is not an enumerator !",
	    _object, NSStringFromClass([_object class]));
  if ((self = [super init])) {
    self->source   = [_source retain];
    self->object   = [_object retain];
    self->selector = _sel;
  }
  return self;
}

- (void)dealloc {
  [self->source release];
  [self->object release];
  [super dealloc];
}

/* operation */

- (id)nextObject {
  id obj;
  
  if ((obj = [self->source nextObject]))
    obj = [self->object performSelector:self->selector withObject:obj];
  
  return obj;
}

@end /* SxMapEnumerator */
