/*
  Copyright (C) 2006-2007 Whitemice Consulting

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
#include "zOGIAction.h"
#include "zOGIAction+Object.h"
#include "zOGIAction+Project.h"
#include "zOGIAction+Task.h"

@implementation zOGIAction(Task)

/* Render a ZOGI Task From A Job EOGenericRecord
   TODO: Why does this work differently then every other kind of object? */
-(NSMutableDictionary *)_renderTaskFromEO:(EOGenericRecord *)_task {
  NSMutableDictionary   *task;

  task = [NSMutableDictionary dictionaryWithObjectsAndKeys:
            [self ZERO:[_task valueForKey:@"objectVersion"]], @"version",
            @"Task", @"entityName",
            [_task valueForKey:@"creatorId"], @"creatorObjectId",
            [_task valueForKey:@"jobId"], @"objectId",
            [self ZERO:[_task valueForKey:@"isTeamJob"]], @"isTeamJob",
            [self NIL:[_task valueForKey:@"jobStatus"]], @"status",
            [self NIL:[_task valueForKey:@"endDate"]], @"end",
            [self NIL:[_task valueForKey:@"startDate"]], @"start",
            [self NIL:[_task valueForKey:@"executantId"]], 
               @"executantObjectId",
            [self ZERO:[_task valueForKey:@"priority"]], @"priority",
            [self NIL:[_task valueForKey:@"name"]], @"name",
            [self NIL:[_task valueForKey:@"keywords"]], @"keywords",
            [self NIL:[_task valueForKey:@"kind"]], @"kind",
            [self NIL:[_task valueForKey:@"category"]], @"category",
            [self ZERO:[_task valueForKey:@"projectId"]], @"objectProjectId",
            [self ZERO:[_task valueForKey:@"sensitivity"]], @"sensitivity",
            [self ZERO:[_task valueForKey:@"totalWork"]], @"totalWork",
            [self NIL:[_task valueForKey:@"timerDate"]], @"timerDate",
            /* 
              [self NIL:[_task valueForKey:@"parentJobId"]], @"parentJobId", 
             */
            [self ZERO:[_task valueForKey:@"percentComplete"]], 
               @"percentComplete",
            [self ZERO:[_task valueForKey:@"notify"]], @"notify",
            [self ZERO:[_task valueForKey:@"kilometers"]], @"kilometers",
            [self NIL:[_task valueForKey:@"completionDate"]], 
               @"completionDate",
            [self NIL:[_task valueForKey:@"comment"]], @"comment",
            [self NIL:[_task valueForKey:@"accountingInfo"]], 
               @"accountingInfo",
            [self ZERO:[_task valueForKey:@"actualWork"]], @"actualWork",
            [self NIL:[_task valueForKey:@"associatedCompanies"]], 
               @"associatedCompanies",
            [self NIL:[_task valueForKey:@"associatedContacts"]], 
               @"associatedContacts",
            [self NIL:[_task valueForKey:@"lastModified"]], @"lastModified",
            nil];
  return task;
} /* end renderTaskFromEO */

-(NSMutableDictionary *)_renderTask:(EOGenericRecord *)_task 
                         withDetail:(NSNumber *)_detail {
  NSMutableDictionary   *task;
  
  task = [self _renderTaskFromEO:_task];
  if([_detail intValue] > 0) {
    [task setObject:_task forKey:@"*eoObject"];
    if([_detail intValue] & zOGI_INCLUDE_NOTATIONS)
      [self _addNotesToTask:task];
    [self _addObjectDetails:task withDetail:_detail];
   }
  return task;
} /* end _renderTask */

/*
  Render EOGenericRecords into dictionaries
  _tasks Array of EOGenericRecord Job objects
  _detail Specifies how much detail to add to dictionary
*/
-(NSArray *)_renderTasks:(NSArray *)_tasks withDetail:(NSNumber *)_detail {
  NSMutableArray       *taskList;
  int                  count;

  taskList = [NSMutableArray arrayWithCapacity:[_tasks count]];
  for (count = 0; count < [_tasks count]; count++)
    [taskList addObject:[self _renderTask:[_tasks objectAtIndex:count] 
                               withDetail:_detail]];
  return taskList;
} /* end _renderTasks */

-(id)_getUnrenderedTasksForKeys:(id)_arg {
  return [[[self getCTX] runCommand:@"job::get-by-globalid",
                                    @"gids", [self _getEOsForPKeys:_arg],
                                    nil] retain];
} /* end _getUnrenderedTasksForKeys */

