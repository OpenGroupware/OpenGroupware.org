// $Id$

#ifndef __XmlSchema_XmlSchemaSimpleContent_H__
#define __XmlSchema_XmlSchemaSimpleContent_H__

#import "XmlSchemaContent.h"

/*
  <simpleContent 
    id = ID 
    {any attributes with non-schema namespace . . .}>
    Content: (annotation?, (restriction | extension))
  </simpleContent>
*/

@class NSString;

@interface XmlSchemaSimpleContent : XmlSchemaContent
@end

#endif /* __XmlSchema_XmlSchemaSimpleContent_H__ */
