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

#include <OGoIDL/SkyIDLTag.h>
#include <OGoIDL/SkyIDLDocumentation.h>
#include <OGoIDL/SkyIDLInterface.h>
#include <SaxObjC/SaxDefaultHandler.h>
#include "common.h"

@implementation SkyIDLTag

- (void)dealloc {
  RELEASE(self->documentation);
  RELEASE(self->namespace);
  RELEASE(self->extraAttributes);
  [super dealloc];
}

/* accessors */

- (SkyIDLDocumentation *)documentation {
  return self->documentation;
}

- (NSArray *)extraAttributeNames {
  return [self->extraAttributes allKeys];
}

- (NSString *)extraAttributeWithName:(NSString *)_name {
  if (_name == nil)
    return nil;
  return [self->extraAttributes objectForKey:_name];
}

- (NSString *)description {
  NSMutableString *s;
  
  s = [NSMutableString stringWithFormat:@"<%p[%@]: ",
                         self, NSStringFromClass([self class])];
  [s appendString:@">"];
  return s;
}

@end /* SkyIDLTag */

@implementation SkyIDLTag(SkyIDLSaxBuilder)

- (id)initWithAttributes:(id<SaxAttributes>)_attrs
               namespace:(NSString *)_namespace
              namespaces:(NSDictionary *)_namespaces {
  if ((self = [super init])) {
    NSArray *qnamedAttrs;
    unsigned i, cnt;
    
    self->namespace = [_namespace copy];
    self->extraAttributes = [[NSMutableDictionary alloc] initWithCapacity:4];

    cnt = [_attrs count];
    qnamedAttrs = [self qnamedExtraAttributes];
    
    for (i=0; i<cnt; i++) {
      NSString *uri   = [_attrs uriAtIndex:i];

      if (!isSkyIdlNamespace(uri)) {
        NSString *name  = [_attrs nameAtIndex:i];
        NSString *value = [_attrs valueAtIndex:i];
        NSString *key   = [NSString stringWithFormat:@"{%@}%@", uri, name];

        if ([qnamedAttrs containsObject:key])
          value = [self _getQNameFrom:value ns:_namespaces];
        
        if (key && value)
          [self->extraAttributes setObject:value forKey:key];
      }
    }
  }
  return self;
}

- (NSString *)namespace {
  return self->namespace;
}

- (void)prepareWithInterface:(SkyIDLInterface *)_interface {
  // do nothing
}

- (NSString *)tagName {
  return [self notImplemented:_cmd];
}

- (BOOL)isTagAccepted:(SkyIDLTag *)_tag {
  return [[_tag tagName] isEqualToString:@"documentation"];
}

- (BOOL)addTag:(SkyIDLTag *)_tag {
  if ([[_tag tagName] isEqualToString:@"documentation"]) {
    ASSIGN(self->documentation, _tag);
    return YES;
  }
  return NO;
}

- (void)setCharacters:(NSString *)_characters {
  // do nothing
}

- (NSArray *)qnamedExtraAttributes {
  return nil;
}

@end /* SkyIDLTag(SkyIDLSaxBuilder) */

@implementation SkyIDLTag(SkyIDLSaxBuilder_PrivateMethods)
- (BOOL)_insertTag:(SkyIDLTag *)_tag intoDict:(NSMutableDictionary *)_dict {
  NSString *n;

  if (![_tag respondsToSelector:@selector(name)])
    return NO;
  
  n = [(id)_tag name];
  if (n) {
    [_dict setObject:_tag forKey:n];
    return YES;
  }
  else {
    NSLog(@"%s WARNING: tagName of %@ is nil!", __PRETTY_FUNCTION__, _tag);
    return NO;
  }
}

// e.g. "xsd:string" --> "{http://schemas.xmlsoap.org/soap}string"
- (NSString *)_getQNameFrom:(NSString *)_value ns:(NSDictionary *)_ns {
  NSArray  *segs;

  segs  = [_value componentsSeparatedByString:@":"];
  if ([segs count] <= 1)
    return _value;
  else {
    NSString *prefix = [segs objectAtIndex:0];
    NSString *result;
    
    if ((result = [[_ns objectForKey:prefix] lastObject])) {
      NSString *suffix;
      
      segs   = [segs subarrayWithRange:NSMakeRange(1,[segs count] - 1)];
      suffix = [segs componentsJoinedByString:@":"];
      result = [NSString stringWithFormat:@"{%@}", result];
      result = [result stringByAppendingString:suffix];

      return result;
    }
    return _value;
  }
}

- (NSString *)copy:(NSString *)_key
             attrs:(id<SaxAttributes>)_attrs
                ns:(NSDictionary *)_ns
{
  NSString *value;

  value = [_attrs valueForRawName:_key];
  return [[self _getQNameFrom:value ns:_ns] copy];
}

- (void)append:(NSString *)_value
          attr:(NSString *)_attrName
      toString:(NSMutableString *)_str
{
  if (_value) {
    [_str appendString:@" "];
    [_str appendString:_attrName];
    [_str appendString:@"=\""];
    [_str appendString:_value];
    [_str appendString:@"\""];
  }
}

- (void)_prepareTags:(id)_tags withInterface:(SkyIDLInterface *)_interface {
  NSEnumerator *tagEnum;
  SkyIDLTag *tag;

  tagEnum = [_tags objectEnumerator];
  while ((tag = [tagEnum nextObject])) {
    [tag prepareWithInterface:_interface];
  }
}

@end /* SkyIDLTag(SkyIDLSaxBuilder_PrivateMethods) */
