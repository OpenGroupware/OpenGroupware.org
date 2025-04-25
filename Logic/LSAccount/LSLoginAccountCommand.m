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

#include "LSGetAccountCommand.h"
#import <openssl/sha.h> // hh(2025-04-25) will this build?

@class NSString, NSNumber;

@interface LSLoginAccountCommand : LSGetAccountCommand
{
@private
  NSString *password;
  NSNumber *crypted;
  NSNumber *isSessionLogEnabled;

  // super user context
  id suCtx;
}

- (void)setLogin:(NSString *)_username;
- (NSString *)login;
- (void)setPassword:(NSString *)_password;
- (NSString *)password;

@end

#include "common.h"
#include <GDLAccess/EOSQLQualifier.h>

//#include <NGLdap/NGLdapConnection.h>

@interface LSCommandContext(LDAPSupport)
+ (BOOL)useLDAPAuthorization;
+ (BOOL)isLDAPLoginAuthorized:(NSString *)_login password:(NSString *)_pwd;
@end

@interface NSObject(Defaults)
- (id)initWithUserDefaults:(NSUserDefaults *)_ud
  andContext:(LSCommandContext *)_tx;
@end

NSString *GetSHA512PasswordUpdate(NSString *plainPassword, NSString *companyId) 
{
  const char *cstr = [plainPassword UTF8String];
  unsigned char hash[SHA512_DIGEST_LENGTH];
  SHA512((const unsigned char*)cstr, strlen(cstr), hash);
  
  NSMutableString *sha512 = 
    [NSMutableString stringWithCapacity:SHA512_DIGEST_LENGTH * 2 + 8];
  [sha512 appendString:@"{SHA512}"];
  
  int i;
  for (i = 0; i < SHA512_DIGEST_LENGTH; i++) {
    [sha512 appendFormat:@"%02x", hash[i]];
  }
  
  /* What we do here should be pretty safe wrt SQL injection given the
   * nature of the values. Would be better to do with the entity/adaptor
   * anyways */
  NSMutableString *sql = [NSMutableString stringWithCapacity:256];
  /*
  DO $$
  BEGIN
    BEGIN
      EXECUTE 'UPDATE my_table SET missing_column = 42';
    EXCEPTION
      WHEN undefined_column THEN
        RAISE NOTICE 'Column does not exist, update skipped.';
    END;
  END;
  $$;*/
  [sql appendString:@"DO $$ BEGIN BEGIN EXECUTE '"];
  
  [sql appendString:@"UPDATE person SET modern_password = ''"];
  [sql appendString:sha512];
  [sql appendString:@"'' WHERE company_id = "];
  [sql appendString:companyId];
  [sql appendString:@" AND (modern_password != ''"];
  [sql appendString:sha512];
  [sql appendString:@"'' OR modern_password IS NULL)"];

  [sql appendString:@"'; "];

  [sql appendString:@"EXCEPTION WHEN undefined_column THEN "];
  [sql appendString:@"RAISE NOTICE 'Column does not exist, update skipped.'; "];
  [sql appendString:@"END; END; $$;"];
  return sql;
}

@implementation LSLoginAccountCommand

- (id)initForOperation:(NSString *)_operation inDomain:(NSString *)_domain {
  if ((self = [super initForOperation:_operation inDomain:_domain])) {
    [self setOperator:@"AND"];
  }
  return self;
}
- (void)dealloc {
  [self->password            release];
  [self->crypted             release];
  [self->isSessionLogEnabled release];
  [super dealloc];
}

/* validation */

- (void)_validateKeysForContext:(id)_context {  
  if (self->password == nil) {
    [LSDBObjectCommandException raiseOnFail:NO
                                object:self
                                reason:@"no password set !"];
  }
  if (self->crypted == nil)
    self->crypted = [[NSNumber numberWithBool:NO] retain];
  if (self->isSessionLogEnabled == nil)
    self->isSessionLogEnabled = [[NSNumber numberWithBool:YES] retain];
}

- (BOOL)isLDAPLoginAuthorized:(NSString *)_login password:(NSString *)_pwd
  inContext:(id)_context
{
  return [[_context class] isLDAPLoginAuthorized:_login password:_pwd];
}

- (BOOL)isSuperUserContext:(id)_suCtx {
  id account;
  if (_suCtx == nil) return NO;
  account = [_suCtx valueForKey:LSAccountKey];
  return [[account valueForKey:@"companyId"] intValue] == 10000 ? YES : NO;
}

