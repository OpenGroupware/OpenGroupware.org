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

#include "SkyMasterApplication.h"
#include "common.h"
#include "MasterTask.h"
#include "SkyMasterAction.h"
#include "TaskTemplate+Logic.h"
#include "AutostartInstance+Logic.h"
#include "SkyMasterConfig.h"
#include "AutostartConfig.h"

#include <signal.h>
#include <unistd.h>

#define STATUS_STARTING_UP 100
#define STATUS_RUNNING     101

@interface DirectAction : SkyMasterAction
@end

@implementation DirectAction
@end /* DirectAction */

@interface WOApplication(TerminateOnSignal)
- (void)terminateOnSignal:(int)_signal;
@end /* WOApplication(TerminateOnSignal) */

@implementation SkyMasterApplication

static int instanceSort(AutostartInstance *instance1,
                        AutostartInstance *instance2,
                        void *context)
{
  int v1 = [[instance1 priority] intValue];
  int v2 = [[instance2 priority] intValue];
  if (v1 < v2)
    return NSOrderedAscending;
  else if (v1 > v2)
    return NSOrderedDescending;
  else
   return NSOrderedSame;
}

static BOOL isConfigFile(id _file) {
  if ([[_file pathExtension] isEqualToString:@"xml"]) return YES;
  return NO;
}

static void _exitNow(int sig) {
  exit(1);
}

+ (NSString *)defaultRequestHandlerClassName {
  return @"NGXmlRpcRequestHandler";
}

- (WORequestHandler *)handlerForRequest:(WORequest *)_request {
  if ([[_request method] isEqualToString:@"POST"])
    return [self defaultRequestHandler];
  else
    return [self requestHandlerForKey:@"wa"];
}

- (void)_setupDefaults {
  static int didInitDefs = NO;
  if (!didInitDefs) {
    NSUserDefaults *ud;
    NSDictionary *defs;
    didInitDefs = YES;

    defs = [NSDictionary dictionaryWithObjectsAndKeys:
                         [NSNumber numberWithBool:YES], @"SMPerformCheck",
                         [NSNumber numberWithBool:YES], @"SMPerformAutostart",
                         [NSNumber numberWithInt:30],   @"SMCheckInterval",
                         [NSNumber numberWithInt:50],   @"SMPriority",
                         [NSNumber numberWithInt:1],    @"SMRestartDelay",
                         [NSNumber numberWithInt:5],    @"SMStartCount",
                         [NSNumber numberWithInt:20],   @"SMStartInterval",
                         nil];
    
    ud = [NSUserDefaults standardUserDefaults];
    [ud registerDefaults:defs];
  }
}

- (id)init {
  [self _setupDefaults];
  if ((self = [super init])) {
    NSNotificationCenter *nc         = nil;
    NSString             *configPath = nil;

    self->serverStatusFlag = STATUS_STARTING_UP;

    /* when changing this, also change RegistryTask ! */
    [NGXmlRpcAction registerActionClass:[SkyMasterAction class]
                    forURI:@"/RPC2"];
    [SkyMasterAction registerMappingsInFile:@"SkyMasterActionMap"];
    
    if (![self _createPidFile]) {
      RELEASE(self);
      return nil;
    }

    self->tasks         = [[NSMutableDictionary alloc] initWithCapacity:8];
    self->taskTemplates = [[NSMutableDictionary alloc] initWithCapacity:8];
    self->instances     = [[NSMutableDictionary alloc] initWithCapacity:8];

    /* autoregister notifications */
    nc = [NSNotificationCenter defaultCenter];

#if 0    
    [nc addObserver:self selector:@selector(unregisterFromRegistry:)
        name:WOApplicationWillTerminateNotification
        object:self];
#endif
    
    /* start processes after the daemon has started up */
    [nc addObserver:self selector:@selector(autostartProcesses:)
        name:WOApplicationDidFinishLaunchingNotification
        object:self];
    
    [[UnixSignalHandler sharedHandler] addObserver:self
                                       selector:@selector(sigHUP:)
                                       forSignal:SIGHUP
                                       immediatelyNotifyOnSignal:NO];

    /* apply defaults */
    [self setServerGlobalValues];

    /* load main config file if available */
    if ((configPath = [self configFile])) {
      if (![self _loadConfigFile:configPath])
        [self debugWithFormat:@"did not load config file '%@' ..", configPath];
    }
    
    /* load config file templates */
    [self _loadTemplatesFromDirectory:[self templateDirectory]];
  }
  return self;
}

