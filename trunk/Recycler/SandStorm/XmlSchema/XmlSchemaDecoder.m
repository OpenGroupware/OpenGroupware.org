
#include "XmlSchemaCoder.h"
#include "XmlSchema.h"
#include "XmlSchemaMapping.h"
#include "NSObject+XmlSchemaCoding.h"
#include "NSString+XML.h"
#include "common.h"

@interface XmlSchemaInfo : NSObject
{
  XmlSchemaType       *type;
  id                  value;
  NSMutableDictionary *info2List;
  NSMutableArray      *errors;
  
  XmlSchemaMapping    *mapping; // non retained
  NSMutableArray      *stack;   // non retained
}
- (id)initWithStack:(NSMutableArray *)_stack
            mapping:(XmlSchemaMapping *)_mapping
           rootType:(XmlSchemaType *)_rootType
          localName:(NSString *)_localName
          namespace:(NSString *)_namespace;

- (XmlSchemaType *)elementType;

- (void)setValue:(id)_value;
- (id)value;

- (BOOL)isComplete;

- (void)prepareForRemovingFromStack;

- (NSArray *)errors;

@end /* XmlSchemaInfo */

@interface XmlSchemaInfo(PrivateMethods)
- (NSArray *)_infos;
- (void)_addValue:(id)_value forInfo:(XmlSchemaInfo *)_info;
@end /* XmlSchemaInfo(PrivateMethods) */


@interface XmlSchemaDecoder(PrivateMethods)
- (Class)_valueClass;
- (void)_endElement;
- (void)_setAttributes:(id<SaxAttributes>)_attrs
                  type:(XmlSchemaType *)_type
                object:(id)_object;
- (void)_endError:(NSString *)_errorCode
     localName:(NSString *)_localName
     namespace:(NSString *)_namespace;
- (void)_startError:(NSString *)_errorCode
          localName:(NSString *)_localName
          namespace:(NSString *)_namespace;

@end /* XmlSchemaDecoder(PrivateMethods) */

@implementation XmlSchemaDecoder

static NSDictionary *ErrorCodes  = nil;

+ (void)initialize {
  if (ErrorCodes == nil) {
    NSString *file;

    file       = @"XmlSchemaErrorCodes.plist";
    ErrorCodes = [[NSDictionary alloc] initWithContentsOfFile:file];
  }
}

+ (id)_makeSaxParserWithHandler:(id)_handler {
  id parser;
  
  parser = [[SaxXMLReaderFactory standardXMLReaderFactory] createXMLReader];
  [parser setContentHandler:_handler];
  [parser setErrorHandler:_handler];
  return parser;
}

+ (id)parseObjectFromData:(NSData *)_data
                  mapping:(XmlSchemaMapping *)_mapping
                 rootType:(XmlSchemaType *)_rootType
{
  NSAutoreleasePool *pool;
  id parser, sax;
  id result;

  pool   = [[NSAutoreleasePool alloc] init];
  sax    = AUTORELEASE([[self alloc] init]);
  [sax setMapping:_mapping];
  [sax setRootType:_rootType];
  parser = [self _makeSaxParserWithHandler:sax];
  [parser parseFromSource:_data];
  result = RETAIN([sax object]);
  RELEASE(pool); pool = nil;
  
  return AUTORELEASE(result);
}

+ (id)parseObjectFromContentsOfFile:(NSString *)_path
                            mapping:(XmlSchemaMapping *)_mapping
                           rootType:(XmlSchemaType *)_rootType
{
  NSAutoreleasePool *pool;
  id parser, sax;
  id result;

  if ([_path length] == 0) return nil;

  _path = [@"file://" stringByAppendingString:_path];

  pool   = [[NSAutoreleasePool alloc] init];
  sax    = AUTORELEASE([[self alloc] init]);
  [sax setMapping:_mapping];
  [sax setRootType:_rootType];
  parser = [self _makeSaxParserWithHandler:sax];
  [parser parseFromSystemId:_path];
  result = RETAIN([sax object]);
  RELEASE(pool); pool = nil;
  
  return AUTORELEASE(result);
}

- (id)init {
  if ((self = [super init])) {
    NSZone *z;

    z = [self zone];
    self->infoStack  = [[NSMutableArray allocWithZone:z] initWithCapacity:8];
    self->characters = [[NSMutableString allocWithZone:z]
                                         initWithCapacity:128];
    self->namespaces = [[NSMutableDictionary allocWithZone:z]
                                             initWithCapacity:32];
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->infoStack);
  RELEASE(self->characters);
  RELEASE(self->namespaces);
  RELEASE(self->object);
  RELEASE(self->mapping);

  [super dealloc];
}
#endif

/* accessors */
- (void)setNamespaces:(NSMutableDictionary *)_namespaces {
  ASSIGN(self->namespaces, _namespaces);
}

- (id)object {
  return self->object;
}

- (unsigned)tagDepth {
  return self->tagDepth;
}

