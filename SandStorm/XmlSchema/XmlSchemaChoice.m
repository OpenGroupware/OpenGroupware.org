// $Id$

#include "XmlSchemaChoice.h"
#include "common.h"

@implementation XmlSchemaChoice
@end /* XmlSchemaChoice */

@implementation XmlSchemaChoice(XmlSchemaSaxBuilder)
- (NSString *)tagName {
  return @"choice";
}
@end /* XmlSchemaChoice(XmlSchemaSaxBuilder) */
