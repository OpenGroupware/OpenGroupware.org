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

/* TODO: hh asks: what the hell is that??? - see TODO file! */

#include <LSFoundation/LSGetObjectForGlobalIDs.h>

/*
  This command fetches team-objects based on a list of EOGlobalIDs.
*/

@interface LSGetTeamsForGlobalIDsCommand : LSGetObjectForGlobalIDs
{
@protected  
  BOOL     fetchArchivedTeams;
}
@end

#include "common.h"
#include <LSFoundation/LSCommandKeys.h>
#include <EOControl/EOControl.h>
#include <GDLAccess/GDLAccess.h>

@implementation LSGetTeamsForGlobalIDsCommand

- (id)initForOperation:(NSString *)_operation inDomain:(NSString *)_domain {
  if ((self = [super initForOperation:_operation inDomain:_domain])) {
    self->fetchArchivedTeams = NO;
  }
  return self;
}

- (NSString *)entityName {
  return @"Team";
}

/* execution */

- (EOSQLQualifier *)validateQualifier:(EOSQLQualifier *)_qual {
  EOSQLQualifier *isArchivedQualifier;
  
  if (self->fetchArchivedTeams == YES)
    return _qual;

  isArchivedQualifier = 
      [[EOSQLQualifier alloc] initWithEntity:[self entity]
                              qualifierFormat:@"dbStatus <> 'archived'"];
  [_qual conjoinWithQualifier:isArchivedQualifier];
  [isArchivedQualifier release]; isArchivedQualifier = nil;
  return _qual;
}

- (void)fetchAdditionalInfosForObjects:(NSArray *)_obj context:(id)_context {
}

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"fetchArchivedTeams"])
    self->fetchArchivedTeams = [_value boolValue];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  return [_key isEqualToString:@"fetchArchivedTeams"]
    ? [NSNumber numberWithBool:self->fetchArchivedTeams]
    : [super valueForKey:_key];
}

@end /* LSGetTeamsForGlobalIDsCommand */
