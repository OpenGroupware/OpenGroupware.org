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

#include "SkyAccountAction.h"
#include "SkyAccountApplication.h"
#include "NSObject+EKVC.h"
#include "common.h"

@implementation SkyAccountAction(AccountActions)

- (void)setAccountValues:(id)_account toDBObj:(id)_dbObj {
  NSEnumerator        *dbEnum, *accEnum;
  id                  obj, dbKey, accKey;

  dbEnum  = [[self dbKeys] objectEnumerator];
  accEnum = [[self accountKeys] objectEnumerator];

  while ((dbKey = [dbEnum nextObject]) && (accKey = [accEnum nextObject])) {
    if ([accKey isEqualToString:@"uid"])
      continue;
    
    if ([(obj = [_account valueForKey:accKey]) isNotNull]) {
      [_dbObj takeValue:obj forKey:dbKey];
    }
  }
}

- (NSMutableDictionary *)_buildAccountFromDB:(id)_account {
  NSEnumerator        *dbEnum, *accEnum;
  NSMutableDictionary *dict;
  id                  obj, dbKey, accKey;

  dbEnum  = [[self dbKeys] objectEnumerator];
  accEnum = [[self accountKeys] objectEnumerator];
  dict    = [NSMutableDictionary dictionaryWithCapacity:8];

  while ((dbKey = [dbEnum nextObject]) && (accKey = [accEnum nextObject])) {
    if ([(obj = [_account valueForKey:dbKey]) isNotNull]) {
      if ([accKey isEqualToString:@"uid"])
        obj = [obj stringValue];

      [dict setObject:obj forKey:accKey];
    }
  }
  return dict;
}

- (id)_getAccountById:(NSString *)_uid {
  id acc;

  if (![_uid length])
    return nil;
  
  acc = [[self commandContext]
                runCommand:@"account::get",
                @"companyId", [NSNumber numberWithInt:[_uid intValue]],
                @"suppressAdditionalInfos", [NSNumber numberWithBool:YES],
                nil];
  return [acc isKindOfClass:[NSArray class]]?[acc lastObject]:acc;
}

- (id)_getAccountsForIds:(NSArray *)_uids {
  NSEnumerator   *enumerator;
  id             uid;
  NSMutableArray *array;

  array      = [NSMutableArray array];
  enumerator = [_uids objectEnumerator];


  while ((uid = [enumerator nextObject])) {
    [array addObject:[self _getAccountById:uid]];
  }
  return array;
}

/* actions */

- (NSNumber *)authenticateAction:(NSString *)_login :(NSString *)_pwd
{
  if ([[[self application] lso] isLoginAuthorized:_login
                                password:[_pwd stringByDecodingBase64]]) {
    return [NSNumber numberWithInt:0];
  }
  return [NSNumber numberWithInt:1];
}


- (NSDictionary *)getAccountAction:(NSString *)_uid
{
  return [[self application] accountById:_uid];
}

- (NSDictionary *)getAccountByLoginAction:(NSString *)_login
{
  return [[self application] accountByLogin:_login];
}

