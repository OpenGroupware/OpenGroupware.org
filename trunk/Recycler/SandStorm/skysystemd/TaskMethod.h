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

#ifndef __skysystemd_TaskMethod_h__
#define __skysystemd_TaskMethod_h__

#import <Foundation/NSObject.h>

@class NSDictionary, NSArray, NSString;

/*
  call patterns:
    $0$		- RPC methodName
    $1$...$n$	- RPC arguments
    $argc$	- number of RPC args
  
  after the call it is filled with:
    $stdout$	- stdout output
    $stderr$	- stderr output
    $exitCode$	- exit code
*/

@interface TaskMethod : NSObject 
{
  NSString *methodName;
  
  NSString *executablePath;
  id       signatures;
  NSString *faultCode;
  NSString *faultMessage;
  int      successExitCode;
}

- (id)initWithMethodName:(NSString *)_m config:(NSDictionary *)_dict;

/* accessors */

- (NSString *)methodName;
- (NSArray *)xmlRpcSignatures;

- (NSString *)executablePathPattern;
- (NSString *)faultCodePattern;
- (NSString *)faultMessagePattern;
- (int)successExitCode;

/* dispatcher */

- (id)callMethodNamed:(NSString *)_method parameters:(NSArray *)_ps;

@end

#endif /* __skysystemd_TaskMethod_h__ */
