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

#include "NSObject+EKVC.h"
#include "SkyAccountApplication.h"
#include "SkyAccountAction.h"
#include "common.h"

@interface SkyAccountAction(AccountActions)
- (id)_getAccountsForIds:(NSArray *)_uids;
@end /* SkyAccountAction(AccountActions) */

@implementation SkyAccountAction(GroupActions)

- (NSMutableDictionary *)_buildGroupFromDB:(id)_group {
  NSEnumerator        *enumerator;
  id                  key, obj;
  NSMutableDictionary *dict;

  dict = [NSMutableDictionary dictionaryWithCapacity:8];

  enumerator = [[self groupKeys] objectEnumerator];

  while ((key = [enumerator nextObject])) {
    if ([(obj = [_group valueForKey:key]) isNotNull]) {
      [dict setObject:obj forKey:key];
    }
  }
  return dict;
}


- (id)_getGroupById:(NSString *)_uid {
  id acc;

  if (![_uid length])
    return nil;
  
  acc = [[self commandContext]
                runCommand:@"team::get",
                @"companyId", [NSNumber numberWithInt:[_uid intValue]],
                nil];
  return [acc isKindOfClass:[NSArray class]]?[acc lastObject]:acc;
}

- (void)setGroupValues:(id)_group toDBObj:(id)_dbObj {
  NSEnumerator *enumerator;
  id           key, obj;

  enumerator = [[self groupKeys] objectEnumerator];

  while ((key = [enumerator nextObject])) {
    if ([(obj = [_group valueForKey:key]) isNotNull]) {
      [_dbObj takeValue:obj forKey:key];
    }
  }
}

- (NSDictionary *)getGroupAction:(NSString *)_uid {
  return [[self application] groupById:_uid];
}

- (NSDictionary *)getGroupByNameAction:(NSString *)_name {
  return [[self application] groupByName:_name];
}

- (NSArray *)getGroupsAction {
  return [[self application] allGroups];
}

- (NSArray *)getGroupNamesAction {
  return [[[self application] allGroups]
                 map:@selector(objectForKey:) with:@"description"];
}


- (id)updateGroupAction:(NSString *)_uid :(NSDictionary *)_group {
  id       group;
  NSString *oldName;
  BOOL     containsName;

  containsName = [[_group allKeys] containsObject:@"description"];

  if (![self isRoot]) {
    return [self buildExceptonWithNumber:1
                 reason:@"only root can change groups"
                 command:__PRETTY_FUNCTION__];
  }
  if (!(group = [self _getGroupById:_uid])) {
    return [self buildExceptonWithNumber:3
                 reason:@"couldn`t fetch group"
                 command:__PRETTY_FUNCTION__];
  }
  oldName = nil;
  if (containsName) {
    oldName = [group valueForKey:@"description"];
  }
  [self setGroupValues:_group toDBObj:group];

  if (![[self commandContext] runCommand:@"team::set",
                              @"object", group,
                              nil]) {
    return [self buildExceptonWithNumber:2
                 reason:@"team::set failed" command:__PRETTY_FUNCTION__];
  }
  if (containsName) {
    [[self application] flushCachesForGroupName:oldName];
  }
  [[self application] insertGroup:[self _buildGroupFromDB:group]];
  return [NSNumber numberWithBool:YES];
}

