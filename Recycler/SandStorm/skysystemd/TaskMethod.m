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

#include "TaskMethod.h"
#include "TaskMethodSignature.h"
#include "TaskMethodInvocation.h"
#include <NGXmlRpc/NGAsyncResultProxy.h>
#include "common.h"

@implementation TaskMethod

- (id)initWithMethodName:(NSString *)_m config:(NSDictionary *)_dict {
  NSMutableArray *ma;
  NSDictionary   *env;
  NSDictionary   *fd, *sd;
  NSEnumerator   *e;
  NSString       *s;

  env = [[NSProcessInfo processInfo] environment];
  
  self->methodName      = [_m copy];
  self->successExitCode = 0;

  sd = [_dict objectForKey:@"signatures"];
  fd = [_dict objectForKey:@"fault"];
  self->executablePath = [[[_dict objectForKey:@"executable"]
                                  stringByReplacingVariablesWithBindings:env]
                                  copy];
  
  self->faultCode    = [[fd objectForKey:@"code"]    copy];
  self->faultMessage = [[fd objectForKey:@"message"] copy];
  
  ma = [NSMutableArray arrayWithCapacity:8];
  e = [sd keyEnumerator];
  while ((s = [e nextObject])) {
    TaskMethodSignature *ms;
    
    ms = [[TaskMethodSignature alloc] initWithSignature:s 
                                      config:[sd objectForKey:s]];
    [ma addObject:ms];
    RELEASE(ms);
  }
  self->signatures = [ma shallowCopy];
  
  return self;
}

- (void)dealloc {
  RELEASE(self->signatures);
  RELEASE(self->faultCode);
  RELEASE(self->faultMessage);
  RELEASE(self->executablePath);
  RELEASE(self->methodName);
  [super dealloc];
}

/* accessors */

- (NSString *)methodName {
  return self->methodName;
}

- (NSArray *)xmlRpcSignatures {
  NSMutableArray *ma;
  unsigned i, count;
  
  count = [self->signatures count];
  ma = [NSMutableArray arrayWithCapacity:count];
  for (i = 0; i < count; i++)
    [ma addObject:[[self->signatures objectAtIndex:i] xmlRpcSignature]];
  return ma;
}

- (NSString *)executablePathPattern {
  return self->executablePath;
}
- (NSString *)faultCodePattern {
  return self->faultCode;
}
- (NSString *)faultMessagePattern {
  return self->faultMessage;
}
- (int)successExitCode {
  return self->successExitCode;
}

/* dispatcher */

- (TaskMethodSignature *)signatureForParameters:(NSArray *)_ps {
  NSEnumerator        *e;
  TaskMethodSignature *s;
  
  /* try to find exact match ... */
  e = [self->signatures objectEnumerator];
  while ((s = [e nextObject])) {
    if ([s doesMatchArguments:_ps]) return s;
  }
  
  /* try to find approximate match ... */
  e = [self->signatures objectEnumerator];
  while ((s = [e nextObject])) {
    if ([s canProcessArguments:_ps]) return s;
  }
  
  return nil;
}

- (BOOL)runAsync {
  return [[[NSUserDefaults standardUserDefaults]
                           objectForKey:@"SkySystemRunSync"]
                           boolValue] ? NO : YES;
}

- (NSException *)faultForMissingSignature:(NSString *)_method
  parameters:(NSArray *)_ps
{
  NSException  *exc;
  NSDictionary *ui;

  ui = [NSDictionary dictionaryWithObjectsAndKeys:
                       _method, @"methodName",
                       [NSNumber numberWithInt:[_ps count]],
                       @"parameterCount",
                       nil];
  
  exc = [NSException exceptionWithName:@"1000"
                     reason:@"found no signature matching arguments"
                     userInfo:ui];
  return exc;
}

- (id)callMethodNamed:(NSString *)_method parameters:(NSArray *)_ps {
  TaskMethodInvocation *mi;
  NSAutoreleasePool   *pool;
  TaskMethodSignature *sig;
  id                  result;
  
  if ((sig = [self signatureForParameters:_ps]) == nil) {
    [self logWithFormat:@"found no signature match arguments %@", _ps];
    return [self faultForMissingSignature:_method parameters:_ps];
  }
  
  pool = [[NSAutoreleasePool alloc] init];
  
  mi = [[[TaskMethodInvocation alloc]
                               initWithTaskMethod:self signature:sig]
                               autorelease];
  [mi setArguments:_ps];
  
  if (![self runAsync]) {
    if ([mi invoke]) {
      result = [mi returnValue];
    }
    else {
      /* check last exception */
      result = [mi lastException];
    }
    result = RETAIN(result);
  }
  else {
    if ([mi asyncInvoke]) {
      result = [[mi asyncResultProxy] retain];
    }
    else {
      /* check last exception */
      result = [[mi lastException] retain];
    }
  }
  
  RELEASE(pool);
  return AUTORELEASE(result);
}

/* description */

- (NSString *)description {
  return [NSString stringWithFormat:@"<%p[%@]: %@>",
                     self, NSStringFromClass([self class]),
                     [self methodName]];
}

@end /* TaskMethod */
