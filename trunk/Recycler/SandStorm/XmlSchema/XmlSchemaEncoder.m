
#include "XmlSchema.h"
#include "XmlDefaultClassSchemaMapping.h"
#include "XmlSchemaCoder.h"
#include "NSObject+XmlSchemaCoding.h"
#include "NSMutableString+EscStr.h"
#include "common.h"

@interface XmlSchemaEncoder(CodingPrivateMethodes)
- (void)_reset;
- (void)_encodeObject:(id)_object;
- (void)_encodeObject:(id)_object attrs:(NSDictionary *)_attrs;
- (void)_encodeStruct:(id)_object tag:(id)_tag;
- (void)_encodeChoice:(id)_object tag:(id)_tag;
@end /* XmlSchemaEncoder(CodingPrivateMethodes) */

@implementation XmlSchemaEncoder

- (id)initForWritingWithMutableString:(NSMutableString *)_string {
  if ((self = [super init])) {
    self->string = RETAIN(_string);

    self->objectStack          = [[NSMutableArray alloc] initWithCapacity:8];
    self->objectHasStructStack = [[NSMutableArray alloc] initWithCapacity:8];
    self->typeStack            = [[NSMutableArray alloc] initWithCapacity:8];

    self->timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    RETAIN(self->timeZone);
  }
  return self;
}

- (id)init {
  return [self initForWritingWithMutableString:nil];
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->string);
  RELEASE(self->mapping);
  
  RELEASE(self->objectStack);
  RELEASE(self->objectHasStructStack);
  RELEASE(self->typeStack);

  RELEASE(self->timeZone);
  [super dealloc];
}
#endif

/* accessors */

- (void)setDefaultTimeZone:(NSTimeZone *)_timeZone {
  ASSIGN(self->timeZone, _timeZone);
}
- (NSTimeZone *)defaultTimeZone {
  return self->timeZone;
}

- (void)setString:(NSMutableString *)_string {
  ASSIGN(self->string, _string);
}

- (void)encodeRootObject:(id)_rootObject
                  schema:(XmlSchema *)_schema
             elementName:(NSString *)_elementName
{
  XmlSchemaMapping *myMapping;
  XmlSchemaType    *rootType;

  myMapping = [[XmlDefaultClassSchemaMapping alloc] initWithSchema:_schema];
  rootType  = [_schema elementWithName:_elementName];
    
  [self encodeObject:_rootObject mapping:myMapping rootType:rootType];
  RELEASE(myMapping);
}


- (void)encodeObject:(id)_rootObject
             mapping:(XmlSchemaMapping *)_mapping
            rootType:(XmlSchemaType *)_rootType
{
  XmlSchemaType       *type;
  NSMutableDictionary *attrs = nil;
  NSString            *ns;
  
  [self _reset];
  ASSIGN(self->mapping, _mapping);

  type = _rootType;
  
  if (type == nil) {
    NSLog(@"Warning(%s): Could not find mapping %@ defines no rootType'",
          __PRETTY_FUNCTION__,
          _mapping);
    return;
  }

  if ((ns = [[_mapping schema] targetNamespace])) {
    attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                          ns, @"xmlns", nil];
  }
  
  [self->typeStack addObject:type];
  [self _encodeObject:_rootObject attrs:attrs];
  [self->typeStack removeLastObject];
}


- (void)encodeObject:(id)_object
            typeName:(NSString *)_typeName // (qname)
             tagName:(NSString *)_tagName
{
  XmlSchema        *schema;
  XmlSchemaType    *type;
  NSEnumerator     *nameEnum;
  XmlSchemaContent *content;
  NSString         *name;

  [self _reset];
  type     = [XmlSchema typeWithQName:_typeName];
  content  = [type content];

  schema    = [XmlSchema schemaForNamespace:[_typeName uriFromQName]];
  RELEASE(self->mapping);
  self->mapping = [[XmlDefaultClassSchemaMapping alloc] initWithSchema:schema];

  [self->string appendString:@"<"];
  [self->string appendString:_tagName];
  [self->string appendString:@" xsi:type=\""];  
  [self->string appendString:@"tt:"];
  [self->string appendString:[_typeName valueFromQName]];
  [self->string appendString:@"\""];
  [self->string appendString:@" xmlns:tt=\""];
  [self->string appendString:[_typeName uriFromQName]];
  [self->string appendString:@"\""];
  [self->string appendString:@">"];

  if ([type isSimpleType]) {
    [self->string appendEscStr:[_object baseValueWithMapping:self->mapping]];
  }
  else {
    nameEnum = [[content elementNames] objectEnumerator];

    [self->string appendString:@"\n"];
    while ((name = [nameEnum nextObject])) {
      XmlSchemaElement *element = [content elementWithName:name];

      if (element == nil) continue;
    
      [self->typeStack addObject:element];
      [self _encodeObject:[_object valueForElement:element
                                   mapping:self->mapping]
                     attrs:nil];
      [self->typeStack removeLastObject];
    }
  }
  
  [self->string appendString:@"</"];
  [self->string appendString:_tagName];
  [self->string appendString:@">\n"];
}