- (void)dealloc {
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  
  [nc removeObserver:self
      name:WOApplicationDidFinishLaunchingNotification
      object:self];
  [nc removeObserver:self 
      name:WOApplicationWillTerminateNotification
      object:self];
  
  RELEASE(self->tasks);
  RELEASE(self->taskTemplates);
  RELEASE(self->instances);
  RELEASE(self->taskCheckTimer);
  [super dealloc];
}

/* accessors */

- (NSDictionary *)tasks {
  return (NSDictionary *)self->tasks;
}

- (NSDictionary *)taskTemplates {
  return self->taskTemplates;
}

- (NSDictionary *)instances {
  return self->instances;
}

- (void)setPerformAutostart:(BOOL)_autostart {
  self->performAutostart = _autostart;
}

- (void)setPerformCheck:(BOOL)_check {
  self->performCheck = _check;
}

- (void)setCheckInterval:(int)_interval {
  self->checkInterval = _interval;
}

- (void)setPriority:(int)_priority {
  self->priority = _priority;
}
- (int)priority {
  return self->priority;
}

- (void)setRestartDelay:(int)_delay {
  self->restartDelay = _delay;
}
- (int)restartDelay {
  return self->restartDelay;
}

- (void)setStartCount:(int)_count {
  self->startCount = _count;
}
- (int)startCount {
  return self->startCount;
}

- (void)setStartInterval:(int)_interval {
  self->startInterval = _interval;
}
- (int)startInterval {
  return self->startInterval;
}

- (NSString *)userDirectory {
#if COCOA_Foundation_LIBRARY
  return [[[NSProcessInfo processInfo]
                          environment]
                          objectForKey:@"HOME"];
#else
  return [[[NSProcessInfo processInfo]
                          environment]
                          objectForKey:@"GNUSTEP_USER_ROOT"];
#endif
}

- (NSString *)configDirectory {
  return [[self userDirectory] stringByAppendingPathComponent:@"config"];
}

- (NSString *)templateDirectory {
  return [[self configDirectory] stringByAppendingPathComponent:@"skymasterd"];
}

- (NSString *)instanceDirectory {
  return [[self configDirectory] stringByAppendingPathComponent:
                                 @"skymasterd-instances"];
}

- (NSString *)pidDirectory {
  return [[self userDirectory] stringByAppendingPathComponent:@"run"];
}

- (NSString *)autostartConfigFileName {
  return [[self configDirectory] stringByAppendingPathComponent:
                                 @"skymasterd-instances.xml"];
}

- (NSString *)defaultConfigFileName {
  NSString      *fileName;
  NSFileManager *fm;

  fm = [NSFileManager defaultManager];

  fileName = [[self configDirectory] stringByAppendingPathComponent:
                                     @"skymasterd.xml"];

  if(![fm fileExistsAtPath:fileName]) {
    return nil;
  }
  return fileName;
}

- (NSString *)pidFile {
  NSString *fileName;
  
  fileName = [NSString stringWithFormat:@"%@.pid",
                       [[NSProcessInfo processInfo] processName]];
  return [[self pidDirectory] stringByAppendingPathComponent:fileName];
}

- (NSUserDefaults *)userDefaults {
  return [NSUserDefaults standardUserDefaults];
}

- (NSString *)configFile {
  NSString *configPath;

  if((configPath = [[self userDefaults] objectForKey:@"f"]) == nil)
    configPath = [self defaultConfigFileName];

  return configPath;
}

/* actions */

- (void)autostartProcesses:(NSNotification *)_notification {
  if (self->performAutostart) {
    [self _loadAutostartConfig:[self autostartConfigFileName]];
  }
  self->serverStatusFlag = STATUS_RUNNING;
}

