// $Id$

#include "XmlSchema.h"
#include "XmlSchemaGroup.h"
#include "XmlSchemaAttributeGroup.h"
#include "XmlSchemaAttribute.h"
#include "XmlSchemaElement.h"
#include "XmlSchemaType.h"
#include "XmlSchemaSaxBuilder.h"
#include "common.h"

@interface XmlSchema(Resources)
+ (NSString *)schemesPath;
+ (void)loadSchemaResources;
@end

static NSMutableDictionary *namespace2schema = nil;
static NSDictionary        *namespace2file   = nil;

@implementation XmlSchema

+ (XmlSchema *)schemaForNamespace:(NSString *)_namespace {
  XmlSchema *result;

  if (_namespace == nil) return nil;

  result = [namespace2schema objectForKey:_namespace];

  if (result == nil) {
    NSString *file;

    file = [namespace2file objectForKey:_namespace];
    if (file == nil) {
      NSLog(@"Warning: Could not find schema file for namespace '%@'. "
            @"Try namespace instead!", _namespace);
      file = _namespace;
    }
    
    result = [[[XmlSchema alloc] initWithContentsOfFile:file] autorelease];
  }
  return result;
}

+ (BOOL)hasSchemaForNamespace:(NSString *)_namespace {
  return ([namespace2schema objectForKey:_namespace] != nil) ? YES : NO;
}

+ (void)registerSchemaAtPath:(NSString *)_path {
  XmlSchema *result = nil;
  NSString  *uri;
    
  if (_path == nil) return;

  result = [[[XmlSchema alloc] initWithContentsOfFile:_path] autorelease];

  if (result == nil) return;
  
  uri = [result targetNamespace];
  if ([namespace2schema objectForKey:uri] == nil)
    [namespace2schema setObject:result forKey:uri];
  else {
    NSLog(@"Could not register schema at path '%@' ",
          @"(There is already a schema at targetNamespace='%@')",
          _path, uri);
  }
}

+ (XmlSchemaElement *)elementWithQName:(NSString *)_qName {
  XmlSchema *mySchema;

  mySchema  = [XmlSchema schemaForNamespace:[_qName uriFromQName]];
  return [mySchema elementWithName:[_qName valueFromQName]];
}

+ (XmlSchemaType *)typeWithQName:(NSString *)_qName {
  XmlSchema     *mySchema;
  XmlSchemaType *type;

  mySchema = [XmlSchema schemaForNamespace:[_qName uriFromQName]];
  type     = [mySchema typeWithName:[_qName valueFromQName]];
  
  return type;
}

+ (BOOL)isXmlSchemaNamespace:(NSString *)_namespace {
  return isXmlSchemaNamespace(_namespace);
}

- (void)registerSchemaForNamespace:(NSString *)_namespace {
  if (_namespace == nil) return;
  if ([namespace2schema objectForKey:_namespace] != nil) {
    NSLog(@"can not register schema for uri '%@'(schema already exists!)",
          _namespace);
    return;
  }
  [namespace2schema setObject:self forKey:_namespace];
}

- (void)registerSchema {
  [self registerSchemaForNamespace:[self targetNamespace]];
}

- (id)initWithContentsOfFile:(NSString *)_file prepare:(BOOL)_prepare {
  RELEASE(self);
  self = [XmlSchemaSaxBuilder parseSchemaFromContentsOfFile:_file];
  [self setSchemaLocation:_file];

  [self _prepareTags:self->includes withSchema:self];
  [self _prepareTags:self->imports  withSchema:self];

  if (_prepare) [self prepareSchema];
  
  RETAIN(self);
  
  return self;  
}

- (id)initWithContentsOfFile:(NSString *)_file {
  return [self initWithContentsOfFile:_file prepare:YES];
}