- (void)_executeInContext:(id)_context {
  NSArray        *accounts            = nil;
  id             account              = nil;
  NSString       *userName            = nil;
  EOSQLQualifier *authQualifier;
  EOSQLQualifier *isArchivedQualifier;  
  NSAutoreleasePool *p;
  static int UseSkyrixLoginForImap = -1;

  if (UseSkyrixLoginForImap == -1) {
    UseSkyrixLoginForImap =
      [[NSUserDefaults standardUserDefaults]
                       boolForKey:@"UseSkyrixLoginForImap"]?1:0;
  }
  
  p = [[NSAutoreleasePool alloc] init];
  
  userName      = [self->recordDict valueForKey:@"login"];
  authQualifier = [[EOSQLQualifier alloc] initWithEntity:[self entity]
                                       qualifierFormat:
                                          @"login='%@' AND isAccount=1 AND "
                                          @"(NOT login='template') AND "
                                          @"(isLocked=0 OR isLocked IS NULL)",
                                          userName];
  isArchivedQualifier =
    [[EOSQLQualifier alloc] initWithEntity:[self entity]
                            qualifierFormat:@"dbStatus <> 'archived'"];
  [authQualifier conjoinWithQualifier:isArchivedQualifier];

  {
    EODatabaseChannel *dbChannel;
    int            cnt     = 0;
    NSMutableArray *result = nil;
    id             obj     = nil;

    dbChannel = [self databaseChannel];
    [dbChannel selectObjectsDescribedByQualifier:authQualifier fetchOrder:nil];

    result = [[NSMutableArray allocWithZone:[self zone]] init];
    
    while ((obj = [dbChannel fetchWithZone:NULL])) {
      [result addObject:obj];
      cnt++;
      obj = nil;
    }

    if (result != nil) [self setReturnValue:result];
    [result              release]; result              = nil;
    [authQualifier       release]; authQualifier       = nil;
    [isArchivedQualifier release]; isArchivedQualifier = nil;
  }
  accounts = [self returnValue];

  if ([accounts count] > 1)
    [self warnWithFormat:@"more than one user for login '%@'.", [self login]];

  account = [accounts isNotEmpty]
    ? [accounts lastObject]
    : nil;

  if (account) { /* compare password */
    //[self logWithFormat:@"account: %@", account];

    // check for superuser context
    if ([self isSuperUserContext:self->suCtx]) {
      // root's context -> relogin
      
    }
    else if ([LSCommandContext useLDAPAuthorization]) {
      if ([self->crypted boolValue] == YES) {
        NSLog(@"Couldn`t perfom LDAP-login with crypted password");
        account = nil;
      }
      else if (![self isLDAPLoginAuthorized:userName password:[self password]
                      inContext:_context]) {
        /* wasn't authorized by LDAP server */
        account = nil;
      }
      else {
        if (UseSkyrixLoginForImap) 
          [_context takeValue:[self password] forKey:@"LSUser_P_W_D_Key"];
        else if ([[account valueForKey:@"companyId"] intValue] == 10000) {
          /* needed for password modiification */
          [_context takeValue:[self password] forKey:@"LSUser_P_W_D_Key"];
        }
      }
    }
    else { /* use table for authorization */

      // This is the hashed password in the account.
      id accountPassword = [account valueForKey:@"password"];
      if (accountPassword == nil)
        accountPassword = @"";

      // The crypted version of the password.
      NSString *cryptedPwd = nil;
      if (![self->crypted boolValue] && [[self password] isNotEmpty]) {
        id cmd = LSLookupCommandV(@"system", @"crypt",
                                  @"password", [self password],
                                  @"salt",     accountPassword,
                                  nil);
        if (cmd != nil) {
          cryptedPwd = [cmd runInContext:nil];
          [_context takeValue:cryptedPwd forKey:LSCryptedUserPasswordKey];
        }
        else
          [self logWithFormat:@"missing cryped-pwd command ..."];
        
        if ([[NSUserDefaults standardUserDefaults]
                             boolForKey:@"UseSkyrixLoginForImap"])
          [_context takeValue:[self password] forKey:@"LSUser_P_W_D_Key"];
        else if ([[account valueForKey:@"companyId"] intValue] == 10000) {
          /* needed for password modiification */
          [_context takeValue:[self password] forKey:@"LSUser_P_W_D_Key"];
        }
      }
      else
        cryptedPwd = [self password];

      if (![cryptedPwd isEqualToString:accountPassword])
        account = nil; // password didn't match
    }
  }

  if (account == nil)
    NSLog(@"%s: login failed: '%@'.", __PRETTY_FUNCTION__, [self login]);
  
  [_context takeValue:(account != nil ? account : (id)[NSNull null])
	    forKey:LSAccountKey];
  [self setReturnValue:account];

  if (account) {
    NSUserDefaults *defs;
    
    // 2025-04-25:
    // HH: Persist a better hash.
    // We could also upgrade from crypt to SHA512, but for that we would need
    // to support this everywhere, doesn't seem worthwile, just yet? Move Auth
    // out of OGo itself into Apache instead?
    // TODO: protect by default
    if (![self->crypted boolValue]) {
      NSString *sql = GetSHA512PasswordUpdate(
        [self password], [[account valueForKey:@"companyId"] stringValue]);
            
      EOAdaptorChannel *adChannel = [[self databaseChannel] adaptorChannel];
      id error;
      if ((error = [adChannel evaluateExpressionX:sql]) != nil) {
        [self errorWithFormat:@"Couldn't write modern_password: %@", error];
      }
    }
    
    
    
    /* load defaults */
    
    Class defaultsClass = NGClassFromString(@"LSUserDefaults");
    defs = [defaultsClass alloc];
    defs = [defs initWithUserDefaults:
                   [NSUserDefaults standardUserDefaults]
                 andContext:_context];
    
    LSRunCommandV(_context, @"userdefaults", @"register",
                  @"defaults", defs, nil);
    [_context takeValue:defs forKey:LSUserDefaultsKey];
    
    /* set extended attributes for result account(s) */
    
    LSRunCommandV(_context, @"person", @"get-extattrs",
                  @"object", account,
                  @"relationKey", @"companyValue", nil);

    /* log login dates */

    if ([self->isSessionLogEnabled boolValue]) {
      if ([[defs objectForKey:@"LSSessionAccountLogEnabled"] boolValue]) {
        LSRunCommandV(_context, @"sessionlog", @"add",
                      @"account", account,
                      @"action" , @"login", nil);
      }
    }
    [defs release]; defs = nil;
  }

  [p release];
}

