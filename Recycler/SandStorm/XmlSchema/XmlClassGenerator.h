

#ifndef __XmlSchema_XmlClassGenerator_H__
#define __XmlSchema_XmlClassGenerator_H__

#import <Foundation/NSObject.h>

@class NSString, NSMutableString;
@class XmlSchema, XmlSchemaType;

@interface XmlClassGenerator : NSObject
{
  XmlSchemaType *type;
  NSString      *className;
  NSString      *prefix;
  NSString      *schemaPath;
  
@private
  NSMutableString  *string;
}

+ (void)generateClassFilesFromSchemaAtPath:(NSString *)_schemaPath
                                bundlePath:(NSString *)_bundlePath
                                    prefix:(NSString *)_prefix;

+ (void)generateClassFilesFromSchema:(XmlSchema *)_schema
                          schemaPath:(NSString *)_schemaPath
                          bundlePath:(NSString *)_path
                              prefix:(NSString *)_prefix;

+ (void)generateClassFilesFromSchema:(XmlSchema *)_schema
                          bundlePath:(NSString *)_path
                              prefix:(NSString *)_prefix;

+ (void)registerClassName:(NSString *)_className forType:(NSString *)_type;
+ (NSString *)classNameForType:(NSString *)_type;

- (id)initWithType:(XmlSchemaType *)_type;

- (void)setType:(XmlSchemaType *)_type;
- (XmlSchemaType *)type;

- (void)setSchemaPath:(NSString *)_schemaPath;
- (NSString *)schemaPath;

- (void)setPrefix:(NSString *)_prefix;
- (NSString *)prefix;

- (NSString *)className;

- (void)generateClassFilesAtPath:(NSString *)_path;
- (void)generateHFileAtPath:(NSString *)_path;
- (void)generateMFileAtPath:(NSString *)_path;

@end

#endif /* __XmlSchema_XmlClassGenerator_H__ */
