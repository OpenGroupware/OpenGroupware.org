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

#ifndef __zOGIAction_Project_H__
#define __zOGIAction_Project_H__

#include "zOGIAction.h"

@interface zOGIAction(Project)

-(NSMutableArray *)_renderProjects:(NSArray *)_projects withDetail:(NSNumber *)_detail;
-(id)_getUnrenderedProjectsForKeys:(id)_arg;
-(id)_getProjectsForKeys:(id)_arg withDetail:(NSNumber *)_detail;
-(id)_getProjectsForKeys:(id)_pk;
-(id)_getProjectForKey:(id)_pk withDetail:(NSNumber *)_detail;
-(id)_getProjectForKey:(id)_pk;
-(void)_addContactsToProject:(NSMutableDictionary *)_project;
-(void)_addEnterprisesToProject:(NSMutableDictionary *)_project;
-(void)_addNotesToProject:(NSMutableDictionary *)_project;
-(void)_addTasksToProject:(NSMutableDictionary *)_project;
-(NSArray *)_getFavoriteProjects:(NSNumber *)_detail;
-(void)_unfavoriteProject:(NSString *)projectId;
-(void)_favoriteProject:(NSString *)projectId;

-(id)_searchForProjects:(NSDictionary *)_query 
             withDetail:(NSNumber *)_detail
              withFlags:(NSDictionary *)_flags;

-(id)_translateProject:(NSDictionary *)_project;

-(id)_createProject:(NSDictionary *)_projectId 
          withFlags:(NSArray *)_flags;

-(id)_updateProject:(NSDictionary *)_projectId
           objectId:(NSString *)objectId 
          withFlags:(NSArray *)_flags;

-(id)_writeProject:(NSDictionary *)_project 
       withCommand:(NSString *)_command
         withFlags:(NSArray *)_flags;

-(id)_deleteProject:(id)_objectId
          withFlags:(NSArray *)_flags;

-(NSArray *)_diffProjectPartners:(NSArray *)_list1 with:(NSArray *)_list2;

@end

#endif /* __zOGIAction_Project_H__ */
