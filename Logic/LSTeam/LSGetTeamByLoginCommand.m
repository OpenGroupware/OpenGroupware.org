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


/* Search in description, not in login */

@interface LSGetTeamByLoginCommand : LSDBObjectBaseCommand

- (void)setLogin:(NSString *)_username;
- (NSString *)login;

@end

#include "common.h"
#include <GDLAccess/EOSQLQualifier.h>

@implementation LSGetTeamByLoginCommand

/* command methods */

- (void)_executeInContext:(id)_context {
  NSString       *l;
  EOSQLQualifier *myQualifier;
  EOSQLQualifier *isArchivedQualifier;  
  NSMutableArray *result;
  EODatabaseChannel *dbChannel;
  id  obj = nil;

  l      = [self->recordDict valueForKey:@"login"];
  result = [[NSMutableArray alloc] init];
  
  isArchivedQualifier =
    [[EOSQLQualifier alloc] initWithEntity:[self entity]
                            qualifierFormat:@"dbStatus <> 'archived'"];
  myQualifier =
    [[EOSQLQualifier alloc] initWithEntity:[self entity]
                            qualifierFormat:
                              @"description = '%@' AND isTeam=1",l];
  [myQualifier conjoinWithQualifier:isArchivedQualifier];
  
  /* perform fetch */
  dbChannel = [self databaseChannel];
  [dbChannel selectObjectsDescribedByQualifier:myQualifier fetchOrder:nil];
  while ((obj = [dbChannel fetchWithZone:NULL])) {
    [result addObject:obj];
    obj = nil;
  }
  
  [myQualifier         release];
  [isArchivedQualifier release];
  
  [self assert:([result count] < 2)
        reason:@"ERROR: more than one team for description!"];
  
  if ([result count] == 1)
    [self setReturnValue:[result objectAtIndex:0]];
  else
    [self setReturnValue:nil];

  [result release]; result = nil;
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
  return @"Team";
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"login"])
    [self setLogin:_value];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"login"])
    return [self login];
  return [super valueForKey:_key];
}

@end /* LSGetTeamByLoginCommand */
