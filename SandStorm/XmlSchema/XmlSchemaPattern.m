// $Id$

#include "XmlSchemaPattern.h"
#include "common.h"

@implementation XmlSchemaPattern
@end /* XmlSchemaPattern */

@implementation XmlSchemaPattern(XmlSchemaSaxBuilder)
- (NSString *)tagName {
  return @"pattern";
}
@end
