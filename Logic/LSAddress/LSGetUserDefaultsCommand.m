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

#include <LSFoundation/LSBaseCommand.h>

/*
  LSGetUserDefaultsCommand

  TODO: document
*/

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

- (BOOL)isRootId:(NSNumber *)_pkey inContext:(LSCommandContext *)_ctx {
  return [_pkey intValue] == 10000 ? YES : NO; // root
}

- (void)_checkLdapAccessInContext:(LSCommandContext *)_context {
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
	      [[[_context valueForKey:LSAccountKey] valueForKey:@"companyId"]
		        isEqual:[self->user valueForKey:@"companyId"]]
	    reason:@"only root is allowed to access foreign preferences"];
    }
}

- (void)_prepareForExecutionInContext:(id)_context {
  id       account;
  NSNumber *login;
  
  account = [_context valueForKey:LSAccountKey];
  login   = [account valueForKey:@"companyId"];
  
  if ([self isRootId:login inContext:_context])
    return;
  
  if (![[_context class] useLDAPAuthorization]) {
    [self assert:[login isEqual:[self->user valueForKey:@"companyId"]]
	  reason:
	    @"only root is allowed to access preferences of other accounts"];
  }
  
  [self _checkLdapAccessInContext:_context];
}

- (void)_executeInContext:(id)_context {
  NSMutableDictionary *dict      = nil;
  NSUserDefaults      *defs      = nil;
  NSNumber            *uid       = nil;
  NSNumber            *loginPKey = nil;
  
  loginPKey = [[_context valueForKey:LSAccountKey] valueForKey:@"companyId"];
  uid = [self->user valueForKey:@"companyId"];
  
  /* check whether we want the defaults of the logged in account */
  
  if ((uid != nil) && ([uid isEqual:loginPKey])) {
    /* retrieve defaults of login account */
    [self setReturnValue:[_context valueForKey:LSUserDefaultsKey]];
    return;
  }
  
  /* no, different account */
  
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
  if (self->user != nil)
    [(LSUserDefaults *)defs setAccount:self->user];
  
  [self setReturnValue:defs];
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"user"]) {
    ASSIGN(self->user, _value);
  }
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"user"])
    return self->user;

  return [super valueForKey:_key];
}

@end /* LSGetUserDefaultsCommand */
