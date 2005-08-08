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

#include <LSSearch/LSExtendedSearchCommand.h>

@interface LSExtendedSearchCommand(PRIVATE)
- (NSNumber *)fetchIds;
@end

@interface LSExtendedSearchTeamCommand : LSExtendedSearchCommand
{
  NSNumber *onlyTeamsWithAccountId;
}

@end

#include "common.h"

@interface LSExtendedSearchCommand(Privates)
- (NSArray *)_fetchObjects:(id)_context;
- (NSArray *)_fetchIds:(id)_context;
@end

@implementation LSExtendedSearchTeamCommand

static NSNumber *yesNum = nil;

+ (int)version {
  return [super version] /* v2 */;
}
+ (void)initialize {
  NSAssert2([super version] == 2,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);

  yesNum = [[NSNumber numberWithBool:YES] retain];
}

- (void)dealloc {
  [self->onlyTeamsWithAccountId release];
  [super dealloc];
}

/* command methods */

- (EOSQLQualifier *)extendedSearchQualifier:(void *)_context {
  EOSQLQualifier *qualifier;
  EOSQLQualifier *isArchivedQualifier;

  qualifier = [super extendedSearchQualifier:_context];
  
  isArchivedQualifier = 
    [[EOSQLQualifier alloc] initWithEntity:[self entity]
                            qualifierFormat:@"dbStatus <> 'archived'"];
  [qualifier conjoinWithQualifier:isArchivedQualifier];
  [isArchivedQualifier release];
  return qualifier;
}

- (NSString *)entityName {
  return @"Team";
}

/* helper methods */

- (BOOL)doesArray:(NSArray *)_gids containPrimaryKey:(id)_pkey {
  unsigned i, count;
  
  if (![_pkey isNotNull])
    return NO;
  if ((count = [_gids count]) == 0)
    return NO;
  
  for (i = 0; i < count; i++) {
    EOKeyGlobalID *gid;
    
    gid = [_gids objectAtIndex:i];
    if (![gid isNotNull]) continue;
    if (![gid isKindOfClass:[EOGlobalID class]])
      gid = (EOKeyGlobalID *)[(id)gid globalID];
    
    if ([_pkey isEqual:[gid keyValues][0]])
      return YES;
  }
  return NO;
}

- (NSArray *)filterResults:(NSArray *)_results onMembers:(id)_members {
  NSMutableArray *ma = nil;
  unsigned i, count;
  
  if (![_results isNotEmpty] || ![self->onlyTeamsWithAccountId isNotNull])
    return _results;
  
  /* just one member matched (results has one record) ... */

  if ([_members isKindOfClass:[NSArray class]]) {
    if ([self doesArray:_members 
              containPrimaryKey:self->onlyTeamsWithAccountId])
      return _results;
    return nil;
  }
  
  /* (zero or) more than one member matched ... */
  
  for (i = 0, count = [_results count]; i < count; i++) {
    NSArray *mmembers;
      
    mmembers = 
      [(NSDictionary *)_members objectForKey:[_results objectAtIndex:i]];
    
    if ([self doesArray:mmembers 
              containPrimaryKey:self->onlyTeamsWithAccountId])
      continue;
    
    if (ma == nil)
      ma = [[_results mutableCopy] autorelease];
    [ma removeObject:[_results objectAtIndex:i]];
  }
  
  return (ma != nil) ? ma : _results;
}

/* override fetch methods to support onlyTeamsWithAccountId */

- (NSArray *)_fetchObjects:(id)_context {
  NSArray *results;
  id      members; /* NSArray or NSDictionary */
  
  results = [super _fetchObjects:_context];
  if (![results isNotEmpty] || ![self->onlyTeamsWithAccountId isNotNull])
    return results;
  
  members = [_context runCommand:@"team::members",
                      @"groups", [results valueForKey:@"globalID"],
                      @"fetchGlobalIDs", yesNum,
                      nil];
  
  return [self filterResults:results onMembers:members];
}

- (NSArray *)_fetchIds:(id)_context {
  NSArray *results;
  id      members; /* NSArray or NSDictionary */
  
  results = [super _fetchIds:_context];
  if (![results isNotEmpty] || ![self->onlyTeamsWithAccountId isNotNull])
    return results;
  
  members = [_context runCommand:@"team::members",
                      @"groups", results,
                      @"fetchGlobalIDs", yesNum,
                      nil];
  // TODO: fix that different-result-objects-crap in team::members!
  
  return [self filterResults:results onMembers:members];
}

/* accessors */

- (void)setOnlyTeamsWithAccount:(id)_account {
  /* extract the id */
  if ([_account isKindOfClass:[EOKeyGlobalID class]])
    _account = [(EOKeyGlobalID *)_account keyValues][0];
  else if ([_account isKindOfClass:[NSNumber class]])
    ;
  else if ([_account isNotNull]) {
    _account = [_account valueForKey:@"globalID"];
    if ([_account isNotNull]) 
      _account = [(EOKeyGlobalID *)_account keyValues][0];
  }
  else
    _account = nil;
  
  ASSIGN(self->onlyTeamsWithAccountId, _account);
}
- (NSNumber *)onlyTeamsWithAccount {
  return self->onlyTeamsWithAccountId;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"onlyTeamsWithAccount"])
    [self setOnlyTeamsWithAccount:_value];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"onlyTeamsWithAccount"])
    return [self onlyTeamsWithAccount];

  return [super valueForKey:_key];
}

@end /* LSExtendedSearchTeamCommand */
