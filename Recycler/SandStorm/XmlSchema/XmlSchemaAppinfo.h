
#ifndef __XmlSchema_XmlSchemaAppinfo_H__
#define __XmlSchema_XmlSchemaAppinfo_H__

/*
  
  <annotation    
     id = xs:ID 
     {any attributes with non-schema namespace}>
    Content: (xs:appinfo | xs:documentation)*
  </annotation>
*/

#import "XmlSchemaTag.h"

@class NSString, NSMutableArray;

@interface XmlSchemaAppinfo : XmlSchemaTag
{
  NSString *source;
}

/* attributes */
- (NSString *)source;

@end /* XmlSchemaAppinfo */

#endif /* __XmlSchema_XmlSchemaAppinfo_H__ */
