// $Id$

#ifndef __XmlSchema_Union_H__
#define __XmlSchema_Union_H__

#import "XmlSchemaDerivator.h"

@class NSString;

@interface XmlSchemaUnion : XmlSchemaDerivator
{
  NSString *memberTypes;
}

/* attributes */

- (NSString *)memberTypes;

@end

#endif /* __XmlSchema_Union_H__ */
