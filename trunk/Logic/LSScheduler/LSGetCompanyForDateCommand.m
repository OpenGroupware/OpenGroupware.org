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

#include <LSFoundation/LSDBObjectBaseCommand.h>

@class NSMutableArray;

@interface LSGetCompanyForDateCommand : LSDBObjectBaseCommand
{
  NSMutableArray *currentIds;
  BOOL           fetchGlobalIDs;
  BOOL           singleFetch;
  BOOL           resolveTeams; /* only works on to-one fetches currently */
}
@end

#import <EOControl/EOKeyGlobalID.h>
#import "common.h"

@implementation LSGetCompanyForDateCommand

static NSNumber *yesNum = nil;

+ (void)initialize {
  if (yesNum == nil) yesNum = [[NSNumber numberWithBool:YES] retain];
}

- (void)dealloc {
  [self->currentIds release];
  [super dealloc];
}

/* accessors */

- (void)setFetchGlobalIDs:(BOOL)_flag {
  self->fetchGlobalIDs = _flag;
}
- (BOOL)fetchGlobalIDs {
  return self->fetchGlobalIDs;
}

/* command methods */

- (NSArray *)_ids {
  NSMutableSet *idSet;
  NSEnumerator *listEnum;
  id           item;

  idSet    = [NSMutableSet set];
  listEnum = [[self object] objectEnumerator];

  while ((item = [listEnum nextObject])) {
    id pKey;

    pKey = ([self fetchGlobalIDs])
      ? [item keyValues][0]
      : [item valueForKey:@"dateId"];
    
    [self assert:(pKey != nil) reason:@"found foreign key which is nil !"];

    if (pKey) [idSet addObject:pKey];
  }
  return [idSet allObjects];
}

- (EOSQLQualifier *)_qualifierOneAppointmentForTeam {
  EOEntity       *teamEntity;
  EOSQLQualifier *qualifier;
  id             fkey;
  
  teamEntity = [[self databaseModel] entityNamed:@"Team"];
  fkey       = [[self object] lastObject];
  fkey       = [self fetchGlobalIDs]
             ? [(EOKeyGlobalID *)fkey keyValues][0]
             : [fkey valueForKey:@"dateId"];
  qualifier  = [[EOSQLQualifier alloc] initWithEntity:teamEntity
                                       qualifierFormat:
                                       @"%A = %@",
                                       @"toDateCompanyAssignment.dateId",
                                       fkey];
  
  [qualifier setUsesDistinct:YES];

  return [qualifier autorelease];  
}

- (EOSQLQualifier *)_qualifierOneAppointmentForPerson {
  EOEntity       *personEntity;
  EOSQLQualifier *qualifier;
  id             fkey;
  
  personEntity = [[self databaseModel] entityNamed:@"Person"];
  fkey         = [[self object] lastObject];
  fkey         = [self fetchGlobalIDs]
               ? [(EOKeyGlobalID *)fkey keyValues][0]
               : [fkey valueForKey:@"dateId"];
  
  qualifier = [[EOSQLQualifier alloc] initWithEntity:personEntity
                                   qualifierFormat:
                                      @"%A = %@",
                                      @"toDateCompanyAssignment.dateId", fkey];
  [qualifier setUsesDistinct:YES];
  
  return [qualifier autorelease];
}

- (EOSQLQualifier *)_qualifierForDateCompanyAssignment:(NSArray *)_ids {
  EOEntity       *assignmentEntity;
  EOSQLQualifier *qualifier;
  NSString       *in;
  
  assignmentEntity = [[self databaseModel]
                            entityNamed:@"DateCompanyAssignment"];
  in               = [self joinPrimaryKeysFromArrayForIN:_ids];
  
  qualifier        = [EOSQLQualifier alloc];
  qualifier        = ([in length] > 0)
                   ? [qualifier initWithEntity:assignmentEntity
                                qualifierFormat:@"%A IN (%@)", @"dateId", in]
                   : [qualifier initWithEntity:assignmentEntity
                                qualifierFormat:@"1=0"];

  [qualifier setUsesDistinct:YES];
  return [qualifier autorelease];
}

