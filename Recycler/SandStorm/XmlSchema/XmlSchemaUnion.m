// $Id$

#include "XmlSchemaUnion.h"
#include "common.h"

@implementation XmlSchemaUnion

- (void)dealloc {
  RELEASE(self->memberTypes);
  [super dealloc];
}

/* attributes */

- (NSString *)memberTypes {
  return self->memberTypes;
}

@end /* XmlSchemaUnion */

@implementation XmlSchemaUnion(XmlSchemaSaxBuilder)

- (id)initWithAttributes:(id<SaxAttributes>)_attrs
               namespace:(NSString *)_namespace
              namespaces:(NSDictionary *)_ns {
  if ((self = [super initWithAttributes:_attrs
                     namespace:_namespace
                     namespaces:_ns])) {
    self->memberTypes = [self copy:@"memberTypes" attrs:_attrs ns:_ns];
  }
  return self;
}

- (NSString *)tagName {
  return @"union";
}

@end /* XmlSchemaUnion(XmlSchemaSaxBuilder) */
