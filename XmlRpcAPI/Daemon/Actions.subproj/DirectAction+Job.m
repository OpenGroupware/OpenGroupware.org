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

#include "DirectAction.h"
#include <EOControl/EOControl.h>
#include <OGoJobs/SkyJobDocument.h>
#include <OGoContacts/SkyPersonDocument.h>
#include <OGoDocuments/SkyDocumentManager.h>
#include "EOControl+XmlRpcDirectAction.h"
#include "NSObject+EKVC.h"
#include "common.h"

@implementation DirectAction(JobMethods)

- (NSDictionary *)_dictionaryForJobHistoryEOGenericRecord:(id)_record
  withComment:(NSString *)_comment
{
  static NSArray *resKeys = nil;
  id result;
  
  if (resKeys == nil)
    resKeys = [[NSArray alloc] initWithObjects:
                               @"action", @"actionDate", @"actorId",
                               @"jobId", @"jobStatus", nil];

  result = [self _dictionaryForEOGenericRecord:_record withKeys:resKeys];

  if ([_comment length] > 0)
    [result takeValue:_comment forKey:@"comment"];
  else
    [result takeValue:@"" forKey:@"comment"];
  
  [self substituteIdsWithURLsInDictionary:result
        forKeys:[NSArray arrayWithObjects:@"actorId",@"jobId",nil]];

  return result;
}

- (NSArray *)_dictionariesForJobHistoryEOGenericRecords:(NSArray *)_records
  withHistoryComments:(NSArray *)_comments
{
  NSMutableArray *result;
  NSEnumerator *recEnum;
  NSMutableDictionary *lookupDict;
  id record;

  NSEnumerator *commentEnum;
  NSDictionary *commentEntry;

  lookupDict = [NSMutableDictionary dictionaryWithCapacity:[_comments count]];

  // fill lookup dictionary
  commentEnum = [_comments objectEnumerator];
  while ((commentEntry = [commentEnum nextObject]))
    [lookupDict takeValue:[commentEntry valueForKey:@"comment"]
                forKey:[commentEntry valueForKey:@"jobHistoryId"]];

  
  result = [NSMutableArray arrayWithCapacity:[_records count]];
  recEnum = [_records objectEnumerator];
  while ((record = [recEnum nextObject])) {
    NSString *comment;

    comment = [lookupDict valueForKey:[record valueForKey:@"jobHistoryId"]];
    
    [result addObject:[self _dictionaryForJobHistoryEOGenericRecord:record
                            withComment:comment]];
  }
  return result;
}

- (NSArray *)_jobDocumentsForEORecords:(NSArray *)_records {
  /* the result of this method is directly used as an XML-RPC result */
  NSMutableArray  *resultJobs;
  EODataSource    *ds;
  NSEnumerator    *resEnum;
  EOGenericRecord *resElem;
  
  // TODO: fix prototype
  // TODO: this is not really correct? (but should work sufficiently well)
  ds = [(SkyAccessManager *)
	 [NSClassFromString(@"SkyPersonJobDataSource") alloc] 
	 initWithContext:[self commandContext]];
  if (ds == nil) {
    [self logWithFormat:
	    @"ERROR(%s): could not instantiate SkyPersonJobDataSource!",
	    __PRETTY_FUNCTION__];
  }
  
  resultJobs = [NSMutableArray arrayWithCapacity:[_records count]];
  resEnum = [_records objectEnumerator];

  while ((resElem = [resEnum nextObject])) {
    SkyJobDocument *jd;
    EOGlobalID *gid;
    
    gid = [resElem valueForKey:@"globalID"];
    jd = [[SkyJobDocument alloc] initWithJob:resElem 
				 globalID:gid dataSource:ds];
    if (jd == nil)
      continue;
    
    [resultJobs addObject:jd];
    [jd release];;
  }
  
  [ds release];
  return resultJobs;
}

- (BOOL)commitTaskTransaction {
  // TODO: wrong class name
  LSCommandContext *ctx;

  if ((ctx = [self commandContext]) == nil)
    return NO;
  
  if (![ctx isTransactionInProgress])
    return YES;
  
  if (![ctx commit]) {  
    [self logWithFormat:@"ERROR: could not commit transaction ..."];
    return NO;
  }
  return YES;
}

