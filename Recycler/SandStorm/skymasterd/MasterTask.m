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

#include "MasterTask.h"
#include "SkyMasterApplication.h"
#include "TaskTemplate+Logic.h"
#include "DaemonTask.h"
#include "common.h"

#include <unistd.h>

@interface MasterTask(PrivateMethods)
- (NSString *)defaultPidFileName;
- (void)_ensureLogFileDirectoryExists:(NSString *)_logFileName;
- (NSString *)_pidFileForTemplate:(TaskTemplate *)_template;
- (NSDictionary *)_defaultArgumentsForTemplate:(TaskTemplate *)_template;
- (NSDictionary *)environment;
- (NSFileManager *)fileManager;
- (NSNotificationCenter *)notificationCenter;
@end /* MasterTask(PrivateMethods) */

@implementation MasterTask

/* initialization */

- (id)init {
  return [self initWithTemplate:nil];
}

- (id)initWithTemplate:(TaskTemplate *)_template {
  if ((self = [super init])) {
    NSString              *pathName;

    self->statusFlag            = 0;
    self->counter               = 0;
    self->startTask             = YES;
    self->taskName              = [[_template templateclass] copy];
    self->templateClass         = [[_template templateclass] copy];
    self->commandLine           = [[_template cmdline]       copy];
    self->shouldAlwaysBeRunning = [[_template runcheck]      boolValue];
    self->isSingleton           = [[_template singleton]     boolValue];
    self->canBeZombified        = [[_template zombieable]    boolValue];
    self->autoRestart           = [[_template autorestart]   boolValue];
    self->restartDelay          = [[_template restartdelay]  intValue];
    self->startDelay            = [[_template startdelay]    intValue];
    self->startCount            = [[_template startcount]    intValue];
    self->startInterval         = [[_template startinterval] intValue];
    
    if ((pathName = [_template executablePath]) == nil) {
      [self logWithFormat:@"executable for template '%@' could not be found",
            self->templateClass];
      RELEASE(self);
      return nil;
    }
  
    if (![[self fileManager] isExecutableFileAtPath:pathName]) {
      [self logWithFormat:@"'%@': invalid executable file  '%@'",
            self->taskName, pathName];
      RELEASE(self);
      return nil;
    }

    self->executable = [pathName copy];
    self->pidFile    = [[self _pidFileForTemplate:_template] copy];
    self->defaultArguments = [[self _defaultArgumentsForTemplate:_template]
                                    copy];
  }
  return self;
}

- (void)dealloc {
  [[self notificationCenter]
         removeObserver:self
         name:NSTaskDidTerminateNotification
         object:self->task];

  RELEASE(self->taskName);
  RELEASE(self->templateClass);
  RELEASE(self->task);
  RELEASE(self->pidFile);
  RELEASE(self->processId);
  RELEASE(self->executable);
  RELEASE(self->commandLine);
  RELEASE(self->arguments);
  RELEASE(self->defaultArguments);
  RELEASE(self->stdoutLogFileName);
  RELEASE(self->stderrLogFileName);
  RELEASE(self->startTimer);
  [super dealloc];
}

/* accessors */

- (NSDictionary *)environment {
  return [[NSProcessInfo processInfo] environment];
}

- (NSFileManager *)fileManager {
  return [NSFileManager defaultManager];
}

- (NSNotificationCenter *)notificationCenter {
  return [NSNotificationCenter defaultCenter];
}

- (SkyMasterApplication *)application {
  static Class AppClass = Nil;
  if (AppClass == Nil) AppClass = [SkyMasterApplication class];
  return [AppClass application];
}

- (NSString *)taskName {
  return self->taskName;
}

- (NSString *)templateClass {
  return self->templateClass;
}

- (void)setTaskName:(NSString *)_taskName {
  ASSIGNCOPY(self->taskName, _taskName);
}

- (NSString *)executable {
  return self->executable;
}

- (NSString *)stdoutLogFileName {
  return self->stdoutLogFileName;
}

- (NSString *)stderrLogFileName {
  return self->stderrLogFileName;
}

- (NSString *)processId {
  return self->processId;
}

- (NSDictionary *)defaultArguments {
  return self->defaultArguments;
}

- (BOOL)isSingleton {
  return self->isSingleton;
}

- (BOOL)isRunning {
  return [self->task isRunning];
}

- (BOOL)autoRestart {
  return self->autoRestart;
}

- (BOOL)canBeZombified {
  return self->canBeZombified;
}

