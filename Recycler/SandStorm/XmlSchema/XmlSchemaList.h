
#ifndef __XmlSchema_List_H__
#define __XmlSchema_List_H__

#import "XmlSchemaDerivator.h"

/*
  <list 
    id = ID 
    itemType = QName 
    {any attributes with non-schema namespace . . .}>
    Content: (annotation?, (simpleType?))
  </list>
*/

@class NSString;

@interface XmlSchemaList : XmlSchemaDerivator
{
  NSString *itemType;
}

/* attributes */

- (NSString *)itemType;

@end


#endif /* __XmlSchema_List_H__ */
