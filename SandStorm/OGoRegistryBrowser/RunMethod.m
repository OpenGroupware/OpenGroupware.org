/*
  Copyright (C) 2000-2003 SKYRIX Software AG

  This file is part of OGo

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
// $Id$

#include "common.h"
#include "RunMethod.h"
#include "LoginPanel.h"
#include "Session.h"
#include <SxComponents/SxXmlRpcComponent.h>
#include <SxComponents/SxComponentInvocation.h>
#include <SxComponents/SxComponentMethodSignature.h>
#include <SxComponents/SxComponentRegistry.h>
#include <SxComponents/SxComponentException.h>

@implementation RunMethod

- (id)init {
  if ((self = [super init])) {
    self->methodName = @"";
    self->registry = [[[self session] registry] retain];
    self->item = [[SxComponentInvocation alloc] init];
    
    self->defaultValues = [[NSArray alloc] init];
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->signatures);
  RELEASE(self->lastResult);
  RELEASE(self->methodName);
  RELEASE(self->invocation);
  RELEASE(self->item);
  RELEASE(self->component);
  RELEASE(self->invocations);
  RELEASE(self->registry);
  [super dealloc];
}

- (void)setIndex:(int)_idx {
  self->index = _idx;
}
- (int)index {
  return self->index;
}

- (void)setComponent:(SxXmlRpcComponent *)_component {
  ASSIGN(self->component, _component);
}
- (SxXmlRpcComponent *)component {
  return self->component;
}

- (void)setItem:(SxComponentInvocation *)_item {
  ASSIGN(self->item, _item);
}
- (SxComponentInvocation *)item {
  return self->item;
}

- (void)setValues:(NSArray *)_values
  toInvocation:(SxComponentInvocation *)_invocation
{
  int i;
  for (i = 0; i < [_values count]; i++) {
    [_invocation setArgument:[_values objectAtIndex:i]
                 atIndex:i];
  }
}

- (void)setMethodName:(NSString *)_name {
  ASSIGNCOPY(self->methodName, _name);
}
- (NSString *)methodName {
  return self->methodName;
}

- (void)setDefaultValues:(NSArray *)_defaultValues {
  ASSIGN(self->defaultValues, _defaultValues);
}

- (void)setInvocation:(SxComponentInvocation *)_invocation {
  if(self->invocation == nil)
    self->invocation = [[SxComponentInvocation alloc] init];
  ASSIGN(self->invocation, _invocation);
}
- (SxComponentInvocation *)invocation {
  return self->invocation;
}

- (void)setCurrentElement:(id)_element {
  [self->invocation setArgument:_element atIndex:self->index];
}
- (id)currentElement {
  return [self->invocation argumentAtIndex:self->index];
}

- (void)setSignatures:(NSArray *)_signatures {
  ASSIGN(self->signatures, _signatures);
}
- (NSArray *)signatures {
  id tmp, c;
  
  if (self->signatures) {
    return self->signatures;
  }
  
  if ((c = [self component]) == nil) {
    [self logWithFormat:@"first set component before calling -signatures !"];
    return nil;
  }
  if ([self->methodName length] == 0) {
    [self logWithFormat:@"first set method-name before calling -signatures !"];
    return nil;
  }
  
  if ((tmp = [c methodSignature:self->methodName]) == nil) {
    [self logWithFormat:@"got not method signature for method: %@",
            self->methodName];
    return nil;
  }
  self->signatures = RETAIN(tmp);
  return self->signatures;
}

- (BOOL)hasSignatures {
  return [[self signatures] count] > 0 ? YES : NO;
}

- (NSArray *)invocations {
  NSMutableArray *result = nil;
  NSArray *lSig;
  int i;
  
  if (self->invocations) {
    return self->invocations;
  }
  
  if ((lSig = [self signatures]) == nil) {
    self->invocations = [[NSArray alloc] init];
    return self->invocations;
  }
  
  result = [NSMutableArray arrayWithCapacity:[lSig count]];
  
  for (i = 0; i < [lSig count]; i++) {
    SxComponentInvocation *inv;
    
    inv = [self->component
               invocationForMethodNamed:self->methodName
               methodSignature:[lSig objectAtIndex:i]];
    if (self->invocation == nil) {
      [self setInvocation:inv];
      if(self->defaultValues != nil)
        [self setValues:self->defaultValues toInvocation:[self invocation]];
      [self setItem:inv];
    }
    [result addObject:inv];
  }
  
  self->invocations = [result shallowCopy];
  
  return self->invocations;
}

- (NSString *)help {
  return [[self component] methodHelp:self->methodName];
}

- (int)count {
  return [[self->invocation methodSignature] numberOfArguments];
}

- (NSString *)currentType {
  return [[self->invocation methodSignature]
                 argumentTypeAtIndex:self->index];
}

- (void)setResult:(id)_result {
  ASSIGN(self->lastResult, _result);
  if (_result) self->hasResult = YES;
}
- (id)result {
  return self->lastResult;
}

- (BOOL)hasResult {
  return self->hasResult;
}

- (BOOL)isResultArray {
  return [[self result] isKindOfClass:[NSArray class]];
}

/* actions */

- (id)selectInvocation {
  [self setInvocation:[self item]];
  return self;
}

- (id)run {
  if (![self->invocation invoke]) {
    NSException *lastException;
    
    lastException = [self->invocation lastException];
    
    if ([lastException isCredentialsRequiredException]) {
      id page;
      
      page = [self pageWithName:@"LoginPanel"];
      [page setRunPage:self];
      [page setInvocation:self->invocation];
      [page setCredentials:[(SxAuthException *)lastException credentials]];
      return page;
    }
    
    ASSIGN(self->lastResult, lastException);
    [self debugWithFormat:@"invocation failed: %@", lastException];
  }
  else {
    ASSIGN(self->lastResult, [self->invocation returnValue]);
  }
  
  self->hasResult = self->lastResult ? YES : NO;
  return self;
}

- (id)backToMain {
  return [[self session] objectForKey:@"mainPage"];
}

@end /* RunMethod */
