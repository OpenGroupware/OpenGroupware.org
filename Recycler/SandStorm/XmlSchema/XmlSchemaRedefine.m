// $Id$

#include "XmlSchemaRedefine.h"
#include "common.h"

@implementation XmlSchemaRedefine

- (void)dealloc {
  RELEASE(self->idValue);
  RELEASE(self->schemaLocation);
  [super dealloc];
}

/* attributes */

- (NSString *)id {
  return self->idValue;
}
- (NSString *)schemaLocation {
  return self->schemaLocation;
}

@end /* XmlSchemaRedefine */

@implementation XmlSchemaRedefine(XmlSchemaSaxBuilder)

- (id)initWithAttributes:(id<SaxAttributes>)_attrs
               namespace:(NSString *)_namespace
              namespaces:(NSDictionary *)_ns {
  if ((self = [super initWithAttributes:_attrs
                     namespace:_namespace
                     namespaces:_ns])) {
    self->idValue        = [[_attrs valueForRawName:@"id"]             copy];
    self->schemaLocation = [[_attrs valueForRawName:@"schemaLocation"] copy];
  }
  return self;
}

- (NSString *)tagName {
  return @"redefine";
}

@end /* XmlSchemaRedefine(XmlSchemaSaxBuilder) */
