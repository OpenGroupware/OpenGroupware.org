
#ifndef __XmlSchema_XmlSchemaDocumentation_H__
#define __XmlSchema_XmlSchemaDocumentation_H__

/*
  <xs:documentation    
     source = xs:anyURI 
     xml:lang = xml:lang> 
    Content: ({any})* 
  </xs:documentation>   
*/

#import "XmlSchemaTag.h"

@class NSString;

@interface XmlSchemaDocumentation : XmlSchemaTag
{
  NSString *source;
}

/* attributes */
- (NSString *)source;

@end /* XmlSchemaDocumentation */

#endif /* __XmlSchema_XmlSchemaDocumentation_H__ */
