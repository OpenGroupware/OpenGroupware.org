// $Id$

#include "XmlSchemaAll.h"
#include "XmlSchemaElement.h"
#include "common.h"

@implementation XmlSchemaAll

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->minOccurs);
  RELEASE(self->elements);
  
  [super dealloc];
}
#endif

/* attributes */
- (NSString *)maxOccurs {
  return @"1";
}
- (NSString *)minOccurs {
  return self->minOccurs;
}

/* element */
- (NSArray *)elementNames {
  return [self->elements allKeys];
}
- (XmlSchemaElement *)elementWithName:(NSString *)_name {
  return [self->elements objectForKey:_name];
}

- (NSString *)description {
  NSEnumerator    *elemEnum; 
  NSMutableString *str = [NSMutableString stringWithCapacity:128];
  id              elem;

  [str appendString:@"<all>\n"];
  
  elemEnum = [self->elements objectEnumerator];
  while ((elem = [elemEnum nextObject])) {
    [str appendString:[elem description]];
    [str appendString:@"\n"];
  }
  [str appendString:@"</all>\n"];
  return str;
}

@end /* XmlSchemaAll */

@implementation XmlSchemaAll(XmlSchemaSaxBuilder)

static NSSet *Valid_all_ContentTags = nil;

+ (void)initialize {
  if (Valid_all_ContentTags == nil) {
    Valid_all_ContentTags = [[NSSet alloc] initWithObjects:
                                                @"element",
                                                nil];
  }
}

- (id)initWithAttributes:(id<SaxAttributes>)_attrs
               namespace:(NSString *)_namespace
              namespaces:(NSDictionary *)_ns {
  if ((self = [super initWithAttributes:_attrs
                     namespace:_namespace
                     namespaces:_ns])) {
    // maxOccurs is @"1"
    self->minOccurs = [[_attrs valueForRawName:@"minOccurs"] copy];
    
    if (![self->minOccurs isEqualToString:@"0"]) {
      ASSIGN(self->minOccurs, @"1");
    }
    
    self->elements = [[NSMutableDictionary allocWithZone:[self zone]]
                                           initWithCapacity:32];
  }
  return self;
}

- (BOOL)isTagNameAccepted:(NSString *)_tagName {
  if ([super isTagNameAccepted:_tagName])
    return YES;
  else
    return [Valid_all_ContentTags containsObject:_tagName];
}

- (BOOL)addTag:(XmlSchemaTag *)_tag {
  if ([[_tag tagName] isEqualToString:@"element"]) {
    return [self _insertTag:(XmlSchemaElement *)_tag intoDict:self->elements];
  }
  return [super addTag:_tag];
}

- (NSString *)tagName {
  return @"all";
}

- (void)prepareWithSchema:(XmlSchema *)_schema {
  [super prepareWithSchema:_schema];
  [self _prepareTags:self->elements withSchema:_schema];
}


@end /* XmlSchemaAll(XmlSchemaSaxBuilder) */
