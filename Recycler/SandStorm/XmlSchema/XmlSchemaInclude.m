
#include "XmlSchemaInclude.h"
#include "XmlSchema.h"
#include "common.h"

@interface XmlSchema(XmlSchemaInclude)
- (void)addAttributesFromSchema:(XmlSchema *)_schema;
- (void)addElementsFromSchema:(XmlSchema *)_schema;
- (void)addGroupsFromSchema:(XmlSchema *)_schema;
- (void)addTypesFromSchema:(XmlSchema *)_schema;
- (void)addAttributeGroupsFromSchema:(XmlSchema *)_schema;
@end

@implementation XmlSchemaInclude

- (void)dealloc {
  RELEASE(self->idValue);
  RELEASE(self->schemaLocation);
  [super dealloc];
}

/* attributes */

- (NSString *)id {
  return self->idValue;
}
- (NSString *)schemaLocation {
  return self->schemaLocation;
}

@end /* XmlSchemaInclude */

@implementation XmlSchemaInclude(XmlSchemaSaxBuilder)

- (id)initWithAttributes:(id<SaxAttributes>)_attrs
                 namespace:(NSString *)_namespace
              namespaces:(NSDictionary *)_ns {
  if ((self = [super initWithAttributes:_attrs
                     namespace:_namespace
                     namespaces:_ns])) {
    self->idValue        = [[_attrs valueForRawName:@"id"]             copy];
    self->schemaLocation = [[_attrs valueForRawName:@"schemaLocation"] copy];
  }
  return self;
}

- (NSString *)tagName {
  return @"include";
}

- (void)prepareWithSchema:(XmlSchema *)_schema {
  NSString  *path;
  NSString  *file;

  path = [[_schema schemaLocation] stringByDeletingPathExtension];
  path = [path stringByDeletingLastPathComponent];

  if (self->schemaLocation) {
    if ([self->schemaLocation isAbsolutePath])
      file = self->schemaLocation;
    else if (path)
      file = [path stringByAppendingPathComponent:self->schemaLocation];
    else
      file = self->schemaLocation;

    if ([[NSFileManager defaultManager] fileExistsAtPath:file]) {
      XmlSchema *subSchema = nil;
      
      subSchema = [[XmlSchema alloc] initWithContentsOfFile:file prepare:NO];
      [_schema addAttributesFromSchema:subSchema];
      [_schema addElementsFromSchema:subSchema];
      [_schema addGroupsFromSchema:subSchema];
      [_schema addTypesFromSchema:subSchema];
      [_schema addAttributeGroupsFromSchema:subSchema];
#if 0
      if ([file hasSuffix:@"xhtml11-model-1.xsd"]) {
        NSLog(@"file is %@", file);
        NSLog(@"groups is %@", [subSchema groupNames]);
      }
#endif
      
      RELEASE(subSchema);
    }
    else {
      NSLog(@"Warning: Could not include file %@", file);
    }
  }
  
  /*
    ToDo: get schema for schemaLocation and copy all content to _schema
    the targetNamespace of the schema in schemaLocation MUST be equal to
    _schema.targetNamespace or MUST be empty
  */
}

@end /* XmlSchemaInclude(XmlSchemaSaxBuilder) */

@implementation XmlSchema(XmlSchemaInclude)

- (void)addAttributesFromSchema:(XmlSchema *)_schema {
  NSEnumerator *nameEnum = [[_schema attributeNames] objectEnumerator];
  NSString     *name;

  while ((name = [nameEnum nextObject])) {
    [self addTag:[_schema attributeWithName:name]];
  }
}

- (void)addElementsFromSchema:(XmlSchema *)_schema {
  NSEnumerator *nameEnum = [[_schema elementNames] objectEnumerator];
  NSString     *name;

  while ((name = [nameEnum nextObject])) {
    [self addTag:[_schema elementWithName:name]];
  }
}

- (void)addGroupsFromSchema:(XmlSchema *)_schema {
  NSEnumerator *nameEnum = [[_schema groupNames] objectEnumerator];
  NSString     *name;

  while ((name = [nameEnum nextObject])) {
    [self addTag:[_schema groupWithName:name]];
  }
}

- (void)addTypesFromSchema:(XmlSchema *)_schema {
  NSEnumerator *nameEnum = [[_schema typeNames] objectEnumerator];
  NSString     *name;

  while ((name = [nameEnum nextObject])) {
    [self addTag:[_schema typeWithName:name]];
  }
}

- (void)addAttributeGroupsFromSchema:(XmlSchema *)_schema {
  NSEnumerator *nameEnum = [[_schema attributeGroupNames] objectEnumerator];
  NSString     *name;

  while ((name = [nameEnum nextObject])) {
    [self addTag:[_schema attributeGroupWithName:name]];
  }
}


@end
