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
#include <OGoAccounts/SkyTeamDocument.h>

@interface DirectAction(Account)
- (id)_checkEmail:(NSString *)_email context:(NSMutableDictionary *)_dict;
@end /* DirectAction(Account) */

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
  id result;

  if ((ctx = [self commandContext]) == nil)
    return [NSNumber numberWithBool:NO];

  if ((result = [ctx runCommand:@"team::get", @"number",_number, nil]) == nil){
    [self logWithFormat:@"no team for number '%@' found", _number];
    return [NSNumber numberWithBool:NO];
  }
  
  //return [self _dictionaryForTeamEOGenericRecord:[result objectAtIndex:0]];
  return [result objectAtIndex:0];
}

- (id)team_getMembersForTeamAction:(NSString *)_number {
  LSCommandContext *ctx;
  id team;

  if ((ctx = [self commandContext]) == nil) 
    return [NSNumber numberWithBool:NO];
  
  if ((team = [self team_getByNumberAction:_number]) == nil) {
    [self logWithFormat:@"no team for number '%@' found", _number];
    return [NSNumber numberWithBool:NO];
  }
  
  return [ctx runCommand:@"team::members", @"team",team, nil];
}


- (NSDictionary *)_MTATeamInfo:(id)_team ctx:(NSMutableDictionary *)ctx {
  NSMutableDictionary *dict;
  NSMutableArray      *array;
  id                  tmp, documentManager, ud;
  NSEnumerator        *enumerator;


  documentManager = [[self commandContext] documentManager];
  dict            = [[NSMutableDictionary alloc] initWithCapacity:8];
  array           = [[NSMutableArray alloc] initWithCapacity:8];
  tmp             = [[documentManager urlForGlobalID:[_team globalID]]
                                      absoluteString];

  [dict setObject:tmp                   forKey:@"globalId"];
  [dict setObject:[_team number]        forKey:@"login"];
  [dict setObject:[_team objectVersion] forKey:@"version"];
  
  ud              = [[self commandContext]
                           runCommand:@"userdefaults::get", @"user",
                           _team, nil];

  enumerator = [[[[ud objectForKey:@"admin_vaddresses"]
                      componentsSeparatedByString:@"\n"]
                      map:@selector(stringByTrimmingSpaces)] objectEnumerator];
  while ((tmp = [enumerator nextObject])) {
    if ((tmp = [self _checkEmail:tmp context:ctx]) == nil)
      continue;
    
    [array addObject:tmp];
  }
  if ((tmp = [self _checkEmail:[_team email] context:ctx]))
    [array addObject:tmp];

  [dict setObject:array forKey:@"emails"];

  [array release]; array = nil;
  return dict;
}

- (id)team_fetchAllMTAInfoAction {
  NSArray              *teams;
  EOFetchSpecification *fspec;
  EODataSource         *teamDS;
  NSEnumerator         *enumerator;
  id                   a;
  NSMutableArray       *result;
  NSMutableDictionary  *ctx;
  
  teamDS = [self teamDataSource];
  fspec    = [[[EOFetchSpecification alloc]
                                     initWithBaseValue:@"login like '*'"]
                                     autorelease];
  ctx      = [NSMutableDictionary dictionaryWithCapacity:16];
  
  [fspec setEntityName:@"Team"];
  [teamDS setFetchSpecification:fspec];

  teams           = [teamDS fetchObjects];
  enumerator      = [teams objectEnumerator];
  result          = [NSMutableArray arrayWithCapacity:[teams count]];
  
  while ((a = [enumerator nextObject])) {
    id tmp;
    
    if ((tmp = [self _MTATeamInfo:a ctx:ctx]))
      [result addObject:tmp];
  }
  return result;
}


@end /* DirectAction(Team) */
