
#ifndef __XmlSchema_XmlSchemaAttributeGroup_H__
#define __XmlSchema_XmlSchemaAttributeGroup_H__

/*
  <attributeGroup 
    id   = ID 
    ref  = QName 
    name = NCName 
    {any attributes with non-schema namespace . . .}>
    Content: (annotation?, ((attribute | attributeGroup)*, anyAttribute?))
  </attributeGroup>
*/

#import "XmlSchemaTag.h"

@class NSString;
@class XmlSchemaAttribute;

@interface XmlSchemaAttributeGroup : XmlSchemaTag
{
  NSString *idValue;
  NSString *ref;
  NSString *name;

  NSMutableDictionary *attributes;
  NSMutableArray      *children;
}

/* attributes */

- (NSString *)id;
- (NSString *)ref;
- (NSString *)name;

- (NSArray *)attributeNames;
- (XmlSchemaAttribute *)attributeWithName:(NSString *)_name;

@end

#endif /* __XmlSchema_XmlSchemaAttributeGroup_H__ */
