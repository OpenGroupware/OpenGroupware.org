/*
  Copyright (C) 2000-2003 SKYRIX Software AG

  This file is part of OGo

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

#import <LSFoundation/LSDBObjectSetCommand.h>

@class NSString;

@interface LSJobActionCommand : LSDBObjectSetCommand
{
  NSString *action;
  NSString *comment;
  NSString *divideComment;
}

- (void)setAction:(NSString *)_action;
- (NSString *)action;
- (void)setComment:(NSString *)_comment;
- (NSString *)comment;

@end

#import "common.h"

extern NSString *LSWJobHasChanged;

@implementation LSJobActionCommand

- (id)initForOperation:(NSString *)_operation inDomain:(NSString *)_domain {
  if ((self = [super initForOperation:_operation inDomain:_domain])) {
    [self takeValue:@"05_changed"  forKey:@"logAction"];
    [self takeValue:@"Job changed" forKey:@"logText"];
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->action);
  RELEASE(self->comment);
  RELEASE(self->divideComment);
  [super dealloc];
}
#endif

- (void)_commentJobInContext:(id)_context {
  id job  = [self object];

  LSRunCommandV(_context, @"JobHistory", @"new",
                @"jobId",      [job valueForKey:@"jobId"],
                @"action",     LSJobCommented,
                @"actorId",    [[_context valueForKey:LSAccountKey]
                                          valueForKey:@"companyId"],
                @"jobStatus",  [job valueForKey:@"jobStatus"],
                @"actionDate", [NSCalendarDate date],
                @"comment",    self->comment?:@"",
                nil);
}

- (void)_acceptJobInContext:(id)_context {
  id job  = [self object];

  LSRunCommandV(_context, @"JobHistory", @"new",
                @"jobId",      [job valueForKey:@"jobId"],
                @"action",     LSJobAccepted,
                @"actorId",    [[_context valueForKey:LSAccountKey]
                                          valueForKey:@"companyId"],
                @"jobStatus",  [job valueForKey:@"jobStatus"],
                @"actionDate", [NSCalendarDate date],
                @"comment",    self->comment?:@"",
                nil);
}

- (void)_doneJobInContext:(id)_context {
  id job  = [self object];

  LSRunCommandV(_context, @"JobHistory", @"new",
                @"jobId",      [job valueForKey:@"jobId"],
                @"action",     LSJobDone,
                @"actorId",    [[_context valueForKey:LSAccountKey]
                                          valueForKey:@"companyId"],
                @"jobStatus",  [job valueForKey:@"jobStatus"],
                @"actionDate", [NSCalendarDate date],
                @"comment",    self->comment?:@"",                
                nil);
  
}

- (void)_archiveJobInContext:(id)_context {
  id job  = [self object];

  LSRunCommandV(_context, @"JobHistory", @"new",
                @"jobId",      [job valueForKey:@"jobId"],
                @"action",     LSJobArchived,
                @"actorId",    [[_context valueForKey:LSAccountKey]
                                          valueForKey:@"companyId"],
                @"jobStatus",  [job valueForKey:@"jobStatus"],
                @"actionDate", [NSCalendarDate date],
                @"comment",    self->comment?:@"",                
                nil);
  LSRunCommandV(_context,@"job", @"archive",
                @"comment",    self->comment?:@"",
                @"object" ,    job,
                nil);
}

- (void)_reactivateJobInContext:(id)_context {
  id job  = [self object];

  LSRunCommandV(_context, @"JobHistory", @"new",
                @"jobId",      [job valueForKey:@"jobId"],
                @"action",     LSJobReactivate,
                @"actorId",    [[_context valueForKey:LSAccountKey]
                                          valueForKey:@"companyId"],
                @"jobStatus",  [job valueForKey:@"jobStatus"],
                @"actionDate", [NSCalendarDate date],
                @"comment",    self->comment?:@"",                
                nil);
}

- (void)_divideJobInContext:(id)_context {
  id       job            = [self object];
  id       parentJob      = [job valueForKey:@"toParentJob"];

  LSRunCommandV(_context, @"job", @"setexecutant",
                                @"object", job,
                                @"relationKey", @"executant",
                                nil);

  LSRunCommandV(_context, @"JobHistory", @"new",
                @"jobId",      [parentJob valueForKey:@"jobId"],
                @"action",     LSJobDivided,
                @"actorId",    [[_context valueForKey:LSAccountKey]
                                          valueForKey:@"companyId"],
                @"jobStatus",  [parentJob valueForKey:@"jobStatus"],
                @"actionDate", [NSCalendarDate date],
                @"comment",    self->divideComment,
                nil);
}

- (void)_rejectJobInContext:(id)_context {
  id job  = [self object];

  LSRunCommandV(_context, @"JobHistory", @"new",
                @"jobId",      [job valueForKey:@"jobId"],
                @"action",     LSJobRejected,
                @"actorId",    [[_context valueForKey:LSAccountKey]
                                          valueForKey:@"companyId"],
                @"jobStatus",  [job valueForKey:@"jobStatus"],
                @"actionDate", [NSCalendarDate date],
                @"comment",    self->comment?:@"",                
                nil);
}

- (void)_validateKeysForContext:(id)_context {
  id       job     = [self object];
  BOOL     isRoot  = NO;
  id       account = [_context valueForKey:LSAccountKey];
  id       userId  = [account valueForKey:@"companyId"];
  NSArray  *groups = nil;

  groups = [[account valueForKey:@"groups"]
                             map:@selector(valueForKey:)
                             with:@"companyId"];
  
  isRoot = ([userId intValue] == 10000) ? YES : NO;
  
  [self assert:(self->action != nil)  reason:@"no action set"];
  [self assert:(job != nil) reason:@"no job set"];

  
  if ([self->action isEqualToString:@"done"] ||
      [self->action isEqualToString:@"archive"])
    [self assert:[LSRunCommandV(_context, @"job", @"allsubjobs-done",
                                @"object", job, nil) boolValue]];
                             
  
  [self assert:([self->action isEqualToString:@"accept"]     ||
                [self->action isEqualToString:@"done"]       ||
                [self->action isEqualToString:@"archive"]    ||
                [self->action isEqualToString:@"reactivate"] ||                
                [self->action isEqualToString:@"reject"]     ||                
                [self->action isEqualToString:@"comment"]    ||
                [self->action isEqualToString:@"divided"])
        format:@"invalid action key (%@) specified", self->action];


  if ([self->action isEqualToString:@"archive"]) {
    id      firstParentJob = nil;
    NSArray *parentJobs    = nil;
    
    LSRunCommandV(_context, @"job", @"getparentjobs", @"job", job, nil);
    parentJobs     = [job valueForKey:@"parentHierachie"];
    firstParentJob = ([parentJobs count] == 0)?job:[parentJobs objectAtIndex:0];

    [self assert:(([[firstParentJob valueForKey:@"creatorId"] isEqual:userId]) ||
                  (isRoot == YES))
          reason:@"only super-parent-job creator may archive job object"];
  }
  else if ([self->action isEqualToString:@"divided"]) {
    id parentJob = [job valueForKey:@"toParentJob"];
    id pex       = [parentJob valueForKey:@"executantId"];

    [self assert:[parentJob isNotNull]
          reason:@"try to execute divide-action  without parentJob"];
    [self assert:(([pex isEqual:userId] == YES) ||
                  ([groups containsObject:pex] == YES) ||
                  [[parentJob valueForKey:@"creatorId"] isEqual:userId] ||
                  (isRoot == YES))
          reason:@"only parent-job executant or creator "
                 @"may execute divide-action"];
  }
  else  if (![self->action isEqualToString:@"comment"]    &&
            ![self->action isEqualToString:@"archive"]    &&
            ![self->action isEqualToString:@"reactivate"] &&                  
            ![self->action isEqualToString:@"reject"] &&                  
            ![self->action isEqualToString:@"divided"]) {
    id ex = [job valueForKey:@"executantId"];
    id ct = [job valueForKey:@"creatorId"];
    [self assert:
          (([ex isEqual:userId]) ||
           ([ct isEqual:userId]) ||
           ([groups containsObject:ex]) ||
           (isRoot))
          reason:@"only executant may process job object"];
  }
  
  [super _validateKeysForContext:_context];
}

- (void)_prepareForExecutionInContext:(id)_context {
  id  obj        = [self object];
  id  state      = [obj valueForKey:@"jobStatus"];
  int objVersion = [[obj valueForKey:@"objectVersion"] intValue] + 1;

  [obj takeValue:[NSNumber numberWithInt:objVersion] forKey:@"objectVersion"];

  [self assert:(self->action != nil)  reason:@"no action set"];

  if ([self->action isEqualToString:@"accept"])
    state = LSJobProcessing;
  else if ([self->action isEqualToString:@"done"])
    state = LSJobDone;
  else if ([self->action isEqualToString:@"archive"])
    state = LSJobArchived;
  else if ([self->action isEqualToString:@"reactivate"])
    state = LSJobCreated;
  else if ([self->action isEqualToString:@"reject"])
    state = LSJobRejected;
/*  else  // fake nur zum testen ??????????
    state = LSJobProcessing; */

  [self assert:(state != nil) reason:@"state may not be nil"];

  [[self object] takeValue:state forKey:@"jobStatus"];
  
  
  [super _prepareForExecutionInContext:_context];
}

