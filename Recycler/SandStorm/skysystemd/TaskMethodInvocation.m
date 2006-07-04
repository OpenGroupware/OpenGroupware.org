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
// Created by Helge Hess on Sat Feb 02 2002.

#include "TaskMethodInvocation.h"
#include "TaskMethod.h"
#include "TaskMethodSignature.h"
#include <NGXmlRpc/NGAsyncResultProxy.h>
#include "common.h"

@interface TaskMethodInvocation(Privates)
- (void)reset;
- (BOOL)processResult;
@end

@implementation TaskMethodInvocation

- (id)initWithTaskMethod:(TaskMethod *)_m signature:(TaskMethodSignature *)_s {
  if (_m == nil) {
    RELEASE(self);
    return nil;
  }
  
  self->method    = RETAIN(_m);
  self->signature = RETAIN(_s);
  
  return self;
}
- (id)init {
  return [self initWithTaskMethod:nil signature:nil];
}

- (void)dealloc {
  [self logWithFormat:@"dealloc ..."];
  [self reset];
  RELEASE(self->resultProxy);
  RELEASE(self->errPath);
  RELEASE(self->outPath);
  RELEASE(self->patternDictionary);
  RELEASE(self->result);
  RELEASE(self->lastException);
  RELEASE(self->arguments);
  RELEASE(self->task);
  RELEASE(self->method);
  RELEASE(self->signature);
  [super dealloc];
}

/* accessors */

- (NSString *)methodName {
  return [self->method methodName];
}
- (NSArray *)xmlRpcSignatures {
  return [self->method xmlRpcSignatures];
}

- (TaskMethod *)method {
  return self->method;
}
- (TaskMethodSignature *)signature {
  return self->signature;
}

- (void)setReturnValue:(id)_result {
  ASSIGN(self->result, _result);
}
- (id)returnValue {
  return self->result;
}
- (NSException *)lastException {
  return self->lastException;
}
- (void)resetLastException {
  ASSIGN(self->lastException, (id)nil);
}

- (void)setArguments:(NSArray *)_args {
  NSAssert2(([self->signature numberOfArguments] == [_args count]),
            @"arg count mismatch (%i expected, got %i)",
            [self->signature numberOfArguments],
            [_args count]);
  
  AUTORELEASE(self->arguments);
  self->arguments = [_args mutableCopy];
}
- (NSArray *)arguments {
  return self->arguments;
}

/* dispatcher */

- (void)_fillPatternDictionary {
  int i, count;
  
  count = [self->arguments count];
  
  if (self->patternDictionary == nil) {
    self->patternDictionary =
      [[NSMutableDictionary alloc] initWithCapacity:32];
  }
  
  [self->patternDictionary setObject:[self->method methodName] forKey:@"0"];
  [self->patternDictionary
       setObject:[NSNumber numberWithInt:count] forKey:@"argc"];
  for (i = 0; i < count; i++) {
    NSString *s;
    
    s = [[NSString alloc] initWithFormat:@"%i", (i + 1)];
    [self->patternDictionary
         setObject:[self->arguments objectAtIndex:i] forKey:s];
    RELEASE(s);
  }
}

- (NSFileManager *)fileManager {
  return [NSFileManager defaultManager];
}
- (NSNotificationCenter *)notificationCenter {
  return [NSNotificationCenter defaultCenter];
}

- (void)resetTask {
  [[self notificationCenter] removeObserver:self];
  [self->task terminate];
  ASSIGN(self->task, (id)nil);
}
- (void)resetLogFiles {
  NSFileManager *fm = [self fileManager];
  
  if (self->outPath) {
    if (![fm removeFileAtPath:self->outPath handler:nil])
      [self logWithFormat:@"couldn't remove out path: %@", self->outPath];
    ASSIGN(self->outPath, (id)nil);
  }
  if (self->errPath) {
    if (![fm removeFileAtPath:self->errPath handler:nil])
      [self logWithFormat:@"couldn't remove err path: %@", self->errPath];
    ASSIGN(self->errPath, (id)nil);
  }
}

- (id)asyncResultProxy {
  return self->resultProxy;
}

- (void)reset {
  if (self->resultProxy) {
    if (![self->resultProxy isReady]) {
      [self logWithFormat:@"WARNING: reset before result %@ was ready ...",
              self->resultProxy];
    }
  }
  [self resetTask];
  [self resetLogFiles];
  [self->patternDictionary removeAllObjects];
}

- (NSString *)temporaryFileName:(NSString *)_tmp {
  return [[NSProcessInfo processInfo] temporaryFileName:_tmp];
}
- (NSString *)outPath {
  return [self temporaryFileName:@"/tmp/skysysd.stdout"];
}
- (NSString *)errPath {
  return [self temporaryFileName:@"/tmp/skysysd.stderr"];
}

- (void)processFinishNotification:(NSNotification *)_notification {
  if ([_notification object] != self->task) {
    [self logWithFormat:@"got incorrect task termination notification: %@",
            _notification];
    return;
  }
  
  if (![self processResult]) {
    [self logWithFormat:@"result processing failed ..."];
  }
  else {
    [self->resultProxy postResult:[self returnValue]];
  }
  [self reset];
}

- (void)taskFinished:(NSNotification *)_notification {
  /* perform-later is used because task-finish notification can occur
     anytime !!! */
  [self performSelector:@selector(processFinishNotification:)
        withObject:_notification
        afterDelay:0.000001 /* 0.0 leads to immediate notification ... */];
}

