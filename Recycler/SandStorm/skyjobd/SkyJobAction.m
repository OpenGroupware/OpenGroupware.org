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

#include "SkyJobAction.h"
#include "SkyJobAction+PrivateMethods.h"
#include "SkyJobQualifier.h"

#include "Job.h"
#include "JobPool.h"
#include "JobHistoryPool.h"

#include "common.h"

#include <XmlRpc/XmlRpcMethodCall.h>
#include <OGoIDL/NGXmlRpcAction+Introspection.h>
#include <LSFoundation/NSObject+Commands.h>
#include <OGoDaemon/SDXmlRpcFault.h>

@implementation SkyJobAction

+ (NSArray *)xmlrpcNamespaces {
  return [NSArray arrayWithObject:@"jobs"];
}

- (NSString *)xmlrpcComponentName {
  return @"jobs";
}

- (id)initWithContext:(WOContext *)_ctx {
  if ((self = [super initWithContext:_ctx])) {
    NSString *path;
    NSBundle *bundle;
    LSCommandContext *ctx;
    JobPool *jp;
    JobHistoryPool *jhp;

    ctx = [self commandContext];

    if ([ctx valueForKey:@"jobPool"] == nil) {
      [self logWithFormat:@"initializing job/job-history pool"];
      jp = [JobPool poolWithContext:ctx];
      jhp = [JobHistoryPool poolWithContext:ctx];
      [ctx takeValue:jp forKey:@"jobPool"];
      [ctx takeValue:jhp forKey:@"jobHistoryPool"];
    }
    
    bundle = [NSBundle bundleForClass:[self class]];

    path = [bundle pathForResource:@"INTERFACE" ofType:@"xml"];
    if (path != nil)
      [self registerInterfaceAtPath:path forComponentName:
            [self xmlrpcComponentName]];
    else
      [self logWithFormat:@"INTERFACE.xml not found in bundle path"];
  }
  return self;
}

- (BOOL)requiresCommandContextForMethodCall:(NSString *)_method {
  static NSArray *methodNames = nil;
  
  if (methodNames == nil)
    methodNames = [[NSArray alloc] initWithObjects:
                            @"system.listMethods",
                            @"system.methodSignature",
                            @"system.methodHelp",
                            nil];

  if ([methodNames containsObject:_method])
    return NO;
  return YES;
}

/* accessors */

- (JobPool *)jobPool {
  return [[self commandContext] valueForKey:@"jobPool"];
}

- (JobHistoryPool *)jobHistoryPool {
  return [[self commandContext] valueForKey:@"jobHistoryPool"];
}

/* job status actions */

- (NSNumber *)doneJobAction:(NSString *)_id:(NSString *)_comment {
  return [self _setJobStatus:@"done" forJobId:_id withComment:_comment];
}

- (NSNumber *)archiveJobAction:(NSString *)_id:(NSString *)_comment {
  return [self _setJobStatus:@"archive" forJobId:_id withComment:_comment];
}

- (NSNumber *)acceptJobAction:(NSString *)_id:(NSString *)_comment {
  return [self _setJobStatus:@"accept" forJobId:_id withComment:_comment];
}

- (NSNumber *)annotateJobAction:(NSString *)_id:(NSString *)_comment {
  return [self _setJobStatus:@"comment" forJobId:_id withComment:_comment];
}

- (NSNumber *)rejectJobAction:(NSString *)_id:(NSString *)_comment {
  return [self _setJobStatus:@"reject" forJobId:_id withComment:_comment];
}

- (NSNumber *)reactivateJobAction:(NSString *)_id:(NSString *)_comment {
  return [self _setJobStatus:@"reactivate" forJobId:_id withComment:_comment];
}

/* single job actions */

- (id)getJobAction:(NSString *)_jobId {
  return [[self jobPool] getJobDictionaryForId:_jobId];
}
  
- (id)deleteJobAction:(NSString *)_jobId {
  return [[self jobPool] deleteJobWithId:_jobId];
}

/* fetching jobs */

- (NSArray *)todoJobsInTimeRangeAction:(NSNumber *)_timeRange {
  return [[self jobPool] getTodoJobsInTimeRange:_timeRange];
}

