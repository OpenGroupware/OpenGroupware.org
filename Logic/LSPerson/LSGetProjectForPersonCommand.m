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

@class NSArray, NSMutableString;

@interface LSGetProjectForPersonCommand : LSDBObjectBaseCommand
{
  BOOL            onlyAssigned;
  BOOL            withArchived;
  NSArray         *withoutKinds;
  NSMutableString *kindClause;
  NSMutableString *archivedClause;
}
@end

@interface LSGetProjectGlobalIDsForPersonCommand : LSGetProjectForPersonCommand
@end

#include "common.h"
#include <GDLAccess/EOSQLQualifier.h>

@implementation LSGetProjectForPersonCommand

- (id)initForOperation:(NSString *)_operation inDomain:(NSString *)_domain
  initDictionary:(NSDictionary *)_init 
{
  if ((self = [super initForOperation:_operation inDomain:_domain
                     initDictionary:_init])) {
    self->onlyAssigned = [[_init objectForKey:@"onlyAssigned"] boolValue];
  }
  return self;
}

- (void)dealloc {
  [self->withoutKinds   release];
  [self->kindClause     release];
  [self->archivedClause release];
  [super dealloc];
}

/* command methods */

- (NSString *)_teamIdStringForTeams:(NSArray *)_teams {
  NSMutableSet    *idSet;
  NSEnumerator    *listEnum;
  id              item      = nil;
  
  idSet    = [NSMutableSet setWithCapacity:[_teams count]];
  listEnum = [_teams objectEnumerator];
  
  while ((item = [listEnum nextObject])) {
    NSNumber *pKey;
    
    pKey = [item valueForKey:@"companyId"];
    if ([pKey isNotNull]) [idSet addObject:pKey];
  }
  
  return [[idSet allObjects] componentsJoinedByString:@","];
}

- (EOSQLQualifier *)_qualifierForTeams:(NSArray *)_teams {
  EOEntity       *projectEntity = nil;
  EOSQLQualifier *qualifier     = nil;
  NSString       *in            = nil;

  projectEntity = [[self databaseModel] entityNamed:@"Project"];
  in            = [self _teamIdStringForTeams:_teams];

  if ([in length] > 0) {
    qualifier = [[EOSQLQualifier alloc] initWithEntity:projectEntity
                                        qualifierFormat:
                                        @"(%A IN (%@) OR (%A IS NULL AND %A=%@))"
                                        @" AND (%A=0) %@ %@",
                                        @"teamId", in,
                                        @"teamId",
                                        @"ownerId",
                                        [[self object] valueForKey:@"companyId"],
                                        @"isFake",
                                        self->kindClause,
                                        self->archivedClause];
  }
  else {
    qualifier = [[EOSQLQualifier alloc] initWithEntity:projectEntity
                                        qualifierFormat:
                                        @"%A IS NULL AND %A=%@ AND %A=0 %@ %@",
                                        @"teamId",
                                        @"ownerId",
                                        [[self object] valueForKey:@"companyId"],
                                        @"isFake",
                                        self->kindClause,
                                        self->archivedClause];
  }
  [qualifier setUsesDistinct:YES];

  return AUTORELEASE(qualifier);  
}

- (NSArray *)_fetchProjectsForTeams:(NSArray *)_teams {
  NSMutableArray    *myProjects = nil;
  EODatabaseChannel *channel    = nil;
  BOOL              isOk        = NO;
  id                obj         = nil; 

  myProjects    = [NSMutableArray arrayWithCapacity:128];
  channel       = [self databaseChannel];

  isOk = [channel selectObjectsDescribedByQualifier:
                    [self _qualifierForTeams:_teams]
                  fetchOrder:nil];
  
  [self assert:isOk reason:[sybaseMessages description]];
  
  while ((obj = [channel fetchWithZone:NULL])) {
    [myProjects addObject:obj];
    obj = nil;
  }
  return AUTORELEASE([myProjects copy]);
}

