// $Id$

#include "XmlSchemaSequence.h"
#include "XmlSchemaGroup.h"
#include "XmlSchemaChoice.h"
#include "XmlSchemaElement.h"
#include "common.h"

@implementation XmlSchemaSequence

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->maxOccurs);
  RELEASE(self->minOccurs);
  RELEASE(self->elementNames);
  RELEASE(self->elements);

  RELEASE(self->contents);
  [super dealloc];
}
#endif

/* attributes */
- (NSString *)maxOccurs {
  return self->maxOccurs;
}
- (NSString *)minOccurs {
  return self->minOccurs;
}

/* element */
- (NSArray *)elementNames {
  return self->elementNames;
}
- (id)elementWithName:(NSString *)_name {
  if (_name == nil) return nil;
  return [self->elements objectForKey:_name];
}

/* *************************** */

- (NSString *)description {
  NSEnumerator    *nameEnum;
  NSString        *name;
  NSMutableString *str = [NSMutableString stringWithCapacity:128];
  id              tag;

  [str appendString:@"<sequence>\n"];
  
  nameEnum = [[self elementNames] objectEnumerator];
  while ((name = [nameEnum nextObject])) {
    tag = [self elementWithName:name];
    [str appendString:@"  "];
    [str appendString:[tag description]];
    [str appendString:@"\n"];
  }
  [str appendString:@"</sequence>\n"];
  return str;
}

@end /* XmlSchemaSequence */

@implementation XmlSchemaSequence(XmlSchemaSaxBuilder)

static NSSet *Valid_sequence_ContentTags = nil;

+ (void)initialize {
  if (Valid_sequence_ContentTags == nil) {
    Valid_sequence_ContentTags = [[NSSet alloc] initWithObjects:
                                                @"element",
                                                @"group",
                                                @"choice",
                                                @"sequence",
                                                @"any",
                                                nil];
  }
}

- (id)initWithAttributes:(id<SaxAttributes>)_attrs
               namespace:(NSString *)_namespace
              namespaces:(NSDictionary *)_ns {
  if ((self = [super initWithAttributes:_attrs
                     namespace:_namespace
                     namespaces:_ns])) {
    self->maxOccurs = [[_attrs valueForRawName:@"maxOccurs"] copy];
    self->minOccurs = [[_attrs valueForRawName:@"minOccurs"] copy];

    {
      NSZone *z;

      z = [self zone];
      self->elementNames = [[NSMutableArray      allocWithZone:z] init];
      self->elements     = [[NSMutableDictionary allocWithZone:z] init];
      self->contents     = [[NSMutableArray      allocWithZone:z] init];
    }
  }
  return self;
}

- (void)prepareWithSchema:(XmlSchema *)_schema {
  static Class GroupClass   = Nil;
  static Class ElementClass = Nil;
  NSEnumerator *tagEnum;
  id           tag;

  if (GroupClass   == Nil) GroupClass   = [XmlSchemaGroup   class];
  if (ElementClass == Nil) ElementClass = [XmlSchemaElement class];

  tagEnum = [self->contents objectEnumerator];
  while ((tag = [tagEnum nextObject])) {
    if ([tag isKindOfClass:GroupClass]) {
      NSString       *ref = [tag ref];
      XmlSchemaGroup *group;

      if (ref)
        group = [_schema groupWithName:ref];
      else
        group = (XmlSchemaGroup *)tag;
    }
    else if ([tag isKindOfClass:ElementClass]) {
      NSString *eName;

      [tag prepareWithSchema:_schema];
      eName = [tag name];
      if (eName) {
        [self->elementNames addObject:eName];
        [self->elements setObject:tag forKey:eName];
      }
    }
    else
      NSLog(@"WARNING: ignore sequence.%@ while preparing schema",
            [tag tagName]);
  }
}

- (BOOL)isTagNameAccepted:(NSString *)_tagName {
  if ([super isTagNameAccepted:_tagName])
    return YES;
  else
    return [Valid_sequence_ContentTags containsObject:_tagName];
}

- (BOOL)addTag:(XmlSchemaTag *)_tag {
  NSString *tagName;

  tagName = [_tag tagName];
  if ([tagName isEqualToString:@"element"] ||
      [tagName isEqualToString:@"choice"]  ||
      [tagName isEqualToString:@"group"]) {
    [self->contents addObject:_tag];
    return YES;
  }
  else
    return [super addTag:_tag];
}

- (NSString *)tagName {
  return @"sequence";
}

@end /* XmlSchemaSequence(XmlSchemaSaxBuilder) */
