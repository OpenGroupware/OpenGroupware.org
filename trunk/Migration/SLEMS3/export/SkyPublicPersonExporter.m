
#include "common.h"
#include "SkyPublicPersonExporter.h"

@implementation SkyPublicPersonExporter

- (NSString *)searchBase {
  return [@"o=AddressBook," stringByAppendingString:[super searchBase]];
}

- (NSString *)primaryKeyForEntry:(NSDictionary *)_entry {
  return [[[[_entry objectForKey:@"dn"] lastDNComponent]
                    componentsSeparatedByString:@"="] lastObject];
}


static NSArray *Attrs = nil;

- (NSArray *)fetchAttributes {
  if (Attrs == nil) {
    Attrs = [[NSArray alloc]
                      initWithObjects:
                      @"dn",
                      @"c",
                      @"cn",
                      @"description",
                      @"facsimileTelephoneNumber",
                      @"givenName",
                      @"homePhone",
                      @"initials",
                      @"l",
                      @"mail",
                      @"mobile",
                      @"o",
                      @"ou",
                      @"postalAddress",
                      @"postalCode",
                      @"sn",
                      @"st",
                      @"street",
                      @"telephoneNumber",
                      @"title",
                      nil];
  }
  return Attrs;
}

- (BOOL)fetchDeep {
  return NO;
}

- (NSDictionary *)buildEntry:(NSDictionary *)_attrs {
  return _attrs;
}
/*
  objectclass=doof
*/

- (EOQualifier *)searchQualifier {
  return
    [EOQualifier qualifierWithQualifierFormat:
                 @"objectclass=organizationalPerson"];
}


@end /* SkyPersonExporter */
