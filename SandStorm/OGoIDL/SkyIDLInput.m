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

#include <OGoIDL/SkyIDLInput.h>
#include "common.h"

static unsigned SkyIDLInputNameCounter = 0;

@implementation SkyIDLInput

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->name);
  RELEASE(self->type);
  
  [super dealloc];
}
#endif

/* attributes */

- (NSString *)name {
  return self->name;
}

- (NSString *)type {
  return self->type;
}

@end /* SkyIDLInput */

@implementation SkyIDLInput(SkyIDLSaxBuilder)

- (id)initWithAttributes:(id<SaxAttributes>)_attrs
               namespace:(NSString *)_namespace
              namespaces:(NSDictionary *)_ns {
  if ((self = [super initWithAttributes:_attrs
                     namespace:_namespace
                     namespaces:_ns])) {
  
    self->name  = [[_attrs valueForRawName:@"name"] copy];
    self->type  = [self copy:@"type" attrs:_attrs ns:_ns];

    if (self->name == nil) {
      self->name =
        [[NSString stringWithFormat:@"_part%d", SkyIDLInputNameCounter++] copy];
    }
  }
  return self;
}

- (NSString *)tagName {
  return @"input";
}

- (void)_setName:(NSString *)_name {
  ASSIGNCOPY(self->name, _name);
}

- (NSArray *)qnamedExtraAttributes {
  static NSArray *qnamedAttrs = nil;

  if (qnamedAttrs == nil) {
    qnamedAttrs = [[NSArray alloc] initWithObjects:
               @"{http://schemas.xmlsoap.org/soap/encoding/}arrayType",
               @"{http://schemas.xmlsoap.org/soap/encoding/}type",
               @"{http://www.skyrix.com/od/xmlrpc-types}type", nil];
  }
  return qnamedAttrs;
}

@end /* SkyIDLInput(SkyIDLSaxBuilder) */
