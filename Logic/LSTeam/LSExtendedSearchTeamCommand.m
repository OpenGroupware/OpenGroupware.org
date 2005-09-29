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

/*
  LSExtendedSearchTeamCommand (team::extended-search)
  
  TODO: document

  Example call:
    gids = [cmdctx runCommand:@"team::extended-search",
                     @"fetchGlobalIDs",       @"YES",
                     @"onlyTeamsWithAccount", [[self session] activeAccount],
                     @"description",          @"%%", 
                   nil];
  TODO: is the 'description %%' required?

    ogo-runcmd  -login donald -password duck \
      team::extended-search \
      fetchGlobalIDs NO description '%%' onlyTeamsWithAccount 10290

  TODO: this filters members in memory, should be moved to the SQL qualifier.
*/

@interface LSExtendedSearchTeamCommand : LSExtendedSearchCommand
{
  NSNumber *onlyTeamsWithAccountId;
}

@end

#include "common.h"

@interface LSExtendedSearchCommand(PRIVATE)
- (NSNumber *)fetchIds;
@end

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

- (BOOL)doesArray:(NSArray *)_gidsOrEOs containPrimaryKey:(NSNumber *)_pkey {
  unsigned i, count;
  
  if (![_pkey isNotNull])
    return NO;
  if ((count = [_gidsOrEOs count]) == 0)
    return NO;
  
  for (i = 0; i < count; i++) {
    EOKeyGlobalID *gid;
    
    gid = [_gidsOrEOs objectAtIndex:i];
    if (![gid isNotNull]) /* NSNull */
      continue;
    
    if (![gid isKindOfClass:[EOGlobalID class]]) {
      /* treat it as an EO object */
      // TODO: also support NSNumbers?
      gid = (EOKeyGlobalID *)[(id)gid globalID];
    }
    
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
  
  /* 
     Just one member matched (results has one record) ... 
     
     If multiple ones matched, '_members' will be an NSDictionary.
  */
  if ([_members isKindOfClass:[NSArray class]]) {
    if ([self doesArray:_members 
              containPrimaryKey:self->onlyTeamsWithAccountId])
      return _results;
    return nil;
  }
  
  /* 
     (zero or) more than one member matched ... 
     
     '_members' is an array of GIDs keyed to the GID in '_results'.
  */
  for (i = 0, count = [_results count]; i < count; i++) {
    NSArray *mmembers;
    id eoOrGID;
    
    eoOrGID = [_results objectAtIndex:i];
    
    mmembers = [eoOrGID isKindOfClass:[EOGlobalID class]]
      ? [(NSDictionary *)_members objectForKey:eoOrGID]
      : [(NSDictionary *)_members objectForKey:
                           [eoOrGID valueForKey:@"globalID"]];
    
    if ([self doesArray:mmembers 
              containPrimaryKey:self->onlyTeamsWithAccountId])
      continue;
    
    /* did not contain member, make mutable and remove */
    
    if (ma == nil)
      ma = [[_results mutableCopy] autorelease];
    [ma removeObject:eoOrGID];
  }
  
  return (ma != nil) ? ma : _results;
}

/* override fetch methods to support onlyTeamsWithAccountId */

- (id)_fetchMemberGIDsForTeamGIDs:(NSArray *)_gids inContext:(id)_context {
  // TODO: fix that different-result-objects-crap in team::members!
  return [_context runCommand:@"team::members",
                     @"groups",         _gids,
                     @"fetchGlobalIDs", yesNum,
                   nil];
}

- (NSArray *)_fetchObjects:(id)_context {
  NSArray *results;
  id      members; /* NSArray or NSDictionary */
  
  results = [super _fetchObjects:_context];
  if (![results isNotEmpty] || ![self->onlyTeamsWithAccountId isNotNull])
    return results;
  
  /* Note: the result is keyed on the global-id, not the EO! */
  members = [self _fetchMemberGIDsForTeamGIDs:[results valueForKey:@"globalID"]
                  inContext:_context];
  
  return [self filterResults:results onMembers:members];
}

- (NSArray *)_fetchIds:(id)_context {
  NSArray *results;
  id      members; /* NSArray or NSDictionary */
  
  results = [super _fetchIds:_context];
  if (![results isNotEmpty] || ![self->onlyTeamsWithAccountId isNotNull])
    return results;
  
  members = [self _fetchMemberGIDsForTeamGIDs:results inContext:_context];
  return [self filterResults:results onMembers:members];
}

/* accessors */

- (NSNumber *)_primaryKeyFromObject:(id)_account {
  /* extract the id */
  if ([_account isKindOfClass:[EOKeyGlobalID class]])
    return [(EOKeyGlobalID *)_account keyValues][0];
  
  if ([_account isKindOfClass:[NSNumber class]])
    return _account;

  if ([_account isKindOfClass:[NSString class]]) {
    if (![_account isNotEmpty])
      return nil;
    
    if (!isdigit([_account characterAtIndex:0])) {
      // TODO: we might want to run a fetch in this case?
      //       => but not inside an accessor
      [self errorWithFormat:@"parameter is not a number: '%@'", _account];
      return nil;
    }
    
    return [NSNumber numberWithUnsignedInt:[_account unsignedIntValue]];
  }
  
  if ([_account isNotNull]) {
    _account = [_account valueForKey:@"globalID"];
    if ([_account isNotNull]) 
      _account = [(EOKeyGlobalID *)_account keyValues][0];
    
    return _account;
  }
  
  return nil;
}

- (void)setOnlyTeamsWithAccount:(id)_account {
  _account = [self _primaryKeyFromObject:_account];
  
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