/* accessors */

- (void)setLogin:(NSString *)_login {
  if ([[NSUserDefaults standardUserDefaults] boolForKey:@"LSUserDefaultsKey"])
    _login = [_login lowercaseString];
  [self->recordDict setObject:_login forKey:@"login"];
}
- (NSString *)login {
  return [self->recordDict objectForKey:@"login"];
}

- (void)setPassword:(NSString *)_pwd {
  ASSIGNCOPY(self->password, _pwd);
}
- (NSString *)password {
  return self->password;
}

- (void)setIsSessionLogEnabled:(NSNumber *)_flag {
  ASSIGNCOPY(self->isSessionLogEnabled, _flag);
}
- (NSNumber *)isSessionLogEnabled {
  return self->isSessionLogEnabled;
}

- (void)setCrypted:(NSNumber *)_flag {
  ASSIGNCOPY(self->crypted, _flag);
}
- (NSNumber *)crypted {
  return self->crypted;
}

// If this is set, no password checks are done and the login will always
// succeed, i.e. the SU can login as any other user.
- (void)setSuContext:(id)_ctx {
  ASSIGN(self->suCtx,_ctx);
}
- (id)suContext {
  return self->suCtx;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"password"])
    [self setPassword:_value];
  else if ([_key isEqualToString:@"crypted"])
    [self setCrypted:_value];
  else if ([_key isEqualToString:@"isSessionLogEnabled"])
    [self setIsSessionLogEnabled:_value];
  else if ([_key isEqualToString:@"superUserContext"])
    [self setSuContext:_value];
  else 
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"password"])
    return [self password];
  if ([_key isEqualToString:@"crypted"])
    return [self crypted];
  if ([_key isEqualToString:@"isSessionLogEnabled"])
    return [self isSessionLogEnabled];
  if ([_key isEqualToString:@"superUserContext"])
    return [self suContext];

  return [super valueForKey:_key];
}

@end /* LSLoginAccountCommand */