- (void)_executeInContext:(id)_context {
  NSString *logText   = [NSString stringWithFormat:@"Job %@", self->action];
  NSString *logAction = @"05_changed";
  
  [super _executeInContext:_context];
  if ([self->action isEqualToString:@"comment"])
    [self _commentJobInContext:_context];
  else if ([self->action isEqualToString:@"accept"])
     [self _acceptJobInContext:_context];
  else if ([self->action isEqualToString:@"divided"])
     [self _divideJobInContext:_context];
  else if ([self->action isEqualToString:@"done"])
     [self _doneJobInContext:_context];
  else if ([self->action isEqualToString:@"archive"]) {
     [self _archiveJobInContext:_context];
     logAction = @"10_archived";
  }
  else if ([self->action isEqualToString:@"reactivate"])
     [self _reactivateJobInContext:_context];
  else if ([self->action isEqualToString:@"reject"])
     [self _rejectJobInContext:_context];

  if ([[self valueForKey:@"logText"] isEqualToString:@"Job changed"])
    [self takeValue:logText forKey:@"logText"];
  if ([[self valueForKey:@"logAction"] isEqualToString:@"05_changed"])
    [self takeValue:logAction forKey:@"logAction"];
  
  LSRunCommandV(_context, @"object", @"add-log",
                @"logText"    , [self valueForKey:@"logText"], 
                @"action"     , [self valueForKey:@"logAction"],
                @"objectToLog", [self object],
                nil);
}

- (void)setAction:(NSString *)_action {
  if (self->action != _action) {
    RELEASE(self->action);
    self->action = [_action copyWithZone:[self zone]];
  }
}
- (NSString *)action {
  return action;
}

- (void)setComment:(NSString *)_comment {
  if (self->comment != _comment) {
    RELEASE(self->comment);
    self->comment = [_comment copyWithZone:[self zone]];
  }
}
- (NSString *)comment {
  return self->comment;
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

// initialize records

- (NSString *)entityName {
  return @"Job";
}

// key/value coding

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"action"])
    [self setAction:_value];
  else if ([_key isEqualToString:@"comment"])
    [self setComment:_value];
  else if ([_key isEqualToString:@"divideComment"])
    [self setDivideComment:_value];
  else if ([_key isEqualToString:@"object"])
    [self setObject:_value];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"action"])
    return [self action];
  else if ([_key isEqualToString:@"comment"])
    return [self comment];
  else if ([_key isEqualToString:@"divideComment"])
    return [self divideComment];
  else if ([_key isEqualToString:@"object"])
    return [self object];
  else
    return [super valueForKey:_key];
}

@end
