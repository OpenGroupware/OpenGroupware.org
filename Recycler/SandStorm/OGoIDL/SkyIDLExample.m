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

#include <OGoIDL/SkyIDLExample.h>
#include "common.h"

@implementation SkyIDLExample

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->characters);

  [super dealloc];
}
#endif

- (NSString *)characters {
  return self->characters;
}

@end /* SkyIDLExample */

@implementation SkyIDLExample(SkyIDLSaxBuilder)


- (id)initWithAttributes:(id<SaxAttributes>)_attrs
               namespace:(NSString *)_namespace
              namespaces:(NSDictionary *)_ns {
  if ((self = [super initWithAttributes:_attrs
                     namespace:_namespace
                     namespaces:_ns])) {
  }
  return self;
}

- (NSString *)tagName {
  return @"example";
}

- (void)setCharacters:(NSString *)_characters {
  ASSIGNCOPY(self->characters, _characters);
}

@end /* SkyIDLExample(SkyIDLSaxBuilder) */
