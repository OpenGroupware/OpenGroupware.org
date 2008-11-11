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

#include "LSWJobImport.h"
#include <OGoFoundation/LSWNotifications.h>
#include "common.h"

static NSString *Resume = @"resume";

@implementation LSWJobImport

static NSDictionary *emptyEntry  = nil;
static NGMimeType   *dictJobType = nil;

+ (void)initialize {
  if (emptyEntry == nil) {
    emptyEntry = [[NSDictionary alloc] initWithObjectsAndKeys:
					 @"-- empty --", @"name",
				         @"YES"        , @"isEmpty",
				       nil];
  }
  if (dictJobType == nil)
    dictJobType = [[NGMimeType mimeType:@"dict" subType:@"job"] retain];
}

- (id)init {
  if ((self = [super init])) {
    NSMutableArray *array = nil;
    
    self->jobs        = [[NSMutableArray alloc] initWithCapacity:16];
    self->importField = YES;
    
    array = [[NSMutableArray alloc] initWithObjects:&emptyEntry count:1];
    [array addObjectsFromArray:
             [[[self session] activeAccount] run:@"job::get-todo-jobs", nil]];
    self->parentJobList = array;
  }
  return self;
}

- (void)dealloc {
  [self->data              release];
  [self->jobs              release];
  [self->selectedAttribute release];
  [self->project           release];
  [self->job               release];
  [self->selectedParentJob release];
  [self->item              release];
  [self->parentJobList     release];
  [self->importAnnotation  release];
  [self->errorReport       release];
  [self->currentError      release];
  [self->currentErrorName  release];
  [super dealloc];
}

/* activation */

- (BOOL)prepareForActivationCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  // TODO: no supercall?
  if (self->project)
    [self->project release];
  self->project = [[[self session] getTransferObject] retain];
  
  if (self->importAnnotation)
    [self->importAnnotation release];
  
  self->importAnnotation = 
    [[[self labels] valueForKey:@"ImportAnnotation"] retain];
  return YES;
}

/* actions */

- (id)import {
  NSArray *j = nil;
  /*
    self->data = @"hallo|du|1999-1-1|2000-2-1\n"
    @"halllo|da|1999-1-3|2000-2-2\n"    
    @"hal|hallo|1999-4|2000-2-2\n"
    @"hal||1999-1-2|2000-2-2\n"
    @"|da|1999-1-3|2000-2-2\n"    
    @"hallo|2000-2-2\n"
    @"0-2\n"
    @"hal||1999-1-6|20-2";
  */
  if ((self->data != nil) && [self->data isNotNull]) {
    if (self->errorReport)
      [self->errorReport release];

    self->errorReport = [[NSMutableDictionary alloc] init];
  
    j = [self runCommand:@"job::import",
              @"data",        self->data,
              @"accounts",    [[self session] valueForKey:@"accounts"],
              @"errorReport", self->errorReport, nil];

    if (![self commit]) {
      [self setErrorString:@"Couldn't commit job::import command (rollback)!"];
      [self rollback];
      return nil;
    }

    { // set resume value and project
      int      i, cnt;
      IMP      objAtIdx;
      NSNumber *number;
      id       projId;

      objAtIdx = [j methodForSelector:@selector(objectAtIndex:)];
      number   = [NSNumber numberWithBool:NO];
      projId   = [self->project valueForKey:@"projectId"];
      
      NSAssert(projId != nil, @"no projectId");
    
      for (i = 0, cnt = [j count]; i < cnt; i++) {
        id obj, execId;

        execId = [[obj objectForKey:@"executant"] valueForKey:@"companyId"];
        obj    = objAtIdx(j, @selector(objectAtIndex:), i);
        
        NSAssert(execId != nil, @"no executantId");
      
        [obj setObject:number forKey:Resume];
        [obj setObject:self->project forKey:@"toProject"];
        [obj setObject:projId forKey:@"projectId"];
        [obj setObject:execId forKey:@"executantId"];            
      }
    }

    [self _setImportAnnotation:j];
  
    [self->jobs addObjectsFromArray:j];
    {
      id dum;

      dum = self->jobs;
      self->jobs = [self->jobs mutableCopy];
      [dum release]; dum = nil;
    }
    self->showErrors = ([self->errorReport count] > 0) ? YES : NO;
  }
  self->importField = NO;
  return nil;
}

