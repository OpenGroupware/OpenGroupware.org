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

#ifndef __zOGIAction_Task_H__
#define __zOGIAction_Task_H__

#include "zOGIAction.h"

@interface zOGIAction(Task)

-(NSMutableDictionary *)_renderTaskFromEO:(EOGenericRecord *)_task;
-(NSMutableDictionary *)_renderTask:(EOGenericRecord *)_task withDetail:(NSNumber *)_detail;
-(NSArray *)_renderTasks:(NSArray *)_tasks withDetail:(NSNumber *)_detail;
-(id)_getUnrenderedTasksForKeys:(id)_arg;
-(id)_getTasksForKeys:(id)_arg withDetail:(NSNumber *)_detail;
-(id)_getTasksForKeys:(id)_pk;
-(id)_getTaskForKey:(id)_pk withDetail:(NSNumber *)_detail;
-(id)_getTaskForKey:(id)_pk;
-(id)_getTaskList:(NSString *)_list withDetail:(NSNumber *)_detail;
-(id)_createTaskNotation:(NSDictionary *)_notation;
-(id)_doTaskAction:(id)_pk action:(NSString *)_action 
                           withComment:(NSString *)_comment;
-(void)_addNotesToTask:(NSMutableDictionary *)_task;
-(NSString *)_getCommentFromHistoryEO:(EOGenericRecord *)_history;
-(id)_createTask:(NSDictionary *)_task;
-(id)_updateTask:(NSDictionary *)_task 
        objectId:(NSString *)objectId
       withFlags:(NSArray *)_flags;
-(NSMutableDictionary *)_fillTask:(NSDictionary *)_task;
-(void)_validateTask:(NSDictionary *)_task;
-(NSMutableDictionary *)_translateTask:(NSDictionary *)_task;
-(NSArray *)_searchForTasks:(id)_query 
                 withDetail:(NSNumber *)_detail
                  withFlags:(NSDictionary *)_flags;
@end

#endif /* __zOGIAction_Task_H__ */
