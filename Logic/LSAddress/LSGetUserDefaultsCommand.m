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

#include <LSFoundation/LSBaseCommand.h>

@interface LSGetUserDefaultsCommand : LSBaseCommand
{
  id user;
}

@end

#include "LSUserDefaults.h"
#include "common.h"
#include <LSUserDefaultsFunctions.h>
#include <LSUserDefaults.h>

@implementation LSGetUserDefaultsCommand

- (void)dealloc {
  [self->user release];
  [super dealloc];
}

/* command type */

- (BOOL)requiresChannel {
  return NO;
}
- (BOOL)requiresTransaction {
  return NO;
}

/* prepare for execution */

- (void)_prepareForExecutionInContext:_context {
  id       account;
  NSString *login;
  
  account = [_context valueForKey:LSAccountKey];
  login   = [account valueForKey:@"companyId"];
  
  if ([login intValue] == 10000) // TODO: check 'root' role (or pref-edit perm)
    return;

  if (![[_context class] useLDAPAuthorization]) {
    [self assert:[[account valueForKey:@"companyId"]
                           isEqual:[self->user valueForKey:@"companyId"]]
	  reason:
	    @"only root is allowed to access preferences of other accounts"];
  }
  
  {
    NSString *authLogin;
    NSString *userLogin;
      
    authLogin = [_context valueForKey:@"authorizedLDAPLogin"];
    userLogin = [self->user valueForKey:@"login"];

    if (authLogin) {
        [self assert:[userLogin isEqualToString:authLogin]
              format:
                @"only root is allowed to access foreign preferences "
                @"(user-login=%@, ldap-login=%@)",
                userLogin, authLogin];
    }
    else {
      [self assert:
	      [[account valueForKey:@"companyId"]
		        isEqual:[self->user valueForKey:@"companyId"]]
	    reason:@"only root is allowed to access foreign preferences"];
    }
  }
}

- (void)_executeInContext:(id)_context {
  NSMutableDictionary *dict      = nil;
  NSUserDefaults      *defs      = nil;
  NSNumber            *uid       = nil;
  NSNumber            *loginPKey = nil;
  
  loginPKey = [[_context valueForKey:LSAccountKey] valueForKey:@"companyId"];
  uid = [self->user valueForKey:@"companyId"];
  
  if ((uid != nil) && ([uid isEqual:loginPKey])) {
    /* retrieve defaults of login account */
    [self setReturnValue:[_context valueForKey:LSUserDefaultsKey]];
    return;
  }
  
  defs = [[[LSUserDefaults alloc]
                           initWithUserDefaults:
	                     [NSUserDefaults standardUserDefaults]
                           andContext:_context] autorelease];

  if (![[self->user valueForKey:@"isTemplateUser"] boolValue]) {
    NSNumber *tmplId;
  
    tmplId = [self->user valueForKey:@"templateUserId"];
    
    if (![tmplId isNotNull]) // TODO: move to a static
      tmplId = [NSNumber numberWithInt:9999];  

    // register template-user
    if (![uid isEqual:tmplId]) {
      dict = __getUserDefaults_LSLogic_LSAddress(self, _context, tmplId);
      __registerVolatileLoginDomain_LSLogic_LSAddress(self, _context, defs,
                                                      dict, tmplId);
    }
  }
  // register user-defaults
  if (uid != nil) {
    dict = __getUserDefaults_LSLogic_LSAddress(self, _context, uid);
    __registerVolatileLoginDomain_LSLogic_LSAddress(self, _context, defs, dict,
                                                    uid);
  }
  if (self->user)
    [(LSUserDefaults *)defs setAccount:self->user];
  
  [self setReturnValue:defs];
}

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"user"]) {
    ASSIGN(self->user, _value);
  }
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"user"])
    return self->user;

  return [super valueForKey:_key];
}

@end /* LSGetUserDefaultsCommand */