- (id)init {
  return [self initWithContentsOfFile:nil];
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  /* attributes */
  RELEASE(self->targetNamespace);
  RELEASE(self->attributes);
  RELEASE(self->elements);
  RELEASE(self->groups);
  RELEASE(self->attributeGroups);
  RELEASE(self->types);
  RELEASE(self->includes);
  RELEASE(self->imports);

  RELEASE(self->blockDefault);
  RELEASE(self->finalDefault);
  RELEASE(self->idValue);
  RELEASE(self->version);
  RELEASE(self->elementFormDefault);
  RELEASE(self->attributeFormDefault);

  //
  RELEASE(self->schemaLocation);

  [super dealloc];
}
#endif

/* attributes */

- (NSString *)targetNamespace {
  return self->targetNamespace;
}
- (NSString *)blockDefault {
  return self->blockDefault;
}
- (NSString *)finalDefault {
  return self->finalDefault;
}
- (NSString *)id {
  return self->idValue;
}
- (NSString *)version {
  return self->version;
}
- (NSString *)elementFormDefault {
  return self->elementFormDefault;
}
- (NSString *)attributeFormDefault {
  return self->attributeFormDefault;
}

/* elements */

- (NSArray *)elementNames {
  return [self->elements allKeys];
}
- (XmlSchemaElement *)elementWithName:(NSString *)_key {
  id result;

  result = [self->elements objectForKey:_key];

  if (result == nil) {
    NSLog(@"Warning: schema '%@' has no element '%@'",
          self->targetNamespace, _key);
  }
  
  return result;
}

/* attribute */

- (NSArray *)attributeNames {
  return [self->attributes allKeys];
}
- (XmlSchemaAttribute *)attributeWithName:(NSString *)_key {
  return [self->attributes objectForKey:_key];
}

/* groups */

- (NSArray *)groupNames {
  return [self->groups allKeys];
}
- (XmlSchemaGroup *)groupWithName:(NSString *)_key {
  return [self->groups objectForKey:_key];
}

/* attribute groups */

- (NSArray *)attributeGroupNames {
  return [self->attributeGroups allKeys];
}
- (XmlSchemaAttributeGroup *)attributeGroupWithName:(NSString *)_key {
  return [self->attributeGroups objectForKey:_key];
}

/* types */

- (NSArray *)typeNames {
  return [self->types allKeys];
}
- (XmlSchemaType *)typeWithName:(NSString *)_key {
  id result;

  result = [self->types objectForKey:_key];

  if (result == nil) {
    NSLog(@"Warning: schema '%@' has no type '%@'",
          self->targetNamespace, _key);
  }
  
  return result;
}

/***************************************************************/

- (NSString *)description {
  NSEnumerator    *tagEnum; 
  NSMutableString *str = [NSMutableString stringWithCapacity:128];
  id              tag;

  [str appendString:@"\n<schema"];

  if (self->targetNamespace) {
    [str appendString:@" targetNamespace=\""];
    [str appendString:self->targetNamespace];
    [str appendString:@"\""];
  }
  if (self->blockDefault) {
    [str appendString:@" blockDefault=\""];
    [str appendString:self->blockDefault];
    [str appendString:@"\""];
  }
  if (self->finalDefault) {
    [str appendString:@" finalDefault=\""];
    [str appendString:self->finalDefault];
    [str appendString:@"\""];
  }
  if (self->idValue) {
    [str appendString:@" id=\""];
    [str appendString:self->idValue];
    [str appendString:@"\""];
  }
  if (self->version) {
    [str appendString:@" version=\""];
    [str appendString:self->version];
    [str appendString:@"\""];
  }
  if (self->elementFormDefault) {
    [str appendString:@" elementFormDefault=\""];
    [str appendString:self->elementFormDefault];
    [str appendString:@"\""];
  }

  if (self->attributeFormDefault) {
    [str appendString:@" attributeFormDefault=\""];
    [str appendString:self->attributeFormDefault];
    [str appendString:@"\""];
  }

  [str appendString:@">\n"];
  
  tagEnum = [self->elements objectEnumerator];
  while ((tag = [tagEnum nextObject])) {
    [str appendString:@"  "];
    [str appendString:[tag description]];
    [str appendString:@"\n"];
  }
  tagEnum = [self->attributes objectEnumerator];
  while ((tag = [tagEnum nextObject])) {
    [str appendString:@"  "];
    [str appendString:[tag description]];
    [str appendString:@"\n"];
  }  
  [str appendString:@"</schema>"];
  return str;
}

