// $Id$

#ifndef __XmlSchema_Sequence_H__
#define __XmlSchema_Sequence_H__

/*
  <sequence 
    id = ID 
    maxOccurs = (nonNegativeInteger | unbounded)  : 1
    minOccurs = nonNegativeInteger : 1
    {any attributes with non-schema namespace . . .}>
    Content: (annotation?, (element | group | choice | sequence | any)*)
  </sequence>
*/

#import "XmlSchemaContent.h"

@class NSMutableArray, NSString, NSMutableDictionary, XmlSchemaGroup;

@interface XmlSchemaSequence : XmlSchemaContent
{
  NSString            *maxOccurs;
  NSString            *minOccurs;
  NSMutableDictionary *elements;
  NSMutableArray      *elementNames;
  NSMutableArray      *contents;
}

/* attributes */
- (NSString *)maxOccurs;
- (NSString *)minOccurs;

/* content */

/* elements */

- (NSArray *)elementNames;
- (id)elementWithName:(NSString *)_key;

@end

#endif /* __XmlSchema_Sequence_H__ */
