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

#include "JobHistoryPool.h"
#include "JobHistory.h"
#include "JobPool.h"
#include "Job.h"
#include "NSObject+Transaction.h"
#include "common.h"

@implementation JobHistoryPool

static int jobHistorySort(id historyDict1, id historyDict2, void *context) {
  NSDate *d1 = [historyDict1 valueForKey:@"actionDate"];
  NSDate *d2 = [historyDict2 valueForKey:@"actionDate"];

  return [d2 compare:d1];
}

- (JobPool *)jobPool {
  return [[self commandContext] valueForKey:@"jobPool"];
}

/* convert functions */

- (NSArray *)_dictionariesForJobHistoryRecords:(NSArray *)_records {
  NSEnumerator    *recordEnum;
  EOGenericRecord *record;
  NSMutableArray  *actorGIDs;
  NSMutableArray  *result;

  result = [NSMutableArray arrayWithCapacity:[_records count]];
  actorGIDs = [NSMutableArray arrayWithCapacity:[_records count]];

  recordEnum = [_records objectEnumerator];
  while ((record = [recordEnum nextObject])) {
    JobHistory *jh;
    NSDictionary *dict;
    NSString *aid;
    EOGlobalID *gid;

    jh = [JobHistory jobHistoryWithContext:[self commandContext]
                     record:record];
    dict = [jh asDictionary];
    aid = [dict valueForKey:@"actor"];

    [result addObject:dict];

    gid = [EOKeyGlobalID globalIDWithEntityName:@"Person"
                         keys:&aid
                         keyCount:1
                         zone:nil];

    if (gid != nil)
      [actorGIDs addObject:gid];
    else
      [self logWithFormat:@"couldn't create global ID from key '%@'", aid];
  }

  [self fillArray:result withRole:@"actor"
        forGlobalIDs:actorGIDs usingListAttributes:NO];

  return [result sortedArrayUsingFunction:jobHistorySort context:nil];
}

- (NSArray *)jobHistoryForId:(id)_id {
  Job *job;
  
  if ((job = [[self jobPool] getJobById:_id]) != nil) {
    NSArray *result;

    NSLog(@"-- executing command job::get-job-history");      
    result = [[self commandContext] runCommand:@"job::get-job-history",
                                    @"object", job,
                                    nil];
    if ([self isCurrentTransactionCommitted])
      return [self _dictionariesForJobHistoryRecords:result];
  }
  return nil;
}

@end /* JobHistoryPool */
