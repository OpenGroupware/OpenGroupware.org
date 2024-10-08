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

/*
  account::get-by-login

  TODO: document
*/

@interface LSGetAccountByLoginCommand : LSDBObjectBaseCommand

- (void)setLogin:(NSString *)_username;
- (NSString *)login;

@end

#include "common.h"
#include <GDLAccess/EOSQLQualifier.h>

@implementation LSGetAccountByLoginCommand

/* command methods */

- (void)_executeInContext:(id)_context {
  NSString       *userName;
  EOSQLQualifier *myQualifier = nil;
  NSMutableArray *result;
  EOSQLQualifier *isArchivedQualifier;
  EODatabaseChannel *dbChannel;
  id obj;
  
  result = [[NSMutableArray alloc] initWithCapacity:4];

  isArchivedQualifier =
    [[EOSQLQualifier alloc] initWithEntity:[self entity]
			    qualifierFormat:@"dbStatus <> 'archived'"];
  
  userName    = [self->recordDict valueForKey:@"login"];
  myQualifier = [[EOSQLQualifier alloc] initWithEntity:[self entity]
                                     qualifierFormat:
                                     @"login = '%@' AND isAccount=1",
                                     userName];
  [myQualifier conjoinWithQualifier:isArchivedQualifier];

  dbChannel = [self databaseChannel];
  [dbChannel selectObjectsDescribedByQualifier:myQualifier fetchOrder:nil];
  
  while ((obj = [dbChannel fetchWithZone:NULL]) != nil) {
    [result addObject:obj];
    obj = nil;
  }
  [myQualifier         release]; myQualifier       = nil;
  [isArchivedQualifier release]; isArchivedQualifier = nil;
  [self assert:([result count] < 2)
        reason:@"ERROR: more than one user for login!"];
  
  if ([result count] == 1)
    [self setReturnValue:[result objectAtIndex:0]];
  else {
    [self setReturnValue:nil];
    [result release]; result = nil;
    return;
  }
  
  [result release]; result = nil;
        
  /* set teams for result accounts(s) in key 'teams' */

  LSRunCommandV(_context, @"account", @"teams",
                @"object", [self object],
                @"returnType", intObj(LSDBReturnType_ManyObjects), nil);

  /* set extended attributes for result account */

  LSRunCommandV(_context, @"person", @"get-extattrs",
                @"object", [self object],
                @"relationKey", @"companyValue", nil);

  /* get telephones */
  LSRunCommandV(_context, @"person", @"get-telephones",
                @"object", [self object],
                @"relationKey", @"telephones", nil);
}

/* accessors */

- (void)setLogin:(NSString *)_login {
  [self->recordDict setObject:_login forKey:@"login"];
}
- (NSString *)login {
  return [self->recordDict objectForKey:@"login"];
}

/* record initializer */

- (NSString *)entityName {
  return @"Person";
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"login"]) {
    [self setLogin:_value];
    return;
  }
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"login"])
    return [self login];
  return [super valueForKey:_key];
}

@end /* LSGetAccountByLoginCommand */
