
#ifndef __XmlSchema_XmlSchemaImport_H__
#define __XmlSchema_XmlSchemaImport_H__

/*
  <import 
    id = ID 
    namespace = anyURI 
    schemaLocation = anyURI 
    {any attributes with non-schema namespace . . .}>
    Content: (annotation?)
  </import>
*/

#import "XmlSchemaTag.h"

@class NSString;

@interface XmlSchemaImport : XmlSchemaTag
{
  NSString *idValue;
  NSString *namespace;
  NSString *schemaLocation;
}

- (NSString *)id;
- (NSString *)namespace;
- (NSString *)schemaLocation;

@end

#endif /* __XmlSchema_XmlSchemaImport_H__ */