void _setParentJob(LSWJobImport *self, NSArray *_jobs, id _parent) {
  SEL      _cmd = @selector(_setParentJob);
  int      i,cnt;
  IMP      objAtIdx;
  NSNumber *parentId;

  parentId = [_parent valueForKey:@"jobId"];

  NSAssert(self     != nil, @"no self is set");  
  NSAssert(_parent  != nil, @"no parent is set");
  NSAssert1(parentId != nil, @"no parentId from parent %@", _parent);

  objAtIdx = [_jobs methodForSelector:@selector(objectAtIndex:)];

  for (i = 0, cnt = [_jobs count]; i < cnt; i++) {
    [objAtIdx(_jobs, @selector(objectAtIndex:), i)
             setObject:_parent
             forKey:@"toParentJob"];
    [objAtIdx(_jobs, @selector(objectAtIndex:), i)
             setObject:parentId
             forKey:@"toParentJobId"];
  }
}

- (void)_createJob:(id)_job jobs:(id)_jobs {
  id jobId     = nil;
  
  if ([_job valueForKey:@"jobId"])
    return;

  jobId = [[self runCommand:@"job::new" arguments:_job] valueForKey:@"jobId"];
  if ([self commit]) {
    [_job setObject:jobId forKey:@"jobId"];
  }
  else {
    [self setErrorString:@"couldn't commit job::new command (rollback) !"];
    [self rollback];
  }
}

- (void)_saveJobs:(NSArray *)_jobs {
  NSAssert(self != nil, @"no self");
  
  if ([_jobs count] == 0) {
    [self leavePage];
    return;
  }

  if ([self->selectedParentJob valueForKey:@"isEmpty"] == nil) {
    _setParentJob(self, _jobs, self->selectedParentJob);
  }
  else if (self->oneControlJob) {
      NSMutableDictionary *fakeJob   = nil;
      NSDate              *startDate = nil;
      NSDate              *endDate   = nil;
      NSDictionary        *j;
      id                  parentJob  = nil;
      EOGenericRecord     *rec       = nil;

      j = [_jobs objectAtIndex:0];
      
      rec = [[EOGenericRecord alloc] init];
      startDate = [j objectForKey:@"startDate"];
      endDate   = [j objectForKey:@"endDate"];
      NSAssert(startDate && endDate, @"No start-[%@] or endate[%@]  is set");
      fakeJob = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     startDate, @"startDate",
                                     endDate,   @"endDate", nil];
      [rec takeValue:startDate forKey:@"startDate"];
      parentJob = [fakeJob run:@"job::controlJob",
                             @"project", self->project,
                             @"comment", self->importAnnotation,
                             @"name",    @"Job Import",
                             nil];
      [rec release]; rec = nil;
      NSAssert(parentJob != nil, @"no controljob");
      _setParentJob(self, _jobs, parentJob);
    }
    { // create jobs 
      int i, cnt;
      IMP objAtIdx;

      cnt      = [_jobs count];
      objAtIdx = [_jobs methodForSelector:@selector(objectAtIndex:)];
      
      for (i = 0; i < cnt; i++) {
        [self _createJob:objAtIdx(_jobs, @selector(objectAtIndex:), i)
	      jobs:_jobs];
      }
    }
  [self postChange:LSWJobHasChanged onObject:self->project];
  [self leavePage];  
}


- (id)resumeSelected {
  NSMutableArray *mArray = nil;
  IMP            addObj;
  IMP            objAtIdx;
  int            i, cnt;
  
  mArray   = [[NSMutableArray alloc] initWithCapacity:16];
  addObj   = [mArray methodForSelector:@selector(addObject:)];
  objAtIdx = [jobs methodForSelector:@selector(objectAtIndex:)];

  for (i = 0, cnt = [jobs count]; i < cnt; i++) {
    id o;

    o = objAtIdx(jobs, @selector(objectAtIndex:), i);
    if ([[o valueForKey:Resume] boolValue])
      addObj(mArray, @selector(addObject:), o);
  }
  [self _saveJobs:mArray];
  [mArray release]; mArray = nil;
  return nil;
}

- (id)resumeAll {
  [self _saveJobs:self->jobs];
  return nil;
}

- (id)viewExecutant {
  // TODO: replace with GID activation
  return [self activateObject:[self->job valueForKey:@"executant"]
	       withVerb:@"view"];
}

- (id)viewProject {
  // TODO: replace with GID activation
  return [self activateObject:[self->job valueForKey:@"toProject"]
	       withVerb:@"view"];
}

- (NSFormatter *)startDateFormatter {
  return [[self session] formatterForValue:
                         [self->job valueForKey:@"startDate"]];
}