- (id)getJobByGlobalID:(NSString *)_gid {
  EOGlobalID *gid;
  id result;
  
  if ([_gid isKindOfClass:[NSDictionary class]])
    _gid = [(NSDictionary *)_gid objectForKey:@"jobId"];
  
  _gid = [_gid stringValue];
  
  if (_gid == nil) {
    // TODO: raise fault?
    [self debugWithFormat:@"ERROR: got no identifier for job."];
    return nil;
  }
  
  if ([_gid hasPrefix:@"skyrix://"]) {
    gid = [[[self commandContext] documentManager] globalIDForURL:_gid];
  }
  else {
    _gid = (id)[NSNumber numberWithInt:[_gid intValue]];
    gid = [EOKeyGlobalID globalIDWithEntityName:@"Job"
                         keys:&_gid keyCount:1 zone:NULL];
  }
  
  if (gid == nil) {
    [self logWithFormat:@"could not create a valid globalID for '%@'", _gid];
    return nil;
  }
  
  result = [[self commandContext] runCommand:@"job::get-by-globalid",
				    @"gid", gid, nil];

  if (![self commitTaskTransaction])
    return nil;
  
  if (result != nil)
    return [result lastObject];
  
  return nil;
}

- (id)_setJobStatus:(NSString *)_status
  forJobId:(NSString *)_jobId
  withComment:(NSString *)_comment
{
  LSCommandContext *ctx;
  EOGenericRecord  *job;
  id               result;
  
  if ((ctx = [self commandContext]) == nil)
    return [self invalidCommandContextFault];
  
  if ((job = [self getJobByGlobalID:_jobId]) == nil) {
    return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_PARAMETER
		 reason:@"Could not find task with given ID"];
  }

  if (_comment != nil) {
    result = [ctx runCommand:@"job::jobaction",
                      @"object", job,
                      @"action", _status,
                      @"comment", _comment,
                      nil];
  }
  else {
    result = [ctx runCommand:@"job::jobaction",
                      @"object", job,
                      @"action", _status,
                      nil];
  }
  
  if (![result isKindOfClass:[EOGenericRecord class]]) {
    // TODO: document intention!
    return [self invalidResultFault];
  }
  
  if ([_status isEqualToString:@"accept"] &&
      [[job valueForKey:@"isTeamJob"] boolValue]) {
    NSDictionary *attributes;
    NSNumber     *loginId;

    loginId    = [[ctx valueForKey:LSAccountKey] valueForKey:@"companyId"];
    attributes = [NSDictionary dictionaryWithObjectsAndKeys:
				 loginId, @"executantId", _jobId,@"jobId",nil];
    
    result = [ctx runCommand:@"job::set", @"attributes", attributes, nil];
    if (![result isKindOfClass:[EOGenericRecord class]]) {
      // TODO: document intention!
      return [self invalidResultFault];
    }
  }
  
  return [NSNumber numberWithBool:[self commitTaskTransaction]];
}

/* assign to/detach from project */

- (id)_validateURL:(NSString *)_url forEntity:(NSString *)_entity
  inContext:(LSCommandContext *)_ctx
{
  EOGlobalID *gid;
  NSString *eName;
  NSString *errorMessage;

  if ((gid = [[_ctx documentManager] globalIDForURL:_url]) == nil) {
    return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_PARAMETER
                 reason:@"No object for URL found"];
  }

  eName = [gid entityName];
  if ([eName isEqualToString:_entity])
    return nil;

  errorMessage = [NSString stringWithFormat:
			     @"Given URL is of type '%@' (expected '%@')",
                             eName, _entity];
  
  return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_PARAMETER
	       reason:errorMessage];
}

