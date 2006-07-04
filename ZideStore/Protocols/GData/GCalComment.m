/*
  Copyright (C) 2006 Helge Hess

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

#include "GCalComment.h"
#include "GCalComments.h"
#include "common.h"

@implementation GCalComment

- (id)initWithName:(NSString *)_name inContainer:(id)_container {
  if ((self = [super init]) != nil) {
    if (_container == nil || ![_name isNotEmpty]) {
      [self release];
      return nil;
    }
    
    self->name      = [_name copy];
    self->container = [_container retain];
  }
  return self;
}

- (void)dealloc {
  [self->container release];
  [self->name      release];
  [super dealloc];
}

/* accessors */

- (id)container {
  return self->container;
}
- (NSString *)nameInContainer {
  return self->name;
}

/* debugging */

- (BOOL)isDebuggingEnabled {
  return YES; // TODO: make that a default
}

- (NSString *)description {
  NSMutableString *ms = [NSMutableString stringWithCapacity:128];
  
  [ms appendFormat:@"<0x%p[%@]:", self, NSStringFromClass([self class])];
  
  [ms appendFormat:@" name=%@", [self nameInContainer]];
  
  [ms appendString:@">"];
  return ms;
}

@end /* GCalComment */
