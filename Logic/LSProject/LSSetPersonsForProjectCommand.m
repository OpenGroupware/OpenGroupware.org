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

@interface LSSetPersonsForProjectCommand : LSDBObjectBaseCommand
@end

#import "common.h"

@implementation LSSetPersonsForProjectCommand

// command methods

- (EOSQLQualifier *)_qualifierForPerson {
  EOEntity       *personEntity;
  EOSQLQualifier *qualifier;

  personEntity = [[self databaseModel] entityNamed:@"Person"];
  
  qualifier = [[EOSQLQualifier alloc] initWithEntity:personEntity
                                   qualifierFormat:
                                   @"%A = %@",
                                   @"toProjectCompanyAssignment.projectId",
                                   [[self object] valueForKey:@"projectId"]];
  [qualifier setUsesDistinct:YES];

  return AUTORELEASE(qualifier);  
}

- (void)_executeInContext:(id)_context {
  EODatabaseChannel *dbch;
  NSMutableArray *persons;
  BOOL isOk;
  id   obj;
  
  dbch = [self databaseChannel];
  isOk = [dbch selectObjectsDescribedByQualifier:[self _qualifierForPerson]
	       fetchOrder:nil];

  [LSDBObjectCommandException raiseOnFail:isOk object:self
                              reason:[sybaseMessages description]];
  
  persons = [[NSMutableArray alloc] init];
  while ((obj = [dbch fetchWithZone:NULL])) {
    [persons addObject:obj];
    obj = nil;
  }
  
  // TODO: we might want to return the relation as a result?!
  //       find out whether the current return value (the object) is actually
  //       used somewhere in user-level code
  [[self object] takeValue:persons forKey:@"persons"];
  [persons release]; persons = nil;
}

// record initializer

- (NSString *)entityName {
  return @"Project";
}

// key/value coding

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"project"])
    [self setObject:_value];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"project"])
    return [self object];
  else
    return [super valueForKey:_key];
}

@end
