// $Id$

#ifndef __XmlSchema_XmlSchemaContent_H__
#define __XmlSchema_XmlSchemaContent_H__

#import "XmlSchemaTag.h"

/*
  abstract super class of
    XmlSchemaSimpleContent
    XmlSchemaComplexContent
    XmlSchemaSequence
      XmlSchemaAll
      XmlSchemaChoice
    XmlSchemaDerivator
      XmlSchemaList
      XmlSchemaUnion
      XmlSchemaRestriction
*/

@class NSString;
@class XmlSchemaElement;

@interface XmlSchemaContent : XmlSchemaTag
{
  NSString *idValue;
}

- (NSString *)id;

- (NSArray *)elementNames;
- (XmlSchemaElement *)elementWithName:(NSString *)_name;

@end

#endif /* __XmlSchema_XmlSchemaContent_H__ */