- (EOSQLQualifier *)_qualifierMoreAppointmentsForTeam {
  EOEntity       *teamEntity;
  EOSQLQualifier *qualifier;
  NSString       *in         = nil;

  teamEntity = [[self databaseModel] entityNamed:@"Team"];
  in         = [self joinPrimaryKeysFromArrayForIN:self->currentIds];
  qualifier  = [EOSQLQualifier alloc];
  qualifier  = ([in length] > 0)
             ? [qualifier initWithEntity:teamEntity
                          qualifierFormat:
                          @"%A IN (%@)",
                          @"toDateCompanyAssignment.dateId", in]
             : [qualifier initWithEntity:teamEntity qualifierFormat:@"1=2"];

  [qualifier setUsesDistinct:YES];
  return [qualifier autorelease];
}

- (EOSQLQualifier *)_qualifierMoreAppointmentsForPerson {
  EOEntity       *personEntity;
  EOSQLQualifier *qualifier;
  NSString       *in;

  personEntity = [[self databaseModel] entityNamed:@"Person"];
  in           = [self joinPrimaryKeysFromArrayForIN:self->currentIds];
  qualifier    = [EOSQLQualifier alloc];
  qualifier    = ([in length] > 0)
               ? [qualifier initWithEntity:personEntity
                            qualifierFormat:
                            @"%A IN (%@)",
                            @"toDateCompanyAssignment.dateId", in]
               : [qualifier initWithEntity:personEntity
                            qualifierFormat:@"1=2"];

  [qualifier setUsesDistinct:YES];
  return [qualifier autorelease];
}

- (void)_fetchExtendedAttributesOfParticipants:(NSSet *)_objs 
  inContext:(id)_context 
{
  // get extended attributes
  LSRunCommandV(_context, @"person", @"get-extattrs",
                @"objects", [_objs allObjects],
                @"relationKey", @"companyValue", nil);
}
- (void)_fetchPhonesOfParticipants:(NSSet *)_objs inContext:(id)_context {
  // get telephones
  LSRunCommandV(_context, @"person", @"get-telephones",
                @"objects", [_objs allObjects],
                @"relationKey", @"telephones", nil);
}

- (NSArray *)_expandTeamGIDs:(NSArray *)_gids inContext:(id)_context {
  return LSRunCommandV(_context, @"team", @"expand",
                           @"teams", _gids,
                           @"fetchGlobalIDs", yesNum,
                           nil);
}
- (NSArray *)_expandTeams:(NSArray *)_teams inContext:(id)_context {
  return LSRunCommandV(_context, @"team", @"expand", @"teams", _teams, nil);
}

- (NSException *)_fetchResultsOfChannel:(EODatabaseChannel *)_channel
  into:(id)_result
{
  /* Note: _result can be either a mutable set or a mutable array! */
  id obj;
  
  while ((obj = [_channel fetchWithZone:NULL]))
    [_result addObject:obj];
  return nil;
}

- (NSArray *)_fetchGIDsForOneObjectInContext:(id)_context {
  /* TODO: cleanup this method */
  EODatabaseChannel *channel;
  NSMutableSet      *participants;
  EOSQLQualifier    *q;
  NSArray *gids;

  channel      = [self databaseChannel];
  participants = [NSMutableSet setWithCapacity:16];
    
  /* run person participant query */
    
  q    = [self _qualifierOneAppointmentForPerson];
  gids = [channel globalIDsForSQLQualifier:q];

  if ([gids count] > 0) {
    NSArray *a;

    a = gids;
    a = [[_context accessManager] objects:a forOperation:@"r"];

    if ([a count] != [gids count]) {
      NSMutableArray *ma;
      NSEnumerator   *enumerator;
      id             obj;

      enumerator = [gids objectEnumerator];
      ma         = [NSMutableArray arrayWithCapacity:[a count]];

      while ((obj = [enumerator nextObject])) {
        if ([a containsObject:obj]) 
          [ma addObject:obj];
      }
      gids = ma;
    }
  }    
  [self assert:(gids != nil)];
  [participants addObjectsFromArray:gids];
    
  /* run team participant query */
    
  q    = [self _qualifierOneAppointmentForTeam];
  gids = [channel globalIDsForSQLQualifier:q];
  [self assert:(gids != nil)];
    
  /* resolve teams if required */
  if (self->resolveTeams)
    gids = [self _expandTeamGIDs:gids inContext:_context];
  
  [participants addObjectsFromArray:gids];
  
  return [participants allObjects];
}
- (NSArray *)_fetchEOsForOneObjectInContext:(id)_context {
  /* TODO: cleanup this method */
  EODatabaseChannel *channel;
  NSMutableSet      *participants;
  EOSQLQualifier    *q;

  channel      = [self databaseChannel];
  participants = [NSMutableSet setWithCapacity:16];
  
  /* fetch persons */
  q = [self _qualifierOneAppointmentForPerson];
  [self assert:[channel selectObjectsDescribedByQualifier:q
                        fetchOrder:nil]];
  [[self _fetchResultsOfChannel:channel into:participants] raise];
    
  if ([participants count] > 0) {
    NSArray *a;

    a = [[participants allObjects] map:@selector(globalID)];
    a = [[_context accessManager] objects:a forOperation:@"r"];

    if ([a count] != [participants count]) {
      NSMutableArray *ma;
      NSEnumerator   *enumerator;
      id             obj;

      enumerator = [participants objectEnumerator];
      ma         = [NSMutableArray arrayWithCapacity:[a count]];

      while ((obj = [enumerator nextObject])) {
        if ([a containsObject:[obj globalID]])
          [ma addObject:obj];
      }
      participants = [NSMutableSet setWithArray:ma];
    }
  }    

  [self _fetchExtendedAttributesOfParticipants:participants 
        inContext:_context];
  [self _fetchPhonesOfParticipants:participants inContext:_context];
    
  /* fetch teams */
    
  q = [self _qualifierOneAppointmentForTeam];
  [self assert:[channel selectObjectsDescribedByQualifier:q
                        fetchOrder:nil]];
  if (self->resolveTeams) {
    NSMutableArray *teams;
      
    teams = [NSMutableArray arrayWithCapacity:16];
    [[self _fetchResultsOfChannel:channel into:teams] raise];
      
    if ([teams count] > 0) {
      NSArray *tmp;
      tmp = [self _expandTeams:teams inContext:_context];
      [participants addObjectsFromArray:tmp];
    }
  }
  else {
    [[self _fetchResultsOfChannel:channel into:participants] raise];
  }
  
  [[[self object] lastObject]
            takeValue:[participants allObjects]
            forKey:@"participants"];
  return [participants allObjects];
}

