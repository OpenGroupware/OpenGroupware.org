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

#include "SkyContactAction+Conversion.h"
#include "common.h"
#include "SkyContactAction+PrivateMethods.h"
#include "SkyContactAction+QueryMethods.h"

@interface NSMutableDictionary(SetSafeObject)
- (void)setSafeObject:(id)_object forKey:(NSString *)_key;
@end /* NSMutableDictionary(SetSafeObject) */

@implementation NSMutableDictionary(SetSafeObject)
- (void)setSafeObject:(id)_object forKey:(NSString *)_key {
  if (_object == nil)
    _object = @"";
  [self setObject:_object forKey:_key];
}
@end /* NSMutableDictionary(SetSafeObject) */

@interface EOGenericRecord(GlobalID)
- (EOGlobalID *)globalID;
@end /* EOGenericRecord(GlobalID) */

@implementation SkyContactAction(Conversion)

- (NSArray *)_dictionariesForObjectRecords:(NSArray *)_records
  ofEntity:(NSString *)_entity
  withEnterprises:(BOOL)_withEnterprises
{
  NSMutableArray  *result;
  NSEnumerator    *recordEnum;
  EOGenericRecord *record;
  BOOL isContactEntity = NO;

  NSLog(@"--- getting dicts for %d object records", [_records count]);
  
  if ([_entity isEqualToString:@"Person"])
    isContactEntity = YES;

  if (_withEnterprises) {
    NSLog(@"-- executing command person::enterprises");
    [[self commandContext] runCommand:@"person::enterprises",
            @"persons",     _records,
            @"relationKey", @"enterprises",
            nil];

    [self _ensureCurrentTransactionIsCommitted];
  }

  result = [NSMutableArray arrayWithCapacity:[_records count]];

  recordEnum = [_records objectEnumerator];
  while ((record = [recordEnum nextObject])) {
    NSMutableDictionary *dict;

    dict = [NSMutableDictionary dictionaryWithCapacity:9];
    [dict setObject:[record globalID] forKey:@"globalID"];
    [dict setSafeObject:[self _urlStringForGlobalId:[record globalID]]
          forKey:@"id"];
    [dict setSafeObject:[record valueForKey:@"objectVersion"]
          forKey:@"objectVersion"];
    [dict setSafeObject:[record valueForKey:@"companyId"]
          forKey:@"companyId"];
    
    if (isContactEntity) {
      NSArray *enterprises;

      [dict setSafeObject:[record valueForKey:@"name"]
            forKey:@"name"];
      [dict setSafeObject:[record valueForKey:@"description"]
          forKey:@"nickname"];
      [dict setSafeObject:[record valueForKey:@"firstname"]
            forKey:@"firstname"];
      [dict setSafeObject:[record valueForKey:@"degree"]
            forKey:@"degree"];
      [dict setObject:@"Person" forKey:@"entity"];

      if (_withEnterprises) {
        enterprises = [record valueForKey:@"enterprises"];
        if ([enterprises count] > 0) {
          NSMutableArray *containedOIDs;
          NSMutableArray *entDicts;
          NSEnumerator *enterpriseEnum;
          id enterprise;

          entDicts = [NSMutableArray arrayWithCapacity:
                                     [enterprises count]];
          containedOIDs = [NSMutableArray arrayWithCapacity:
                                          [enterprises count]];
      
          enterpriseEnum = [enterprises objectEnumerator];
          while ((enterprise = [enterpriseEnum nextObject])) {
            NSDictionary *dict;
            NSDictionary *versionAndId;
            NSString *url;

            url = [self _urlStringForGlobalId:[enterprise globalID]];

            versionAndId = [NSDictionary dictionaryWithObjectsAndKeys:
                                         url, @"id",
                                         [enterprise valueForKey:
                                                     @"objectVersion"],
                                         @"version",
                                         nil];

            [containedOIDs addObject:versionAndId];
            
            dict = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [enterprise valueForKey:@"description"],
                                 @"description",
                                 [enterprise valueForKey:@"companyId"],
                                 @"companyId",
                                 url,
                                 @"id",
                                 nil];
            [entDicts addObject:dict];
          }

          [dict setObject:containedOIDs forKey:@"containedOIDs"];
          [dict setSafeObject:entDicts forKey:@"enterprises"];
        }
      }
    }
    else {
      [dict setSafeObject:[record valueForKey:@"description"] forKey:@"name"];
      [dict setSafeObject:[record valueForKey:@"number"] forKey:@"number"];
      [dict setSafeObject:[record valueForKey:@"url"] forKey:@"url"];
      [dict setSafeObject:[record valueForKey:@"keywords"] forKey:@"keywords"];
      [dict setObject:@"Enterprise" forKey:@"entity"];
    }

    {
      NSEnumerator *telEnum;
      EOGenericRecord *tel;

      telEnum = [[record valueForKey:@"telephones"] objectEnumerator];
      while ((tel = [telEnum nextObject])) {
        if ([[tel valueForKey:@"type"] isEqualToString:@"01_tel"]) {
          [dict setSafeObject:[tel valueForKey:@"number"] forKey:@"01_tel"];
          break;
        }
      }
    }
    
    {
      NSEnumerator *cvEnum;
      EOGenericRecord *cv;

      cvEnum = [[record valueForKey:@"companyValue"] objectEnumerator];
      while ((cv = [cvEnum nextObject])) {
        if ([[cv valueForKey:@"attribute"] isEqualToString:@"email1"]) {
          [dict setSafeObject:[cv valueForKey:@"value"] forKey:@"email1"];
        }
        if (isContactEntity)
          if ([[cv valueForKey:@"attribute"] isEqualToString:@"job_title"]) {
            [dict setSafeObject:[cv valueForKey:@"value"] forKey:@"job_title"];
          }
      }
    }
    [result addObject:dict];
  }
  return result;
}

- (NSArray *)dictionariesForEnterpriseRecords:(NSArray *)_records {
  return [self _dictionariesForObjectRecords:_records
               ofEntity:@"Enterprise"
               withEnterprises:NO];
}

- (NSArray *)dictionariesForContactRecords:(NSArray *)_records
  withEnterprises:(BOOL)_withEnterprises
{
  return [self _dictionariesForObjectRecords:_records
               ofEntity:@"Person"
               withEnterprises:_withEnterprises];
}

- (NSDictionary *)teamDictionaryForTeam:(EOGlobalID *)_teamGID
  withMembers:(NSArray *)_members
  fromLookupCache:(NSDictionary *)_lookupCache
{
  NSMutableArray *teamMembers;
  NSEnumerator *memberEnum;
  id member;
  NSMutableDictionary *teamDict;
  NSString *teamName;
  
  if ((teamName = [self teamNameForTeamWithGID:_teamGID]) == nil) {
    [self logWithFormat:@"warning: no team name for team GID"];
    teamName = @"";
  }
      
  teamDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                  teamName, @"teamName",
                                  [NSNumber numberWithBool:YES],
                                  @"isTeam",
                                  nil];

  teamMembers = [NSMutableArray arrayWithCapacity:[_members count]];
  memberEnum = [_members objectEnumerator];
  while ((member = [memberEnum nextObject])) {
    id elem;

    if ((elem = [_lookupCache valueForKey:member]) != nil)
      [teamMembers addObject:elem];
    else
      [self logWithFormat:@"skipping %@, not found in lookup cache",
            member];
  }

  //[teamMembers sortUsingFunction:personSort context:nil];
  [teamDict setObject:teamMembers forKey:@"members"];
  return teamDict;
}

@end /* SkyContactAction(Conversion) */
