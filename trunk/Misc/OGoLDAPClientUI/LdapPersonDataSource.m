
#include "common.h"
#include "LdapPersonDocument.h"
#include "LdapPersonDataSource.h"

@implementation LdapPersonDataSource

// Anonymous LDAP access.

- (id)init {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  self = [super initWithBaseDN:[ud objectForKey:@"LdapViewer_Base"]
                host:[ud objectForKey:@"LdapViewer_Host"]
                port:389
                bindDN:@""
                credentials:@""];
  return self;
}

// Init and bind the connection to a DN.

- (id)initWithUID:(NSString *)_uid credentials:(NSString *)_password {
  NSUserDefaults *ud  = [NSUserDefaults standardUserDefaults];
  NSString       *bdn = nil;

  bdn = [ud objectForKey:@"LdapViewer_Base"];
  bdn = [bdn stringByAppendingDNComponent:
             [@"uid=" stringByAppendingString:[_uid stringValue]]];
  
  self = [super initWithBaseDN:[ud objectForKey:@"LdapViewer_Base"]
                host:[ud objectForKey:@"LdapViewer_Host"]
                port:389
                bindDN:bdn
                credentials:_password];
  return self;
}

- (Class)documentClass {
  return [LdapPersonDocument class];
}

- (BOOL)_shouldCheckLastPathComponent {
  return YES;
}

- (NSArray *)objectClassNames {
  static NSArray *objClassNames = nil;

  if (objClassNames == nil) {
    objClassNames = 
      [[NSArray alloc] initWithObjects:@"SuSEeMailObject", @"inetOrgPerson",
                       @"top", @"person", @"organizationalPerson", nil];
  }
  return objClassNames;
}

@end // LdapPersonDataSource.
