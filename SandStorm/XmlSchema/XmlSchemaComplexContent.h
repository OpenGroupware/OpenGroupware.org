// $Id$

#ifndef __XmlSchema_XmlSchemaComplexContent_H__
#define __XmlSchema_XmlSchemaComplexContent_H__

#import "XmlSchemaContent.h"

/*
  <complexContent 
    id = ID 
    mixed = boolean 
    {any attributes with non-schema namespace . . .}>
    Content: (annotation?, (restriction | extension))
  </complexContent>
*/

@class NSString;
@class XmlSchemaDerivator;

@interface XmlSchemaComplexContent : XmlSchemaContent
{
  BOOL mixed;
  
  XmlSchemaDerivator *derivator;
}

/* attributes */
- (BOOL)mixed;
- (XmlSchemaDerivator *)derivator;

@end

#endif /* __XmlSchema_XmlSchemaComplexContent_H__ */
