/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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
// $Id$

#include <OGoIDL/SkyIDLSaxBuilder.h>
#include <OGoIDL/SkyIDLInterface.h>
#include "common.h"

@implementation SkyIDLSaxBuilder

static NSDictionary *Classes   = nil;

+ (void)initialize {
  if (Classes == nil) {
    NSEnumerator        *tagEnum;
    NSMutableDictionary *dummy;
    NSString            *tag;
    NSSet               *validTags;
    
    validTags = [[NSSet alloc] initWithObjects:
                               @"documentation",
                               @"example",
                               @"fault",
                               @"import",
                               @"input",
                               @"interface",
                               @"method",
                               @"output",
                               @"signature",
                               @"throw",
                               nil];

    dummy   = [NSMutableDictionary dictionary];
    tagEnum = [validTags objectEnumerator];
    while ((tag = [tagEnum nextObject])) {
      NSString *cName;
      NSString *str;
      Class    clazz;

      if ([tag length] == 0) continue;
      
      str   = [tag substringToIndex:1];
      cName = [@"SkyIDL" stringByAppendingString:[str uppercaseString]];
      cName = [cName stringByAppendingString:[tag substringFromIndex:1]];
      clazz     = NSClassFromString(cName);
      if (clazz != Nil)
        [dummy setObject:clazz forKey:tag];
    }
    Classes = [[NSDictionary alloc] initWithDictionary:dummy];
    RELEASE(validTags);
  }
}

+ (id)_makeSaxParserWithHandler:(id)_handler {
  id parser;
  
  parser = [[SaxXMLReaderFactory standardXMLReaderFactory] createXMLReader];
  [parser setContentHandler:_handler];
  [parser setErrorHandler:_handler];
  return parser;
}

+ (SkyIDLInterface *)parseInterfaceFromData:(NSData *)_data {
  NSAutoreleasePool *pool;
  id parser, sax;
  id result;

  pool   = [[NSAutoreleasePool alloc] init];
  sax    = AUTORELEASE([[self alloc] init]);
  parser = [self _makeSaxParserWithHandler:sax];
  [parser parseFromSource:_data];
  result = RETAIN([sax interface]);
  RELEASE(pool); pool = nil;
  
  return AUTORELEASE(result);
}
+ (SkyIDLInterface *)parseInterfaceFromContentsOfFile:(NSString *)_path {
  NSAutoreleasePool *pool;
  id parser, sax;
  id result;

  if ([_path length] == 0) return nil;

  _path = [@"file://" stringByAppendingString:_path];

  pool   = [[NSAutoreleasePool alloc] init];
  sax    = AUTORELEASE([[self alloc] init]);
  parser = [self _makeSaxParserWithHandler:sax];
  [parser parseFromSystemId:_path];
  result = RETAIN([sax interface]);
  RELEASE(pool); pool = nil;
  
  return AUTORELEASE(result);
}

- (id)init {
  if ((self = [super init])) {
    NSZone *z;

    z = [self zone];
    self->valueStack = [[NSMutableArray allocWithZone:z] initWithCapacity:8];
    self->namespaces = [[NSMutableDictionary allocWithZone:z]
                                             initWithCapacity:32];
    self->characters = [[NSMutableString allocWithZone:z]
                                         initWithCapacity:256];

  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->valueStack);
  RELEASE(self->namespaces);
  RELEASE(self->interface);
  RELEASE(self->characters);
  [super dealloc];
}
#endif

/* result access */

- (SkyIDLInterface *)interface {
  return self->interface;
}

- (unsigned)tagDepth {
  return self->tagDepth;
}

- (BOOL)_ensureIsNotRootElement:(NSString *)_tagName {
  if ([self tagDepth] <= 1) {
    NSLog(@"%s: <%@> cannot be the root element!",
          __PRETTY_FUNCTION__,
          _tagName);
    return NO;
  }
  if ([self interface] == nil) {
    NSLog(@"%s: missing <interface> root element!", __PRETTY_FUNCTION__);
    return NO;
  }
  return YES;
}

/*** processing ***/

- (void)start_interface:(id<SaxAttributes>)_attrs ns:(NSString *)_ns {
  NSAssert([self->valueStack count] == 0,
           @"<interface> can only be root element !");
  NSAssert(self->interface == nil, @"<interface> can only occur once !");
  self->interface =
    [[SkyIDLInterface alloc] initWithAttributes:_attrs
                             namespace:_ns
                             namespaces:self->namespaces];
  [self->valueStack addObject:self->interface];
}
- (void)end_interface {
  [self->valueStack removeLastObject];
  [self->interface prepareInterface];
}