- (BOOL)boolDefaultForKey:(NSString *)_key {
  return [[[self userDefaults] objectForKey:_key] boolValue];
}

- (BOOL)intDefaultForKey:(NSString *)_key {
  return [[[self userDefaults] objectForKey:_key] intValue];
}

- (void)setServerGlobalValues {
  [self setPerformAutostart:[self boolDefaultForKey:@"SMPerformAutostart"]];
  [self setPerformCheck:[self boolDefaultForKey:@"SMPerformCheck"]];

  [self setCheckInterval:[self intDefaultForKey:@"SMCheckInterval"]];
  [self setPriority:[self intDefaultForKey:@"SMPriority"]];
  [self setRestartDelay:[self intDefaultForKey:@"SMRestartDelay"]];
  [self setStartCount:[self intDefaultForKey:@"SMStartCount"]];
  [self setStartInterval:[self intDefaultForKey:@"SMStartInterval"]];

#if 0  
  [self logWithFormat:@"Server settings"];
  [self logWithFormat:@"Autostart : %@  - Check : %@",
        (self->performAutostart == 1) ? @"YES" : @"NO",
        (self->performCheck == 1) ? @"YES" : @"NO"];
  [self logWithFormat:@"CheckInterval : %ds  - DefPrio : %d - Restart : %ds",
        self->checkInterval, self->priority, self->restartDelay];
  [self logWithFormat:@"StartCount : %d  - StartInterval : %ds",
        self->startCount, self->startInterval];
#endif
}

- (id)startNewTask:(NSString *)_name
      withTemplate:(TaskTemplate *)_template
         arguments:(NSDictionary *)_arguments
    asRequiredTask:(BOOL)_requiredTask
{
  id task;
   
  if (![self isTerminating]) {
    if (_template == nil) {
      [self logWithFormat:@"no such template '%@'", _template];
    }
    else {
      if ((task = [_template taskFromTemplate]) != nil) {
        id result;

        [task setTaskName:_name];
        [task setIsRequiredTask:_requiredTask];
      
        if ([_template singleton]) {
          NSEnumerator *taskEnum;

          id aTask;

          taskEnum = [self->tasks objectEnumerator];
          while((aTask = [taskEnum nextObject])) {
            if([aTask isRunning] && [[aTask taskName] isEqualToString:_name]) {
              [self logWithFormat:
                    @"trying to start already running singleton class '%@'",
                    _name];
              return [NSNumber numberWithBool:NO];
            }
          }
        }

        if ((result = [task start:_arguments]) != nil) {
          [self addTask:task];
          return result;
        }
      }

      if ([[_template required] boolValue]) {
        [self logWithFormat:@"ERROR: couldn't start required task, shutdown"];
        [self terminate];
      }
    }
  }
  return [NSNumber numberWithBool:NO];
}

- (NSArray *)tasksForTaskClass:(NSString *)_taskClass {
  NSEnumerator   *taskEnum;
  MasterTask     *task;
  NSMutableArray *result;
  
  if([self->taskTemplates objectForKey:_taskClass] == nil) {
    [self logWithFormat:@"No such task class: '%@'", _taskClass];
    return nil;
  }

  result = [NSMutableArray arrayWithCapacity:[[self tasks] count]];
  
  taskEnum = [[self tasks] objectEnumerator];

  while((task = [taskEnum nextObject])) {
    if([[task templateClass] isEqualToString:_taskClass]) {
      [result addObject:task];
    }
  }
  return result;
}

- (NSArray *)tasksForInstanceNamed:(NSString *)_instanceName {
  NSEnumerator   *taskEnum;
  MasterTask     *task;
  NSMutableArray *result;
  
  if([self->instances objectForKey:_instanceName] == nil) {
    [self logWithFormat:@"no such instance '%@'", _instanceName];
    return nil;
  }

  result = [NSMutableArray arrayWithCapacity:[[self tasks] count]];
  
  taskEnum = [[self tasks] objectEnumerator];

  while((task = [taskEnum nextObject])) {
    if([[task taskName] isEqualToString:_instanceName]) {
      [result addObject:task];
    }
  }
  return result;  
}

