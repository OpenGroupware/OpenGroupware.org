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

@class NSUserDefaults;

@interface LSRegisterUserDefaultsCommand : LSBaseCommand
{
  NSUserDefaults *defaults;
  id             account;
}

@end

#include "common.h"
#include "LSUserDefaultsFunctions.h"

@implementation LSRegisterUserDefaultsCommand

- (void)dealloc {
  [self->defaults release];
  [self->account  release];
  [super dealloc];
}

/* command execution */

- (void)_prepareForExecutionInContext:_context {
  if (self->defaults == nil) {
    [self warnWithFormat:@"no defaults set --> using StandardUserDefaults"];
    self->defaults = [[NSUserDefaults standardUserDefaults] retain];
  }
}

- (void)_executeInContext:(id)_context {
  NSMutableDictionary *dict     = nil;
  NSNumber            *uid;
  NSNumber            *template = nil;
  id                  user;

  user = [_context valueForKey:LSAccountKey];
  uid  = [user valueForKey:@"companyId"];
  
  if (self->account != nil) {
    NSNumber *aid;

    aid = [self->account valueForKey:@"companyId"];

    if ([aid intValue] != [uid intValue]) {
      if ([uid intValue] != 10000) {
        NSLog(@"Only root is allow to change/register foreign defaults "
              @"user:%@ account: %@", user, account);
        return;
      }
      uid  = aid;
      user = self->account;
    }
  }
  
  template = [user valueForKey:@"templateUserId"];
  if ((template == nil) || ((id)[NSNull null] == template)) // TODO: isNotNull
    template = [NSNumber numberWithInt:9999];
  
  if (![uid isEqual:template]) {
    // register template-user
    dict = __getUserDefaults_LSLogic_LSAddress(self, _context, template);
    __registerVolatileLoginDomain_LSLogic_LSAddress(self, _context,
                                                    self->defaults, dict,
                                                    template);
  }

  // register user-defaults
  
  dict = __getUserDefaults_LSLogic_LSAddress(self, _context, uid);
  __registerVolatileLoginDomain_LSLogic_LSAddress(self, _context,
                                                  self->defaults, dict, uid);
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"defaults"]) {
    ASSIGN(self->defaults, _value);
  }
  else if ([_key isEqualToString:@"account"]) {
    ASSIGN(self->account, _value);
  }
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"defaults"])
    return self->defaults;

  if ([_key isEqualToString:@"account"])
    return self->account;
  
  return [super valueForKey:_key];
}

@end /* LSRegisterUserDefaultsCommand */
