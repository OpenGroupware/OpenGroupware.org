// $Id$

#include <Foundation/Foundation.h>
#include "Person.h"
#include "SkyMasterConfig.h"

static void doit(void) {
  id person = nil;
  id config = nil;
  
  person = [[Person alloc] initWithContentsOfFile:@"person.xml"];

  config =
    [[SkyMasterConfig alloc] initWithContentsOfFile:@"config.xml"];

  NSLog(@"config.checkinterval=%@", [config checkinterval]);

  NSLog(@"config.templates.defaultEntries = %@",
        [[config templates] valueForKey:@"defaultEntries"]);
  
  NSLog(@"person: %@", person);
  
  [person writeToFile:@"persondataout.xml" atomically:NO];
  [config writeToFile:@"configdataout.xml" atomically:NO];
  RELEASE(person);
  RELEASE(config);
}

int main(int argc, char **argv, char **env) { 
  NSAutoreleasePool *pool;
  
#if LIB_FOUNDATION_LIBRARY
  [NSProcessInfo initializeWithArguments:argv count:argc environment:env];
#endif

  pool = [[NSAutoreleasePool alloc] init];
  
  doit();
  
  RELEASE(pool);
  return 0;
}
