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

#include <OGoIDL/SkyIDLInterface.h>
#include <OGoIDL/SkyIDLSaxBuilder.h>
#include <OGoIDL/SkyIDLImport.h>
#include <XmlSchema/XmlSchema.h>
#include "common.h"

@interface SkyIDLTag(Name)
- (NSString *)name;
@end /* SkyIDLTag(Name) */

@implementation SkyIDLInterface

static NSMutableDictionary *namespace2interface = nil;
static NSMutableDictionary *namespace2file      = nil;

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->name);
  RELEASE(self->targetNamespace);

  RELEASE(self->methods);
  RELEASE(self->imports);
  
  [super dealloc];
}
#endif

+ (void)initialize {
  if (namespace2interface == nil)
    namespace2interface = [[NSMutableDictionary alloc] initWithCapacity:64];
  if (namespace2interface == nil)
    namespace2interface = [[NSMutableDictionary alloc] initWithCapacity:64];
}

+ (SkyIDLInterface *)interfaceForNamespace:(NSString *)_namespace {
  SkyIDLInterface *result;

  if (_namespace == nil) return nil;
  
  result = [namespace2interface objectForKey:_namespace];
  if (result == nil) {
    NSString *file;

    file = [namespace2file objectForKey:_namespace];
    if (file == nil) file = _namespace;
    
    result = [SkyIDLSaxBuilder parseInterfaceFromContentsOfFile:file];
  }
  return result;
}

+ (BOOL)hasInterfaceForNamespace:(NSString *)_namespace {
  return ([namespace2interface objectForKey:_namespace] != nil) ? YES : NO;
}

- (void)registerForNamespace:(NSString *)_namespace {
  if (_namespace == nil) return;
  if ([namespace2interface objectForKey:_namespace] != nil) {
    NSLog(@"can not register %@ for uri '%@'(namespace already exists!)",
          self, _namespace);
    return;
  }
  [namespace2interface setObject:self forKey:_namespace];
}

/* attributes */

- (NSString *)name {
  return self->name;
}

- (NSString *)targetNamespace {
  return self->targetNamespace;
}

/* accessors */

- (NSArray *)methodNames {
  return [self->methods allKeys];
}

- (SkyIDLMethod *)methodWithName:(NSString *)_methodName {
  if (_methodName == nil) return nil;
  return [self->methods objectForKey:_methodName];
}

- (NSArray *)imports {
  return (NSArray *)self->imports;
}

@end /* SkyIDLInterface */

@implementation SkyIDLInterface(SkyIDLSaxBuilder)

static NSSet *Valid_interface_ContentTags = nil;

+ (void)initialize {
  if (Valid_interface_ContentTags == nil) {
    Valid_interface_ContentTags = [[NSSet alloc] initWithObjects:
                                                 @"method",
                                                 @"import",
                                                 nil];
  }
}

- (id)initWithAttributes:(id<SaxAttributes>)_attrs
               namespace:(NSString *)_namespace
              namespaces:(NSDictionary *)_ns {
  if ((self = [super initWithAttributes:_attrs
                     namespace:_namespace
                     namespaces:_ns])) {
  
    self->name           = [[_attrs valueForRawName:@"name"]             copy];
    self->targetNamespace= [[_attrs valueForRawName:@"targetNamesspace"] copy];

    self->methods   = [[NSMutableDictionary alloc] initWithCapacity:16];
    self->imports   = [[NSMutableArray      alloc] initWithCapacity:8];
  }
  return self;
}

- (NSString *)tagName {
  return @"interface";
}

- (BOOL)isTagAccepted:(SkyIDLTag *)_tag {
  if ([super isTagAccepted:_tag])
    return YES;
  else
    return [Valid_interface_ContentTags containsObject:[_tag tagName]];
}

- (BOOL)addTag:(SkyIDLTag *)_tag {
  NSString *tagName;

  tagName = [_tag tagName];
  
  if ([tagName isEqualToString:@"method"]) {
    [self->methods setObject:_tag forKey:[_tag name]];
    return YES;
  }
  else if ([tagName isEqualToString:@"import"]) {
    [self->imports addObject:_tag];
    return YES;
  }
  else
    return [super addTag:_tag];
}

- (void)prepareInterface {
  id schemaRegistry;
  NSEnumerator *tagEnum;
  id           tag;
  
  schemaRegistry = NSClassFromString(@"XmlSchema");
  
  tagEnum = [self->imports objectEnumerator];
  while ((tag = [tagEnum nextObject])) {
    [schemaRegistry registerSchemaAtPath:[(SkyIDLImport *)tag location]];
  }
  // [self _prepareTags:self->methods withInterface:self];
  // [super prepareWithInterface:self];
}

@end /* SkyIDLInterface(SkyIDLSaxBuilder) */
