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

#include "DirectAction.h"
#include "common.h"
#include "NSObject+EKVC.h"
#include "EOControl+XmlRpcDirectAction.h"
#include <OGoAccounts/SkyAccountDocument.h>
#include <EOControl/EOGenericRecord.h>
#include <EOControl/EOKeyGlobalID.h>

@implementation DirectAction(Account)

/* private methods */

- (id)_getAccountForId:(NSString *)_uid withAttributes:(id)_attributes
  inContext:(id)_ctx
{
  return [[_ctx documentManager] documentForURL:_uid];
}

- (id)_getEOForURL:(NSString *)_url inContext:(id)_ctx {
  EOGlobalID *gid;

  if ((gid = [[_ctx documentManager] globalIDForURL:_url]) != nil) {
    id result;
    
    result =  [_ctx runCommand:@"person::get-by-globalid",
                    @"gid", gid, nil];
    if ([result isKindOfClass:[NSArray class]])
      return [result objectAtIndex:0];
  }
  return nil;
}

- (id)_getAccountForURL:(NSString *)_url inContext:(id)_ctx {
  EOGlobalID *gid;
  NSString   *key;

  key = [_url lastPathComponent];

  // the account gid can't be queried from the document manager,
  // as it would always return IDs from the 'Person' entity
  gid = [EOKeyGlobalID globalIDWithEntityName:@"Account"
                       keys:&key keyCount:1 zone:NULL];

  if (gid != nil) {
    id result;
    
    result =  [_ctx runCommand:@"account::get-by-globalid",
                    @"gid", gid, nil];
    if ([result isKindOfClass:[NSArray class]])
      return [result objectAtIndex:0];
  }
  return nil;
}

- (NSDictionary *)_dictionaryForAccountEOGenericRecord:(id)_record {
  static NSArray *accountKeys = nil;
  id result;
  
  if (accountKeys == nil)
    accountKeys = [[NSArray alloc] initWithObjects:
                                   @"login", @"isAccount", @"isExtraAccount",
                                   @"isPerson", @"isIntraAccount",
                                   @"ownerId", @"templateUserId",
                                   @"isTemplateUser",
                                   nil];

  result = [self _dictionaryForEOGenericRecord:_record withKeys:accountKeys];

  [self substituteIdsWithURLsInDictionary:result
        forKeys:[NSArray arrayWithObjects:@"templateUserId", @"ownerId", nil]];
  return result;
}

- (void)_takeValuesDict:(NSDictionary *)_from
  toAccount:(SkyAccountDocument **)_to
{
  [*_to takeValuesFromObject:_from keys:@"login",@"name",@"firstname",
        @"middlename", @"nickname",@"password", nil];
}

- (BOOL)_setPassword:(NSString *)_pwd forAccount:(EOGenericRecord *)_account
  withLogText:(NSString *)_text isCrypted:(NSNumber *)_isCrypted
{
  LSCommandContext *ctx;

  if ((ctx = [[self session] commandContext]) != nil) {
    id result;
    
    result = [ctx runCommand:@"account::change-password",
                  @"isCrypted", _isCrypted,
                  @"password", _pwd,
                  @"object", _account,
                  @"logText", _text,
                  nil];

    if ([result isKindOfClass:[EOGenericRecord class]])
      return YES;
  }
  return NO;
}

- (id)account_setPasswordAction:(id)_uid:(NSString *)_newPwd
  :(NSNumber *)_isCrypted
{
  if ([_newPwd length] == 0) {
    return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_PARAMETER
                 reason:@"Invalid new password supplied"];
  }

  if ([self isCurrentUserRoot]) {
    LSCommandContext *ctx;

    if ((ctx = [self commandContext]) != nil) {
      id account;

      if ((account = [self _getEOForURL:_uid inContext:ctx]) == nil)
        return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_PARAMETER
                     reason:@"Invalid account UID supplied"];

      if (_isCrypted == nil)
        _isCrypted = [NSNumber numberWithBool:NO];

      if ([self _setPassword:_newPwd forAccount:account
                withLogText:@"Password changed by 'root'"
                isCrypted:_isCrypted]) {
        if ([[account valueForKey:@"companyId"] intValue] == 10000)
          [[self session] terminate];

        return [NSNumber numberWithBool:YES];
      }
      return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_RESULT
                   reason:@"Invalid result for password update command"];
    }
    return [self invalidCommandContextFault];
  }
  return [self faultWithFaultCode:XMLRPC_MISSING_PERMISSIONS
               reason:@"This function is only allowed to be used by 'root'"];
}

