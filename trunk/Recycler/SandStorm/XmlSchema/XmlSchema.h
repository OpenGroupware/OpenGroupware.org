
#ifndef __XmlSchema_XmlSchema_H__
#define __XmlSchema_XmlSchema_H__

#include "XmlSchemaTag.h"
#include "XmlSchemaAll.h"
#include "XmlSchemaAttribute.h"
#include "XmlSchemaSequence.h"
#include "XmlSchemaElement.h"
#include "XmlSchemaChoice.h"
#include "XmlSchemaCoder.h"
#include "XmlSchemaGroup.h"
#include "XmlSchemaAttributeGroup.h"
#include "NSString+XML.h"

#include "XmlClassGenerator.h"
#include "XmlSchemaMapping.h"
#include "XmlDefaultClassSchemaMapping.h"

/* done:
   all: 2.7 
   attribute: 2.2 
   attributeGroup: 2.8 
   choice: 2.7
   complexContent: 2.5.3
   complexType: 2.2
   element: 2.2
   group: 2.7
   import: 5.4
   include: 4.1
   list: 2.3.1 
   restriction: 2.3, 4.4 
   schema: 2.1
   sequence: 2.7
   simpleContent: 2.5.1 
   simpleType: 2.3 
   union: 2.3.2 
*/

/* not implemented:
   annotation: 2.6
   any: 5.5
   anyAttribute: 5.5
   appInfo: 2.6
   documentation: 2.6
   enumeration: 2.3
   extension: 2.5.1, 4.2
   field: 5.1
   key: 5.2
   keyref: 5.2
   length: 2.3.1 
   maxInclusive: 2.3 
   maxLength: 2.3.1 
   minInclusive: 2.3 
   minLength: 2.3.1 
   pattern: 2.3 
   redefine: 4.5 
   selector: 5.1 
   unique: 5.1 
*/

@class NSDictionary, NSMutableDictionary;
@class XmlSchemaType;

/*
  <schema 
    attributeFormDefault = (qualified | unqualified) : unqualified
    blockDefault = (#all | List of (extension | restriction | substitution))  : ''
    elementFormDefault = (qualified | unqualified) : unqualified
    finalDefault = (#all | List of (extension | restriction))  : ''
    id = ID 
    targetNamespace = anyURI 
    version = token 
    xml:lang = language 
    {any attributes with non-schema namespace . . .}>
    Content: ((include | import | redefine | annotation)*, (((simpleType | complexType | group | attributeGroup) | element | attribute | notation), annotation*)*)
  </schema>
*/

@interface XmlSchema : XmlSchemaTag
{
  NSString *targetNamespace;
  NSString *blockDefault;
  NSString *finalDefault;
  NSString *idValue;
  NSString *version;
  NSString *elementFormDefault;
  NSString *attributeFormDefault;
  
  NSMutableDictionary *attributes;
  NSMutableDictionary *elements;
  NSMutableDictionary *groups;
  NSMutableDictionary *attributeGroups;
  NSMutableDictionary *types;
  NSMutableArray      *includes;
  NSMutableArray      *imports;

  NSString            *schemaLocation;
}

+ (XmlSchema *)schemaForNamespace:(NSString *)_namespace;
+ (BOOL)hasSchemaForNamespace:(NSString *)_namespace;
+ (void)registerSchemaAtPath:(NSString *)_path;
+ (XmlSchemaElement *)elementWithQName:(NSString *)_qName;
+ (XmlSchemaType *)typeWithQName:(NSString *)_qName;
+ (BOOL)isXmlSchemaNamespace:(NSString *)_namespace;
- (void)registerSchemaForNamespace:(NSString *)_namespace;
- (void)registerSchema;

- (id)initWithContentsOfFile:(NSString *)_file prepare:(BOOL)_prepare;
- (id)initWithContentsOfFile:(NSString *)_path;

/* attributes */

- (NSString *)targetNamespace;
- (NSString *)blockDefault;
- (NSString *)finalDefault;
- (NSString *)id;
- (NSString *)version;
- (NSString *)elementFormDefault;
- (NSString *)attributeFormDefault;

/* elements */

- (NSArray *)elementNames;
- (XmlSchemaElement *)elementWithName:(NSString *)_key;

/* attributes */

- (NSArray *)attributeNames;
- (XmlSchemaAttribute *)attributeWithName:(NSString *)_key;

/* groups */

- (NSArray *)groupNames;
- (XmlSchemaGroup *)groupWithName:(NSString *)_key;

/* groups */

- (NSArray *)attributeGroupNames;
- (XmlSchemaAttributeGroup *)attributeGroupWithName:(NSString *)_key;

/* types */
- (NSArray *)typeNames;
- (XmlSchemaType *)typeWithName:(NSString *)_key;

@end

@interface XmlSchema(AdditionalApi)
- (void)setSchemaLocation:(NSString *)_schemaLocation;
- (NSString *)schemaLocation;
@end

@interface XmlSchema(XmlSchemaSaxBuilder)
- (void)prepareSchema;
@end /* XmlSchema(XmlSchemaSaxBuilder) */

#endif /* __XmlSchema_XmlSchema_H__ */
