// $Id$

#ifndef __XmlSchema_ComplexType_H__
#define __XmlSchema_ComplexType_H__

/*
  <complexType 
    abstract = boolean : false
    block = (#all | List of (extension | restriction)) 
    final = (#all | List of (extension | restriction)) 
    id = ID 
    mixed = boolean : false
    name = NCName 
    {any attributes with non-schema namespace . . .}>
    Content: (annotation?, (simpleContent | complexContent | ((group | all | choice | sequence)?, ((attribute | attributeGroup)*, anyAttribute?))))
  </complexType>
*/

#include "XmlSchemaType.h"

@class NSString, NSMutableDictionary;
@class XmlSchemaContent, XmlSchemaAttributeGroup;

@interface XmlSchemaComplexType : XmlSchemaType
{
  /* attributes */
  NSString       *abstract;
  NSString       *block;
  BOOL           mixed;

  /* content */
  XmlSchemaContent    *content;
  NSMutableDictionary *attributes;
  NSMutableArray      *attributeGroups;
}

/* attributes */

- (NSString *)abstract;
- (NSString *)block;
- (BOOL)mixed;

@end

#endif /* __XmlSchema_ComplexType_H__ */