-(id)_getTasksForKeys:(id)_arg withDetail:(NSNumber *)_detail {
  return [self _renderTasks:[self _getUnrenderedTasksForKeys:_arg] 
                  withDetail:_detail];
} /* end _getTasksForKeys */

-(id)_getTasksForKeys:(id)_pk {
  return [self _getTasksForKeys:_pk withDetail:intObj(0)];
} /* end _getTasksForKeys */

-(id)_getTaskForKey:(id)_pk withDetail:(NSNumber *)_detail {
  return [[self _getTasksForKeys:_pk withDetail:_detail] objectAtIndex:0];
} /* end _getTasksForKey */

-(id)_getTaskForKey:(id)_pk {
  return [[self _getTasksForKeys:_pk withDetail:intObj(0)] objectAtIndex:0];
} /* end _getTasksForKey */

/* Retreive tasks from specified list
   _list can be: "todo", "control", "delegated", "archived", or "palm" */
-(id)_getTaskList:(NSString *)_list 
       withDetail:(NSNumber *)_detail {
  NSString       *listCommand;
  NSArray        *tasks, *taskList;

  if ([_list isEqualToString:@"todo"])
    listCommand = [NSString stringWithString:@"job::get-todo-jobs"];
  if ([_list isEqualToString:@"delegated"])
    listCommand = [NSString stringWithString:@"job::get-delegated-jobs"];
  if ([_list isEqualToString:@"archived"])
    listCommand = [NSString stringWithString:@"job::get-archived-jobs"];
  if ([_list isEqualToString:@"palm"])
    listCommand = [NSString stringWithString:@"job::get-palm-jobs"];

  tasks = [[self getCTX] runCommand:listCommand,
                          @"gid", [[self getCTX] valueForKey:LSAccountKey],
                          @"limit", intObj(65535),
                          nil];
  taskList = [self _renderTasks:tasks withDetail:_detail];
  return taskList;
} /* end _getTaskList */

-(id)_createTaskNotation:(NSDictionary *)_notation {
  /* TODO: Verification & gaurdian clauses */
  return [self _doTaskAction:[_notation objectForKey:@"taskObjectId"]
                      action:[_notation objectForKey:@"action"]
                 withComment:[_notation objectForKey:@"comment"]];
} /* end _createTaskNotation */

/* Perform a task action
  _action must be a valid action
  _command may be nil,  the action will then have no comment */
-(id)_doTaskAction:(id)_pk action:(NSString *)_action 
                      withComment:(NSString *)_comment {
  id                 result;
  EOGenericRecord   *task;
  NSDictionary      *args;
  NSDictionary      *notation;

  task = [[self _getUnrenderedTasksForKeys:_pk] lastObject];
  if (_comment != nil) {
    /* With Comment */
    notation = [[self getCTX] runCommand:@"job::jobaction",
                                         @"object", task,
                                         @"action", _action,
                                         @"comment", _comment,
                                         nil];
   } else {
      /* No Comment */
      notation = [[self getCTX] runCommand:@"job::jobaction",
                                           @"object", task,
                                           @"action", _action,
                                           nil];
     }
  if (notation == nil) {
    return [NSException exceptionWithHTTPStatus:500
                        reason:@"Recording of task action failed."];
   }
  if ([notation isKindOfClass:[EOGenericRecord class]]) {
    if ([_action isEqualToString:@"accept"]) {
      args = [NSDictionary dictionaryWithObjectsAndKeys:
                       [self _getCompanyId], @"executantId",
                       [task valueForKey:@"jobId"], @"jobId",
                       nil];
      result = [[self getCTX] runCommand:@"job::set" arguments:args];
      if (result == nil) {
        return [NSException exceptionWithHTTPStatus:500
                            reason:@"Accepting of task failed."];
       }
     } // End if _action == accpet
   } else {
       [[self getCTX] rollback];
       return [NSException exceptionWithHTTPStatus:500
                           reason:@"Task action resulting in unkown class"];
      }
  [[self getCTX] commit];
  return [self _renderTask:[[self _getUnrenderedTasksForKeys:_pk] lastObject] 
                withDetail:[NSNumber numberWithInt:65535]];
} /* end doTaskAction */

