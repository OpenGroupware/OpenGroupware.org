/*
  Copyright (C) 2000-2003 SKYRIX Software AG

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
//$Id$

#include <LSFoundation/OGoContextManager.h>
#include "common.h"

@implementation OGoContextManager(SkyAccountd)

- (BOOL)isLoginAuthorized:(NSString *)_login password:(NSString *)_pwd
  isCrypted:(BOOL)_crypted
{
  NSUserDefaults      *ud;
  NSMutableDictionary *row        = nil;
  NSString            *password   = nil;
  NSString            *cryptedPwd = nil;
  EOSQLQualifier      *qualifier  = nil;
  BOOL                isOk        = NO;

  ud = [NSUserDefaults standardUserDefaults];
  
  if (_crypted == YES) {
    NSLog(@"couldn`t perform LDAP-Login with crypted password");
    return NO;
  }

  if ([_login length] == 0) {
    [self logWithFormat:@"no login name provided for authorization check"];
    return NO;
  }

#if 0
  if ([LSCommandContext useLDAPAuthorization])
    return [self isLDAPLoginAuthorized:_login password:_pwd];
#endif  
  
  NSAssert(self->adContext, @"no adaptor context available");
  NSAssert(self->adChannel, @"no adaptor channel available");
  
  qualifier = [[EOSQLQualifier alloc]
                            initWithEntity:self->personEntity
                            qualifierFormat:@"(login = '%@') AND (isAccount=1)",
                              _login];
  AUTORELEASE(qualifier);
  
  if ([self->adChannel openChannel]) {
    if ([self->adContext beginTransaction]) {
      isOk = [self->adChannel selectAttributes:self->authAttributes
                              describedByQualifier:qualifier
                              fetchOrder:nil
                              lock:NO];
      if (isOk) {
        id obj;

        while ((obj = [self->adChannel fetchAttributes:authAttributes
                                       withZone:NULL]))
          row = obj;
        
        if (!(isOk = [self->adContext commitTransaction]))
          [self->adContext rollbackTransaction];
      }
      else
        [self->adContext rollbackTransaction];
      
      [self->adChannel closeChannel];

      if (!isOk) {
        [self logWithFormat:@"couldn't fetch login information .."];
        return NO;
      }
    }
    else {
      [self logWithFormat:@"couldn't begin database transaction"];
      [self->adChannel closeChannel];
      return NO;
    }
  }
  else {
    [self logWithFormat:@"couldn't open adaptor channel"];
    return NO;
  }

  if (row == nil) {
    [self logWithFormat:@"no user with login: %@", _login];
    return NO;
  }
  
  NSAssert(row, @"no row is set ..");

  password = [row objectForKey:@"password"];
  if (![password isNotNull]) {
    [self debugWithFormat:@"no password set for login %@.", _login];
    return ([_pwd length] == 0) ? YES : NO;
  }

  // run crypt command
  if (_crypted == NO) {
    id cryptCmd;

    cryptCmd = [self->cmdFactory command:@"crypt" inDomain:@"system"];
    NSAssert(cryptCmd, @"couldn't lookup crypt command !");
    
    [cryptCmd takeValue:_pwd     forKey:@"password"];
    [cryptCmd takeValue:password forKey:@"salt"];
    cryptedPwd = [cryptCmd runInContext:nil];
  }
  else {
    cryptedPwd = _pwd;
  }
  if ([cryptedPwd isEqualToString:password]) {
    return YES;
  }
  else {
    [self logWithFormat:@" pwd '%s' != '%s' (len=%i vs len=%i)",
            [cryptedPwd cString],
            [password cString],
            [cryptedPwd cStringLength],
            [password cStringLength]];
    [self logWithFormat:@"login for user %@ wasn't authorized.", _login];
    return NO;
  }
}

@end
