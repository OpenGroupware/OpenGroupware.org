
#include "XmlClassGenerator.h"
#include <XmlSchema/XmlSchema.h>
#include "common.h"

@interface NSString(XmlClassGenerator)
- (NSString *)firstLetterUpperCase;
@end

@interface XmlClassGenerator(PrivateMethods)
- (void)_appendStartIncludeConditionalWithPath:(NSString *)_path;
- (void)_appendEndIncludeConditionalWithPath:(NSString *)_path;
- (void)_appendClasses;
- (void)_appendIncludes;
- (void)_appendInstanceVariables;
- (void)_appendAccessorDeclarations;
- (void)_appendAccessorDefinitions;
- (void)_appendDealloc;
- (void)_appendDefaultSchemaMethods;
- (NSString *)_classNameFromElement:(XmlSchemaElement *)_element;
- (void)_writeToFile:(NSString *)_path;
- (NSString *)_nameWithElement:(XmlSchemaElement *)_element;
@end /* XmlClassGenerator(PrivateMethods) */

@implementation XmlClassGenerator

static NSMutableDictionary *qtype2className = nil;

+ (void)generateClassFilesFromSchemaAtPath:(NSString *)_schemaPath
                                bundlePath:(NSString *)_bundlePath
                                    prefix:(NSString *)_prefix
{
  XmlSchema *schema;

  schema = [[XmlSchema alloc] initWithContentsOfFile:_schemaPath];
  
  [self generateClassFilesFromSchema:schema
        schemaPath:_schemaPath
        bundlePath:_bundlePath
        prefix:_prefix];
  
  RELEASE(schema);
}

+ (void)generateClassFilesFromSchema:(XmlSchema *)_schema
                          schemaPath:(NSString *)_schemaPath
                          bundlePath:(NSString *)_path
                              prefix:(NSString *)_prefix
{
  XmlClassGenerator *cGenerator;
  NSEnumerator      *nameEnum;
  NSString          *name;

  fprintf(stderr, "creating classes from '%s'\n", [_schemaPath cString]);
  cGenerator = [[XmlClassGenerator alloc] init];
  
  // create classes for types
  nameEnum = [[_schema typeNames] objectEnumerator];
  while ((name = [nameEnum nextObject])) {
    [cGenerator setType:[_schema typeWithName:name]];
    [cGenerator setPrefix:_prefix];
    [cGenerator setSchemaPath:_schemaPath];
    [cGenerator generateClassFilesAtPath:_path];
  }
  // create classes for elements
  nameEnum = [[_schema elementNames] objectEnumerator];
  while ((name = [nameEnum nextObject])) {
    XmlSchemaType *myType = [[_schema elementWithName:name] contentType];
    NSString      *tName;

    tName = [myType nameAsQName];
    
    if ((tName == nil) || ([tName valueFromQName] == nil) ||
        ([self classNameForType:tName] == nil)) {
      [cGenerator setType:[_schema elementWithName:name]];
      [cGenerator setPrefix:_prefix];
      [cGenerator setSchemaPath:_schemaPath];
      [cGenerator generateClassFilesAtPath:_path];
    }
  }
  RELEASE(cGenerator);
  fprintf(stderr, "creating classes is done\n");
}

+ (void)generateClassFilesFromSchema:(XmlSchema *)_schema
                          bundlePath:(NSString *)_path
                              prefix:(NSString *)_prefix
{
  [self generateClassFilesFromSchema:_schema
        schemaPath:nil
        bundlePath:_path
        prefix:_prefix];
}

+ (void)registerClassName:(NSString *)_className
                  forType:(NSString *)_type { // QName
  if (qtype2className == nil)
    qtype2className = [[NSMutableDictionary alloc] initWithCapacity:32];
  
  if (_className && _type)
    [qtype2className setObject:_className forKey:_type];
}

+ (NSString *)classNameForType:(NSString *)_type { // QName
  return (_type)
    ? [qtype2className objectForKey:_type]
    : nil;
}

- (id)initWithType:(XmlSchemaType *)_type {
  if ((self = [super init])) {
    self->string = [[NSMutableString alloc] initWithCapacity:512];
    ASSIGN(self->type, _type);
  }
  return self;
}

- (id)init {
  return [self initWithType:nil];
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->type);
  RELEASE(self->className);
  RELEASE(self->prefix);
  RELEASE(self->string);
  RELEASE(self->schemaPath);
  
  [super dealloc];
}
#endif

// accessors

