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

#include "SkyContactAction+QueryMethods.h"
#include "common.h"
#include "SkyContactAction+PrivateMethods.h"
#include "SkyContactAction+Conversion.h"
#include "SkyContactAction+Caching.h"

@interface NSObject(SearchDict)
- (id)searchDict;
@end /* NSObject(SearchDict) */

@interface NSObject(TakeSafeValue)
- (void)takeSafeValue:(id)_value forKey:(NSString *)_key;
@end /* NSObject(TakeSafeValue) */

@implementation NSObject(TakeSafeValue)
- (void)takeSafeValue:(id)_value forKey:(NSString *)_key
{
  if (_value != nil && ![_value isEqualToString:@""]) {
    NSString *value;

    value = [NSString stringWithFormat:@"%@*",[_value stringValue]];
    [self takeValue:value forKey:_key];
  }
}
@end /* NSObject(TakeSafeValue) */

@implementation SkyContactAction(QueryMethods)

int personSort(id person1, id person2, void *context)
{
  NSString* v1 = [person1 valueForKey:@"name"];
  NSString* v2 = [person2 valueForKey:@"name"];

  return [v1 caseInsensitiveCompare:v2];
}

- (id)_newRecordForEntity:(NSString *)_entity {
  LSCommandContext *ctx;

  if ((ctx = [self commandContext]) != nil) {
    id record;
    
    NSLog(@"-- executing command search::newrecord");    
    record = [ctx runCommand:@"search::newrecord",
                  @"entity", _entity,
                  nil];

    [self _ensureCurrentTransactionIsCommitted]; 

    [record setComparator:@"LIKE"];
    return record;
  }
  [self logWithFormat:@"invalid command context"];
  return nil;
}

- (NSArray *)_getPersonIDsFromTeams:(id)_teams {
  NSMutableArray *result;
  NSEnumerator *teamEnum;
  id team;

  result = [NSMutableArray arrayWithCapacity:[_teams count]];

  if ([_teams isKindOfClass:[NSArray class]]) {
    return _teams;
  }
  teamEnum = [_teams keyEnumerator];
  while ((team = [teamEnum nextObject])) {
    [result addObjectsFromArray:[_teams valueForKey:team]];
  }
  return result;
}

- (NSDictionary *)_resolveMembersForTeamsWithGIDs:(NSArray *)_teamGIDs {
  LSCommandContext *ctx;

  if ((ctx = [self commandContext]) != nil) {
    NSArray *teams;
    NSDictionary *members;

    teams = [ctx runCommand:@"team::get-by-globalid",
                 @"gids", _teamGIDs,
                 nil];
    
    members = [ctx runCommand:@"team::members",
                   @"teams", teams,
                   @"suppressAdditionalInfos",
                   [NSNumber numberWithBool:YES],
                   @"fetchGlobalIDs",
                   [NSNumber numberWithBool:YES],
                   nil];

    return members;
  }
  [self logWithFormat:@"missing command context."];
  return nil;
}

- (NSArray *)_arrayForPersons:(NSArray *)_persons
  sortedByTeams:(id)_teams
  withGlobalIDs:(NSArray *)_gids
{
  NSMutableArray      *result;
  NSMutableDictionary *lookupCache;
  NSEnumerator        *gidEnum;
  id                  gid;

  lookupCache = [NSMutableDictionary dictionaryWithCapacity:[_persons count]];
  result = [NSMutableArray arrayWithCapacity:[_persons count]];
  
  // set up person lookup cache
  {
    NSArray *urls;
    NSArray *gids;
    int     i, j;

    // collect URLs
    urls = [_persons valueForKey:@"id"];
    gids = [self _globalIDsForURLs:urls];

    if ([urls count] != [gids count]) {
      [self logWithFormat:@"size mismatch while getting GIDs for URLs"];
    }

    for (i = 0, j = [_persons count]; i < j; i++) {
      [lookupCache setObject:[_persons objectAtIndex:i]
                   forKey:[gids objectAtIndex:i]];
    }
  }
  
  // get the persons who are not assigned to a team
  // by finding all globalIDs who are Person entities
  gidEnum = [_gids objectEnumerator];
  while ((gid = [gidEnum nextObject])) {
    if ([[gid entityName] isEqualToString:@"Person"]) {
      [result addObject:[lookupCache valueForKey:gid]];
    }
  }

  // sort the array
  [result sortUsingFunction:personSort context:nil];
  
  // now iterate over the teams and get the corresponding team members
  {
    // just one team
    if ([_teams isKindOfClass:[NSArray class]]) {
      NSEnumerator *gidEnum;
      id gid;

      gidEnum = [_gids objectEnumerator];
      while ((gid = [gidEnum nextObject])) {
        if ([[gid entityName] isEqualToString:@"Team"])
          break;
      }
      
      [result addObject:[self teamDictionaryForTeam:gid
                              withMembers:_teams
                              fromLookupCache:lookupCache]];
    }
    // dictionary of teams
    else {
      NSEnumerator *teamEnum;
      NSArray *members;
      id team;

      teamEnum = [_teams keyEnumerator];
      while ((team = [teamEnum nextObject])) {
        members = [_teams valueForKey:team];

        [result addObject:[self teamDictionaryForTeam:team
                                withMembers:members
                                fromLookupCache:lookupCache]];
      }
    }
  }
  return result;
}

