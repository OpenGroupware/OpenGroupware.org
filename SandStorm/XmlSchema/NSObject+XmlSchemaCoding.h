// $Id$

#ifndef __XmlSchema_NSObject_XmlSchemaCoding_H__
#define __XmlSchema_NSObject_XmlSchemaCoding_H__

#import <Foundation/Foundation.h>

@class NSString;
@class XmlSchema, XmlSchemaElement, XmlSchemaType, XmlSchemaAttribute;
@class XmlSchemaMapping;

@interface NSObject(XmlSchemaMappingCoding)

/* XML encoding */

- (id)valueForElement:(XmlSchemaElement *)_element
  mapping:(XmlSchemaMapping *)_mapping;

- (id)valueForOptionalElement:(XmlSchemaElement *)_element
  mapping:(XmlSchemaMapping *)_mapping;

- (NSString *)valueForAttribute:(XmlSchemaAttribute *)_attribute
  mapping:(XmlSchemaMapping *)_mapping;

- (NSString *)baseValueWithMapping:(XmlSchemaMapping *)_mapping;

/* XML decoding */

- (id)initWithBaseValue:(NSString *)_baseValue
  type:(XmlSchemaType *)_type
  mapping:(XmlSchemaMapping *)_mapping;

- (void)takeValue:(id)_value
  forElement:(XmlSchemaElement *)_element
  mapping:(XmlSchemaMapping *)_mapping;

- (void)takeValue:(id)_value
  forAttribute:(XmlSchemaAttribute *)_attribute
  mapping:(XmlSchemaMapping *)_mapping;

@end /* NSObject(XmlSchemaCodingMapping) */

#endif /* __XmlSchema_NSObject_XmlSchemaCoding_H__ */
