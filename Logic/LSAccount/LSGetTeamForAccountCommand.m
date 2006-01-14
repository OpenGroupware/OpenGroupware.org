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

#include <LSAddress/LSGetCompanyForMemberCommand.h>

/*
  Note: the members (accounts!) must be mutable objects since the superclass
        sets certain KVC keys in them. NSDictionary's are not sufficient, they
	will break on OSX.
*/

@interface LSGetTeamForAccountCommand : LSGetCompanyForMemberCommand
@end

@interface LSGetTeamForAccountCommand(PrivateMethodes)
- (BOOL)fetchGlobalIDs;
@end

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

/* run command */

- (void)_executeInContext:(id)_context {
  NSString *cacheKey    = nil;
  NSArray  *cachedTeams = nil;
  id       companyId    = nil;
  
  // TODO: not using cache for multiple members?
  if ([[self members] count] > 1) {
    [super _executeInContext:_context];
    return;
  }
  
  cacheKey = ([self fetchGlobalIDs])
    ? @"_cache_account_teamGIDs"
    : @"_cache_account_teams";

  companyId = [self member];
  companyId = ([companyId isKindOfClass:[EOKeyGlobalID class]])
    ? [companyId keyValues][0]
    : [companyId valueForKey:@"companyId"];

  cacheKey    = [cacheKey stringByAppendingString:[companyId stringValue]];
  cachedTeams = [_context valueForKey:cacheKey];
  
  if (cachedTeams) {
    [self setReturnValue:cachedTeams];
  }
  else {
    [super _executeInContext:_context];
    [_context takeValue:[self returnValue] forKey:cacheKey];
  }
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"account"] || [_key isEqualToString:@"object"])
    [self setMember:_value];
  else if ([_key isEqualToString:@"accounts"])
    [self setMembers:_value];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"account"] || [_key isEqualToString:@"object"])
    return [self member];
  if ([_key isEqualToString:@"accounts"])
    return [self members];

  return [super valueForKey:_key];
}

@end /* LSGetTeamForAccountCommand */
