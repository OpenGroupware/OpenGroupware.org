
#ifndef __XmlSchema_Type_H__
#define __XmlSchema_Type_H__

#include "XmlSchemaTag.h"

/*
    XmlSchemaType (abstract class)
      XmlSchemaElement
      XmlSchemaSimpleType
      XmlSchemaComplexType
*/

@class NSString;
@class XmlSchemaAttribute, XmlSchemaElement, XmlSchemaContent;

@interface XmlSchemaType : XmlSchemaTag
{
  NSString *final;
  NSString *idValue;
  NSString *name;
}

/* attributes */

- (NSString *)final;
- (NSString *)id; // rename to 'identifier'
- (NSString *)name;

- (NSString *)typeValue;
- (NSString *)nameAsQName;

- (BOOL)isSimpleType;
- (BOOL)isScalar;

- (NSArray *)attributeNames;
- (XmlSchemaAttribute *)attributeWithName:(NSString *)_name;

- (NSArray *)elementNames;
- (XmlSchemaElement *)elementWithName:(NSString *)_name;

- (XmlSchemaContent *)content;

@end


#endif /* __XmlSchema_Type_H__ */
