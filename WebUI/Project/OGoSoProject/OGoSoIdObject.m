/*
  Copyright (C) 2005 Helge Hess

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

#include "OGoSoIdObject.h"
#include "common.h"

@implementation OGoSoIdObject

- (id)initWithName:(NSString *)_key inContainer:(id)_folder {
  if ((self = [super init]) != nil) {
    self->name = [_key copy];
  }
  return self;
}

- (void)dealloc {
  [self->name release];
  [super dealloc];
}

/* accessors */

- (NSString *)nameInContainer {
  return self->name;
}

- (NSString *)entityName {
  [self logWithFormat:@"ERROR: subclass needs to override: %s",
	  __PRETTY_FUNCTION__];
  return nil;
}

- (EOGlobalID *)globalID {
  NSNumber *pkey;

  pkey = [NSNumber numberWithUnsignedInt:
		     [[self nameInContainer] unsignedIntValue]];
  
  return [EOKeyGlobalID globalIDWithEntityName:[self entityName]
			keys:&pkey keyCount:1
			zone:NULL];
}

/* context */

- (OGoNavigation *)navInContext:(WOContext *)_ctx {
  return [(OGoSession *)[_ctx session] navigation];
}

- (id)activateWithVerb:(NSString *)_verb inContext:(WOContext *)_ctx {
  return [[self navInContext:_ctx] activateObject:[self globalID]
				   withVerb:_verb];
}

/* methods */

- (id)defaultAction:(id)_ctx {
  return [self activateWithVerb:@"view" inContext:_ctx];
}

- (id)GETAction:(id)_c {
  return [self defaultAction:_c];
}
- (id)indexAction:(id)_c {
  return [self defaultAction:_c];
}
- (id)viewAction:(id)_c {
  return [self defaultAction:_c];
}

- (id)editAction:(id)_ctx {
  return [self activateWithVerb:@"edit" inContext:_ctx];
}
- (id)mailAction:(id)_ctx {
  return [self activateWithVerb:@"mail" inContext:_ctx];
}
- (id)deleteAction:(id)_ctx {
  return [self activateWithVerb:@"delete" inContext:_ctx];
}

// TODO: any other verbs?

@end /* OGoSoIdObject */
