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

#include "SxTaskManager.h"
#include "SxContactManager.h"
#include "common.h"
#include <NGObjWeb/NSException+HTTP.h>

@implementation SxTaskManager

- (void)dealloc {
  [super dealloc];
}

/* common */

- (NSString *)getJobCommandForType:(NSString *)_type {
  //return @"job::get-todo-jobs";
  return @"job::get-executant-jobs";
}

- (id)objectForTeam:(id)_group {
  EOGlobalID *gid;
  id result;
  
  if (_group == nil) return nil;
  
  if ([_group isKindOfClass:[NSString class]])
    gid = [self globalIDForGroupWithName:_group];
  else if ([_group isKindOfClass:[NSNumber class]])
    gid = [self globalIDForGroupWithPrimaryKey:_group];
  else if ([_group isKindOfClass:[EOKeyGlobalID class]])
    gid = _group;
  else {
    [self logWithFormat:@"cannot resolve team-id: %@", _group];
    return _group;
  }
  
  if (gid == nil) {
    [self logWithFormat:@"could not resolve team-id: %@", _group];
    return nil;
  }
  
  result = [self->cmdctx runCommand:@"team::get-by-globalid",
		@"gid", gid, nil];
  if ([result isKindOfClass:[NSArray class]]) {
    if ([result count] == 0) {
      [self logWithFormat:@"could not resolve team-gid: %@", gid];
      return nil;
    }
    result = [result objectAtIndex:0];
  }
  return result;
}

- (NSArray *)fetchTasksOfGroup:(id)_group type:(NSString *)_type {
  NSException *error = nil;
  NSArray  *jobs;
  id object;
  
  object = (_group == nil)
    ? [[self commandContext] valueForKey:LSAccountKey]
    : [self objectForTeam:_group];
  
  if (object == nil) {
    [self logWithFormat:
          @"ERROR: got no object for %@", _group ? _group : @"login"];
    return nil;
  }
  
  NS_DURING {
    jobs = [self->cmdctx runCommand:[self getJobCommandForType:_type],
		@"object", object, nil];
    [self->cmdctx commit]; /* need to commit since we are dealing with EOs */
  }
  NS_HANDLER {
    error = [localException retain];
  }
  NS_ENDHANDLER;
  error = [error autorelease];
  
  if (error) {
    [self logWithFormat:@"FAILED: %@", error];
    return nil;
  }
  
  return jobs;
}

/* list queries, returns: jobId, title */

- (NSEnumerator *)listTasksOfGroup:(id)_group type:(NSString *)_type {
  NSArray *tasks;
  
  tasks = [self fetchTasksOfGroup:_group type:_type];
  return [tasks objectEnumerator];
}
- (int)countTasksOfGroup:(id)_group type:(NSString *)_type {
  NSArray *tasks;
  if ((tasks = [self fetchTasksOfGroup:_group type:_type]) == nil)
    return -1;
  return [tasks count];
}

/* evo searches, returns: .. */

- (NSEnumerator *)evoTasksOfGroup:(id)_group type:(NSString *)_type {
  NSArray *tasks;
  
  tasks = [self fetchTasksOfGroup:_group type:_type];
  return [tasks objectEnumerator];
}

/* deleting */

- (SxContactManager *)contactManager {
  // TODO: use backend master
  return [SxContactManager managerWithContext:[self commandContext]];
}

- (void)fetchCreatorForTaskEO:(id)_task {
  SxContactManager *cm;
  id creatorId;
  id gid;
  
  if ((creatorId = [_task valueForKey:@"creatorId"]) == nil)
    return;

  cm  = [self contactManager];
  gid = [EOKeyGlobalID globalIDWithEntityName:@"Person"
                       keys:&creatorId keyCount:1 zone:NULL];
  
  if ((gid = [cm accountForGlobalID:gid]))
    [_task takeValue:gid forKey:@"creator"];
}

- (id)eoForPrimaryKey:(NSNumber *)_key {
  /* should not be used by frontend ... */
  LSCommandContext *ctx;
  id o;
  
  ctx = [self commandContext];
  o = [ctx runCommand:@"job::get",  @"jobId", _key, nil];
  if (o == nil) {
    [self logWithFormat:@"job::get returned no result for pkey %@",
            _key];
    return nil;
  }
  if (![self commit]) {
    [self logWithFormat:@"could not commit transaction !"];
    [self rollback];
  }
  
  o = ([o isKindOfClass:[NSArray class]])
    ? [[o lastObject] retain]
    : [o retain];
  
  if (o) 
    [self fetchCreatorForTaskEO:o];
  
  return o;
}

- (NSException *)deleteRecordWithPrimaryKey:(NSNumber *)_key {
  NSException *error;
  
  error = nil;
  NS_DURING {
    id obj = [self eoForPrimaryKey:_key];

    if ([[obj valueForKey:@"jobStatus"] isEqual:@"30_archived"]) {
      [[self commandContext] runCommand:@"job::delete", @"object",  obj, nil];
    }
    else {
      [[self commandContext] runCommand:@"job::jobaction",
  	        @"object",  obj, 
	        @"action",  @"archive",
  	        @"comment", @"archived by ZideStore",
  	      nil];
    }
    if (![self commit]) {
      error = [[NSException exceptionWithHTTPStatus:409 /* Conflict */
			    reason:@"could not commit transaction !"] retain];
    }
  }
  NS_HANDLER
    error = [localException retain];
  NS_ENDHANDLER;
  error = [error autorelease];
  
  if (error != nil) {
    [self logWithFormat:@"delete failed: %@", error];
    [self rollback];
  }
  return error;
}

@end /* SxTaskManager */
