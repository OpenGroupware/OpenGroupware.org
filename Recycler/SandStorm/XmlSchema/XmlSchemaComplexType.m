
#include "XmlSchemaComplexType.h"
#include "XmlSchemaContent.h"
#include "XmlSchemaAttribute.h"
#include "XmlSchemaAttributeGroup.h"
#include "common.h"

@interface XmlSchemaComplexType(PrivateMethods)
- (void)setContent:(XmlSchemaContent *)_content;
@end

@implementation XmlSchemaComplexType

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->abstract);
  RELEASE(self->block);
  RELEASE(self->content);
  RELEASE(self->attributes);
  RELEASE(self->attributeGroups);
  
  [super dealloc];
}
#endif

/* attributes */

- (NSString *)abstract {
  return self->abstract;
}
- (NSString *)block {
  return self->block;
}
- (BOOL)mixed {
  return self->mixed;
}

/* accessors */

- (BOOL)isSimpleType {
  return NO;
}

- (BOOL)isScalar {
  return YES;
}

- (NSArray *)elementNames {
  return [self->content elementNames];
}

- (XmlSchemaElement *)elementWithName:(NSString *)_name {
  return [self->content elementWithName:_name];
}

- (NSArray *)attributeNames {
  return [self->attributes allKeys];
}
- (XmlSchemaAttribute *)attributeWithName:(NSString *)_key {
  return [self->attributes objectForKey:_key];
}

- (void)setContent:(XmlSchemaContent *)_content {
  ASSIGN(self->content, _content);
}
- (XmlSchemaContent *)content {
  return self->content;
}


/* ***************** */

- (NSString *)description {
  NSMutableString *str = [NSMutableString stringWithCapacity:128];

  [str appendString:@"<complexType name=\""];
  [str appendString:[self name]];
  [str appendString:@"\">"];
  [str appendString:[self->content description]];
  [str appendString:@"</complexType>\n"];
  return str;
}

@end /* XmlSchemaComplexType */


@implementation XmlSchemaComplexType(XmlSchemaSaxBuilder)

static NSSet *Valid_complexType_ContentTags = nil;

+ (void)initialize {
  if (Valid_complexType_ContentTags == nil) {
    Valid_complexType_ContentTags = [[NSSet alloc] initWithObjects:
                                                   @"simpleContent",
                                                   @"complexContent",
                                                   @"group",
                                                   @"all",
                                                   @"choice",
                                                   @"sequence",
                                                   @"attribute",
                                                   @"attributeGroup",
                                                   nil];
  }
}

- (id)initWithAttributes:(id<SaxAttributes>)_attrs
               namespace:(NSString *)_namespace
              namespaces:(NSDictionary *)_ns {
  if ((self = [super initWithAttributes:_attrs
                     namespace:_namespace
                     namespaces:_ns])) {
    self->abstract = [[_attrs valueForRawName:@"abstract"] copy];
    self->block    = [[_attrs valueForRawName:@"block"]    copy];
    
    if ([[_attrs valueForRawName:@"mixed"] isEqualToString:@"true"])
      self->mixed = YES;

    self->attributes      = [[NSMutableDictionary alloc] initWithCapacity:8];
    self->attributeGroups = [[NSMutableArray      alloc] initWithCapacity:8];
  }
  return self;
}

- (void)prepareWithSchema:(XmlSchema *)_schema {
  NSEnumerator            *groupEnum;
  XmlSchemaAttributeGroup *group;
  
  [super prepareWithSchema:_schema];

  groupEnum = [self->attributeGroups objectEnumerator];

  while ((group = [groupEnum nextObject])) {
    NSEnumerator *nameEnum;
    NSString     *attrName;
    
    [group prepareWithSchema:_schema];

    nameEnum = [[group attributeNames] objectEnumerator];
    while ((attrName = [nameEnum nextObject])) {
      XmlSchemaAttribute *attr = [group attributeWithName:attrName];
      if (attr)
        [self->attributes setObject:attr  forKey:attrName];
    }
  }
  [self->content prepareWithSchema:_schema];
}

- (NSString *)tagName {
  return @"complexType";
}

- (BOOL)isTagNameAccepted:(NSString *)_tagName {
  if ([super isTagNameAccepted:_tagName])
    return YES;
  else
    return [Valid_complexType_ContentTags containsObject:_tagName];
}

- (BOOL)addTag:(XmlSchemaTag *)_tag {
  NSString *tagName;

  tagName = [_tag tagName];
  if ([tagName isEqualToString:@"attribute"]) {
    return [self _insertTag:(XmlSchemaType *)_tag intoDict:self->attributes];
  }
  else if ([tagName isEqualToString:@"attributeGroup"]) {
    [self->attributeGroups addObject:_tag];
    return YES;
  }
  else {
    [self setContent:(XmlSchemaContent *)_tag];
    return YES;
  }
  
  return [super addTag:_tag];
}

@end /* XmlSchemaComplexType(XmlSchemaSaxBuilder) */