- (id)account_changePasswordAction:(NSString *)_newPwd:(NSNumber *)_isCrypted {
  LSCommandContext *ctx;

  if ([_newPwd length] == 0)
    return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_PARAMETER
                 reason:@"Invalid new password supplied"];

  if ((ctx = [self commandContext]) != nil) {
    id account;

    if ((account = [[self commandContext] valueForKey:LSAccountKey]) == nil)
      return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_RESULT
                   reason:@"Didn't find current account"];
      
    if (_isCrypted == nil)
      _isCrypted = [NSNumber numberWithBool:NO];

    if ([self _setPassword:_newPwd forAccount:account
              withLogText:@"Password changed by user" isCrypted:_isCrypted]) {
      [[self session] terminate];
      return [NSNumber numberWithBool:YES];
    }
    return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_RESULT
                 reason:@"Invalid result for password update command"];
  }
  return [self invalidCommandContextFault];
}

- (id)account_getLoginAccountAction {
  EOGenericRecord *loginAccount;

  loginAccount = [[self commandContext] valueForKey:LSAccountKey];
  if (loginAccount != nil) {
    EODataSource       *accountDS;
    SkyAccountDocument *account;
    EOGlobalID         *gid;
    
    accountDS = [self accountDataSource];
    gid = [loginAccount valueForKey:@"globalID"];
    account = [[SkyAccountDocument alloc] initWithAccount:loginAccount
                                          globalID:gid
                                          dataSource:accountDS];
    if (account != nil)
      return [account autorelease];
    else {
      [self logWithFormat:@"Couldn't create account document"];
      return [NSNumber numberWithBool:NO];
    }
  }
  [self logWithFormat:@"Couldn't find current login account"];
  return [NSNumber numberWithBool:NO];
}

- (id)account_getLoginAccountIdAction {
  EOGlobalID *gid;

  gid = [[[self commandContext] valueForKey:LSAccountKey]
                 valueForKey:@"globalID"];

  if (gid != nil)
    return [[[self commandContext] documentManager] urlForGlobalID:gid];

  [self logWithFormat:@"Couldn't find global id of current login account"];
  return [NSNumber numberWithBool:NO];
}

- (NSArray *)account_fetchIdsAction:(id)_arg {
  EOFetchSpecification *fspec;
  NSMutableDictionary  *hints;
  EODataSource         *accountDS;
  NSArray              *fetchResult;
  NSMutableArray       *ids;
  int i;
  
  accountDS = [self accountDataSource];
  fspec     = [[EOFetchSpecification alloc] initWithBaseValue:_arg];
  hints     = [NSMutableDictionary dictionaryWithDictionary:[fspec hints]];
  [hints setObject:[NSNumber numberWithBool:YES] forKey:@"fetchGlobalIDs"];
  [fspec setHints:hints];
  [fspec setEntityName:@"Account"];
  
  [accountDS setFetchSpecification:fspec];

  [fspec release]; fspec = nil;

  fetchResult = [accountDS fetchObjects];
  ids = [NSMutableArray arrayWithCapacity:[fetchResult count]];

  for(i = 0; i < [fetchResult count]; i++) {
    [ids addObject:[[fetchResult objectAtIndex:i] globalID]];
  }
  
  return [[[self commandContext] documentManager]
                 urlsForGlobalIDs:ids];
}

- (NSDictionary *)account_fetchIdsAndVersionsAction:(id)_arg {
  EOFetchSpecification *fspec;
  NSMutableDictionary  *hints;
  EODataSource         *accountDS;
  NSArray              *fetchResult;
  NSMutableDictionary  *result;
  NSEnumerator         *documentEnum;
  SkyAccountDocument   *account;
  id                   documentManager;
  
  accountDS = [self accountDataSource];
  fspec     = [[EOFetchSpecification alloc] initWithBaseValue:_arg];

  hints     = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithBool:YES],
                                   @"fetchGlobalIDs",nil];
  [fspec setHints:hints];
  [fspec setEntityName:@"Account"];
  [accountDS setFetchSpecification:fspec];

  [fspec release]; fspec = nil;
  fetchResult = [accountDS fetchObjects];

  result = [NSMutableDictionary dictionaryWithCapacity:[fetchResult count]];

  documentManager = [[self commandContext] documentManager];
  
  documentEnum = [fetchResult objectEnumerator];
  while ((account = [documentEnum nextObject])) {
    id gid;
    NSNumber *version;
    
    gid = [[documentManager urlForGlobalID:[account globalID]] absoluteString];
    version = ([account objectVersion] != nil)
      ? [account objectVersion]
      : [NSNumber numberWithInt:0];
    
    [result setObject:version forKey:gid];
  }
  return result;
}