- (void)setType:(XmlSchemaType *)_type {
  ASSIGN(self->type, _type);
  ASSIGN(self->className, (id)nil);
}
- (XmlSchemaType *)type {
  return self->type;
}

- (void)setSchemaPath:(NSString *)_schemaPath {
  ASSIGNCOPY(self->schemaPath, _schemaPath);
}
- (NSString *)schemaPath {
  return self->schemaPath;
}

- (void)setPrefix:(NSString *)_prefix {
  ASSIGNCOPY(self->prefix, _prefix);
}
- (NSString *)prefix {
  return self->prefix;
}

- (NSString *)className {
  if (self->className == nil) {
    NSString *str = [self->type name];

    str = (self->prefix)
      ? [self->prefix stringByAppendingString:str]
      : str;
    
    ASSIGN(self->className, str);
  }
  return self->className;
}

// ++++++++++++++++++++++

- (void)generateClassFilesAtPath:(NSString *)_path {
  if ([self->type isSimpleType]) return;

  if ([[self->type name] length] == 0) return;

  fprintf(stderr, "create class %s\n", [[self className] cString]);

  [self->string setString:@""];

  [XmlClassGenerator registerClassName:[self className]
                     forType:[self->type nameAsQName]];

  [self generateHFileAtPath:_path];
  [self generateMFileAtPath:_path];
}

- (void)generateHFileAtPath:(NSString *)_path {
  if ([self->type isSimpleType]) return;
  
  [self->string setString:@""];
  [self->string appendString:@"// This File is generated automatically. "];
  [self->string appendString:@"Don't edit it!!!\n\n"];
  [self _appendStartIncludeConditionalWithPath:_path];
  
  [self->string appendString:@"#import <Foundation/NSObject.h>\n\n"];

  [self _appendClasses];
  
  [self->string appendString:@"@interface "];
  [self->string appendString:[self className]];
  [self->string appendString:@" : NSObject\n"];
  [self->string appendString:@"{\n"];

  [self _appendInstanceVariables];

  [self->string appendString:@"}\n\n"];

  [self _appendAccessorDeclarations];
  
  [self->string appendString:@"@end /* "];
  [self->string appendString:[self className]];
  [self->string appendString:@" */\n\n"];

  [self _appendEndIncludeConditionalWithPath:_path];

  {
    NSString *path;
    
    path = (_path) ? _path : @"";
    path = [path stringByAppendingPathComponent:[self className]];
    path = [path stringByAppendingPathExtension:@"h"];
    [self _writeToFile:path];
  }
}

- (void)generateMFileAtPath:(NSString *)_path {
  if ([self->type isSimpleType]) return;
  
  [self->string setString:@""];
  [self->string appendString:@"// This File is generated automatically. "];
  [self->string appendString:@"Don't edit it!!!\n\n"];
  [self->string appendString:@"#include \""];
  [self->string appendString:[self className]];
  [self->string appendString:@".h\"\n"];
  
  [self _appendIncludes];
  
  [self->string appendString:@"@implementation "];
  [self->string appendString:[self className]];
  [self->string appendString:@"\n\n"];

  [self _appendDealloc];

  [self _appendAccessorDefinitions];

  [self _appendDefaultSchemaMethods];
  
  [self->string appendString:@"@end /* "];
  [self->string appendString:[self className]];
  [self->string appendString:@" */\n"];

  {
    NSString *path;
    
    path = (_path) ? _path : @"";
    path = [path stringByAppendingPathComponent:[self className]];
    path = [path stringByAppendingPathExtension:@"m"];
    [self _writeToFile:path];
  }
}

@end /* XmlClassGenerator */


@implementation XmlClassGenerator(PrivateMethods)

- (unsigned)_maxClassNameLength {
  NSEnumerator *nameEnum;
  NSString     *name;
  unsigned     maxLength = 0;

  nameEnum = [[self->type elementNames] objectEnumerator];
  
  while ((name = [nameEnum nextObject])) {
    NSString *cName;

    cName = [self _classNameFromElement:[self->type elementWithName:name]];
    if ([cName length] > maxLength)
      maxLength = [cName length];
  }
  return maxLength;
}

