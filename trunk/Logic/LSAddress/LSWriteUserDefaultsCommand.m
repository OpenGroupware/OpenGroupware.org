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

@class NSUserDefaults, NSNumber;

@interface LSWriteUserDefaultsCommand : LSBaseCommand
{
  id             value;
  id             key;
  NSUserDefaults *defaults;
  NSNumber       *userId;
  BOOL delete;
}

@end

#include "common.h"
#include "LSUserDefaultsFunctions.h"

@implementation LSWriteUserDefaultsCommand

- (id)initForOperation:(NSString *)_operation inDomain:(NSString *)_domain {
  if ((self = [super initForOperation:_operation inDomain:_domain])) {
    self->delete = [_operation isEqualToString:@"delete"];
  }
  return self;
}

- (void)dealloc {
  [self->key      release];
  [self->value    release];
  [self->defaults release];
  [self->userId   release];
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

- (void)_prepareForExecutionInContext:(id)_context {
  id account;
  
  if (self->defaults == nil) {
    NSLog(@"WARNING: defaults == nil using StandardUserDefaults");
    self->defaults = [[_context valueForKey:LSUserDefaultsKey] retain];
  }
  [self assert:[self->key isNotNull] reason:@"expect a key"];

  if (!self->delete)
    [self assert:[self->value isNotNull] reason:@"expect a value"];
  
  account = [_context valueForKey:LSAccountKey];
  if (self->userId == nil) {
    self->userId = [[account valueForKey:@"companyId"] retain];
  }
  else if (![self->userId isEqual:[account valueForKey:@"companyId"]]) {
    [self assert:([[account valueForKey:@"companyId"] intValue] == 10000)
          reason:@"only root is allowed to write foreign preferences"];
  }
  [super _prepareForExecutionInContext:_context];
}

- (void)_executeInContext:(id)_context {
  NSMutableDictionary *dict;

  dict = __getUserDefaults_LSLogic_LSAddress(self, _context, self->userId);
  
  if (!self->delete) {
    [dict setObject:self->value forKey:self->key];
  }
  else {
    [dict removeObjectForKey:self->key];
  }
  __writeUserDefaults_LSLogic_LSAddress(self, _context, dict, self->userId);
  __registerVolatileLoginDomain_LSLogic_LSAddress(self, _context, 
						  self->defaults,
                                                  dict, self->userId);
}

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"key"]) {
    ASSIGNCOPY(self->key, _value);
  }
  else if ([_key isEqualToString:@"value"]) {
    ASSIGNCOPY(self->value, _value);
  }
  else if ([_key isEqualToString:@"defaults"] ||
           [_key isEqualToString:@"userdefaults"]) {
    ASSIGN(self->defaults, _value);
  }
  else if ([_key isEqualToString:@"userId"]) {
    ASSIGN(self->userId, _value);
  }
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"key"])
    return self->key;
  if ([_key isEqualToString:@"value"])
    return self->value;
  if ([_key isEqualToString:@"defaults"])
    return self->defaults;
  if ([_key isEqualToString:@"userdefaults"])
    return self->defaults;
  if ([_key isEqualToString:@"userId"])
    return self->userId;

  return [super valueForKey:_key];
}

@end /* LSWriteUserDefaultsCommand */
