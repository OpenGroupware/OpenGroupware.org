// $Id$

#include "XmlSchemaElement.h"
#include "XmlSchema.h"
#include "NSString+XML.h"
#include "common.h"

@implementation XmlSchemaElement

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->block);
  RELEASE(self->defValue);
  RELEASE(self->fixed);
  RELEASE(self->form);
  RELEASE(self->maxOccurs);
  RELEASE(self->minOccurs);
  RELEASE(self->ref);
  RELEASE(self->substitutionGroup);
  RELEASE(self->type);

  RELEASE(self->contentType);
  
  [super dealloc];
}
#endif

/* attributes */

- (BOOL)abstract {
  return self->abstract;
}
- (NSString *)block {
  return self->block;
}
- (NSString *)default {
  return self->defValue;
}
- (NSString *)fixed {
  return self->fixed;
}
- (NSString *)form {
  return self->form;
}
- (NSString *)maxOccurs {
  return self->maxOccurs;
}
- (NSString *)minOccurs {
  return self->minOccurs;
}
- (BOOL)nillable {
  return self->nillable;
}
- (NSString *)ref {
  return self->ref;
}
- (NSString *)substitutionGroup {
  return self->substitutionGroup;
}
- (NSString *)type {
  return self->type;
}

- (NSString *)typeValue {
  return (self->type) ? [self->type valueFromQName] : self->name;
}

/* accessors */

- (BOOL)isSimpleType {
  if (self->contentType == nil) return YES;
  return [self->contentType isSimpleType];
}

- (BOOL)isScalar {
  if ([self->maxOccurs intValue] == 1)
    return YES;
  else
    return NO;
}

- (NSArray *)elementNames {
  if ([self isSimpleType])
    return [NSArray array];
  else {
    return [[self->contentType content] elementNames];
  }
}
- (XmlSchemaElement *)elementWithName:(NSString *)_name {
  return [[self->contentType content] elementWithName:_name];
}

- (NSArray *)attributeNames {
  if ([self isSimpleType])
    return [NSArray array];
  else {
    return [self->contentType attributeNames];
  }
}
- (XmlSchemaAttribute *)attributeWithName:(NSString *)_name {
  return [self->contentType attributeWithName:_name];
}

- (void)setContentType:(XmlSchemaType *)_contentType {
  ASSIGN(self->contentType, _contentType);
}
- (XmlSchemaType *)contentType {
  return self->contentType;
}

- (XmlSchemaContent *)content {
  return [self-> contentType content];
}

- (NSString *)description {
  NSMutableString *str = [NSMutableString stringWithCapacity:128];

  [str appendString:@"<element"];
  [self append:[self name]             attr:@"name"             toString:str];
  [self append:self->type              attr:@"type"             toString:str];
  [self append:self->block             attr:@"block"            toString:str];
  [self append:self->defValue          attr:@"defValue"         toString:str];
  [self append:[self final]            attr:@"final"            toString:str];
  [self append:self->fixed             attr:@"fixed"            toString:str];
  [self append:[self id]               attr:@"id"               toString:str];
  [self append:self->maxOccurs         attr:@"maxOccurs"        toString:str];
  [self append:self->minOccurs         attr:@"minOccurs"        toString:str];
  [self append:self->ref               attr:@"ref"              toString:str];
  [self append:self->substitutionGroup attr:@"substitutionGroup" toString:str];
  
  [self append:(self->abstract) ? @"true" : @"false"
        attr:@"abstract" toString:str];
  [self append:(self->nillable) ? @"true" : @"false"
        attr:@"nillable" toString:str];
  
  [str appendString:@">"];
  [str appendString:[self->contentType description]];
  [str appendString:@"</element>\n"];
  return str;
}

@end /* XmlSchemaElement */

@implementation XmlSchemaElement(XmlSchemaSaxBuilder)
                                
static NSSet *Valid_element_ContentTags = nil;

+ (void)initialize {
  if (Valid_element_ContentTags == nil) {
    Valid_element_ContentTags = [[NSSet alloc] initWithObjects:
                                               @"simpleType",
                                               @"complexType",
                                               @"unique",
                                               @"key",
                                               @"keyref",
                                               nil];
  }
}

