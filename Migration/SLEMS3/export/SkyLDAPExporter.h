// $Id$

#ifndef __SkyLDAPExporter_H__
#define __SkyLDAPExporter_H__

#include "SkyExporter.h"

@class NGLdapConnection, NSString, NSString;

@interface SkyLDAPExporter : SkyExporter
{
  NGLdapConnection *connection;
  NSString         *ldapLogin;
  NSString         *ldapPwd;
  NSString         *ldapHost;
  NSString         *ldapBindDN;
  NSString         *ldapBaseDN;
  int              ldapPort;
}

- (NSString *)ldapBindDN;
- (NSString *)ldapPwd;
- (NSString *)ldapHost;
- (int)ldapPort;

- (BOOL)openConnection;
- (void)closeConnection;

- (NSArray *)fetchAttributes;
- (NSString *)searchBase;
- (BOOL)fetchDeep;
- (NSDictionary *)buildEntry:(NSDictionary *)_attrs;

- (EOQualifier *)searchQualifier;

- (BOOL)exportEntries;

@end /* SkyLDAPExporter */

#endif /* __SkyLDAPExporter_H__ */
