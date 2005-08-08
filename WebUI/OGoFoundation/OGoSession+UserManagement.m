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

#include "OGoSession.h"
#include "common.h"
#include <LSFoundation/OGoContextSession.h>
#include <LSFoundation/OGoContextManager.h>
#include <EOControl/EOKeyGlobalID.h>
#include <GDLAccess/EONull.h>

@interface NSObject(OGoSessionUserManagementPrivateMethodes)
- (id)initWithContext:(id)_ctx projectGlobalID:(EOGlobalID *)_gid;
@end

@interface OGoSession(UserManagementPrivateMethodes)
- (void)_buildDockInfos;
@end


@implementation OGoSession(UserManagement)

static int compareAccounts(id member1, id member2, void *context) {
  static EONull *null = nil;
  id name1 = [member1 valueForKey:@"login"];
  id name2 = [member2 valueForKey:@"login"];
  if (null == nil) null = [[EONull null] retain];
  
  if (name1 == null) name1 = @"";
  if (name2 == null) name2 = @"";
  return [(NSString *)name1 compare:name2];
}

static int compareTeams(id team1, id team2, void *context) {
  static EONull *null = nil;
  NSString *name1 = [team1 valueForKey:@"description"];
  NSString *name2 = [team2 valueForKey:@"description"];
  if (null == nil) null = [[EONull null] retain];
  
  if (name1 == (id)null) name1 = @"";
  if (name2 == (id)null) name2 = @"";
  return [(NSString *)name1 compare:name2];
}

/* notifications */

- (void)_refetchAccountInfo:(NSNotification *)_notification {
  ASSIGN(self->accounts,    (id)nil);
  ASSIGN(self->allAccounts, (id)nil);
  ASSIGN(self->teams,       (id)nil);
}

- (void)accountPWWasUpdated:(NSNotification *)_notification {
}

- (void)accountPreferenceWasUpdated:(NSNotification *)_notification {
  [self runCommand:@"account::get", @"companyId",
          [[self activeAccount] valueForKey:@"companyId"], nil];
}

/* on demand */

- (void)_fetchAccountsOnDemand {
  if ((self->accounts == nil) || (self->allAccounts == nil))
    [self fetchAccounts];
}
- (void)_fetchTeamsOnDemand {
  if (self->teams == nil)
    [self fetchTeams];
}

/* staff */

- (NSArray *)teams { // DEPRECATED
  /* 
     used in:
     - SkyParticipantsSelection.wod
     ??
  */
#if DEBUG
  [self debugWithFormat:
          @"called deprecated method [session -teams] in component '%@'!",
	  [(WOComponent *)[[self context] component] name]];
#endif
  [self _fetchTeamsOnDemand];
  return self->teams;
}

- (NSArray *)accounts { // DEPRECATED
#if DEBUG
  [self debugWithFormat:@"called deprecated method [session -accounts]!"];
#endif
  [self _fetchAccountsOnDemand];
  return self->accounts;
}
- (NSArray *)allAccounts {
#if DEBUG
  [self debugWithFormat:@"called deprecated method [session -allAccounts]!"];
#endif
  [self _fetchAccountsOnDemand];
  return self->allAccounts;
}

- (NSArray *)categories {
  return self->categories; 
}
- (NSArray *)categoryNames {
  return self->categoryNames; 
}

- (NSArray *)locationTeams {
  NSMutableArray *myTeams;
  int            i, cnt;
  
  [self _fetchTeamsOnDemand];
  
  myTeams = [NSMutableArray arrayWithCapacity:4];
  for (i = 0, cnt = [self->teams count]; i < cnt; i++) {
    id   team;
    BOOL isLocation;

    team       = [self->teams objectAtIndex:i] ;
    isLocation = [[team valueForKey:@"isLocationTeam"] boolValue];
    
    if (isLocation)
      [myTeams addObject:team];
  }
  return myTeams;
}

- (NSArray *)teamsWithNames:(NSArray *)_names {
  // TODO: who uses this??
  // Note: might have side-effects with OGoShowMemberTeamsOnly (only searches
  //       in such which may or may not be wanted)
  NSMutableArray *myTeams;
  int            i, cnt;
  
  [self _fetchTeamsOnDemand];
  
  myTeams = [NSMutableArray arrayWithCapacity:4];
  cnt     = [self->teams count];
  
  for (i = 0; i < cnt; i++) {
    id team, name;
    
    team = [self->teams objectAtIndex:i] ;
    name = [team valueForKey:@"description"];
    
    if ([_names containsObject:name])
      [myTeams addObject:team];
  }
  return myTeams;
}

- (void)fetchTeams {
  static int showMembersOnly = -1;
  NSArray *t;
  
  if (showMembersOnly == -1) {
    showMembersOnly = [[NSUserDefaults standardUserDefaults]
                        boolForKey:@"OGoShowMemberTeamsOnly"] ? 1 : 0;
    if (showMembersOnly)
      [self logWithFormat:@"Note: configured to return only member-teams!"];
  }
  
  if (showMembersOnly) {
    t = [self runCommand:@"account::teams", 
              @"account", [self activeAccount], nil];
  }
  else {
    t = [self runCommand:@"team::get",
              @"returnType", intObj(LSDBReturnType_ManyObjects), nil];
  }
  
  t = [t sortedArrayUsingFunction:compareTeams context:self];
  
  ASSIGN(self->teams, t);

#if 0 /* this fetches the members of the teams, which means: all accounts! */
  [self runCommand:@"team::members",
          @"teams",      self->teams,
          @"returnType", intObj(LSDBReturnType_ManyObjects), nil];
#endif
}