- (NSFormatter *)endDateFormatter {
  return [[self session] formatterForValue:[self->job valueForKey:@"endDate"]];
}

- (NSString *)bodyCellColor {
  return (self->count % 2 == 1)
    ? [[self config] valueForKey:@"colors_evenRow"]
    : [[self config] valueForKey:@"colors_oddRow"];
}

- (NSString *)errorBodyCellColor {
  return (self->errorCount % 2 == 1)
    ? [[self config] valueForKey:@"colors_errorEvenRow"]
    : [[self config] valueForKey:@"colors_errorOddRow"];
}

- (id)editJob {
  id cp = nil;

  [[self session] transferObject:self->job owner:self];  
  cp = [[self session] instantiateComponentForCommand:@"edit"
                       type:dictJobType];
  [self enterPage:cp];
  return nil;
}

- (void)_setImportAnnotation:(NSArray *)_import {
  int i, cnt;
  IMP objAtIdx;

  objAtIdx = [_import methodForSelector:@selector(objectAtIndex:)];
  for (i = 0, cnt = [_import count]; i < cnt; i++) {
    [objAtIdx(_import, @selector(objectAtIndex:), i)
             setObject:self->importAnnotation forKey:@"comment"];
  }
}

- (id)setImportAnnotation {
  [self _setImportAnnotation:self->jobs];
  return nil;
}

- (id)showErrorsAction {
  self->showErrors = YES;
  return nil;
}

- (id)hideErrorsAction {
  self->showErrors = NO;
  return nil;  
}

/* accessors */

- (NSArray *)errorMainRepetition {
  return [self->errorReport allKeys];
}

- (NSArray *)errorSubRepetition {
  return [self->errorReport objectForKey:self->currentErrorName];
}

- (BOOL)importField {
  return self->importField;
}

- (id)cancel {
  [self leavePage];
  return nil;
}

- (BOOL)oneControlJob {
  return self->oneControlJob;
}
- (void)setOneControlJob:(BOOL)_oneControlJob {
  self->oneControlJob = _oneControlJob;
}

- (BOOL)relShowErrors {
  return (!self->showErrors && ([self->errorReport count] > 1));
}

- (BOOL)showErrors {
  return self->showErrors;
}
- (void)setShowErrors:(BOOL)_errors {
  self->showErrors = _errors;
}

- (id)currentError {
  return self->currentError;
}
- (void)setCurrentError:(NSString *)_error {
  ASSIGN(self->currentError, _error);
}

- (id)currentErrorName {
  return self->currentErrorName;
}
- (void)setCurrentErrorName:(NSNumber *)_error {
  ASSIGN(self->currentErrorName, _error);
}

- (id)parentJobList {
  return self->parentJobList;
}
- (void)setParentJobList:(id)_parentJobList {
  ASSIGN(self->parentJobList, _parentJobList);
}

- (id)item {
  return self->item;
}
- (void)setItem:(id)_item {
  ASSIGN(self->item, _item);
}

- (id)selectedParentJob {
  return self->selectedParentJob;
}
- (void)setSelectedParentJob:(id)_job {
  ASSIGN(self->selectedParentJob, _job);
}

- (id)job {
  return self->job;
}
- (void)setJob:(id)_job {
  ASSIGN(self->job, _job);
}

- (id)importAnnotation {
  return self->importAnnotation;
}
- (void)setImportAnnotation:(id)_an {
  ASSIGN(self->importAnnotation, _an);
}

- (int)start {
  return self->start;
}
- (void)setStart:(int)_start {
  self->start = _start;
}

- (id)selectedAttribute {
  return self->selectedAttribute;
}
- (void)setSelectedAttribute:(id)_selectedAttribute {
  ASSIGN(self->selectedAttribute, _selectedAttribute);
}

- (id)jobs {
  return self->jobs;
}
- (id)path {
  return @"";
}
- (void)setPath:(id)_path {
}

- (id)project {
  return self->project;
}
- (void)setProject:(id)_project {
  ASSIGN(self->project, _project);
}

- (id)data {
  return self->data;
}
- (void)setData:(id)_data {
  ASSIGN(self->data, _data);
}

- (void)setCount:(int)_count {
  self->count = _count;
}
- (int)count {
  return self->count;
}

- (void)setErrorCount:(int)_count {
  self->errorCount = _count;
}
- (int)errorCount {
  return self->errorCount;
}

@end /* LSWJobImport */
