/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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
// $Id$

#include "JobPool.h"
#include "Job.h"
#include "SkyJobQualifier.h"
#include "NSObject+Transaction.h"
#include "common.h"
#include <OGoDaemon/SDXmlRpcFault.h>

@interface JobPool(PrivateMethods)
- (EOGlobalID *)_globalIdForPersonWithId:(NSString *)_id;
- (EOGlobalID *)_globalIdForTeamWithId:(NSString *)_id;
@end /* JobPool */

@implementation JobPool

static int jobSort(id jobDict1, id jobDict2, NSDictionary *context) {
  NSString *sortKey;
  BOOL     sortDescending;
  id element1, element2;

  sortKey = [context valueForKey:@"sortKey"];
  sortDescending = [[context valueForKey:@"sortDescending"] boolValue];
  element1 = [jobDict1 valueForKey:sortKey];
  element2 = [jobDict2 valueForKey:sortKey];

  if (sortDescending)
    return [element1 caseInsensitiveCompare:element2];
  return [element2 caseInsensitiveCompare:element1];
}

/* accessors */

- (id)commandContext {
  return self->context;
}

- (id)getJobByGlobalID:(NSString *)_gid {
  // TODO: add cache access
  EOGlobalID    *gid;

  if (_gid == nil) {
    [self debugWithFormat:@"Invalid globalId"];
    return nil;
  }
  
  if ([_gid hasPrefix:@"skyrix://"]) {
    gid = [[[self commandContext] documentManager] globalIDForURL:_gid];
  }
  else {
    gid = [EOKeyGlobalID globalIDWithEntityName:@"Job"
                         keys:&_gid
                         keyCount:1
                         zone:nil];
  }

  if (gid != nil) {
      id result;

      NSLog(@"-- executing command job::get-by-globalid");
      result = [[self commandContext] runCommand:@"job::get-by-globalid",
                    @"gid", gid,
                    nil];

      if ([self isCurrentTransactionCommitted]) {
        if (result != nil)
          return [result lastObject];
        else
          return nil;
      }
  }
  else
    [self logWithFormat:@"couldn't create a valid globalID for '%@'", _gid];
  return nil;
}

- (NSArray *)_dictionariesForJobRecords:(NSArray *)_records
  withQualifier:(SkyJobQualifier *)_qual
{
  NSEnumerator    *recordEnum;
  EOGenericRecord *record;
  NSMutableArray  *result;
  NSMutableArray  *executantGIDs;
  NSMutableArray  *creatorGIDs;
  NSString        *currentCId;
  EOGlobalID      *gid;
  
  result = [NSMutableArray arrayWithCapacity:[_records count]];
  creatorGIDs = [NSMutableArray arrayWithCapacity:[_records count]];
  executantGIDs = [NSMutableArray arrayWithCapacity:[_records count]];

  currentCId = [self currentCompanyId];
  recordEnum = [_records objectEnumerator];
  
  while ((record = [recordEnum nextObject])) {
    NSString            *executantId;
    BOOL                handleJob     = YES;
    NSString            *teamId;

    teamId = [[_qual teamId] stringValue];
    executantId = [[record valueForKey:@"executantId"] stringValue];

    // filter for team IDs
    if (teamId != nil && ([teamId length] > 0)) {
      if (![executantId isEqualToString:teamId]) {
        NSLog(@"%s: not handling the job cause teamId is filtered",
              __PRETTY_FUNCTION__);
        handleJob = NO;
      }
    }
    else {
      if (![_qual showMyGroups] &&
          ![[_qual methodName] isEqualToString:@"job::get-delegated-jobs"]) {
        if (![executantId isEqualToString:currentCId]) {
          NSLog(@"%s: not handling the job cause team jobs are filtered",
                __PRETTY_FUNCTION__);
          handleJob = NO;
        }
      }
    }

    // filter for time selection
    if ([_qual timeSelection] != nil) {
      BOOL isFuture;
      NSCalendarDate *date;
      NSCalendarDate *sd;

      [self debugWithFormat:@"-- filtering for time selection"];

      isFuture = [[_qual timeSelection] isEqualToString:@"future"];

      date = [NSCalendarDate date];
      // TODO: fix timezone
      // [date setTimeZone:[[self session] timeZone]];

      sd = [record valueForKey:@"startDate"];

      if ([sd compare:[date endOfDay]]  == NSOrderedDescending) {
        if (!isFuture) {
          NSLog(@"%s: not handling the job cause it's not future",
                __PRETTY_FUNCTION__);
          handleJob = NO;
        }
      }
      else {
        if (isFuture) {
          NSLog(@"%s: not handling the job cause it's future",
                __PRETTY_FUNCTION__);
          handleJob = NO;
        }
      }      
    }

    // filter for keywords
    if ([_qual query] != nil) {
      NSArray *query;
      BOOL found = NO;
      NSString *keywords;
      NSEnumerator *queryEnum;
      NSString *field;
      NSRange r;

      [self debugWithFormat:@"-- filtering for keywords"];

      query    = [[_qual query] componentsSeparatedByString:@","];
      keywords = [record valueForKey:@"keywords"];

      queryEnum = [query objectEnumerator];

      while ((keywords != nil) && (field = [queryEnum nextObject])) {
        r = [keywords rangeOfString:field options:NSCaseInsensitiveSearch];

        if (r.length > 0) {
          found = YES;
        }
        else {
          found = NO;
          break;
        }
      }
      if (!found) {
        NSLog(@"%s: not handling the job cause the keyword was not found",
              __PRETTY_FUNCTION__);
        handleJob = NO;
      }
    }
    
    if (handleJob) {
      Job *job;
      NSDictionary *dict;
      
      job = [Job jobWithContext:[self commandContext]
                 record:record];

      dict = [job dictionaryForQualifier:_qual];

      if ([_qual withCreator]) {
        if ((gid = [self _globalIdForPersonWithId:
                         [dict valueForKey:@"creatorId"]]) != nil)
          [creatorGIDs addObject:gid];
      }

      if (![[dict valueForKey:@"isTeamJob"] boolValue])
        gid = [self _globalIdForPersonWithId:executantId];
      else
        gid = [self _globalIdForTeamWithId:executantId];

      if (gid != nil) {
        [executantGIDs addObject:gid];
      }
      
      [result addObject:dict];
    }
  }

  [self fillArray:result withRole:@"executant" forGlobalIDs:executantGIDs
        usingListAttributes:[_qual useListAttributes]];
  
  if ([_qual withCreator]) {
    [self fillArray:result withRole:@"creator" forGlobalIDs:creatorGIDs
          usingListAttributes:[_qual useListAttributes]];
  }
  
  return result;
}