- (void)setMapping:(XmlSchemaMapping *)_mapping {
  ASSIGN(self->mapping, _mapping);
}
- (XmlSchemaMapping *)mapping {
  return self->mapping;
}

- (void)setRootType:(XmlSchemaType *)_rootType {
  ASSIGN(self->rootType, _rootType);
}
- (XmlSchemaType *)rootType {
  return self->rootType;
}

/* ************************ */

/* SAX */

- (void)startDocument {
  self->tagDepth        = 0;
  self->invalidTagDepth = 0;
  [self->infoStack    removeAllObjects];
  [self->namespaces   removeAllObjects];
  [self->characters   setString:@""];
  ASSIGN(self->object, (id)nil);
}
- (void)endDocument {
  if ([self->infoStack count] != 0) {
    NSLog(@"%s: Warning: infoStack is not empty (%@)",
          __PRETTY_FUNCTION__, self->infoStack);
    NSLog(@"value is %@", [[self->infoStack objectAtIndex:0] value]);
  }
  if (self->tagDepth != 0) {
    NSLog(@"%s: Warning: tagDepth is not 0 (%d)",
          __PRETTY_FUNCTION__, self->tagDepth);
  }
}

- (void)startElement:(NSString *)_localName
  namespace:(NSString *)_ns
  rawName:(NSString *)_rawName
  attributes:(id<SaxAttributes>)_attrs
{
  XmlSchemaInfo *info    = nil;
  id            value    = nil;

  self->tagDepth++;
  [self->characters setString:@""];

  if (self->invalidTagDepth > 0) return;

  info = [[[XmlSchemaInfo alloc] initWithStack:self->infoStack
                                 mapping:self->mapping
                                 rootType:self->rootType
                                 localName:_localName
                                 namespace:_ns] autorelease];
  
  if (![info isComplete]) { // is info on stack ???
    NSString  *errorCode = [[info errors] lastObject];

    if (errorCode == nil)
      errorCode = @"103"; // Error: Could not find element or schema
    
    return [self _startError:errorCode localName:_localName namespace:_ns];
  }

  if (![[info elementType] isSimpleType]) {
    value = [[[self _valueClass] alloc] initWithBaseValue:nil
                                        type:[info elementType]
                                        mapping:self->mapping];
    [self _setAttributes:_attrs type:[info elementType] object:value];
  }
  else
    return;
  
  if (value == nil) // Error: Could not instantiate complex object
    return [self _startError:@"101" localName:_localName namespace:_ns];
  else
    [info setValue:value];
}

- (void)endElement:(NSString *)_localName
  namespace:(NSString *)_ns
  rawName:(NSString *)_rawName
{
  XmlSchemaInfo *info;
  id            value;
  
  if (self->invalidTagDepth > 0) {
    if (self->tagDepth > (self->invalidTagDepth)) {
      self->tagDepth--;
      return;
    }
    self->invalidTagDepth = 0;
  }

  info = [self->infoStack lastObject];
  if (![info isComplete])
    return [self _endElement];

  if ([[info elementType] isSimpleType]) {
    value = [[[self _valueClass] alloc] initWithBaseValue:self->characters
                                        type:[info elementType]
                                        mapping:self->mapping];
  }
  else
    return [self _endElement];

  if (value == nil)  // Error: could not instantiate simple object
    return [self _endError:@"102" localName:_localName namespace:_ns];
  else
    [info setValue:value];

  return [self _endElement];
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

@end /* XmlSchemaDecoder */

@implementation XmlSchemaDecoder(PrivateMethods)

- (void)_endElement {
  self->tagDepth--;

  if (([self->infoStack count] == 1) && (self->object == nil)) {
    id obj = [[self->infoStack lastObject] value];
    ASSIGN(self->object, obj);
  }
  [[self->infoStack lastObject] prepareForRemovingFromStack];
  [self->infoStack removeLastObject];
}

- (Class)_valueClass {
  return [self->mapping classForType:[[self->infoStack lastObject] elementType]];
}

- (void)_setAttributes:(id<SaxAttributes>)_attrs
                  type:(XmlSchemaType *)_type
                object:(id)_object
{
  unsigned i, cnt= [_attrs count];

  for (i=0; i<cnt; i++) {
    NSString           *name = [_attrs nameAtIndex:i];
    NSString           *val  = [_attrs valueAtIndex:i];
    XmlSchemaAttribute *attr = [_type  attributeWithName:name];

    if (attr)
      [_object takeValue:val forAttribute:attr mapping:self->mapping];
  }
}

- (void)_error:(NSString *)_errorCode
     localName:(NSString *)_localName
     namespace:(NSString *)_namespace
{
  NSAssert1(_errorCode, @"%s: error code is nil!", __PRETTY_FUNCTION__);
  
  NSLog(@"XmlSchemaDecoder: Error(%@): %@ (tagName='%@', namespace='%@')",
        _errorCode,
        [ErrorCodes objectForKey:_errorCode],
        _localName,
        _namespace);
}

- (void)_startError:(NSString *)_errorCode
     localName:(NSString *)_localName
     namespace:(NSString *)_namespace
{
  [self _error:_errorCode localName:_localName namespace:_namespace];
  self->invalidTagDepth = self->tagDepth;
}

- (void)_endError:(NSString *)_errorCode
        localName:(NSString *)_localName
        namespace:(NSString *)_namespace {
  [self _error:_errorCode localName:_localName namespace:_namespace];
  self->tagDepth--;  
}

@end /* XmlSchemaDecoder(PrivateMethods) */

@implementation XmlSchemaInfo

- (id)initWithStack:(NSMutableArray *)_stack
            mapping:(XmlSchemaMapping *)_mapping
           rootType:(XmlSchemaType *)_rootType
          localName:(NSString *)_localName
          namespace:(NSString *)_ns
{
  if ((self = [super init])) {
    XmlSchemaInfo *topInfo = nil;
    XmlSchemaType *newType = nil;
    unsigned      cnt;
    
    self->stack   = _stack;   // non retained !!!
    self->mapping = _mapping; // non retained !!!

    topInfo    = [self->stack lastObject];
    cnt        = [self->stack count];

    NSAssert1(((cnt==0) || [topInfo isComplete]),
              @"%s: info MUST be complete!", __PRETTY_FUNCTION__);

    if (cnt == 0)
      newType = _rootType;
    else
      newType = [_mapping typeFromType:[topInfo elementType] name:_localName];
    
    ASSIGN(self->type, newType);

    if (![self isComplete]) {
      self->errors = [[NSMutableArray alloc] initWithCapacity:4];
      [self->errors addObject:@"105"]; // Error: type not found
      [self->stack addObject:self];
      return self;
    }
    else { // check whether info already exists
      NSEnumerator  *infoEnum = [[topInfo _infos] objectEnumerator];
      XmlSchemaInfo *info;

      while ((info = [infoEnum nextObject])) {
        if ([info elementType] == self->type) {
          RELEASE(self); self = [info retain];
          break;
        }
      }
      [self->stack addObject:self];
      if (self->info2List == nil)
        self->info2List = [[NSMutableDictionary alloc] initWithCapacity:8];
      return self;
    }
  }
  NSAssert1(NO, @"%s: This should *never* be happen!", __PRETTY_FUNCTION__);
  RELEASE(self); self = nil;
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->value);
  RELEASE(self->type);
  RELEASE(self->info2List);
  RELEASE(self->errors);
  // self->stack   is non retained !!!
  // self->mapping is non retained !!!
  
  [super dealloc];
}
#endif

