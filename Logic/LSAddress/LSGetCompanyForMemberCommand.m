/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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
// $Id$

#import "common.h"
#import "LSGetCompanyForMemberCommand.h"
#import <GDLAccess/EOSQLQualifier.h>
#import <EOControl/EOKeyGlobalID.h>

@implementation LSGetCompanyForMemberCommand

/* make configurable and document */
const unsigned int batchSize = 200;

static int compareGroups(id group1, id group2, void *context) {
  NSString *name1 = [group1 valueForKey:@"description"];
  NSString *name2 = [group2 valueForKey:@"description"];
    
  if (name1 == nil) name1 = @"";
  if (name2 == nil) name2 = @"";

  return [name1 compare:name2];
}

- (id)initForOperation:(NSString *)_operation inDomain:(NSString *)_domain {
  if ((self = [super initForOperation:_operation inDomain:_domain])) {
    self->fetchForOneObject = nil;
  }
  return self;
}

- (void)dealloc {
  [self->relationKey       release];
  [self->members           release];
  [self->fetchForOneObject release];
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

- (NSArray *)_memberIdString {
  NSMutableSet *idSet    = nil;
  NSEnumerator *listEnum = nil;
  id           item      = nil;
  BOOL         doGIDs;
  
  idSet    = [NSMutableSet setWithCapacity:[self->members count]];
  listEnum = [self->members objectEnumerator];

  doGIDs = [self fetchGlobalIDs];
  while ((item = [listEnum nextObject])) {
    id pKey;
    
    pKey = doGIDs
      ? [item keyValues][0]
      : [item valueForKey:@"companyId"];
    
    if ([pKey isNotNull]) [idSet addObject:pKey];
  }
  
  item = [idSet allObjects];
  if ([item count] < batchSize)
    return [NSArray arrayWithObject:[item componentsJoinedByString:@","]];
  
  /* split into batches */
  {
    unsigned i, count = [item count], batchCount;
    NSMutableArray *batches;
    
    batchCount = count / batchSize + 1;
    batches = [NSMutableArray arrayWithCapacity:batchCount];
    
    for (i = 0; i < count; i += batchSize) {
      NSMutableString *batch;
      unsigned j;
      
      batch = [[NSMutableString alloc] initWithCapacity:batchSize];
      
      for (j = i; (j < (i + batchSize)) && (j < count); j++) {
        NSString *ids;
        
        if (j != i) [batch appendString:@","];

        ids = [[item objectAtIndex:j] stringValue];
        [batch appendString:ids];
      }
      
      [batches addObject:batch];
      RELEASE(batch);
    }
    return batches;
  }
}

- (EOSQLQualifier *)_qualifierForOneMember {
  EOEntity       *memberEntity;
  EOSQLQualifier *qualifier;
  id             pkeyValue;
  
  memberEntity = [[self database] entityNamed:[self groupEntityName]];

  pkeyValue = ([self fetchGlobalIDs])
    ? [[self member] keyValues][0]
    : [[self member] valueForKey:@"companyId"];
  
  qualifier = [[EOSQLQualifier alloc] initWithEntity:memberEntity
                                   qualifierFormat:
                                     @"%A = %@",
                                     @"toCompanyAssignment.subCompanyId",
                                      pkeyValue];
  [qualifier setUsesDistinct:YES];
  
  return AUTORELEASE(qualifier);  
}

- (EOSQLQualifier *)_qualifierForCompanyAssignment:(NSString *)_in {
  EOEntity       *assignmentEntity = nil;
  EOSQLQualifier *qualifier        = nil;

  assignmentEntity = [[self database] entityNamed:@"CompanyAssignment"];
  
  if ([_in length] > 0) {
    qualifier = [[[EOSQLQualifier alloc]
                                  initWithEntity:assignmentEntity
                                  qualifierFormat:@"%A IN (%@)",
                                  @"subCompanyId", _in]
                                  autorelease];
    [qualifier setUsesDistinct:YES];
  }
  return qualifier;
}

- (EOSQLQualifier *)_qualifierForMoreMembers:(NSString *)_in {
  EOEntity       *memberEntity = nil;
  EOSQLQualifier *qualifier    = nil;

  memberEntity = [[self database] entityNamed:[self groupEntityName]];
  
  qualifier = [EOSQLQualifier alloc];
  if ([_in length] > 0) {
    qualifier = [qualifier initWithEntity:memberEntity
                           qualifierFormat:
                             @"%A IN (%@)",
                             @"toCompanyAssignment.subCompanyId", _in];
  }
  else {
    qualifier = [qualifier initWithEntity:memberEntity
                           qualifierFormat:@"1=2"];
  }
  
  [qualifier setUsesDistinct:YES];
  
  return [qualifier autorelease];
}

- (NSArray *)_fetchForOneObjectInContext:(id)_context {
  NSArray           *checkedGroups = nil;
  NSMutableArray    *myGroups      = nil;
  EODatabaseChannel *channel       = nil;
  BOOL              isOk           = NO;
  id                obj            = nil;
  EOSQLQualifier    *q;

  myGroups  = [NSMutableArray arrayWithCapacity:64];
  channel   = [self databaseChannel];
  
  q = [self _qualifierForOneMember];

  if ([self fetchGlobalIDs]) {
    checkedGroups = [channel globalIDsForSQLQualifier:q];
    [self assert:(checkedGroups != nil) reason:[sybaseMessages description]];
    return checkedGroups;
  }
  else {
    isOk = [channel selectObjectsDescribedByQualifier:q
                    fetchOrder:nil];
  
    [self assert:isOk reason:[sybaseMessages description]];
  
    while ((obj = [channel fetchWithZone:NULL])) {
      [myGroups addObject:obj];
      obj = nil;
    }
    [myGroups sortUsingFunction:compareGroups context:self];
    {
      NSString *eName;

      eName = [[self groupEntityName] lowercaseString];
      
      checkedGroups = LSRunCommandV(_context,
                                    eName, @"check-permission",
                                    @"object", myGroups, nil);
    }
    [[self member] takeValue:checkedGroups forKey:[self relationKey]];
    return checkedGroups;
  }
}

- (id)_findGroupWithId:(NSNumber *)_groupId inGroups:(NSArray *)_groups  {
  NSEnumerator *listEnum = [_groups objectEnumerator];
  id           myGroup   = nil;

  while ((myGroup = [listEnum nextObject])) {
    if ([[myGroup valueForKey:@"companyId"] isEqual:_groupId]) {
      return myGroup;
    }
  }
  return nil;
}

- (void)_setAssignments:(NSMutableArray *)_assignments
  andGroups:(NSArray *)_groups
{
  NSEnumerator *listEnum = nil;
  id           myMember  = nil;

  listEnum = [self->members objectEnumerator];

  while ((myMember = [listEnum nextObject])) {
    NSMutableArray *myGroups = nil;
    NSNumber       *memberId = nil;
    int            i, cnt    = [_assignments count];

    myGroups = [NSMutableArray arrayWithCapacity:64];
    memberId = [myMember valueForKey:@"companyId"];

    i = 0;
    while (i < cnt) {
      id myAssignment = [_assignments objectAtIndex:i];

      if ([memberId isEqual:[myAssignment valueForKey:@"subCompanyId"]]) {
        NSNumber *cId;
        id       myGroup;

        cId     = [myAssignment valueForKey:@"companyId"];
        myGroup = [self _findGroupWithId:cId inGroups:_groups];

        if (myGroup != nil) [myGroups addObject:myGroup];
        
        [_assignments removeObjectAtIndex:i];
        cnt--;
      }
      else
        i++;
    }
    [myGroups sortUsingFunction:compareGroups context:self];
    [myMember takeValue:myGroups forKey:[self relationKey]];
  }
}

- (NSArray *)_fetchForMoreGidsInContext:(id)_context {
  EOAdaptorChannel    *adChannel;
  NSMutableDictionary *gids;
  NSDictionary        *result;
  EOSQLQualifier      *q;
  EOEntity            *entity;
  NSArray             *attrs;
  BOOL                isOk;
  NSDictionary        *row;
  Class               EOKeyGlobalIDClass;

  EOKeyGlobalIDClass = [EOKeyGlobalID class];
  adChannel = [[self databaseChannel] adaptorChannel];
  gids      = [[NSMutableDictionary alloc] init];

  /* fetch in batches */
  {
    NSEnumerator *idBatches;
    NSString     *idBatch;
    
    idBatches = [[self _memberIdString] objectEnumerator];
    
    while ((idBatch = [idBatches nextObject])) {
      q = [self _qualifierForCompanyAssignment:idBatch];
      if (q == nil)
        return nil;
      //  [self assert:(q != nil) reason:@"missing qualifier"];
      
      entity = [q entity];
      attrs  = [NSArray arrayWithObjects:
                          [entity attributeNamed:@"subCompanyId"],
                          [entity attributeNamed:@"companyId"],
                          nil];
      
      isOk = [adChannel selectAttributes:attrs
                        describedByQualifier:q
                        fetchOrder:nil
                        lock:NO];
      [self assert:isOk reason:[sybaseMessages description]];
      
      while ((row = [adChannel fetchAttributes:attrs withZone:NULL])) {
        NSNumber       *sourceId,  *targetId;
        EOKeyGlobalID  *sourceGid, *targetGid;
        NSMutableArray *subGids;
        
        sourceId = [row objectForKey:@"subCompanyId"];
        targetId = [row objectForKey:@"companyId"];
        
        sourceGid = [EOKeyGlobalIDClass globalIDWithEntityName:
                                        [self entityName]
                                        keys:&sourceId keyCount:1 zone:NULL];

        targetGid = [EOKeyGlobalIDClass globalIDWithEntityName:
                                          [self groupEntityName]
                                        keys:&targetId keyCount:1 zone:NULL];
        
        if ((subGids = [gids objectForKey:sourceGid]) == nil) {
          subGids = [[NSMutableArray alloc] init];
          [gids setObject:subGids forKey:sourceGid];
          RELEASE(subGids);
        }
        [subGids addObject:targetGid];
      }
    }
  }
  
  result = [gids copy];
  [gids release]; gids = nil;
  return [result autorelease];
}

- (NSArray *)_fetchForMoreObjectsInContext:(id)_context {
  NSMutableArray    *myAssignments = nil;
  NSMutableArray    *myGroups      = nil;
  EODatabaseChannel *channel       = nil;
  NSArray           *checkedGroups = nil;
  BOOL              isOk           = NO;
  id                obj            = nil;
  EOSQLQualifier    *qualifier     = nil;

  if ([self fetchGlobalIDs])
    return [self _fetchForMoreGidsInContext:_context];
  
  myAssignments = [NSMutableArray arrayWithCapacity:64];
  myGroups      = [NSMutableArray arrayWithCapacity:64];
  channel       = [self databaseChannel];

  /* fetch in batches */
  {
    NSEnumerator *inBatches;
    NSString     *inBatch;

    inBatches = [[self _memberIdString] objectEnumerator];
    while ((inBatch = [inBatches nextObject])) {
      qualifier = [self _qualifierForCompanyAssignment:inBatch];
      
      if (qualifier != nil) {
  #if 1
        EOAdaptorChannel *adChannel;
        EOEntity *entity;
        NSArray  *attributes;
    
        adChannel  = [channel adaptorChannel];
        entity     = [qualifier entity];
        attributes = [NSArray arrayWithObjects:
                                [entity attributeNamed:@"companyId"],
                                [entity attributeNamed:@"subCompanyId"],
                                nil];
        isOk = [adChannel selectAttributes:attributes
                          describedByQualifier:qualifier
                          fetchOrder:nil
                          lock:NO];
        [self assert:isOk reason:[sybaseMessages description]];
        
        while ((obj = [adChannel fetchAttributes:attributes withZone:NULL]))
          [myAssignments addObject:obj];
  #else
        isOk = [channel selectObjectsDescribedByQualifier:qualifier
                        fetchOrder:nil];
        [self assert:isOk reason:[sybaseMessages description]];
        while ((obj = [channel fetchWithZone:nil])) {
          [myAssignments addObject:obj];
        }
#endif
      }
    }
  }

  if ([self->members count] > 0) {
    NSEnumerator *idBatches;
    NSString     *idBatch;
    
    idBatches = [[self _memberIdString] objectEnumerator];

    while ((idBatch = [idBatches nextObject])) {
      EOSQLQualifier *qmm;
      
      qmm = [self _qualifierForMoreMembers:idBatch];
    
      [self assert:[channel selectObjectsDescribedByQualifier:qmm
                            fetchOrder:nil]
            reason:[sybaseMessages description]];
    
      while ((obj = [channel fetchWithZone:NULL]))
        [myGroups addObject:obj];
    }
  }
  [self _setAssignments:myAssignments andGroups:myGroups];
  {
    NSString *eName;

    eName = [[self groupEntityName] lowercaseString];
      
    checkedGroups = LSRunCommandV(_context,
                                  eName, @"check-permission",
                                  @"object", myGroups, nil);
  }

  return checkedGroups;
}

- (void)_executeInContext:(id)_context {
  if ([self->members count] == 0)
    [self setReturnValue:[NSArray array]];

  if (self->fetchForOneObject != nil) {
    [self setReturnValue:[self->fetchForOneObject boolValue]
          ? [self _fetchForOneObjectInContext:_context]
          : [self _fetchForMoreObjectsInContext:_context]];
  }
  else {
    [self setReturnValue:([self->members count] == 1)
          ? [self _fetchForOneObjectInContext:_context]
          : [self _fetchForMoreObjectsInContext:_context]];
  }
}

// record initializer

- (NSString *)entityName {
  return @"Company";
}

- (NSString *)groupEntityName {
  return @"Company";
}

// accessors

- (void)setMember:(id)_member {
  NSArray *m;

  m = [NSArray arrayWithObject:_member];
  ASSIGN(self->members, m);
}
- (id)member {
  return [[self->members objectEnumerator] nextObject];
}

- (void)setMembers:(NSArray *)_members {
  ASSIGN(self->members, _members);
}
- (NSArray *)members {
  return self->members;
}
- (void)setRelationKey:(NSString *)_key {
  ASSIGN(self->relationKey, _key);
}
- (NSString *)relationKey {
  return self->relationKey;
}

// key/value coding

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"member"]) {
    [self setMember:_value];
    return;
  }
  else if ([_key isEqualToString:@"members"]) {
    [self setMembers:_value];
    return;
  }
  else if ([_key isEqualToString:@"relationKey"]) {
    [self setRelationKey:_value];
    return;
  }
  else if ([_key isEqualToString:@"fetchGlobalIDs"]) {
    [self setFetchGlobalIDs:[_value boolValue]];
    return;
  }
  else if ([_key isEqualToString:@"fetchForOneObject"]) {
    ASSIGN(self->fetchForOneObject, _value);
    return;
  }
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"member"])
    return [self member];
  else if ([_key isEqualToString:@"members"])
    return [self members];
  else if ([_key isEqualToString:@"relationKey"])
    return [self relationKey];
  else if ([_key isEqualToString:@"fetchGlobalIDs"])
    return [NSNumber numberWithBool:[self fetchGlobalIDs]];
  else if ([_key isEqualToString:@"fetchForOneObject"])
    return self->fetchForOneObject;
  return [super valueForKey:_key];
}

@end /* LSGetCompanyForMemberCommand */
