// $Id$

#include "common.h"
#include "SkyPersonExporter.h"

@implementation SkyPersonExporter

static NSDictionary *AttrMapping = nil;

- (NSDictionary *)attributeMapping {
  if (AttrMapping == nil) {
    AttrMapping = [[NSDictionary alloc]
                                 initWithObjectsAndKeys:
                                 @"name",          @"sn",
                                 @"firstname",     @"givenName",
                                 @"description",   @"description",
                                 @"degree",        @"title",
                                 
                                 @"email1",        @"mail",

                                 @"03_tel_funk",   @"mobile",
                                 @"05_tel_private",@"homePhone",
                                 @"10_fax",        @"facsimileTelephoneNumber",
                                 @"01_tel",        @"telephoneNumber",
                                 
                                 @"addr_location_street",  @"street",
                                 @"addr_location_country", @"c",
                                 @"addr_location_state",   @"st",
                                 @"addr_location_city",    @"l",
                                 @"addr_location_zip",     @"postalCode",

                                 @"addr_mailing_name1",    @"o",
                                 @"addr_mailing_name2",    @"ou",
                                 @"addr_mailing_name3",    @"postalAddress",
                               nil];
  }
  return AttrMapping;
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