/* SAX */

- (void)startDocument {
  self->tagDepth        = 0;
  self->invalidTagDepth = 0;
  [self->valueStack removeAllObjects];
  [self->namespaces removeAllObjects];
  ASSIGN(self->interface, (id)nil);
  [self->characters setString:@""];
}
- (void)endDocument {
  if ([self->valueStack count] != 0) {
    NSLog(@"%s: valueStack is not empty (%@)",
          __PRETTY_FUNCTION__, self->valueStack);
  }
  if (self->tagDepth != 0) {
    NSLog(@"%s: tagDepth is not 0 (%d)",
          __PRETTY_FUNCTION__, self->tagDepth);
  }
  if ([[self->namespaces allKeys] count] > 0) {
    NSLog(@"%s: namespaces dict is not empty (%@)",
          __PRETTY_FUNCTION__, self->namespaces);
  }
}

- (Class)classForElement:(NSString *)_localName namespace:(NSString *)_ns {
  if (!isSkyIdlNamespace(_ns))
    return Nil;

  return [Classes objectForKey:_localName];
}

- (void)startElement:(NSString *)_localName
  namespace:(NSString *)_ns
  rawName:(NSString *)_rawName
  attributes:(id<SaxAttributes>)_attrs
{
  self->tagDepth++;
  [self->characters setString:@""];
  if (self->invalidTagDepth > 0) return;

  if (isSkyIdlNamespace(_ns) &&
           [_localName isEqualToString:@"interface"]) {
     [self start_interface:_attrs ns:_ns];
  }
  else {
    SkyIDLTag *topValue = nil;
    SkyIDLTag *tag      = nil;
    Class clazz;
    
    [self _ensureIsNotRootElement:_localName];
    topValue = [self->valueStack lastObject];

    if ((clazz = [self classForElement:_localName namespace:_ns])) {
      tag = [[clazz alloc]
                    initWithAttributes:_attrs
                    namespace:_ns
                    namespaces:self->namespaces];
    }
    else {
      /* ToDo: create extra elements ?? */
      NSLog(@"+++ could not create class for element <%@>", _localName);
    }
    
    if ([topValue isTagAccepted:tag]) {
      [topValue addTag:tag];
      [self->valueStack addObject:tag];
    }
    else {
      self->invalidTagDepth = self->tagDepth;
      NSLog(@"Warning:(%s): cannot add element (%@) to (%@)",
            __PRETTY_FUNCTION__,
            _localName,
            [topValue tagName]);
    }
    RELEASE(tag);
  }
}

- (void)endElement:(NSString *)_localName
  namespace:(NSString *)_ns
  rawName:(NSString *)_rawName
{
  self->tagDepth--;

  if (self->invalidTagDepth > 0) {
    if (self->tagDepth >= (self->invalidTagDepth-1)) return;
    self->invalidTagDepth = 0;
  }
  
  if ([_localName isEqualToString:@"interface"])
    [self end_interface];
  else {
    SkyIDLTag *topValue;

    topValue = [self->valueStack lastObject];
    [topValue setCharacters:self->characters];
    if ([[topValue tagName] isEqualToString:_localName])
      [self->valueStack removeLastObject];
  }
}

- (void)startPrefixMapping:(NSString *)_prefix uri:(NSString *)_uri {
  NSMutableArray *uriStack;

  if ((uriStack = [self->namespaces objectForKey:_prefix])) {
    [uriStack addObject:_uri];
  }
  else {
    uriStack = [NSMutableArray arrayWithCapacity:4];
    [uriStack addObject:_uri];
    [self->namespaces setObject:uriStack forKey:_prefix];
  }
}

- (void)endPrefixMapping:(NSString *)_prefix {
  NSMutableArray *uriStack;

  if ((uriStack = [self->namespaces objectForKey:_prefix])) {
    [uriStack removeLastObject];
  }
  if ([uriStack count] == 0)
    [self->namespaces removeObjectForKey:_prefix];
}

- (void)characters:(unichar *)_chars length:(int)_len {
  if (_len > 0) {
    [self->characters appendString:
         [NSString stringWithCharacters:_chars length:_len]];
  }
}

/* error handler */

- (void)warning:(SaxParseException *)_exception {
  NSLog(@"warning: %@", [_exception reason]);
}
- (void)error:(SaxParseException *)_exception {
  NSLog(@"error: %@", [_exception reason]);
}
- (void)fatalError:(SaxParseException *)_exception {
  [_exception raise];
}

@end /* SkyIDLSaxBuilder */