- (NSArray *)getObjectsForURLs:(NSArray *)_urls
  entity:(NSString *)_entity
{
  NSArray *gids;

  NSLog(@"--- trying to get objects for %d urls", [_urls count]);
  
  if ((gids = [self _globalIDsForURLs:_urls]) != nil) {
    NSArray *fetchAttributes;
    NSDictionary *arguments;
    NSMutableArray *personGIDs;
    NSMutableArray *teamGIDs;
    NSEnumerator *gidEnum;
    NSDictionary *teamsAndMembers;
    EOGlobalID *gid;
    NSArray *persons;

    personGIDs = [NSMutableArray arrayWithCapacity:[gids count]];
    teamGIDs = [NSMutableArray arrayWithCapacity:[gids count]];

    gidEnum = [gids objectEnumerator];
    while ((gid = [gidEnum nextObject])) {

      if ([[gid entityName] isEqualToString:@"Team"])
        [teamGIDs addObject:gid];
      else
        [personGIDs addObject:gid];
    }

    teamsAndMembers = [self _resolveMembersForTeamsWithGIDs:teamGIDs];
    [personGIDs addObjectsFromArray:[self _getPersonIDsFromTeams:
                                          teamsAndMembers]];

    fetchAttributes = [NSArray arrayWithObjects:
                               @"objectVersion",
                               @"globalID",
                               nil];
    
    arguments = [NSDictionary dictionaryWithObjectsAndKeys:
                              personGIDs, @"gids",
                              fetchAttributes, @"attributes",
                              nil];

    if ([_entity isEqualToString:@"Enterprise"]) {
      persons = [self enterprisesForSearchCommand:
                      @"enterprise::get-by-globalid"
                      arguments:arguments];
    }
    else if ([_entity isEqualToString:@"Person"]) {
      persons = [self personsForSearchCommand:
                      @"person::get-by-globalid"
                      arguments:arguments
                      withEnterprises:YES];
    }
    else {
      [self logWithFormat:@"unknown entity '%@'", _entity];
      return nil;
    }

    if ([teamGIDs count] > 0)
      return [self _arrayForPersons:persons
                   sortedByTeams:teamsAndMembers
                   withGlobalIDs:gids];

    return [persons sortedArrayUsingFunction:personSort context:nil];
  }
  return nil;
}

