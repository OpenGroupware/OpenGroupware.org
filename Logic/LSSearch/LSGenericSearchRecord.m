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

#include "LSGenericSearchRecord.h"
#include "common.h"

@implementation LSGenericSearchRecord

- (id)init{
  if ((self = [super init])) {
    self->searchDict = [[NSMutableDictionary alloc] initWithCapacity:4];
  }
  return self;
}
 
- (id)initWithEntity:(EOEntity *)_entity {
  if ((self = [self init])) {
    self->entity = [_entity retain];
  }
  return self;
}
 
- (void)dealloc {
  [self->entity     release];
  [self->searchDict release];
  [self->comparator release];
  [super dealloc];
}

/* accessors */

- (void)setEntity:(EOEntity *)_entity {
  ASSIGN(self->entity, _entity);
}
- (EOEntity *)entity {
  return self->entity;
}

- (void)setComparator:(NSString *)_comparator {
  ASSIGNCOPY(self->comparator, _comparator);
}
- (NSString *)comparator {
  return self->comparator;
}

- (NSDictionary *)searchDict {
  return self->searchDict;
}

- (void)removeAllObjects {
  [self->searchDict removeAllObjects];
}

- (void)removeObjectForKey:(id)_key {
  [self->searchDict removeObjectForKey:_key];
}

// enumerators

- (NSEnumerator *)keyEnumerator {
  return [self->searchDict keyEnumerator];
}

/* key/value coding */

- (void)takeValuesFromDictionary:(NSDictionary *)_dictionary {
  NSEnumerator *keyEnum;
  id           key;
  
  keyEnum = [_dictionary keyEnumerator];
  
  while ((key = [keyEnum nextObject]))
    [self takeValue:[_dictionary objectForKey:key] forKey:key];
}

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  [self->searchDict takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  return [self->searchDict valueForKey:_key];
}

/* description */

- (NSString *)description {
  return [NSString stringWithFormat:
		     @"<LSGenericSearchRecord entity %@ searchDict %@>", 
		     self->entity, self->searchDict];
}
@end /* LSGenericSearchRecord */
