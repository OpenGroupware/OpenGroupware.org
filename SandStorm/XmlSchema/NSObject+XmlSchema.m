// $Id$

#include "NSObject+XmlSchema.h"
#include "XmlDefaultClassSchemaMapping.h"
#include "XmlSchemaType.h"
#include "XmlSchema.h"
#include "common.h"

@interface NSObject(XmlSchemaPrivate)
- (NSString *)_defaultXmlSchemaFile;
- (NSString *)_defaultXmlElementName;
- (XmlSchema *)_defaultXmlSchema;
- (XmlSchemaType *)_defaultXmlRootType;
- (XmlSchemaMapping *)_defaultXmlSchemaMapping;
- (NSString *)_defaultXmlSchemaDirectory;
@end

@implementation NSObject(XmlSchema)

static NSMutableDictionary *file2mapping = nil;

- (id)initWithContentsOfFile:(NSString *)_file
  mapping:(XmlSchemaMapping *)_map
  rootType:(XmlSchemaType *)_rootType
{
  self = [XmlSchemaDecoder parseObjectFromContentsOfFile:_file
                           mapping:_map
                           rootType:_rootType];
  RETAIN(self);

  return self;
}

- (BOOL)writeToFile:(NSString *)_file
         atomically:(BOOL)_atomically
            mapping:(XmlSchemaMapping *)_mapping
           rootType:(XmlSchemaType *)_rootType
{
  if (_mapping && _rootType) {
    NSMutableString  *str     = nil;
    XmlSchemaEncoder *encoder = nil;
    BOOL             result   = NO;

    str     = [[NSMutableString alloc] initWithCapacity:512];
    [str appendString:@"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n\n"];
    encoder = [[XmlSchemaEncoder alloc] initForWritingWithMutableString:str];
    
    [encoder encodeObject:self
             mapping:_mapping
             rootType:_rootType];
  
    result = [str writeToFile:_file atomically:_atomically];
    
    RELEASE(str);
    RELEASE(encoder);

    return result;
  }
  return NO;
}

- (id)initWithContentsOfFile:(NSString *)_file {
  return [self initWithContentsOfFile:_file
               mapping:[self _defaultXmlSchemaMapping]
               rootType:[self _defaultXmlRootType]];
}

- (BOOL)writeToFile:(NSString *)_file atomically:(BOOL)_atomically {
  return [self writeToFile:_file
               atomically:_atomically
               mapping:[self _defaultXmlSchemaMapping]
               rootType:[self _defaultXmlRootType]];
}

- (NSString *)_defaultXmlSchemaFile {
  return nil;
}

- (NSString *)_defaultXmlElementName {
  return nil;
}

- (NSString *)_defaultXmlTypeName {
  return nil;
}

- (NSString *)_classPrefix {
  return nil;
}

- (XmlSchema *)_defaultXmlSchema {
  NSString *str;
  NSString *path;
  
  path = str = [self _defaultXmlSchemaFile];
  if ([str length] == 0)
    return nil;
  
  if (![str isAbsolutePath]) {
    NSBundle *bundle;
    
    if ((bundle = [NSBundle bundleForClass:[self class]])) {
      path = [bundle pathForResource:[str stringByDeletingPathExtension]
                     ofType:[str pathExtension]];
    }
    
    if ([path length] == 0) {
      path = [self _defaultXmlSchemaDirectory];
      path = [path stringByAppendingPathComponent:str];
      if (![[NSFileManager defaultManager] fileExistsAtPath:path])
        path = nil;
    }
    
    if ([path length] == 0)
      path = str;
  }
  
  return [[[XmlSchema alloc] initWithContentsOfFile:path] autorelease];
}

- (XmlSchemaMapping *)_defaultXmlSchemaMapping {
  XmlSchema                    *schema;
  XmlDefaultClassSchemaMapping *mapping;
  NSString                     *file;

  if (file2mapping == nil)
    file2mapping = [[NSMutableDictionary alloc] initWithCapacity:8];
  
  file = [self _defaultXmlSchemaFile];

  if (file != nil) {
    if ((mapping = [file2mapping objectForKey:file]) == nil) {
      schema  = [self _defaultXmlSchema];
      mapping = [[XmlDefaultClassSchemaMapping alloc] initWithSchema:schema];
      [mapping setClassPrefix:[self _classPrefix]];
      [file2mapping setObject:mapping forKey:file];
      AUTORELEASE(mapping);
    }
    return mapping;
  }
  else {
    schema  = [self _defaultXmlSchema];
    mapping = [[XmlDefaultClassSchemaMapping alloc] initWithSchema:schema];
    [mapping setClassPrefix:[self _classPrefix]];
    return AUTORELEASE(mapping);
  }
}

- (XmlSchemaType *)_defaultXmlRootType {
  XmlSchema     *schema;
  NSString      *str;
  XmlSchemaType *type = nil;

  schema = [[self _defaultXmlSchemaMapping] schema];

  if ((str = [self _defaultXmlElementName]))
    type = [schema elementWithName:str];
  else if ((str = [self _defaultXmlTypeName]))
    type = [schema typeWithName:str];

  return type;
}

- (NSString *)_defaultXmlSchemaDirectory {
  NSString      *apath;
  NSFileManager *fm = [NSFileManager defaultManager];
  NSDictionary  *env;
  NSString      *relPath;

  env  = [[NSProcessInfo processInfo] environment];
  relPath = @"Library";
  relPath = [relPath stringByAppendingPathComponent:@"XmlSchemes"];

#if COMPILE_AS_FRAMEWORK
#warning MacOSX support not complete here, use PathInDomain...
  apath = [env objectForKey:@"HOME"];
  apath = [apath stringByAppendingPathComponent:relPath];
#else
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
          @"of XmlSchema library !");\
  }
#endif

  return apath;
}

@end /* NSObject(XmlSchema) */
