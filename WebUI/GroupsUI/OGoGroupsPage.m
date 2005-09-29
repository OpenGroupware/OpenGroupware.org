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

#include <OGoFoundation/OGoContentPage.h>

@class NSArray;

@interface OGoGroupsPage : OGoContentPage
{
  NSArray *groupList;
  id group;
  id account;
}

- (NSArray *)_fetchMyTeams;

@end

#include "common.h"

@implementation OGoGroupsPage

static NSNotificationCenter *nc = nil;

+ (void)initialize {
  if (nc == nil)
    nc = [[NSNotificationCenter defaultCenter] retain];
}

- (void)_registerResetNotification:(NSString *)_name {
  [nc addObserver:self selector:@selector(resetList:) name:_name object:nil];
}

- (id)init {
  id p;

  /* this component is a session-singleton */
  if ((p = [self persistentInstance]) != nil) {
    [self release];
    return [p retain];
  }
  
  if ((self = [super init]) != nil) {
    [self registerAsPersistentInstance];
    
    [self _registerResetNotification:LSWNewAccountNotificationName];
    [self _registerResetNotification:LSWDeletedAccountNotificationName];
    [self _registerResetNotification:LSWNewTeamNotificationName];
    [self _registerResetNotification:LSWDeletedTeamNotificationName];
    [self _registerResetNotification:LSWUpdatedAccountNotificationName];
    [self _registerResetNotification:LSWUpdatedTeamNotificationName];
  }
  return self;
}

- (void)dealloc {
  [nc removeObserver:self];
  
  [self->groupList release];
  [self->group     release];
  [self->account   release];
  [super dealloc];
}

/* accessors */

- (void)setGroup:(id)_value {
  ASSIGN(self->group, _value);
}
- (id)group {
  return self->group;
}

- (void)setAccount:(id)_value {
  ASSIGN(self->account, _value);
}
- (id)account {
  return self->account;
}

- (void)setGroupList:(NSArray *)_value {
  ASSIGN(self->groupList, _value);
}
- (NSArray *)groupList {
  if (self->groupList == nil)
    self->groupList = [[self _fetchMyTeams] retain];
  
  return self->groupList;
}

/* operations */

- (NSArray *)_fetchMyTeams {
  LSCommandContext *cmdctx;
  NSArray *gids, *teams;
  
  cmdctx = [[self session] commandContext];
  
  /* fetch global ids of teams where I'm a member */
  
  // TODO: also fetch teams where the user is the 'ownerId'?!
  gids = [cmdctx runCommand:@"team::extended-search",
                 @"fetchGlobalIDs",       @"YES",
                 @"onlyTeamsWithAccount", [[self session] activeAccount],
                 @"description",          @"%%", 
                 nil];
  if (![gids isNotNull]) {
    [self setErrorString:@"Did not find teams for login account?!"];
    return nil;
  }
  
  /* fetch information about the teams */
  
  teams = [cmdctx runCommand:@"team::get-by-globalID",
                  @"gids", gids, nil];
  
  /* fetch members */

  [cmdctx runCommand:@"team::members",
	  @"teams",      teams,
	  @"returnType", intObj(LSDBReturnType_ManyObjects), 
	  nil];
  
  return teams;
}

/* notifications */

- (void)sleep {
  [self setGroup:nil];
  [self setAccount:nil];
  [super sleep];
}

- (void)resetList:(NSNotification *)_nc {
  [self setGroupList:nil];
  [self setGroup:nil];
  [self setAccount:nil];
}

@end /* OGoGroupsPage */
