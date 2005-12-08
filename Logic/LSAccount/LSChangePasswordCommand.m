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

#include <LSAddress/LSSetCompanyCommand.h>


@class NSString;

/*
  The command does not check the old password.
  just crypts the password, if not yet crypted
  and sets it.
  Only allowed for account itself or root
  if not root password length must be at least 6 characters
  (this might not be valid if password already crypted)
  
   parameters:
     object/account
     newPassword/password
     isCrypted
*/

@interface LSChangePasswordCommand : LSSetCompanyCommand
{
@protected
  NSString *newPassword;
  NSString *oldPassword;
  NSString *newPlainTextPassword;
  BOOL     isCrypted;
}

@end

#include "common.h"
#include <NGLdap/NGLdap.h>

@implementation LSChangePasswordCommand

static int      UsePlainLdapPWD     = -1;
static int      WritePasswordToLDAP = -1;
static NSString *LDAPHost = nil;
static NSString *LDAPRoot = nil;
static int      LDAPPort  = 0;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

  if ((UsePlainLdapPWD = [ud boolForKey:@"UsePlainLdapPWD"] ? 1 : 0))
    NSLog(@"password::change: configured to use plain LDAP password.");
  
  if ((WritePasswordToLDAP = [ud boolForKey:@"WritePasswordToLDAP"]))
    NSLog(@"password::change: configured to write password to LDAP.");

  LDAPHost = [[ud stringForKey:@"LSWriteLDAPServer"]     copy];
  LDAPRoot = [[ud stringForKey:@"LSWriteLDAPServerRoot"] copy];
  LDAPPort = [ud integerForKey:@"LSWriteLDAPServerPort"];
  
  if (![LDAPHost isNotEmpty])
    LDAPHost = [[ud stringForKey:@"LSAuthLDAPServer"] copy];
  if (![LDAPRoot isNotEmpty])
    LDAPRoot = [[ud stringForKey:@"LSAuthLDAPServerRoot"] copy];
  if (LDAPPort == 0)
    LDAPPort = [ud integerForKey:@"LSAuthLDAPServerPort"];
  
  if (LDAPPort == 0)
    LDAPPort = 389;
}

- (NSNumber *)checkAccess {
  static NSNumber *NoNumber = nil;

  if (NoNumber == nil)
    NoNumber = [[NSNumber numberWithBool:NO] retain];

  return NoNumber;
}


- (void)dealloc {
  [self->oldPassword          release];
  [self->newPassword          release];
  [self->newPlainTextPassword release];
  [super dealloc];
}

/* support methods */

- (BOOL)isRootId:(int)_root inContext:(LSCommandContext *)_ctx {
  return _root == 10000 ? YES : NO;
}

/* writing to LDAP */

- (void)_writePasswordToLdap:(id)_context writeOnly:(BOOL)_wo {
  NSString         *login, *accLogin, *dn, *accDn, *authPwd;
  NGLdapConnection *con;
  BOOL             isRoot;
  id               acc, obj;
  
  acc      = [_context valueForKey:LSAccountKey];
  isRoot   = [self isRootId:[[acc valueForKey:@"companyId"] intValue]
                   inContext:_context];
  accLogin = [acc valueForKey:@"login"];
  obj      = [self object];
  login    = [obj valueForKey:@"login"];

  authPwd = isRoot // better: "isModifyingOtherUsersPwd"
    ? [_context valueForKey:@"LSUser_P_W_D_Key"]
    : self->oldPassword;
  
  if (![accLogin isEqualToString:login] && !isRoot) {
    if (!isRoot) {
      [self errorWithFormat:@"only root can change foreign password`s"];
      return;
    }
  }
  
  if (![login isNotEmpty]) {
    [self errorWithFormat:@"%s: missing login for %@", __PRETTY_FUNCTION__,
            [self object]];
    [self assert:NO reason:@"Missing login"];
    return;
  }

  {
    BOOL     res = NO, iC;
    NSString *invalidCredentials = @"invalid credentials";
    
    iC    = NO;
    dn    = nil;
    accDn = nil;
    con   = nil;
    
    NS_DURING {
      con = [[NGLdapConnection alloc] initWithHostName:LDAPHost
                                      port:LDAPPort];
      accDn  = [con dnForLogin:accLogin baseDN:LDAPRoot];
      dn     = [con dnForLogin:login baseDN:LDAPRoot];
      res    = [con bindWithMethod:@"simple" binddn:accDn
                    credentials:authPwd];
    }
    NS_HANDLER {
      fprintf(stderr, "Error[_makeConnectionWithContext:]: got exception %s "
              "host %s port %d \n", [[localException description] cString],
              [LDAPHost cString], LDAPPort);
      if ([[localException reason] isEqualToString:invalidCredentials])
        iC = YES;
      
      [con release]; con = nil;
    }
    NS_ENDHANDLER;

    if (iC) {
      [self assert:NO reason:@"Wrong ldap password"];
      return;
    }
    
    if (con == nil) {
      NSLog(@"ERROR[%s]: missing ldap-connection (host:%@; port:%d)",
            __PRETTY_FUNCTION__, LDAPHost, LDAPPort);
      [self assert:NO reason:@"Couldn`t connect to ldap server"];
      return;
    }
    if (!res) {
      NSLog(@"ERROR[%s] couldn't connect", __PRETTY_FUNCTION__);
      [self assert:NO reason:@"Wrong ldap password"];
      return;
    }
    [con setUseCache:NO];
  }
  {
    NSArray            *changes;
    NGLdapModification *mod;
    NGLdapAttribute    *attr;

    attr = [[NGLdapAttribute alloc] initWithAttributeName:@"userPassword"];

    if (UsePlainLdapPWD)
      [attr addStringValue:[self->newPlainTextPassword stringValue]];
    else {
      [attr addStringValue:[@"{crypt}" stringByAppendingString:
                                     self->newPassword]];
    }
    
    mod     = [NGLdapModification replaceModification:attr];
    changes = [NSArray arrayWithObject:mod];

    if (![con modifyEntryWithDN:dn changes:changes]) {
      NSLog(@"ERROR[%s]: modifyEntryWithDN: %@ changes:%@ failed",
            __PRETTY_FUNCTION__, dn, changes);
      [self assert:NO
            reason:@"Couldn`t modify password entry"];
      return;
    }
    [attr release]; attr = nil;
  }
  [con release]; con = nil;
  
  if (_wo == NO) {
    if (self->newPlainTextPassword != nil) {
      NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
      
      if ([ud boolForKey:@"UseSkyrixLoginForImap"] && !isRoot)
        [_context takeValue:self->newPlainTextPassword
                  forKey:@"LSUser_P_W_D_Key"];

      if ([accLogin isEqualToString:login] && isRoot)
        [_context takeValue:self->newPlainTextPassword
                  forKey:@"LSUser_P_W_D_Key"];
    }
  }
}