- (XmlSchemaType *)elementType {
  return self->type;
}

- (void)setValue:(id)_val {
  XmlSchemaInfo *topInfo = nil;
  id             topValue = nil;
  unsigned       cnt      = [self->stack count];

  if (_val == nil) return;

  NSAssert1([self isComplete],
            @"%s:info is not complete", __PRETTY_FUNCTION__);
  
  NSAssert1((cnt > 0),
            @"%s: Stack MAY NOT be empty", __PRETTY_FUNCTION__);
  
  NSAssert1(([self->stack lastObject] == self),
            @"%s: info MUST be at the top of the stack!!!",
            __PRETTY_FUNCTION__);
  
  if (cnt > 1)
    topInfo = [self->stack objectAtIndex:cnt-2];
  
  topValue = [topInfo value];

  if ([self->type isScalar])
    [topValue takeValue:_val
              forElement:(XmlSchemaElement *)self->type
              mapping:self->mapping];
  else
    [topInfo _addValue:_val forInfo:self];
  
  ASSIGN(self->value, _val);
}
- (id)value {
  return self->value;
}

- (BOOL)isComplete {
  if (self->type != nil)
    return YES;
  else
    return NO;
}

- (NSArray *)errors {
  return (NSArray *)self->errors;
}

- (void)prepareForRemovingFromStack {
  NSArray       *infos    = [self->info2List allKeys];
  NSEnumerator  *infoEnum = [infos objectEnumerator];
  XmlSchemaInfo *info;

  while ((info = [infoEnum nextObject])) {
    [self->value takeValue:[self->info2List objectForKey:info]
         forElement:(XmlSchemaElement *)[info elementType]
         mapping:self->mapping];
    [self->info2List removeObjectForKey:info];
  }
}

@end /* XmlSchemaInfo */

@implementation XmlSchemaInfo(PrivateMethods)

- (NSArray *)_infos {
  return [self->info2List allKeys];
}

- (void)_addValue:(id)_value forInfo:(XmlSchemaInfo *)_info {
  NSMutableArray *list;

  if (_info == nil) {
    NSLog(@"Warning(%s): _info is nil!", __PRETTY_FUNCTION__);
    return;
  }
  if (_value == nil) return;
  
  list = [self->info2List objectForKey:_info];
  if (list == nil) {
    list = [NSMutableArray arrayWithCapacity:8];
    [self->info2List setObject:list forKey:_info];
  }
  [list addObject:_value];
}

@end /* XmlSchemaInfo(PrivateMethods) */
