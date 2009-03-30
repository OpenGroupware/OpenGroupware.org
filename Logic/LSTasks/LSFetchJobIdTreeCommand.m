/*
  Copyright (C) 2008 Whitemice Consulting (Adam Tauno Williams)

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

@class NSCalendarDate, NSTimeZone, NSNumber;
@class NSMutableDictionary;
@class LSCommandContext;

@interface LSFetchJobIdTreeCommand : LSDBObjectBaseCommand
{
  NSDictionary      *jobTree;
  NSNumber          *jobId;
}
- (NSDictionary *)_getChildrenOfJob:(NSNumber *)_jobId;
- (NSNumber *)_getParentJobIdOfJobId:(NSNumber *)_jobId;

@end

@implementation LSFetchJobIdTreeCommand

+ (void)initialize {
}

- (id)initForOperation:(NSString *)_operation inDomain:(NSString *)_domain {
  if ((self = [super initForOperation:_operation inDomain:_domain])) {
  }
  return self;
}

- (void)dealloc {
  [self->jobId release];
  [super dealloc];
}

- (void)setJobId:(NSNumber *)_jobId {
  ASSIGNCOPY(self->jobId, _jobId);
}
- (NSNumber *)jobId {
  return self->jobId;
}

-(NSNumber *)_getParentJobIdOfJobId:(NSNumber *)_jobId
{
  EOAdaptorChannel    *eoChannel;
  NSArray             *attributes;
  NSDictionary        *record;
  NSString            *query;
  id                   result;

  eoChannel = [[self databaseChannel] adaptorChannel];

  query = [NSString stringWithFormat:@"SELECT %@ FROM %@ WHERE %@ = %@",
            @"parent_job_id",
            [[[self databaseModel] entityNamed:@"Job"] externalName],
            @"job_id",
            _jobId];
  if ([eoChannel evaluateExpression:query]) {
    if ((attributes = [eoChannel describeResults]) != nil) {
      while ((record = [eoChannel fetchAttributes:attributes 
                                         withZone:NULL]) != nil) {
        result = [record valueForKey:@"parentJobId"];
      }
    }
  }
  if ([result isKindOfClass:[EONull class]])
    return nil;
  return result;
}

-(NSNumber *)_getRootJobId
{
  NSNumber *currentJobId, *tmp;

  currentJobId = self->jobId;
  while((tmp = [self _getParentJobIdOfJobId:currentJobId]) != nil)
  {
    currentJobId = tmp;
  }  
  return currentJobId;
}

- (NSDictionary *)_getChildrenOfJob:(NSNumber *)_jobId
{
  EOAdaptorChannel    *eoChannel;
  NSArray             *attributes;
  NSDictionary        *record;
  NSMutableDictionary *result;
  NSMutableArray      *children;
  NSString            *query;
  NSEnumerator        *enumerator;
  id                   tmp;

  eoChannel = [[self databaseChannel] adaptorChannel];

  query = [NSString stringWithFormat:@"SELECT %@ FROM %@ WHERE %@ = %@",
            @"job_id",
            [[[self databaseModel] entityNamed:@"Job"] externalName],
            @"parent_job_id",
            _jobId];

  result = [NSMutableDictionary dictionaryWithCapacity:16];
  children = [NSMutableArray arrayWithCapacity:16];
  if ([eoChannel evaluateExpression:query]) {
    if ((attributes = [eoChannel describeResults]) != nil) {
      while ((record = [eoChannel fetchAttributes:attributes 
                                         withZone:NULL]) != nil) {
        [children addObject:[record valueForKey:@"jobId"]];
      }
    }
  }
  enumerator = [children objectEnumerator];
  while ((tmp = [enumerator nextObject]) != nil)
    [result setObject:[self _getChildrenOfJob:tmp] forKey:tmp];
  return result;
}

- (void)_executeInContext:(id)_context {
  id              rootId;

  /* Run up the chain of jobs to find the top-level job */
  rootId = [self _getRootJobId];
  /* Descend from the top building a graph of the jobs */
  self->jobTree = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [self _getChildrenOfJob:rootId], 
                                  rootId, 
                                  nil];
  [self setReturnValue:self->jobTree];
  [super _executeInContext:_context];
}

/* key-value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualTo:@"jobId"]) {
    [self setJobId:_value];
  } else {
      [super takeValue:_value forKey:_key];
    }
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualTo:@"jobId"])
    return [self jobId];
  return [super valueForKey:_key];
}


@end /* LSFetchJobIdTreeCommand */
