
#ifndef __XmlSchemaRestriction_H__
#define __XmlSchemaRestriction_H__

/*
  <restriction    
     base = xs:QName 
     id = xs:ID 
     {any attributes with non-schema namespace}> 
    Content: ((annotation?), ( simpleType ?,
              (minExclusive | minInclusive | maxExclusive | maxInclusive |
              totalDigits | fractionDigits | length | minLength | maxLength |
              enumeration | whiteSpace | pattern)*)) 
  </restriction>
*/

#import "XmlSchemaDerivator.h"

@class NSString;
@class XmlSchemaAttribute;

@interface XmlSchemaRestriction : XmlSchemaDerivator
{
  NSString *base;

  NSMutableArray *attributes;
}

/* attributes */

- (NSString *)base;

/* content */

- (NSArray *)attributeNames;
- (XmlSchemaAttribute *)attributeWithName:(NSString *)_name;
- (NSArray *)attributes;

@end

#endif /* __XmlSchemaRestriction_H__ */
