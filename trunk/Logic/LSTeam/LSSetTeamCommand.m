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

#include "LSSetCompanyCommand.h"

@class NSArray;

@interface LSSetTeamCommand : LSSetCompanyCommand
{
@protected
  NSArray *accounts;
}

@end

#import "common.h"

@implementation LSSetTeamCommand

- (void)dealloc {
  [self->accounts release];
  [super dealloc];
}

/* command methods */

- (void)_setStaffInContext:(id)_context {
  BOOL isOk  = NO;
  id   staff = nil;
  id   team  = [self object]; 

  staff = [[team valueForKey:@"toStaff"] lastObject];
    
  [staff takeValue:[team valueForKey:@"description"]
         forKey:@"description"];
  [staff takeValue:[NSNumber numberWithBool:NO] forKey:@"isAccount"];
  [staff takeValue:[NSNumber numberWithBool:YES] forKey:@"isTeam"];
  [staff takeValue:@"updated" forKey:@"dbStatus"];

  isOk = [[self databaseChannel] updateObject:staff];

  [LSDBObjectCommandException raiseOnFail:isOk object:self
                              reason:[sybaseMessages description]];
}

- (void)_setMemberAssignmentsInContext:(id)_context {
  LSRunCommandV(_context, @"team", @"setmembers",
                @"group", [self object],
                @"members", self->accounts, nil);
}

- (void)_prepareForExecutionInContext:(id)_context {
  [self takeValue:[NSNumber numberWithBool:YES] forKey:@"isTeam"];
  [super _prepareForExecutionInContext:_context];
}

- (void)_executeInContext:(id)_context {
  [super _executeInContext:_context];
  [self _setStaffInContext:_context];

  if (self->accounts != nil) 
    [self _setMemberAssignmentsInContext:_context];
}

/* record initializer */

- (NSString *)entityName {
  return @"Team";
}

/* accessors */

- (void)setAccounts:(NSArray *)_accounts {
  ASSIGN(accounts, _accounts);
}

- (NSArray *)accounts {
  return self->accounts;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"accounts"] || [_key isEqualToString:@"toMember"])
    [self setAccounts:_value];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"accounts"] || [_key isEqualToString:@"toMember"])
    return [self accounts];
  else
    return [super valueForKey:_key];
}

@end /* LSSetTeamCommand */
