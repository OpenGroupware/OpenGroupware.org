
#ifndef __XmlSchema_XmlSchemaGroup_H__
#define __XmlSchema_XmlSchemaGroup_H__

/*

  <xs:group
     maxOccurs = (nonNegativeInteger | unbounded)  : 1
     minOccurs = nonNegativeInteger : 1
     name      = xs:NCName 
     ref       = qname> 
    Content: (xs:annotation?, ( xs:all | xs:choice | xs:sequence )) 
  </xs:group>   
*/

#import "XmlSchemaTag.h"

@class NSString;
@class XmlSchemaContent, XmlSchemaElement;

@interface XmlSchemaGroup : XmlSchemaTag
{
  NSString *name;
  NSString *maxOccurs;
  NSString *minOccurs;
  NSString *ref;

  XmlSchemaContent *content;
}

/* attributes */

- (NSString *)name;
- (NSString *)ref;
- (NSString *)maxOccurs;
- (NSString *)minOccurs;

- (XmlSchemaContent *)content;

- (NSArray *)elementNames;
- (XmlSchemaElement *)elementWithName:(NSString *)_name;

@end

#endif /* __XmlSchema_XmlSchemaGroup_H__ */
