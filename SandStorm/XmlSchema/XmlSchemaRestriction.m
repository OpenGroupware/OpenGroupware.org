// $Id$

#include "XmlSchemaRestriction.h"
#include "XmlSchemaAttribute.h"
#include "common.h"

@implementation XmlSchemaRestriction

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->base);
  RELEASE(self->attributes);
  [super dealloc];
}
#endif

/* attributes */

- (NSString *)base {
  return self->base;
}

- (NSArray *)elementNames {
  return [NSArray array];
}

- (XmlSchemaElement *)elementWithName:(NSString *)_name {
  return nil;
}

- (NSArray *)attributeNames {
  return [self->attributes valueForKey:@"name"];
}

- (XmlSchemaAttribute *)attributeWithName:(NSString *)_name {
  unsigned i, cnt  = [self->attributes count];
  
  for (i=0; i<cnt; i++) {
    XmlSchemaAttribute *tmp = [self->attributes objectAtIndex:i];

    if ([[tmp name] isEqualToString:_name])
      return tmp;
  }
  return nil;
}

- (NSArray *)attributes {
  return self->attributes;
}

@end /* XmlSchemaRestriction */


@implementation XmlSchemaRestriction(XmlSchemaSaxBuilder)

static NSSet *Valid_restriction_ContentTags = nil;

+ (void)initialize {
  if (Valid_restriction_ContentTags == nil) {
    Valid_restriction_ContentTags = [[NSSet alloc] initWithObjects:
                                                   // @"group",
                                                   // @"all",
                                                   // @"choice",
                                                   // @"sequence",
                                                   @"attribute",
                                                   // @"attributeGroup",
                                                   nil];
  }
}

- (id)initWithAttributes:(id<SaxAttributes>)_attrs
               namespace:(NSString *)_namespace
              namespaces:(NSDictionary *)_ns {
  if ((self = [super initWithAttributes:_attrs
                     namespace:_namespace
                     namespaces:_ns])) {
    self->base = [self copy:@"base" attrs:_attrs ns:_ns];
    self->attributes = [[NSMutableArray alloc] initWithCapacity:8];
  }
  return self;
}

- (NSString *)tagName {
  return @"restriction";
}

- (BOOL)isTagNameAccepted:(NSString *)_tagName {
  if ([super isTagNameAccepted:_tagName])
    return YES;
  else
    return [Valid_restriction_ContentTags containsObject:_tagName];
}

- (BOOL)addTag:(XmlSchemaTag *)_tag {
  if ([[_tag tagName] isEqualToString:@"attribute"]) {
    [self->attributes addObject:_tag];
    return YES;
  }
  return [super addTag:_tag];
}

@end /* XmlSchemaRestriction(XmlSchemaSaxBuilder) */
