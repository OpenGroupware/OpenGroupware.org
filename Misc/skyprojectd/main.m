// $Id$

#include "common.h"

int main(int argc, const char **argv, char **env) {
  NSAutoreleasePool *pool;
  
  pool = [[NSAutoreleasePool alloc] init];
#if LIB_FOUNDATION_LIBRARY
  [NSProcessInfo initializeWithArguments:(void*)argv count:argc environment:env];
  [NSAutoreleasePool enableDoubleReleaseCheck:NO];
#endif
  NGInitTextStdio();

  {
    NSString *projectId = nil;
    
    projectId = [[NSUserDefaults standardUserDefaults] stringForKey:@"project"];
    
    if (projectId == nil || [projectId length] == 0) {
      NSLog(@"ERROR: Missing project identifier: "
            @"please use skyprojectd -project '__Project_Number__'");
      return 1;
    }
    
  }
  return WOWatchDogApplicationMain(@"Application", argc, argv);
}
