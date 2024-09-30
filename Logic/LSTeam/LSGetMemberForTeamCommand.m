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

#include <LSAddress/LSGetMemberForCompanyCommand.h>

/*
  LSGetMemberForTeamCommand

  eg used by LSQueryAppointments:
    team::members(@"groups",[teamGids allObjects], @"fetchGlobalIDs", YES);
*/

@interface LSGetMemberForTeamCommand : LSGetMemberForCompanyCommand
@end

#include "common.h"

@implementation LSGetMemberForTeamCommand

static NSComparisonResult compareAccounts(id member1, id member2, void *context) 
{
  NSString *name1;
  NSString *name2;
  
  name1 = [member1 valueForKey:@"login"];
  name2 = [member2 valueForKey:@"login"];
  if (name1 == nil) name1 = @"";
  if (name2 == nil) name2 = @"";
  if (name1 == name2) return NSOrderedSame;
  
  return [name1 compare:name2];
}

/* record initializer */

- (NSString *)entityName {
  return @"Team";
}

- (NSString *)memberEntityName {
  return @"Person";
}

- (void)_fetchMembersOfTeam:(id)team inContext:(id)_context {
  NSMutableArray *m;
    
  if (![team isNotNull])
    return;
  if ([team isKindOfClass:[EOGlobalID class]])
    return;
  if ((m = [team valueForKey:@"members"]) == nil)
    return;
  
#if DEBUG
  [self assert:(![m containsObject:[NSNull null]])
	format:@"invalid members %@ of team: %@", m, team];
#endif
  if (![m isKindOfClass:[NSMutableArray class]])
    m = [m mutableCopy];
  else
    m = [m retain];
  
  [m sortUsingFunction:compareAccounts context:self];
        
  /* get extended attributes  */
  LSRunCommandV(_context, @"person", @"get-extattrs",
		@"objects", m,
		@"relationKey", @"companyValue", nil);
  
  /* get telephones */
  LSRunCommandV(_context, @"person", @"get-telephones",
		@"objects", m,
		@"relationKey", @"telephones", nil);
  
  [m release];
}

- (void)_executeInContext:(id)_context {
  NSEnumerator *e;
  id team;
  
  [super _executeInContext:_context];
  
  /* fetch additional info for members */
  
  // TODO: collect all members in one set and perform just one fetch!
  e = [[self groups] objectEnumerator];
  while ((team = [e nextObject]) != nil)
    [self _fetchMembersOfTeam:team inContext:_context];
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"team"] || [_key isEqualToString:@"object"]) {
    [self setGroup:_value];
    return;
  }
  if ([_key isEqualToString:@"teams"]) {
    [self setGroups:_value];
    return;
  }
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"team"] || [_key isEqualToString:@"object"])
    return [self group];
  if ([_key isEqualToString:@"teams"])
    return [self groups];
  
  return [super valueForKey:_key];
}

@end /* LSGetMemberForTeamCommand */
