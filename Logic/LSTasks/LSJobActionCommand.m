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

#include <LSFoundation/LSDBObjectSetCommand.h>

/*
  LSJobActionCommand

  TODO: document
*/

@class NSString;

@interface LSJobActionCommand : LSDBObjectSetCommand
{
  NSString *action;
  NSString *comment;
}

- (void)setAction:(NSString *)_action;
- (NSString *)action;
- (void)setComment:(NSString *)_comment;
- (NSString *)comment;

@end /* LSJobActionCommand */

#include "common.h"

extern NSString *LSWJobHasChanged;

@implementation LSJobActionCommand

- (id)initForOperation:(NSString *)_operation inDomain:(NSString *)_domain {
  if ((self = [super initForOperation:_operation inDomain:_domain])) {
    [self takeValue:@"05_changed"  forKey:@"logAction"];
    [self takeValue:@"Job changed" forKey:@"logText"];
  }
  return self;
}

- (void)dealloc {
  [self->action  release];
  [self->comment release];
  [super dealloc];
}

/* account */

- (NSNumber *)loginIdInContext:(id)_context {
  return [[_context valueForKey:LSAccountKey] valueForKey:@"companyId"];
}

/* maintaining job history */

- (void)_addHistory:(NSString *)_action inContext:(id)_context {
  id job, command;

  job     = [self object];
  command = LSCommandLookup([self commandFactory], @"JobHistory", @"new");
  
  [command takeValue:[self loginIdInContext:_context] forKey:@"actorId"];
  [command takeValue:[job valueForKey:@"jobId"]       forKey:@"jobId"];
  [command takeValue:[job valueForKey:@"jobStatus"]   forKey:@"jobStatus"];
  [command takeValue:[NSCalendarDate calendarDate]    forKey:@"actionDate"];
  [command takeValue:(self->comment != nil ? self->comment: (NSString *)@"")
	   forKey:@"comment"];
  [command takeValue:_action                          forKey:@"action"];
  [command runInContext:_context];
}

- (NSNumber *)_loginAccountIdInContext:(id)_context {
  id account;
  
  account = [_context valueForKey:LSAccountKey];
  return [account valueForKey:@"companyId"];
}

- (void)_commentJobInContext:(id)_context {
  [self _addHistory:LSJobCommented inContext:_context];
}

- (void)_acceptJobInContext:(id)_context {
  LSRunCommandV(_context, @"job", @"set",
                @"object",      [self object],
		@"executantId", [self _loginAccountIdInContext:_context],
		nil);

  [self _addHistory:LSJobAccepted inContext:_context];
}

- (void)_doneJobInContext:(id)_context {
  NSCalendarDate        *complete;
  NSTimeZone            *tz;

  complete = [NSCalendarDate calendarDate];
  tz = [complete timeZoneDetail];
  [complete setTimeZone:tz];
 
  LSRunCommandV(_context, @"job", @"set",
                @"object", [self object],
                @"percentComplete", @"100", 
		@"executantId", [self _loginAccountIdInContext:_context],
		@"completionDate", complete, 
		nil);

  [self _addHistory:LSJobDone inContext:_context];
}

- (void)_archiveJobInContext:(id)_context {
  [self _addHistory:LSJobArchived inContext:_context];
}

- (void)_reactivateJobInContext:(id)_context {
  [self _addHistory:LSJobReactivate inContext:_context];

  LSRunCommandV(_context, @"job", @"set",
                @"object", [self object],
                @"percentComplete", @"0", nil);
}

- (void)_rejectJobInContext:(id)_context {
  [self _addHistory:LSJobRejected inContext:_context];
}

- (void)_divideJobInContext:(id)_context {
  id job, command;
  
  LSRunCommandV(_context, @"job", @"setexecutant",
                @"object", [self object],
                @"relationKey", @"executant",
                nil);
  job     = [[self object] valueForKey:@"toParentJob"];
  command = LSCommandLookup([self commandFactory], @"JobHistory", @"new");
  
  [command takeValue:[self loginIdInContext:_context] forKey:@"actorId"];
  [command takeValue:[job valueForKey:@"jobId"]       forKey:@"jobId"];
  [command takeValue:[job valueForKey:@"jobStatus"]   forKey:@"jobStatus"];
  [command takeValue:[NSCalendarDate calendarDate]    forKey:@"actionDate"];
  [command takeValue:self->comment ? self->comment : (NSString *)@""
	   forKey:@"comment"];
  [command takeValue:LSJobDivided                     forKey:@"action"];
  [command runInContext:_context];
}

- (BOOL)isKnownAction:(NSString *)_action {
  static NSSet *actions = nil;
  
  if (actions == nil) {
    actions = [[NSSet alloc] initWithObjects:
			       @"accept", @"done", @"archive", @"reactivate",
			       @"reject", @"comment", @"divided", nil];
  }
  if (![_action isNotEmpty])
    return NO;
  
  return [actions containsObject:_action];
}

