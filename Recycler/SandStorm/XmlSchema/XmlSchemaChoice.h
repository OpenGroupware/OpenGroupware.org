
#ifndef __XmlSchema_Choice_H__
#define __XmlSchema_Choice_H__

/*
  <choice 
    id = ID 
    maxOccurs = (nonNegativeInteger | unbounded)  : 1
    minOccurs = nonNegativeInteger : 1
    {any attributes with non-schema namespace . . .}>
    Content: (annotation?, (element | group | choice | sequence | any)*)
  </choice>
*/

#import "XmlSchemaSequence.h"

@interface XmlSchemaChoice : XmlSchemaSequence
{
}
@end

#endif /* __XmlSchema_Choice_H__ */
