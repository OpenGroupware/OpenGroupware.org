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

@interface LSFetchPersonRelationCommand : LSDBObjectBaseCommand
@end

// TODO: this looks very similiar to the LSFetchEnterpriseRelationCommand
//       can't we share code?

#include "common.h"
#include <LSFoundation/SkyAccessManager.h>

@implementation LSFetchPersonRelationCommand

// command methods

- (EOSQLQualifier *)_qualifierForPerson {
  EOEntity    *personEntity = nil;
  EOSQLQualifier *qualifier    = nil;
  id          obj, key;

  [self assert:((obj = [self object]) != nil) reason:@"missing object"];
  [self assert:((key = [obj valueForKey:@"projectId"]) != nil)
        format:@"missing key 'projectId' in object %@", obj];
  
  personEntity = [[self databaseModel] entityNamed:@"Person"];
  qualifier = [[EOSQLQualifier alloc] initWithEntity:personEntity
                                   qualifierFormat:
                                     @"(%A = %@) AND (%A = %@)",
                                     @"toProjectCompanyAssignment.projectId",
                                     key,
                                     @"toProjectCompanyAssignment.hasAccess",
                                     [NSNumber numberWithBool:NO]];
  [qualifier setUsesDistinct:YES];
  
  return [qualifier autorelease];  
}

- (void)_executeInContext:(id)_context {
  NSMutableArray  *persons = nil;
  BOOL            isOk     = NO;
  id              obj      = nil; 
  
  persons = [[NSMutableArray alloc] init];
  
  isOk = [[self databaseChannel] selectObjectsDescribedByQualifier:
                                   [self _qualifierForPerson]
                                 fetchOrder:nil];

  [LSDBObjectCommandException raiseOnFail:isOk object:self
                              reason:[sybaseMessages description]];
  
  while ((obj = [[self databaseChannel] fetchWithZone:NULL])) {
    [persons addObject:obj];
    obj = nil;
  }

  {
    // check permission
    NSArray *permittedObjs =
      LSRunCommandV(_context,
                    @"person", @"check-permission",
                    @"object", persons, nil);
    { // if current account has access to project but not to persons
      SkyAccessManager *am      = [_context accessManager];
      NSEnumerator     *e       = [permittedObjs objectEnumerator];
      id               one      = nil;
      NSMutableArray   *allowed = [NSMutableArray array];
        
      while ((one = [e nextObject])) {
        if ([am operation:@"r"
                allowedOnObjectID:[one valueForKey:@"globalID"]]) {
          [allowed addObject:one];
        }
        else {
          [one takeValue:@"*" forKey:@"name"];
          [one takeValue:@"*" forKey:@"firstname"];
          [one takeValue:@"*" forKey:@"login"];
          [one takeValue:@"*" forKey:@"description"];
        }
      }
      LSRunCommandV(_context, @"person", @"get-extattrs",
                    @"objects", allowed,
                    @"relationKey", @"companyValue", nil);

      LSRunCommandV(_context, @"person", @"get-telephones",
                    @"objects", allowed,
                    @"relationKey", @"telephones", nil);
    }
    
    [[self object] takeValue:permittedObjs forKey:@"persons"];
  }
  [persons release]; persons = nil;
}

/* record initializer */

- (NSString *)entityName {
  return @"Project";
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"project"] || [_key isEqualToString:@"object"]) {
    if (_value == nil)
      [self warnWithFormat:@"set 'object' key to nil !"];
    
    [self setObject:_value];
    return;
  }
  
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"project"] || [_key isEqualToString:@"object"])
    return [self object];

  return [super valueForKey:_key];
}

@end /* LSFetchPersonRelationCommand */