-(void)_addNotesToTask:(NSMutableDictionary *)_task {
  NSMutableArray    *noteList;
  NSEnumerator      *enumerator;
  id                 annotation;
 
  noteList = [NSMutableArray arrayWithCapacity:16];
  [[self getCTX] runCommand:@"job::get-job-history",
                            @"object", [_task valueForKey:@"*eoObject"],
                            @"relationKey", @"jobHistory", 
                            nil];
  enumerator = [[[_task valueForKey:@"*eoObject"] valueForKey:@"jobHistory"] objectEnumerator];
  while ((annotation = [enumerator nextObject]) != nil) {
    [noteList addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
       [annotation valueForKey:@"jobHistoryId"], @"objectId",
       @"taskNotation", @"entityName",
       [annotation valueForKey:@"action"], @"action",
       [annotation valueForKey:@"actionDate"], @"actionDate",
       [annotation valueForKey:@"jobId"], @"taskObjectId",
       [annotation valueForKey:@"jobStatus"], @"taskStatus",
       [annotation valueForKey:@"actorId"], @"actorObjectId",
       [self _getCommentFromHistoryEO:annotation], @"comment",
       nil]];
   }
  [_task setObject:noteList forKey:@"_NOTES"];
} /* end _addNotesToTask */

-(NSString *)_getCommentFromHistoryEO:(EOGenericRecord *)_history {
  EOGenericRecord   *infoRecord;

  infoRecord = [_history valueForKey:@"toJobHistoryInfo"];
  return [self NIL:[[infoRecord valueForKey:@"comment"] lastObject]];
} /* end _getCommentFromHistoryEO */

/* Create a job entry from dictionary */
-(id)_createTask:(NSDictionary *)_task {
  NSMutableDictionary   *taskDictionary;
  NSString              *executantEntityName;
  id	                 taskObject;

  taskDictionary = [self _translateTask:[self _fillTask:_task]];
  [self _validateTask:taskDictionary];
  executantEntityName = 
    [self _getEntityNameForPKey:[taskDictionary objectForKey:@"executantId"]];
  if ([executantEntityName isEqualToString:@"Team"])
    [taskDictionary setObject:[NSNumber numberWithInt:1] forKey:@"isTeamJob"];
   else
     [taskDictionary setObject:[NSNumber numberWithInt:0] forKey:@"isTeamJob"];
  taskObject = [[self getCTX] runCommand:@"job::new" 
                              arguments:taskDictionary];
  if(taskObject == nil) {
    // \todo Throw exception when task is not created
    return [NSException exceptionWithHTTPStatus:500
                        reason:@"Failure to create task"];
  }
  [self _saveObjectLinks:[_task objectForKey:@"_OBJECTLINKS"] 
               forObject:[taskObject valueForKey:@"jobId"]];
  [self _saveProperties:[_task objectForKey:@"_PROPERTIES"]
              forObject:[taskObject valueForKey:@"jobId"]];
  [[self getCTX] commit];
  return [self _renderTask:taskObject 
                 withDetail:[NSNumber numberWithInt:65535]];
} /* end _createTask */

/* Update the task object */
-(id)_updateTask:(NSDictionary *)_task 
        objectId:(NSString *)objectId 
       withFlags:(NSArray *)_flags {
  id    task;

  if(![self _checkEntity:[_task valueForKey:@"objectId"] 
              entityName:@"Task"]) {
    /* Throw exception if object is not a Task
       TODO: Can this happen? */
    return [NSException 
              exceptionWithHTTPStatus:500
              reason:@"Update of task requested for non-task object"];
  }

  [self _validateTask:_task];
  task = [[self getCTX] runCommand:@"job::set" 
                        arguments:[self _translateTask:_task]];
  if (task == nil) {
    return [NSException exceptionWithHTTPStatus:500
                        reason:@"Update of task failed"];
  }
  /* TODO: Detail with failure */
  if ([_task objectForKey:@"_OBJECTLINKS"] != nil)
    [self _saveObjectLinks:[_task objectForKey:@"_OBJECTLINKS"] 
                 forObject:objectId];
  if ([_task objectForKey:@"_PROPERTIES"] != nil)
    [self _saveProperties:[_task objectForKey:@"_PROPERTIES"] 
                forObject:objectId];
  [[self getCTX] commit];
  return [self _renderTask:task 
                 withDetail:[NSNumber numberWithInt:65535]];
} /* end _updateTask */

/* Fill the empty fields in a new task
   Will turn the NSDictionary into a NSMutableDictionary */