- (id)changePasswordAction:(NSString *)_uid
                          :(NSString *)_newPwd
                          :(NSString *)_oldPwd
{
  NSString *pwd, *cryptPwd;
  id       account;
  id       ctx;

  if ((([_uid intValue] != [self loginId]) || (_uid = nil)) &&
      (![self isRoot])) {
    return [self buildExceptonWithNumber:1
                 reason:@"only root can change passwords for foreign uids"
                 command:__PRETTY_FUNCTION__];
  }

  if (_uid == nil)
    _uid = [NSString stringWithFormat:@"%d", [self loginId]];

  if (!(account = [self _getAccountById:_uid])) {
    return [self buildExceptonWithNumber:3
                 reason:@"couldn fetch account"
                 command:__PRETTY_FUNCTION__];
  }
  ctx     = [self commandContext];
  _newPwd = [_newPwd stringByDecodingBase64];
  _oldPwd = [_oldPwd stringByDecodingBase64];

  if (![_oldPwd isNotNull])
    _oldPwd = nil;

  if (![self isRoot]) {
    pwd      = [account valueForKey:@"password"];
    cryptPwd = [ctx runCommand:@"system::crypt",
                    @"password", _oldPwd,
                    @"salt", pwd, nil];

    if (![pwd isEqualToString:cryptPwd]) {
      return [self buildExceptonWithNumber:1
                   reason:@"authentication error" command:__PRETTY_FUNCTION__];
    }
  }
  cryptPwd = [ctx runCommand:@"system::crypt",
                  @"password", _newPwd, nil];
  [account takeValue:cryptPwd forKey:@"password"];

  if (![[self commandContext] runCommand:@"account::set",
                              @"object", account,
                              @"primaryInsert", [NSNumber numberWithBool:YES],
                              nil]) {
    return [self buildExceptonWithNumber:2
                 reason:@"account::set failed" command:__PRETTY_FUNCTION__];
  }
  [[self application] flushContextForLogin:[self login]];
  return [NSNumber numberWithBool:YES];
}

- (id)createAccountAction:(NSDictionary *)_account {
  id       account;
  NSString *l;
  NSMutableDictionary *dict;

  dict = [NSMutableDictionary dictionaryWithCapacity:
                              [[self  accountKeys] count]];
  {
    NSEnumerator *enumerator;
    id           obj, key;

    enumerator = [[self accountKeys] objectEnumerator];
    while ((key = [enumerator nextObject])) {
      if ((obj = [_account objectForKey:key])) {
        [dict setObject:obj forKey:key];
      }
    }
  }
  if (![self isRoot]) {
    return [self buildExceptonWithNumber:1
                 reason:@"only root can create accounts"
                 command:__PRETTY_FUNCTION__];
  }
  if (!([l = [_account objectForKey:@"login"] length])) {
    return [self buildExceptonWithNumber:4
                 reason:@"Missing reqiered attributes"
                 command:__PRETTY_FUNCTION__];
  }
  if ([[self application] accountByLogin:l]) {
    return [self buildExceptonWithNumber:4
                 reason:@"login is already used"
                 command:__PRETTY_FUNCTION__];
  }
  if (!(account = [[self commandContext] runCommand:@"account::new"
                                         arguments:_account])) {
    return [self buildExceptonWithNumber:2
                 reason:@"account::new failed" command:__PRETTY_FUNCTION__];
  }
  [[self application] insertAccount:[self _buildAccountFromDB:account]];
  return [NSNumber numberWithBool:YES];
}

- (id)updateAccountAction:(NSString *)_uid :(NSDictionary *)_account {
  id       account;
  NSString *oldLogin;
  BOOL     containsLogin;

  containsLogin = [[_account allKeys] containsObject:@"login"];

  if (containsLogin && ![self isRoot]) {
    return [self buildExceptonWithNumber:1
                 reason:@"only root can change login"
                 command:__PRETTY_FUNCTION__];
  }
  if (([_uid intValue] != [self loginId]) && (![self isRoot])) {
    return [self buildExceptonWithNumber:1
                 reason:@"only root can change values for foreign uids"
                 command:__PRETTY_FUNCTION__];
  }
  if (!(account = [self _getAccountById:_uid])) {
    return [self buildExceptonWithNumber:3
                 reason:@"couldn`t fetch account"
                 command:__PRETTY_FUNCTION__];
  }
  oldLogin = nil;
  if (containsLogin) {
    oldLogin = [account valueForKey:@"login"];
  }
  [self setAccountValues:_account toDBObj:account];

  if (![[self commandContext] runCommand:@"account::set",
                              @"object", account,
                              @"primaryInsert", [NSNumber numberWithBool:YES],
                              nil]) {
    return [self buildExceptonWithNumber:2
                 reason:@"account::set failed" command:__PRETTY_FUNCTION__];
  }
  if (containsLogin) {
    [[self application] flushCachesForLogin:oldLogin];
  }
  [[self application] insertAccount:[self _buildAccountFromDB:account]];
  return [NSNumber numberWithBool:YES];
}

