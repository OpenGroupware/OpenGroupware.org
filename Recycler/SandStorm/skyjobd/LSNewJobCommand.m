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

#import <LSFoundation/LSDBObjectNewCommand.h>

@class NSString;

@interface LSNewJobCommand : LSDBObjectNewCommand
{
  id       parentProcess;
  id       parentJob;
  id       project;
  id       executant;
  NSString *comment;
  NSString *divideComment;
  NSString *assignmentKind;
}
@end

#import "common.h"

@interface LSNewJobCommand(PrivateMethodes)
- (NSArray *)_sortedChildProcessesOf:parent inContext:_context;
- (NSArray *)_getChildsOf:(id)_object inContext:(id)_context;
- (void)_updateParent:(id)_parent inContext:(id)_context;
@end

@implementation LSNewJobCommand

static int comparePos(id jobAss1, id jobAss2, void *context) {
  NSNumber *pos1 = [jobAss1 valueForKey:@"position"];
  NSNumber *pos2 = [jobAss2 valueForKey:@"position"];
  
  if (pos1 == nil)
    return NSOrderedAscending;
  if (pos2 == nil)
    return NSOrderedDescending;
  return [pos1 compare:pos2];
}

- (id)initForOperation:(NSString *)_operation inDomain:(NSString *)_domain {
  if ((self = [super initForOperation:_operation inDomain:_domain])) {
    [self takeValue:@"00_created"  forKey:@"logAction"];
    [self takeValue:@"Job created" forKey:@"logText"];
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->project); 
  RELEASE(self->parentJob); 
  RELEASE(self->comment); 
  RELEASE(self->divideComment);
  RELEASE(self->assignmentKind);
  [super dealloc];
}
#endif

- (void)_checkStartDateIsBeforeEndDate {
  NSCalendarDate *startDate = [self valueForKey:@"startDate"];
  NSCalendarDate *endDate   = [self valueForKey:@"endDate"];

  if ([startDate compare:endDate] == NSOrderedDescending) {
    [self takeValue:startDate forKey:@"endDate"];
    [self takeValue:endDate forKey:@"startDate"];
  }
}

- (void)_newJobHistoryInContext:(id)_context {
  id job  = [self object];

  if (![[job valueForKey:@"executantId"]
             isEqual:[job valueForKey:@"creatorId"]]) {
    id user = [_context valueForKey:LSAccountKey];
    id nCmd = LSLookupCommand(@"JobHistory", @"new");

    [nCmd takeValue:LSJobCreated                    forKey:@"action"]; 
    [nCmd takeValue:[job valueForKey:@"jobId"]      forKey:@"jobId"]; 
    [nCmd takeValue:[user valueForKey:@"companyId"] forKey:@"actorId"]; 
    [nCmd takeValue:[NSCalendarDate calendarDate]   forKey:@"actionDate"];
    [nCmd takeValue:[job valueForKey:@"jobStatus"]  forKey:@"jobStatus"];
    [nCmd takeValue:self->comment                   forKey:@"comment"];
    [nCmd runInContext:_context];
  }
}

- (void)_newControlJobInContext:(id)_context {
  id o = [self object];
  id cid;

  cid = [o valueForKey:@"creatorId"];
  
  if (![self->parentJob isNotNull] &&
      ![[o valueForKey:@"executantId"] isEqual:cid]) {
    LSRunCommandV(_context, @"job",@"controlJob",
                  @"object",    o,
                  @"project",   self->project,
                  @"comment",   self->comment,
                  @"executant", self->executant, nil);
  }
}

#if 0
- (void)_validateKeysForContext:(id)_context {
  if (!self->project && !self->parentJob) 
    [LSDBObjectCommandException raiseOnFail:NO object:self
                                reason:@"no project and no parentJob!"];
  [super _validateKeysForContext:_context];
}
#endif

