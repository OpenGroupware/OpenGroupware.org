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

#include <LSFoundation/LSDBObjectBaseCommand.h>

@interface LSGetAccountByLoginCommand : LSDBObjectBaseCommand

- (void)setLogin:(NSString *)_username;
- (NSString *)login;

@end

#import "common.h"
#import <GDLAccess/EOSQLQualifier.h>

@implementation LSGetAccountByLoginCommand

// command methods

- (void)_executeInContext:(id)_context {
  NSString       *userName    = [self->recordDict valueForKey:@"login"];
  EOSQLQualifier *myQualifier = nil;
  NSMutableArray *result      = [[NSMutableArray allocWithZone:[self zone]] init];
  
  EOSQLQualifier *isArchivedQualifier = nil;

  isArchivedQualifier =  [[EOSQLQualifier alloc] initWithEntity:[self entity]
                                     qualifierFormat:@"dbStatus <> 'archived'"];
  
  myQualifier = [[EOSQLQualifier alloc] initWithEntity:[self entity]
                                     qualifierFormat:
                                     @"login = '%@' AND isAccount=1",
                                     userName];
  [myQualifier conjoinWithQualifier:isArchivedQualifier];
  {
    EODatabaseChannel *dbChannel = [self databaseChannel];
    id  obj = nil;

    [dbChannel selectObjectsDescribedByQualifier:myQualifier fetchOrder:nil];

    while ((obj = [dbChannel fetchWithZone:NULL])) {
      [result addObject:obj];
      obj = nil;
    }
  }
  RELEASE(myQualifier);         myQualifier       = nil;
  RELEASE(isArchivedQualifier); isArchivedQualifier = nil;
  [self assert:([result count] < 2)
        reason:@"ERROR: more than one user for login !!!"];
  
  if ([result count] == 1)
    [self setReturnValue:[result objectAtIndex:0]];
  else {
    [self setReturnValue:nil];
    return;
  }
  
  RELEASE(result); result = nil;
        
  // set teams for result accounts(s) in key 'teams'

  LSRunCommandV(_context, @"account", @"teams",
                @"object", [self object],
                @"returnType", intObj(LSDBReturnType_ManyObjects), nil);

  //set extended attributes for result account

  LSRunCommandV(_context, @"person", @"get-extattrs",
                @"object", [self object],
                @"relationKey", @"companyValue", nil);

  //get telephones
  LSRunCommandV(_context, @"person", @"get-telephones",
                @"object", [self object],
                @"relationKey", @"telephones", nil);
}

// accessors

- (void)setLogin:(NSString *)_login {
  [self->recordDict setObject:_login forKey:@"login"];
}
- (NSString *)login {
  return [self->recordDict objectForKey:@"login"];
}

// record initializer

- (NSString *)entityName {
  return @"Person";
}

// key/value coding

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"login"]) {
    [self setLogin:_value];
    return;
  }
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"login"])
    return [self login];
  return [super valueForKey:_key];
}

@end