- (id)account_getByIdAction:(NSString *)_uid:(id)_attributes {
  id result;
  LSCommandContext *ctx;

  if ((ctx = [self commandContext]) != nil) {
    result = [self _getEOForURL:_uid inContext:ctx];

    if (result != nil) {
      return [[[SkyAccountDocument alloc] initWithAccount:result
                                          globalID:
                                          [result valueForKey:@"globalID"]
                                          dataSource:[self accountDataSource]]
                                   autorelease];
    }
    return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_RESULT
                 reason:@"No account with given ID found"];
  }
  return [self invalidCommandContextFault];
}

- (id)_getAccountByAttribute:(NSString *)_attr forKey:(NSString *)_key {
  EODataSource         *accountDS;
  NSString             *attr;
  EOQualifier          *qual      = nil;
  EOFetchSpecification *fspec     = nil;
  NSArray               *result;
  
  accountDS = [self accountDataSource];
  attr      = [_attr stringValue];
  
  if ([attr length] == 0)
    return nil;
  
  qual = [[EOKeyValueQualifier alloc] initWithKey:_key
                                      operatorSelector:EOQualifierOperatorEqual
                                      value:attr];
  
  fspec = [EOFetchSpecification fetchSpecificationWithEntityName:@"Person"
                                qualifier:qual
                                sortOrderings:nil];

  [accountDS setFetchSpecification:fspec];
  [qual release]; qual = nil;
  
  result = [accountDS fetchObjects];
  
  if ([result count] == 0)
    return nil;
  
  NSAssert1([result count] == 1,
            @"invalid result count (%i records for login)", [result count]);

  return [result objectAtIndex:0];
}

- (id)_getAccountByLogin:(NSString *)_login {
  return [self _getAccountByAttribute:_login forKey:@"login"];
}

- (id)_getAccountByNumber:(NSString *)_number {
  return [self _getAccountByAttribute:_number forKey:@"number"];
}

- (id)account_getByNumberAction:(NSString *)_number {
  id account;

  if ((account = [self _getAccountByNumber:_number]))
    return account;

  return [NSNumber numberWithBool:NO];
}

- (id)account_getByLoginAction:(NSString *)_login {
  id account;

  if ((account = [self _getAccountByLogin:_login]))
    return account;

  return [NSNumber numberWithBool:NO];
}

- (id)account_passwordForLoginAction:(NSString *)_login {
  SkyAccountDocument *account = nil;

  if ([self isCurrentUserRoot]) {
    if ((account = [self _getAccountByLogin:_login]))
      return [account password];
    return [NSNumber numberWithBool:NO];
  }
  else {
    [self logWithFormat:@"non-root user tried to call passwordForLogin"];
    return [NSNumber numberWithBool:NO];
  }
}

- (id)account_getTeamsForLoginAction:(NSString *)_login {
  LSCommandContext *ctx;
  id acc;

  if ((ctx = [self commandContext]) == nil)
    return [NSNumber numberWithBool:NO];

  acc = [ctx runCommand:@"account::get-by-login", @"login", _login, nil];
  if (acc != nil)
    return [ctx runCommand:@"account::teams", @"account", acc, nil];
  
  return [NSNumber numberWithBool:NO];
}

- (id)account_deleteByNumberAction:(NSString *)_login {
  id account = nil;
  
  _login = [_login stringValue];
  if ([_login length] == 0)
    return [NSNumber numberWithBool:NO];
  
  if ((account = [self _getAccountByLogin:_login]) == nil)
    return [NSNumber numberWithBool:NO];

  [[self personDataSource] deleteObject:account];
  return [NSNumber numberWithBool:YES];
}

- (id)account_deleteByLoginAction:(NSString *)_login {
  id account = nil;

  _login = [_login stringValue];
  if ([_login length] == 0)
    return [NSNumber numberWithBool:NO];
  
  if ((account = [self _getAccountByLogin:_login]) == nil)
    return [NSNumber numberWithBool:NO];
  
  [[self personDataSource] deleteObject:account];
  return [NSNumber numberWithBool:YES];
}

