// $Id$

#ifndef __XmlSchema_XmlSchemaInclude_H__
#define __XmlSchema_XmlSchemaInclude_H__

/*
  <include
    id = ID 
    schemaLocation = anyURI
    {any attributes with non-schema namespace . . .}>
    Content: (annotation?)
  </include>
*/

#import "XmlSchemaTag.h"

@class NSString;

@interface XmlSchemaInclude : XmlSchemaTag
{
  NSString *idValue;
  NSString *schemaLocation;
}

- (NSString *)id;
- (NSString *)schemaLocation;

@end

#endif /* __XmlSchema_XmlSchemaInclude_H__ */