- (int)statusFlag {
  return self->statusFlag;
}

- (int)terminationStatus {
  return [self->task terminationStatus];
}

- (void)setIsRequiredTask:(BOOL)_isRequired {
  self->isRequiredTask = _isRequired;
} 

- (NSString *)pidFile {
  return self->pidFile;
}

- (NSString *)userDirectory {
#if COCOA_Foundation_LIBRARY
  return [[self environment] objectForKey:@"HOME"];
#else
  return [[self environment] objectForKey:@"GNUSTEP_USER_ROOT"];
#endif
}

- (NSString *)defaultPidFileName {
  NSString *pidFilePath;
  
  pidFilePath = [[self userDirectory] stringByAppendingPathComponent:@"run"];
  pidFilePath = [pidFilePath stringByAppendingPathComponent:
                             [self templateClass]];
  pidFilePath = [pidFilePath stringByAppendingString:@".pid"];

  return pidFilePath;
}

- (NSString *)loggingPrefix {
  return [NSString stringWithFormat:@"%@[%@]",
                     NSStringFromClass([self class]), self->taskName];
}

- (NSString *)uniquePid {
  NSString *uniquePart;

  uniquePart = [[NSDate date] descriptionWithCalendarFormat:@"%Y%m%d%H%M%S"
                              timeZone:nil locale:nil];
  return [@"PID." stringByAppendingString:uniquePart];
}

- (NSString *)logFileDirectory {
  return [[self userDirectory] stringByAppendingPathComponent:@"logs"];
}

- (NSString *)defaultStdoutLogFileName {
  return [[[self logFileDirectory]
                 stringByAppendingPathComponent:[self taskName]]
                 stringByAppendingString:@".out"];
}

- (NSString *)defaultStderrLogFileName {
  return [[[self logFileDirectory]
                 stringByAppendingPathComponent:[self taskName]]
                 stringByAppendingString:@".err"];
}

- (NSString *)uniqueProcessId {
  if (self->task != nil) {
    return [NSString stringWithFormat:@"%@.%d",
                     [self uniquePid],[self->task processId]];
  }
  return nil;
}

- (void)sleep:(NSTimeInterval)_interval {
  sleep(_interval);
}

- (NSString *)absolutePathStringForPathNamed:(NSString *)_path {
  return [[_path stringByReplacingVariablesWithBindings:[self environment]]
                 stringByExpandingTildeInPath];
}

- (NSDictionary *)_defaultArgumentsForTemplate:(TaskTemplate *)_template {
  NSMutableDictionary *defaults;
  NSEnumerator *defaultEnum;
  id defaultEntry;
  
  defaults = [[_template parametersAsDictionary] mutableCopy];
  defaultEnum = [defaults keyEnumerator];

  while((defaultEntry = [defaultEnum nextObject])) {
    NSString *value;

    value = [defaults objectForKey:defaultEntry];
    if ([value isKindOfClass:[NSString class]]) {
      [defaults setObject:[self absolutePathStringForPathNamed:value]
                forKey:defaultEntry];
    }
  }
  return defaults;
}

- (NSString *)_pidFileForTemplate:(TaskTemplate *)_template {
  NSString *pidFileLocation;

  if ((pidFileLocation = [_template pidfile]) == nil) {
    pidFileLocation = [self defaultPidFileName];
  }
  return [self absolutePathStringForPathNamed:pidFileLocation];
}

- (void)_ensureLogFileDirectoryExists:(NSString *)_logFileName {
  NSFileManager *fm;
  NSString      *directory;
  BOOL          isDir;
  
  fm = [self fileManager];
  directory = [_logFileName stringByDeletingLastPathComponent];
  
  if (!([fm fileExistsAtPath:directory isDirectory:&isDir] && isDir))
    [fm createDirectoryAtPath:directory attributes:nil];
  
  if (![fm fileExistsAtPath:_logFileName])
    [fm createFileAtPath:_logFileName contents:nil attributes:nil];
}

- (void)_resetTask {
  ASSIGN(self->task, nil);
}