- (id)_jobProjectAssignmentWithCommand:(NSString *)_command
  forJobId:(NSString *)_jobId
  projectId:(NSString *)_projectId
  logText:(NSString *)_logText
{
  LSCommandContext    *ctx;
  NSString            *projectId;
  NSMutableDictionary *arguments;
  id                  result;
  
  if ((ctx = [self commandContext]) == nil) 
    return [self invalidCommandContextFault];
    
  [self _validateURL:_jobId     forEntity:@"Job"     inContext:ctx];
  [self _validateURL:_projectId forEntity:@"Project" inContext:ctx];

  projectId = [_projectId lastPathComponent];

  arguments = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     [_jobId lastPathComponent], @"jobId",
				   nil];

  if ([_command isEqualToString:@"job::assign-to-project"])
    [arguments takeValue:projectId forKey:@"projectId"];

  if ([_logText length] > 0)
    [arguments takeValue:_logText forKey:@"logText"];

  result = [ctx runCommand:_command arguments:arguments];
  
  if (![result isKindOfClass:[EOGenericRecord class]]) {
    return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_RESULT
		 reason:@"Invalid result for operation"];
  }
  return [NSNumber numberWithBool:YES];
}

- (id)jobs_assignToProjectAction:(NSString *)_jobId:(NSString *)_projectId
  :(NSString *)_logText
{
  return [self _jobProjectAssignmentWithCommand:@"job::assign-to-project"
               forJobId:_jobId projectId:_projectId
               logText:_logText];
}

- (id)jobs_detachFromProjectAction:(NSString *)_jobId:(NSString *)_logText {
  return [self _jobProjectAssignmentWithCommand:@"job::detach-from-project"
               forJobId:_jobId projectId:nil
               logText:_logText];
}

/* job history */

- (id)jobs_getHistoryAction:(NSString *)_jobId {
  LSCommandContext *ctx;
  NSArray *comments;
  id job;
  id result;

  if ((ctx = [self commandContext]) == nil)
    return [self invalidCommandContextFault];
  
  if ((job = [self getJobByGlobalID:_jobId]) == nil) {
    return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_PARAMETER
		 reason:@"didn ot find job for given URL"];
  }
  
  result = [ctx runCommand:@"job::get-job-history", @"object", job, nil];
      
  if (![result isKindOfClass:[NSArray class]]) {
    return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_RESULT
		 reason:@"Invalid result for job history operation"];
  }
  
  /* fill comment BLOBs into job-history */
  comments = [ctx runCommand:@"job::get-job-history-info",
		    @"objects", result, nil];
  if (![comments isKindOfClass:[NSArray class]]) {
    return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_RESULT
		 reason:@"Invalid result for job history operation"];
  }
  
  return [self _dictionariesForJobHistoryEOGenericRecords:result
	       withHistoryComments:comments];
}

/* job status actions */

- (id)jobs_markDoneAction:(NSString *)_jobId:(NSString *)_comment {
  return [self _setJobStatus:@"done" forJobId:_jobId withComment:_comment];
}

- (id)jobs_archiveJobAction:(NSString *)_jobId:(NSString *)_comment {
  return [self _setJobStatus:@"archive" forJobId:_jobId withComment:_comment];
}

- (id)jobs_acceptJobAction:(NSString *)_jobId:(NSString *)_comment {
  return [self _setJobStatus:@"accept" forJobId:_jobId withComment:_comment];
}

- (id)jobs_annotateJobAction:(NSString *)_jobId:(NSString *)_comment {
  if ([_comment length] == 0) {
    return [self faultWithFaultCode:XMLRPC_FAULT_MISSING_PARAMETER
                 reason:@"Missing comment for annotate operation"];
  }
  
  return [self _setJobStatus:@"comment" forJobId:_jobId withComment:_comment];
}

- (id)jobs_rejectJobAction:(NSString *)_jobId:(NSString *)_comment {
  return [self _setJobStatus:@"reject" forJobId:_jobId withComment:_comment];
}

- (id)jobs_reactivateJobAction:(NSString *)_jobId:(NSString *)_comment {
  return [self _setJobStatus:@"reactivate" forJobId:_jobId
               withComment:_comment];
}

/* fetching jobs */

