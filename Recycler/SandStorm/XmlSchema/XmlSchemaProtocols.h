// $Id$


#ifndef __XmlSchema_XmlSchemaSchemaProtocols_H__
#define __XmlSchema_XmlSchemaSchemaProtocols_H__

#include <objc/objc.h>

@class NSString, NSArray;
@class XmlSchemaElement, XmlSchemaAttribute;

@protocol XmlSchemaContent

- (NSArray *)elementNames;
- (XmlSchemaElement *)elementWithName:(NSString *)_name;

- (BOOL)isSimpleType;

@end /* XmlSchemaContent */

@protocol XmlSchemaType <XmlSchemaContent>

- (NSString *)name;

- (NSArray *)attributeNames;
- (XmlSchemaAttribute *)attributeWithName:(NSString *)_name;

@end /* XmlSchemaType */

#endif /* __XmlSchema_XmlSchemaSchemaProtocols_H__ */
