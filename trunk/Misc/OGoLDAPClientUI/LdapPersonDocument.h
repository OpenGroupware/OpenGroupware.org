
#ifndef SKYRIX_SKYLDAP_LDAPPERSONDOCUMENT_H
#define SKYRIX_SKYLDAP_LDAPPERSONDOCUMENT_H

#include "SkyLDAPDocument.h"

@class NSDictionary;
@class NSMutableDictionary;
@class NSString;

@interface LdapPersonDocument: SkyLDAPDocument {
@protected
}

- (id)initWithDN:(NSString *)_dn newDocument:(BOOL)_new; // ?

@end

#endif /* SKYRIX_SKYLDAP_LDAPPERSONDOCUMENT_H */
