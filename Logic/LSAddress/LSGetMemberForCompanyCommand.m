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

/*
  Superclass for:
    LSGetMemberForTeamCommand (team::members)
    ..
*/

#include "common.h"
#include "LSGetMemberForCompanyCommand.h"
#include <GDLAccess/EOSQLQualifier.h>
#include <EOControl/EOGlobalID.h>
#include <EOControl/EOKeyGlobalID.h>

@interface _LSGetMembersForCompany_Cache : NSObject
{
@public
  NSArray *groups;
  id      result;
}

@end

@interface LSGetMemberForCompanyCommand(PrivateMethods)
- (void)setFetchGlobalIDs:(BOOL)_flag;
- (BOOL)fetchGlobalIDs;
@end

@implementation LSGetMemberForCompanyCommand

// TODO: document and make configurable
static unsigned int batchSize = 200;
static BOOL coreOnNullGroup = NO;
static BOOL debugCache      = NO;

+ (void)initialize {
  if (coreOnNullGroup)
    NSLog(@"WARNING: coreOnNullGroup is enabled in get-member commands!");
}

+ (int)version {
  return [super version] + 0;
}

- (void)dealloc {
  [self->groups release];
  [super dealloc];
}

/* qualifier processing */

- (EOSQLQualifier *)verifyQualifier:(EOSQLQualifier *)_qual_ {
  EOSQLQualifier *qualifier;
  EOEntity       *entity;
  
  entity    = [[self databaseModel] entityNamed:[self memberEntityName]];
  qualifier = [[EOSQLQualifier alloc] 
		initWithEntity:entity
		qualifierFormat:@"dbStatus <> 'archived'"];
  [_qual_ conjoinWithQualifier:qualifier];
  [qualifier release];
  
  return _qual_;
}

/* command methods */

- (NSArray *)_splitIntoBatches:(NSArray *)item {
  unsigned i, count, batchCount;
  NSMutableArray *batches;
  
  count      = [item count];
  batchCount = count / batchSize + 1;
  batches    = [NSMutableArray arrayWithCapacity:batchCount];
    
  for (i = 0; i < count; i += batchSize) {
    NSMutableString *batch;
    unsigned j;
    
    batch = [[NSMutableString alloc] initWithCapacity:(batchSize + 1)];
    
    for (j = i; (j < (i + batchSize)) && (j < count); j++) {
      if (j != i) [batch appendString:@","];
      [batch appendString:[[item objectAtIndex:j] stringValue]];
    }
    
    [batches addObject:batch];
    [batch release];
  }
  return batches;
}

- (NSArray *)_groupIdString {
  NSMutableSet *idSet;
  NSEnumerator *listEnum;
  id           item;
  BOOL         doGIDs;
  
  idSet    = [NSMutableSet setWithCapacity:[self->groups count]];
  listEnum = [self->groups objectEnumerator];
  
  doGIDs = [self fetchGlobalIDs];
  while ((item = [listEnum nextObject]) != nil) {
    NSNumber *pKey;
    
    pKey = doGIDs
      ? [item keyValues][0]
      : [item valueForKey:@"companyId"];
    
    if ([pKey isNotNull])
      [idSet addObject:pKey];
  }
  
  item = [idSet allObjects];
  if ([item count] < batchSize)
    return [NSArray arrayWithObject:[item componentsJoinedByString:@","]];
  
  /* split into batches */
  return [self _splitIntoBatches:item];
}

- (EOSQLQualifier *)_qualifierForCompanyAssignment:(NSString *)_in {
  EOEntity       *assignmentEntity;
  EOSQLQualifier *qualifier;

  assignmentEntity = [[self databaseModel] entityNamed:@"CompanyAssignment"];
  
  qualifier = [EOSQLQualifier alloc];
  if ([_in isNotEmpty]) {
    qualifier = [qualifier initWithEntity:assignmentEntity
                           qualifierFormat:
                             @"%A IN (%@)", @"companyId", _in];
  }
  else {
    qualifier = [qualifier initWithEntity:assignmentEntity
                           qualifierFormat:@"1=2"];
  }

  [qualifier setUsesDistinct:YES];
  
  return [qualifier autorelease];
}

- (EOSQLQualifier *)buildQualifier {
  EOSQLQualifier    *q;
  EOEntity *memberEntity;
  id       pkeyValue;
    
  memberEntity = [[self databaseModel] entityNamed:[self memberEntityName]];
    
  pkeyValue = [self fetchGlobalIDs]
    ? [[self group] keyValues][0]
    : [[self group] valueForKey:@"companyId"];

  if (pkeyValue == nil)
    pkeyValue = [EONull null];
    
  q = [[EOSQLQualifier alloc]
                       initWithEntity:memberEntity
                       qualifierFormat:
                         @"%A=%@",
                         @"toCompanyAssignment1.companyId",
                         pkeyValue];
  [q setUsesDistinct:YES];
  return [q autorelease];  
}

