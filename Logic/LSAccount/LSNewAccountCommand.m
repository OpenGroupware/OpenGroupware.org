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

#include <LSAddress/LSNewCompanyCommand.h>

@class NSArray;

@interface LSNewAccountCommand : LSNewCompanyCommand
{
  NSArray *teams;
  BOOL    dontCryptPassword;
}

@end

#include "common.h"

@implementation LSNewAccountCommand

- (void)dealloc {
  [self->teams release];
  [super dealloc];
}

- (void)_newStaffInContext:(id)_context {
  BOOL         isOk         = NO;
  id           account;
  id           pkey;
  EOEntity     *staffEntity;
  id           staff;
  NSDictionary *pk;
  
  account     = [self object];
  pkey        = [account valueForKey:[self primaryKeyName]];
  staffEntity = [[self databaseModel] entityNamed:@"Staff"];

  pk    = [self newPrimaryKeyDictForContext:_context keyName:@"staffId"];
  staff = [self produceEmptyEOWithPrimaryKey:pk entity:staffEntity];
  
  [staff takeValue:[pk valueForKey:@"staffId"]          forKey:@"staffId"];
  [staff takeValue:pkey                                 forKey:@"companyId"];
  [staff takeValue:[account valueForKey:@"login"]       forKey:@"login"];
  [staff takeValue:[NSNumber numberWithBool:YES]        forKey:@"isAccount"];
  [staff takeValue:[NSNumber numberWithBool:NO]         forKey:@"isTeam"];
  [staff takeValue:@"inserted"                          forKey:@"dbStatus"];
  [staff takeValue:[account valueForKey:@"description"] forKey:@"description"];
  
  isOk = [[self databaseChannel] insertObject:staff];

  [LSDBObjectCommandException raiseOnFail:isOk object:self
                              reason:[sybaseMessages description]];
}

- (void)_takeCryptedPasswdInContext:(id)_context {
  NSString *passwd;
  
  passwd = [self valueForKey:@"password"];
  
  if ([passwd isNotNull]) {
    NSString *cryptedPasswd;
    
    cryptedPasswd = LSRunCommandV(_context, @"system", @"crypt",
                                  @"password", passwd, nil);
    
    [self takeValue:cryptedPasswd forKey:@"password"]; 
  }
}

- (void)_prepareForExecutionInContext:(id)_context {
  id isExtraAccount;
  id nYes, nNo;
  id account        = [_context valueForKey:LSAccountKey];

  if ([[account valueForKey:@"companyId"] intValue] != 10000) {
    if ([LSCommandContext useLDAPAuthorization]) {
      // only user can create a skyrix account for itself
      // compare by login
      NSString *ldapLogin = [_context valueForKey:@"authorizedLDAPLogin"];
      [self assert:([ldapLogin length] != 0) reason:@"no ldap login authorized"];
      [self assert:([[self valueForKey:@"login"] isEqualToString:ldapLogin])
            reason:@"LDAPAuthorization is enabled. Cannot create "
            @"skyrix-accounts."];
    }
    else {
      // only root can create accounts
      [self assert:NO reason:@"Only root can create accounts"];
    }
  }
  
  nYes = [NSNumber numberWithBool:YES];
  nNo  = [NSNumber numberWithBool:NO];
  
  isExtraAccount = [self valueForKey:@"isExtraAccount"];
  [self takeValue:nYes forKey:@"isPerson"];
  [self takeValue:nYes forKey:@"isAccount"];

  if ([isExtraAccount boolValue]) {
    [self takeValue:nNo forKey:@"isIntraAccount"];
    [self takeValue:nYes forKey:@"isExtraAccount"];    
  }
  else {
    [self takeValue:nYes forKey:@"isIntraAccount"];
    [self takeValue:nNo forKey:@"isExtraAccount"];
  }

  [self takeValue:nYes forKey:@"isIntraAccount"];

  if (!self->dontCryptPassword)
    [self _takeCryptedPasswdInContext:_context];

  if ([[NSUserDefaults standardUserDefaults]
                       boolForKey:@"LSUseLowercaseLogin"])
    [self takeValue:[[self valueForKey:@"login"] lowercaseString]
          forKey:@"login"];
  if ([[NSUserDefaults standardUserDefaults]
                       boolForKey:@"LSCreateAccountsReadonly"])
    [self takeValue:nYes forKey:@"isReadonly"];
  
  [super _prepareForExecutionInContext:_context];
}

- (void)_executeInContext:(id)_context {
  /* check nu */
  if (![[self valueForKey:@"isTemplateUser"] boolValue]) {
    NSNumber       *templId = nil;
    
    // set template user, if not set
    templId = [self valueForKey:@"templateUserId"];
    
    if (![templId isNotNull]) {
      id tmp = nil;
      
      tmp =  LSRunCommandV(_context, @"account", @"extended-search",
                           @"fetchGlobalIDs", [NSNumber numberWithBool:YES],
                           @"isTemplateUser", [NSNumber numberWithBool:YES],
                           nil);

      if ([tmp count] > 0) {
        templId = [[tmp objectAtIndex:0] keyValues][0];

        if (templId != nil)
          [[self object] takeValue:templId forKey:@"templateUserId"];
      }
    }
  }
  [super _executeInContext:_context];
  [self _newStaffInContext:_context];

  if (self->teams != nil && [self->teams count] > 0) {
    LSRunCommandV(_context, @"account", @"setgroups",
                  @"member", [self object],
                  @"groups", self->teams, nil);
  }
#if 0  
  else  if (![[[self object] valueForKey:@"isTemplateUser"] boolValue]) {
    NSArray *t = nil;

    t = LSRunCommandV(_context, @"team", @"get",
                      @"companyId", [NSNumber numberWithInt:10003], nil);
    if (t != nil && [t count] > 0) {
      LSRunCommandV(_context, @"account", @"setgroups",
                    @"member", [self object],
                    @"groups", t, nil);
    }
  }
#endif  
}

/* initialize records */

- (NSString *)entityName {
  return @"Person";
}

/* accessors */

- (void)setTeams:(NSArray *)_teams {
  ASSIGN(teams, _teams);
}
- (NSArray *)teams {
  return self->teams;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"teams"] ||
      [_key isEqualToString:@"toGroup"] ||
      [_key isEqualToString:@"groups"]) {
    [self setTeams:_value];
    return;
  }
  if ([_key isEqualToString:@"dontCryptPassword"]) {
    self->dontCryptPassword = [_value boolValue];
    return;
  }

  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"teams"] ||
      [_key isEqualToString:@"toGroup"] ||
      [_key isEqualToString:@"groups"])
    return [self teams];

  if ([_key isEqualToString:@"dontCryptPassword"])
    return [NSNumber numberWithBool:self->dontCryptPassword];
  
  return [super valueForKey:_key];
}

@end /* LSNewAccountCommand */
