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

@interface LSGetAssignedProjectIdsForPersonCommand : LSDBObjectBaseCommand
@end

#include "common.h"
#include <GDLAccess/EOSQLQualifier.h>

@implementation LSGetAssignedProjectIdsForPersonCommand

- (NSString *)_sqlExprForAssignedProjectIds {
  NSString *expr;
  EOModel  *model;
  EOEntity *personEntity;
  EOEntity *assignEntity;
  NSString *personTab;
  NSString *assignTab;
  NSString *companyId;
  NSString *assignCompanyId;
  NSString *projectId;
  
  model = [self databaseModel];
  
  // TODO: do we really need to use the model here? (is it different between
  //       DBs?)
  
  personEntity = [model entityNamed:@"Person"];
  assignEntity = [model entityNamed:@"ProjectCompanyAssignment"];
  
  assignTab = [assignEntity externalName];
  personTab = [personEntity externalName];
  projectId = [[assignEntity attributeNamed:@"projectId"] columnName];
  companyId = [[personEntity attributeNamed:@"companyId"] columnName];
  
  assignCompanyId = [NSString stringWithFormat:@"%@.%@", assignTab, companyId];
  companyId       = [NSString stringWithFormat:@"%@.%@", personTab, companyId];
  
  expr = [NSString stringWithFormat:@"SELECT %@ FROM %@,%@ WHERE %@=%@",
                     projectId, assignTab, personTab, companyId, 
                     assignCompanyId];
  return expr;
}

- (NSString *)_sqlExprForAllProjectIds {
  /* fetch all project ids except the fake ones */
  NSString *expr;
  EOEntity *projectEntity;
  NSString *projectTab;
  NSString *projectId;
  NSString *isFake;
  
  projectEntity = [[self databaseModel] entityNamed:@"Project"];

  projectTab = [projectEntity externalName];
  projectId  = [[projectEntity attributeNamed:@"projectId"] columnName];
  isFake     = [[projectEntity attributeNamed:@"isFake"]    columnName];
  
  expr = [NSString stringWithFormat:@"SELECT %@ FROM %@ WHERE %@=0",
                   projectId, projectTab, isFake];
  return expr;
}

- (NSArray *)_fetchAssignedProjectIds {
  EOAdaptorChannel *adChannel;
  NSMutableArray   *result;
  NSString         *expr;
  NSArray          *attrs;
  NSDictionary     *r = nil;

  adChannel = [[self databaseChannel] adaptorChannel];
  result    = [NSMutableArray arrayWithCapacity:16];
  expr      = [self _sqlExprForAssignedProjectIds];

  if (![adChannel evaluateExpression:expr])
    return nil;
  
  if (![adChannel isFetchInProgress])
    return nil;
  
  attrs = [adChannel describeResults];
  while ((r = [adChannel fetchAttributes:attrs withZone:[self zone]]))
    [result addObject:[r valueForKey:@"projectId"]];
  
  [adChannel cancelFetch];
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

- (BOOL)isRootAccountID:(NSNumber *)_login {
  if (![_login isNotNull])
    return NO;
  
  if ([_login intValue] == 10000)
    return YES;
  
  return NO;
}

- (void)_executeInContext:(id)_context {
  NSMutableSet *projectIds;
  id           account;
  NSNumber     *login;
  
  projectIds = [NSMutableSet setWithCapacity:20];
  account    = [_context valueForKey:LSAccountKey];
  login      = [account valueForKey:@"companyId"];
  
  // TODO: explain this conditional
  if ([self isRootAccountID:login] &&
      [self isRootAccountID:[[self object] valueForKey:@"companyId"]]) {
    [projectIds addObjectsFromArray:[self _fetchAllProjectIds]];
  }
  else
    [projectIds addObjectsFromArray:[self _fetchAssignedProjectIds]];
  
  [self setReturnValue:[projectIds allObjects]];
}

/* record initializer */

- (NSString *)entityName {
  return @"Person";
}

/* key/value coding */

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

@end /* LSGetAssignedProjectIdsForPersonCommand */
