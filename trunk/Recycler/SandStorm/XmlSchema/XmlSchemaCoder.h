
#ifndef __XmlSchema_XmlSchemaCoder_H__
#define __XmlSchema_XmlSchemaCoder_H__

#import <Foundation/NSObject.h>
#include <SaxObjC/SaxDefaultHandler.h>

@class NSDictionary, NSArray, NSNumber, NSString, NSCalendarDate, NSData;
@class NSMutableArray, NSMutableString, NSMutableDictionary, NSTimeZone;
@class XmlSchemaType, XmlSchemaMapping, XmlSchema;

@interface XmlSchemaEncoder : NSObject
{
  NSMutableString  *string;
  XmlSchemaMapping *mapping;
  NSTimeZone       *timeZone;
  
  NSMutableArray  *objectStack;
  NSMutableArray  *objectHasStructStack;
  NSMutableArray  *typeStack;
  unsigned        depth;
}

- (id)initForWritingWithMutableString:(NSMutableString *)_string;

- (void)setDefaultTimeZone:(NSTimeZone *)_timeZone;
- (NSTimeZone *)defaultTimeZone;

- (void)setString:(NSMutableString *)_string;

- (void)encodeObject:(id)_rootObject
             mapping:(XmlSchemaMapping *)_mapping
            rootType:(XmlSchemaType *)_rootType;

@end /* XmlSchemaEncoder */

@interface XmlSchemaDecoder : SaxDefaultHandler
{
  NSMutableArray      *infoStack;
  NSMutableDictionary *namespaces; // namespacePrefix -> namespaceUri
  NSMutableString     *characters;
  id                  object;
  XmlSchemaMapping    *mapping;
  XmlSchemaType       *rootType;
  
  unsigned tagDepth;
  unsigned invalidTagDepth;
}

- (void)setMapping:(XmlSchemaMapping *)_mapping;
- (XmlSchemaMapping *)mapping;

- (void)setRootType:(XmlSchemaType *)_rootType;
- (XmlSchemaType *)rootType;

- (void)setNamespaces:(NSMutableDictionary *)_namespaces;
- (unsigned)tagDepth;
- (id)object;

+ (id)parseObjectFromContentsOfFile:(NSString *)_path
                            mapping:(XmlSchemaMapping *)_mapping
                           rootType:(XmlSchemaType *)_rootType;
+ (id)parseObjectFromData:(NSData *)_data
                  mapping:(XmlSchemaMapping *)_mapping
                 rootType:(XmlSchemaType *)_rootType;

@end /* XmlSchemaDecoder */


#endif /* __XmlSchema_XmlSchemaCoder_H__ */