- (void)_prepareForExecutionInContext:(id)_context {
  id user = [_context valueForKey:LSAccountKey];
  
  [self _checkStartDateIsBeforeEndDate];

  [self takeValue:LSJobCreated                    forKey:@"jobStatus"];
  [self takeValue:[user valueForKey:@"companyId"] forKey:@"creatorId"];

  if (self->executant)
    [self takeValue:[self->executant valueForKey:@"companyId"]
          forKey:@"executantId"];

  if (self->project)
    [self takeValue:[self->project valueForKey:@"projectId"]
          forKey:@"projectId"];

  if (self->parentJob)
    [self takeValue:[self->parentJob valueForKey:@"jobId"]
          forKey:@"parentJobId"];
  
  [super _prepareForExecutionInContext:_context];
}

- (void)_executeMoreActionInContext:(id)_context {
  id job = [self object];

  if ([[job valueForKey:@"parentJobId"] isNotNull]) {
    LSRunCommandV(_context,
                  @"job",           @"jobaction",
                  @"action",        @"divided",
                  @"object",        job,
                  @"comment",       self->comment,
                  @"divideComment", self->divideComment, nil);
  }
  if ([[job valueForKey:@"executantId"]
            isEqual:[job valueForKey:@"creatorId"]]) {
    LSRunCommandV(_context,
                  @"job", @"jobaction",
                  @"action", @"accept",
                  @"object", job,
                  @"comment", self->comment, nil);
  }
}

- (void)_executeInContext:(id)_context {
  [self  _newControlJobInContext:_context];
  [super _executeInContext:_context];
  [self  _newJobHistoryInContext:_context];  
  [self  _executeMoreActionInContext:_context];

  LSRunCommandV(_context, @"object", @"add-log",
                @"logText"    , [self valueForKey:@"logText"],
                @"action"     , [self valueForKey:@"logAction"],
                @"objectToLog", [self object],
                nil);
  
  if (self->parentProcess != nil) {
    id  parent = self->parentProcess;
    int pos;
    
    LSRunCommandV(_context, @"job", @"get",
                  @"jobId", [parent valueForKey:@"jobId"], nil);

    pos = [[self _getChildsOf:parent inContext:_context] count] + 1;
    
    if (![self->assignmentKind isEqualToString:LSParallelProcess])
      ASSIGN(self->assignmentKind, LSSequentialProcess);

    LSRunCommandV(_context, @"jobassignment", @"new",
                  @"parentJobId",    [parent valueForKey:@"jobId"],
                  @"childJobId",     [[self object] valueForKey:@"jobId"],
                  @"position",       [NSNumber numberWithInt:pos],
                  @"assignmentKind", self->assignmentKind, nil);

    [self _updateParent:parent inContext:_context];
    
    LSRunCommandV(_context, @"job", @"get",
                  @"jobId", [parent valueForKey:@"jobId"], nil);
  }
}

// process dependencies are saved in job_assignment table
- (void)setParentProcess:(id)_parentProcess {
  ASSIGN(self->parentProcess, _parentProcess);
}
- (id)parentProcess {
  return self->parentProcess;
}

- (void)setCreateAs:(NSString *)_assignmentKind {
  ASSIGN(self->assignmentKind, _assignmentKind);
}
- (NSString *)assignmentKind {
  return self->assignmentKind;
}

- (void)setParentJob:(id)_parentJob {
  ASSIGN(self->parentJob, _parentJob);
}
- (id)parentJob {
  return self->parentJob;
}

- (void)setProject:(id)_project {
  ASSIGN(self->project, _project);
}
- (id)project {
  return self->project;
}

- (void)setDivideComment:(NSString *)_comment {
  if (self->divideComment != _comment) {
    RELEASE(self->divideComment);
    self->divideComment = [_comment copyWithZone:[self zone]];
  }
}
- (NSString *)divideComment {
  return self->divideComment;
}

- (void)setComment:(id)_comment {
  ASSIGN(self->comment, _comment);
}
- (id)comment {
  return self->comment;
}

- (void)setExecutant:(id)_executant {
  ASSIGN(self->executant, _executant);
}
- (id)executant {
  return self->executant;
}