- (NSArray *)getTodoJobsInTimeRange:(NSNumber *)_timeRange {
  NSArray *result;
  NSCalendarDate    *today;
  NSCalendarDate    *future;
  unsigned int      seconds;
  NSString          *command;
  id ctx;

  ctx = [self commandContext];
  command = @"job::get-todo-jobs";
    
  seconds = [_timeRange intValue] * (3600 * 24);
  today  = [NSCalendarDate date];
  future = [today addTimeInterval:seconds];
    
  NSLog(@"-- executing command %@", command);
  result = [ctx runCommand:command,
                @"object", [ctx valueForKey:LSAccountKey],
                @"startDate", today,
                @"endDate", future,
                nil];
    
  if ([self isCurrentTransactionCommitted]) {
    SkyJobQualifier *qual;

    qual = [SkyJobQualifier qualifierForMethodName:command
                            arguments:nil];

    [qual setWithCreator:YES];
    [qual setShowMyGroups:YES];
    
    result = [self _dictionariesForJobRecords:result
                   withQualifier:qual];
    
    if ([result count] > 1) {
      NSDictionary *sortContext;

      sortContext = [NSDictionary dictionaryWithObjectsAndKeys:
                                  @"jobStatus" ,@"sortKey",
                                  [NSNumber numberWithBool:YES],
                                  @"sortDescending",
                                  nil];

      return [result sortedArrayUsingFunction:(void *)jobSort
                     context:sortContext];
    }
    return result;
  }
  return nil;
}

- (id)jobsForProject:(NSString *)_projectId {
  EOGlobalID *projectGID;
  id project;
  id ctx;

  ctx = [self commandContext];

  projectGID = [[ctx documentManager] globalIDForURL:_projectId];

  if (projectGID != nil) {
    NSLog(@"-- executing command project::get-by-globalid");
    project = [ctx runCommand:@"project::get-by-globalid",
                   @"gid",projectGID,
                   nil];

    if (project != nil) {
      NSArray *result;
      SkyJobQualifier *qual;
      NSString *methodName;

      methodName = @"project::get-jobs";

      NSLog(@"-- executing command project::get-jobs");
      result = [ctx runCommand:methodName,
                    @"object",project,
                    nil];

      qual = [SkyJobQualifier qualifierForMethodName:methodName
                              arguments:nil];
      [qual setWithCreator:YES];
      [qual setShowMyGroups:YES];

      result = [self _dictionariesForJobRecords:result
                     withQualifier:qual];
    
      if ([result count] > 1) {
        NSDictionary *sortContext;

        sortContext = [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"jobStatus",
                                    @"sortKey",
                                    [NSNumber numberWithBool:YES],
                                    @"sortDescending",
                                    nil];

        return [result sortedArrayUsingFunction:(void *)jobSort
                       context:sortContext];
      }
      return result;
    }
  }
  return [SDXmlRpcFault invalidObjectFaultForId:_projectId entity:@"project"];
}

