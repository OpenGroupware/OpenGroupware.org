// $Id$

#ifndef SKYRIX_SKYLDAP_SKYLDAPFILEMANAGER_H
#define SKYRIX_SKYLDAP_SKYLDAPFILEMANAGER_H

#import <Foundation/NSObject.h>
#import <NGExtensions/NGFileManager.h>
#import <NGExtensions/NSFileManager+Extensions.h>

@class NSString, NSDictionary, NSData, NSArray;
@class NGLdapConnection;

@interface SkyLDAPFileManager : NGFileManager
{
  NGLdapConnection *connection;
  NSString         *rootDN;
  NSString         *currentDN;
  NSString         *currentPath;
}


@end

#endif /* SKYRIX_SKYLDAP_SKYLDAPFILEMANAGER_H */