- (id)stopTasksWithTaskClass:(NSString *)_taskClass {
  NSArray *matchingTasks;
  NSEnumerator *taskEnum;
  MasterTask* task;

  if ((matchingTasks = [self tasksForInstanceNamed:_taskClass]) == nil)
    matchingTasks = [self tasksForTaskClass:_taskClass];

  if ([matchingTasks count] == 0)
    return [NSNumber numberWithBool:NO];    
    
  taskEnum = [matchingTasks objectEnumerator];
  while((task = [taskEnum nextObject])) {
    if ([task stop] == RETURN_CODE_ERROR) return [NSNumber numberWithBool:NO];
  }
  return [NSNumber numberWithBool:YES];
}

- (id)restartTasksWithTaskClass:(NSString *)_taskClass {
  NSArray        *matchingTasks;
  NSMutableArray *result;
  NSEnumerator   *taskEnum;
  MasterTask     *task;

  if ((matchingTasks = [self tasksForInstanceNamed:_taskClass]) == nil)
    matchingTasks = [self tasksForTaskClass:_taskClass];
  
  if ([matchingTasks count] == 0)
    return [NSNumber numberWithBool:NO];    

  taskEnum = [matchingTasks objectEnumerator];
  result = [NSMutableArray arrayWithCapacity:[matchingTasks count]];

  while((task = [taskEnum nextObject])) {
    id pid;
    if ((pid = [task restart]) != nil)
      [result addObject:pid];
  }
  return result;
}

- (id)reloadTaskTemplates {
  [self logWithFormat:@"reloading task templates"];
  [self->taskTemplates removeAllObjects];
  
  [self _loadConfigFile:[self configFile]];
  [self _loadTemplatesFromDirectory:[self templateDirectory]];
   
  return [NSNumber numberWithBool:YES];  
}

- (NSString *)serverStatus {
  switch (self->serverStatusFlag) {
    case STATUS_STARTING_UP:
      {
        return @"starting";
        break;
      }
    case STATUS_RUNNING:
      {
        return @"running";
        break;
      }
  }
  return nil;
}

- (void)sigHUP:(int)_signal {
  [self reloadTaskTemplates];
}

- (MasterTask *)taskForProcessId:(NSString *)_pid {
  if ([_pid length] == 0) return nil;
  return [self->tasks objectForKey:_pid];
}

- (void)terminateOnSignal:(int)_signal {
  /* overrides WOApplication signal handler !!! */
  if (_signal != SIGHUP) {
    signal(SIGALRM, _exitNow);
    alarm(10);
    [super terminateOnSignal:_signal];
  }
}

- (void)tearDown {
  [[UnixSignalHandler sharedHandler] removeObserver:self];

  [[self->tasks allValues]
                makeObjectsPerformSelector:@selector(stopWithApplication:)
                withObject:self];
  [[NSFileManager defaultManager] removeFileAtPath:[self pidFile]
                                  handler:nil];
}

- (void)run {
  [super run];
  [self tearDown];
}

- (void)addTask:(MasterTask *)_task {
  if (_task != nil && ![self isTerminating]) {
    [self debugWithFormat:@"adding task: %@", [_task taskName]];
    if ([_task processId] != nil)
      [self->tasks setObject:_task forKey:[_task processId]];
    else {
      [self debugWithFormat:@"task '%@' has no valid PID", [_task taskName]];
    }
  }
}

- (void)removeTask:(NSString *)_processId {
  [self debugWithFormat:@"removing task: %@", _processId];
  [self->tasks removeObjectForKey:_processId];
}

- (void)checkRunningTasks:(NSTimer *)_timer {
  [[[self tasks] allValues] makeObjectsPerformSelector:
                            @selector(checkTask)];
}

@end /* SkyMasterApplication */

@implementation SkyMasterApplication(PrivateMethods)