- (NSArray *)_filteredTypesFromType:(XmlSchemaType *)_type {
  NSMutableArray *types;
  NSEnumerator   *nameEnum;
  NSString       *name;

  nameEnum = [[_type elementNames] objectEnumerator];
  types    = [[NSMutableArray alloc] initWithCapacity:4];
  
  while ((name = [nameEnum nextObject])) {
    XmlSchemaElement *el    = [_type elementWithName:name];
    NSString         *typeValue  = [el type];
    NSString         *uri   = [typeValue uriFromQName];

    if ((uri != nil) && ![XmlSchema isXmlSchemaNamespace:uri]) {
      [types addObject:typeValue];
    }
    [types addObjectsFromArray:[self _filteredTypesFromType:el]];
  }
  return AUTORELEASE(types);
}

- (NSString *)_includeNameWithPath:(NSString *)_path {
  NSMutableString *iName;

  iName = [[NSMutableString alloc] initWithString:@"__"];
  if (_path) {
    [iName appendString:_path];
    [iName appendString:@"_"];
  }
  [iName appendString:[self className]];
  [iName appendString:@"_H__"];
  
  return AUTORELEASE(iName);
}

- (void)_appendStartIncludeConditionalWithPath:(NSString *)_path {
  NSString *iName;

  iName = [self _includeNameWithPath:_path];
  [self->string appendString:@"#ifndef "];
  [self->string appendString:iName];
  [self->string appendString:@"\n"];
  [self->string appendString:@"#define "];
  [self->string appendString:iName];
  [self->string appendString:@"\n\n"];
}

- (void)_appendEndIncludeConditionalWithPath:(NSString *)_path {
  [self->string appendString:@"#endif /* "];
  [self->string appendString:[self _includeNameWithPath:_path]];
  [self->string appendString:@" */\n"];
}

- (void)_appendClasses {
  NSEnumerator *typeEnum;
  NSString     *typeValue;

  typeEnum = [[self _filteredTypesFromType:self->type] objectEnumerator];
  
  while ((typeValue = [typeEnum nextObject])) {
    NSString *cName;

    if ((cName = [XmlClassGenerator classNameForType:typeValue])) {
      [self->string appendString:@"@class "];
      [self->string appendString:cName];
      [self->string appendString:@";\n"];
    }
  }
  [self->string appendString:
       @"@class NSString, NSNumber, NSCalendarDate, "
       @"NSData, NSArray;\n\n"];
}

- (void)_appendInstanceVariables {
  NSEnumerator *nameEnum;
  unsigned     maxLength;
  NSString     *name;

  maxLength = [self _maxClassNameLength];

  // append attribut variables
  [self->string appendString:@"// attributes\n"];
  nameEnum  = [[self->type attributeNames] objectEnumerator];
  while ((name = [nameEnum nextObject])) {
    [self->string appendString:@"  NSString *"];
    [self->string appendString:name];
    [self->string appendString:@";\n"];
    if (maxLength < 8) maxLength = 8;
  }

  [self->string appendString:@"// elements\n"];
  nameEnum  = [[self->type elementNames] objectEnumerator];
  while ((name = [nameEnum nextObject])) {
    XmlSchemaElement *el;
    NSString         *cName;
    int              i, len;

    cName = [self _classNameFromElement:[self->type elementWithName:name]];
    len   = maxLength - [cName length] + 1;
    el    = [self->type elementWithName:name];
    
    [self->string appendString:@"  "];
    [self->string appendString:cName];
    for (i=0; i<len; i++) {
      [self->string appendString:@" "];
    }
    if (![cName isEqualToString:@"id"])
      [self->string appendString:@"*"];
    [self->string appendString:[self _nameWithElement:el]];
    [self->string appendString:@";\n"];
  }
}

- (void)_appendIncludes {
  NSEnumerator *typeEnum;
  NSString     *typeValue;

  typeEnum = [[self _filteredTypesFromType:self->type] objectEnumerator];

  [self->string appendString:@"#include <Foundation/Foundation.h>\n"];
  while ((typeValue = [typeEnum nextObject])) {
    NSString *cName;

    if ((cName = [XmlClassGenerator classNameForType:typeValue])) {
      [self->string appendString:@"#include \""];
      [self->string appendString:cName];
      [self->string appendString:@".h\"\n"];
    }
  }
  [self->string appendString:@"\n"];
}