- (NSDictionary *)argumentsForAdvancedSearch:(NSDictionary *)_attrs
  extendedAttributes:(NSDictionary *)_extAttrs
  maxSearchCount:(NSNumber *)_maxSearchCount
  entity:(NSString *)_entity
{
  NSMutableDictionary *args;
  id company, address, info, pValue, email, phone;
  NSMutableArray *searchRecords;
  BOOL isContactEntity = NO;
  
  if ([_entity isEqualToString:@"Person"]) {
    isContactEntity = YES;
    company = [self _newRecordForEntity:@"Person"];
  }
  else {
    company = [self _newRecordForEntity:@"Enterprise"];
  }

  address = [self _newRecordForEntity:@"Address"];
  pValue  = [self _newRecordForEntity:@"CompanyValue"];
  info    = [self _newRecordForEntity:@"CompanyInfo"];
  phone   = [self _newRecordForEntity:@"Telephone"];

  if (isContactEntity) {
    NSString *mailString;

    /* contact specific attributes */
    
    email   = [self _newRecordForEntity:@"CompanyValue"];

    [company takeSafeValue:[_attrs valueForKey:@"lastname"]
             forKey:@"name"];
    [company takeSafeValue:[_attrs valueForKey:@"firstname"]
             forKey:@"firstname"];

    [phone takeSafeValue:[_attrs valueForKey:@"phoneType"]
             forKey:@"type"];

    if ((mailString = [_attrs valueForKey:@"email"]) != nil) {
      [email takeValue:@"email1" forKey:@"attribute"];
      [email takeSafeValue:mailString forKey:@"value"];
    }
  }
  else {
    /* enterprise specific attributes */
    
    [company takeSafeValue:[_attrs valueForKey:@"description"]
             forKey:@"description"];
    [company takeSafeValue:[_attrs valueForKey:@"number"]
             forKey:@"number"];

    [address takeSafeValue:[_attrs valueForKey:@"country"]
             forKey:@"country"];
  }
    
  [company takeSafeValue:[_attrs valueForKey:@"category"]
           forKey:@"keywords"];
  [company takeSafeValue:[_attrs valueForKey:@"url"]
           forKey:@"url"];

  [address takeSafeValue:[_attrs valueForKey:@"zip"]
           forKey:@"zip"];
  [address takeSafeValue:[_attrs valueForKey:@"city"]
           forKey:@"city"];
  [address takeSafeValue:[_attrs valueForKey:@"street"]
           forKey:@"street"];

  [phone takeSafeValue:[_attrs valueForKey:@"phoneNumber"]
         forKey:@"number"];

  [info takeSafeValue:[_attrs valueForKey:@"comment"]
        forKey:@"comment"];

  if (_extAttrs != nil) {
    [pValue takeSafeValue:[_extAttrs valueForKey:@"extAttrName"]
            forKey:@"attribute"];
    [pValue takeSafeValue:[_extAttrs valueForKey:@"extAttrValue"]
            forKey:@"value"];
  }

  searchRecords = [NSMutableArray arrayWithCapacity:6];
  [searchRecords addObject:company];
  if ([[[info searchDict] allKeys] count] > 0)
    [searchRecords addObject:info];
  if ([[[address searchDict] allKeys] count] > 0)
    [searchRecords addObject:address];
  if ([[[pValue searchDict] allKeys] count] > 0)
    [searchRecords addObject:pValue];
  if (isContactEntity) {
    if ([[[email searchDict] allKeys] count] > 0)
      [searchRecords addObject:email];
  }
  if ([[[phone searchDict] allKeys] count] > 0)
    [searchRecords addObject:phone];    
  
  args = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                              @"AND",         @"operator",
                              searchRecords,  @"searchRecords",
                              [NSNumber numberWithBool:YES],
                              @"fetchGlobalIDsAndVersions",
                              nil];
  
  if (_maxSearchCount != nil)
    [args setObject:_maxSearchCount forKey:@"maxSearchCount"];

  return args;
}

- (NSString *)teamNameForTeamWithGID:(EOGlobalID *)_teamGID {
  LSCommandContext *ctx;

  if (_teamGID == nil)
    return nil;
  
  if ((ctx = [self commandContext]) != nil) {
    id result;

    result = [ctx runCommand:@"team::get-by-globalid",
                  @"gid", _teamGID,
                  @"attributes", [NSArray arrayWithObject:@"description"],
                  nil];

    [self _ensureCurrentTransactionIsCommitted];

    if (result != nil)
      return [[result valueForKey:@"description"] lastObject];
    else {
      [self logWithFormat:@"no team name for team with GID %@ found",
            _teamGID];
      return nil;
    }
  }
  [self logWithFormat:@"no valid command context found"];
  return nil;
}

- (NSArray *)_gidsAndVersionsForURLs:(NSArray *)_urls
  entity:(NSString *)_entity
{
  NSArray *gids;

  NSLog(@"--- trying to get GIDs and versions for %d urls", [_urls count]);
 
  if ((gids = [self _globalIDsForURLs:_urls]) != nil) {
    NSArray *fetchAttributes;
    NSDictionary *arguments;
    
    fetchAttributes = [NSArray arrayWithObjects:
                               @"objectVersion",
                               @"globalID",
                               nil];
    
    arguments = [NSDictionary dictionaryWithObjectsAndKeys:
                              gids, @"gids",
                              fetchAttributes, @"attributes",
                              nil];

    if ([_entity isEqualToString:@"Enterprise"]) {
      return [[self commandContext] runCommand:@"enterprise::get-by-globalid"
                   arguments:arguments];
    }
    else if ([_entity isEqualToString:@"Person"]) {
      return [[self commandContext] runCommand:@"person::get-by-globalid"
                   arguments:arguments];
    }
    else {
      [self logWithFormat:@"unknown entity '%@'", _entity];
      return nil;
    }
  }
  [self logWithFormat:@"Invalid URL"];
  return nil;
}

- (NSArray *)_gidsAndVersionsForEnterpriseURLs:(NSArray *)_urls {
  return [self _gidsAndVersionsForURLs:_urls entity:@"Enterprise"];
}

@end /* SkyContactAction(QueryMethods) */
