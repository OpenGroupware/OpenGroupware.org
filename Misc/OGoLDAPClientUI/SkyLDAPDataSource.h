
#ifndef SKYRIX_SKYLDAP_SKYLDAPDATASOURCE_H
#define SKYRIX_SKYLDAP_SKYLDAPDATASOURCE_H

#import <EOControl/EODataSource.h>

@class NSString;
@class NGLdapConnection;
@class EOFetchSpecification;

@interface SkyLDAPDataSource : EODataSource
{
@protected
  NSString             *dn;
  NSString             *host;
  int                  port;
  NSString             *bindDN;
  NSString             *credentials;
  NGLdapConnection     *connection;
  EOFetchSpecification *fspec;
}

- (id)initWithBaseDN:(NSString *)_dn
                host:(NSString *)_host
                port:(int)_port
              bindDN:(NSString *)_bindDN
         credentials:(NSString *)_credentials;

- (Class)documentClass;

- (void)setFetchSpecification:(EOFetchSpecification *)_fs;
- (EOFetchSpecification *)fetchSpecification;

@end // SkyLDAPDataSource.

#endif /* SKYRIX_SKYLDAP_SKYLDAPDATASOURCE_H */
