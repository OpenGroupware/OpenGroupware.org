// $Id$

#include "XmlSchemaGroup.h"
#include "XmlSchemaElement.h"
#include "XmlSchemaContent.h"
#include "common.h"

@interface XmlSchemaGroup(PrivateMethods)
- (void)setContent:(XmlSchemaContent *)_content;
@end

@implementation XmlSchemaGroup

- (void)dealloc {
  RELEASE(self->name);
  RELEASE(self->maxOccurs);
  RELEASE(self->minOccurs);
  RELEASE(self->ref);

  RELEASE(self->content);
  [super dealloc];
}

/* attributes */

- (NSString *)name {
  return self->name;
}
- (NSString *)minOccurs {
  return self->minOccurs;
}
- (NSString *)maxOccurs {
  return self->maxOccurs;
}
- (NSString *)ref {
  return self->ref;
}

/* accessors */

- (void)setContent:(XmlSchemaContent *)_content {
  ASSIGN(self->content, _content);
}
- (XmlSchemaContent *)content {
  return self->content;
}

- (NSArray *)elementNames {
  return [self->content elementNames];
}

- (XmlSchemaElement *)elementWithName:(NSString *)_name {
  return [self->content elementWithName:_name];
}

@end /* XmlSchemaGroup */

@implementation XmlSchemaGroup(XmlSchemaSaxBuilder)

static NSSet *Valid_group_ContentTags = nil;

+ (void)initialize {
  if (Valid_group_ContentTags == nil) {
    Valid_group_ContentTags = [[NSSet alloc] initWithObjects:
                                             @"all",
                                             @"choice",
                                             @"sequence",
                                             nil];
  }
}

- (id)initWithAttributes:(id<SaxAttributes>)_attrs
               namespace:(NSString *)_namespace
              namespaces:(NSDictionary *)_ns
{
  if ((self = [super initWithAttributes:_attrs
                     namespace:_namespace
                     namespaces:_ns])) {
    self->name      = [[_attrs valueForRawName:@"name"] copy];
    self->minOccurs = [[_attrs valueForRawName:@"minOccurs"] copy];
    self->maxOccurs = [[_attrs valueForRawName:@"maxOccurs"] copy];
    self->ref       = [self copy:@"ref" attrs:_attrs ns:_ns];

    if (self->ref) {
      if (self->minOccurs == nil) ASSIGN(self->minOccurs, @"1");
      if (self->maxOccurs == nil) ASSIGN(self->maxOccurs, @"1");
    
      if ([self->minOccurs intValue] == 0)
        ASSIGN(self->maxOccurs, @"0");
      if ([self->maxOccurs intValue] == 0)
        ASSIGN(self->maxOccurs, @"unbounded");
    }
    else {
      RELEASE(self->minOccurs);
      RELEASE(self->maxOccurs);
    }
  }
  return self;
}

- (NSString *)tagName {
  return @"group";
}

- (void)prepareWithSchema:(XmlSchema *)_schema {
  [super prepareWithSchema:_schema];
  [self->content prepareWithSchema:_schema];
  if (self->name != nil && NO)
    NSLog(@"==== '%@'-> %@", self->name, [self content]);
}

- (BOOL)isTagNameAccepted:(NSString *)_tagName {
  if ([super isTagNameAccepted:_tagName])
    return YES;
  else
    return [Valid_group_ContentTags containsObject:_tagName];
}

- (BOOL)addTag:(XmlSchemaTag *)_tag {
  NSString *tagName;

  tagName = [_tag tagName];
  if ([tagName isEqualToString:@"all"]    ||
      [tagName isEqualToString:@"choice"] ||
      [tagName isEqualToString:@"sequence"]) {
    [self setContent:(XmlSchemaContent *)_tag];
    return YES;
  }
  return [super addTag:_tag];
}

@end /* XmlSchemaGroup(XmlSchemaSaxBuilder) */
