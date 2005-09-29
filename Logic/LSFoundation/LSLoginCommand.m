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

#include "LSCommandKeys.h"
#include "LSLoginCommand.h"
#include "common.h"
#include <GDLAccess/EOSQLQualifier.h>

@implementation LSLoginCommand

+ (int)version {
  return 1;
}

- (void)dealloc {
  [self->login  release];
  [self->passwd release];
  [super dealloc];
}

- (EOSQLQualifier *)_qualifierForAccount {
  EOEntity       *accountEntity;
  EOSQLQualifier *qualifier;
    
  if ((accountEntity = [[self databaseModel] entityNamed:@"Person"]) == nil)
    return nil;
  
  qualifier = [[EOSQLQualifier alloc] initWithEntity:accountEntity
                                      qualifierFormat:
                                        @"(%A='%@') AND (%A=1)",
                                        @"login", self->login,
                                        @"isAccount"];
  [qualifier setUsesDistinct:YES];
  return [qualifier autorelease]; 
} 

- (void)_validateKeysForContext:(id)_context {
  [self assert:(self->passwd != nil) reason:@"no password set !"];
}

- (void)_checkCryptedPasswdInContext:(id)_context forUser:(id)_user {
  NSString *cryptedPasswd = nil;
  NSString *userPasswd;
  id       cCmd;
  
  userPasswd    = [_user valueForKey:@"password"];
  cCmd = LSCommandLookupV([self commandFactory],
                          @"system", @"crypt",
                          @"password", self->passwd,
                          @"salt",     userPasswd,
                          nil);
  cryptedPasswd = [cCmd runInContext:_context];
  [self assert:(cryptedPasswd != nil)
        reason:@"password check failed (missing password)."];
  
  [_context takeValue:cryptedPasswd forKey:LSCryptedUserPasswordKey];
  [self assert:[cryptedPasswd isEqualToString:userPasswd]
        reason:@"password check failed."];
}

- (void)_executeInContext:(id)_context {
  EODatabaseChannel *channel = nil;
  NSMutableArray    *users   = nil;
  id                user     = nil;

  channel = [self databaseChannel];
  users   = [NSMutableArray arrayWithCapacity:128];
  
  [self assert:[channel selectObjectsDescribedByQualifier:
                          [self _qualifierForAccount]
                        fetchOrder:nil]];
  while ((user = [channel fetchWithZone:nil]))
    [users addObject:user];
  user = [users lastObject];
  
  if ([users count] > 1)
    [self warnWithFormat:@"more than one user for login '%@'!", [self login]];
  
  [LSUserNotAuthorizedException raiseOnFail:(user != nil) object:self
                                reason:@"no permission to login"];

  [self _checkCryptedPasswdInContext:_context forUser:user];

  [_context takeValue:user forKey:LSAccountKey];

  [self setReturnValue:user];
}

- (void)setLogin:(NSString *)_login {
  ASSIGN(self->login, _login);
}
- (NSString *)login {
  return self->login;
}

- (void)setPasswd:(NSString *)_passwd {
  ASSIGN(self->passwd, _passwd);
}
- (NSString *)passwd {
  return self->passwd;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"login"])
    [self setLogin:_value];
  else if ([_key isEqualToString:@"password"])
    [self setPasswd:_value];
  else
    [self foundInvalidSetKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"login"])
    return [self login];
  else if ([_key isEqualToString:@"password"])
    return [self passwd];
  else
    return [super valueForKey:_key];
}

@end /* LSLoginCommand */

@implementation LSUserNotAuthorizedException

@end /* LSUserNotAuthorizedException */
