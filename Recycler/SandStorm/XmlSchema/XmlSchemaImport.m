
#include "XmlSchemaImport.h"
#include "common.h"

@implementation XmlSchemaImport

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->idValue);
  RELEASE(self->namespace);
  RELEASE(self->schemaLocation);
  [super dealloc];
}
#endif

/* attributes */

- (NSString *)id {
  return self->idValue;
}
- (NSString *)namespace {
  return self->namespace;
}
- (NSString *)schemaLocation {
  return self->schemaLocation;
}

@end /* XmlSchemaImport */

@implementation XmlSchemaImport(XmlSchemaSaxBuilder)

- (id)initWithAttributes:(id<SaxAttributes>)_attrs
                 namespace:(NSString *)_namespace
              namespaces:(NSDictionary *)_ns {
  if ((self = [super initWithAttributes:_attrs
                     namespace:_namespace
                     namespaces:_ns])) {
    self->idValue        = [[_attrs valueForRawName:@"id"]             copy];
    self->namespace      = [[_attrs valueForRawName:@"namespace"]      copy];
    self->schemaLocation = [[_attrs valueForRawName:@"schemaLocation"] copy];
  }
  return self;
}

- (NSString *)tagName {
  return @"import";
}

- (void)prepareWithSchema:(XmlSchema *)_schema {
  
}

@end /* XmlSchemaImport(XmlSchemaSaxBuilder) */
