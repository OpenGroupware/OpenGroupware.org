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

@interface LSFetchAccountRelationCommand : LSDBObjectBaseCommand
@end

#import "common.h"
#include <LSFoundation/SkyAccessManager.h>

@implementation LSFetchAccountRelationCommand

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
                                     [NSNumber numberWithBool:YES]];
  [qualifier setUsesDistinct:YES];

  return AUTORELEASE(qualifier);  
}

- (void)_executeInContext:(id)_context {
  NSMutableArray  *persons = nil;
  BOOL            isOk     = NO;
  id              obj      = nil; 

  persons = [[NSMutableArray allocWithZone:[self zone]] init];
  
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

#if 0
    LSRunCommandV(_context, @"person", @"get-extattrs",
                  @"objects", permittedObjs,
                  @"relationKey", @"companyValue", nil);

    LSRunCommandV(_context, @"person", @"get-telephones",
                  @"objects", permittedObjs,
                  @"relationKey", @"telephones", nil);
#else
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
#endif

    [[self object] takeValue:permittedObjs forKey:@"accounts"];
  }
  RELEASE(persons); persons = nil;
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
