
#include "XmlSchemaSimpleType.h"
#include "XmlSchemaDerivator.h"
#include "common.h"

@implementation XmlSchemaSimpleType

- (void)dealloc {
  RELEASE(self->derivator);
  
  [super dealloc];
}
/* attributes */

/* accessors */

- (void)setDerivator:(XmlSchemaDerivator *)_derivator {
  ASSIGN(self->derivator, _derivator);
}
- (XmlSchemaDerivator *)derivator {
  return self->derivator;
}

- (BOOL)isSimpleType {
  return YES;
}

- (BOOL)isScalar {
  return YES;
}

- (NSArray *)elementNames {
  return [NSArray array];
}
- (XmlSchemaElement *)elementWithName:(NSString *)_name {
  return nil;
}

- (NSArray *)attributeNames {
  return [NSArray array];
}
- (XmlSchemaAttribute *)attributeWithName:(NSString *)_name {
  return nil;
}

- (XmlSchemaContent *)content {
  return nil;
}

@end /* XmlSchemaSimpleType */

@implementation XmlSchemaSimpleType(XmlSchemaSaxBuilder)

static NSSet *Valid_simpleType_ContentTags = nil;

+ (void)initialize {
  if (Valid_simpleType_ContentTags == nil) {
    Valid_simpleType_ContentTags = [[NSSet alloc] initWithObjects:
                                                  @"restriction",
                                                  @"union",
                                                  @"list",
                                                  nil];
  }
}


- (BOOL)isTagNameAccepted:(NSString *)_tagName {
  if ([super isTagNameAccepted:_tagName])
    return YES;
  else
    return [Valid_simpleType_ContentTags containsObject:_tagName];
}

- (NSString *)tagName {
  return @"simpleType";
}

- (BOOL)addTag:(XmlSchemaTag *)_tag {
  if ([Valid_simpleType_ContentTags containsObject:[_tag tagName]]) {
    ASSIGN(self->derivator, _tag);
    return YES;
  }
  return [super addTag:_tag];
}

@end /* XmlSchemaSimpleType(XmlSchemaSaxBuilder) */
