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

#ifndef __skysystemd_TaskMethodInvocation_h__
#define __skysystemd_TaskMethodInvocation_h__

#import <Foundation/NSObject.h>

@class NSDictionary, NSArray, NSString, NSTask, NSException;
@class NSMutableDictionary, NSMutableArray;
@class TaskMethod, TaskMethodSignature;

@interface TaskMethodInvocation : NSObject 
{
  TaskMethod          *method;
  TaskMethodSignature *signature;
  NSMutableArray      *arguments;
  id                  result;
  NSException         *lastException;

  /* transient */
  NSTask              *task;
  NSMutableDictionary *patternDictionary;
  NSString            *outPath;
  NSString            *errPath;
  id                  resultProxy;
}

- (id)initWithTaskMethod:(TaskMethod *)_m signature:(TaskMethodSignature *)_s;

/* accessors */

- (TaskMethod *)method;
- (TaskMethodSignature *)signature;
- (NSString *)methodName;
- (NSArray *)xmlRpcSignatures;

- (void)setArguments:(NSArray *)_args;
- (NSArray *)arguments;

- (void)setReturnValue:(id)_result;
- (id)returnValue;
- (NSException *)lastException;
- (void)resetLastException;

- (id)asyncResultProxy;

/* dispatcher */

- (BOOL)invoke;
- (BOOL)asyncInvoke;

@end

#endif /* __skysystemd_TaskMethodInvocation_h__ */