- (id)_getJobsWithCommand:(NSString *)_jobCommand
  forPersonWithURL:(NSString *)_personURL
  iDsAndVersion:(BOOL)_iDsAndVersion
{
  /* the result of this method is directly used as an XML-RPC result */
  LSCommandContext *ctx;
  NSArray *result;
  id   object;
  BOOL isTeamSelected = NO;
  
  if ((ctx = [self commandContext]) == nil)
    return [self invalidCommandContextFault];

  /* fetch and handle person or team */
  
  object = nil;
  if ([_personURL isNotNull]) {
    id person;
    
    if (![self isCurrentUserRoot]) {
      return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_PARAMETER
		   reason:@"Only 'root' can fetch jobs of other users"];
    }
    
    person = [[ctx documentManager] globalIDForURL:_personURL];
    
    if (person != nil) {
      NSString *command;
        
      if ([[person entityName] isEqualToString:@"Person"])
	command = @"person::get-by-globalid";
      else {
	command = @"team::get-by-globalid";
	isTeamSelected = YES;
      }
      object = [[ctx runCommand:command, @"gid", person, nil] lastObject];
    }
  }
  else
    object = [ctx valueForKey:LSAccountKey];

  if ([object isNotNull] && !isTeamSelected) {
    object = [ctx runCommand:@"account::get-by-login",
                    @"login", [object valueForKey:@"login"],
                    nil];
  }
  
  if (![object isNotNull]) {
    // TODO: improve
    return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_PARAMETER
		 reason:@"could not determine object for job command!"];
  }

  /* process jobs */
  
  if (!_iDsAndVersion) {
    result = [ctx runCommand:_jobCommand, @"object", object, nil];
  }
  else {
    result = [ctx runCommand:_jobCommand,
		    @"object", object,
		    @"fetchGlobalIDs", [NSNumber numberWithBool:YES],
		  nil];
  }

  if (![self commitTaskTransaction]) {
    return [self faultWithFaultCode:XMLRPC_FAULT_INTERNAL_ERROR
		 reason:@"could not commit transaction"];
  }

  if (!_iDsAndVersion)
    return [self _jobDocumentsForEORecords:result];
  
  /* just IDs and versions */
  {
    NSArray *urls;
    NSArray *versions;
    int counter;
    int urlCount;

    urlCount = [result count];
    urls     = [[ctx documentManager] urlsForGlobalIDs:result];
    versions = [ctx runCommand:@"job::get-by-globalid",
		      @"gids", result,
		      @"attributes",[NSArray arrayWithObject:@"objectVersion"],
		    nil];

    for (counter = 0; counter < urlCount; counter++) {
      NSMutableDictionary *dict;

      dict = [versions objectAtIndex:counter];
      [dict removeObjectForKey:@"jobId"];
      [dict takeValue:[urls objectAtIndex:counter] forKey:@"id"];
    }
    return versions;
  }
}

- (id)jobs_getToDoListAction:(NSNumber *)_iDsAndVersion
  :(NSString *)_personURL
{
  return [self _getJobsWithCommand:@"job::get-todo-jobs"
               forPersonWithURL:_personURL
               iDsAndVersion:[_iDsAndVersion boolValue]];
}

- (id)jobs_getDelegatedJobsAction:(NSNumber *)_iDsAndVersion
  :(NSString *)_personURL
{
  return [self _getJobsWithCommand:@"job::get-delegated-jobs"
               forPersonWithURL:_personURL
               iDsAndVersion:[_iDsAndVersion boolValue]];
}

- (id)jobs_getArchivedJobsAction:(NSNumber *)_iDsAndVersion
  :(NSString *)_personURL
{
  return [self _getJobsWithCommand:@"job::get-archived-jobs"
               forPersonWithURL:_personURL
               iDsAndVersion:[_iDsAndVersion boolValue]];
}

