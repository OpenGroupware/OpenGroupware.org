/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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
// $Id$

#include <LSFoundation/LSCommandContext.h>
#include "common.h"

#include "OGoContextSession.h"
#include "OGoContextManager.h"

@implementation LSCommandContext(LoginStuff)

- (id)activeLogin {
  id login;
  
  if ((login = [self valueForKey:LSAccountKey]) == nil)
    return nil;

  if (![login isNotNull])
    return nil;

  return login;
}
- (NSString *)activeLoginName {
  NSString *login;
  
  login = [[self activeLogin] valueForKey:@"login"];
  if (![login isNotNull])
    return nil;
  
  return login;
}

- (BOOL)logout {
  NSString *tmp;
  NSString *login;
  NSAutoreleasePool *pool;
  
  if ((login = [self activeLoginName]) == nil)
    return NO;
  
  if ([self isTransactionInProgress]) {
    if (![self commit])
      return NO;
  }

  pool = [[NSAutoreleasePool alloc] init];;
  
  [self flush];
  
  tmp = [[login copy] autorelease];
  
  [self->extraVariables removeObjectForKey:LSAccountKey];
  
  [self debugWithFormat:@"logged out account '%@'.", tmp];
  
  [pool release];
  return YES;
}

- (BOOL)login:(NSString *)_login password:(NSString *)_pwd {
  return [self login:_login password:_pwd crypted:NO isSessionLogEnabled:YES];
}

- (BOOL)login:(NSString *)_login password:(NSString *)_pwd
  isSessionLogEnabled:(BOOL)_isSessionLogEnabled
{
  return [self login:_login password:_pwd crypted:NO
               isSessionLogEnabled:_isSessionLogEnabled];
}

- (BOOL)login:(NSString *)_login password:(NSString *)_pwd
  crypted:(BOOL)_crypted
{
  return [self login:_login password:_pwd crypted:_crypted
               isSessionLogEnabled:YES];
}

- (BOOL)login:(NSString *)_login password:(NSString *)_pwd
  crypted:(BOOL)_crypted isSessionLogEnabled:(BOOL)_isSessionLogEnabled
  superUserContext:(LSCommandContext *)_suContext
{
  id                loginAccount;
  NSString          *login;
  NSAutoreleasePool *p;
  
  p = [[NSAutoreleasePool alloc] init];
  
  if ((loginAccount = [self activeLogin])) {
    if (![self logout]) {
      [self logWithFormat:@"could not logout (tried to login)."];
      [p release];
      return NO;
    }
  }
  
  loginAccount = [self activeLogin];
  login        = [loginAccount valueForKey:@"login"];
  
  NSAssert(login        == nil, @"login is still set");
  NSAssert(loginAccount == nil, @"login account is still set");
  
  if ([_login length] < 1) {
    [self logWithFormat:@"login name is not valid (contains no chars)!"];
    [p release];
    return NO;
  }
  
#if 0
  if ([_pwd length] == 0)
    [self logWithFormat:@"WARNING: missing password!"];
#endif  
  
  loginAccount = [self runCommand:@"account::login",
                         @"login",    _login,
                         @"password", _pwd,
                         @"crypted",  [NSNumber numberWithBool:_crypted],
                         @"isSessionLogEnabled",
                         [NSNumber numberWithBool:_isSessionLogEnabled],
                         @"superUserContext", _suContext,
                         nil];
  loginAccount = RETAIN(loginAccount);
  [p release];
  [loginAccount autorelease];
  
  if ([self commit]) {
    [self debugWithFormat:@"account '%@' is logged in.", _login];
    return (loginAccount != nil) ? YES : NO;
  }
  else {
    return NO;
  }
}

- (BOOL)login:(NSString *)_login password:(NSString *)_pwd
  crypted:(BOOL)_crypted isSessionLogEnabled:(BOOL)_isSessionLogEnabled
{
  return [self login:_login password:_pwd crypted:_crypted
               isSessionLogEnabled:_isSessionLogEnabled
               superUserContext:nil];
}

- (LSCommandContext *)su_contextForLogin:(NSString *)_login
                     isSessionLogEnabled:(BOOL)_isSessionLogEnabled
{
  OGoContextManager *manager;
  OGoContextSession *session;
  LSCommandContext  *ctx;
  
  manager = (id)[OGoContextManager defaultManager];
  
  session = [[[OGoContextSession alloc] initWithManager:manager] autorelease];
  ctx = [session commandContext];
  if ([ctx login:_login password:@"" crypted:YES
           isSessionLogEnabled:_isSessionLogEnabled
           superUserContext:nil]) {
    // TODO: add s.th. in the logs
    return ctx;
  }
  else {
    NSLog(@"%s failed to create context for login: %@ as user %@",
          __PRETTY_FUNCTION__, _login, [self valueForKey:LSAccountKey]);
    return nil;
  }
}

@end /* LSCommandContext(LoginStuff) */
