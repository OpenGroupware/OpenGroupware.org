/*
  Copyright (C) 2000-2004 SKYRIX Software AG

  This file is part of OGo

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
// $Id$

#include "OGoContextManager.h"
#include "OGoContextSession.h"
#include "LSCommandContext.h"
#include "LSBundleCmdFactory.h"
#include "common.h"
#include <NGLdap/NGLdapConnection.h>

/*
  Defaults:

    LSAuthLDAPServer      eg imap.mdlink.de
    LSAuthLDAPServerRoot  eg ou=people,o=mdlink.de
    LSAuthLDAPServerPort  eg 389

    always checks on 'uid'
*/

@interface LSCommandContext(LDAPSupportProto)
+ (BOOL)useLDAPAuthorization;
+ (BOOL)isLDAPLoginAuthorized:(NSString *)_login password:(NSString *)_pwd;
@end

@interface OGoContextManager(FailedLogin)
- (void)handleFailedAuthorization:(NSString *)_login;
@end

@implementation LSCommandContext(LDAPSupport)

static int UseLDAPAuth = -1;

+ (BOOL)useLDAPAuthorization {
  if (UseLDAPAuth == -1) {
    NSUserDefaults      *ud;
    
    ud = [NSUserDefaults standardUserDefaults];
    
    UseLDAPAuth = ([[ud stringForKey:@"LSAuthLDAPServer"] length] > 0)
      ? 1 : 0;
  }
  return (UseLDAPAuth == 1) ? YES : NO;
}

+ (BOOL)isLDAPLoginAuthorized:(NSString *)_login password:(NSString *)_pwd {
    static NSString *LDAPHost = nil;
    static NSString *LDAPRoot = nil;
    static int      LDAPPort  = -1;

    if (LDAPHost == nil || LDAPRoot == nil || LDAPPort == -1) {
      NSUserDefaults *ud;

      ud       = [NSUserDefaults standardUserDefaults];
      LDAPHost = [[ud stringForKey:@"LSAuthLDAPServer"] retain];
      LDAPRoot = [[ud stringForKey:@"LSAuthLDAPServerRoot"] retain];
      LDAPPort = [ud integerForKey:@"LSAuthLDAPServerPort"];
    }

    if ([_pwd length] == 0) {
      [self logWithFormat:@"missing password for authorization of login '%@'",
              _login];
      return NO;
    }
  
    if (![NGLdapConnection checkPassword:_pwd ofLogin:_login
                           atBaseDN:LDAPRoot onHost:LDAPHost port:LDAPPort]) {
      [self logWithFormat:
              @"%s: LDAP server '%@:%i' did not authenticate user '%@'",
              __PRETTY_FUNCTION__, LDAPHost, LDAPPort, _login];
      return NO;
    }
    else {
      [self logWithFormat:
              @"%s: LDAP server '%@:%i' did authenticate user '%@'",
              __PRETTY_FUNCTION__, LDAPHost, LDAPPort, _login];
    }

    return YES;
}

@end /* LSCommandContext(LDAPSupport) */

@implementation OGoContextManager(LDAPSupport)

- (BOOL)isLDAPLoginAuthorized:(NSString *)_login password:(NSString *)_pwd {
  NSString *key = nil;
  
  NSAssert(self->adContext, @"no adaptor context available");
  NSAssert(self->adChannel, @"no adaptor channel available");

  if (![LSCommandContext isLDAPLoginAuthorized:_login password:_pwd]) {
    [self handleFailedAuthorization:_login];
    return NO;
  }
  
  ASSIGN(self->lastAuthorized, key);
  [NSTimer scheduledTimerWithTimeInterval:600
           target:self selector:@selector(_expireCache:)
           userInfo:nil repeats:NO];
  return YES;
}

@end /* OGoContextManager(LDAPSupport) */
