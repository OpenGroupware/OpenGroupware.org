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

#include <LSFoundation/LSDBObjectNewCommand.h>

@class NSString;

@interface LSNewJobCommand : LSDBObjectNewCommand
{
  id       project;
  id       executant;
  NSString *comment;
  NSString *divideComment;
  NSString *assignmentKind;
}

- (void)setProject:(id)_project;
- (id)project;

@end

#include "common.h"

@implementation LSNewJobCommand

static NSString *OGoHelpDeskRoleName = nil;

+ (void)initialize {
  NSLog(@"LSNewJobCommand initialized");
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

  OGoHelpDeskRoleName = [[ud stringForKey:@"OGoHelpDeskRoleName"] copy];
  if ([OGoHelpDeskRoleName isNotEmpty]) {
    NSLog(@"Note: Team '%@' assigned Help Desk role.",
          OGoHelpDeskRoleName);
  } else NSLog(@"Note: No team assigned Help Desk role.");
}

- (id)initForOperation:(NSString *)_operation inDomain:(NSString *)_domain {
  if ((self = [super initForOperation:_operation inDomain:_domain])) {
    [self takeValue:@"00_created"  forKey:@"logAction"];
    [self takeValue:@"Job created" forKey:@"logText"];
  }
  return self;
}

- (void)dealloc {
  [self->project        release];
  [self->executant      release];
  [self->comment        release];
  [self->divideComment  release];
  [self->assignmentKind release];
  [super dealloc];
}

/* operation */

- (BOOL)isRootAccountEO:(id)_eo {
  return [[_eo valueForKey:@"companyId"] intValue] == 10000 ? YES : NO;
}

- (BOOL)isHelpDeskUser:(id)_context {
  id   user;

  user = [_context valueForKey:LSAccountKey];
  /* Root user is always considered Help Desk */
  if ([self isRootAccountEO:user])
    return YES;
  if ([OGoHelpDeskRoleName isNotEmpty]) {
    NSArray *teams;

    teams = [_context runCommand:@"account::teams",
                           @"account", user,
                           @"returnType", intObj(LSDBReturnType_ManyObjects),
                           nil];
    teams = [teams valueForKey:@"description"];
    if ([teams containsObject:OGoHelpDeskRoleName])
      return YES;
  }
  return NO;
}



- (void)_checkStartDateIsBeforeEndDate {
  NSCalendarDate *startDate;
  NSCalendarDate *endDate;
  
  startDate = [self valueForKey:@"startDate"];
  endDate   = [self valueForKey:@"endDate"];
  if ([startDate compare:endDate] == NSOrderedDescending) {
    /* TODO: should assert ... */
    [self logWithFormat:@"WARNING: startDate is before endDate !"];
  }
}

- (void)_newJobHistoryInContext:(id)_context {
  id job, user, nCmd;
  
  job = [self object];
  
  if ([[job valueForKey:@"executantId"]isEqual:[job valueForKey:@"creatorId"]])
    return;
    
  user = [_context valueForKey:LSAccountKey];
  nCmd = LSLookupCommand(@"JobHistory", @"new");
    
  [nCmd takeValue:LSJobCreated                    forKey:@"action"]; 
  [nCmd takeValue:[job valueForKey:@"jobId"]      forKey:@"jobId"]; 
  [nCmd takeValue:[user valueForKey:@"companyId"] forKey:@"actorId"]; 
  [nCmd takeValue:[NSCalendarDate calendarDate]   forKey:@"actionDate"];
  [nCmd takeValue:[job valueForKey:@"jobStatus"]  forKey:@"jobStatus"];
  [nCmd takeValue:self->comment                   forKey:@"comment"];
  [nCmd runInContext:_context];
}

