// $Id$

#include "XmlSchemaClassDescription.h"
#include "XmlSchemaMapping.h"
#include "XmlSchemaElement.h"
#include "common.h"

@implementation XmlSchemaClassDescription

- (id)initWithMapping:(XmlSchemaMapping *)_mapping type:(XmlSchemaType *)_type
{
  if ((self = [super init])) {
    ASSIGN(self->mapping, _mapping);
    ASSIGN(self->type, _type);
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->mapping);
  RELEASE(self->type);
  
  RELEASE(self->attributeKeys);
  RELEASE(self->toOneRelationshipKeys);
  RELEASE(self->toManyRelationshipKeys);
  
  [super dealloc];
}
#endif

/* accessors */

- (void)_generateKeys {
  NSMutableArray *attrKeys;
  NSMutableArray *toOneKeys;
  NSMutableArray *toManyKeys;
  NSEnumerator   *nameEnum;
  NSString       *name;

  attrKeys   = [[NSMutableArray alloc] initWithCapacity:8];
  toOneKeys  = [[NSMutableArray alloc] initWithCapacity:8];
  toManyKeys = [[NSMutableArray alloc] initWithCapacity:8];
  
  nameEnum   = [[self->type elementNames] objectEnumerator];
  while ((name = [nameEnum nextObject])) {
    XmlSchemaElement *element = [type elementWithName:name];

    name = [self->mapping nameFromElement:element];

    if ([element isSimpleType])
      [attrKeys addObject:name];
    else {
      if ([element isScalar])
        [toOneKeys addObject:name];
      else
        [toManyKeys addObject:name];
    }
  }
  
  self->attributeKeys          = [[NSArray alloc] initWithArray:attrKeys];
  self->toOneRelationshipKeys  = [[NSArray alloc] initWithArray:toOneKeys];
  self->toManyRelationshipKeys = [[NSArray alloc] initWithArray:toManyKeys];
  
  RELEASE(attrKeys);
  RELEASE(toOneKeys);
  RELEASE(toManyKeys);
}

- (NSArray *)attributeKeys {
  if (self->attributeKeys == nil) [self _generateKeys];
  return self->attributeKeys;
}

- (NSArray *)toOneRelationshipKeys {
  if (self->toOneRelationshipKeys == nil) [self _generateKeys];
  return self->toOneRelationshipKeys;
}

- (NSArray *)toManyRelationshipKeys {
  if (self->toManyRelationshipKeys == nil) [self _generateKeys];
  return self->toManyRelationshipKeys;
}

- (NSString *)inverseForRelationshipKey:(NSString *)_key {
  /*
    this only makes sense if XML Schema allows references,
    don't know about that yet ...
  */
  return nil;
}

@end /* XmlSchemaClassDescription */

