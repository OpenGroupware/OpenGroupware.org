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

#include "Job.h"
#include "JobHistoryPool.h"
#include "SkyJobQualifier.h"

#include "NSObject+Transaction.h"
#include "common.h"

#include <EOControl/EOGenericRecord.h>

@implementation Job

+ (Job *)jobWithContext:(id)_ctx attributes:(NSDictionary *)_attributes {
  Job *job;

  if (_ctx != nil) {
    id object;
    
    job = [[Job alloc] initWithEOGenericRecord:nil context:_ctx];

    object = [_ctx runCommand:@"job::new" arguments:_attributes];

    if (object != nil) {
      [job setRecord:object];
      [job setJobId:[object valueForKey:@"jobId"]];
      return AUTORELEASE(job);
    }
  }
  [self logWithFormat:@"Couldn't create Job"];
  return nil;
}

+ (Job *)jobWithContext:(id)_ctx record:(EOGenericRecord *)_record {
  return AUTORELEASE([[Job alloc] initWithEOGenericRecord:_record
                                  context:_ctx]);
}

- (id)init {
  return [self initWithEOGenericRecord:nil context:nil];
}

- (id)initWithEOGenericRecord:(id)_record context:(id)_ctx {
  if ((self = [super init])) {
    if (_record != nil) {
      self->jobId = [[_record valueForKey:@"jobId"] copy];
      ASSIGN(self->record, _record);
    }
    self->context = _ctx;
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->record);
  //RELEASE(self->context);
  RELEASE(self->jobId);
  [super dealloc];
}

/* accessors */

- (id)record {
  return self->record;
}

- (void)setRecord:(id)_record {
  ASSIGN(self->record, _record);
}

- (id)commandContext {
  return self->context;
}

- (void)setJobId:(NSString *)_jobId {
  _jobId = [_jobId stringValue];
  ASSIGNCOPY(self->jobId, _jobId);
}  

- (NSString *)jobId {
  return self->jobId;
}

- (JobHistoryPool *)jobHistoryPool {
  return [[self commandContext] valueForKey:@"jobHistoryPool"];
}

- (NSDictionary *)dictionaryForQualifier:(SkyJobQualifier *)_qual {
  NSString            *tmp;
  NSNumber            *isTeamJob;
  NSMutableDictionary *dict;
  NSString            *executantId;
  NSCalendarDate      *now;
  NSCalendarDate      *eD;
  BOOL                isOutOfTime   = NO;
  BOOL                onTime;
  
  id                  rec;
  id                  project;
  
  rec = [self record];
  isTeamJob = [NSNumber numberWithBool:[[rec valueForKey:@"isTeamJob"]
                                             boolValue]];
  
  dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                              [rec valueForKey:@"jobStatus"],
                              @"jobStatus",
                              [rec valueForKey:@"name"],
                              @"name",
                              [rec valueForKey:@"startDate"],
                              @"startDate",
                              [rec valueForKey:@"endDate"],
                              @"endDate",
                              [rec valueForKey:@"objectVersion"],
                              @"objectVersion",
                              [rec valueForKey:@"jobId"],
                              @"jobId",
                              isTeamJob,
                              @"isTeamJob",
                              [self _urlStringForGlobalId:
                                    [rec valueForKey:@"globalID"]],
                              @"id",
                              nil];
  
  if ((tmp = [rec valueForKey:@"notify"]) != nil)
    [dict setObject:tmp forKey:@"notify"];

  if ((tmp = [rec valueForKey:@"category"]) != nil)
    [dict setObject:tmp forKey:@"category"];

  if ((tmp = [rec valueForKey:@"keywords"]) != nil)
    [dict setObject:tmp forKey:@"keywords"];

  if ((tmp = [rec valueForKey:@"priority"]) != nil)
    [dict setObject:tmp forKey:@"priority"]; 

  if ((project = [rec valueForKey:@"toProject"]) != nil) {
    NSDictionary *projectDict;
        
    if ([_qual useListAttributes])
      projectDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [project valueForKey:@"name"],
                                  @"name",
                                  nil];
    else
      projectDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [project valueForKey:@"name"],
                                  @"name",
                                  [project valueForKey:@"number"],
                                  @"number",
                                  [self _urlStringForGlobalId:
                                        [project valueForKey:@"globalID"]],
                                  @"id",
                                  nil];          

    [dict setObject:projectDict forKey:@"project"];
  }

  if ((tmp = [self _urlStringForGlobalId:[rec valueForKey:@"globalId"]])
       != nil)
    [dict setObject:tmp forKey:@"id"];
  
  if ([_qual withCreator]) {
    NSString *creatorId;
        
    if ((creatorId = [rec valueForKey:@"creatorId"]) != nil) {
      [dict setObject:creatorId forKey:@"creatorId"];
    }
  }

  if ((executantId = [record valueForKey:@"executantId"]) != nil) {
    [dict setObject:executantId forKey:@"executantId"];
  }

  now = [NSCalendarDate date];
  eD  = [record valueForKey:@"endDate"];

  [now setTimeZone:[eD timeZone]];

  if ([[eD beginOfDay] compare:[now beginOfDay]] == NSOrderedAscending)
    isOutOfTime = YES;

  [dict setObject:[NSNumber numberWithBool:isOutOfTime]
        forKey:@"isEndDateOutOfTime"];

  onTime = ([eD timeIntervalSinceNow] > 0) ? YES : NO;

  [dict setObject:[NSNumber numberWithBool:onTime]
        forKey:@"isEndDateOnTime"];  
      
  return dict;
}

/* actions */

- (BOOL)updateWithAttributes:(NSDictionary *)_attributes {
  id object;
  
  object = [[self commandContext] runCommand:@"job::set"
                                  arguments:_attributes];
  
  if ([object isKindOfClass:[EOGenericRecord class]]) {
    RELEASE(self->record);
    self->record = [object copy];
    return YES;
  }
  [self logWithFormat:@"Couldn't update Job"];
  return NO;
}

- (BOOL)setJobStatus:(NSString *)_status withComment:(NSString *)_comment {
  id result;
  id ctx;

  ctx = [self commandContext];

  if (_comment != nil) {
    result = [ctx runCommand:@"job::jobaction",
                  @"object", self->record,
                  @"action", _status,
                  @"comment", _comment,
                  nil];
  }
  else {
    result = [ctx runCommand:@"job::jobaction",
                  @"object", self->record,
                  @"action", _status,
                  nil];
  }

  if ([result isKindOfClass:[EOGenericRecord class]]) {
    if ([_status isEqualToString:@"accept"] &&
        [[[self record] valueForKey:@"isTeamJob"] boolValue]) {
      NSDictionary *attributes;

      attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [[ctx valueForKey:LSAccountKey]
                                       valueForKey:@"companyId"],
                                 @"executantId",
                                 [self jobId],
                                 @"jobId",
                                 nil];

      result = [ctx runCommand:@"job::set",
                    @"attributes", attributes,
                    nil];
    }

    if ([result isKindOfClass:[EOGenericRecord class]]) {
      return [self isCurrentTransactionCommitted];
    }
  }
  return NO;
}

- (NSArray *)getJobHistory {
  return [[self jobHistoryPool] jobHistoryForId:self->jobId];
}

- (BOOL)delete {
  id result;

  result = [[self commandContext] runCommand:@"job::delete",
                                  @"object", self->record,
                                  nil];
  if (result != nil)
    return [self isCurrentTransactionCommitted];       

  return NO;
}

@end /* Job */
