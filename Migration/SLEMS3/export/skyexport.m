//$Id$


#include "common.h"
#include "SkyAccountExporter.h"
#include "SkyGroupExporter.h"
#include "SkyResourceGroupExporter.h"
#include "SkyResourceExporter.h"
#include "SkyPublicPersonExporter.h"
#include "SkyPrivatePersonExporter.h"
#include "SkyAppExporter.h"
#include "SkyJobExporter.h"

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


  rc = 0;
  
  if (rc == 0) {
    SkyGroupExporter *exporter;
    exporter = [[SkyGroupExporter alloc] init];
    rc = [exporter exportToPath:groupsPath]?0:1;
    RELEASE(exporter);
  }
  if (rc == 0) {
    SkyAccountExporter *exporter;
    exporter = [[SkyAccountExporter alloc] initWithGroupsPath:groupsPath];
    rc = [exporter exportToPath:accountsPath]?0:2;
    RELEASE(exporter);
  }
  if (rc == 0) {
    SkyResourceGroupExporter *exporter;
    exporter = [[SkyResourceGroupExporter alloc] init];
    rc = [exporter exportToPath:@"resource_groups"]?0:3;
    RELEASE(exporter);
  }
  if (rc == 0) {
    SkyResourceExporter *exporter;
    exporter = [[SkyResourceExporter alloc] init];
    rc = [exporter exportToPath:@"resources"]?0:4;
    RELEASE(exporter);
  }
  if (rc == 0) {
    SkyPublicPersonExporter *exporter;
    exporter = [[SkyPublicPersonExporter alloc] init];
    rc = [exporter exportToPath:@"public_persons"]?0:5;
    RELEASE(exporter);
  }
  if (rc == 0) {
    SkyPrivatePersonExporter *exporter;
    exporter = [[SkyPrivatePersonExporter alloc]
                                          initWithAccountsPath:accountsPath];
    rc = [exporter exportToPath:@"private_persons"]?0:6;
    RELEASE(exporter);
  }
  if (rc == 0) {
    SkyAppExporter *exporter;
    exporter = [[SkyAppExporter alloc] initWithAccountsPath:accountsPath];
    [exporter  setExportDate:
              [NSCalendarDate dateWithString:@"2002-07-10 12:00:00 +0200"]];
    rc = [exporter exportToPath:@"appointments"]?0:7;
    RELEASE(exporter);
  }
  if (rc == 0) {
    SkyJobExporter *exporter;
    exporter = [[SkyJobExporter alloc] initWithAccountsPath:accountsPath];
    rc = [exporter exportToPath:@"jobs"]?0:8;
    RELEASE(exporter);
  }
  RELEASE(pool); pool = nil;
  return rc;
}