- (void)_appendAccessorDeclarations {
  NSEnumerator *nameEnum;
  NSString     *name;

  [self->string appendString:@"// attributes\n"];
  nameEnum = [[self->type attributeNames] objectEnumerator];
  while ((name = [nameEnum nextObject])) {
    // append -(void)set... methode
    [self->string appendString:@"- (void)set"];
    [self->string appendString:[name firstLetterUpperCase]];
    [self->string appendString:@":(NSString *)_"];
    [self->string appendString:name];
    [self->string appendString:@";\n"];

    // append -(NSString *)... method
    [self->string appendString:@"- (NSString *)"];
    [self->string appendString:name];
    [self->string appendString:@";\n\n"];
  }

  [self->string appendString:@"// elements\n"];
  nameEnum = [[self->type elementNames] objectEnumerator];
  while ((name = [nameEnum nextObject])) {
    NSString *cName;

    cName = [self _classNameFromElement:[self->type elementWithName:name]];
    if (![cName isEqualToString:@"id"])
      cName = [cName stringByAppendingString:@" *"];

    name = [self _nameWithElement:[self->type elementWithName:name]];
    // append -(void)set... methode
    [self->string appendString:@"- (void)set"];
    [self->string appendString:[name firstLetterUpperCase]];
    [self->string appendString:@":("];
    [self->string appendString:cName];
    [self->string appendString:@")_"];
    [self->string appendString:name];
    [self->string appendString:@";\n"];

    // append -(type)... method
    [self->string appendString:@"- ("];
    [self->string appendString:cName];
    [self->string appendString:@")"];
    [self->string appendString:name];
    [self->string appendString:@";\n\n"];
  }
}

- (void)_appendAccessorDefinitions {
  NSEnumerator *nameEnum;
  NSString     *name;


  [self->string appendString:@"// attributes\n"];
  nameEnum = [[self->type attributeNames] objectEnumerator];
  while ((name = [nameEnum nextObject])) {
    // append -(void)set... methode
    [self->string appendString:@"- (void)set"];
    [self->string appendString:[name firstLetterUpperCase]];
    [self->string appendString:@":(NSString *)_"];
    [self->string appendString:name];
    [self->string appendString:@" {\n"];
    [self->string appendString:@"  ASSIGNCOPY(self->"];
    [self->string appendString:name];
    [self->string appendString:@", _"];
    [self->string appendString:name];
    [self->string appendString:@");\n"];
    [self->string appendString:@"}\n"];

    // append -(NSString *)... method
    [self->string appendString:@"- (NSString *)"];
    [self->string appendString:name];
    [self->string appendString:@" {\n"];
    [self->string appendString:@"  return self->"];
    [self->string appendString:name];
    [self->string appendString:@";\n"];
    [self->string appendString:@"}\n\n"];
  }


  [self->string appendString:@"// elements\n"];
  nameEnum = [[self->type elementNames] objectEnumerator];
  while ((name = [nameEnum nextObject])) {
    NSString *cName;

    cName = [self _classNameFromElement:[self->type elementWithName:name]];
    if (![cName isEqualToString:@"id"])
      cName = [cName stringByAppendingString:@" *"];

    name = [self _nameWithElement:[self->type elementWithName:name]];
    // append -(void)set... methode
    [self->string appendString:@"- (void)set"];
    [self->string appendString:[name firstLetterUpperCase]];
    [self->string appendString:@":("];
    [self->string appendString:cName];
    [self->string appendString:@")_"];
    [self->string appendString:name];
    [self->string appendString:@" {\n"];
    [self->string appendString:@"  ASSIGN(self->"];
    [self->string appendString:name];
    [self->string appendString:@", _"];
    [self->string appendString:name];
    [self->string appendString:@");\n"];
    [self->string appendString:@"}\n"];

    // append -(type)... method
    [self->string appendString:@"- ("];
    [self->string appendString:cName];
    [self->string appendString:@")"];
    [self->string appendString:name];
    [self->string appendString:@" {\n"];
    [self->string appendString:@"  return self->"];
    [self->string appendString:name];
    [self->string appendString:@";\n"];
    [self->string appendString:@"}\n\n"];
  }
}

- (void)_appendDealloc {
  NSEnumerator *nameEnum;
  NSString     *name;

  [self->string appendString:@"#if !LIB_FOUNDATION_BOEHM_GC\n"];
  [self->string appendString:@"- (void)dealloc {\n"];

  nameEnum = [[self->type attributeNames] objectEnumerator];
  while ((name = [nameEnum nextObject])) {
    [self->string appendString:@"  RELEASE(self->"];
    [self->string appendString:name];
    [self->string appendString:@");\n"];
  }

  nameEnum = [[self->type elementNames] objectEnumerator];
  while ((name = [nameEnum nextObject])) {
    name = [self _nameWithElement:[self->type elementWithName:name]];
    [self->string appendString:@"  RELEASE(self->"];
    [self->string appendString:name];
    [self->string appendString:@");\n"];
  }
  [self->string appendString:@"  [super dealloc];\n"];
  [self->string appendString:@"}\n"];
  [self->string appendString:@"#endif\n\n"];
}

