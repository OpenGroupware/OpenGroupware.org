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

#ifndef __SkyMasterDaemon_MasterTask_H__
#define __SkyMasterDaemon_MasterTask_H__

#import <Foundation/NSObject.h>

@class NSTask, NSString, NSDictionary, NSTimer;
@class TaskTemplate;

@interface MasterTask : NSObject
{
  NSTask         *task;
  NSTimer        *startTimer;
  NSString       *taskName;
  NSString       *templateClass;
  NSString       *processId;
  NSString       *executable;
  NSString       *commandLine;
  NSString       *stdoutLogFileName;
  NSString       *stderrLogFileName;
  NSString       *pidFile;
  NSDictionary   *arguments;
  NSDictionary   *defaultArguments;
  
  int            restartDelay;
  int            counter;
  int            startDelay;
  int            startCount;
  int            startInterval;
  int            statusFlag;
  BOOL           canBeZombified;
  BOOL           isRequiredTask;
  BOOL           autoRestart;
  BOOL           shouldAlwaysBeRunning;
  BOOL           startTask;
  BOOL           isSingleton;
  BOOL           hasBeenStopped;
}

/* initialization */

- (id)initWithTemplate:(TaskTemplate *)_template;

/* accessors */

- (NSString *)taskName;
- (NSString *)templateClass;
- (void)setTaskName:(NSString *)_taskName;

- (NSString *)executable;
- (NSString *)processId;
- (NSString *)stdoutLogFileName;
- (NSString *)stderrLogFileName;
- (NSDictionary *)defaultArguments;
- (NSString *)uniquePid;

- (int)terminationStatus;
- (int)statusFlag;
- (BOOL)autoRestart;
- (BOOL)canBeZombified;

- (void)startWithApplication:(id)_app;
- (void)stopWithApplication:(id)_app;
- (void)checkTask;

- (void)postProcessTaskTermination:(int)_terminationStatus;
- (void)setIsRequiredTask:(BOOL)_isRequired;

/* commands (/etc/init.d/ scripts alike) */

- (id)start:(id)_arguments;
- (int)stop;
- (BOOL)status;
- (BOOL)tryRestart;
- (id)restart;

@end /* MasterTask */

#endif /* __SkyMasterDaemon_MasterTask_H__ */
