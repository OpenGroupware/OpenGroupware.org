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

#include <NGObjWeb/WOComponent.h>

@class NSString;

@interface Main : WOComponent
{
  NSString *login;
  NSString *password;
}

@end

#include "PLRConnectionSet.h"
#include <OGoClient/OGoClientConnection.h>
#include "common.h"

@implementation Main

- (void)dealloc {
  [self->login    release];
  [self->password release];
  [super dealloc];
}

/* accessors */

- (void)setLogin:(NSString *)_value {
  ASSIGNCOPY(self->login, _value);
}
- (NSString *)login {
  return self->login;
}

- (void)setPassword:(NSString *)_value {
  ASSIGNCOPY(self->password, _value);
}
- (NSString *)password {
  return self->password;
}

/* actions */

- (BOOL)shouldTakeValuesFromRequest:(WORequest *)_rq inContext:(WOContext*)_c{
  return YES;
}

- (id)logoutAction {
  [[self existingSession] terminate];
  return [self redirectToLocation:[[self context] applicationURL]];
}

- (id)loginAction {
  NSArray  *connections;
  NSString *uri;
  
  if ([self existingSession])
    return [self logoutAction];
  
  connections = [[PLRConnectionSet sharedConnectionSet]
                  connectionsForLogin:[self login] password:[self password]];
  
  [self debugWithFormat:@"valid connections for '%@': %@", 
          [self login], connections];
  
  if ([connections count] == 0) {
    [self setPassword:nil];
    return self;
  }
  
  [[self session] takeValue:connections  forKey:@"connections"];
  [[self session] takeValue:[self login]    forKey:@"login"];
  [[self session] takeValue:[self password] forKey:@"password"];
  [self setPassword:nil];
  
  uri = [[self context] directActionURLForActionNamed:@"WelcomePage/default"
                        queryDictionary:nil];
  return [self redirectToLocation:uri];
}

@end /* Main */