- (BOOL)_anontherDaemonInstanceIsRunning {
  NSString      *pidFileName;
  NSFileManager *fm;

  fm = [NSFileManager defaultManager];
  pidFileName = [self pidFile];

  if([fm fileExistsAtPath:pidFileName]) {
    NSString *pid;
    NSString *processPath;
    BOOL     isDir;
      
    pid = [NSString stringWithContentsOfFile:pidFileName];
    processPath = @"/proc";
    processPath = [processPath stringByAppendingPathComponent:pid];

    if([fm fileExistsAtPath:processPath isDirectory:&isDir] && isDir) {
      [self logWithFormat:
            @"Master daemon already running at PID %@", pid];
      return YES;
    }
  }
  return NO;
}

- (BOOL)_createPidFile {
  NSString      *pidFilePath;
  NSString      *pidFileName;
  NSFileManager *fm;
  BOOL          isDir;

  fm = [NSFileManager defaultManager];
  
  pidFilePath = [self pidDirectory];
  if (![fm fileExistsAtPath:pidFilePath isDirectory:&isDir]) {
    [fm createDirectoryAtPath:pidFilePath attributes:nil];
  }
    
  pidFileName = [self pidFile];
  if(![self _anontherDaemonInstanceIsRunning]) {
    NSString *pid;
    
    pid = [NSString stringWithFormat:@"%d", getpid()];

    if (pid) {
      if(![pid writeToFile:pidFileName atomically:NO]) {
        [self logWithFormat:@"ERROR: couldn't write PID file"];
        return NO;
      }
      return YES;
    }
  }
  return NO;
}

- (id)_autostartInstances:(NSArray *)_instances {
  NSEnumerator      *instanceEnum;
  AutostartInstance *instance;
  id result;
  
  _instances = [_instances sortedArrayUsingFunction:instanceSort context:nil];
  
  instanceEnum = [_instances objectEnumerator];
  while((instance = [instanceEnum nextObject])) {
    TaskTemplate *template;

    template = [self->taskTemplates objectForKey:[instance templateclass]];
    if (template == nil) {
      [self logWithFormat:
            @"ERROR: Invalid template class '%@'", [instance templateclass]];
    }
    else {
      NSString *taskName;

      if ((taskName = [instance uid]) == nil) {
        taskName = [instance templateclass];
      }

      result = [self startNewTask:[instance instanceName]
                     withTemplate:template
                     arguments:[instance parametersAsDictionary]
                     asRequiredTask:[[instance required] boolValue]];
      if (result == nil && [instance required]) {
        [self logWithFormat:@"couldn't start required task"];
        return nil;
      }
    }
  }
  return result;
}

- (AutostartInstance *)instanceFromFile:(NSString *)_fileName {
  AutostartInstance* instance = nil;
  
  instance = [[AutostartInstance alloc] initWithContentsOfFile:_fileName];

  if(instance != nil) {
    return AUTORELEASE(instance);
  }
  else {
    [self debugWithFormat:@"ERROR while laoding instance"];
    return nil;
  }
}

- (void)_addTemplateFromFile:(NSString *)_fileName {
  id template = nil;
  
  template = [[TaskTemplate alloc] initWithContentsOfFile:_fileName];

  if(template != nil) {
    [self _addTemplate:template];
    RELEASE(template); template = nil;
  }
  else {
    [self debugWithFormat:@"ERROR while laoding template"];
  }
}

- (void)_addTemplate:(TaskTemplate *)_template {
  if (_template == nil)
    return;

  if ([_template templateclass] == nil) {
    [self logWithFormat:@"ERROR: template without templateclass found"];
    return;
  }

  [self debugWithFormat:@"adding template '%@'", [_template templateclass]];
  [self->taskTemplates setObject:_template forKey:[_template templateclass]];
}

- (NSArray *)_configFilesForDirectory:(NSString *)_directory {
  BOOL isDir;
  NSFileManager *fm;
  
  if (_directory == nil)
    return nil;

  fm = [NSFileManager defaultManager];
  
  if ([fm fileExistsAtPath:_directory isDirectory:&isDir]) {
    if (isDir) 
      return [[fm directoryContentsAtPath:_directory]
                  arrayWithObjectsThat:isConfigFile];
  }
  return nil;
}

