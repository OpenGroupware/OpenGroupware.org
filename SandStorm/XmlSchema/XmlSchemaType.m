// $Id$

#include "XmlSchemaType.h"
#include "XmlSchemaContent.h"
#include "XmlSchema.h"
#include "common.h"

@implementation XmlSchemaType

- (void)dealloc {
  RELEASE(self->final);
  RELEASE(self->idValue);
  RELEASE(self->name);
  [super dealloc];
}

- (NSString *)final {
  return self->final;
}
- (NSString *)id {
  return self->idValue;
}

- (NSString *)name {
  return self->name;
}

- (NSString *)typeValue {
  return [self name];
}

- (NSString *)nameAsQName {
  return [NSString qNameWithUri:[[self schema] targetNamespace]
                   andValue:[self name]];
}

- (BOOL)isSimpleType {
  [self subclassResponsibility:_cmd];
  return YES;
}

- (BOOL)isScalar {
  [self subclassResponsibility:_cmd];
  return YES;
}

- (NSArray *)elementNames {
  return [self subclassResponsibility:_cmd];
}
- (XmlSchemaElement *)elementWithName:(NSString *)_name {
  return [self subclassResponsibility:_cmd];
}

- (NSArray *)attributeNames {
  return [self subclassResponsibility:_cmd];
}
- (XmlSchemaAttribute *)attributeWithName:(NSString *)_name {
  return [self subclassResponsibility:_cmd];
}

- (XmlSchemaContent *)content {
  return [self subclassResponsibility:_cmd];
}

@end /* XmlSchemaType */

@implementation XmlSchemaType(XmlSchemaSaxBuilder)

- (id)initWithAttributes:(id<SaxAttributes>)_attrs
               namespace:(NSString *)_namespace
              namespaces:(NSDictionary *)_ns {
  if ((self = [super initWithAttributes:_attrs
                     namespace:_namespace
                     namespaces:_ns])) {
    self->final   = [[_attrs valueForRawName:@"final"] copy];
    self->idValue = [[_attrs valueForRawName:@"id"]    copy];
    self->name    = [[_attrs valueForRawName:@"name"]  copy];
  }
  return self;
}

@end /* XmlSchemaType(XmlSchemaSaxBuilder) */
