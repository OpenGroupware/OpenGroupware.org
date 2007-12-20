/*
  Copyright (C) 2006-2007 Whitemice Consulting

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
#include "zOGIAction.h"
#include "zOGIAction+Contact.h"
#include "zOGIAction+Defaults.h"
#include "zOGIAction+Object.h"
#include "zOGIAction+Team.h"

@implementation zOGIAction(Team)

-(NSArray *)_renderTeams:(NSArray *)_teams withDetail:(NSNumber *)_detail {
  NSMutableArray *result;
  NSDictionary   *eoTeam;
  int             count;

  result = [NSMutableArray arrayWithCapacity:[_teams count]];
  for (count = 0; count < [_teams count]; count++) {
    eoTeam = [_teams objectAtIndex:count];
    [result addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys: 
       [eoTeam valueForKey:@"companyId"], @"objectId",
       [eoTeam valueForKey:@"objectVersion"], @"objectVersion",
       @"Team", @"entityName",
       [self NIL:[eoTeam valueForKey:@"ownerId"]], @"ownerObjectId",
       [self NIL:[eoTeam valueForKey:@"description"]], @"name",
       nil]];
     if([_detail intValue] > 0) {
       [[result objectAtIndex:count] setObject:eoTeam forKey:@"*eoObject"];
       if (([[eoTeam objectForKey:@"companyId"] intValue] != 10003) ||
           ([[self _getDefaults] boolForKey:@"zOGIExpandAllIntranet"])) {
         if([_detail intValue] & zOGI_INCLUDE_CONTACTS)
           [self _addContactsToTeam:[result objectAtIndex:count]];
         if([_detail intValue] & zOGI_INCLUDE_MEMBERSHIP)
           [[result objectAtIndex:count]
                        setObject:[self _getTeamMembers:eoTeam]
                           forKey:@"memberObjectIds"];
       }
       [self _addObjectDetails:[result objectAtIndex:count] 
                    withDetail:_detail];
     }
   }
  return result;
} /* end _renderTeams */

-(id)_getUnrenderedTeamsForKeys:(id)_arg {
  NSArray       *teams;

  teams = [[[self getCTX] runCommand:@"team::get-by-globalid",
                                     @"gids", [self _getEOsForPKeys:_arg],
                                     nil] retain];
  return teams;
} /* end _getUnrenderedTeamsForKeys */

-(id)_getTeamsForKeys:(id)_arg withDetail:(NSNumber *)_detail {
  return [self _renderTeams:[self _getUnrenderedTeamsForKeys:_arg] 
                 withDetail:_detail];
} /* end _getTeamsForKeys */

-(id)_getTeamForKey:(id)_arg withDetail:(NSNumber *)_detail {
  return [[self _renderTeams:[self _getUnrenderedTeamsForKeys:[NSArray arrayWithObject:_arg]] 
                  withDetail:_detail] lastObject];
} /* _getTeamForKey */

-(void)_addContactsToTeam:(NSMutableDictionary *)_team {
  NSArray     *memberList;
  NSArray            *members;

  members = [[self getCTX] runCommand:@"team::members",
                                      @"team",[_team objectForKey:@"*eoObject"],
                                      nil];
  if (members != nil) {
    memberList = [self _renderContacts:members withDetail:0];
   } else { memberList = [NSArray arrayWithObjects:nil]; }
  [_team setObject:memberList forKey:@"_CONTACTS"];
} /* end _addContactsToTeam */

/* Get list of team member as an array of objectIds */
-(NSArray *)_getTeamMembers:(id)_team {
  NSArray            *members;
  NSMutableArray     *memberList;
  int                 count;

  members = [[self getCTX] runCommand:@"team::members",
                                      @"team", _team,
                                      nil];
  memberList = [NSMutableArray arrayWithCapacity:[members count]];
  for (count = 0; count < [members count]; count++) {
    [memberList 
       addObject:[[members objectAtIndex:count] valueForKey:@"companyId"]];
  }
  return memberList;
} /* end _getTeamMembers */

/* Search for teams
   Supported qualifiers are "all" and "mine" */
-(NSArray *)_searchForTeams:(id)_arg 
                 withDetail:(NSNumber *)_detail
                  withFlags:(NSDictionary *)_flags; {
  NSArray   *teams;

  teams = nil;
  if ([self isDebug])
    [self logWithFormat:@"searchForTeams criteria is a %@", [_arg class]];
  if ([_arg isKindOfClass:[NSString class]]) {
    if ([_arg isEqualToString:@"all"]) {
      if ([self isDebug])
        [self logWithFormat:@"Retrieving all teams"];
      teams = [[self getCTX] runCommand:@"team::get-all", nil];
    } else if ([_arg isEqualToString:@"mine"]) {
        if ([self isDebug])
          [self logWithFormat:@"Retrieving teams for account %d",
                  [self _getCompanyId]];
        teams = [[self getCTX] runCommand:@"account::teams", 
                                 @"account", [[self getCTX] valueForKey:LSAccountKey],
                                 @"returnType", intObj(LSDBReturnType_ManyObjects),
                                 nil];
      }
  } /* end if-arg-is-a-string */
  if (teams == nil) {
    [self warnWithFormat:@"result of team search is nil, returning no teams"];
    return [NSArray arrayWithObjects:nil];
  }
  if ([self isDebug])
     [self logWithFormat:@"Logic found %d teams matching criteria",
        [teams count]];
  return [self _renderTeams:teams withDetail:_detail];
} /* end _searchForTeams */

-(id)_updateTeam:_dictionary
        objectId:_objectId
       withFlags:_flags {
  id team;

  /* get team */
  team = [[[self getCTX] runCommand:@"team::get-by-globalid",
                           @"gid", [self _getEOForPKey:_objectId],
                           nil] lastObject];
  /* if i got the team */
  if ([team isNotNull]) {
	  /* if members are specified in the update*/
    if ([[_dictionary objectForKey:@"memberObjectIds"] isNotNull]) {
      NSArray *accounts, *gids;
      /* turn members into gids */
      gids = [self _getEOsForPKeys:[_dictionary objectForKey:@"memberObjectIds"]];
      /* get the account objects for the gids */
      accounts = [[self getCTX] runCommand:@"object::get-by-globalid",
                                   @"gids", gids,
                                   nil];
      /* set the membership of the team to the prescribed accounts */
      [[self getCTX] runCommand:@"team::setmembers",
                       @"group", team,
                       @"members", accounts,
                       nil];
    }
  }
  /* commit changes */
  [[self getCTX] commit];
  /* get potentially modified team and return to client */
  return [self _getObjectByObjectId:_objectId withDetail:intObj(65535)];
} /* end _updateTeam */

@end /* End zOGIAction(Team) */