- (NSArray *)account_fetchAction:(id)_arg {
  EOFetchSpecification *fspec;
  EODataSource         *accountDS;
  
  accountDS = [self accountDataSource];
  fspec = [[EOFetchSpecification alloc] initWithBaseValue:_arg];
  // TODO: should we warn or even fault if qualifier is nil?
  [fspec setEntityName:@"account"];
  [accountDS setFetchSpecification:fspec];
  [fspec release]; fspec = nil;
  
  return [accountDS fetchObjects];
}

- (NSArray *)account_getAllTemplateUserLoginsAction {
  id result;

  result = [self account_fetchAction:@"isTemplateUser = 1"];
  return [result valueForKey:@"login"];
}

- (id)account_insertAction:(id)_account:(NSNumber *)_dontCryptPassword {
  LSCommandContext *ctx;
    NSMutableDictionary *args = nil;
    NSString *templateUserId;
    id result;

  if ((ctx = [self commandContext]) == nil) {
    [self logWithFormat:@"Invalid command context"];
    return [NSNumber numberWithBool:NO];
  }

  if ((templateUserId = [_account valueForKey:@"templateUserId"]) != nil) {
    EOGlobalID *gid;

    if (([templateUserId intValue] == 0) &&
          (![templateUserId hasPrefix:@"skyrix://"])) {
        id account;

        account = [ctx runCommand:@"account::get-by-login",
                       @"login", templateUserId,
                       nil];

       if ([account isKindOfClass:[EOGenericRecord class]])
          gid = [account globalID];
        else
          return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_RESULT
                       reason:@"Invalid template user account"];
    }
    else
      gid = [[ctx documentManager] globalIDForURL:templateUserId];

    if (gid != nil) {
        id tmpId;
        id account = nil;

        if (![[gid entityName] isEqualToString:@"Person"])
          return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_PARAMETER
                       reason:@"Specified template user is no person"];
        
        tmpId = [ctx runCommand:@"person::get-by-globalid",
                     @"gid", gid,
                     nil];

        if ([tmpId isKindOfClass:[NSArray class]])
          account = [tmpId objectAtIndex:0];

        if (account != nil) {
          if ([[account valueForKey:@"isTemplateUser"] boolValue]) {
            args = [_account mutableCopy];
            [args takeValue:[[tmpId objectAtIndex:0] valueForKey:@"companyId"]
                  forKey:@"templateUserId"];
          }
          else {
            return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_PARAMETER
                         reason:@"Given account is no template user"];
          }
        }
        else {
          return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_PARAMETER
                       reason:@"Didn't find account for template user ID"];
        }
    }
    else {
      return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_PARAMETER
		   reason:@"Couldn't find template user for user ID"];
    }
  }

  if ([_dontCryptPassword boolValue]) {
      if (args == nil) 
        args = [_account mutableCopy];

      [args setObject:[NSNumber numberWithBool:YES]
            forKey:@"dontCryptPassword"];
  }

  if (args != nil) {
      result = [ctx runCommand:@"account::new" arguments:args];
      [args release]; args = nil;
  }
  else
      result = [ctx runCommand:@"account::new" arguments:_account];

  return [self _dictionaryForAccountEOGenericRecord:result];
}

- (id)account_updateAction:(id)_account {
  LSCommandContext *ctx;
  SkyAccountDocument *account = nil;
  NSString *tmp;

  if ((ctx = [self commandContext]) == nil) // TODO: improve error
    return [NSNumber numberWithBool:NO];

  if ((tmp = [_account valueForKey:@"id"]) == nil) {
    return [self faultWithFaultCode:XMLRPC_FAULT_MISSING_PARAMETER
		 reason:@"Missing ID in account record"];
  }
  
  if ((account = [self _getAccountForURL:tmp inContext:ctx]) == nil)
    return [NSNumber numberWithBool:NO];

  [self _takeValuesDict:_account toAccount:&account];
  [[self accountDataSource] updateObject:account];
  return account;
}

- (id)account_deleteAction:(id)_account {
  SkyAccountDocument *account = nil;

  if ([_account isKindOfClass:[NSDictionary class]]) {
    NSString *tmp;

    if ((tmp = [_account objectForKey:@"login"]))
      account = [self _getAccountByLogin:tmp];
    else if ((tmp = [_account objectForKey:@"number"]))
      account = [self _getAccountByNumber:tmp];
    else
      return [NSNumber numberWithBool:NO];
  }
  else if ([_account isKindOfClass:[SkyAccountDocument class]])
    account = _account;
  
  if (account) {
    [[self accountDataSource] deleteObject:account];
    return [NSNumber numberWithBool:YES];
  }
  return [NSNumber numberWithBool:NO];
}

@end /* DirectAction(Account) */
