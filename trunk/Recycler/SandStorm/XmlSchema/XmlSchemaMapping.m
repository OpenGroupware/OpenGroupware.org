
#include "XmlSchemaMapping.h"
#include "XmlSchemaAttribute.h"
#include "XmlSchema.h"
#include "common.h"

@implementation XmlSchemaMapping

+ (NSString *)nameFromElement:(XmlSchemaElement *)_element {
  return [_element name];
}

- (id)initWithSchema:(XmlSchema *)_schema {
  if ((self = [super init])) {
    ASSIGN(self->schema, _schema);
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->schema);
  [super dealloc];
}
#endif

- (void)setSchema:(XmlSchema *)_schema {
  ASSIGN(self->schema, _schema);
}
- (XmlSchema *)schema {
  return self->schema;
}

- (Class)classForType:(XmlSchemaType *)_type {
  return [self subclassResponsibility:_cmd];
}

- (NSString *)nameFromElement:(XmlSchemaElement *)_element {
  return [[self class] nameFromElement:_element];
}

- (XmlSchemaType *)typeFromType:(XmlSchemaType *)_type name:(NSString *)_name {
  return [self subclassResponsibility:_cmd];
}

/* callback API for coder */

- (id)valueForElement:(XmlSchemaElement *)_element
  inObject:(id)_object
{
  return [self subclassResponsibility:_cmd];
}

- (id)valueForOptionalElement:(XmlSchemaElement *)_element
  inObject:(id)_object
{
  return [self subclassResponsibility:_cmd];
}

- (NSString *)valueForAttribute:(XmlSchemaAttribute *)_attribute
  inObject:(id)_object
{
  return [self subclassResponsibility:_cmd];
}

- (NSString *)baseValueOfObject:(id)_object {
  return [self subclassResponsibility:_cmd];
}

- (id)objectWithBaseValue:(NSString *)_baseValue
  type:(XmlSchemaType *)_type
  object:(id)_object
{
  return [self subclassResponsibility:_cmd];  
}

- (void)takeValue:(id)_value
  forElement:(XmlSchemaElement *)_element
  inObject:(id)_object
{
  [self subclassResponsibility:_cmd];  
}

- (void)takeValue:(id)_value
  forAttribute:(XmlSchemaAttribute *)_attribute
  inObject:(id)_object
{
  [self subclassResponsibility:_cmd];  
}

@end /* XmlSchemaMapping */
