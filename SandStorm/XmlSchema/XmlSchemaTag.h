// $Id$

#ifndef __XmlSchema_XmlSchemaTag_H__
#define __XmlSchema_XmlSchemaTag_H__

#import <Foundation/NSObject.h>
#include <SaxObjC/SaxAttributes.h>

@class NSString, NSDictionary, NSMutableString, NSMutableDictionary;
@class XmlSchema, XmlSchemaType;

@interface XmlSchemaTag : NSObject
{
  NSMutableArray      *annotations;
  NSMutableDictionary *extraAttributes;
  XmlSchema           *schema; // non retained

  BOOL                didPrepare;
}
/* attributes */

- (NSArray *)extraAttributeNames;
- (NSString *)extraAttributeWithName:(NSString *)_name;

- (XmlSchema *)schema;

/* content */
- (NSArray *)annotations;
@end

@interface XmlSchemaTag(XmlSchemaSaxBuilder)
- (id)initWithAttributes:(id)_attrs
  namespace:(NSString *)_namespace
  namespaces:(NSDictionary *)_namespaces;
- (void)prepareWithSchema:(XmlSchema *)_schema;
- (NSString *)tagName;
- (BOOL)isTagAccepted:(XmlSchemaTag *)_tag;
- (BOOL)isTagNameAccepted:(NSString *)_tagName;
- (BOOL)addTag:(XmlSchemaTag *)_tag;
@end /* XmlSchemaTag(XmlSchemaSaxBuilder) */

@interface XmlSchemaTag(XmlSchemaSaxBuilder_PrivateMethods)
- (BOOL)_shouldPrepare;
- (BOOL)_insertTag:(XmlSchemaType *)_tag
          intoDict:(NSMutableDictionary *)_dict
         restArray:(NSMutableArray *)_rest;
- (BOOL)_insertTag:(XmlSchemaType *)_tag
          intoDict:(NSMutableDictionary *)_dict;
- (NSString *)copy:(NSString *)_key
             attrs:(id<SaxAttributes>)_attrs
                ns:(NSDictionary *)_ns;
- (void)append:(NSString *)_value
          attr:(NSString *)_attrName
      toString:(NSMutableString *)_str;
- (void)_prepareTags:(id)_tags withSchema:(XmlSchema *)_schema;

@end /* XmlSchemaTag(XmlSchemaSaxBuilder_PrivateMethods) */

#endif /* __XmlSchema_XmlSchemaTag_H__ */
