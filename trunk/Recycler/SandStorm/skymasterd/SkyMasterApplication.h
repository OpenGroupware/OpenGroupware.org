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

#ifndef __SkyMasterDaemon__SkyMasterApplication_H__
#define __SkyMasterDaemon__SkyMasterApplication_H__

#include <NGObjWeb/WOApplication.h>

@class NSString, NSDictionary, NSTimer, NSMutableDictionary;
@class MasterTask, TaskTemplate, AutostartInstance;

@interface SkyMasterApplication : WOApplication
{
  NSMutableDictionary *taskTemplates;
  NSMutableDictionary *tasks;
  NSMutableDictionary *instances;
  NSTimer             *taskCheckTimer;
  BOOL                performAutostart;
  BOOL                performCheck;

  int                 serverStatusFlag;
  int                 checkInterval;
  int                 priority;
  int                 restartDelay;
  int                 startCount;
  int                 startInterval;
}

/* accessors */

- (NSDictionary *)tasks;
- (NSDictionary *)taskTemplates;
- (NSDictionary *)instances;
- (NSString *)configFile;
- (NSString *)autostartConfigFileName;
- (NSString *)pidFile;
- (NSString *)pidDirectory;
- (NSString *)defaultConfigFileName;
- (NSString *)templateDirectory;
- (NSString *)instanceDirectory;

- (int)priority;
- (int)restartDelay;
- (int)startCount;
- (int)startInterval;

/* actions */

- (void)setServerGlobalValues;
- (MasterTask *)taskForProcessId:(NSString *)_processId;
- (id)startNewTask:(NSString *)_name
  withTemplate:(TaskTemplate *)_template
  arguments:(NSDictionary *)_arguments
  asRequiredTask:(BOOL)_required;
- (id)stopTasksWithTaskClass:(NSString *)_taskClass;
- (id)restartTasksWithTaskClass:(NSString *)_taskClass;

- (void)addTask:(MasterTask *)_task;
- (void)removeTask:(NSString *)_processId;

- (id)reloadTaskTemplates;
- (NSString *)serverStatus;

@end /* SkyMasterApplication */

@interface SkyMasterApplication(PrivateMethods)
- (void)_addTemplate:(TaskTemplate *)_template;
- (id)_loadConfigFile:(NSString *)_configFile;
- (id)_loadAutostartConfig:(NSString *)_configFile;
- (void)_loadTemplatesFromDirectory:(NSString *)_directory;
- (NSArray *)_loadAutostartInstancesFromDirectory:(NSString *)_directory;
- (BOOL)_createPidFile;
@end /* SkyMasterApplication(PrivateMethods) */


#endif /* __SkyMasterDaemon__SkyMasterApplication_H__ */