@end /* XmlSchema */

@implementation XmlSchema(XmlSchemaSaxBuilder)

static NSSet *Valid_schema_ContentTags = nil;

+ (void)initialize {
  if (Valid_schema_ContentTags == nil) {
    Valid_schema_ContentTags = [[NSSet alloc] initWithObjects:
                                              @"include",
                                              @"import",
                                              //@"redefine",
                                              @"simpleType",
                                              @"complexType",
                                              @"group",
                                              @"attributeGroup",
                                              @"element",
                                              @"attribute",
                                              //@"notation",
                                              nil];
  }
  if (namespace2schema == nil)
    [XmlSchema loadSchemaResources];  
}

/* designated initialzer */
- (id)initWithAttributes:(id<SaxAttributes>)_attrs
               namespace:(NSString *)_namespace
              namespaces:(NSDictionary *)_ns {
  if ((self = [super initWithAttributes:_attrs
                     namespace:_namespace
                     namespaces:_ns])) {
    NSZone *z;

    z = [self zone];
    
    self->attributes      = [[NSMutableDictionary alloc] initWithCapacity:32];
    self->elements        = [[NSMutableDictionary alloc] initWithCapacity:32];
    self->groups          = [[NSMutableDictionary alloc] initWithCapacity:32];
    self->attributeGroups = [[NSMutableDictionary alloc] initWithCapacity:32];
    self->types           = [[NSMutableDictionary alloc] initWithCapacity:32];
    self->includes        = [[NSMutableArray      alloc] initWithCapacity:4];
    self->imports         = [[NSMutableArray      alloc] initWithCapacity:4];

    self->targetNamespace =[[_attrs valueForRawName:@"targetNamespace"] copy];
    self->blockDefault    =[[_attrs valueForRawName:@"blockDefault"]    copy];
    self->finalDefault    =[[_attrs valueForRawName:@"finalDefault"]    copy];
    self->version         =[[_attrs valueForRawName:@"version"]         copy];
    self->idValue         =[[_attrs valueForRawName:@"id"]              copy];

    self->elementFormDefault =
      [[_attrs valueForRawName:@"elementFormDefault"] copy];
    self->attributeFormDefault =
      [[_attrs valueForRawName:@"attributeFormDefault"] copy];

    if (![self->attributeFormDefault isEqualToString:@"qualified"])
      ASSIGN(self->attributeFormDefault, @"unqualified");

    if (![self->elementFormDefault isEqualToString:@"qualified"])
      ASSIGN(self->elementFormDefault, @"unqualified");

    if (self->targetNamespace == nil) {
      ASSIGN(self->targetNamespace, @"");
    }
  }
  return self;
}

- (void)prepareSchema {
  [self _prepareTags:self->types           withSchema:self];
  [self _prepareTags:self->attributes      withSchema:self];
  [self _prepareTags:self->attributeGroups withSchema:self];
  [self _prepareTags:self->groups          withSchema:self];
  [self _prepareTags:self->elements        withSchema:self];
}

- (void)prepareWithSchema:(XmlSchema *)_schema {
  // do nothing
}

- (NSString *)tagName {
  return @"schema";
}

- (BOOL)isTagNameAccepted:(NSString *)_tagName {
  if ([super isTagNameAccepted:_tagName])
    return YES;
  else
    return [Valid_schema_ContentTags containsObject:_tagName];
}