- (BOOL)_invokeAndWaitForExit:(BOOL)_waitForExit {
  static NSData *emptyData = nil;
  NSFileManager *fm = [self fileManager];
  NSData *inData;
  NSPipe *tin;
  id tmp;
  
  if (emptyData == nil)
    emptyData = [[NSData alloc] init];
  
  /* clear call environment */
  
  [self resetLastException];
  ASSIGN(self->result, (id)nil);
  [self reset];
  
  /* setup env */
  
  [self _fillPatternDictionary];
  self->outPath = [[self outPath] copy];
  self->errPath = [[self errPath] copy];
  
  NSAssert(self->task == nil, @"task already setup ...");
  self->task = [[NSTask alloc] init];

  [[self notificationCenter]
         addObserver:self selector:@selector(taskFinished:)
         name:NSTaskDidTerminateNotification object:self->task];
  
  /* setup task */
  
  tmp = [self->method executablePathPattern];
  tmp = [tmp stringByReplacingVariablesWithBindings:self->patternDictionary];
  [self->task setLaunchPath:tmp];
  
  tmp = [self->signature
             argumentsWithPatternDictionary:self->patternDictionary];
  [self->task setArguments:tmp];
  
  inData = [self->signature
                standardInputWithPatternDictionary:self->patternDictionary
                parameters:self->arguments];
  if ([inData length] > 0)
    [self->task setStandardInput: (tin  = [NSPipe pipe])];
  else
    tin = nil;
  
  if (![fm createFileAtPath:outPath contents:emptyData attributes:nil]) {
    NSLog(@"%s: couldn't create stdout file: '%@'", __PRETTY_FUNCTION__,
          outPath);
  }
  if ((tmp = [NSFileHandle fileHandleForWritingAtPath:outPath]))
    [self->task setStandardOutput:tmp];
  else {
    NSLog(@"%s: couldn't create handle for file: '%@'", __PRETTY_FUNCTION__,
          outPath);
  }
  
  if (![fm createFileAtPath:errPath contents:emptyData attributes:nil]) {
    NSLog(@"%s: couldn't create stderr file: '%@'", __PRETTY_FUNCTION__,
          errPath);
  }
  if ((tmp = [NSFileHandle fileHandleForWritingAtPath:errPath]))
    [self->task setStandardError:tmp];
  else {
    NSLog(@"%s: couldn't create handle for file: '%@'", __PRETTY_FUNCTION__,
          errPath);
  }
  
  /* start process */
  
  [self->task launch];
  
  if (tin) {
    NSFileHandle *fh;
    fh = [tin fileHandleForWriting];
    [fh writeData:inData];
    [fh closeFile];
  }
  
  if (_waitForExit) {
    [self->task waitUntilExit];
  }
  else {
    self->resultProxy = [[NGAsyncResultProxy alloc] init];
    [self->resultProxy retainObject:self]; /* need inv for processing .. */
  }
  
  return YES;
}

- (BOOL)invoke {
  return [self _invokeAndWaitForExit:YES];
}
- (BOOL)asyncInvoke {
  return [self _invokeAndWaitForExit:NO];
}

- (BOOL)processResult {
  NSData *outData, *errData;
  int    exitCode;
  
  [self->task waitUntilExit];
  
  outData = [NSData dataWithContentsOfMappedFile:outPath];
  errData = [NSData dataWithContentsOfMappedFile:errPath];
  
  /* process result */
  
  ASSIGN(self->result, (id)nil);
  
  exitCode = [self->task terminationStatus];
  
  [self->patternDictionary
       setObject:[NSNumber numberWithInt:exitCode] forKey:@"exit"];
  
  if ([outData length] > 0) {
    NSString *s;
    
    if ((s = [self->signature standardOutputStringWithData:outData]))
      [self->patternDictionary setObject:s forKey:@"stdout"];
    else {
      NSLog(@"WARNING(%s): couldn't create string for stdout ...",
            __PRETTY_FUNCTION__);
    }
    [self->patternDictionary setObject:outData forKey:@"stdoutData"];
  }
  else
    [self->patternDictionary setObject:@"" forKey:@"stdout"];
  
  if ([errData length] > 0) {
    NSString *s;
    if ((s = [self->signature standardErrorStringWithData:errData]))
      [self->patternDictionary setObject:s forKey:@"stderr"];
    else {
      NSLog(@"WARNING(%s): couldn't create string for stderr ...",
            __PRETTY_FUNCTION__);
    }
    [self->patternDictionary setObject:errData forKey:@"stderrData"];
  }
  else
    [self->patternDictionary setObject:@"" forKey:@"stderr"];
  
  if (exitCode == [self->method successExitCode]) {
    self->result =
      [[self->signature resultWithPatternDictionary:self->patternDictionary]
                        retain];
  }
  else {
    NSString *ename, *emsg;
    NSDictionary *ui;
    
#if DEBUG
    NSLog(@"%s: method call failed: %@ ..", __PRETTY_FUNCTION__,
          [self->patternDictionary objectForKey:@"stderr"]);
#endif
    
    ui = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:exitCode]
                       forKey:@"XmlRpcFaultCode"];
    
    ename  = [[self->method faultCodePattern]
                            stringByReplacingVariablesWithBindings:
                              self->patternDictionary];
    emsg   = [[self->method faultMessagePattern]
                            stringByReplacingVariablesWithBindings:
                              self->patternDictionary];
    
    self->result = [[NSException exceptionWithName:ename reason:emsg
                                 userInfo:ui]
                                 retain];
  }
  
  return YES;
}

/* description */

- (NSString *)description {
  return [NSString stringWithFormat:@"<0x%p[%@]: %@>",
                     self, NSStringFromClass([self class]),
                     [self methodName]];
}

@end /* TaskMethodInvocation */
