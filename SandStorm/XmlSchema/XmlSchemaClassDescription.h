// $Id$

#ifndef __XmlSchema_XmlSchemaClassDescription_H__
#define __XmlSchema_XmlSchemaClassDescription_H__

#import <Foundation/NSClassDescription.h>

@class XmlSchemaType, XmlSchemaMapping;

@interface XmlSchemaClassDescription : NSClassDescription
{
  XmlSchemaMapping *mapping;
  XmlSchemaType    *type;

  NSArray *attributeKeys;
  NSArray *toOneRelationshipKeys;
  NSArray *toManyRelationshipKeys;
}

- (id)initWithMapping:(XmlSchemaMapping *)_mapping type:(XmlSchemaType *)_type;

@end

#endif /* __XmlSchema_XmlSchemaClassDescription_H__ */

