// $Id$

#include "XmlSchemaSaxBuilder.h"
#include "XmlSchemaCoder.h"
#include "common.h"


int main(int argc, char **argv, char **env) {
  NSAutoreleasePool *pool;
  
#if LIB_FOUNDATION_LIBRARY
  [NSProcessInfo initializeWithArguments:argv count:argc environment:env];
#endif

  pool = [[NSAutoreleasePool alloc] init];

  // do something

  RELEASE(pool);
  
  return 0;
}
