// $Id$

#ifndef __XmlSchema_SimpleType_H__
#define __XmlSchema_SimpleType_H__

/*
  <simpleType 
    final = (#all | (list | union | restriction)) 
    id = ID 
    name = NCName 
    {any attributes with non-schema namespace . . .}>
    Content: (annotation?, (restriction | list | union))
  </simpleType>
*/

#include "XmlSchemaType.h"

@class XmlSchemaDerivator;

@interface XmlSchemaSimpleType : XmlSchemaType
{
  XmlSchemaDerivator *derivator;
}

/* attributes */

/* accessors */
- (void)setDerivator:(XmlSchemaDerivator *)_derivator;
- (XmlSchemaDerivator *)derivator;

@end

#endif /* __XmlSchema_SimpleType_H__ */