- (id)createGroupAction:(NSDictionary *)_group {
  id       group;
  NSString *n;
  NSMutableDictionary *dict;

  dict = [NSMutableDictionary dictionaryWithCapacity:[[self groupKeys] count]];
  {
    NSEnumerator *enumerator;
    id           obj, key;

    enumerator = [[self groupKeys] objectEnumerator];
    while ((key = [enumerator nextObject])) {
      if ((obj = [_group objectForKey:key])) {
        [dict setObject:obj forKey:key];
      }
    }
  }
  if (![self isRoot]) {
    return [self buildExceptonWithNumber:1
                 reason:@"only root can create groups"
                 command:__PRETTY_FUNCTION__];
  }
  if (!([n = [_group objectForKey:@"description"] length])) {
    return [self buildExceptonWithNumber:4
                 reason:@"Missing reqiered attributes"
                 command:__PRETTY_FUNCTION__];
  }
  if ([[self application] groupByName:n]) {
    return [self buildExceptonWithNumber:4
                 reason:@"group is already used"
                 command:__PRETTY_FUNCTION__];
  }
  if (!(group = [[self commandContext] runCommand:@"team::new"
                                         arguments:_group])) {
    return [self buildExceptonWithNumber:2
                 reason:@"team::new failed" command:__PRETTY_FUNCTION__];
  }
  [[self application] insertGroup:[self _buildGroupFromDB:group]];
  return [NSNumber numberWithBool:YES];
}

- (id)deleteGroupAction:(NSString *)_uid {
  id group;

  
  if (![self isRoot]) {
    return [self buildExceptonWithNumber:1
                 reason:@"only root can delete groups"
                 command:__PRETTY_FUNCTION__];
  }
  _uid = [_uid stringValue];
  
  if (!(group = [self _getGroupById:_uid])) {
    return [self buildExceptonWithNumber:3
                 reason:@"couldn`t fetch group"
                 command:__PRETTY_FUNCTION__];
  }
  if (![[self commandContext] runCommand:@"team::delete",
                              @"object", group, nil]) {
    return [self buildExceptonWithNumber:2
                 reason:@"team::delete failed" command:__PRETTY_FUNCTION__];
  }
  
  [[self application] flushCachesForGid:_uid];
  return [NSNumber numberWithBool:YES];
}

- (id)groupMemberAction:(NSString *)_gid {
  return [[self application] accountsForGroup:_gid];
}

- (id)addAccountsAction:(NSString *)_gid :(NSArray *)_accounts {
  id group;
  id accounts, teamAccounts;
  
  if (![self isRoot]) {
    return [self buildExceptonWithNumber:1
                 reason:@"only root can add accounts to groups"
                 command:__PRETTY_FUNCTION__];
  }
  group = [self _getGroupById:_gid];
  teamAccounts = [[self commandContext] runCommand:@"team::members",
                                        @"suppressAdditionalInfos",
                                        [NSNumber numberWithBool:YES],
                                        @"team", group, nil];
  
  
  accounts = [self _getAccountsForIds:_accounts];
  teamAccounts = [NSMutableSet setWithArray:teamAccounts];
  [teamAccounts addObjectsFromArray:accounts];
  teamAccounts = [teamAccounts allObjects];

  [[self commandContext] runCommand:@"team::setmembers",
                         @"group", group,
                         @"members", teamAccounts, nil];
    
  [[self application] addAccounts:_accounts toGroup:_gid];
  return [NSNumber numberWithBool:YES];
}

- (id)removeAccountsAction:(NSString *)_gid :(NSArray *)_accounts {
  id group;
  id accounts, teamAccounts;
  
  if (![self isRoot]) {
    return [self buildExceptonWithNumber:1
                 reason:@"only root can add accounts to groups"
                 command:__PRETTY_FUNCTION__];
  }
  group = [self _getGroupById:_gid];
  teamAccounts = [[self commandContext] runCommand:@"team::members",
                                        @"suppressAdditionalInfos",
                                        [NSNumber numberWithBool:YES],
                                        @"team", group, nil];
  
  
  accounts = [self _getAccountsForIds:_accounts];
  teamAccounts = [teamAccounts mutableCopy];
  [teamAccounts removeObjectsInArray:accounts];
  AUTORELEASE(teamAccounts);

  [[self commandContext] runCommand:@"team::setmembers",
                         @"group", group,
                         @"members", teamAccounts, nil];
  [[self application] removeAccounts:_accounts fromGroup:_gid];
  return [NSNumber numberWithBool:YES];
}

@end /* SkyAccountAction(GroupActions) */