- (NSArray *)todoJobsAction:(NSString *)_personURL
                           :(NSString *)_teamId
                           :(NSNumber *)_showMyGroups
                           :(NSString *)_query
                           :(NSString *)_timeSelection
                           :(NSString *)_sortKey
                           :(NSNumber *)_sortOrdering
{
  NSDictionary    *attributes;
  SkyJobQualifier *qual;

  // this should handle the cache instead
  //if ((jobs = [[self commandContext] valueForKey:@"loginJobs"]) != nil)
  //  return jobs;
  //
  
  attributes = [self _buildDictionaryForAttributes:_query:_personURL:_teamId
                     :_timeSelection:_sortKey:_sortOrdering:_showMyGroups];
  
  qual = [SkyJobQualifier qualifierForMethodName:@"job::get-todo-jobs"
                          arguments:attributes];
  
  return [self _getJobsWithQualifier:qual];
}

- (NSArray *)privateJobsAction:(NSString *)_personURL
                              :(NSString *)_teamId
                              :(NSNumber *)_showMyGroups
                              :(NSString *)_query
                              :(NSString *)_timeSelection
                              :(NSString *)_sortKey
                              :(NSNumber *)_sortOrdering
{
  NSDictionary *attributes;
  SkyJobQualifier *qual;

  attributes = [self _buildDictionaryForAttributes:_query:_personURL:_teamId
                     :_timeSelection:_sortKey:_sortOrdering:_showMyGroups];

  qual = [SkyJobQualifier qualifierForMethodName:@"job::get-private-jobs"
                          arguments:attributes];
  
  return [self _getJobsWithQualifier:qual];
}

- (NSArray *)archivedJobsAction:(NSString *)_personURL
                               :(NSString *)_teamId
                               :(NSNumber *)_showMyGroups
                               :(NSString *)_query
                               :(NSString *)_timeSelection
                               :(NSString *)_sortKey
                               :(NSNumber *)_sortOrdering
{
  NSDictionary *attributes;
  SkyJobQualifier *qual;

  attributes = [self _buildDictionaryForAttributes:_query:_personURL:_teamId
                     :_timeSelection:_sortKey:_sortOrdering:_showMyGroups];

  qual = [SkyJobQualifier qualifierForMethodName:@"job::get-archived-jobs"
                          arguments:attributes];
  [qual setIsTeamSelected:YES];
  
  return [self _getJobsWithQualifier:qual];
}

- (NSArray *)controlJobsAction:(NSString *)_personURL
                              :(NSString *)_teamId
                              :(NSNumber *)_showMyGroups
                              :(NSString *)_query
                              :(NSString *)_timeSelection
                              :(NSString *)_sortKey
                              :(NSNumber *)_sortOrdering

{
  NSDictionary *attributes;
  SkyJobQualifier *qual;

  attributes = [self _buildDictionaryForAttributes:_query:_personURL:_teamId
                     :_timeSelection:_sortKey:_sortOrdering:_showMyGroups];

  qual = [SkyJobQualifier qualifierForMethodName:@"job::get-control-jobs"
                          arguments:attributes];
  
  return [self _getJobsWithQualifier:qual];
}

- (NSArray *)delegatedJobsAction:(NSString *)_personURL
                                :(NSString *)_teamId
                                :(NSNumber *)_showMyGroups
                                :(NSString *)_query
                                :(NSString *)_timeSelection
                                :(NSString *)_sortKey
                                :(NSNumber *)_sortOrdering
{
  NSDictionary *attributes;
  SkyJobQualifier *qual;

  attributes = [self _buildDictionaryForAttributes:_query:_personURL:_teamId
                     :_timeSelection:_sortKey:_sortOrdering:_showMyGroups];

  qual = [SkyJobQualifier qualifierForMethodName:@"job::get-delegated-jobs"
                          arguments:attributes];
  
  return [self _getJobsWithQualifier:qual];
}

/* project jobs */

- (NSArray *)jobsForProjectAction:(NSString *)_projectId {
  return [[self jobPool] jobsForProject:_projectId];
}

/* login action */

- (NSNumber *)loginAction {
  [NSTimer scheduledTimerWithTimeInterval:0.1
           target:self
           selector:@selector(_fetchTodoJobsOfCurrentUser)
           userInfo:nil
           repeats:NO];
  
  return [NSNumber numberWithBool:YES];
}

