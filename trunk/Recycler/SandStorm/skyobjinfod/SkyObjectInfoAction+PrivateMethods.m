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

#include "SkyObjectInfoAction+PrivateMethods.h"
#include "common.h"

@implementation SkyObjectInfoAction(PrivateMethods)

- (id)documentManager {
  return [[self commandContext] documentManager];
}

- (void)_fillArray:(NSMutableArray *)_array
  withActorsForGlobalIDs:(NSArray *)_gids
{
  NSArray *persons;

  if ((persons = [self _getPersonsForGIDs:_gids]) != nil) {
    NSEnumerator *personEnum;
    NSMutableDictionary *lookupDict;
    id person;
    NSEnumerator *arrayEnum;
    NSMutableDictionary *arrayElem;
    
    // build lookup dictionary
    lookupDict = [NSMutableDictionary dictionaryWithCapacity:
                                      [persons count]];
        
    personEnum = [persons objectEnumerator];
    while ((person = [personEnum nextObject])) {
      id obj;
        
      obj = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 [person valueForKey:@"login"],
                                 @"login",
                                 [self _urlStringForGlobalId:
                                       [person valueForKey:@"globalID"]],
                                 @"id",
                                 nil];
                           
      [lookupDict setObject:obj
                  forKey:[person valueForKey:@"companyId"]];
    }

    arrayEnum = [_array objectEnumerator];
    while ((arrayElem = [arrayEnum nextObject])) {
      NSDictionary *personEntry;

      personEntry = [lookupDict valueForKey:
                                [arrayElem valueForKey:@"actorId"]];

      if (personEntry != nil)
        [arrayElem setObject:personEntry forKey:@"actor"];
      [arrayElem removeObjectForKey:@"actorId"];
    }
  }
}

- (NSArray *)_dictionariesForLogRecords:(NSArray *)_records
  withActor:(BOOL)_withActor
{
  NSEnumerator    *recordEnum;
  EOGenericRecord *record;
  NSMutableArray  *result;
  NSMutableArray  *actorGIDs;

  result = [NSMutableArray arrayWithCapacity:[_records count]];
  actorGIDs = [NSMutableArray arrayWithCapacity:[_records count]];
  
  recordEnum = [_records objectEnumerator];

  while ((record = [recordEnum nextObject])) {
    NSMutableDictionary *dict;

    dict = [NSMutableDictionary dictionaryWithCapacity:8];
    
    [dict setObject:[record valueForKey:@"creationDate"]
          forKey:@"creationDate"];
    [dict setObject:[record valueForKey:@"logText"] forKey:@"logText"];
    [dict setObject:[record valueForKey:@"action"] forKey:@"action"];

    if (_withActor) {
      NSString *actorId;
      EOGlobalID *gid;
      
      actorId = [record valueForKey:@"accountId"];
      [dict setObject:actorId forKey:@"actorId"];

      if ((gid = [self _globalIdForPersonWithId:actorId]) != nil)
        [actorGIDs addObject:gid];
    }

    [result addObject:dict];
  }

  if (_withActor)
    [self _fillArray:result withActorsForGlobalIDs:actorGIDs];

  return result;
}

- (NSArray *)_getPersonsForGIDs:(NSArray *)_gids {
  if (_gids != nil) {
    LSCommandContext *ctx;

    if ((ctx = [self commandContext]) != nil) {
      id result;

      NSLog(@"-- executing command person::get-by-globalid");
      result = [ctx runCommand:@"person::get-by-globalid",
                    @"gids", _gids,
                    nil];
      [self _ensureCurrentTransactionIsCommitted];
      return result;
    }
    else {
      [self logWithFormat:@"no valid command context found"];
    }
  }
  else {
    [self logWithFormat:@"no global IDs set"];
  }
  return nil;
}

- (NSString *)_urlStringForGlobalId:(id)_gid {
  return [[[[self commandContext] documentManager]
                  urlForGlobalID:_gid] absoluteString];
}

- (EOGlobalID *)_globalIdForPersonWithId:(NSString *)_id {
  EOGlobalID *gid;

  gid = [EOKeyGlobalID globalIDWithEntityName:@"Person"
                       keys:&_id
                       keyCount:1
                       zone:nil];
  if (gid != nil)
    return gid;

  [self logWithFormat:@"couldn't create gid for ID %@", _id];
  return nil;
}

- (void)_ensureCurrentTransactionIsCommitted {
  LSCommandContext *ctx;

  if ((ctx = [self commandContext]) != nil) {
    if ([ctx isTransactionInProgress]) {
      if (![ctx commit]) {  
        [self logWithFormat:@"couldn't commit transaction ..."];
      }
    }
  }
}

@end /* SkyObjectInfoAction(PrivateMethods) */
