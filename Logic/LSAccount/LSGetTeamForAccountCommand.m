/*
  Copyright (C) 2000-2003 SKYRIX Software AG

  This file is part of OGo

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

#include <LSGetCompanyForMemberCommand.h>

@interface LSGetTeamForAccountCommand : LSGetCompanyForMemberCommand
@end

@interface LSGetTeamForAccountCommand(PrivateMethodes)
- (BOOL)fetchGlobalIDs;
@end /* LSGetTeamForAccountCommand(PrivateMethodes) */

#import "common.h"

@implementation LSGetTeamForAccountCommand

// record initializer

- (NSString *)entityName {
  return @"Person";
}

- (NSString *)groupEntityName {
  return @"Team";
}

- (NSString *)relationKey {
  return @"groups";
}

- (void)_executeInContext:(id)_context {
  NSString *cacheKey    = nil;
  NSArray  *cachedTeams = nil;
  id       companyId    = nil;

  if ([[self members] count] > 1) {
    [super _executeInContext:_context];
    return;
  }
  
  cacheKey = ([self fetchGlobalIDs])
    ? @"_cache_account_teamGIDs"
    : @"_cache_account_teams";

  companyId = [self member];
  companyId = ([companyId isKindOfClass:[EOKeyGlobalID class]])
    ? [[companyId keyValuesArray] lastObject]
    : [companyId valueForKey:@"companyId"];

  cacheKey = [cacheKey stringByAppendingString:[companyId stringValue]];
  cachedTeams = [_context valueForKey:cacheKey];
  
  if (cachedTeams) {
    [self setReturnValue:cachedTeams];
  }
  else {
    [super _executeInContext:_context];
    [_context takeValue:[self returnValue] forKey:cacheKey];
  }
}

// key/value coding

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"account"] || [_key isEqualToString:@"object"])
    [self setMember:_value];
  else if ([_key isEqualToString:@"accounts"])
    [self setMembers:_value];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"account"] || [_key isEqualToString:@"object"])
    return [self member];
  else if ([_key isEqualToString:@"accounts"])
    return [self members];
  else
    return [super valueForKey:_key];
}

@end
