// $Id$

#include "XmlSchemaAnnotation.h"
#include "common.h"

@implementation XmlSchemaAnnotation

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->idValue);

  RELEASE(self->appinfos);
  RELEASE(self->documentations);
  
  [super dealloc];
}
#endif

/* attributes */
- (NSString *)id {
  return self->idValue;
}

/* content */

- (NSArray *)appinfos {
  return (NSArray *)self->appinfos;
}

- (NSArray *)documentations {
  return (NSArray *)self->documentations;
}

@end /* XmlSchemaAnnotation */

@implementation XmlSchemaAnnotation(XmlSchemaSaxBuilder)

static NSSet *Valid_annotation_ContentTags = nil;

+ (void)initialize {
  if (Valid_annotation_ContentTags == nil) {
    Valid_annotation_ContentTags = [[NSSet alloc] initWithObjects:
                                                   @"appinfo",
                                                   @"documentation",
                                                   nil];
  }
}

- (id)initWithAttributes:(id<SaxAttributes>)_attrs
               namespace:(NSString *)_namespace
              namespaces:(NSDictionary *)_ns {
  if ((self = [super initWithAttributes:_attrs
                     namespace:_namespace
                     namespaces:_ns])) {
    self->idValue = [[_attrs valueForRawName:@"id"] copy];

    self->appinfos       = [[NSMutableArray alloc] initWithCapacity:4];
    self->documentations = [[NSMutableArray alloc] initWithCapacity:4];
  }
  return self;
}

- (BOOL)isTagNameAccepted:(NSString *)_tagName {
  if ([super isTagNameAccepted:_tagName])
    return YES;
  else
    return [Valid_annotation_ContentTags containsObject:_tagName];
}

- (BOOL)addTag:(XmlSchemaTag *)_tag {
  if ([[_tag tagName] isEqualToString:@"appinfo"]) {
    [self->appinfos addObject:_tag];
    return YES;
  }
  else if ([[_tag tagName] isEqualToString:@"documentation"]) {
    [self->documentations addObject:_tag];
    return YES;
  }
  return [super addTag:_tag];
}

- (NSString *)tagName {
  return @"annotation";
}

@end /* XmlSchemaAnnotation(XmlSchemaSaxBuilder) */
