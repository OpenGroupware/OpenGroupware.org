// $Id$

#include "NSObject+XmlSchemaCoding.h"
#include "XmlSchemaMapping.h"
#include "XmlSchemaType.h"
#include "common.h"

@implementation NSObject(XmlSchemaMappingCoding)

- (id)valueForElement:(XmlSchemaElement *)_element
              mapping:(XmlSchemaMapping *)_mapping
{
  return [_mapping valueForElement:_element inObject:self];
}

- (id)valueForOptionalElement:(XmlSchemaElement *)_element
                      mapping:(XmlSchemaMapping *)_mapping
{
  return [_mapping valueForOptionalElement:_element inObject:self];
}

- (NSString *)valueForAttribute:(XmlSchemaAttribute *)_attribute
                       mapping:(XmlSchemaMapping *)_mapping
{
  return [_mapping valueForAttribute:_attribute inObject:self];
}

- (NSString *)baseValueWithMapping:(XmlSchemaMapping *)_mapping {
  return [_mapping baseValueOfObject:self];
}

/* *** decoding *** */

- (id)initWithBaseValue:(NSString *)_baseValue
                   type:(XmlSchemaType *)_type
                mapping:(XmlSchemaMapping *)_mapping
{
  self = [_mapping objectWithBaseValue:_baseValue
                   type:_type
                   object:self];
  RETAIN(self);
  return self;
}

- (void)takeValue:(id)_value
       forElement:(XmlSchemaElement *)_element
          mapping:(XmlSchemaMapping *)_mapping
{
  [_mapping takeValue:_value forElement:_element inObject:self];
}

- (void)takeValue:(id)_value
     forAttribute:(XmlSchemaAttribute *)_attribute
          mapping:(XmlSchemaMapping *)_mapping
{
  [_mapping takeValue:_value forAttribute:_attribute inObject:self];
}

@end /* NSObject(XmlSchemaCodingMapping) */