// initialize records

- (NSString *)entityName {
  return @"Job";
}

// key/value coding

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"parentProcess"])
    [self setParentProcess:_value];
  else if ([_key isEqualToString:@"assignmentKind"])
    [self setCreateAs:_value];
  else if ([_key isEqualToString:@"toParentJob"])
    [self setParentJob:_value];
  else if ([_key isEqualToString:@"toProject"] ||
             [_key isEqualToString:@"project"]) {
    [self setProject:_value];
    return;
  }
  else if ([_key isEqualToString:@"executant"])
    [self setExecutant:_value];
  else if ([_key isEqualToString:@"comment"])
    [self setComment:_value];
  else if ([_key isEqualToString:@"divideComment"])
    [self setDivideComment:_value];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"parentProcess"])
    return [self parentProcess];
  else if ([_key isEqualToString:@"toParentJob"])
    return [self parentJob];
  else if ([_key isEqualToString:@"toProject"] ||
           [_key isEqualToString:@"project"])
    return [self project];
  else if ([_key isEqualToString:@"executant"])
    return [self executant];
  else if ([_key isEqualToString:@"comment"])
    return [self comment];
  else if ([_key isEqualToString:@"divideComment"])
    return [self divideComment];
  else
    return [super valueForKey:_key];
}

// --- LSNewJobCommand(PrivateMethodes) ----------------------------------

- (NSArray *)_getChildsOf:(id)_object inContext:(id)_context {
  return LSRunCommandV(_context, @"job", @"get-subprocesses",
                       @"object", _object, nil);
}

- (NSArray *)_sortedChildProcessesOf:(id)_object inContext:(id)_context {
  id  assigns = [self _getChildsOf:_object inContext:_context];
  int i, cnt  = [assigns count];

  assigns = [assigns sortedArrayUsingFunction:comparePos context:NULL];

  for (i=0; i<cnt; i++) {
    id  assign = [assigns objectAtIndex:i];
    int pos    = [[assign valueForKey:@"position"] intValue];
    
    if (i+1 != pos) {
      [assign takeValue:[NSNumber numberWithInt:i+1] forKey:@"position"];
      LSRunCommandV(_context, @"jobassignment", @"set", @"object", assign, nil);
    }
  }
  return assigns;
}

- (NSCalendarDate *)_update:(id)_process with:(NSCalendarDate *)_startDate
                     inContext:(id)_context {
  NSCalendarDate *startDate = [_process valueForKey:@"startDate"];
  NSCalendarDate *endDate   = [_process valueForKey:@"endDate"];
  NSTimeInterval deltaT     = [endDate timeIntervalSinceDate:startDate];

  endDate = [_startDate addTimeInterval:deltaT];
  
  [_process takeValue:_startDate forKey:@"startDate"];
  [_process takeValue:endDate    forKey:@"endDate"];

  LSRunCommandV(_context, @"job", @"set", @"object", _process, nil);
  
  return endDate;
}

- (void)_updateParent:(id)_parent inContext:(id)_context {
  NSArray *assigns = [self _sortedChildProcessesOf:_parent inContext:_context];
  int     i, cnt   = [assigns count];
  NSCalendarDate *parentStartDate = [_parent valueForKey:@"startDate"];
  NSCalendarDate *startDate       = parentStartDate;

  for (i=0; i<cnt; i++) {
    id a     = [assigns objectAtIndex:i];
    id child = [a valueForKey:@"toChildJob"];

    if ([[a valueForKey:@"assignmentKind"] isEqualToString:LSParallelProcess]) {
      id tmp = [self _update:child with:parentStartDate inContext:_context];
      startDate = (NSCalendarDate *)[startDate laterDate:tmp];
    }
    else if (![startDate isEqualToDate:[child valueForKey:@"startDate"]])
      startDate = [self _update:child with:startDate inContext:_context];
    else
      startDate = [child valueForKey:@"endDate"];

  }
}


@end