- (NSArray *)_fetchForOneObjectInContext:(id)_context {
  EODatabaseChannel *channel        = nil;
  BOOL              isOk            = NO;
  EOSQLQualifier    *q;

  channel   = [self databaseChannel];
  
  q = [self buildQualifier];
  q = [self verifyQualifier:q];
  
  if ([self fetchGlobalIDs]) {
    NSArray *result;
    result = [channel globalIDsForSQLQualifier:q];
    [self assert:(result != nil) reason:[sybaseMessages description]];
    return result;
  }
  
  {
    NSMutableArray *myMembers;
    NSArray        *checkedMembers;
    id             obj;
    
    myMembers = [NSMutableArray arrayWithCapacity:64];
    
    isOk = [channel selectObjectsDescribedByQualifier:q
                    fetchOrder:nil];
    
    [self assert:isOk reason:[sybaseMessages description]];
    
    while ((obj = [channel fetchWithZone:NULL])) {
      [myMembers addObject:obj];
      obj = nil;
    }
    
    /* use access-manager for permission check */
    {
      NSArray      *gids;
      id           *objs, obj;
      NSEnumerator *enumerator;
      int          cnt;

      cnt  = 0;
      gids = [myMembers map:@selector(valueForKey:) with:@"globalID"];
      gids = [[_context accessManager] objects:gids forOperation:@"r"];
      objs = calloc([gids count] + 2, sizeof(id));
      
      enumerator = [myMembers objectEnumerator];
      while ((obj = [enumerator nextObject]) != nil) {
        if ([gids containsObject:[obj valueForKey:@"globalID"]])
          objs[cnt++] = obj;
      }
      checkedMembers = [NSMutableArray arrayWithObjects:objs count:cnt];
      if (objs != NULL) free(objs); objs = NULL;
    }
    
    [[self group] takeValue:checkedMembers forKey:@"members"];
    
    return checkedMembers;
  }
}

- (id)_findMemberWithId:(NSNumber *)_memberId inMembers:(NSArray *)_members  {
  // TODO: make that an NSArray category (-elementWithValue:..forKey: or sth)
  NSEnumerator *listEnum;
  id           myMember;
  
  listEnum = [_members objectEnumerator];
  while ((myMember = [listEnum nextObject]) != nil) {
    if ([[myMember valueForKey:@"companyId"] isEqual:_memberId])
      return myMember;
  }
  return nil;
}

- (void)_setAssignments:(NSArray *)_assignmentArgs
  andMembers:(NSArray *)_members
{
  NSMutableArray *_assignments;
  NSEnumerator *listEnum;
  id           myGroup;
  
  _assignments = [[_assignmentArgs mutableCopy] autorelease];
  
  listEnum = [self->groups objectEnumerator];
  while ((myGroup = [listEnum nextObject]) != nil) {
    NSMutableArray *myMembers = nil;
    NSNumber       *groupId   = nil; 
    int            i, cnt;

    myMembers = [NSMutableArray arrayWithCapacity:64];
    groupId   = [myGroup valueForKey:@"companyId"];
    
    for (i = 0, cnt = [_assignments count]; i < cnt; ) {
      id myAssignment = [_assignments objectAtIndex:i];
      
      if ([groupId isEqual:[myAssignment valueForKey:@"companyId"]]) {
        NSNumber *scId    = nil;
        id       myMember = nil;

        scId     = [myAssignment valueForKey:@"subCompanyId"];
        myMember = [self _findMemberWithId:scId inMembers:_members];
        
        if (myMember != nil)
          [myMembers addObject:myMember];

        [_assignments removeObjectAtIndex:i];
        cnt--;
      }
      else
        i++;
    }
    [myGroup takeValue:myMembers forKey:@"members"];
  }
}

