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

@interface LSFetchEnterpriseRelationCommand : LSDBObjectBaseCommand
@end

#include "common.h"
#include <LSFoundation/SkyAccessManager.h>

@implementation LSFetchEnterpriseRelationCommand

/* command methods */

- (EOSQLQualifier *)_qualifierForEnterprise {
  EOEntity       *enterpriseEntity;
  EOSQLQualifier *qualifier = nil;
  
  enterpriseEntity = [[self databaseModel] entityNamed:@"Enterprise"];
  
  qualifier = [[EOSQLQualifier alloc] initWithEntity:enterpriseEntity
                                   qualifierFormat:
                                   @"%A = %@",
                                   @"toProjectCompanyAssignment.projectId",
                                   [[self object] valueForKey:@"projectId"]];
  [qualifier setUsesDistinct:YES];
  
  return [qualifier autorelease];  
}

- (void)_executeInContext:(id)_context {
  NSMutableArray *enterprises;
  BOOL isOk;
  id   obj;
  
  isOk = [[self databaseChannel] selectObjectsDescribedByQualifier:
                                 [self _qualifierForEnterprise]
                                 fetchOrder:nil];

  [LSDBObjectCommandException raiseOnFail:isOk object:self
                              reason:[sybaseMessages description]];
  
  enterprises = [[NSMutableArray alloc] init];
  while ((obj = [[self databaseChannel] fetchWithZone:NULL])) {
    [enterprises addObject:obj];
    obj = nil;
  }

  {
    // check permission
    SkyAccessManager *am;
    NSEnumerator     *e;
    id               one;
    NSMutableArray   *allowed;
    NSArray *permittedObjs;

    permittedObjs = LSRunCommandV(_context,
				  @"enterprise", @"check-permission",
				  @"object", enterprises, nil);
    
      am      = [_context accessManager];
      e       = [permittedObjs objectEnumerator];
      allowed = [NSMutableArray array];
      
      while ((one = [e nextObject])) {
        if ([am operation:@"r"
                allowedOnObjectID:[one valueForKey:@"globalID"]]) {
          [allowed addObject:one];
        }
        else {
          [one takeValue:@"*" forKey:@"description"];
        }
      }
      LSRunCommandV(_context, @"enterprise", @"get-extattrs",
                    @"objects", allowed,
                    @"relationKey", @"companyValue", nil);
      
    [[self object] takeValue:permittedObjs forKey:@"enterprises"];
  }
  [enterprises release]; enterprises = nil;
}

/* record initializer */

- (NSString *)entityName {
  return @"Project";
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"project"]) {
    [self setObject:_value];
    return;
  }
  
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"project"])
    return [self object];

  return [super valueForKey:_key];
}

@end /* LSFetchEnterpriseRelationCommand */