- (void)_appendDefaultSchemaMethods {
  [self->string appendString:@"\n/* ------------------------ */\n\n"];
  [self->string appendString:@"- (NSString *)_defaultXmlSchemaFile {\n"];
  [self->string appendString:@"  return "];
  if (self->schemaPath != nil) {
    [self->string appendString:@"@\""];
    [self->string appendString:self->schemaPath];
    [self->string appendString:@"\";\n"];
  }
  else {
    [self->string appendString:@"nil; // schema path is unknown\n"];
  }
  [self->string appendString:@"}\n\n"];

  if ([self->type isKindOfClass:[XmlSchemaElement class]])
    [self->string appendString:@"- (NSString *)_defaultXmlElementName {\n"];
  else
    [self->string appendString:@"- (NSString *)_defaultXmlTypeName {\n"];
    
  [self->string appendString:@"  return @\""];
  [self->string appendString:[self->type name]];
  [self->string appendString:@"\";\n"];
  [self->string appendString:@"}\n\n"];

  if ([self->prefix length]) {
    [self->string appendString:@"- (NSString *)_classPrefix {\n"];
    [self->string appendString:@"  return @\""];
    [self->string appendString:self->prefix];
    [self->string appendString:@"\";\n"];
    [self->string appendString:@"}\n\n"];
  }
}

- (void)_writeToFile:(NSString *)_path {
#if 0
  NSFileManager *fm = [NSFileManager defaultManager];
  NSString *path;

  path = [_path stringByDeletingLastPathComponent];
  if (![fm fileExistsAtPath:path]) {
    NSArray      *dirs   = [path componentsSeparatedByString:@"/"];
    NSEnumerator *dirEnm = [dirs objectEnumerator];

    path = [dirEnm nextObject];
    while ((dir = [dirEnm nextObject])) {
      if (![fm fileExistsAtPath:path]) {
        [fm createFile
      }
      path = [path stringByAppendingString:@"/"];
      path = [path stringByAppendingString:dir];
    }
    
  }
#endif  
  
  [self->string writeToFile:_path atomically:YES];
}

- (NSString *)_classNameFromElement:(XmlSchemaElement *)_element {
  NSString *typeValue = [_element type];
  static NSDictionary *type2className = nil;

  if (typeValue == nil) return @"id";
  
  if (type2className == nil) {
    type2className = [[NSDictionary alloc] initWithObjectsAndKeys:
                                         @"NSString", @"string",
                                         @"NSNumber", @"int",
                                         @"NSNumber", @"double",
                                         @"NSNumber", @"float",
                                         @"NSNumber", @"long",
                                         @"NSNumber", @"short",
                                         @"NSNumber", @"byte",
                                         @"NSNumber", @"boolean",
                                         @"NSNumber", @"nonNegativeInteger",
                                         @"NSNumber", @"decimal",
                                         @"NSNumber", @"integer",
                                         @"NSNumber", @"nonPositiveInteger",
                                         @"NSNumber", @"negativeInteger",
                                         @"NSNumber", @"unsignedLong",
                                         @"NSNumber", @"unsignedInt",
                                         @"NSNumber", @"unsignedShort",
                                         @"NSNumber", @"unsignedByte",
                                         @"NSNumber", @"positiveInteger",
                                         @"NSString", @"string",
                                         @"NSData  ", @"base64",
                                         @"NSCalendarDate", @"dateTime", nil];
  }

  if (![_element isScalar])
    typeValue = @"NSArray";
  else if ([XmlSchema isXmlSchemaNamespace:[typeValue uriFromQName]])
    typeValue = [type2className objectForKey:[typeValue valueFromQName]];
  else
    typeValue = [XmlClassGenerator classNameForType:typeValue];

  if (typeValue == nil) typeValue = @"id";
  return typeValue;
}
 
- (NSString *)_nameWithElement:(XmlSchemaElement *)_element {
  return [XmlDefaultClassSchemaMapping nameFromElement:_element];
}

@end /* XmlClassGenerator(PrivateMethods) */

@implementation NSString(XmlClassGenerator)
- (NSString *)firstLetterUpperCase {
  NSString *result;

  if ([self length] == 0) return @"";

  result = [[self substringToIndex:1] uppercaseString];
  result = [result stringByAppendingString:[self substringFromIndex:1]];
  
  return result;
}
@end
