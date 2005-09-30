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

@class NSArray, NSDictionary, NSNotification, NSNotificationCenter;

@interface OGoGroupsPage : OGoContentPage
{
  NSNotificationCenter *nc;
  NSArray      *groupList;
  NSArray      *writeableTeamGIDs;
  NSDictionary *pkeyToOwnerInfo;
  id group;
  id account;
}

- (void)_fetchMyTeams;
- (void)resetList:(NSNotification *)_notification;

@end

#include "common.h"
#include <EOControl/EOKeyGlobalID.h>

@implementation OGoGroupsPage

static NSArray *ownerFetchAttrs = nil;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  ownerFetchAttrs = [[ud arrayForKey:@"groupsui_owner_fetchattrs"] copy];
}

- (void)_registerResetNotification:(NSString *)_name {
  [self->nc addObserver:self selector:@selector(resetList:) 
            name:_name object:nil];
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
    
    /* we retain the NC, the NC doesn't retain us */
    self->nc = [[[self session] notificationCenter] retain];
    
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
  [self->nc removeObserver:self];
  [self->nc release]; self->nc = nil;
  
  [self->pkeyToOwnerInfo   release];
  [self->writeableTeamGIDs release];
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
- (EOGlobalID *)groupGlobalID {
  return [[self group] valueForKey:@"globalID"];
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
    [self _fetchMyTeams];
  
  return self->groupList;
}

- (BOOL)isGroupWritable {
  return [self->writeableTeamGIDs containsObject:[self groupGlobalID]];
}

- (NSDictionary *)ownerInfo {
  id tmp;
  
  if ((tmp = [self group]) == nil)
    return nil;
  if ((tmp = [tmp valueForKey:@"ownerId"]) == nil) /* can happen */
    return nil;
  
  return [self->pkeyToOwnerInfo objectForKey:tmp];
}

/* operations */

- (NSArray *)teamSortOrderings {
  static NSArray *sos = nil;
  
  if (sos == nil) {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    EOSortOrdering *so;
    
    so = [[EOSortOrdering alloc] 
           initWithPropertyList:[ud objectForKey:@"groupsui_team_sortattr"]
           owner:nil];
    sos = [[NSArray alloc] initWithObjects:&so count:1];
    [so release];
  }
  
  return sos;
}

- (NSArray *)setOfOwnerGlobalIDsFromOwnedObjectArray:(NSArray *)teams {
  NSMutableArray *ownerGIDs;
  unsigned i, count;
  
  if (![teams isNotEmpty])
    return nil;
  
  ownerGIDs = [NSMutableArray arrayWithCapacity:8];
  for (i = 0, count = [teams count]; i < count; i++) {
    EOKeyGlobalID *gid;
    NSNumber *pkey;
      
    pkey = [[teams objectAtIndex:i] valueForKey:@"ownerId"];
    if (![pkey isNotNull])
      pkey = [NSNumber numberWithInt:10000 /* root, default owner */];
    
    gid = [EOKeyGlobalID globalIDWithEntityName:@"Person"
                         keys:&pkey keyCount:1 zone:NULL];
    if ([ownerGIDs containsObject:gid])
      continue;
      
    [ownerGIDs addObject:gid];
  }
  
  return ownerGIDs;
}

- (void)_fetchMyTeams {
  LSCommandContext *cmdctx;
  NSArray *ownerGIDs;
  NSArray *gids, *teams;

  [self resetList:nil];
  
  cmdctx = [[self session] commandContext];
  
  /* fetch global ids of teams where I'm a member */
  
  // TODO: also fetch teams where the user is the 'ownerId'?!
  gids = [cmdctx runCommand:@"team::extended-search",
                 @"fetchGlobalIDs",        @"YES",
                 @"onlyTeamsWithAccount",  [[self session] activeAccount],
                 @"includeTeamsWithOwner", [[self session] activeAccount],
                 @"description",           @"%%", 
                 nil];
  if (![gids isNotNull]) {
    // TODO: localize
    [self setErrorString:@"Did not find teams for login account?!"];
    return;
  }
  
  /* fetch information about the teams */
  
  teams = [cmdctx runCommand:@"team::get-by-globalID",
                  @"gids",          gids, 
                  @"sortOrderings", [self teamSortOrderings],
                  nil];
  self->groupList = [teams retain];
  
  /* fetch members */
  
  [cmdctx runCommand:@"team::members",
	  @"teams",      teams,
	  @"returnType", intObj(LSDBReturnType_ManyObjects), 
	  nil];

  /* fetch owners */
  
  ownerGIDs = [self setOfOwnerGlobalIDsFromOwnedObjectArray:teams];
  if ([ownerGIDs isNotEmpty]) {
    self->pkeyToOwnerInfo = 
      [[cmdctx runCommand:@"person::get-by-globalID",
                     @"gids",       ownerGIDs,
                     @"groupBy",    @"companyId",
                     @"attributes", ownerFetchAttrs,
                     nil] copy];
  }
  
  /* fetch permissions */
  
  self->writeableTeamGIDs =
    [[[cmdctx accessManager] objects:gids forOperation:@"w"] copy];
}

/* notifications */

- (void)sleep {
  [self setGroup:nil];
  [self setAccount:nil];
  [super sleep];
}

- (void)resetList:(NSNotification *)_nc {
  [self->writeableTeamGIDs release]; self->writeableTeamGIDs = nil;
  [self->groupList         release]; self->groupList         = nil;
  [self->pkeyToOwnerInfo   release]; self->pkeyToOwnerInfo   = nil;
  
  [self setGroup:nil];
  [self setAccount:nil];
}

@end /* OGoGroupsPage */