- (NSArray *)_fetchForOneObjectInContext:(id)_context {
  NSArray *result;

  result = [self fetchGlobalIDs]
    ? [self _fetchGIDsForOneObjectInContext:_context]
    : [self _fetchEOsForOneObjectInContext:_context];
  
  return result;
}

- (id)_findParticipantWithId:(NSNumber *)_cId inParticipants:(NSArray *)_parts {
  NSEnumerator *listEnum;
  id           myParticipant;
  
  listEnum     = [_parts objectEnumerator];
  while ((myParticipant = [listEnum nextObject])) {
    if ([[myParticipant valueForKey:@"companyId"] isEqual:_cId])
      return myParticipant;
  }
  return nil;
}

- (void)_setAssignments:(NSMutableArray *)_assignments
  andParticipants:(NSArray *)_participants
  onAppointment:(id)myAppointment
{
  NSMutableArray *myAssignments, *myParticipants;
  int            i, cnt;
    
  myAssignments  = [[NSMutableArray alloc] init];
  myParticipants = [[NSMutableArray alloc] init];
    
  for (i = 0, cnt = [_assignments count]; i < cnt; ) {
    id myAssignment = [_assignments objectAtIndex:i];
    NSNumber *cId;
    id       myParticipant;
      
    if (![[myAppointment valueForKey:@"dateId"]
          isEqual:[myAssignment valueForKey:@"dateId"]]) {
      i++;
      continue;
    }
        
    cId           = [myAssignment valueForKey:@"companyId"];
    myParticipant = [self _findParticipantWithId:cId
                          inParticipants:_participants];
        
    [myAssignments addObject:myAssignment];

    if (myParticipant)
      [myParticipants addObject:myParticipant];
    
    [_assignments removeObjectAtIndex:i];
    cnt--;
  }
  
  [myAppointment takeValue:myParticipants forKey:@"participants"];
    
  [myAssignments  release]; myAssignments  = nil;
  [myParticipants release]; myParticipants = nil;
}

- (void)_setAssignments:(NSMutableArray *)_assignments
  andParticipants:(NSArray *)_participants
{
  NSEnumerator *listEnum;
  id           myAppointment;

  listEnum = [[self object] objectEnumerator];
  while ((myAppointment = [listEnum nextObject])) {
    [self _setAssignments:_assignments andParticipants:_participants
          onAppointment:myAppointment];
  }
}

