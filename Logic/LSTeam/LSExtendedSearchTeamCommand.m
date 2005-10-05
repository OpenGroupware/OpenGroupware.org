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

  Arguments:
    fetchGlobalIDs        - bool
    onlyTeamsWithAccount  - pkey | gid | EO
    includeTeamsWithOwner - pkey | gid | EO
    * - EO fields
    TODO: check args of parent-class

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
  NSNumber *includeTeamsWithOwnerId;
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
  [self->onlyTeamsWithAccountId  release];
  [self->includeTeamsWithOwnerId release];
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

- (NSArray *)filterResults:(NSArray *)_results onMembers:(id)_members
  andOwnerIds:(NSDictionary *)_ownerIds
{
  NSMutableArray *ma = nil;
  unsigned i, count;
  
  if (![_results isNotEmpty] || ![self->onlyTeamsWithAccountId isNotNull])
    return _results;
  
  /* 
     Just one member matched (results has one record) ... 
     
     If multiple ones matched, '_members' will be an NSDictionary.
  */
  if ([_members isKindOfClass:[NSArray class]]) {
    if ([_results count] != 1)
      [self errorWithFormat:@"incorrect internal assumption: %@", _results];
    
    if ([self doesArray:_members 
              containPrimaryKey:self->onlyTeamsWithAccountId])
      return _results;
    
    if ([self->includeTeamsWithOwnerId isNotNull]) {
      if ([[[_ownerIds allValues] lastObject] 
                       isEqual:self->includeTeamsWithOwnerId])
        return _results;
    }
    
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
    
    if ([self->includeTeamsWithOwnerId isNotNull]) {
      NSNumber *ownerId;
      
      ownerId = [_ownerIds objectForKey:eoOrGID];
      if ([ownerId isEqual:self->includeTeamsWithOwnerId])
        continue;

      /* 
	 Note: this also filters out teams owned by 'root' (10000). This is
	       indeed intended, because we want all teams where we are a
	       member and then those teams which are owned by us.
      */
    }
    
    /* did not contain member, make mutable and remove */
    
#if DEBUG && 0
    [self debugWithFormat:@"REMOVE: %@ (owner=%@ vs %@)", 
          eoOrGID, [_ownerIds objectForKey:eoOrGID],
          self->includeTeamsWithOwnerId];
#endif
    
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

- (id)_fixupOwnerResult:(id)_owners results:(NSArray *)_results {
  // TODO: quite hackish, but well ...
  NSMutableDictionary *ownerMap;
  
  if (_owners == nil)
    return nil;
  
  ownerMap = [NSMutableDictionary dictionaryWithCapacity:[_owners count]];
  
  if ([_owners isKindOfClass:[NSArray class]]) {
    unsigned i, count;
    
    for (i = 0, count = [_results count]; i < count; i++) {
      [ownerMap setObject:[_owners objectAtIndex:i] 
                forKey:[_results objectAtIndex:i]];
    }
  }
  else if ([_owners isKindOfClass:[NSDictionary class]]) {
    NSEnumerator *keys;
    EOGlobalID   *key;

    keys = [_owners keyEnumerator];
    while ((key = [keys nextObject]) != nil) {
      id value;
      
      if ((value = [(NSDictionary *)_owners objectForKey:key]) == nil)
        continue;
      
      if ([value isKindOfClass:[NSDictionary class]]) {
        if ((value = [value valueForKey:@"ownerId"]) == nil)
          continue;
      }
      
      [ownerMap setObject:value forKey:key];
    }
  }
  else
    [self errorWithFormat:@"unexpected object: %@", _owners];
  
  return ownerMap;
}

- (NSArray *)_fetchObjects:(id)_context {
  NSArray *results;
  id      members; /* NSArray or NSDictionary */
  NSDictionary *ownerIds;
  
  results = [super _fetchObjects:_context];
  if (![results isNotEmpty] || ![self->onlyTeamsWithAccountId isNotNull])
    return results;
  
  ownerIds = [self->includeTeamsWithOwnerId isNotNull]
    ? [results valueForKey:@"ownerId"]
    : nil;
  ownerIds = [self _fixupOwnerResult:ownerIds results:results];
  
  /* Note: the result is keyed on the global-id, not the EO! */
  members = [self _fetchMemberGIDsForTeamGIDs:[results valueForKey:@"globalID"]
                  inContext:_context];
  
  return [self filterResults:results onMembers:members andOwnerIds:ownerIds];
}

- (NSArray *)_fetchIds:(id)_context {
  NSDictionary *ownerIds = nil;
  NSArray *results;
  id      members; /* NSArray or NSDictionary */
  
  results = [super _fetchIds:_context];
  if (![results isNotEmpty] || ![self->onlyTeamsWithAccountId isNotNull])
    return results;
  
  if ([self->includeTeamsWithOwnerId isNotNull]) {
    static NSArray *ownerIdAttrs = nil;
    NSDictionary *tmp;
    
    if (ownerIdAttrs == nil) {
      ownerIdAttrs = 
        [[NSArray alloc] initWithObjects:@"globalID", @"ownerId", nil];
    }
    
    tmp = [_context runCommand:@"team::get-by-globalid",
                    @"gids", results,
                    @"attributes", ownerIdAttrs,
                    @"groupBy", @"globalID",
                    nil];
    
    ownerIds = [self _fixupOwnerResult:tmp results:results];
    
    if ([ownerIds count] < [results count]) {
      [self warnWithFormat:@"less owners than results! (%d vs %d)",
            [ownerIds count], [results count]];
    }
  }
  else
    ownerIds = nil;
  
  members = [self _fetchMemberGIDsForTeamGIDs:results inContext:_context];
  return [self filterResults:results onMembers:members andOwnerIds:ownerIds];
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
  
  ASSIGNCOPY(self->onlyTeamsWithAccountId, _account);
}
- (NSNumber *)onlyTeamsWithAccount {
  return self->onlyTeamsWithAccountId;
}

- (void)setIncludeTeamsWithOwner:(id)_account {
  _account = [self _primaryKeyFromObject:_account];
  
  ASSIGNCOPY(self->includeTeamsWithOwnerId, _account);
}
- (NSNumber *)includeTeamsWithOwner {
  return self->includeTeamsWithOwnerId;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"onlyTeamsWithAccount"]) {
    [self setOnlyTeamsWithAccount:_value];
    return;
  }
  if ([_key isEqualToString:@"includeTeamsWithOwner"]) {
    [self setIncludeTeamsWithOwner:_value];
    return;
  }
  
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"onlyTeamsWithAccount"])
    return [self onlyTeamsWithAccount];

  if ([_key isEqualToString:@"includeTeamsWithOwner"])
    return [self includeTeamsWithOwner];

  return [super valueForKey:_key];
}

@end /* LSExtendedSearchTeamCommand */
