
#ifndef __XmlSchema_XmlSchemaAttribute_H__
#define __XmlSchema_XmlSchemaAttribute_H__

/*
  <attribute 
    default = string 
    fixed = string 
    form = (qualified | unqualified)
    id = ID 
    name = NCName 
    ref = QName 
    type = QName 
    use = (optional | prohibited | required) : optional
    {any attributes with non-schema namespace . . .}>
    Content: (annotation?, (simpleType?))
  </attribute>
*/



#import "XmlSchemaTag.h"

@class NSString;

@interface XmlSchemaAttribute : XmlSchemaTag
{
  NSString *defValue;
  NSString *fixed;
  NSString *form; // (qualified | unqualified)
  NSString *idValue;
  NSString *name;
  NSString *ref;
  NSString *type;
  NSString *use;  // (optional | prohibited | required) : optional

  NSString *typeNamespace;
}

/* attributes */
- (NSString *)default;
- (NSString *)fixed;
- (NSString *)form;
- (NSString *)id;
- (NSString *)name;
- (NSString *)ref;
- (NSString *)type;
- (NSString *)use;

@end /* XmlSchemaAttribute */

#endif /* __XmlSchema_XmlSchemaAttribute_H__ */
