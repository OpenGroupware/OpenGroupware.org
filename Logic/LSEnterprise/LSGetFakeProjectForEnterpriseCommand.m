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

@interface LSGetFakeProjectForEnterpriseCommand : LSDBObjectBaseCommand
@end

#include "common.h"

@implementation LSGetFakeProjectForEnterpriseCommand

/* command methods */

- (EOSQLQualifier *)_qualifierForProjects {
  EOEntity       *projectEntity;
  EOSQLQualifier *qualifier;

  projectEntity = [[self databaseModel] entityNamed:@"Project"];
  qualifier =
    [[EOSQLQualifier alloc] initWithEntity:projectEntity
                            qualifierFormat:
                                   @"(%A = %@) AND (isFake = 1)",
                                   @"toProjectCompanyAssignment.companyId",
                                   [[self object] valueForKey:@"companyId"]];
  [qualifier setUsesDistinct:YES];
  return [qualifier autorelease];  
}

- (NSArray *)_fetchProjects {
  NSMutableArray  *myProjects;
  BOOL            isOk;
  id              obj; 

  myProjects = [NSMutableArray arrayWithCapacity:8];
  isOk = [[self databaseChannel] selectObjectsDescribedByQualifier:
                                   [self _qualifierForProjects]
                                 fetchOrder:nil];
  
  [self assert:isOk reason:[dbMessages description]];
  
  while ((obj = [[self databaseChannel] fetchWithZone:NULL]) != nil)
    [myProjects addObject:obj];
  
  return myProjects;
}

- (void)_executeInContext:(id)_context {
  id projects, obj, pj;
  
  projects = [NSMutableSet setWithCapacity:20];
  obj      = [self object];
  
  [projects addObjectsFromArray:[self _fetchProjects]];

  projects = [projects allObjects];

  if ([projects count] == 0) {
    [self logWithFormat:@"WARNING: did not find fake project of enterprise!"];
    [self setReturnValue:nil];
    return;
  }
  else if ([projects count] > 1) {
    [self logWithFormat:
            @"WARNING: found more then one fake project for enterprise!"];
  }
  pj = [projects objectAtIndex:0];
  
  [obj takeValue:pj forKey:@"fakeProject"];
  [self setReturnValue:[projects objectAtIndex:0]];
  
  LSRunCommandV(_context, @"project", @"get-status", @"object", pj, nil);
}

/* record initializer */

- (NSString *)entityName {
  return @"Enterprise";
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"enterprise"]) {
    [self setObject:_value];
    return;
  }
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"enterprise"])
    return [self object];
  return [super valueForKey:_key];
}

@end /* LSGetFakeProjectForEnterpriseCommand */