- (NSArray *)_loadAutostartInstancesFromDirectory:(NSString *)_directory {
  NSArray        *files;
  NSEnumerator   *fileEnum;
  id             file;
  NSMutableArray *result;

  if (_directory == nil)
    return nil;
  
  [self debugWithFormat:@"loading instances from directory: '%@'",
          _directory];

  files = [self _configFilesForDirectory:_directory];

  fileEnum = [files objectEnumerator];

  result = [NSMutableArray arrayWithCapacity:[files count]];
  
  while((file = [fileEnum nextObject])) {
     NSString          *fileName;
     AutostartInstance *instance;
     
     fileName = [_directory stringByAppendingPathComponent:file];
     if ((instance = [self instanceFromFile:fileName]) != nil)
       [result addObject:instance];
  }

  return result;
}
  
- (void)_loadTemplatesFromDirectory:(NSString *)_directory {
  NSArray      *files;
  NSEnumerator *fileEnum;
  id           file;
  
  [self debugWithFormat:@"loading templates from directory: '%@'",
          _directory];
  
  files = [self _configFilesForDirectory:_directory];
  fileEnum = [files objectEnumerator];
    
  while((file = [fileEnum nextObject])) {
     NSString *fileName;

     fileName = [_directory stringByAppendingPathComponent:file];
     [self _addTemplateFromFile:fileName];
  }
}

- (void)_loadXMLConfigFile:(NSString *)_configFile {
  SkyMasterConfig *config;
  NSEnumerator *templateEnum;
  TaskTemplate *template;

  config = [[SkyMasterConfig alloc] initWithContentsOfFile:_configFile];
      
  templateEnum = [[config templates] objectEnumerator];
  while((template = [templateEnum nextObject])) {
    [self _addTemplate:template];
  }
}

- (void)addInstance:(AutostartInstance *)_instance {

  if (_instance != nil) {
    [self->instances setObject:_instance forKey:[_instance instanceName]];
  }
  else {
    [self debugWithFormat:@"tried to add invalid instance"];
  }
}

- (void)addInstances:(NSArray *)_instances {
  NSEnumerator      *instanceEnum;
  AutostartInstance *instance;

  instanceEnum = [_instances objectEnumerator];
  while ((instance = [instanceEnum nextObject])) {
    [self addInstance:instance];
  }
}

- (id)_loadAutostartConfig:(NSString *)_configFile {
  AutostartConfig *config = nil;
  NSMutableArray  *configInstances;
  NSArray         *instancesFromFile;
  
  if(_configFile == nil) {
    [self logWithFormat:@"no instance config file name set"];
    return nil;
  }

  if([[NSFileManager defaultManager] fileExistsAtPath:_configFile]) {
    config = [[AutostartConfig alloc] initWithContentsOfFile:_configFile];
    configInstances = (NSMutableArray *)[config instances];
  }
  else {
    configInstances = [NSMutableArray arrayWithCapacity:4];
  }

  instancesFromFile = [self _loadAutostartInstancesFromDirectory:
                            [self instanceDirectory]];

  if (instancesFromFile != nil)
    [configInstances addObjectsFromArray:instancesFromFile];

  [self addInstances:configInstances];

  if([self _autostartInstances:configInstances] == nil) {
    return nil;
  }
  
  RELEASE(config); config = nil;
  return nil;
}

- (id)_loadConfigFile:(NSString *)_configFile {
  BOOL fileExists = NO;

  if (_configFile != nil)
    fileExists = [[NSFileManager defaultManager] fileExistsAtPath:_configFile];
  
  if (!fileExists) {
    [self logWithFormat:@"ERROR: invalid config file path '%@'", _configFile];
    return NO;
  }
  
  [self _loadXMLConfigFile:_configFile];

  if (self->performCheck) {
    [self debugWithFormat:@"enabling task check with %ds interval",
          self->checkInterval];
    self->taskCheckTimer = [[NSTimer scheduledTimerWithTimeInterval:
                                     self->checkInterval
                                     target:self
                                     selector:@selector(checkRunningTasks:)
                                     userInfo:nil repeats:YES] retain];
  }
  return [NSNumber numberWithBool:YES];
}

@end /* SkyMasterApplication(PrivateMethods) */