- (NSArray *)_fetchForMoreGidsInContext:(id)_context {
  EOAdaptorChannel    *adChannel;
  NSMutableDictionary *gids;
  NSDictionary        *result;
  EOSQLQualifier *q;
  EOEntity       *entity;
  NSArray        *attrs;
  BOOL           isOk;
  NSDictionary   *row;
  Class          EOKeyGlobalIDClass;
  
  EOKeyGlobalIDClass = [EOKeyGlobalID class];
  adChannel = [[self databaseChannel] adaptorChannel];
  gids      = [[NSMutableDictionary alloc] init];

  /* collect company assignments */
  {
    NSEnumerator *e;
    NSString *in;

    e = [[self _groupIdString] objectEnumerator];
    while ((in = [e nextObject])) {
      q      = [self _qualifierForCompanyAssignment:in];
      entity = [q entity];
      attrs  = [NSArray arrayWithObjects:
                      [entity attributeNamed:@"companyId"],
                      [entity attributeNamed:@"subCompanyId"],
                      nil];

      //      q    = [self verifyQualifier:q];
      isOk = [adChannel selectAttributes:attrs
                        describedByQualifier:q
                        fetchOrder:nil
                        lock:NO];
      [self assert:isOk reason:[sybaseMessages description]];
  
      while ((row = [adChannel fetchAttributes:attrs withZone:NULL])) {
        NSNumber       *sourceId,  *targetId;
        EOKeyGlobalID  *sourceGid, *targetGid;
        NSMutableArray *subGids;
    
        sourceId = [row objectForKey:@"companyId"];
        targetId = [row objectForKey:@"subCompanyId"];
    
        sourceGid = [EOKeyGlobalIDClass globalIDWithEntityName:[self entityName]
                                        keys:&sourceId keyCount:1 zone:NULL];
        targetGid = [EOKeyGlobalIDClass globalIDWithEntityName:
                                        [self memberEntityName]
                                        keys:&targetId keyCount:1 zone:NULL];
    
        if ((subGids = [gids objectForKey:sourceGid]) == nil) {
          subGids = [[NSMutableArray alloc] init];
          [gids setObject:subGids forKey:sourceGid];
          [subGids release];
        }
        [subGids addObject:targetGid];
      }
    }
  }
  result = [gids copy];
  [gids release];
  return [result autorelease];
}

- (NSArray *)_fetchForMoreObjectsInContext:(id)_context {
  NSMutableArray    *myAssignments  = nil;
  NSMutableArray    *myMembers      = nil;
  EODatabaseChannel *channel        = nil;
  EOAdaptorChannel  *adChannel;
  NSArray           *checkedMembers = nil;
  BOOL              isOk            = NO;
  id                obj             = nil;
  EOSQLQualifier    *q;
  NSArray           *attrs;

  if ([self fetchGlobalIDs])
    return [self _fetchForMoreGidsInContext:_context];
  
  myAssignments  = [NSMutableArray arrayWithCapacity:64];
  myMembers      = [NSMutableArray arrayWithCapacity:64];
  channel        = [self databaseChannel];
  adChannel      = [channel adaptorChannel];

  /* fetch company assignments */
  {
    NSEnumerator *e;
    NSString *in;

    e = [[self _groupIdString] objectEnumerator];
    while ((in = [e nextObject])) {
      q = [self _qualifierForCompanyAssignment:in];

      //      q = [self verifyQualifier:q];
      attrs = [[q entity] attributes];
      isOk = [adChannel selectAttributes:attrs
                        describedByQualifier:q
                        fetchOrder:nil
                        lock:NO];
      [self assert:isOk reason:[sybaseMessages description]];

      while ((obj = [adChannel fetchAttributes:attrs withZone:NULL]))
        [myAssignments addObject:obj];
    }
  }
  
  /* more-groups fetch */
  {
    EOEntity       *memberEntity;
    EOSQLQualifier *qualifier    = nil;
    NSString       *in;
    NSEnumerator   *e;
  
    memberEntity = [[self databaseModel] entityNamed:[self memberEntityName]];

    e = [[self _groupIdString] objectEnumerator];
    while ((in = [e nextObject]) != nil) {
      qualifier = [EOSQLQualifier alloc];
      if ([in isNotEmpty]) {
        qualifier = [qualifier initWithEntity:memberEntity
                               qualifierFormat:@"%A IN (%@)",
                               @"toCompanyAssignment1.companyId", in];
      }
      else {
        qualifier = [qualifier initWithEntity:memberEntity
                               qualifierFormat:@"1=2"];
      }
      
      [qualifier setUsesDistinct:YES];
      
      q = [qualifier autorelease];
      q = [self verifyQualifier:q];
      isOk = [channel selectObjectsDescribedByQualifier:q
                      fetchOrder:nil];
      
      [self assert:isOk reason:[sybaseMessages description]];
  
      while ((obj = [channel fetchWithZone:NULL])) {
        [myMembers addObject:obj];
      }
    }
  }
  
  [self _setAssignments:myAssignments andMembers:myMembers];

  {
      NSArray      *gids;
      id           *objs, obj;
      NSEnumerator *enumerator;
      int          cnt;

      cnt  = 0;
      gids = [myMembers map:@selector(valueForKey:) with:@"globalID"];
      gids = [[_context accessManager] objects:gids forOperation:@"r"];
      objs = calloc(sizeof(id), [gids count]);

      enumerator = [myMembers objectEnumerator];

      while ((obj = [enumerator nextObject])) {
        if ([gids containsObject:[obj valueForKey:@"globalID"]])
          objs[cnt++] = obj;
      }
      checkedMembers = [NSMutableArray arrayWithObjects:objs count:cnt];
      free(objs); objs = NULL;
  }
  return checkedMembers;
}