- (NSArray *)groupIdsForLoginInContext:(id)_context {
  id      account;
  NSArray *groups;

  account = [_context valueForKey:LSAccountKey];  

  // TODO: does that use relationships? who sets 'groups'?
  if ((groups = [account valueForKey:@"groups"]) == nil)
    return nil;
  
  groups = [groups map:@selector(valueForKey:) with:@"companyId"];
  return groups;
}

- (BOOL)isRootId:(NSNumber *)_pkey {
  return [_pkey intValue] == 10000 ? YES : NO;
}

- (BOOL)_validateArchiveKeysForContext:(id)_context {
  NSNumber *userId;
  
  /* ensure that the object is filled, TODO: check whether this is required */
  
  /* check permissions */
  
  userId  = [[_context valueForKey:LSAccountKey] valueForKey:@"companyId"];
  
  if ([self isRootId:userId])
    return YES;
  if ([[[self object] valueForKey:@"creatorId"] isEqual:userId])
    return YES;
  if ([[[self object] valueForKey:@"ownerId"] isEqual:userId])
    return YES;
  
  [self assert:NO reason:@"only root, creator, or owner may delete task"];
  return NO;
}

- (BOOL)_validateCommonKeysForContext:(id)_context {
  /*
    checks permissions, allowed are:
    - root
    - the executant
    - the creator
    - if the executant is a group, any account in the same group
  */
  NSNumber *userId, *exId;
  id   account, tmp;
  
  account = [_context valueForKey:LSAccountKey];
  userId  = [account valueForKey:@"companyId"];

  if ([userId intValue] == 10000) /* root */
    return YES;
  
  exId = [[self object] valueForKey:@"executantId"];
  if ([exId isEqual:userId]) /* the login is the executant */
    return YES;
  
  tmp = [[self object] valueForKey:@"creatorId"];
  if ([tmp isEqual:userId]) /* the login is the creator */
    return YES;

  tmp = [[self object] valueForKey:@"ownerId"];
  if ([tmp isEqual:userId]) /* the login is the owner */
    return YES;
  
  tmp = [self groupIdsForLoginInContext:_context];
  if ([tmp containsObject:exId]) /* the executant is a group of the login */
    return YES;
  
  return NO;
}

- (void)_validateKeysForContext:(id)_context {
  id      job, account, userId;
  NSArray *groups;
  
  job = [self object];

  /* pre-conditions */
  
  [self assert:(self->action != nil)  reason:@"no action set"];
  [self assert:(job != nil)           reason:@"no job set"];
  
  /* check permissions */
  
  account = [_context valueForKey:LSAccountKey];
  userId  = [account valueForKey:@"companyId"];
  groups  = [self groupIdsForLoginInContext:_context];
  
  /* special processing */
  
  if (![self isKnownAction:self->action]) {
    [self logWithFormat:@"unknown action: %@", self->action];
    [self assert:NO format:@"invalid action key (%@) specified", self->action];
  }
  else if ([self->action isEqualToString:@"divided"]) {
    [self logWithFormat:@"deprecated action: %@", self->action];
    [self assert:NO format:@"invalid action key (%@) specified", self->action];
  }
  
  if ([self->action isEqualToString:@"archive"])
    [self _validateArchiveKeysForContext:_context];
  else
    [self _validateCommonKeysForContext:_context];
  
  [super _validateKeysForContext:_context];
}

- (void)_prepareForExecutionInContext:(id)_context {
  id  obj, state;
  int objVersion;

  obj        = [self object];
  state      = [obj valueForKey:@"jobStatus"];
  objVersion = [[obj valueForKey:@"objectVersion"] intValue] + 1;

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
#if 0
  else  // fake only for testing ??????????
    state = LSJobProcessing;
#endif

  [self assert:(state != nil) reason:@"state may not be nil"];

  [[self object] takeValue:state forKey:@"jobStatus"];
  
  [super _prepareForExecutionInContext:_context];
}

- (void)_executeInContext:(id)_context {
  NSString *logText, *logAction;
  
  logText   = [@"Job " stringByAppendingString:self->action];
  logAction = @"05_changed";
  
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

/* accessors */

- (void)setAction:(NSString *)_action {
  ASSIGNCOPY(self->action, _action);
}
- (NSString *)action {
  return action;
}

- (void)setComment:(NSString *)_comment {
  ASSIGNCOPY(self->comment, _comment);
}
- (NSString *)comment {
  return self->comment;
}

/* typing */

- (NSString *)entityName {
  return @"Job";
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"action"])
    [self setAction:_value];
  else if ([_key isEqualToString:@"comment"])
    [self setComment:_value];
  else if ([_key isEqualToString:@"object"])
    [self setObject:_value];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"action"])
    return [self action];
  if ([_key isEqualToString:@"comment"])
    return [self comment];
  if ([_key isEqualToString:@"object"])
    return [self object];

  return [super valueForKey:_key];
}

@end /* LSJobActionCommand */