-(NSMutableDictionary *)_fillTask:(NSDictionary *)_task {
  NSMutableDictionary	*task;
  NSCalendarDate		*startDate;
  NSCalendarDate		*endDate;
  NSString              *emptyString;

  task = [NSMutableDictionary dictionaryWithCapacity:32];
  [task addEntriesFromDictionary:_task];
  emptyString = [NSString stringWithString:@""];
  // Name (description)
  if([task objectForKey:@"name"] == nil)
	[task setObject:[NSString stringWithString:@"Unnamed Task"]
          forKey:@"name"];
  // Executant
  if([_task objectForKey:@"executantObjectId"] == nil)
    [task setObject:[[[self getCTX] valueForKey:LSAccountKey] valueForKey:@"companyId"]
          forKey:@"executantObjectId"];
  // Start
  if([task objectForKey:@"start"] == nil) {
    startDate = [NSCalendarDate date];
    [startDate dateByAddingYears:0 months:0 days:7];
    [startDate setTimeZone:[self _getTimeZone]];
    [task setObject:startDate forKey:@"start"];
   }
  // End
  if([task objectForKey:@"end"] == nil) {
    endDate = [NSCalendarDate date];
    [endDate setTimeZone:[self _getTimeZone]];
    endDate = [endDate dateByAddingYears:0 months:0 days:7];
    [task setObject:endDate forKey:@"end"];
   }
  // Category & Associations
  if([task objectForKey:@"category"] == nil)
    [task setObject:emptyString forKey:@"category"];
  if([task objectForKey:@"associatedCompanies"] == nil)
    [task setObject:emptyString forKey:@"associatedCompanies"];
  if([task objectForKey:@"associatedContacts"] == nil)
    [task setObject:emptyString forKey:@"associatedContacts"];
  return task;
} /* end _fillTask */

/* Check that the contents of the _task are valid 
   TODO: Do something. :) */
-(void)_validateTask:(NSDictionary *)_task 
{
}

/* Rewrite zOGI dictionary to something the OGo Logic layer wants to see */
-(NSMutableDictionary *)_translateTask:(NSDictionary *)_task {
  NSMutableDictionary   *task;
  NSCalendarDate        *dateValue;
  NSArray               *keys;
  NSString              *key;
  int                   projectId;
  id                    objectId;
  int                   count;

  objectId = [_task objectForKey:@"objectId"];
  if (objectId == nil)
    objectId = [NSString stringWithString:@"0"];
  else if ([objectId isKindOfClass:[NSNumber class]])
    objectId = [objectId stringValue];

  task = [NSMutableDictionary dictionaryWithCapacity:32];
  keys = [_task allKeys];
  for (count = 0; count < [keys count]; count++) {
    key = [keys objectAtIndex:count];
    if ([key isEqualToString:@"executantObjectId"]) {
      [task setObject:[_task objectForKey:@"executantObjectId"] 
               forKey:@"executantId"];
    } else if ([key isEqualToString:@"objectProjectId"]) {
      projectId = [[_task objectForKey:key] intValue];
      if (projectId == 0)
        [task setObject:[NSNull null] forKey:@"projectId"];
        else [task setObject:[NSNumber numberWithInt:projectId]
                      forKey:@"projectId"];
    } else if ([key isEqualToString:@"parentTaskObjectId"]) {
      // We are currently droping this attribute as the guts of
      // OGo seem to do something odd when they see it and 
      // produce an error
      //[task setObject:[_task objectForKey:@"parentTaskObjectId"] 
      //      forKey:@"parentJobId"];
    } else if ([key isEqualToString:@"kind"]) {
      if (![[_task objectForKey:@"kind"] isEqualToString:@""])
        [task setObject:[_task objectForKey:@"kind"]
              forKey:@"kind"];
    } else if ([key isEqualToString:@"objectId"]) {
      // Only translate this attribute if it has a non-zero value
      if ([objectId isEqualToString:@"0"]) {
      } else { 
          [task setObject:[_task objectForKey:@"objectId"] forKey:@"jobId"];
         }
    } else if ([key isEqualToString:@"entityName"] ||
               [key isEqualToString:@"isTeamJob"]) {
      // These atttributes are deliberately dropped
    } else if ([[key substringToIndex:1] isEqualToString:@"_"]) {
    } else if ([key isEqualToString:@"start"] ||
               [key isEqualToString:@"end"]) {
         dateValue = [self _makeCalendarDate:[_task objectForKey:key]];
         if ([key isEqualToString:@"start"])
           [task setObject:dateValue forKey:@"startDate"];
           else [task setObject:dateValue forKey:@"endDate"];
    } else {
        [task setObject:[_task objectForKey:key] forKey:key];
       }
   } // End for loop through keys
  return task;
} /* end _translateTask */

-(NSArray *)_searchForTasks:(id)_query 
                 withDetail:(NSNumber *)_detail
                  withFlags:(NSDictionary *)_flags {
  /* Task query supports a simple query where _query is a string
     specifying a task list. */
 if ([_query isKindOfClass:[NSString class]]) {
   return [self _getTaskList:_query withDetail:_detail];
  }
 return [[NSArray alloc] init];
} /* end _searchForTasks */

@end /* End zOGIAction(Task) */
