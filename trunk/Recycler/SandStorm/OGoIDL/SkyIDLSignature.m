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

#include <OGoIDL/SkyIDLSignature.h>
#include <OGoIDL/SkyIDLInput.h>
#include <OGoIDL/SkyIDLOutput.h>
#include <OGoIDL/SkyIDLExample.h>
#include "common.h"

@implementation SkyIDLSignature

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->inputs);
  RELEASE(self->outputs);
  RELEASE(self->example);
  
  [super dealloc];
}
#endif

/* attributes */

/* accessors */

- (NSArray *)inputs {
  return (NSArray *)self->inputs;
}

- (NSArray *)outputs {
  return (NSArray *)self->outputs;
}

- (SkyIDLExample *)example {
  return self->example;
}

@end /* SkyIDLSignature */

@implementation SkyIDLSignature(SkyIDLSaxBuilder)

static NSSet *Valid_signature_ContentTags = nil;

+ (void)initialize {
  if (Valid_signature_ContentTags == nil) {
    Valid_signature_ContentTags = [[NSSet alloc] initWithObjects:
                                                 @"input",
                                                 @"output",
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
    self->inputs  = [[NSMutableArray alloc] initWithCapacity:4];
    self->outputs = [[NSMutableArray alloc] initWithCapacity:4];
    
  }
  return self;
}

- (NSString *)tagName {
  return @"signature";
}

- (BOOL)isTagAccepted:(SkyIDLTag *)_tag {
  if ([super isTagAccepted:_tag])
    return YES;
  else
    return [Valid_signature_ContentTags containsObject:[_tag tagName]];
}

- (BOOL)addTag:(SkyIDLTag *)_tag {
  NSString *tagName;

  tagName = [_tag tagName];
  
  if ([tagName isEqualToString:@"input"]) {
    [self->inputs addObject:_tag];
    return YES;
  }
  else if ([tagName isEqualToString:@"output"]) {
    [self->outputs addObject:_tag];
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
}

@end /* SkyIDLSignature(SkyIDLSaxBuilder) */
