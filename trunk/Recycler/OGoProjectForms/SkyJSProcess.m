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

#include "SkyJSProcess.h"

#include <NGObjWeb/WOMailDelivery.h>
#include "common.h"

@implementation SkyJSProcess

- (void)dealloc {
#if DEBUG
  NSLog(@"%s: dealloc JS process 0x%08X ..", __PRETTY_FUNCTION__, self);
#endif
  RELEASE(self->fromString);
  RELEASE(self->fromHandle);
  RELEASE(self->fromErrHandle);
  RELEASE(self->task);
  RELEASE(self->path);
  RELEASE(self->args);
  [super dealloc];
}

- (void)setArguments:(NSArray *)_args {
  ASSIGNCOPY(self->args, _args);
}
- (void)setPath:(NSString *)_path {
  ASSIGNCOPY(self->path, _path);
}

- (void)_setupTask {
  if (self->task == nil) {
    NSPipe *p;

    self->task = [[NSTask alloc] init];
    
    [self->task setLaunchPath:self->path];
    [self->task setArguments:self->args];
    
    if ((p = [NSPipe pipe])) {
      [self->task setStandardOutput:p];
      self->fromHandle = [[p fileHandleForReading] retain];
    }
#if 0
    if ((p = [NSPipe pipe])) {
      [self->task setStandardError:p];
      self->fromErrHandle = [[p fileHandleForReading] retain];
    }
#endif
  }
}
- (void)_tearDownTask {
  RELEASE(self->task);          self->task          = nil;
  RELEASE(self->fromHandle);    self->fromHandle    = nil;
  RELEASE(self->fromErrHandle); self->fromErrHandle = nil;
  
  RELEASE(self->fromString); self->fromString = nil;
}

- (void)appendResultData:(NSData *)_data {
  if (self->fromString == nil)
    self->fromString = [[NSMutableString alloc] initWithCapacity:1024];

  if ([_data length] > 0) {
    NSString *s;

    s = [[NSString alloc] initWithData:_data encoding:NSISOLatin1StringEncoding];
    [self->fromString appendString:s];
    RELEASE(s);
  }
}

- (int)run {
  int    exitCode;
  NSData *data;
  
  [self _tearDownTask];
  [self _setupTask];
  
  if (self->task == nil)
    return -1;
  
  /* launch task */
  
  [self->task launch];
  
  /* collect task output */
  
  while ((data = [self->fromHandle availableData]) && ([data length] > 0))
    [self appendResultData:data];
  
  /* wait for termination of task */
  
  [self->task waitUntilExit];
  
  exitCode = [self->task terminationStatus];
  
  return exitCode;
}

/* JavaScript */

- (id)_jsfunc_getOutput:(NSArray *)_args {
  return self->fromString;
}

- (id)_jsfunc_run:(NSArray *)_args {
  id  result;
  int exitCode;

  NS_DURING
    exitCode = [self run];
  NS_HANDLER
    exitCode = -1;
  NS_ENDHANDLER;
  
  result = [NSNumber numberWithInt:exitCode];
  
  return result;
}

@end /* SkyJSProcess */
