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

#import <LSFoundation/LSDBObjectBaseCommand.h>

@interface LSFetchTeamRelationCommand : LSDBObjectBaseCommand
@end

#import "common.h"

@implementation LSFetchTeamRelationCommand

// command methods

- (EOSQLQualifier *)_qualifierForTeams {
  EOEntity    *personEntity = nil;
  EOSQLQualifier *qualifier    = nil;
  id          obj, key;

  [self assert:((obj = [self object]) != nil) reason:@"missing object"];
  [self assert:((key = [obj valueForKey:@"projectId"]) != nil)
        format:@"missing key 'projectId' in object %@", obj];
  
  personEntity = [[self databaseModel] entityNamed:@"Team"];
  qualifier = [[EOSQLQualifier alloc] initWithEntity:personEntity
                                   qualifierFormat:
                                     @"(%A = %@) AND (%A = %@)",
                                     @"toProjectCompanyAssignment.projectId",
                                     key,
                                     @"toProjectCompanyAssignment.hasAccess",
                                     [NSNumber numberWithBool:YES]];
  [qualifier setUsesDistinct:YES];

  return AUTORELEASE(qualifier);  
}

- (void)_executeInContext:(id)_context {
  NSMutableArray  *teams = nil;
  BOOL            isOk   = NO;
  id              obj    = nil; 

  teams = [[NSMutableArray allocWithZone:[self zone]] init];
  
  isOk = [[self databaseChannel] selectObjectsDescribedByQualifier:
                                   [self _qualifierForTeams]
                                 fetchOrder:nil];

  [LSDBObjectCommandException raiseOnFail:isOk object:self
                              reason:[sybaseMessages description]];
  
  while ((obj = [[self databaseChannel] fetchWithZone:NULL])) {
    [teams addObject:obj];
    obj = nil;
  }

  // check permission
  [[self object] takeValue:teams forKey:@"teams"];

  RELEASE(teams); teams = nil;
}

// record initializer

- (NSString *)entityName {
  return @"Project";
}

// key/value coding

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"project"] || [_key isEqualToString:@"object"]) {
    if (_value == nil)
      [self logWithFormat:@"WARNING: set 'object' key to nil !"];

    [self setObject:_value];
    return;
  }
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"project"] || [_key isEqualToString:@"object"])
    return [self object];
  else
    return [super valueForKey:_key];
}

@end