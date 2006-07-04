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

#include <LSFoundation/LSDBObjectBaseCommand.h>

@class NSArray;

@interface LSResolveAccountsCommand : LSDBObjectBaseCommand
{
@private
  NSArray *staffList;
  BOOL    returnSet;
  BOOL    fetchGlobalIDs;
  BOOL    teamIsGID;
}

- (BOOL)returnSet;

@end

#include "common.h"

// TODO: 'fetchGlobalIDs' also makes 'object/staffList' a GID array, should
//       probably be a separate key (teamGIDs or something)

/*
    team::expand
      <config> : LSResolveAccountsCommand
     
      >[NSArray]        object/staffList (array of EOs) 
      >[EO]             staff
      >[BOOL]           returnSet
      >[BOOL]           fetchGlobalIDs
      = [NSArray/NSSet] resolved accounts (array of EO:Person (isAccount=yes))

      The command takes either a list of EOs or a single EO and expands all
      occurences of a team to it's members. If 'returnSet' is YES, the result
      of the command is a NSSet object, otherwise an NSArray.
      The result set is distinct, that is, no object is contained twice.
*/

@interface _LSResolveAccountsCommand_Cache : NSObject
{
@public
  NSHashTable *set;
  id          cmdTeamMembers;
}
@end

@implementation LSResolveAccountsCommand

+ (int)version {
  return [super version] + 1;
}

/* accessors */

- (void)setFetchGlobalIDs:(BOOL)_flag {
  self->fetchGlobalIDs = _flag;
}
- (BOOL)fetchGlobalIDs {
  return self->fetchGlobalIDs;
}

/* command methods */

- (void)_executeForGlobalIDsInContext:(id)_context {
  NSEnumerator *staffEnum;
  id           gid;
  NSMutableSet *gids;
  NSNumber     *fetchMembersAsGID;
  
  fetchMembersAsGID = [NSNumber numberWithBool:[self fetchGlobalIDs]];
  
  gids = [[NSMutableSet alloc] init];
  
  staffEnum = [[self object] objectEnumerator];
  while ((gid = [staffEnum nextObject])) {
    NSSet *members;
    
    if (![[gid entityName] isEqualToString:@"Team"]) {
      /* not a team */
      [gids addObject:gid];
      continue;
    }
      
    /* found a team */
      
    members = LSRunCommandV(_context,
                            @"team", @"members",
                            @"group", gid,
                            @"fetchGlobalIDs", fetchMembersAsGID,
                            @"returnSet",      [NSNumber numberWithBool:YES],
                            nil);
    if (members) [gids unionSet:members];
  }
  
  if ([self returnSet])
    [self setReturnValue:[[gids copy] autorelease]];
  else
    [self setReturnValue:[gids allObjects]];
  
  [gids release];
}

