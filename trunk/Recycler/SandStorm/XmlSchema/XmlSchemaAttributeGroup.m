
#include "XmlSchemaAttributeGroup.h"
#include "XmlSchema.h"
#include "common.h"

@implementation XmlSchemaAttributeGroup

- (void)dealloc {
  RELEASE(self->idValue);
  RELEASE(self->ref);
  RELEASE(self->name);

  RELEASE(self->attributes);
  RELEASE(self->children);
  [super dealloc];
}

- (NSString *)id {
  return self->idValue;
}
- (NSString *)ref {
  return self->ref;
}
- (NSString *)name {
  return self->name;
}

- (NSArray *)attributeNames {
  return [self->attributes allKeys];
}
- (XmlSchemaAttribute *)attributeWithName:(NSString *)_name {
  if (_name == nil) return nil;
  return [self->attributes objectForKey:_name];
}

@end /* XmlSchemaAttributeGroup */

@implementation XmlSchemaAttributeGroup(XmlSchemaSaxBuilder)

static NSSet *Valid_attributeGroup_ContentTags = nil;

+ (void)initialize {
  if (Valid_attributeGroup_ContentTags == nil) {
    Valid_attributeGroup_ContentTags = [[NSSet alloc] initWithObjects:
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
    self->idValue = [[_attrs valueForRawName:@"id"]   copy];
    self->name    = [[_attrs valueForRawName:@"name"] copy];
    self->ref     = [self copy:@"ref"  attrs:_attrs ns:_ns];

    self->attributes = [[NSMutableDictionary alloc] initWithCapacity:4];
    self->children   = [[NSMutableArray      alloc] initWithCapacity:4];
  }
  return self;
}

- (NSString *)tagName {
  return @"attributeGroup";
}

- (BOOL)isTagNameAccepted:(NSString *)_tagName {
  if ([super isTagNameAccepted:_tagName])
    return YES;
  else
    return [Valid_attributeGroup_ContentTags containsObject:_tagName];
}

- (BOOL)addTag:(XmlSchemaTag *)_tag {
  NSString *tagName;
  
  tagName = [_tag tagName];
  if ([tagName isEqualToString:@"attribute"]) {
    return [self _insertTag:(XmlSchemaType *)_tag intoDict:self->attributes];
  }
  else if ([tagName isEqualToString:@"attributeGroup"]) {
    [self->children addObject:_tag];
    return YES;
  }
  return [super addTag:_tag];
}

- (void)prepareWithSchema:(XmlSchema *)_schema {
  if ([self _shouldPrepare]) {
    NSEnumerator *childEnum = [self->children objectEnumerator];
    XmlSchemaTag *child;

    [super prepareWithSchema:_schema];

    if (self->ref != nil) {
      XmlSchemaAttributeGroup *group;
    
      group = [_schema attributeGroupWithName:self->ref];
      [group prepareWithSchema:_schema];
      [self _readFromAttributeGroup:group];
    }

    while ((child = [childEnum nextObject])) {
      NSString *tagName = [child tagName];
  
      [child prepareWithSchema:_schema];
      if ([tagName isEqualToString:@"attribute"]) {
        if ([child name])
          [self->attributes setObject:child forKey:[child name]];
        else
          NSLog(@"<attributeGroup: attribute.name = nil (%@)", child);
      }
      else if ([tagName isEqualToString:@"attributeGroup"]) {
        NSEnumerator *nameEnum = [[child attributeNames] objectEnumerator];
        NSString     *attrName;

        while ((attrName = [nameEnum nextObject])) {
          [self->attributes setObject:[child attributeWithName:attrName]
               forKey:attrName];
        }
      }
    }
  }
}

@end /* XmlSchemaAttributeGroup(XmlSchemaSaxBuilder) */


@implementation XmlSchemaAttributeGroup(PrivateMethods)

- (void)_readFromAttributeGroup:(XmlSchemaAttributeGroup *)_group {
  NSEnumerator *nameEnum = [[_group attributeNames] objectEnumerator];
  NSString     *attrName = nil;

  while ((attrName = [nameEnum nextObject])) {
    XmlSchemaAttribute *attr = [_group attributeWithName:attrName];
    if (attr)
      [self->attributes setObject:attr forKey:attrName];
  }
}

@end /* XmlSchemaAttributeGroup(PrivateMethods) */