- (NSArray *)_fetchForMoreGidsInContext:(id)_context {
  // TODO: split up this big method
  EOAdaptorChannel    *adChannel;
  NSMutableDictionary *gids;
  NSDictionary        *result; 
  int                 cnt, cntIds, max;

  adChannel = [[self databaseChannel] adaptorChannel];
  gids      = [[NSMutableDictionary alloc] init];

  [self->currentIds addObjectsFromArray:[self _ids]];

  max    = 240;
  cntIds = [self->currentIds count];
  cnt    = 0;
  
  while (cntIds > 0) {
    EOSQLQualifier *q;
    EOEntity       *entity;
    NSArray        *attrs;
    BOOL           isOk;
    NSDictionary   *row;
    NSArray        *idTmp;

    static Class EOKeyGlobalIDClass = NULL;

    if (EOKeyGlobalIDClass == NULL)
      EOKeyGlobalIDClass = [EOKeyGlobalID class];

    if (cntIds > max) {
      idTmp = [self->currentIds subarrayWithRange:NSMakeRange(cnt, max)];
      cntIds = cntIds - max;
      cnt   += 240;
    }
    else {
      idTmp  = [self->currentIds subarrayWithRange:NSMakeRange(cnt , cntIds)];
      cntIds = 0;
    }
    q      = [self _qualifierForDateCompanyAssignment:idTmp];
    entity = [q entity];
    attrs  = [NSArray arrayWithObjects:
                      [entity attributeNamed:@"dateId"],
                      [entity attributeNamed:@"companyId"],
                      nil];
  
    isOk = [adChannel selectAttributes:attrs
                      describedByQualifier:q
                      fetchOrder:nil
                      lock:NO];
    [self assert:isOk reason:[sybaseMessages description]];

    while ((row = [adChannel fetchAttributes:attrs withZone:NULL])) {
      NSNumber       *sourceId,  *targetId;
      EOGlobalID     *sourceGid;
      NSMutableArray *subGids;

      sourceId = [row objectForKey:@"dateId"];
      targetId = [row objectForKey:@"companyId"];
    
      sourceGid = [EOKeyGlobalIDClass globalIDWithEntityName:[self entityName]
                                      keys:&sourceId keyCount:1 zone:NULL];
    
      if ((subGids = [gids objectForKey:sourceGid]) == nil) {
        subGids = [NSMutableArray array];
        [gids setObject:subGids forKey:sourceGid];
      }
      [subGids addObject:targetId];
    }
  }
  /* produce target (team or person) gids */
  {
    NSMutableArray *a;
    EOGlobalID     *sourceGid;
    NSEnumerator   *keys;
    
    /* cache ids for access check */
    a = [NSMutableArray arrayWithCapacity:512];

    keys = [gids keyEnumerator];
    while ((sourceGid = [keys nextObject])) {
      NSMutableArray *ids;
      NSArray        *tmp;
      
      ids = [gids objectForKey:sourceGid];
      tmp = [[_context typeManager] globalIDsForPrimaryKeys:ids];
      
      [ids removeAllObjects];
      [ids addObjectsFromArray:tmp];

      [a addObjectsFromArray:tmp];
    }
    { /* check access */
      NSEnumerator *keyEnumerator;
      id           key;
      NSArray      *readableObjects;
      
      readableObjects = [[_context accessManager] objects:a forOperation:@"r"];
      
      keyEnumerator = [gids keyEnumerator];
      while ((key = [keyEnumerator nextObject])) {
        NSArray      *ids;
        NSEnumerator *enumerator;
        id           *accessIds, obj;
        int          cnt;

        cnt        = 0;
        ids        = [gids objectForKey:key];
        accessIds  = calloc([ids count] + 1, sizeof(id));
        enumerator = [ids objectEnumerator];

        while ((obj = [enumerator nextObject])) {
          if ([readableObjects containsObject:obj])
            accessIds[cnt++] = obj;
        }
        if (cnt != [ids count]) {
          ids = [NSArray arrayWithObjects:accessIds count:cnt];
          [gids setObject:ids forKey:key];
        }
        if (accessIds) free(accessIds); accessIds = NULL;
      }
    }
  }
  [self->currentIds removeAllObjects];
  result = [gids copy];
  [gids release]; gids = nil;
  return [result autorelease];
}

