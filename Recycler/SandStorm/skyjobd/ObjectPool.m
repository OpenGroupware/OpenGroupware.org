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

#include "ObjectPool.h"
#include "NSObject+Transaction.h"
#include "common.h"

@implementation ObjectPool

- (id)initWithContext:(id)_ctx {
  if ((self = [super init])) {
    self->context = _ctx;
  }
  return self;
}

+ (id)poolWithContext:(id)_ctx {
  return AUTORELEASE([[[self class] alloc] initWithContext:_ctx]);
}

- (void)dealloc {
  //RELEASE(self->context);
  [super dealloc];
}

/* accessors */

- (id)commandContext {
  return self->context;
}

- (NSArray *)_getTeamsForGIDs:(NSArray *)_gids
  withListAttributes:(BOOL)_listAttrs
{
  if (_gids != nil) {
    LSCommandContext *ctx;
    static NSArray *attributes = nil;
    static NSArray *listAttrs = nil;
    NSArray *result;

    ctx = [self commandContext];

    NSLog(@"-- executing command team::get-by-globalid");
    if (_listAttrs) {
      if (listAttrs == nil)
        listAttrs = [[NSArray alloc] initWithObjects:@"login",
                                     @"description",@"isTeam",nil];

      result = [ctx runCommand:@"team::get-by-globalid",
                    @"gids", _gids,
                    @"attributes", listAttrs,
                    @"fetchArchivedTeams", [NSNumber numberWithBool:YES],
                    nil];
    }
    else {
      if (attributes == nil)
        attributes = [[NSArray alloc] initWithObjects:
                                      @"globalID",
                                      @"description",
                                      @"login",
                                      nil];
  

      result = [ctx runCommand:@"team::get-by-globalid",
                    @"gids", _gids,
                    @"fetchArchivedTeams", [NSNumber numberWithBool:YES],
                    nil];
    }
      
    if ([self isCurrentTransactionCommitted])
      return result;
  }
  else {
    [self logWithFormat:@"no global IDs set"];
  }
  return nil;
}

- (NSArray *)_getPersonsForGIDs:(NSArray *)_gids
  withListAttributes:(BOOL)_listAttrs
{
  if (_gids != nil) {
    LSCommandContext *ctx;
    static NSArray *listAttrs = nil;
    static NSArray *attributes = nil;
    NSArray *result;

    ctx = [self commandContext];

    NSLog(@"--> executing command person::get-by-globalid");

    if (_listAttrs) {
      if (listAttrs == nil)
        listAttrs = [[NSArray alloc] initWithObjects:@"login",nil];
      
      result = [ctx runCommand:@"person::get-by-globalid",
                    @"gids", _gids,
                    @"attributes", listAttrs,
                    @"fetchArchivedPersons", [NSNumber numberWithBool:YES],
                    nil];
    }
    else {
      if (attributes == nil)
        attributes = [[NSArray alloc] initWithObjects:
                                      @"globalID",
                                      @"name",
                                      @"login",
                                      @"firstname",
                                      nil];
    
      result = [ctx runCommand:@"person::get-by-globalid",
                    @"gids", _gids,
                    @"attributes", attributes,
                    @"fetchArchivedPersons", [NSNumber numberWithBool:YES],
                    nil];
    }
      
    if ([self isCurrentTransactionCommitted])
      return result;
  }
  else {
    [self logWithFormat:@"no global IDs set"];
  }
  return nil;
}

- (NSString *)currentCompanyId {
  return [[[[self commandContext] valueForKey:LSAccountKey]
                  valueForKey:@"companyId"]
                  stringValue];
}

- (void)_addUserStatus:(NSString *)_key
  forObject:(id)_object
  toDictionary:(NSMutableDictionary *)_dict
{
  NSNumber *companyID;
  BOOL flag;
  NSString *cCid;

  companyID = [NSNumber numberWithInt:[[self currentCompanyId] intValue]];
  cCid = [[_object valueForKey:@"companyId"] stringValue];
  
  if ([[_object valueForKey:@"isTeam"] boolValue]) {
    LSCommandContext *ctx;

    if ((ctx = [self commandContext]) != nil) {
      NSArray *members;

      members = [ctx runCommand:@"team::members",
                     @"team", _object,
                     @"suppressAdditionalInfos", [NSNumber numberWithBool:YES],
                     nil];

      flag = [[members valueForKey:@"companyId"] containsObject:companyID];
    }
  }
  else
    flag = [[companyID stringValue] isEqualToString:cCid];
  [_dict setObject:[NSNumber numberWithBool:flag] forKey:_key];
}