- (void)_executeInContext:(id)_context {
  /* TODO: split up this large method .. */
  _LSResolveAccountsCommand_Cache *cache;
  NSEnumerator *staffEnum     = nil;
  id           staffItem      = nil;

  if ([self fetchGlobalIDs] || self->teamIsGID) {
    [self _executeForGlobalIDsInContext:_context];
    return;
  }
  
  cache = [_context valueForKey:@"_cache_ResolveAccounts"];
  if (cache == nil) {
    cache =
      [[[_LSResolveAccountsCommand_Cache alloc] init] autorelease];
    
    [_context takeValue:cache forKey:@"_cache_ResolveAccounts"];
    
    cache->cmdTeamMembers = [LSLookupCommand(@"team", @"members") retain];
    cache->set = NSCreateHashTable(NSObjectHashCallBacks, 30);
  }
  
  [self assert: (cache != nil) reason: @"got no cache .."];

  [self assert:[[self object] isNotEmpty] reason:@"no staff list is set !"];
  
  staffEnum  = [[self object] objectEnumerator];
  while ((staffItem = [staffEnum nextObject]) != nil) {
    NSArray *members = nil;
    register IMP objAtIdx;
    register int i, n;
    
    if (![[staffItem valueForKey:@"isTeam"] boolValue])
      NSHashInsertIfAbsent(cache->set, staffItem);
    
    if ((members = [staffItem valueForKey:@"members"]) == nil) {
      [cache->cmdTeamMembers takeValue:staffItem forKey:@"object"];
      [cache->cmdTeamMembers runInContext:_context];
      members = [staffItem valueForKey:@"members"];
    }
      
    if (members == nil)
      continue;
    
    objAtIdx = [members methodForSelector:@selector(objectAtIndex:)];
    [self assert: (objAtIdx != NULL)
          reason: @"could not get -objectAtIndex: method"];

    for (i = 0, n = [members count]; i < n; i++) {
      NSHashInsertIfAbsent(cache->set,
                           objAtIdx(members, @selector(objectAtIndex:), i));
    }
  }
  
  {
    NSHashEnumerator e = NSEnumerateHashTable(cache->set);
    id  result;
    id  obj;
    IMP addObj;

    result = self->returnSet
      ? [[NSMutableSet alloc] initWithCapacity:16]
      : [[NSMutableArray alloc] initWithCapacity:16];

    addObj = [result methodForSelector:@selector(addObject:)];
    [self assert:(addObj != NULL)
          reason: @"could not get -addObject: method of result collection"];

    while ((obj = NSNextHashEnumeratorItem(&e)))
      addObj(result, @selector(addObject:), obj);
    
    [self setReturnValue:result];
    [result release]; result = nil;
  }

  if (cache->set) NSResetHashTable(cache->set);
  //NSLog(@"LSResolveAccountsCommand executed");
}

/* accessors */

- (void)setTeamGlobalID:(EOGlobalID *)_gid {
  [self setObject:_gid ? [NSArray arrayWithObject:_gid] : nil];
  self->teamIsGID = YES;
}

- (void)setStaff:(id)_staff {
  if ([_staff isKindOfClass:[EOGlobalID class]])
    [self setTeamGlobalID:_staff];
  else
    [self setObject:_staff ? [NSArray arrayWithObject:_staff] : nil];
}
- (id)staff {
  return [[self object] objectAtIndex:0];
}

- (void)setReturnSet:(BOOL)_set {
  self->returnSet = _set;
}
- (BOOL)returnSet {
  return self->returnSet;
}

/* key/value coding */

- (void)_raiseInvalidKeyException:(NSString *)_key {
  NSString *s;
  
  s = [NSString stringWithFormat:
		  @"key '%@' is not valid in domain '%@' for operation '%@'.",
		  _key, [self domain], [self operation]];
  [LSDBObjectCommandException raiseOnFail:NO object:self reason:s];
}

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if (![_key isNotEmpty])
    return;
  
  if ([_key isEqualToString:@"object"] || 
      [_key isEqualToString:@"staffList"] ||
      [_key isEqualToString:@"teams"])
    [self setObject:_value];
  else if ([_key isEqualToString:@"staff"])
    [self setStaff:_value];
  else if ([_key isEqualToString:@"team"])
    [self setStaff:_value];
  else if ([_key isEqualToString:@"teamGID"])
    [self setTeamGlobalID:_value];
  else if ([_key isEqualToString:@"returnSet"])
    [self setReturnSet:[_value boolValue]];
  else if ([_key isEqualToString:@"fetchGlobalIDs"])
    [self setFetchGlobalIDs:[_value boolValue]];
  else
    [self _raiseInvalidKeyException:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"object"] || [_key isEqualToString:@"staffList"])
    return [self object];
  if ([_key isEqualToString:@"staff"])
    return [self staff];
  if ([_key isEqualToString:@"returnSet"])
    return [NSNumber numberWithBool:[self returnSet]];
  if ([_key isEqualToString:@"fetchGlobalIDs"])
    return [NSNumber numberWithBool:[self fetchGlobalIDs]];

  return nil;
}

@end /* LSResolveAccountsCommand */


@implementation _LSResolveAccountsCommand_Cache

- (void)dealloc {
  if (self->set != NULL) {
    NSFreeHashTable(self->set);
    self->set = NULL;
  }
  [self->cmdTeamMembers release];
  [super dealloc];
}

@end /* _LSResolveAccountsCommand_Cache */