- (NSArray *)_fetchForMoreObjectsInContext:(id)_context {
  NSMutableArray *myAssignments, *participants, *persons;
  NSArray        *allIds;
  int            allIdsCount;
  
  if ([self fetchGlobalIDs])
    return [self _fetchForMoreGidsInContext:_context];
  
  myAssignments = [NSMutableArray arrayWithCapacity:256];
  participants  = [NSMutableArray arrayWithCapacity:128];
  persons       = [NSMutableArray arrayWithCapacity:64];
  allIds        = [self _ids];
  allIdsCount   = [allIds count];

  if (allIdsCount > 0) {
    EODatabaseChannel *channel;
    EOAdaptorChannel  *adChannel;
    EOSQLQualifier    *q;
    int               maxSet, countOfRep, i, j;
    id                obj; 
    
    maxSet     = 240;
    countOfRep = (allIdsCount - 1) / maxSet + 1;
    channel    = [self databaseChannel];
    adChannel  = [channel adaptorChannel];

    /* foreach batch */
    
    for (i = 0; i < countOfRep; i++) {
      NSArray *attributes;
      int     repBeg, repEnd, x, y;

      repBeg = i * maxSet;
      
      x = (allIdsCount - repBeg); y = (maxSet - 1);
      x = (x > y) ? y : x;
      repEnd = repBeg + x;
      
      for (j = repBeg; j < repEnd; j++) {
        [self->currentIds addObject:[allIds objectAtIndex:j]];
      }
      
      /* fetch assignmments */
      
      q = [self _qualifierForDateCompanyAssignment:self->currentIds];
      attributes = [[q entity] attributes];
      [self assert:[adChannel selectAttributes:attributes
                              describedByQualifier:q
                              fetchOrder:nil
                              lock:NO]];
      while ((obj = [adChannel fetchAttributes:attributes withZone:NULL])) {
        [myAssignments addObject:obj];
      }
      
      /* fetch persons */
      
      q = [self _qualifierMoreAppointmentsForPerson];
      [self assert:[channel selectObjectsDescribedByQualifier:q
                            fetchOrder:nil]];
      [[self _fetchResultsOfChannel:channel into:persons] raise];
      
      /* fetch teams */
      
      q = [self _qualifierMoreAppointmentsForTeam];
      [self assert:[channel selectObjectsDescribedByQualifier:q
                            fetchOrder:nil]];
      [[self _fetchResultsOfChannel:channel into:participants] raise];
      [self->currentIds removeAllObjects];
    }

    //get extended attributes 
    LSRunCommandV(_context, @"person", @"get-extattrs",
                  @"objects", persons,
                  @"relationKey", @"companyValue", nil);
    
    //get telephones
    LSRunCommandV(_context, @"person", @"get-telephones",
                  @"objects", persons,
                  @"relationKey", @"telephones", nil);

    [participants addObjectsFromArray:persons];

    [self _setAssignments:myAssignments andParticipants:participants];
  }
  return participants;
}

- (void)_executeInContext:(id)_context {
  NSAutoreleasePool *pool;
  id                tmp;
  
  pool = [[NSAutoreleasePool alloc] init];
  {
    [self->currentIds release]; self->currentIds = nil;
    self->currentIds = [[NSMutableArray alloc] init];
  
    if ([[self object] count] == 1) {
      tmp = [self _fetchForOneObjectInContext:_context];
      if (!singleFetch) {
        tmp = [NSDictionary dictionaryWithObject:tmp
                            forKey:[[self object] objectAtIndex:0]];
      }
    }
    else
      tmp = [self _fetchForMoreObjectsInContext:_context];

    [self setReturnValue:tmp];
    [self->currentIds release]; self->currentIds = nil;
  }
  [pool release];
}

/* record initializer */

- (NSString *)entityName {
  return @"Date";
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"object"] ||
      [_key isEqualToString:@"date"]   ||
      [_key isEqualToString:@"appointment"]) {
    [self setObject:[NSArray arrayWithObject:_value]];
    self->singleFetch = YES;
    return;
  }
  if ([_key isEqualToString:@"appointments"] ||
      [_key isEqualToString:@"dates"]) {
    [self setObject:_value];
    return;
  }
  if ([_key isEqualToString:@"fetchGlobalIDs"]) {
    [self setFetchGlobalIDs:[_value boolValue]];
    return;
  }
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"object"] ||
      [_key isEqualToString:@"date"]   ||
      [_key isEqualToString:@"appointment"])
    return [[self object] lastObject];

  if ([_key isEqualToString:@"dates"] ||
           [_key isEqualToString:@"appointments"])
    return [self object];
  
  if ([_key isEqualToString:@"fetchGlobalIDs"])
    return [NSNumber numberWithBool:[self fetchGlobalIDs]];
  
  return [super valueForKey:_key];
}

@end /* LSGetCompanyForDateCommand */
