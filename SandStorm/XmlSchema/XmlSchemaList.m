// $Id$

#include "XmlSchemaList.h"
#include "common.h"

@implementation XmlSchemaList

- (void)dealloc {
  RELEASE(self->itemType);
  [super dealloc];
}

/* attributes */

- (NSString *)itemType {
  return self->itemType;
}

@end /* XmlSchemaList */

@implementation XmlSchemaList(XmlSchemaSaxBuilder)
- (id)initWithAttributes:(id<SaxAttributes>)_attrs
               namespace:(NSString *)_namespace
              namespaces:(NSDictionary *)_ns {
  if ((self = [super initWithAttributes:_attrs
                     namespace:_namespace
                     namespaces:_ns])) {
    self->itemType = [self copy:@"itemType" attrs:_attrs ns:_ns];
  }
  return self;
}

- (NSString *)tagName {
  return @"list";
}
@end /* XmlSchemaList(XmlSchemaSaxBuilder) */
