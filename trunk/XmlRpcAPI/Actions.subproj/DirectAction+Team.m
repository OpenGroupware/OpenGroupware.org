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

#include "DirectAction.h"
#include <EOControl/EOControl.h>
#include "EOControl+XmlRpcDirectAction.h"
#include "NSObject+EKVC.h"
#include "Session.h"
#include "common.h"

@implementation DirectAction(Team)

- (NSDictionary *)_dictionaryForTeamEOGenericRecord:(id)_record {
  static NSArray *teamKeys = nil;
  id result;

  if (teamKeys == nil)
    teamKeys = [[NSArray alloc] initWithObjects:
                               @"description", @"email", @"isLocationTeam",
                               @"ownerId", @"number", nil];

  result = [self _dictionaryForEOGenericRecord:_record withKeys:teamKeys];

  [self substituteIdsWithURLsInDictionary:result
        forKeys:[NSArray arrayWithObjects:@"ownerId",nil]];

  return result;
}

- (NSArray *)_dictionariesForTeamEOGenericRecords:(NSArray *)_records {
  NSMutableArray *result;
  NSEnumerator *recEnum;
  id record;

  result = [NSMutableArray arrayWithCapacity:[_records count]];
  recEnum = [_records objectEnumerator];
  while ((record = [recEnum nextObject]))
    [result addObject:[self _dictionaryForTeamEOGenericRecord:record]];
  return result;
}

- (id)team_insertAction:(id)_account {
  LSCommandContext *ctx;

  if ((ctx = [self commandContext]) != nil) {
    id result;
    result = [ctx runCommand:@"team::new" arguments:_account];
    if ([result isKindOfClass:[EOGenericRecord class]]) {
      return [self _dictionaryForTeamEOGenericRecord:result];
    }
    return [NSNumber numberWithBool:NO];
  }

  [self logWithFormat:@"Invalid command context"];
  return [NSNumber numberWithBool:NO];
}

- (id)team_setMembersAction:(id)_teamId:(NSArray *)_logins {
  LSCommandContext *ctx;

  if ((ctx = [self commandContext]) != nil) {
    id result;
    id team, dm;
    EOGlobalID *gid;
    
    dm = [ctx documentManager];
    gid = [dm globalIDForURL:_teamId];

    team = [[ctx runCommand:@"team::get-by-globalid",
                @"gid", gid,
                nil] lastObject];

    if (team != nil) {
      NSArray *gids;
      NSArray *accounts;

      gids = [dm globalIDsForURLs:_logins];
      accounts = [ctx runCommand:@"object::get-by-globalid",
                      @"gids", gids,
                      nil];

      result = [ctx runCommand:@"team::setmembers",
                    @"group", team,
                    @"members", accounts,
                    nil];

      if ([result isKindOfClass:[EOGenericRecord class]])
        return [NSNumber numberWithBool:YES];
      return [NSNumber numberWithBool:NO];
    }
  }
  [self logWithFormat:@"Invalid command context"];
  return [NSNumber numberWithBool:NO];
}

- (id)team_getTeamsAction {
  LSCommandContext *ctx;

  if ((ctx = [self commandContext]) != nil) {
    id teams;
    
    teams = [ctx runCommand:@"team::get-all",nil];

    if ([teams isKindOfClass:[NSArray class]])
      return [self _dictionariesForTeamEOGenericRecords:teams];
    return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_RESULT
                 reason:@"Invalid result type (no array) for command"];
  }
  return [self invalidCommandContextFault];
}

- (id)team_getByLoginAction:(NSString *)_login {
  LSCommandContext *ctx;

  if ((ctx = [self commandContext]) != nil) {
    id result;

    result = [ctx runCommand:@"team::get-by-login",
                  @"login",_login,
                  nil];

    if (result != nil)
      return [self _dictionaryForTeamEOGenericRecord:result];
    else {
      [self logWithFormat:@"no team for login found"];
      return [NSNumber numberWithBool:NO];
    }
  }
  [self logWithFormat:@"no command context found"];
  return [NSNumber numberWithBool:NO];
}

- (id)team_getByNumberAction:(NSString *)_number {
  LSCommandContext *ctx;

  if ((ctx = [self commandContext]) != nil) {
    id result;

    result = [ctx runCommand:@"team::get",
                  @"number",_number,
                  nil];

    if (result != nil)
      //return [self _dictionaryForTeamEOGenericRecord:[result objectAtIndex:0]];
      return [result objectAtIndex:0];
    else 
      [self logWithFormat:@"no team for number '%@' found", _number];
  }
  return [NSNumber numberWithBool:NO];
}

- (id)team_getMembersForTeamAction:(NSString *)_number {
  LSCommandContext *ctx;

  if ((ctx = [self commandContext]) != nil) {
    id result;
    id team;
    
    team = [self team_getByNumberAction:_number];
    
    if (team != nil) {
      result = [ctx runCommand:@"team::members",
                    @"team",team,
                  nil];
      return result;
    }
    else {
      [self logWithFormat:@"no team for number '%@' found", _number];
    }
  }
  return [NSNumber numberWithBool:NO];
}

@end /* DirectAction(Team) */
