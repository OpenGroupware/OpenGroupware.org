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

@interface LSGetAssignedProjectIdsForPersonCommand : LSDBObjectBaseCommand
@end

#import "common.h"
#import <GDLAccess/EOSQLQualifier.h>

@implementation LSGetAssignedProjectIdsForPersonCommand

// command methods

- (NSString *)_sqlExprForAssignedProjectIds {
  NSString        *expr            = nil;
  EOModel         *model           = nil;
  EOEntity        *personEntity    = nil;
  EOEntity        *assignEntity    = nil;
  NSString        *personTab       = nil;
  NSString        *assignTab       = nil;
  NSString        *companyId       = nil;
  NSString        *assignCompanyId = nil;
  NSString        *projectId       = nil;

  model = [self databaseModel];
  
  personEntity  = [model entityNamed:@"Person"];
  assignEntity  = [model entityNamed:@"ProjectCompanyAssignment"];

  assignTab  = [assignEntity externalName];
  personTab  = [personEntity externalName];
  projectId  = [[assignEntity attributeNamed:@"projectId"] columnName];
  companyId  = [[personEntity attributeNamed:@"companyId"] columnName];

  assignCompanyId = [NSString stringWithFormat:@"%@.%@", assignTab, companyId];
  companyId       = [NSString stringWithFormat:@"%@.%@", personTab, companyId];
  
  expr = [NSString stringWithFormat:@"SELECT %@ FROM %@,%@ WHERE %@=%@",
                   projectId, assignTab, personTab, companyId, assignCompanyId];
  return expr;
}

- (NSString *)_sqlExprForAllProjectIds {
  NSString *expr          = nil;
  EOEntity *projectEntity = nil;
  NSString *projectTab    = nil;
  NSString *projectId     = nil;
  NSString *isFake        = nil;

  projectEntity = [[self databaseModel] entityNamed:@"Project"];

  projectTab = [projectEntity externalName];
  projectId  = [[projectEntity attributeNamed:@"projectId"] columnName];
  isFake     = [[projectEntity attributeNamed:@"isFake"]    columnName];
  
  expr = [NSString stringWithFormat:@"SELECT %@ FROM %@ WHERE %@=0",
                   projectId, projectTab, isFake];
  return expr;
}

- (NSArray *)_fetchAssignedProjectIds {
  EOAdaptorChannel *adChannel = nil;
  NSMutableArray   *result    = nil;
  NSString         *expr      = nil;

  adChannel = [[self databaseChannel] adaptorChannel];
  result    = [NSMutableArray arrayWithCapacity:16];
  expr      = [self _sqlExprForAssignedProjectIds];

  if ([adChannel evaluateExpression:expr]) {
    NSDictionary *r = nil;

    if ([adChannel isFetchInProgress]) {
      while ((r = [adChannel fetchAttributes:[adChannel describeResults]
                             withZone:[self zone]])) {
        [result addObject:[r valueForKey:@"projectId"]];
      }
      [adChannel cancelFetch];
    }
  }
  return result;
}

- (NSArray *)_fetchAllProjectIds {
  EOAdaptorChannel *adChannel = nil;
  NSMutableArray   *result    = nil;
  NSString         *expr      = nil;

  adChannel = [[self databaseChannel] adaptorChannel];
  result    = [NSMutableArray arrayWithCapacity:16];
  expr      = [self _sqlExprForAllProjectIds];

  if ([adChannel evaluateExpression:expr]) {
    NSDictionary *r = nil;

    if ([adChannel isFetchInProgress]) {
      while ((r = [adChannel fetchAttributes:[adChannel describeResults]
                             withZone:[self zone]])) {
        [result addObject:[r valueForKey:@"projectId"]];
      }
      [adChannel cancelFetch];
    }
  }
  
  return result;
}

- (void)_executeInContext:(id)_context {
  NSMutableSet *projectIds = nil;
  id           account     = nil;
  NSString     *login      = nil;

  projectIds = [NSMutableSet setWithCapacity:20];
  account    = [_context valueForKey:LSAccountKey];
  login      = [account valueForKey:@"companyId"];

  if (([login intValue] == 10000) &&
      ([[[self object] valueForKey:@"companyId"] intValue] == 10000)) {
    [projectIds addObjectsFromArray:[self _fetchAllProjectIds]];
  }
  else {
    [projectIds addObjectsFromArray:[self _fetchAssignedProjectIds]];
  }
  [self setReturnValue:[projectIds allObjects]];
}

// record initializer

- (NSString *)entityName {
  return @"Person";
}

// key/value coding

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"person"]) {
    [self setObject:_value];
    return;
  }
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"person"])
    return [self object];
  return [super valueForKey:_key];
}

@end
