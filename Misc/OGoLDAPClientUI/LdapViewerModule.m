
#include <OGoFoundation/LSWModuleManager.h>

@interface LdapViewerModule : OGoModuleManager
@end

@implementation LdapViewerModule

+ (int)version {
  return 1;
}

- (void)_linkClasses {
}

@end /* LdapViewerModule */
