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

#include "DaemonTask.h"
#include "common.h"

#include <sys/types.h>
#include <signal.h>

@implementation DaemonTask

- (NSFileManager *)fileManager {
  return [NSFileManager defaultManager];
} 

- (NSString *)unixProcessId {
  if(![[self fileManager] fileExistsAtPath:self->pidFile]) {
    [self debugWithFormat:@"pidfile for '%@' doesn't (yet) exist",
          [self taskName]];
    return nil;
  }
  return [[NSString stringWithContentsOfFile:self->pidFile]
                    stringByReplacingString:@"\n" withString:@""];
}

- (NSString *)uniqueProcessId {
  if (self->task != nil) {
    return [NSString stringWithFormat:@"%@.%@",
                     [self uniquePid],[self unixProcessId]];
  }
  return nil;
}

- (BOOL)taskGetsTerminatedByCommand {
  return NO;
}

- (BOOL)taskGetsPidFromFile {
  return YES;
}

- (NSString *)terminationProgramPath {
  return nil;
}

- (NSArray *)terminationProgramArguments {
  return nil;
}

- (int)stopProcessWithCommand:(NSString *)_command
  arguments:(NSArray *)_arguments
{
  NSFileHandle *handle;
  NSTask       *aTask;
  int result = 0;
  
  handle = [NSFileHandle fileHandleForWritingAtPath:@"/dev/null"];
  
  aTask = [[NSTask alloc] init];

  [aTask setLaunchPath:_command];
  [aTask setArguments:_arguments];
  [aTask setStandardOutput:handle];
  [aTask setStandardError:handle];

  [aTask launch];
  [aTask waitUntilExit];

  if (![aTask isRunning])
    result = [aTask terminationStatus];
    
  RELEASE(aTask); aTask = nil;
  return result;
}

- (void)deletePidFile {
  NSFileManager *fm;

  fm = [self fileManager];

  if([fm fileExistsAtPath:self->pidFile]) {
    [fm removeFileAtPath:self->pidFile handler:nil];
  }
}

- (void)postProcessTaskTermination:(int)_result {
  if(self->statusFlag != STATUS_FLAG_FORKED) {
    [self logWithFormat:@"task got forked"];
    self->statusFlag = STATUS_FLAG_FORKED;
  }
  else {
    [super postProcessTaskTermination:_result];
  }
}

- (int)stop {
  int result    = RETURN_CODE_ERROR;
  self->hasBeenStopped = YES;
  
  if ([self status]) {
    if ([self taskGetsTerminatedByCommand]) {
      result = [self stopProcessWithCommand:[self terminationProgramPath]
                     arguments:[self terminationProgramArguments]];
    }
    else {
      result = kill([[self unixProcessId] intValue],SIGTERM);
    }
    
    if (result != 0)
      [self logWithFormat:@"terminated with exitcode: %i",result];
    else
      [self debugWithFormat:@"terminated cleanly."];

    [self deletePidFile];
    [self postProcessTaskTermination:result];
  }
  return result;
}

- (BOOL)isRunning {
  NSString *procFile;
  NSString *pid;
  FILE *file;
  char buffer[255];
  int result;
  
  if((pid = [self unixProcessId]) == nil) {
    return NO;
  }
    
  procFile = [@"/proc" stringByAppendingPathComponent:pid];
  procFile = [procFile stringByAppendingPathComponent:@"cmdline"];

  if (![[self fileManager] fileExistsAtPath:procFile]) {
    [self logWithFormat:@"ERROR: file '%@' does not exist", procFile];
  }
  else {
    file = fopen([procFile cString],"r");
    result = fread(buffer, 1, 255, file);

    if (ferror(file))
      [self logWithFormat:@"ERROR while reading file '%@'", procFile];
  
    if ([[NSString stringWithCString:buffer]
                   isEqualToString:[self executable]]) 
      return YES;
  }
  return NO;
}

@end /* DaemonTask */