- (void)postProcessTaskTermination:(int)_terminationStatus {
  SkyMasterApplication *app;

  app = [self application];

  if (![app isTerminating] && !self->hasBeenStopped && self->startTask) {
    if (self->autoRestart) {
      NSTimer *timer;
      NSArray *taskArguments;

      taskArguments = [self->task arguments];
    
      [self _resetTask];

      [self logWithFormat:@"autorestarting task in %ds", self->restartDelay];
      timer = [NSTimer scheduledTimerWithTimeInterval:self->restartDelay
                       target:self selector:@selector(startTask:)
                       userInfo:taskArguments repeats:NO];
      return;
    }
    else if (self->canBeZombified) {
      [self logWithFormat:@"task got zombified", [self taskName]];
      self->statusFlag = STATUS_FLAG_ZOMBIE;
      return;
    }
  }
  
  [self debugWithFormat:@"removing task %@", [self taskName]];
  [self _resetTask];    
  [app removeTask:[self processId]];

  self->hasBeenStopped = NO;
}

- (NSArray *)_convertArgumentDictionaryToArray:(NSDictionary *)_dict {
  NSMutableArray *result;
  NSEnumerator   *keyEnum;
  NSString       *key;

  result = [NSMutableArray arrayWithCapacity:[_dict count] * 2];

  keyEnum = [_dict keyEnumerator];
  while((key = [keyEnum nextObject])) {
    [result addObject:[@"-" stringByAppendingString:key]];
    [result addObject:[_dict objectForKey:key]];
  }
  return result;
}

- (void)_taskDidTerminate:(NSNotification *)_notification {
  int terminationStatus;

  if ([_notification object] != self->task) {
    [self logWithFormat:@"ERROR(%s): got incorrect task-did-terminate %@ ...",
          __PRETTY_FUNCTION__, _notification];
    return;
  }
  if ([self->task isRunning]) {
    [self logWithFormat:
            @"ERROR(%s): task-did-terminate received, "
            @"but task is still running %@ ...",
            __PRETTY_FUNCTION__, self->task];
    return;
  }

  if ((terminationStatus = [self->task terminationStatus]) != 0) {
    [self logWithFormat:@"terminated with exitcode: %i",
            [self->task terminationStatus]];
    if(![[self application] isTerminating]) {
      if(self->isRequiredTask && !self->hasBeenStopped) {
        [self logWithFormat:@"required task terminated, server shutdown"];
        [[self application] terminate];
      }
    }
  }
  else {
    [self debugWithFormat:@"terminated cleanly."];
  }
  [self postProcessTaskTermination:terminationStatus];
}

/* commands */

- (BOOL)launch {
  NSTimer     *timer;
  NSException *lastException = nil;

  NS_DURING {
    [self->task launch];
  }
  NS_HANDLER {
    *(&lastException) = RETAIN(localException);
  }
  NS_ENDHANDLER;
  
  if (lastException) {
    [self logWithFormat:@"CATCHED: %@", lastException];
    return NO;
  }

  if (self->startTask) {
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                     target:self selector:@selector(startUp:)
                     userInfo:nil repeats:NO];  
  }

  return [self->task isRunning];
}

- (void)checkTask {
  if (self->shouldAlwaysBeRunning && self->startTask) {
    if (![self isRunning]) {
      [self debugWithFormat:@"auto-restarting task '%@'", [self taskName]];
      [self _resetTask];
      [self start:[self defaultArguments]];
    }
  }
}

- (void)resetStartCount:(NSTimer *)_timer {
  [self->startTimer invalidate];
  self->counter = 0;
  RELEASE(self->startTimer); self->startTimer = nil;
}

- (void)initStartCounterTimer {
  NSTimeInterval i;
  
  i = self->startInterval;
  
  self->startTimer = [[NSTimer scheduledTimerWithTimeInterval:i
                               target:self
                               selector:@selector(resetStartCount:)
                               userInfo:nil
                               repeats:NO] retain];
}

- (void)tooManyStartsInTimeInterval {
  [self logWithFormat:@"WARNING: too many restarts in time interval"];
  self->startTask = NO;
}

- (NSFileHandle *)handleForFileAtPath:(NSString *)_path {
  NSFileHandle *handle;

  [self _ensureLogFileDirectoryExists:_path];
  handle = [NSFileHandle fileHandleForUpdatingAtPath:_path];
  [handle seekToEndOfFile];
  return handle;
}

- (NSFileHandle *)handleForStdoutLogFile {
  return [self handleForFileAtPath:self->stdoutLogFileName];
}

- (NSFileHandle *)handleForStderrLogFile {
  return [self handleForFileAtPath:self->stderrLogFileName];
}

- (BOOL)taskGetsPidFromFile {
  return NO;
}

- (BOOL)waitForPidFile {
  int sleepCount = 0, timeout = 5;
  
  if (self->pidFile == nil)
    return NO;
  
  sleepCount = 0;
  while (![[self fileManager] fileExistsAtPath:self->pidFile] &&
         sleepCount < timeout)
  {
    [self sleep:1];
    sleepCount += 1;
  }
  return sleepCount == timeout;
}

