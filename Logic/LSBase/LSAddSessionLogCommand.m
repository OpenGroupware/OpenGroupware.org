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

#include <LSFoundation/LSDBObjectNewCommand.h>

@interface LSAddSessionLogCommand : LSDBObjectNewCommand
{
  id account;
}
@end

#include "common.h"

@implementation LSAddSessionLogCommand

static BOOL disableSessionLog = NO;

+ (void)initialize {
  disableSessionLog = 
    [[NSUserDefaults standardUserDefaults] boolForKey:@"LSDisableSessionLog"];
}

- (void)dealloc {
  [self->account release];
  [super dealloc];
}

- (BOOL)isSessionLogEnabledInContext:(id)_ctx {
  return disableSessionLog ? NO : YES;
}

- (BOOL)shouldInsertObjectInObjInfoTable:(id)_object {
  return NO;
}

- (void)_prepareForExecutionInContext:(id)_context {
  NSCalendarDate *now;
  
  if (![self isSessionLogEnabledInContext:_context]) return;

  if (![self valueForKey:@"accountId"]) {
    id accId;

    [self assert:(self->account != nil)
          reason:@"No account for session logging was given!"];
    accId = [self->account valueForKey:@"companyId"];
  
    [self takeValue:accId forKey:@"accountId"];
  }
  
  [self assert:([[self valueForKey:@"action"] length] > 0)
        reason:@"No action for session logging was given!"];

  now = [[NSCalendarDate alloc] init];
  [self takeValue:now forKey:@"logDate"];
  [now release];
  
  [super _prepareForExecutionInContext:_context];
}
- (void)_executeInContext:(id)_context {
  if (![self isSessionLogEnabledInContext:_context]) return;
  [super _executeInContext:_context];
}

/* accessors */

- (NSString *)entityName {
  return @"SessionLog";
}

- (void)setAccount:(id)_account {
  ASSIGN(self->account, _account);
}
- (id)account {
  return self->account;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"account"]) {
    [self setAccount:_value];
    return;
  }
  [super takeValue:_value forKey:_key];
}
- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"account"]) 
    return [self account];
  
  return [super valueForKey:_key];
}

@end /* LSAddSessionLogCommand */