- (id)jobs_getJobsAction:(NSArray *)_urls {
  LSCommandContext *ctx;
  NSArray *gids;
  id      result;
  
  if (![_urls isNotNull]) {
    return [self faultWithFaultCode:XMLRPC_FAULT_MISSING_PARAMETER
		 reason:@"missing URLs parameter"];
  }
  
  if (![_urls isKindOfClass:[NSArray class]])
    _urls = [NSArray arrayWithObject:_urls];
  
  if ((ctx = [self commandContext]) == nil)
    return [self invalidCommandContextFault];
  
  if ((gids =  [[ctx documentManager] globalIDsForURLs:_urls]) == nil) {
    return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_PARAMETER
		 reason:@"did not find specified URLs"];
  }
  
  result = [ctx runCommand:@"job::get-by-globalid", @"gids", gids, nil];
  if (![self commitTaskTransaction]) {
    return [self faultWithFaultCode:XMLRPC_FAULT_INTERNAL_ERROR
		 reason:@"could not commit transaction"];
  }
  
  if (result != nil)
    return [self _jobDocumentsForEORecords:result];
  
  return [self faultWithFaultCode:XMLRPC_FAULT_INTERNAL_ERROR
	       reason:@"got no tasks for specified URLs"];
}

- (id)jobs_deleteJobAction:(NSString *)_jobId {
  LSCommandContext *ctx;
  EOGenericRecord  *job;

  if ((ctx = [self commandContext]) == nil)
    return [self invalidCommandContextFault];
  
  if ((job = [self getJobByGlobalID:_jobId]) == nil) {
    return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_PARAMETER
		 reason:@"Could not find task with given ID"];
  }
  
  [ctx runCommand:@"job::delete", @"object", job, nil];
  
  return [NSNumber numberWithBool:[self commitTaskTransaction]];
}

@end /* DirectAction(JobMethods) */

@interface DirectAction(JobPrivates)
- (void)_takeValuesDict:(NSDictionary *)_from toJob:(SkyJobDocument **)_to;
- (NSArray *)_fetchJobsOf:(id)_doc fSpec:(id)_fSpec;
- (NSArray *)_fetchJobIdsOf:(id)_doc fSpec:(id)_fSpec;
- (SkyJobDocument *)_insertJob:(id)_job intoDoc:(id)_doc;
- (SkyJobDocument *)_updateJob:(id)_job inDoc:(id)_doc;
- (NSException *)_deleteJob:(id)_job inDoc:(id)_doc;

- (id)jobs_deleteJobAction:(NSString *)_jobId;

@end /* DirectAction(JobPrivates) */

@interface DirectAction(JobPerson)
- (SkyPersonDocument *)_getPersonByArgument:(id)_arg;
@end

@implementation DirectAction(PersonJobs)

- (NSArray *)person_fetchJobsAction:(id)_person :(id)_fSpec {
  return [self _fetchJobsOf:[self _getPersonByArgument:_person] fSpec:_fSpec];
}

- (NSArray *)person_fetchJobIdsAction:(id)_person :(id)_fSpec {
  return [self _fetchJobIdsOf:[self _getPersonByArgument:_person]
               fSpec:(id)_fSpec];
}

- (id)person_insertJobAction:(id)_person :(id)_job {
  return [self _insertJob:_job intoDoc:[self _getPersonByArgument:_person]];
}

- (id)person_updateJobAction:(id)_person :(id)_job {
  return [self _updateJob:_job inDoc:[self _getPersonByArgument:_person]];
}

- (id)person_deleteJobAction:(id)_person:(id)_job {
  // TODO: DEPRECATED
  /* TODO: I guess we should remove that method */
  id tmp;
  
  if ((tmp = [self _getPersonByArgument:_person]) == nil) {
    return [self faultWithFaultCode:XMLRPC_FAULT_MISSING_PARAMETER
		 reason:@"did not find specified person"];
  }

  return [self jobs_deleteJobAction:_job];
}

@end /* DirectAction(PersonJobs) */


@implementation DirectAction(ProjectJobs)

- (NSArray *)project_fetchJobsAction:(id)_person :(id)_fSpec {
  /* TODO: hh: NOT IMPLEMENTED ??  */
  /* TODO: hh: person argument ??? */
  return [NSArray array];
  // TODO: ???
  return [self _fetchJobsOf:[self _getPersonByArgument:_person] fSpec:_fSpec];
}