- (void)_executeInContext:(id)_context {
  _LSGetMembersForCompany_Cache *cache;
  NSString                      *cacheKey;
  NSAutoreleasePool             *pool;
  
  pool = [[NSAutoreleasePool alloc] init];
  
  cacheKey = [self fetchGlobalIDs]
    ? @"_cache_CompanyMember_gids"
    : @"_cache_CompanyMembers";
  
  if ((cache = [_context valueForKey:cacheKey]) != nil) {
    if ([cache->groups isEqualToArray:self->groups]) {
      if (debugCache)
        [self logWithFormat:@"%s: reused cached result.", __PRETTY_FUNCTION__];
      [self setReturnValue:cache->result];
      [pool release];
      return;
    }
  }
  else {
    cache = [[[_LSGetMembersForCompany_Cache alloc] init] autorelease];
  }
  
  // TODO: fix to always return an array (if an array parameters was given)
  [self setReturnValue:([self->groups count] == 1)
          ? [self _fetchForOneObjectInContext:_context]
          : [self _fetchForMoreObjectsInContext:_context]];
  
  ASSIGN(cache->groups, self->groups);
  {
    id rv;
    
    rv = [self returnValue];
    ASSIGN(cache->result, rv);
  }
  [_context takeValue:cache forKey:cacheKey];

  [pool release];
}

/* record initializer */

- (NSString *)entityName {
  return @"Company";
}

- (NSString *)memberEntityName {
  return @"Company";
}

/* accessors */

- (void)setGroup:(id)_group {
  if (![_group isNotNull]) {
    [self warnWithFormat:@"called without a group parameter!"];
    if (coreOnNullGroup) {
      [self logWithFormat:@"  => dumping core because core-on-null-group ..."];
      abort();
    }
  }
  
  _group = _group ? [NSArray arrayWithObject:_group] : nil;
  ASSIGN(self->groups, _group);
}
- (id)group {
  unsigned count;
  id group;

  count = [self->groups count];
  
  if (count == 0)
    group = nil;
  else if (count == 1) {
    group = [self->groups objectAtIndex:0];
  }
  else {
    [self warnWithFormat:@"%s: used -group method, with %d groups set",
            __PRETTY_FUNCTION__, count];
    group = [self->groups objectAtIndex:0];
  }

#if DEBUG
  if (![group isNotNull]) {
    [self warnWithFormat:@"null group ! (groups=%@)", self->groups];
    if (coreOnNullGroup) {
      [self logWithFormat:@"  => dumping core because core-on-null-group ..."];
      abort();
    }
  }
#endif
  
  return group;
}

- (void)setGroups:(NSArray *)_groups {
  ASSIGN(self->groups, _groups);
}
- (NSArray *)groups {
  return self->groups;
}

- (void)setFetchGlobalIDs:(BOOL)_flag {
  self->fetchGlobalIDs = _flag;
}
- (BOOL)fetchGlobalIDs {
  return self->fetchGlobalIDs;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
#if DEBUG && 0
  NSAssert1([_value isNotNull], @"take value 'null' for key %@", _key);
#endif
  
  if ([_key isEqualToString:@"group"] || [_key isEqualToString:@"object"]) {
    [self setGroup:_value];
    return;
  }
  else if ([_key isEqualToString:@"groups"]) {
    [self setGroups:_value];
    return;
  }
  else if ([_key isEqualToString:@"fetchGlobalIDs"]) {
    [self setFetchGlobalIDs:[_value boolValue]];
    return;
  }
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"group"] || [_key isEqualToString:@"object"])
    return [self group];
  if ([_key isEqualToString:@"groups"])
    return [self groups];
  if ([_key isEqualToString:@"fetchGlobalIDs"])
    return [NSNumber numberWithBool:[self fetchGlobalIDs]];
  
  return [super valueForKey:_key];
}

@end /* LSGetMemberForCompanyCommand */


@implementation _LSGetMembersForCompany_Cache

- (void)dealloc {
  [self->result release];
  [self->groups release];
  [super dealloc];
}

@end /* _LSGetMembersForCompany_Cache */