- (id)start:(id)_arguments {
  if (self->startTask) {
    NSArray  *args;
    NSString *argString;
    
    [self logWithFormat:@"starting task: %@", [self taskName]];

    if (self->counter == 0)
      [self initStartCounterTimer];

    self->counter++;
    if (self->counter == self->startCount) {
      [self tooManyStartsInTimeInterval];
    }
    
    if(self->task == nil) {
      self->task = [[NSTask alloc] init];
    }
    
    if (self->stdoutLogFileName == nil)
      self->stdoutLogFileName     = [[self defaultStdoutLogFileName] copy];
    if (self->stderrLogFileName == nil)
      self->stderrLogFileName     = [[self defaultStderrLogFileName] copy];

    [self->task setStandardOutput:[self handleForStdoutLogFile]];
    [self->task setStandardError:[self handleForStderrLogFile]];

    [self->task setLaunchPath:[self executable]];  
    
    if (_arguments != nil) {
      if ([_arguments isKindOfClass:[NSDictionary class]]) {
        if (self->commandLine == nil) {
          if (_arguments != nil)
            args = [self _convertArgumentDictionaryToArray:_arguments];
          else {
            args = [self _convertArgumentDictionaryToArray:
                         [self defaultArguments]];
          }
        }
        else {
          NSMutableDictionary *dict;

          dict = [NSMutableDictionary dictionaryWithCapacity:16];
          [dict addEntriesFromDictionary:[self defaultArguments]];

          if(_arguments != nil)
            [dict addEntriesFromDictionary:_arguments];
    
          argString = [self->commandLine
                           stringByReplacingVariablesWithBindings:dict];
          args = [argString componentsSeparatedByString:@" "];
        }
        [self->task setArguments:args];
      }
      else if ([_arguments isKindOfClass:[NSArray class]]) {
        [self->task setArguments:_arguments];
      }
    }

    [[self notificationCenter]
           addObserver:self selector:@selector(_taskDidTerminate:)
           name:NSTaskDidTerminateNotification object:self->task];

    if ([self launch]) {
      if ([self taskGetsPidFromFile]) {
        if ([self waitForPidFile]) {
          [self logWithFormat:
                @"pidfile creation of task '%@' timed out", [self taskName]];
          return [NSNumber numberWithBool:NO];
        }
      }

      /* reset process id */
      ASSIGN(self->processId, nil);
      self->processId = [[self uniqueProcessId] copy];
      
      [self logWithFormat:@"started task: %@", [self processId]];
      
      [self sleep:self->startDelay];
      return [self processId];
    }
    else {
      [self logWithFormat:@"could not launch task: %@", [self taskName]];
      return [NSNumber numberWithBool:NO];
    }
  }
  return [NSNumber numberWithBool:NO];
}

- (int)stop {
  if ([self->task isRunning]) {
    self->hasBeenStopped = YES;
    
    [self->task terminate];
    [self->task waitUntilExit];

    return [self->task terminationStatus];
  }
  return RETURN_CODE_ERROR;
}  

- (id)startTask:(NSTimer *)_timer {
  return [self start:[_timer userInfo]];
}

- (BOOL)startUp:(NSTimer *)_timer {
  BOOL hasStarted;  

  hasStarted = [self->task isRunning];
  
  if (!hasStarted)
    [self _resetTask];
  
  return hasStarted;
}

- (BOOL)status {
  return [self isRunning];
}

- (BOOL)tryRestart {
  if ([self stop]) {
    if ([self start:[self defaultArguments]] != nil)
      return YES;
  }
  return NO;
}

- (id)restart {
  id result = nil;
  id taskArguments;
  
  if([self->task isRunning]) {
    taskArguments = [self->task arguments];
    [self stop];    
  }
  else {
    taskArguments = [self defaultArguments];
  }
  
  if ((result = [self start:taskArguments]) != nil) {
    [[self application] addTask:self];
  }
  return result;
}

- (void)startWithApplication:(id)_app {
  if ([_app isTerminating]) return;
  [self start:[self defaultArguments]];
}

- (void)stopWithApplication:(id)_app {
  [self stop];
}

/* description */

- (NSString *)description {
  return [NSString stringWithFormat:@"<%p[%@]: %@>",
                     self, NSStringFromClass([self class]),
                     [self taskName]];
}

@end /* MasterTask */

