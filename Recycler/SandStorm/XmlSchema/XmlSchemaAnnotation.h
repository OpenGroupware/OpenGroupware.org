
#ifndef __XmlSchema_XmlSchemaAnnotation_H__
#define __XmlSchema_XmlSchemaAnnotation_H__

/*
  <annotation    
     id = ID 
     {any attributes with non-schema namespace . . .}>
    Content: (appinfo | documentation)*
  </annotation>
*/

#import "XmlSchemaTag.h"

@class NSString, NSMutableArray;

@interface XmlSchemaAnnotation : XmlSchemaTag
{
  NSString       *idValue;

  NSMutableArray *appinfos;
  NSMutableArray *documentations;
}

/* attributes */
- (NSString *)id;

/* content */

- (NSArray *)appinfos;
- (NSArray *)documentations;

@end /* XmlSchemaAnnotation */

#endif /* __XmlSchema_XmlSchemaAnnotation_H__ */