- (id)initWithAttributes:(id<SaxAttributes>)_attrs
               namespace:(NSString *)_namespace
              namespaces:(NSDictionary *)_ns {
  if ((self = [super initWithAttributes:_attrs
                     namespace:_namespace
                     namespaces:_ns])) {
    self->block             = [[_attrs valueForRawName:@"block"]     copy];
    self->defValue          = [[_attrs valueForRawName:@"default"]   copy];
    self->fixed             = [[_attrs valueForRawName:@"fixed"]     copy];
    self->form              = [[_attrs valueForRawName:@"form"]      copy];
    self->maxOccurs         = [[_attrs valueForRawName:@"maxOccurs"] copy];
    self->minOccurs         = [[_attrs valueForRawName:@"minOccurs"] copy];
    
    self->ref               = [self copy:@"ref"       attrs:_attrs ns:_ns];
    self->type              = [self copy:@"type"      attrs:_attrs ns:_ns];
    self->substitutionGroup = [self copy:@"substitutionGroup"
                                    attrs:_attrs ns:_ns];

    if (self->minOccurs == nil) ASSIGN(self->minOccurs, @"1");
    if (self->maxOccurs == nil) ASSIGN(self->maxOccurs, @"1");

    if ([self->minOccurs intValue] == 0)
      ASSIGN(self->maxOccurs, @"0");
    if ([self->maxOccurs intValue] == 0)
      ASSIGN(self->maxOccurs, @"unbounded");
    
    if ([[_attrs valueForRawName:@"abstract"] isEqualToString:@"true"])
      self->abstract = YES;
    
    if ([[_attrs valueForRawName:@"nillable"] isEqualToString:@"true"])
      self->nillable = YES;

#if 0
    NSAssert1(self->name, @"XmlSchemaElement: no name set (%@)", self);
    NSAssert1((self->ref == nil || self->type == nil),
           @"XmlSchemaElement: either ref AND type has to be  set (%@)", self);
#endif
  }
  return self;
}

/*

Schema Representation Constraint: Element Declaration Representation OK 

In addition to the conditions imposed on <element> element information items by the schema for schemas: all of the following must be true:
1 default and fixed must not both be present. 
2 If the item's parent is not <schema>, then all of the following must be true:
2.1 One of ref or name must be present, but not both. 
2.2 If ref is present, then all of <complexType>, <simpleType>, <key>, <keyref>, <unique>, nillable, default, fixed, form, block and type must be absent, i.e. only minOccurs, maxOccurs, id are allowed in addition to ref, along with <annotation>. 
3 type and either <simpleType> or <complexType> are mutually exclusive. 
4 The corresponding particle and/or element declarations must satisfy the conditions set out in Constraints on Element Declaration Schema Components (§3.3.6) and Constraints on Particle Schema Components (§3.9.6). 
  
finding the type:
if (complexType or simpleType tag) -> found
else if (type-attribute is present) -> found
else if (substitutionGroup-attribute) ->found
else 'ur-type' definition.
*/

- (int)checkConstraints:(XmlSchema *)_schema {
  if (self->defValue && self->fixed)
    return 1; // element: default and fixed attr may not both be present.
  if (![[_schema elementWithName:self->name] isEqual:self]) { //toDo:-isEqual:
    if (self->ref) {
      if ((self->name && self->ref) || (!self->name && !self->ref)) {
        return 2;
        /*
          elememt: One of ref or name must be present, but not both.
          (if items parent is not <schema>
        */
      }
        // not allowed: <complexType>, <simpleType>, <key>, <keyref>, <unique>
      if (self->nillable || self->defValue  || self->fixed    || self->form ||
          self->block    || self->type) {
        return 3;
      }
      if (self->contentType)
        return 4;
    }
  }
  return 0;
}

- (void)prepareWithSchema:(XmlSchema *)_schema {
  XmlSchema *mySchema;

  [super prepareWithSchema:_schema];

  if (self->ref) {
    XmlSchemaElement *elem;
    NSString *val = [self->ref valueFromQName];
    NSString *uri = [self->ref uriFromQName];
    
    if (uri == nil || [uri isEqualToString:[_schema targetNamespace]])
      mySchema = _schema;
    else
      mySchema = [XmlSchema schemaForNamespace:uri];
    
    elem = [mySchema elementWithName:val];

    [self _readFromElement:elem];
  }
  else if (self->contentType != nil) {
    [self->contentType prepareWithSchema:_schema];
  }
  else if (self->type) {
    NSString *val = [self->type valueFromQName];
    NSString *uri = [self->type uriFromQName];

    if (uri == nil || [uri isEqualToString:[_schema targetNamespace]])
      mySchema = _schema;
    else
      mySchema = [XmlSchema schemaForNamespace:uri];

    self->contentType = [mySchema typeWithName:val]; // ToDo: Ref!!!
    RETAIN(self->contentType);
  }
  else if (self->substitutionGroup) {
    // ToDo: content type muss noch gesetzt werden
  }
  else {
    // ToDo: 'ur-type' definition ???
  }
}

- (BOOL)isTagNameAccepted:(NSString *)_tagName {
  if ([super isTagNameAccepted:_tagName])
    return YES;
  else
    return [Valid_element_ContentTags containsObject:_tagName];
}

- (BOOL)addTag:(XmlSchemaTag *)_tag {
  if ([Valid_element_ContentTags containsObject:[_tag tagName]]) {
    [self setContentType:(XmlSchemaType *)_tag];
    return YES;
  }
  
  return [super addTag:_tag];
}

- (NSString *)tagName {
  return @"element";
}

@end /* XmlSchemaElement(XmlSchemaSaxBuilder) */


@implementation XmlSchemaElement(PrivateMethods)

- (void)_readFromElement:(XmlSchemaElement *)_element {
  RELEASE(self->name);
  RELEASE(self->defValue);
  RELEASE(self->type);

  self->name     = [[_element name]    copy];
  self->type     = [[_element type]    copy];
  self->defValue = [[_element default] copy];
  [self setContentType:[_element contentType]];
}

@end
  