- (void)_prepareForExecutionInContext:(id)_context {
  id user, tmp;
  
  [self _checkStartDateIsBeforeEndDate];
  
  [self assert:([self valueForKey:@"name"] != nil)
        reason:@"job name may not be nil"];
  user = [_context valueForKey:LSAccountKey];
  
  /* check status */
  
  if ([[self valueForKey:@"jobStatus"] isNotNull]) {
    if (![self isRootAccountEO:user])
      [self takeValue:LSJobCreated forKey:@"jobStatus"];
  }
  else
    [self takeValue:LSJobCreated forKey:@"jobStatus"];
  
  /* check creator */

  if ([[self valueForKey:@"creatorId"] isNotNull]) {
    if (![self isRootAccountEO:user])
      [self takeValue:[user valueForKey:@"companyId"] forKey:@"creatorId"];
  }
  else {
    [self takeValue:[user valueForKey:@"companyId"] forKey:@"creatorId"];    
  }

  // Allow owner to be set to other than creator by users who are members of
  // the team defined in the OGoHelpDeskRoleName default. (Bug#2027)
  if ([[self valueForKey:@"ownerId"] isNotNull]) {
    if (!([self isHelpDeskUser:_context])) {
      // current user is not on help desk, owner will be set to creator
      [self takeValue:[user valueForKey:@"companyId"] forKey:@"ownerId"];
    }
  } else {
      // No owner specified, owner is the creator
      [self takeValue:[user valueForKey:@"companyId"] forKey:@"ownerId"];
    }

  /* check executant */
  
  if (self->executant) {
    [self takeValue:[self->executant valueForKey:@"companyId"]
          forKey:@"executantId"];
  }
  if ((tmp = [self valueForKey:@"executantId"]) == nil) {
    if ((tmp = [self valueForKey:@"creatorId"]))
      [self takeValue:tmp forKey:@"executantId"];
  }
  
  /* check project */
  
  if (self->project) {
    [self takeValue:[self->project valueForKey:@"projectId"]
          forKey:@"projectId"];
  }
  
  [super _prepareForExecutionInContext:_context];
}

- (void)_executeMoreActionInContext:(id)_context {
  id job;
  
  job = [self object];

  if (![self isRootAccountEO:[_context valueForKey:LSAccountKey]]) {
    if ([[job valueForKey:@"executantId"]
              isEqual:[job valueForKey:@"creatorId"]]) {
      LSRunCommandV(_context,
                    @"job", @"jobaction",
                    @"action", @"accept",
                    @"object", job,
                    @"comment", self->comment, nil);
    }
  }
}

- (void)_executeInContext:(id)_context {
  [super _executeInContext:_context];
  [self  _newJobHistoryInContext:_context];  
  [self  _executeMoreActionInContext:_context];
  
  LSRunCommandV(_context, @"object", @"add-log",
                @"logText"    , [self valueForKey:@"logText"],
                @"action"     , [self valueForKey:@"logAction"],
                @"objectToLog", [self object],
                nil);

  [self calculateCTagInContext:_context];
}

/* accessors */

- (void)setCreateAs:(NSString *)_assignmentKind {
  ASSIGNCOPY(self->assignmentKind, _assignmentKind);
}
- (NSString *)assignmentKind {
  return self->assignmentKind;
}

- (void)setProject:(id)_project {
  ASSIGN(self->project, _project);
}
- (id)project {
  return self->project;
}

- (void)setDivideComment:(NSString *)_comment {
  ASSIGNCOPY(self->divideComment, _comment);
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

/* initialize records */

- (NSString *)entityName {
  return @"Job";
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"assignmentKind"])
    [self setCreateAs:_value];
  else if ([_key isEqualToString:@"toProject"] ||
             [_key isEqualToString:@"project"]) {
    [self setProject:_value];
    return;
  }
  else if ([_key isEqualToString:@"executant"])
    [self setExecutant:_value];
  else if ([_key isEqualToString:@"comment"]) {
    [self setComment:_value];
    [super takeValue:_value forKey:_key];
  }
  else if ([_key isEqualToString:@"divideComment"])
    [self setDivideComment:_value];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"toProject"] || [_key isEqualToString:@"project"])
    return [self project];
  if ([_key isEqualToString:@"executant"])
    return [self executant];
  if ([_key isEqualToString:@"comment"])
    return [self comment];
  if ([_key isEqualToString:@"divideComment"])
    return [self divideComment];

  return [super valueForKey:_key];
}

@end /* LSNewJobCommand */
