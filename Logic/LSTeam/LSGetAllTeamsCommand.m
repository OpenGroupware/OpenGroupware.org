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

#include <LSFoundation/LSDBObjectGetCommand.h>

@interface LSGetAllTeamsCommand : LSDBObjectBaseCommand
{
  BOOL fetchGlobalIDs;
}

@end

#import "common.h"

@implementation LSGetAllTeamsCommand

- (NSString *)entityName {
  return @"Team";
}

- (void)_fetchGIDsInContext:(id)_context {
  EODatabaseChannel *dbChannel;
  EOSQLQualifier    *sq;
  NSArray *result;
  EOSQLQualifier *isArchivedQualifier = nil;
  
  isArchivedQualifier = [[EOSQLQualifier alloc] initWithEntity:[self entity]
                                  qualifierFormat:@"dbStatus <> 'archived'"];

  sq = [[EOSQLQualifier alloc] initWithEntity:[self entity]
                               qualifierFormat:@"1=1"];
  [sq conjoinWithQualifier:isArchivedQualifier];
  dbChannel = [self databaseChannel];
  result = [dbChannel globalIDsForSQLQualifier:sq];
  [self setReturnValue:result];
  [sq release];
  [isArchivedQualifier release]; isArchivedQualifier = nil;
}

- (void)_fetchEOsInContext:(id)_context {
  id result;
  
  result = LSRunCommandV(_context, @"team", @"get",
                         @"returnType", intObj(LSDBReturnType_ManyObjects),
                         nil);
  [self setReturnValue:result];
}

- (void)_executeInContext:(id)_context {
  if (self->fetchGlobalIDs)
    [self _fetchGIDsInContext:_context];
  else
    [self _fetchEOsInContext:_context];
}

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"fetchGlobalIDs"])
    self->fetchGlobalIDs = [_value boolValue];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"fetchGlobalIDs"])
    return [NSNumber numberWithBool:self->fetchGlobalIDs];
  else
    return [super valueForKey:_key];
}

@end /* LSGetAllTeamsCommand */