- (EOSQLQualifier *)_qualifierForAssignedProjectsInContext:(id)_context {
  EOEntity        *projectEntity = nil;
  EOSQLQualifier  *qualifier     = nil;
  NSMutableString *inFormat;
  NSArray         *teams;
  NSEnumerator    *enumerator;
  id              obj, o;

  obj = [self object];

  if (!(teams = [obj valueForKey:@"groups"])) {
    LSRunCommandV(_context,
                  @"account", @"teams",
                  @"account", obj,
                  @"returnType",
                  intObj(LSDBReturnType_ManyObjects), nil);
    teams = [obj valueForKey:@"groups"];
  }
  teams      = [teams map:@selector(valueForKey:) with:@"companyId"];
  inFormat   = nil;
  enumerator = [teams objectEnumerator];

  while ((o = [enumerator nextObject])) {
    if (inFormat) {
      [inFormat appendString:@", "];
    }
    else {
      inFormat = [NSMutableString stringWithCapacity:64];
    }
    [inFormat appendString:[o stringValue]];
  }

  projectEntity = [[self databaseModel] entityNamed:@"Project"];

  if (inFormat == nil) {
    qualifier = [[EOSQLQualifier alloc] initWithEntity:projectEntity
                                        qualifierFormat:
                                        @"%A = %@ %@ %@",
                                        @"toProjectCompanyAssignment.companyId",
                                        [[self object] valueForKey:@"companyId"],
                                        self->kindClause,
                                        self->archivedClause];
  }
  else {
    qualifier = [[EOSQLQualifier alloc] initWithEntity:projectEntity
                                        qualifierFormat:
                                        @"(%A = %@ OR %A IN (%@)) %@ %@",
                                        @"toProjectCompanyAssignment.companyId",
                                        [[self object] valueForKey:@"companyId"],
                                        @"toProjectCompanyAssignment.companyId",
                                        inFormat,
                                        self->kindClause,
                                        self->archivedClause];
  }
  [qualifier setUsesDistinct:YES];
  
  return AUTORELEASE(qualifier);  
}

- (NSArray *)_fetchAssignedProjectsInContext:(id)_context {
  NSMutableArray    *myProjects = nil;
  EODatabaseChannel *channel    = nil;
  BOOL              isOk        = NO;
  id                obj         = nil; 

  myProjects    = [NSMutableArray arrayWithCapacity:128];
  channel       = [self databaseChannel];

  isOk = [channel selectObjectsDescribedByQualifier:
                  [self _qualifierForAssignedProjectsInContext:_context]
                  fetchOrder:nil];

  [self assert:isOk reason:[sybaseMessages description]];
  
  while ((obj = [channel fetchWithZone:NULL])) {
    [myProjects addObject:obj];
    obj = nil;
  }
  return AUTORELEASE([myProjects copy]);
}

- (NSArray *)_fetchAllProjects {
  NSMutableArray    *myProjects    = nil;
  EOEntity          *projectEntity = nil;
  EOSQLQualifier    *qualifier     = nil;
  EODatabaseChannel *channel       = nil;
  id                obj            = nil; 
  BOOL              isOk           = NO;
  
  myProjects    = [NSMutableArray arrayWithCapacity:128];
  projectEntity = [[self databaseModel] entityNamed:@"Project"];
  channel       = [self databaseChannel];
   
  qualifier = [[EOSQLQualifier alloc] initWithEntity:projectEntity
                                      qualifierFormat:@"%A=0 %@",
                                      @"isFake",
                                      self->kindClause];
  [qualifier setUsesDistinct:YES];

  isOk = [channel selectObjectsDescribedByQualifier:qualifier fetchOrder:nil];

  [self assert:isOk reason:[sybaseMessages description]];
  
  while ((obj = [channel fetchWithZone:NULL])) {
    [myProjects addObject:obj];
    obj = nil;
  }
  RELEASE(qualifier); qualifier = nil;
  
  return AUTORELEASE([myProjects copy]);
}