- (BOOL)addTag:(XmlSchemaTag *)_tag {
  NSString *tagName;

  tagName = [_tag tagName];
  if ([tagName isEqualToString:@"element"]) {
    return [self _insertTag:(XmlSchemaType *)_tag intoDict:self->elements];
  }
  else if ([tagName isEqualToString:@"group"]) {
    return [self _insertTag:(XmlSchemaType *)_tag intoDict:self->groups];
  }
  else if ([tagName isEqualToString:@"attribute"]) {
    return [self _insertTag:(XmlSchemaType *)_tag intoDict:self->attributes];
  }
  else if ([tagName isEqualToString:@"attributeGroup"]) {
    return [self _insertTag:(XmlSchemaType *)_tag
                 intoDict:self->attributeGroups];
  }
  else if ([tagName isEqualToString:@"complexType"]) {
    return [self _insertTag:(XmlSchemaType *)_tag intoDict:self->types];
  }
  else if ([tagName isEqualToString:@"simpleType"]) {
    return [self _insertTag:(XmlSchemaType *)_tag intoDict:self->types];
  }
  else if ([tagName isEqualToString:@"include"]) {
    [self->includes addObject:_tag];
    return YES;
  }
  else if ([tagName isEqualToString:@"import"]) {
    [self->imports addObject:_tag];
    return YES;
  }
  else
    return [super addTag:_tag];
}

@end /* XmlSchema(XmlSchemaSaxBuilder) */

@implementation XmlSchema(AdditionalApi)
- (void)setSchemaLocation:(NSString *)_schemaLocation {
  ASSIGNCOPY(self->schemaLocation, _schemaLocation);
}
- (NSString *)schemaLocation {
  return self->schemaLocation;
}
@end


@implementation XmlSchema(Resources)

#if !COMPILE_AS_FRAMEWORK
+ (NSString *)schemesPath {
  NSString      *apath;
  NSFileManager *fm = [NSFileManager defaultManager];
  NSDictionary  *env;
  NSString      *relPath;

  env  = [[NSProcessInfo processInfo] environment];
  relPath = @"Libraries";
  relPath = [relPath stringByAppendingPathComponent:@"Resources"];
  relPath = [relPath stringByAppendingPathComponent:@"XmlSchema"];
  relPath = [relPath stringByAppendingPathComponent:@"schemes"];
    
  apath = [env objectForKey:@"GNUSTEP_USER_ROOT"];
  apath = [apath stringByAppendingPathComponent:relPath];
  if (![fm fileExistsAtPath:apath]) {
    apath = [env objectForKey:@"GNUSTEP_LOCAL_ROOT"];
    apath = [apath stringByAppendingPathComponent:relPath];
  }
  if (![fm fileExistsAtPath:apath]) {
    apath = [env objectForKey:@"GNUSTEP_SYSTEM_ROOT"];
    apath = [apath stringByAppendingPathComponent:relPath];
  }
  if (![fm fileExistsAtPath:apath]) {
    apath = relPath;
  }
  if (![fm fileExistsAtPath:apath]) {
    NSLog(@"ERROR: cannot find path for schema resources "
          @"of XmlSchema library !");
  }

  return apath;
}
#endif

+ (void)loadSchemaResources {
  NSDictionary        *tmp    = nil;
  NSMutableDictionary *dict   = nil;
  NSEnumerator        *nsEnum = nil;
  NSString            *ns     = nil;
  NSString            *path   = nil;
  NSString            *file   = nil;

  ASSIGN(namespace2schema, (id)nil);
  ASSIGN(namespace2file,   (id)nil);
  
  namespace2schema = [[NSMutableDictionary alloc] initWithCapacity:32];

#if COMPILE_AS_FRAMEWORK
  path = nil;
  file = [[NSBundle bundleForClass:self]
                    pathForResource:@"namespaces" ofType:@"plist"];
#else
  path   = [XmlSchema schemesPath];    
  file   = [path stringByAppendingPathComponent:@"namespaces.plist"];
#endif
  tmp    = [[NSDictionary alloc] initWithContentsOfFile:file];
  nsEnum = [tmp keyEnumerator];
  dict   = [NSMutableDictionary dictionaryWithCapacity:64];
    
  while ((ns = [nsEnum nextObject])) {
    file = [path stringByAppendingPathComponent:[tmp objectForKey:ns]];
    [dict setObject:file forKey:ns];
  }
  namespace2file = [[NSDictionary alloc] initWithDictionary:dict];
}

@end /* XmlSchema(Resources) */