@end /* XmlSchemaEncoder */

@implementation XmlSchemaEncoder(CodingPrivateMethodes)

- (void)_reset {
  [self->objectStack          removeAllObjects];
  [self->objectHasStructStack removeAllObjects];
  [self->typeStack            removeAllObjects];
  self->depth = 0;
}

/*
<attribute 
--default = string 
  fixed = string 
  form = (qualified | unqualified)
  id = ID 
--name = NCName 
  ref = QName 
  type = QName 
--use = (optional | prohibited | required) : optional
  {any attributes with non-schema namespace . . .}>
  Content: (annotation?, (simpleType?))
</attribute>
*/

- (void)_encodeAttributes:(id)_object {
  XmlSchemaType *type     = [self->typeStack lastObject];
  NSEnumerator  *nameEnum = [[type attributeNames] objectEnumerator];
  NSString      *name;

  while ((name = [nameEnum nextObject])) {
    XmlSchemaAttribute *attr;
    NSString           *use;
    NSString           *str;

    attr = [type attributeWithName:name];
    use  = [attr use];
    str  = [_object valueForAttribute:attr mapping:self->mapping];
    if (str == nil) str = [attr default];

    if ([use isEqualToString:@"prohibited"]) continue;

    if (str) {
      [self->string appendString:@" "];
      [self->string appendString:name];
      [self->string appendString:@"=\""];
      [self->string appendEscStr:str];
      [self->string appendString:@"\""];
    }
    else if ([use isEqualToString:@"required"]) {
      NSLog(@"Error: __1__ attr '%@' is required!", attr);
    }
  }
}

- (void)_encodeObject:(id)_object {
  [self _encodeObject:_object attrs:nil];
}

- (void)_openTag:(NSString *)_tagName
          object:(id)_object
           attrs:(NSDictionary *)_attrs
{
  NSEnumerator *attrEnum = [_attrs keyEnumerator];
  NSString     *attr;

  [self->string appendString:@"<"];
  [self->string appendString:_tagName];
  
  while ((attr = [attrEnum nextObject])) {
    [self->string appendString:@" "];
    [self->string appendString:attr];
    [self->string appendString:@"=\""];
    [self->string appendEscStr:[_attrs objectForKey:attr]];
    [self->string appendString:@"\""];
  }

  [self _encodeAttributes:_object];
  [self->string appendString:@">"];
}

- (void)_closeTag:(NSString *)_name {
  [self->string appendString:@"</"];
  [self->string appendString:_name];
  [self->string appendString:@">\n"];
}

- (void)_encodeAsOneObject:(id)_object attrs:(NSDictionary *)_attrs {
  XmlSchemaType *type = [self->typeStack lastObject];
  NSString      *name = [type name];

  [self _openTag:name object:_object attrs:_attrs];

  if ([type isSimpleType]) {
    [self->string appendEscStr:[_object baseValueWithMapping:self->mapping]];
  }
  else { // complexType
    XmlSchemaTag  *content = [type content];
    NSString      *tagName = [content tagName];

    [self->string appendString:@"\n"];
    if ([tagName isEqualToString:@"all"] ||
        [tagName isEqualToString:@"sequence"]) {
      [self _encodeStruct:_object tag:content];
    }
    else if ([tagName isEqualToString:@"choice"]) {
      [self _encodeChoice:_object tag:content];
    }
    else {
      NSLog(@"tagName is %@", tagName);
    }
  }
  [self _closeTag:name];
}

- (void)_encodeAsManyObjects:(id)_array attrs:(NSDictionary *)_attrs {
  if (_array == nil) {
  }
  else if ([_array respondsToSelector:@selector(objectEnumerator)]) {
    NSEnumerator *objEnum = [_array objectEnumerator];
    id           obj;

    while ((obj = [objEnum nextObject])) {
      [self _encodeAsOneObject:obj attrs:_attrs];
    }
  }
  else
    [self _encodeAsOneObject:_array attrs:_attrs];
}


- (void)_encodeObject:(id)_object attrs:(NSDictionary *)_attrs {
  XmlSchemaType *type = [self->typeStack lastObject];

  if ([type isScalar])
    [self _encodeAsOneObject:_object attrs:_attrs];
  else
    [self _encodeAsManyObjects:_object attrs:_attrs];
}

- (void)_encodeStruct:(id)_object tag:(id)_tag {
  NSEnumerator *nameEnum = [[_tag elementNames] objectEnumerator];
  NSString     *name     = nil;

  while ((name = [nameEnum nextObject])) {
    XmlSchemaElement *element;

    if ((element = [_tag elementWithName:name])) {
      [self->typeStack addObject:element];
      [self _encodeObject:
            [_object valueForElement:element mapping:self->mapping]];
      [self->typeStack removeLastObject];
    }
  }
}

- (void)_encodeChoice:(id)_object tag:(XmlSchemaChoice *)_tag {
  NSArray *names = [_tag elementNames];

  NSLog(@"names is %@", names);
}


@end /* XmlSchemaEncoder(CodingPrivateMethodes) */
