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

#include "LSFetchJobCommand.h"
#include "common.h"

@class NSCalendarDate;

/*
 * fetch all jobs, for an executant, which are not archived
 *
 */

@interface LSFetchJobsForExecutantCommand : LSFetchJobCommand
{
}
@end /* LSFetchJobsForExecutantCommand */

@implementation LSFetchJobsForExecutantCommand

/* accessors */

- (NSString *)destinationKey {
  return @"executantId";
}

- (NSString *)_idString {
  NSMutableSet *idSet;
  NSEnumerator *listEnum;
  id           item;

  idSet    = [NSMutableSet set];
  listEnum = [[self object] objectEnumerator];
  
  while ((item = [listEnum nextObject])) {
    id pKey = [item valueForKey:[self sourceKey]];
    
    [self assert:(pKey != nil) reason:@"found foreign key which is nil !"];

    if (pKey != nil) {
      [idSet addObject:pKey];
#if 0
      { // getGroups
        NSArray *gr = [[item valueForKey:@"groups"]
                             map:@selector(valueForKey:)
                             with:@"companyId"];
        [idSet addObjectsFromArray:gr];
      }
#endif
    }
  }
  return [[idSet allObjects] componentsJoinedByString:@","];
  
}

- (EOSQLQualifier *)_qualifier {
  EOSQLQualifier *qualifier = nil;
  NSString *s = [self _idString];

  qualifier = [[EOSQLQualifier allocWithZone:[self zone]]
                               initWithEntity:[self destinationEntity]
                               qualifierFormat:
                               @"((%A <> '%@') AND (%A IN (%@)))",
                               @"jobStatus", LSJobArchived,
                               @"executantId", s,
                               nil];
  return AUTORELEASE(qualifier);
}

@end /* LSFetchJobsForExecutantCommand */