- (void)_prepareForExecutionInContext:(id)_context {
  id  obj = [self object];
  int accountId, activeAcc;

  ASSIGN(self->newPlainTextPassword, nil);
  
  [self assert:([self object] != nil)
        reason:@"no account object to act on"];

  accountId = [[obj valueForKey:@"companyId"] intValue];
  activeAcc = [[[_context valueForKey:LSAccountKey]
                          valueForKey:@"companyId"] intValue];
  [self assert:([self isRootId:activeAcc inContext:_context] || 
                (activeAcc == accountId))
        reason:@"Only root or user itself can change password."];

  [self assert:([self isRootId:activeAcc inContext:_context] ||
                ([self->newPassword length] > 5))
        reason:@"Password too short - must be at least 6 characters"];
  
  [super _prepareForExecutionInContext:_context];
  
  if ((!self->isCrypted) && [self->newPassword isNotEmpty]) {
    NSString *cryptedPasswd;
    
    cryptedPasswd = LSRunCommandV(_context,
                                  @"system",   @"crypt",
                                  @"password", self->newPassword,
                                  nil);
    ASSIGN(self->newPlainTextPassword, self->newPassword);
    ASSIGN(self->newPassword,cryptedPasswd);
  }
  if ([self->newPassword length])
    [[self object] takeValue:self->newPassword forKey:@"password"];
  else
    [[self object] takeValue:[NSNull null] forKey:@"password"];
}

- (void)_executeInContext:(id)_context {
  if ([LSCommandContext useLDAPAuthorization]) {
    [self _writePasswordToLdap:_context writeOnly:NO];
  }
  else {
    [super _executeInContext:_context];
    
    if (WritePasswordToLDAP)
      [self _writePasswordToLdap:_context writeOnly:YES];
  }
}

/* KVC */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"object"] ||
      [_key isEqualToString:@"account"]) {
    [self setObject:_value];
    return;
  }
  if ([_key isEqualToString:@"newPassword"] ||
           [_key isEqualToString:@"password"]) {
    ASSIGNCOPY(self->newPassword, _value);
    return;
  }
  if ([_key isEqualToString:@"oldPassword"]) {
    ASSIGNCOPY(self->oldPassword, _value);
    return;
  }
  if ([_key isEqualToString:@"isCrypted"]) {
    self->isCrypted = [_value boolValue];
    return;
  }
  if ([_key isEqualToString:@"logText"] ||
      [_key isEqualToString:@"logAction"]) {
    [super takeValue:_value forKey:_key];
    return;
  }
  
  [self warnWithFormat:@"%s: key %@ (value: %@) is not setable in "
        @"change-password command",
        __PRETTY_FUNCTION__, _key, _value];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"object"] ||
      [_key isEqualToString:@"account"]) {
    return [self object];
  }
  
  if ([_key isEqualToString:@"newPassword"] ||
      [_key isEqualToString:@"password"]) {
    return self->newPassword;
  }
  if ([_key isEqualToString:@"isCrypted"])
    return [NSNumber numberWithBool:self->isCrypted];
  
  if ([_key isEqualToString:@"logText"] ||
           [_key isEqualToString:@"logAction"] ||
           [_key isEqualToString:@"companyId"])
    return [super valueForKey:_key];
  
  [self warnWithFormat:@"%s: key %@ is not valid in "
        @"change-password command",
        __PRETTY_FUNCTION__, _key];
  return nil;
}

/* command entity */

- (NSString *)entityName {
  return @"Person";
}

@end /* LSChangePasswordCommand */
