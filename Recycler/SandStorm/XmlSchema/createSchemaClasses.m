
#include "XmlClassGenerator.h"
#include "common.h"

void createSchemaClasses(NSArray *_args) {
  NSString *schemaPath = nil;
  NSString *bundlePath = nil;
  NSString *prefix     = nil;
  unsigned cnt         = [_args count];

  if (cnt == 0)
    return;
  
  schemaPath = [_args objectAtIndex:0];

  if (cnt > 1)
    prefix = [_args objectAtIndex:1];
  if (cnt > 2)
    bundlePath = [_args objectAtIndex:2];
  
  [XmlClassGenerator generateClassFilesFromSchemaAtPath:schemaPath
                     bundlePath:bundlePath
                     prefix:prefix];
}

int main(int argc, char **argv, char **env) { 
  NSAutoreleasePool *pool;
  NSArray           *args;
  
#if LIB_FOUNDATION_LIBRARY
  [NSProcessInfo initializeWithArguments:argv count:argc environment:env];
#endif

  pool = [[NSAutoreleasePool alloc] init];

  args = [[NSProcessInfo processInfo] arguments];
  args = [args subarrayWithRange:NSMakeRange(1, [args count] -1)];

  createSchemaClasses(args); // (@"person.xsd", @"prefix", @"bundlePath");

  RELEASE(pool);

  return 0;
}