- (NSArray *)getJobsWithQualifier:(SkyJobQualifier *)_qual {
  LSCommandContext *ctx;
  
  if ((ctx = [self commandContext]) != nil) {
    NSArray *result;
    id object = nil;
    id person;
    
    NSString *_personURL = [_qual personURL];
    
    if (_personURL != nil) {
      person = [[ctx documentManager] globalIDForURL:_personURL];

      if (person != nil) {
        NSString *command;
        
        if ([[person entityName] isEqualToString:@"Person"])
          command = @"person::get-by-globalid";
        else {
          command = @"team::get-by-globalid";
          [_qual setIsTeamSelected:YES];
          [_qual setShowMyGroups:YES];
        }
        NSLog(@"--+ executing command %@", command);
        object = [[ctx runCommand:command, @"gid", person, nil] lastObject];
      }
    }
    else
      object = [ctx valueForKey:LSAccountKey];

    if (object && ![_qual isTeamSelected]) {
      object = [ctx runCommand:@"account::get-by-login",
                    @"login",[object valueForKey:@"login"],
                    nil];
    }
    
    if (object != nil) {
      NSString *command = [_qual methodName];
      
      NSLog(@"--~ executing command %@", command);
      result = [ctx runCommand:command,
                    @"object", object,
                    nil];

      NSLog(@"%s: got %d results from command", __PRETTY_FUNCTION__,
            [result count]);
      
      if ([self isCurrentTransactionCommitted]) {
        if ([command isEqualToString:@"job::get-todo-jobs"]) {
          [_qual setWithCreator:YES];
        }

        NSLog(@"count --- %d", [result count]);
        result = [self _dictionariesForJobRecords:result
                       withQualifier:_qual];
        NSLog(@"count --- %d", [result count]);
        
        if ([result count] > 1) {
          NSString *sortKey = [_qual sortKey];
          NSNumber *sortDescending = [NSNumber numberWithBool:
                                               [_qual sortDescending]];
          
          if (sortKey != nil && sortDescending != nil) {
            NSDictionary *sortContext;

            sortContext = [NSDictionary dictionaryWithObjectsAndKeys:
                                        sortKey,        @"sortKey",
                                        sortDescending, @"sortDescending",
                                        nil];

            return [result sortedArrayUsingFunction:(void *)jobSort
                           context:sortContext];
          }
        }
        return result;
      }
    }
  }
  return nil;
}

- (id)getJobById:(id)_jobId {
  EOGenericRecord *record;

  if ((record = [self getJobByGlobalID:_jobId]) != nil) {
    NSLog(@"%s: record is %@", __PRETTY_FUNCTION__, record);
    return [Job jobWithContext:[self commandContext] record:record];
  }
  return nil;
}

- (id)getJobDictionaryForId:(id)_jobId {
  Job *job;

  if ((job = [self getJobById:_jobId]) != nil) {
    SkyJobQualifier *qual;

    qual = [SkyJobQualifier qualifierForMethodName:@"job::get-job"
                            arguments:nil];
    [qual setWithCreator:YES];
    [qual setShowMyGroups:YES];
    [qual setUseListAttributes:NO];

    return [[self _dictionariesForJobRecords:
                  [NSArray arrayWithObject:[job record]]
                  withQualifier:qual]
                  lastObject];
  }
  [self logWithFormat:@"ERROR: no job with ID '%@' found", _jobId];
  return [SDXmlRpcFault invalidObjectFaultForId:_jobId entity:@"job"];
}

- (id)setJobStatus:(NSString *)_status withComment:(NSString *)_comment
  forJobWithId:(NSString *)_id
{
  Job *job;

  if ((job = [self getJobByGlobalID:_id]) != nil) {

    Job *jb;
    BOOL result;

    jb = [Job jobWithContext:[self commandContext]
              record:(EOGenericRecord *)job];

    result = [jb setJobStatus:_status withComment:_comment];
    return [NSNumber numberWithBool:result];
  }
  return [SDXmlRpcFault invalidObjectFaultForId:_id
                        entity:@"Job"];
}

- (id)deleteJobWithId:(id)_jobId {
  Job *job;

  if ((job = [self getJobById:_jobId]) != nil) {
    if ([job isKindOfClass:[NSException class]])
      return job;
    return [NSNumber numberWithBool:[job delete]];
  }
  return [SDXmlRpcFault invalidObjectFaultForId:_jobId entity:@"job"];
}

@end /* JobPool */

@implementation JobPool(PrivateMethods)

- (EOGlobalID *)_globalIdWithEntityName:(NSString *)_entity
  forId:(NSString *)_id
{
  EOGlobalID *gid;

  gid = [EOKeyGlobalID globalIDWithEntityName:_entity
                       keys:&_id
                       keyCount:1
                       zone:nil];

  if (gid != nil)
    return gid;

  [self logWithFormat:@"couldn't create '%@' gid for ID %@", _entity, _id];
  return nil;
}

- (EOGlobalID *)_globalIdForPersonWithId:(NSString *)_id {
  return [self _globalIdWithEntityName:@"Person" forId:_id];
}

- (EOGlobalID *)_globalIdForTeamWithId:(NSString *)_id {
  return [self _globalIdWithEntityName:@"Team" forId:_id];
}

@end /* JobPool(PrivateMethods) */
