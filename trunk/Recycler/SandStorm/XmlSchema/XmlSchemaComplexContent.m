
#include "XmlSchemaComplexContent.h"
#include "XmlSchemaDerivator.h"
#include "common.h"

@implementation XmlSchemaComplexContent

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->derivator);
  
  [super dealloc];
}
#endif

/* attributes */
- (BOOL)mixed {
  return self->mixed;
}

- (XmlSchemaDerivator *)derivator {
  return self->derivator;
}

- (NSArray *)elementNames {
  return [self->derivator elementNames];
}

- (XmlSchemaElement *)elementWithName:(NSString *)_name {
  return [self->derivator elementWithName:_name];
}

@end /* XmlSchemaComplexContent */

@implementation XmlSchemaComplexContent(XmlSchemaSaxBuilder)

static NSSet *Valid_complexContent_ContentTags = nil;

+ (void)initialize {
  if (Valid_complexContent_ContentTags == nil) {
    Valid_complexContent_ContentTags = [[NSSet alloc] initWithObjects:
                                                      @"restriction",
                                                      @"extension",
                                                      nil];
  }
}

- (id)initWithAttributes:(id<SaxAttributes>)_attrs
               namespace:(NSString *)_namespace
              namespaces:(NSDictionary *)_namespaces {
  if ((self = [super initWithAttributes:_attrs
                     namespace:_namespace
                     namespaces:_namespaces])) {
    if (([[_attrs valueForRawName:@"mixed"] isEqualToString:@"true"]))
      self->mixed = YES;
  }
  return self;
}

- (BOOL)isTagNameAccepted:(NSString *)_tagName {
  if ([super isTagNameAccepted:_tagName])
    return YES;
  else
    return [Valid_complexContent_ContentTags containsObject:_tagName];
}

- (NSString *)tagName {
  return @"complexContent";
}

- (BOOL)addTag:(XmlSchemaTag *)_tag {
  if ([Valid_complexContent_ContentTags containsObject:[_tag tagName]]) {
    ASSIGN(self->derivator, _tag);
    return YES;
  }
  return [super addTag:_tag];
}

@end /* XmlSchemaComplexContent(XmlSchemaSaxBuilder) */
