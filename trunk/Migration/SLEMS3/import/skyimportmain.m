//$Id$

#include "common.h"
#include "SkyGroupImport.h"
#include "SkyAccountImport.h"
#include "SkyResourceImport.h"
#include "SkyPersonImport.h"
#include "SkyPrivatePersonImport.h"
#include "SkyAppImport.h"
#include "SkyJobImport.h"

int main(int argc, const char **argv, char **env) {
  NSAutoreleasePool *pool = nil;
  int rc;
  NSString *groupsPath;
  NSString *accountsPath;

  groupsPath   = @"groups";
  accountsPath = @"accounts";

  pool = [[NSAutoreleasePool alloc] init];
  
#if LIB_FOUNDATION_LIBRARY
  [NSProcessInfo initializeWithArguments:(void*)argv count:argc
                 environment:env];
#endif
#if 1
  {
    SkyGroupImport *imp;

    imp = [[SkyGroupImport alloc]
                           initWithGroupsPath:@"groups"];
    [imp import];
    RELEASE(imp); imp = nil;
  }
  {
    SkyAccountImport *imp;

    imp = [[SkyAccountImport alloc]
                             initWithAccountsPath:@"accounts"];
    [imp import];
    RELEASE(imp); imp = nil;
  }
#endif  
  {
    SkyResourceImport *imp;

    imp = [[SkyResourceImport alloc]
                              initWithResourcesPath:@"resources"
                              groupsPath:@"resource_groups"];
    [imp import];
    RELEASE(imp); imp = nil;
  }
  {
    SkyPersonImport *imp;

    imp = [[SkyPersonImport alloc]
                             initWithPersonsPath:@"public_persons"];
    [imp import];
    RELEASE(imp); imp = nil;
  }
  
  {
    SkyPrivatePersonImport *imp;

    imp = [[SkyPrivatePersonImport alloc]
                             initWithPersonsPath:@"private_persons"];
    [imp import];
    RELEASE(imp); imp = nil;
  }
  {
    SkyAppImport *imp;

    imp = [[SkyAppImport alloc]
                             initWithAppsPath:@"appointments"];
    [imp import];
    RELEASE(imp); imp = nil;
  }
  {
    SkyJobImport *imp;

    imp = [[SkyJobImport alloc]
                             initWithJobsPath:@"jobs"];
    [imp import];
    RELEASE(imp); imp = nil;
  }
  
  RELEASE(pool); pool = nil;

  return rc;
}