- (id)deleteAccountAction:(NSString *)_uid {
  id account;

  _uid = [_uid stringValue];
  
  if (![self isRoot]) {
    return [self buildExceptonWithNumber:1
                 reason:@"only root can delete accounts"
                 command:__PRETTY_FUNCTION__];
  }
  if (!(account = [self _getAccountById:_uid])) {
    return [self buildExceptonWithNumber:3
                 reason:@"couldn fetch account"
                 command:__PRETTY_FUNCTION__];
  }
  if (![[self commandContext] runCommand:@"account::delete",
                              @"object", account, nil]) {
    return [self buildExceptonWithNumber:2
                 reason:@"account::delete failed" command:__PRETTY_FUNCTION__];
  }
  
  [[self application] flushCachesForUid:_uid];
  return [NSNumber numberWithBool:YES];
}

- (id)isAccountLockedAction:(NSString *)_uid {
  id       acc;
  NSNumber *isL;
  
  if (![self isRoot]) {
    return [self buildExceptonWithNumber:1
                 reason:@"only root can lock accounts"
                 command:__PRETTY_FUNCTION__];
  }
  if (!(acc = [self _getAccountById:_uid])) {
    return [self buildExceptonWithNumber:3
                 reason:@"couldn`t fetch account"
                 command:__PRETTY_FUNCTION__];
  }
  isL = [acc valueForKey:@"isLocked"];
  if (![isL isNotNull])
    isL = [NSNumber numberWithBool:NO];

  return isL;
}

- (id)lockAccountAction:(NSString *)_uid {
  id       acc;
  
  if (![self isRoot]) {
    return [self buildExceptonWithNumber:1
                 reason:@"only root can lock accounts"
                 command:__PRETTY_FUNCTION__];
  }
  if (!(acc = [self _getAccountById:_uid])) {
    return [self buildExceptonWithNumber:3
                 reason:@"couldn`t fetch account"
                 command:__PRETTY_FUNCTION__];
  }
  [acc takeValue:[NSNumber numberWithBool:YES] forKey:@"isLocked"];
  if (![[self commandContext] runCommand:@"account::set",
                              @"object", acc,
                              @"primaryInsert", [NSNumber numberWithBool:YES],
                              nil]) {
    return [self buildExceptonWithNumber:2
                 reason:@"account::set failed" command:__PRETTY_FUNCTION__];
  }
  [[self application] flushContextForLogin:[acc valueForKey:@"login"]];
  return [NSNumber numberWithBool:YES];
}

- (id)unlockAccountAction:(NSString *)_uid {
  id       acc;
  
  if (![self isRoot]) {
    return [self buildExceptonWithNumber:1
                 reason:@"only root can lock accounts"
                 command:__PRETTY_FUNCTION__];
  }
  if (!(acc = [self _getAccountById:_uid])) {
    return [self buildExceptonWithNumber:3
                 reason:@"couldn`t fetch account"
                 command:__PRETTY_FUNCTION__];
  }
  [acc takeValue:[NSNumber numberWithBool:NO] forKey:@"isLocked"];
  if (![[self commandContext] runCommand:@"account::set",
                              @"object", acc,
                              @"primaryInsert", [NSNumber numberWithBool:YES],
                              nil]) {
    return [self buildExceptonWithNumber:2
                 reason:@"account::set failed" command:__PRETTY_FUNCTION__];
  }
  return [NSNumber numberWithBool:YES];
}

- (id)accountGroupsAction:(NSString *)_uid {
  return [[self application] groupsForAccount:_uid];
}


@end /* SkyAccountAction(AccountActions) */

