
#ifndef __XmlSchema_XmlSchemaRedefine_H__
#define __XmlSchema_XmlSchemaRedefine_H__

/*
  <redefine 
    id = ID 
    schemaLocation = anyURI 
    {any attributes with non-schema namespace . . .}>
    Content:(annotation | (simpleType | complexType | group | attributeGroup))*
 </redefine>
*/

#import "XmlSchemaTag.h"

@class NSString;

@interface XmlSchemaRedefine : XmlSchemaTag
{
  NSString *idValue;
  NSString *schemaLocation;
}

- (NSString *)id;
- (NSString *)schemaLocation;

@end

#endif /* __XmlSchema_XmlSchemaRedefine_H__ */
