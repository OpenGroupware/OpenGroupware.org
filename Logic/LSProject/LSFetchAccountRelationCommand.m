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

@interface LSFetchAccountRelationCommand : LSDBObjectBaseCommand
@end

#include "common.h"
#include <LSFoundation/SkyAccessManager.h>

@implementation LSFetchAccountRelationCommand

// command methods

- (EOSQLQualifier *)_qualifierForPerson {
  EOEntity       *personEntity;
  EOSQLQualifier *qualifier;
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
                                     [NSNumber numberWithBool:YES]];
  [qualifier setUsesDistinct:YES];

  return [qualifier autorelease];  
}

- (void)_executeInContext:(id)_context {
  NSMutableArray  *persons;
  BOOL            isOk     = NO;
  id              obj      = nil; 

  persons = [[NSMutableArray alloc] initWithCapacity:4];
  
  isOk = [[self databaseChannel] selectObjectsDescribedByQualifier:
                                   [self _qualifierForPerson]
                                 fetchOrder:nil];

  [LSDBObjectCommandException raiseOnFail:isOk object:self
                              reason:[dbMessages description]];
  
  while ((obj = [[self databaseChannel] fetchWithZone:NULL]) != nil) {
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
      SkyAccessManager *am;
      NSEnumerator     *e;
      id               one;
      NSMutableArray   *allowed;
      
      am      = [_context accessManager];
      allowed = [NSMutableArray arrayWithCapacity:4];
      
      e = [permittedObjs objectEnumerator];
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
    
    [[self object] takeValue:permittedObjs forKey:@"accounts"];
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
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"project"] || [_key isEqualToString:@"object"])
    return [self object];

  return [super valueForKey:_key];
}

@end /* LSFetchAccountRelationCommand */
