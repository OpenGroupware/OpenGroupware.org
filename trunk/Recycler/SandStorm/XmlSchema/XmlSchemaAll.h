
#ifndef __XmlSchemaAll_H__
#define __XmlSchemaAll_H__

/*
  XmlSchemaAll represents the structure of a Dictionary
  
  <all 
    id = ID 
    maxOccurs = 1 : 1
    minOccurs = (0 | 1) : 1
    {any attributes with non-schema namespace . . .}>
    Content: (annotation?, element*)
  </all>
*/

#import "XmlSchemaContent.h"
@class NSMutableDictionary;

@interface XmlSchemaAll : XmlSchemaContent
{
  // maxOccurs is @"1"
  NSString            *minOccurs;
  NSMutableDictionary *elements;
}

/* attributes */
- (NSString *)maxOccurs;
- (NSString *)minOccurs;

/* elements */
- (NSArray *)elementNames;
- (id)elementWithName:(NSString *)_key;
@end

#endif /* __XmlSchemaAll_H__ */
