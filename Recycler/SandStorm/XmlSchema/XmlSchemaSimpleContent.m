// $Id$

#include "XmlSchemaSimpleContent.h"
#include "common.h"

@implementation XmlSchemaSimpleContent
@end /* XmlSchemaSimpleContent */

@implementation XmlSchemaSimpleContent(XmlSchemaSaxBuilder)

- (BOOL)isSimpleType {
  return YES;
}

- (NSArray *)elementNames {
  return [NSArray array];
}
- (XmlSchemaElement *)elementWithName:(NSString *)_name {
  return nil;
}

- (NSString *)tagName {
  return @"simpleContent";
}

@end /* XmlSchemaSimpleContent(XmlSchemaSaxBuilder) */
