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

#import <LSFoundation/LSDBObjectBaseCommand.h>

@interface LSGetProjectForEnterpriseCommand : LSDBObjectBaseCommand
@end

#import "common.h"
#import <GDLAccess/EOSQLQualifier.h>

@implementation LSGetProjectForEnterpriseCommand

// command methods

- (EOSQLQualifier *)_qualifierForProjects {
  EOEntity       *projectEntity = [[self databaseModel] entityNamed:@"Project"];
  EOSQLQualifier *qualifier     = nil;

  qualifier = [[EOSQLQualifier alloc] initWithEntity:projectEntity
                                      qualifierFormat:
                                      @"%A=%@ AND (isFake=0 OR isFake IS NULL)"
                                      @" AND dbStatus <> 'archived'",
                                      @"toProjectCompanyAssignment.companyId",
                                      [[self object] valueForKey:@"companyId"]];
  [qualifier setUsesDistinct:YES];
  return AUTORELEASE(qualifier);  
}

- (NSArray *)_fetchProjects {
  NSMutableArray    *myProjects = nil;
  EODatabaseChannel *channel    = nil;
  BOOL              isOk        = NO;
  id                obj         = nil; 

  channel    = [self databaseChannel];
  myProjects = [NSMutableArray arrayWithCapacity:8];

  isOk = [channel selectObjectsDescribedByQualifier:
                  [self _qualifierForProjects]
                  fetchOrder:nil];

  [self assert:isOk reason:[sybaseMessages description]];
  
  while ((obj = [channel fetchWithZone:NULL])) {
    [myProjects addObject:obj];
    obj = nil;
  }
  return myProjects;
}

- (void)_executeInContext:(id)_context {
  NSArray *pj = nil;
  id      obj = [self object];

  pj = [self _fetchProjects];

  LSRunCommandV(_context, @"project", @"get-owner",
                @"objects",     pj,
                @"relationKey", @"owner", nil);
  LSRunCommandV(_context, @"project", @"get-team",
                @"objects",     pj,
                @"relationKey", @"team", nil);
  LSRunCommandV(_context, @"project", @"get-company-assignments",
                @"objects",     pj,
                @"relationKey", @"companyAssignments", nil);
  pj = LSRunCommandV(_context,
                     @"project", @"check-get-permission",
                     @"object", pj, nil);
  LSRunCommandV(_context, @"project", @"get-status", @"projects", pj, nil);

  [obj takeValue:pj forKey:@"projects"];
  [self setReturnValue:pj];
}


// record initializer

- (NSString *)entityName {
  return @"Enterprise";
}

// key/value coding

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"enterprise"]) {
    [self setObject:_value];
    return;
  }
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"enterprise"])
    return [self object];
  return [super valueForKey:_key];
}

@end
