
#include "XmlSchemaDocumentation.h"
#include "common.h"

@implementation XmlSchemaDocumentation

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->source);
  
  [super dealloc];
}
#endif

/* attributes */
- (NSString *)source {
  return self->source;
}

@end /* XmlSchemaDocumentation */

@implementation XmlSchemaDocumentation(XmlSchemaSaxBuilder)

- (id)initWithAttributes:(id<SaxAttributes>)_attrs
               namespace:(NSString *)_namespace
              namespaces:(NSDictionary *)_ns {
  if ((self = [super initWithAttributes:_attrs
                     namespace:_namespace
                     namespaces:_ns])) {
    self->source = [[_attrs valueForRawName:@"source"] copy];
  }
  return self;
}

- (BOOL)isTagNameAccepted:(NSString *)_tagName {
  if ([super isTagNameAccepted:_tagName])
    return YES;
  else
    return NO;
}

- (BOOL)addTag:(XmlSchemaTag *)_tag {
  return [super addTag:_tag];
}

- (NSString *)tagName {
  return @"documentation";
}

@end /* XmlSchemaDocumentation(XmlSchemaSaxBuilder) */