- (void)_fetchTodoJobsOfCurrentUser {
 id jobs;

  jobs = [self todoJobsAction:nil:nil:nil:nil:nil:nil:nil];

  [[self commandContext] takeValue:jobs forKey:@"loginJobs"];
}

- (NSException *)_invalidArgument:(NSString *)_arg {
  NSException  *exc;
  NSString     *s;
  NSDictionary *ui;
  
  ui = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:21]
		     forKey:@"faultCode"];
  s = [NSString stringWithFormat:@"got an invalid argument '%@'", _arg];
  
  exc = [NSException exceptionWithName:@"InvalidArgument"
		     reason:s
		     userInfo:ui];
  return exc;
}

- (id)createJobAction:(NSString *)_title
                     :(NSString *)_executantId
                     :(NSString *)_projectId
                     :(NSDate *)_startDate
                     :(NSDate *)_endDate
                     :(NSNumber *)_priority
                     :(NSString *)_keywords
                     :(NSString *)_category
                     :(NSString *)_comment
                     :(NSNumber *)_notify
{
  Job *job;
  NSMutableDictionary *attributes;
  NSString *executantId;

  if (_title == nil)
    return [SDXmlRpcFault missingValueFaultForArgument:@"title"];

  executantId = [self _validExecutantId:_executantId];
  if ([executantId isKindOfClass:[SDXmlRpcFault class]])
    return executantId;
 
  // FIXME: some attribute added to the NSMutableDictionary is nil...
 
  attributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                    _title, @"name",
                                    executantId, @"executantId",
                                    [self _validStartDate:_startDate],
                                    @"startDate",
                                    [self _validEndDate:_endDate],
                                    @"endDate",
                                    [self _validPriority:_priority],
                                    @"priority",
                                    _notify,
                                    @"notify",
                                    nil];
  
  if ([_projectId length] == 0)
    _projectId = nil;
  else if ([_projectId isEqual:@"0"])
    _projectId = nil;
    
  if ([_projectId length] > 0) {
    [attributes setObject:_projectId forKey:@"projectId"];
  }
  
  if (_keywords != nil)
    [attributes setObject:_keywords forKey:@"keywords"];

  if (_category != nil)
    [attributes setObject:_category forKey:@"category"];

  if (_comment != nil)
    [attributes setObject:_comment forKey:@"comment"];
  
  if ([self _executantIsTeam:executantId])
    [attributes setObject:[NSNumber numberWithBool:YES] forKey:@"isTeamJob"];
  
  job = [Job jobWithContext:[self commandContext] attributes:attributes];
  return [job jobId];
}

- (id)updateJobAction:(NSString *)_url
                     :(NSString *)_title
                     :(NSString *)_executantId
                     :(NSDate *)_startDate
                     :(NSDate *)_endDate
                     :(NSNumber *)_priority
                     :(NSString *)_keywords
                     :(NSString *)_category
                     :(NSNumber *)_notify
{
  Job *job;

  if ((job = [[self jobPool] getJobById:_url]) != nil) {
    NSMutableDictionary *attributes;
    NSString *executantId;

    if (_title == nil)
      return [SDXmlRpcFault missingValueFaultForArgument:@"title"];

    executantId = [self _validExecutantId:_executantId];
    
    attributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                      [_url lastPathComponent], @"jobId",
                                      _title, @"name",
                                      executantId, @"executantId",
                                      [self _validStartDate:_startDate],
                                      @"startDate",
                                      [self _validEndDate:_endDate],
                                      @"endDate",
                                      [self _validPriority:_priority],
                                      @"priority",
                                      _notify,
                                      @"notify",
                                      nil];

    if (_keywords != nil)
      [attributes setObject:_keywords forKey:@"keywords"];

    if (_category != nil)
      [attributes setObject:_category forKey:@"category"];

    if ([self _executantIsTeam:executantId])
      [attributes setObject:[NSNumber numberWithBool:YES] forKey:@"isTeamJob"];
    
    return [NSNumber numberWithBool:[job updateWithAttributes:attributes]];
  }

  [self logWithFormat:@"ERROR: no job with ID '%@' found", _url];
  return [SDXmlRpcFault invalidObjectFaultForId:_url entity:@"job"];
}

/* job history */
  
- (id)jobHistoryAction:(NSString *)_url {
  return [[self jobHistoryPool] jobHistoryForId:_url];
}

@end /* SkyJobAction */

