
#ifndef __XmlSchema_XmlSchemaElement_H__
#define __XmlSchema_XmlSchemaElement_H__

/*
  <element 
    abstract = boolean : false
    block = (#all | List of (extension | restriction | substitution)) 
    default = string 
    final = (#all | List of (extension | restriction)) 
    fixed = string 
    form = (qualified | unqualified)
    id = ID 
    maxOccurs = (nonNegativeInteger | unbounded)  : 1
    minOccurs = nonNegativeInteger : 1
    name = NCName 
    nillable = boolean : false
    ref = QName 
    substitutionGroup = QName 
    type = QName 
    {any attributes with non-schema namespace . . .}>
    Content: (annotation?, ((simpleType | complexType)?, (unique | key | keyref)*))
  </element>
*/

/*

The type definition corresponding to the <simpleType> or <complexType>
element information item in the [children], if either is present, otherwise
the type definition ·resolved· to by the ·actual value· of the type [attribute]
, otherwise the {type definition} of the element declaration ·resolved· to by
the ·actual value· of the substitutionGroup [attribute], if present, otherwise
the ·ur-type definition·.


finding the type:
if (complexType or simpleType tag) -> found
else if (type-attribute is present) -> found
else if (substitutionGroup-attribute) ->found
else 'ur-type' definition.

*/

#include "XmlSchemaType.h"

@class NSString;

@interface XmlSchemaElement : XmlSchemaType
{
  /* attributes */
  BOOL        abstract;  // default: NO
  NSString    *block;
  NSString    *defValue;
  NSString    *fixed;
  NSString    *form;

  NSString    *maxOccurs; // default: @"1"
  NSString    *minOccurs; // defautl: @"1"

  BOOL        nillable;   // default: NO
  NSString    *ref;
  NSString    *substitutionGroup;
  NSString    *type;

  /* content */
  XmlSchemaType *contentType;
}

/* attributes */

- (BOOL)abstract;
- (NSString *)block;
- (NSString *)default;
- (NSString *)fixed;
- (NSString *)form;
- (NSString *)maxOccurs;
- (NSString *)minOccurs;
- (BOOL)nillable;
- (NSString *)ref;
- (NSString *)substitutionGroup;
- (NSString *)type;

- (void)setContentType:(XmlSchemaType *)_contentType;
- (XmlSchemaType *)contentType;

@end

#endif /* __XmlSchema_XmlSchemaElement_H__ */
