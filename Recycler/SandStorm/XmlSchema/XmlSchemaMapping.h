
#ifndef __XmlSchema_XmlSchemaMapping_H__
#define __XmlSchema_XmlSchemaMapping_H__

#import <Foundation/NSObject.h>

@class XmlSchema, XmlSchemaElement, XmlSchemaType, XmlSchemaAttribute;

@interface XmlSchemaMapping : NSObject
{
  XmlSchema     *schema;
}

- (id)initWithSchema:(XmlSchema *)_schema;

- (void)setSchema:(XmlSchema *)_schema;
- (XmlSchema *)schema;

- (Class)classForType:(XmlSchemaType *)_type;

- (NSString *)nameFromElement:(XmlSchemaElement *)_element;

- (XmlSchemaType *)typeFromType:(XmlSchemaType *)_type name:(NSString *)_name;

/* callback API for coder */

- (id)valueForElement:(XmlSchemaElement *)_element
  inObject:(id)_object;

- (id)valueForOptionalElement:(XmlSchemaElement *)_element
  inObject:(id)_object;

- (NSString *)valueForAttribute:(XmlSchemaAttribute *)_attribute
  inObject:(id)_object;

- (NSString *)baseValueOfObject:(id)_object;

- (id)objectWithBaseValue:(NSString *)_baseValue
  type:(XmlSchemaType *)_type
  object:(id)_object;

- (void)takeValue:(id)_value
  forElement:(XmlSchemaElement *)_element
  inObject:(id)_object;

- (void)takeValue:(id)_value
  forAttribute:(XmlSchemaAttribute *)_attribute
  inObject:(id)_object;

@end /* XmlSchemaMapping */

#endif /* __XmlSchema_XmlSchemaMapping_H__ */
