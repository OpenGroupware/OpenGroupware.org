// $Id$

#ifndef __XmlSchema_XmlSchemaSaxBuilder_H__
#define __XmlSchema_XmlSchemaSaxBuilder_H__

#import <Foundation/NSObject.h>
#include <SaxObjC/SaxDefaultHandler.h>

@class NSString, NSData, NSMutableArray, NSMutableDictionary;
@class XmlSchema;

@interface XmlSchemaSaxBuilder : SaxDefaultHandler
{
  XmlSchema           *schema;
  NSMutableArray      *valueStack;
  NSMutableDictionary *namespaces; // namespacePrefix -> namespaceUri

  unsigned tagDepth;
  unsigned invalidTagDepth;
}


- (void)setNamespaces:(NSMutableDictionary *)_namespaces;

+ (XmlSchema *)parseSchemaFromContentsOfFile:(NSString *)_path;
+ (XmlSchema *)parseSchemaFromData:(NSData *)_data;

/* result access */

- (XmlSchema *)schema;

@end

#endif /* __XmlSchema_XmlSchemaSaxBuilder_H__ */
