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

@interface LSNewTeamCommand : LSNewCompanyCommand
{
  NSArray *accounts;
}

@end

#include "common.h"

@implementation LSNewTeamCommand

static NSString *OGoTeamCreatorRoleName = nil;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  OGoTeamCreatorRoleName = [[ud stringForKey:@"OGoTeamCreatorRoleName"] copy];
  if ([OGoTeamCreatorRoleName isNotEmpty]) {
    NSLog(@"Note: members of role team '%@' are allowed to create teams.",
          OGoTeamCreatorRoleName);
  }
}

- (void)dealloc {
  [self->accounts release];
  [super dealloc];
}

/* operation */

- (void)_newMemberAssignmentsInContext:(id)_context {
  LSRunCommandV(_context, @"team", @"setmembers",
                @"group",   [self object],
                @"members", self->accounts, nil);
}

- (void)_prepareForExecutionInContext:(id)_context {
  [self takeValue:[NSNumber numberWithBool:YES] forKey:@"isTeam"];
  [super _prepareForExecutionInContext:_context];
}

- (void)_executeInContext:(id)_context {
  if ([OGoTeamCreatorRoleName isNotEmpty]) {
    if (![_context isRoot]) {
      id loginAccount = [_context valueForKey:LSAccountKey];
      NSArray *myTeams;
    
      // TODO: improve efficiency
      myTeams = [_context runCommand:@"account::teams",
                          @"account",   loginAccount,
                          @"returnType", intObj(LSDBReturnType_ManyObjects),
                          nil];
      myTeams = [myTeams valueForKey:@"description"];
      
      [self assert:[myTeams containsObject:OGoTeamCreatorRoleName]
            reason:@"no permission to create teams!"];
    }
  }
  
  [super _executeInContext:_context];
  
  if (self->accounts != nil) 
    [self _newMemberAssignmentsInContext:_context];
}

/* initialize records */

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

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"accounts"] || [_key isEqualToString:@"toMember"])
    [self setAccounts:_value];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"accounts"] || [_key isEqualToString:@"toMember"])
    return [self accounts];

  return [super valueForKey:_key];
}

@end /* LSNewTeamCommand */