- (void)fillArray:(NSMutableArray *)_array
  withRole:(NSString *)_role forGlobalIDs:(NSArray *)_gids
  usingListAttributes:(BOOL)_listAttrs
{
  NSMutableArray *entries;
  NSEnumerator *gidEnum;
  EOGlobalID *gid;
  NSMutableArray *persons;
  NSMutableArray *teams;

  persons = [NSMutableArray arrayWithCapacity:[_gids count]/2];
  teams = [NSMutableArray arrayWithCapacity:[_gids count]/2];

  if ([_role isEqualToString:@"executant"]) {
    gidEnum = [_gids objectEnumerator];
    while ((gid = [gidEnum nextObject])) {
      if ([[gid entityName] isEqualToString:@"Person"])
        [persons addObject:gid];
      else
        [teams addObject:gid];
    }

    if ([persons count] > 0) {
      entries = [[self _getPersonsForGIDs:persons
                       withListAttributes:_listAttrs] mutableCopy];
    }
    else
      entries = [NSMutableArray arrayWithCapacity:[teams count]];

   if ([teams count] > 0)
     [entries addObjectsFromArray:[self _getTeamsForGIDs:teams
                                         withListAttributes:_listAttrs]];
  }
  else {
    NSLog(@"ROLE is %@", _role);
    NSLog(@"gids are %@", _gids);
    entries = (NSMutableArray *)[self _getPersonsForGIDs:_gids
                                      withListAttributes:_listAttrs];
  }
  
  if (entries != nil) {
    NSEnumerator *personEnum;
    NSMutableDictionary *lookupDict;
    id person;
    NSEnumerator *arrayEnum;
    NSMutableDictionary *arrayElem;
    NSString *keyName;

    keyName = [_role stringByAppendingString:@"Id"];

    // build lookup dictionary
    lookupDict = [NSMutableDictionary dictionaryWithCapacity:
                                      [entries count]];

    personEnum = [entries objectEnumerator];
    while ((person = [personEnum nextObject])) {
      id obj;
      BOOL personIsArchived;
      
      personIsArchived = [[person valueForKey:@"dbStatus"]
                                  isEqualToString:@"archived"];
      
      if ([[person valueForKey:@"isTeam"] boolValue])
        obj = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   [person valueForKey:@"description"],
                                   @"login",
                                   [self _urlStringForGlobalId:
                                         [person valueForKey:@"globalID"]],
                                   @"id",
                                   nil];
      else
        obj = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   [person valueForKey:@"login"],
                                   @"login",
                                   [person valueForKey:@"firstname"],
                                   @"firstname",
                                   [person valueForKey:@"name"],
                                   @"name",
                                   [self _urlStringForGlobalId:
                                         [person valueForKey:@"globalID"]],
                                   @"id",
                                   nil];

      if ([_role isEqualToString:@"creator"]) {
        [self _addUserStatus:@"userIsCreator"
              forObject:person
              toDictionary:obj];

      }
      else if ([_role isEqualToString:@"executant"]) {
        [self _addUserStatus:@"userIsExecutant"
              forObject:person
              toDictionary:obj];
      }

      [obj setObject:[NSNumber numberWithBool:personIsArchived]
           forKey:@"isArchived"];

      [lookupDict setObject:obj
                  forKey:[person valueForKey:@"companyId"]];
    }

    arrayEnum = [_array objectEnumerator];
    while ((arrayElem = [arrayEnum nextObject])) {
      NSDictionary *personEntry;

      personEntry = [lookupDict valueForKey:[arrayElem valueForKey:keyName]];

      if (personEntry != nil) {
        [arrayElem setObject:personEntry forKey:_role];
      }
      [arrayElem removeObjectForKey:keyName];
    }
  }
  if ([persons count] > 0)
    RELEASE(entries); entries = nil;
}

@end /* ObjectPool */