- (id)project_insertJobAction:(id)_person :(id)_job {
  /* TODO: hh: person argument ??? */
  return [self _insertJob:_job intoDoc:nil];
}

- (id)project_updateJobAction:(id)_person :(id)_job {
  /* TODO: hh: person argument ??? */
  return [self _updateJob:_job inDoc:nil];
}

- (id)project_deleteJobAction:(id)_project:(id)_job {
  // DEPRECATED
  return [self jobs_deleteJobAction:_job];
}

@end /* DirectAction(ProjectJobs) */

@implementation DirectAction(JobPrivate)

- (void)_takeValuesDict:(NSDictionary *)_from toJob:(SkyJobDocument **)_to {
  [*_to takeValuesFromObject:_from
        keys:@"name", @"startDate", @"endDate", @"category", @"jobStatus",
	@"priority", @"type", @"comment", nil];
}

- (NSArray *)_fetchJobsOf:(id)_doc fSpec:(id)_fSpec {
  EODataSource         *jobDS;
  NSArray              *jobs;
  EOFetchSpecification *fSpec;

  jobDS  = [_doc jobDataSource];
  fSpec = [[EOFetchSpecification alloc] initWithBaseValue:_fSpec];
  [fSpec setEntityName:@"Job"];
  [jobDS setFetchSpecification:fSpec];
  [fSpec release]; fSpec = nil;
  
  jobs = [jobDS fetchObjects];
  return [jobs isNotNull] ? jobs : [NSArray array];
}

- (NSArray *)_fetchJobIdsOf:(id)_doc fSpec:(id)_fSpec {
  EOFetchSpecification *fspec;
  NSMutableDictionary  *hints;
  EODataSource         *jobDS;
  
  jobDS    = [_doc jobDataSource];
  fspec    = [[EOFetchSpecification alloc] initWithBaseValue:_fSpec];
  [fspec setEntityName:@"Job"];
  hints    = [NSMutableDictionary dictionaryWithDictionary:[fspec hints]];
  [hints setObject:[NSNumber numberWithBool:YES] forKey:@"fetchGlobalIDs"];
  [fspec setHints:hints];
  
  [jobDS setFetchSpecification:fspec];
  
  [fspec release];
  
  return [[[self commandContext] documentManager]
                 urlsForGlobalIDs:[jobDS fetchObjects]];
}

- (id)_insertJob:(NSDictionary *)_job intoDoc:(id)_doc {
  EODataSource   *jobDS = [_doc jobDataSource];
  SkyJobDocument *job   = nil;

  if ([[_job valueForKey:@"name"] length] == 0) {
    return [self faultWithFaultCode:XMLRPC_FAULT_MISSING_PARAMETER
                 reason:@"tried to create a job without a 'name' attribute"];
  }
  
  job = [jobDS createObject];
  NSAssert(job, @"couldn't create job");
  [self _takeValuesDict:_job toJob:&job];

  [jobDS insertObject:job];
  
  return job;
}

- (SkyJobDocument *)_updateJob:(id)_job inDoc:(id)_doc {
  SkyJobDocument *job = nil;

  job = (SkyJobDocument *)[self getDocumentByArgument:_job];
  
  if (![job isKindOfClass:[SkyJobDocument class]]) return nil;
  
  if (job != nil) {
    [self _takeValuesDict:_job toJob:&job];
    [[_doc jobDataSource] updateObject:job];
  }
  return job;
}

- (NSException *)_deleteJob:(id)_job inDoc:(id)_doc {
  SkyJobDocument *job;
  EODataSource   *ds;
  
  if ((job = (SkyJobDocument *)[self getDocumentByArgument:_job]) == nil) {
    return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_PARAMETER
		 reason:@"did not find specified task"];
  }
  if ((ds = [_doc jobDataSource]) == nil) {
    return [self faultWithFaultCode:XMLRPC_FAULT_INTERNAL_ERROR
		 reason:@"did not find task datasource in source object"];
  }
  
  [[_doc jobDataSource] deleteObject:job];
  return nil;
}

@end /* DirectAction(JobPrivate) */

