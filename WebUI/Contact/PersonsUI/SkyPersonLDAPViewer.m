/*
  Copyright (C) 2000-2005 SKYRIX Software AG

  This file is part of OpenGroupware.org.

  OGo is free software; you can redistribute it and/or modify it under
  the terms of the GNU Lesser General Public License as published by the
  Free Software Foundation; either version 2, or (at your option) any
  later version.

  OGo is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or
  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
  License for more details.

  You should have received a copy of the GNU Lesser General Public
  License along with OGo; see the file COPYING.  If not, write to the
  Free Software Foundation, 59 Temple Place - Suite 330, Boston, MA
  02111-1307, USA.
*/

#include <OGoFoundation/OGoComponent.h>

@class NSString, NGLdapURL;

@interface SkyPersonLDAPViewer : OGoComponent
{
  NSString  *skyrixLogin;
  NSString  *dn;
  NGLdapURL *url;
}

@end

#include <NGLdap/NGLdap.h>
#include "common.h"

@implementation SkyPersonLDAPViewer

- (void)dealloc {
  [self->dn  release];
  [self->url release];
  [self->skyrixLogin release];
  [super dealloc];
}

/* accessors */

- (void)setSkyrixLogin:(NSString *)_login {
  // TODO: cleanup method
  NSUserDefaults   *ud;
  NSString         *ldapHost;
  NSString         *ldapBase;
  int              port;
  NGLdapConnection *con;
  NSEnumerator     *e;
    
  if ([_login isEqualToString:self->skyrixLogin])
    return;
    
  [self->dn  release]; self->dn  = nil;
  [self->url release]; self->url = nil;
    
  ASSIGNCOPY(self->skyrixLogin, _login);
    
  ud = [NSUserDefaults standardUserDefaults];
  port = [ud integerForKey:@"LSAuthLDAPServerPort"];
  if (port == 0) port = 389;

  ldapHost = [ud stringForKey:@"LSAuthLDAPServer"];
  if (ldapHost == nil) ldapHost = @"localhost";
    
  ldapBase = [ud stringForKey:@"LSAuthLDAPServerRoot"];
    
  if ((con = [[NGLdapConnection alloc]
	       initWithHostName:ldapHost port:port]) != nil) {
    NGLdapEntry *entry;
    EOQualifier *q;
    
    q = [EOQualifier qualifierWithQualifierFormat:@"uid=%@", _login];
      
    e = [con deepSearchAtBaseDN:ldapBase
	     qualifier:q
	     attributes:[NSArray arrayWithObject:@"uid"]];
    entry = [e nextObject];

    self->dn = [[entry dn] copy];
      
    [con release];
  }
  else {
    [self logWithFormat:@"could not alloc LDAP connection for host %@:%d",
	  ldapHost, port];
  }
    
  if (self->dn) {
    NSString *s;
      
    /* "ldap://host:port/dn?attributes?scope?filter?extensions" */
    s = [NSString stringWithFormat:@"ldap://%@:%i/%@",
		  ldapHost, port?port:389, self->dn];
    self->url = [[NGLdapURL alloc] initWithString:s];
  }
}
- (NSString *)skyrixLogin {
  return self->skyrixLogin;
}

/* regular accessors */

- (NSString *)dn {
  return self->dn;
}

- (NGLdapURL *)ldapURL {
  return self->url;
}
- (NSString *)ldapURLString {
  return [self->url urlString];
}

- (NSString *)viewerTitle {
  return [NSString stringWithFormat:@"%@ (%@)", [self skyrixLogin], [self dn]];
}

@end /* SkyPersonLDAPViewer */
