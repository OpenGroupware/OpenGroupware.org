
#ifndef SKYRIX_SKYLDAP_LDAPPERSONDATASOURCE_H
#define SKYRIX_SKYLDAP_LDAPPERSONDATASOURCE_H

#include "SkyLDAPDataSource.h"

@class NSString;

@interface LdapPersonDataSource : SkyLDAPDataSource

- (id)init;
- (id)initWithUID:(NSString *)_uid credentials:(NSString *)_password;

@end // LdapPersonDataSource.

#endif /* SKYRIX_SKYLDAP_LDAPPERSONDATASOURCE_H */
