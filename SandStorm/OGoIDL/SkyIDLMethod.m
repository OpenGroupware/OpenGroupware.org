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

#include <OGoIDL/SkyIDLMethod.h>
#include <OGoIDL/SkyIDLExample.h>
#include "common.h"

@implementation SkyIDLMethod

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->name);

  RELEASE(self->signatures);
  RELEASE(self->example);
  
  [super dealloc];
}
#endif

/* attributes */

- (NSString *)name {
  return self->name;
}

/* accessors */

- (NSArray *)signatures {
  return (NSArray *)self->signatures;
}

- (SkyIDLExample *)example {
  return self->example;
}

@end /* SkyIDLMethod */

@implementation SkyIDLMethod(SkyIDLSaxBuilder)

static NSSet *Valid_method_ContentTags = nil;

+ (void)initialize {
  if (Valid_method_ContentTags == nil) {
    Valid_method_ContentTags = [[NSSet alloc] initWithObjects:
                                                 @"signature",
                                                 @"example",
                                                 nil];
  }
}

- (id)initWithAttributes:(id<SaxAttributes>)_attrs
               namespace:(NSString *)_namespace
              namespaces:(NSDictionary *)_ns {
  if ((self = [super initWithAttributes:_attrs
                     namespace:_namespace
                     namespaces:_ns])) {
  
    self->name = [[_attrs valueForRawName:@"name"] copy];
    
    self->signatures = [[NSMutableArray alloc] initWithCapacity:4];
  }
  return self;
}

- (NSString *)tagName {
  return @"method";
}

- (BOOL)isTagAccepted:(SkyIDLTag *)_tag {
  if ([super isTagAccepted:_tag])
    return YES;
  else
    return [Valid_method_ContentTags containsObject:[_tag tagName]];
}

- (BOOL)addTag:(SkyIDLTag *)_tag {
  NSString *tagName;

  tagName = [_tag tagName];
  
  if ([tagName isEqualToString:@"signature"]) {
    [self->signatures addObject:_tag];
    return YES;
  }
  else if ([tagName isEqualToString:@"example"]) {
    ASSIGN(self->example, _tag);
    return YES;
  }
  else
    return [super addTag:_tag];
}

- (void)prepareWithInterface:(SkyIDLInterface *)_interface {
  [self->example prepareWithInterface:_interface];
}

@end /* SkyIDLMethod(SkyIDLSaxBuilder) */
