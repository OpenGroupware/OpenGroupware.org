
#include <NGLdap/NGLdap.h>
#include "common.h"
#include "LdapPersonDocument.h"
#include "LdapPersonDataSource.h"

@implementation LdapPersonDocument

+ (Class)dataSourceClass {
  return [LdapPersonDataSource class];
}

- (id)initWithDN:(NSString *)_dn newDocument:(BOOL)_new {
  if (![_dn length]) {
    NSLog(@"%s missing dn", __PRETTY_FUNCTION__);
    return nil;
  }

  if ((self = [super initWithDN:_dn newDocument:_new])) {
    [self load];

    return self;
  }
  return nil;
}

@end // LdapPersonDocument.

@implementation LdapPersonDocument(Internals)

- (NSString *)uniqueId {
  return @"uid";
}

@end // LdapPersonDocument(Internals).
