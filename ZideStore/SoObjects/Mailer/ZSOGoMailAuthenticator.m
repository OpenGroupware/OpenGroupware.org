/*
  Copyright (C) 2005 SKYRIX Software AG

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

#include "ZSOGoMailAuthenticator.h"
#include "ZSOGoMailAccount.h"
#include "SOGoMailManager.h"
#include "common.h"

@implementation ZSOGoMailAuthenticator

- (id)initWithMailAccount:(ZSOGoMailAccount *)_account context:(id)_ctx {
  if ((self = [super init])) {
    self->account = [_account retain];
  }
  return self;
}

- (void)dealloc {
  [self->account release];
  [super dealloc];
}

/* parent */

- (id)parentAuthenticator {
  return [[self->account container] authenticatorInContext:self->context];
}

- (BOOL)checkLogin:(NSString *)_login password:(NSString *)_pwd {
  id client;

  [self logWithFormat:@"CHECK LOGIN: %@", _login];
  
  client = [[self->account mailManager] imap4ClientForURL:
					  [self->account imap4URL] 
					password:_pwd];
  if (client == nil)
    return NO;
  if ([client isKindOfClass:[NSException class]]) {
    [self logWithFormat:@"ERROR: could not login: %@", client];
    return NO;
  }
  return YES;
}

/* user management */

#if 1
- (SoUser *)userInContext:(WOContext *)_ctx {
  [self logWithFormat:@"LOOKUP USER ..."];
  return [super userInContext:_ctx];
}
- (NSArray *)rolesForLogin:(NSString *)_login {
  [self logWithFormat:@"LOOKUP ROLES OF %@ ...", _login];
  return [super rolesForLogin:_login];
}
#else
- (SoUser *)userInContext:(WOContext *)_ctx {
  return [[self parentAuthenticator] userInContext:_ctx];
}
- (NSArray *)rolesForLogin:(NSString *)_login {
  return [[self parentAuthenticator] rolesForLogin:_login];
}
#endif

/* ZideStore support */

- (id)commandContextInContext:(id)_ctx {
  return [[self parentAuthenticator] commandContextInContext:_ctx];
}

@end /* ZSOGoMailAuthenticator */
