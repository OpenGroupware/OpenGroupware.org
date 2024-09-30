/*
  Copyright (C) 2000-2008 Whitemice Consulting

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
#include "common.h"
#include <EOControl/EOKeyGlobalID.h>
#include <GDLAccess/EOSQLQualifier.h>

static NSComparisonResult compareLogs(id part1, id part2, void* context) {
  return [(NSNumber *)[part1 valueForKey:@"logId"]
 		           compare:(NSNumber *)
		      [part2 valueForKey:@"logId"]];
}

@interface LSQueryLogsSince : LSDBObjectBaseCommand
{
  id      lastLogId;
}
@end

@implementation LSQueryLogsSince

+ (void)initialize {
}

- (void)dealloc {
  [self->lastLogId release];
  [super dealloc];
}

/* execute */

- (void)_executeInContext:(id)_context {
  /* split up this method */
  NSMutableArray    *result;
  EOAdaptorChannel  *ac        = nil;
  EOSQLQualifier    *q         = nil;
  EOEntity          *logEntity = nil;
  id                obj        = nil;
  NSArray           *ordering  = nil;
  int               cnt        = 0;  
  id account        = [_context valueForKey:LSAccountKey];

  if ([[account valueForKey:@"companyId"] intValue] != 10000) {
    [self assert:NO reason:@"Only root can retrieve audit entries"];
    return;
  }

  ac        = [[self databaseChannel] adaptorChannel];
  logEntity = [[self databaseModel] entityNamed:@"Log"];
  result    = [NSMutableArray arrayWithCapacity:64];
  
  ordering = [NSArray arrayWithObjects:
                [EOSortOrdering sortOrderingWithKey:@"logId" 
                                           selector:EOCompareAscending],
                nil];

  q = [EOSQLQualifier alloc];
  q = [q initWithEntity:logEntity qualifierFormat:@"logId>%@", lastLogId];

  [self assert:[ac selectAttributes:[logEntity attributes]
               describedByQualifier:q
                         fetchOrder:ordering
                               lock:NO]
        reason:[dbMessages description]];
  
  while (((obj = [ac fetchAttributes:[logEntity attributes] 
                           withZone:NULL]) != nil) &&
          (cnt < 150)) {
    id tmp;
    
    cnt++;
    tmp = [obj mutableCopy];
    [result addObject:tmp];
    [tmp release];
  }

  if ([ac isFetchInProgress])
    [ac cancelFetch];
  
  result = (id)[result sortedArrayUsingFunction:compareLogs context:NULL];
  
  if (result) [self setReturnValue:result];
  [q release];
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"logId"]) {
    ASSIGN(self->lastLogId, _value);
  }
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  id v = nil;

  if ([_key isEqualToString:@"logId"])
    v = self->lastLogId;

  return v;
}

@end /* LSGetChangesSince */