- (void)_executeInContext:(id)_context {
  NSMutableSet *projects = nil;
  NSString     *login    = nil;
  id           obj       = nil;
  id           account   = nil;
  BOOL         isRoot    = NO;

  NSAutoreleasePool *pool;

  pool = [[NSAutoreleasePool alloc] init];

  obj      = [self object];
  account  = [_context valueForKey:LSAccountKey];
  login    = [account valueForKey:@"companyId"];

  projects             = [[NSMutableSet alloc] init];
  self->kindClause     = [[NSMutableString alloc] initWithCapacity:16];
  self->archivedClause = [[NSMutableString alloc] initWithCapacity:16];

  isRoot = (([login intValue] == 10000) &&
            ([[obj valueForKey:@"companyId"] intValue] == 10000)) ? YES : NO;
  
  if (!self->withArchived) {
    [self->archivedClause setString:@" AND dbStatus <> 'archived'"];
  }
  
  if (self->withoutKinds != nil) {
    int i, cnt;

    [self->kindClause setString:@" AND ((kind IS NULL) OR ("];

    for (i = 0, cnt = [self->withoutKinds count]; i < cnt; i++) {
      NSString *k = [self->withoutKinds objectAtIndex:i];

      if (i > 0)
        [self->kindClause appendString:@" AND "];
        
      [self->kindClause appendFormat:@"kind <> '%@'", k];
    }
    [self->kindClause appendString:@"))"];
  }

  if (isRoot && !self->onlyAssigned) {
    [projects addObjectsFromArray:[self _fetchAllProjects]];
  }
  else {
    if ([[obj valueForKey:@"isAccount"] boolValue] && !self->onlyAssigned) { 
      NSArray *myTeams = [obj valueForKey:@"groups"];

      if (myTeams == nil) {
        LSRunCommandV(_context,
                      @"account", @"teams",
                      @"account", obj,
                      @"returnType",
                      intObj(LSDBReturnType_ManyObjects), nil);
      }
      myTeams = [obj valueForKey:@"groups"];
      [projects addObjectsFromArray:[self _fetchProjectsForTeams:myTeams]];
    }
    [projects addObjectsFromArray:[self _fetchAssignedProjectsInContext:_context]];
  }
  {
    NSMutableArray *pj;

    pj = [[NSMutableArray alloc] init];
    
    [pj addObjectsFromArray:[projects allObjects]];
    
    LSRunCommandV(_context, @"project", @"get-owner",
                  @"objects",     pj,
                  @"relationKey", @"owner", nil);
    LSRunCommandV(_context, @"project", @"get-team",
                  @"objects",     pj,
                  @"relationKey", @"team", nil);
    LSRunCommandV(_context, @"project", @"get-company-assignments",
                  @"objects",     pj,
                  @"relationKey", @"companyAssignments", nil);

    if (!isRoot) {
      id tmp;
      
      tmp = LSRunCommandV(_context,
                         @"project", @"check-get-permission",
                         @"object",  pj, nil);
      if (tmp != pj) {
        RETAIN(tmp);
        RELEASE(pj);
        pj = tmp;
      }
    }
    LSRunCommandV(_context, @"project", @"get-status", @"projects", pj, nil);
    
    {
      id tmp;
      tmp = [pj copy];
      [obj takeValue:tmp forKey:@"projects"];
      [self setReturnValue:tmp];
      RELEASE(tmp); tmp = nil;
    }
    RELEASE(pj); pj = nil;
  }
  RELEASE(projects); projects = nil;
  
  RELEASE(pool); pool = nil;
}

// accessors

- (void)setWithoutKinds:(NSArray *)_kinds {
  ASSIGN(self->withoutKinds, _kinds);
}
- (NSArray *)withoutKinds {
  return self->withoutKinds;
}

- (void)setWithArchived:(BOOL)_flag {
  self->withArchived = _flag;
}
- (BOOL)withArchived {
  return self->withArchived;
}

- (BOOL)onlyAssigned {
  return self->onlyAssigned; 
}

/* record initializer */

- (NSString *)entityName {
  return @"Person";
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"person"]) {
    [self setObject:_value];
    return;
  }
  if ([_key isEqualToString:@"withoutKinds"]) {
    [self setWithoutKinds:_value];
    return;
  }
  if ([_key isEqualToString:@"withArchived"]) {
    [self setWithArchived:[_value boolValue]];
    return;
  }
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"person"])
    return [self object];
  if ([_key isEqualToString:@"withoutKinds"])
    return [self withoutKinds];
  if ([_key isEqualToString:@"withArchived"])
    return [NSNumber numberWithBool:self->withArchived];

  return [super valueForKey:_key];
}

@end /* LSGetProjectForPersonCommand */


@implementation LSGetProjectGlobalIDsForPersonCommand

- (void)_executeInContext:(id)_context {
  NSMutableArray *gids;
  NSArray *projects;
  unsigned i, count;
  
  /* TO BE optimized, fetches all project objects !!! */
  
  [super _executeInContext:_context];

  if ((projects = [self returnValue]) == nil)
    return;
  if ((count = [projects count]) == 0)
    return;
  
  gids = [NSMutableArray arrayWithCapacity:(count + 1)];
  for (i = 0; i < count; i++) {
    EOGlobalID *gid;
    
    if ((gid = [[projects objectAtIndex:i] globalID]) != nil) {
      [gids addObject:gid];
    }
    else {
      [self logWithFormat:@"missing global-id in project %@",
              [projects objectAtIndex:i]];
    }
  }
  
  [self setReturnValue:[[gids copy] autorelease]];
}

@end /* LSGetProjectGlobalIDsForPersonCommand */