- (void)fetchAccounts {
  int            i, cnt;
  NSArray        *a   = nil;
  NSMutableArray *ac;
  NSMutableArray *aac;
  NSAutoreleasePool *pool;

  pool = [[NSAutoreleasePool alloc] init];
  
  ac  = [NSMutableArray arrayWithCapacity:128];
  aac = [NSMutableArray arrayWithCapacity:8];
  
  a = [self runCommand:@"account::get",
            @"returnType", intObj(LSDBReturnType_ManyObjects), nil];
  
  for (i = 0, cnt = [a count]; i < cnt; i++) {
    id       account;
    NSString *login;

    account = [a objectAtIndex:i] ;
    login   = [account valueForKey:@"login"];
    
    /* 10000 = root-user, 9999 = template user */
    // TODO: should we filter out template users?
    
    if (([login intValue] != 10000) && ([login intValue] != 9999))
      [ac addObject:account];
    
    if (![login intValue] == 10000)
      [aac addObject:account];
  }

  [ac  sortUsingFunction:compareAccounts context:self];
  [aac sortUsingFunction:compareAccounts context:self];
  
  ASSIGNCOPY(self->accounts,    ac);
  ASSIGNCOPY(self->allAccounts, aac);
  
  [pool release];
}

- (void)fetchCategories {
  NSMutableArray *c = nil;
  NSArray        *t = nil;
  int i, cnt;

  t = [self runCommand:@"companycategory::get",
              @"returnType", intObj(LSDBReturnType_ManyObjects),
              nil];
  ASSIGN(self->categories, t);
  
  c = [NSMutableArray arrayWithCapacity:10];
  for (i = 0, cnt = [t count]; i < cnt; i++)
    [c addObject:[[t objectAtIndex:i] valueForKey:@"category"]];
  
  [self->categoryNames release]; self->categoryNames = nil;
  self->categoryNames = 
    [[c sortedArrayUsingSelector:@selector(compare:)] copy];
}

/*
  hasIconData -> YES | NO
  iconData    -> content of "project.gif"
  title       -> project.name
  projectId   -> project.projectId
  globalId    -> globalId
*/
 
- (NSArray *)dockedProjectInfos {
  if (self->dockedProjectInfos == nil)
    [self _buildDockInfos];

  return self->dockedProjectInfos;
}

- (void)fetchDockedProjectInfos {
  [self->dockedProjectInfos release]; self->dockedProjectInfos = nil;
  // [self _buildDockInfos]; is done by dockedProjectInfos
}

@end /* OGoSession(UserManagement) */


@implementation OGoSession(UserManagementPrivateMethodes)

- (void)_validateDockedProjectIDs {
  // hh: I do not understand how this method works ...
  NSArray  *validIds, *projectIds;
  unsigned cnt;
  
  projectIds = [[self userDefaults] arrayForKey:@"docked_projects"];
  cnt       = [projectIds count];
  
  validIds = [self->dockedProjectInfos valueForKey:@"projectId"];
  if ([validIds count] >= cnt)
    return;
  
  /* some projects seem to have been deleted */
  [[self userDefaults] setObject:validIds forKey:@"docked_projects"];
}

- (void)_buildDockInfos {
  static Class ProjectFileManagerClass = Nil;
  NSArray *projectIds;
  NSMutableArray *dockInfos;    
  unsigned i, cnt;

  if (ProjectFileManagerClass == Nil)
    ProjectFileManagerClass = NSClassFromString(@"SkyProjectFileManager");
  
  projectIds = [[self userDefaults] arrayForKey:@"docked_projects"];
  
  cnt       = [projectIds count];
  dockInfos = [[NSMutableArray alloc] initWithCapacity:cnt+1];
    
  for (i = 0; i < cnt; i++) {
    NSMutableDictionary   *info;
    NSString              *projectId;
    NSData                *iconData = nil;
    id                    project;
    EOKeyGlobalID         *gid;
      
    projectId = [projectIds objectAtIndex:i];
    gid       = [EOKeyGlobalID globalIDWithEntityName:@"Project"
                               keys: &projectId keyCount:1 zone:NULL];

    project = [[self runCommand:@"project::get-by-globalid",
                     @"gid", gid, nil] lastObject];
      
    if (![project isNotNull])
      continue;
      
    {
      id pfm;
      pfm = [(id)[ProjectFileManagerClass alloc]
                 initWithContext:[self commandContext]
                 projectGlobalID:gid];
      iconData = [pfm contentsAtPath:@"project.gif"];
      [pfm release]; pfm = nil;
    }
      
    info = [[NSMutableDictionary alloc] initWithCapacity:8];
    [info setObject:projectId forKey:@"projectId"];
    [info setObject:gid       forKey:@"globalId"];
    [info takeValue:[project valueForKey:@"name"]  forKey:@"title"];
      
    if (iconData) {
      [info setObject:@"YES"    forKey:@"hasIconData"];
      [info setObject:iconData  forKey:@"iconData"];
    }
    [dockInfos addObject:info];
      
    [info release];
  }
  ASSIGN(self->dockedProjectInfos, dockInfos);
  [dockInfos release];
  
  /* validate doc ids */
  [self _validateDockedProjectIDs];
}

@end /* OGoSession(UserManagementPrivateMethodes) */
