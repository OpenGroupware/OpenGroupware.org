
#include "XmlSchemaSaxBuilder.h"
#include "XmlSchema.h"
#include "XmlSchemaElement.h"
#include "XmlSchemaAttribute.h"
#include "common.h"

@implementation XmlSchemaSaxBuilder

static NSDictionary *Classes   = nil;

+ (void)initialize {
  if (Classes == nil) {
    NSEnumerator        *tagEnum;
    NSMutableDictionary *dummy;
    NSString            *tag;
    NSSet               *validTags;

    validTags = [[NSSet alloc] initWithObjects:
                               @"all",
                               @"annotation",
                               @"appinfo",
                               @"attribute",
                               @"attributeGroup",
                               @"choice",
                               @"complexContent",
                               @"complexType",
                               @"documentation",
                               @"element",
                               @"group",
                               @"import",
                               @"include",
                               @"list",
                               @"restriction",
                               @"sequence",
                               @"simpleContent",
                               @"simpleType",
                               @"union",
                               nil];

    dummy   = [NSMutableDictionary dictionary];
    tagEnum = [validTags objectEnumerator];
    while ((tag = [tagEnum nextObject])) {
      NSString *cName;
      NSString *str;
      Class    clazz;

      if ([tag length] == 0) continue;
      
      str   = [tag substringToIndex:1];
      cName = [@"XmlSchema" stringByAppendingString:[str uppercaseString]];
      cName = [cName stringByAppendingString:[tag substringFromIndex:1]];
      clazz = NGClassFromString(cName);

      NSAssert2((clazz != Nil),
                @"%s: could not find class for string: %@",
                __PRETTY_FUNCTION__, cName);
      
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

+ (XmlSchema *)parseSchemaFromData:(NSData *)_data {
  NSAutoreleasePool *pool;
  id parser, sax;
  id result;

  pool   = [[NSAutoreleasePool alloc] init];
  sax    = AUTORELEASE([[self alloc] init]);
  parser = [self _makeSaxParserWithHandler:sax];
  [parser parseFromSource:_data];
  result = RETAIN([sax schema]);
  RELEASE(pool); pool = nil;
  
  return AUTORELEASE(result);
}
+ (XmlSchema *)parseSchemaFromContentsOfFile:(NSString *)_path {
  NSAutoreleasePool *pool;
  NSString          *path;
  id parser, sax;
  id result;

#warning should scan anyroot/Library/XmlSchemas/
  if ([_path length] == 0) return nil;
  
  path = [@"file://" stringByAppendingString:_path];
  
  pool   = [[NSAutoreleasePool alloc] init];
  sax    = AUTORELEASE([[self alloc] init]);
  parser = [self _makeSaxParserWithHandler:sax];
  [parser parseFromSystemId:path];
  result = RETAIN([sax schema]);
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
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->valueStack);
  RELEASE(self->namespaces);
  RELEASE(self->schema);
  [super dealloc];
}
#endif

- (void)setNamespaces:(NSMutableDictionary *)_namespaces {
  ASSIGN(self->namespaces, _namespaces);
}

/* result access */

- (XmlSchema *)schema {
  return self->schema;
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
  if ([self schema] == nil) {
    NSLog(@"%s: missing <schema> root element!", __PRETTY_FUNCTION__);
    return NO;
  }
  return YES;
}

/*** processing ***/

- (void)start_schema:(id<SaxAttributes>)_attrs ns:(NSString *)_ns {
  NSAssert([self->valueStack count] == 0,
           @"<schema> can only be root element !");
  NSAssert(self->schema == nil, @"<schema> can only occur once !");

  self->schema =
    [[XmlSchema alloc] initWithAttributes:_attrs
                       namespace:_ns
                       namespaces:self->namespaces];
  [self->valueStack addObject:self->schema];
}
- (void)end_schema {
  [self->valueStack removeLastObject];
}

/* SAX */

- (void)startDocument {
  self->tagDepth        = 0;
  self->invalidTagDepth = 0;
  [self->valueStack removeAllObjects];
  [self->namespaces removeAllObjects];
  ASSIGN(self->schema, (id)nil);
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
}

- (void)startElement:(NSString *)_localName
  namespace:(NSString *)_ns
  rawName:(NSString *)_rawName
  attributes:(id<SaxAttributes>)_attrs
{
  self->tagDepth++;
  
  if (self->invalidTagDepth > 0) return;
  
  if (!isXmlSchemaNamespace(_ns)) {
    NSLog(@"%s: wrong namespace='%@' <%@>",
          __PRETTY_FUNCTION__,_ns, _localName);
    return;
  }
  
  if ([_localName isEqualToString:@"schema"])
    [self start_schema:_attrs ns:_ns];
  else {
    XmlSchemaTag *topValue = nil;
    XmlSchemaTag *tag      = nil;

    [self _ensureIsNotRootElement:_localName];
    topValue = [self->valueStack lastObject];

    if ([topValue isTagNameAccepted:_localName]) {
      tag = [[[Classes objectForKey:_localName] alloc]
                       initWithAttributes:_attrs
                       namespace:_ns
                       namespaces:self->namespaces];
      if (tag == nil) {
        NSLog(@"WARNING (XmlSchemaSaxBuilder: Does not support tag <%@>",
              _localName);
      }
    }
    else if (NO) {
      NSLog(@"Warning:(XmlSchemaSaxBuilder): cannot add element (%@) to (%@)",
            _localName,
            [topValue tagName]);
    }

    if (tag) {
      [topValue addTag:tag];
      [self->valueStack addObject:tag];
      RELEASE(tag);
    }
    else {
      self->invalidTagDepth = self->tagDepth;
    }
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
  
  if (!isXmlSchemaNamespace(_ns)) return;

  if ([_localName isEqualToString:@"schema"])
    [self end_schema];
  else {
    if ([[[self->valueStack lastObject] tagName] isEqualToString:_localName])
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

@end /* XmlSchemaSaxBuilder */
