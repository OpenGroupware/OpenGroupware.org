// $Id$

#ifndef __XmlSchema_NSObject_XmlSchema_H__
#define __XmlSchema_NSObject_XmlSchema_H__

#import <Foundation/NSObject.h>

@class NSString;
@class XmlSchema, XmlSchemaType, XmlSchemaMapping;

@interface NSObject(XmlSchema)

- (id)initWithContentsOfFile:(NSString *)_file
  mapping:(XmlSchemaMapping *)_mapping
  rootType:(XmlSchemaType *)_rootType;

- (BOOL)writeToFile:(NSString *)_file
  atomically:(BOOL)_atomically
  mapping:(XmlSchemaMapping *)_mapping
  rootType:(XmlSchemaType *)_rootType;

/* convenience methods */

- (id)initWithContentsOfFile:(NSString *)_file;
- (BOOL)writeToFile:(NSString *)_file atomically:(BOOL)_atomically;

@end /* NSObject(XmlSchema) */

#endif /* __XmlSchema_NSObject_XmlSchema_H__ */
