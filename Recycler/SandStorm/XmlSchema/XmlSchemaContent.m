// $Id$

#include "XmlSchemaContent.h"
#include "XmlSchemaElement.h"
#include "common.h"

@implementation XmlSchemaContent

- (void)dealloc {
  RELEASE(self->idValue);
  [super dealloc];
}

/* attributes */

- (NSString *)id {
  return self->idValue;
}

- (NSArray *)elementNames {
  [self subclassResponsibility:_cmd];
  return nil;
}
- (XmlSchemaElement *)elementWithName:(NSString *)_name {
  [self subclassResponsibility:_cmd];
  return nil;
}

@end /* XmlSchemaContent */

@implementation XmlSchemaContent(XmlSchemaSaxBuilder)

- (id)initWithAttributes:(id<SaxAttributes>)_attrs
  namespace:(NSString *)_namespace
  namespaces:(NSDictionary *)_ns
{
  if ((self = [super initWithAttributes:_attrs
                     namespace:_namespace
                     namespaces:_ns])) {
    self->idValue = [[_attrs valueForRawName:@"id"] copy];
  }
  return self;
}

@end /* XmlSchemaContent(XmlSchemaSaxBuilder) */
