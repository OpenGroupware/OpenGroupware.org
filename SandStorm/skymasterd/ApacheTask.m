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

#include "ApacheTask.h"
#include "common.h"

@implementation ApacheTask

- (NSString *)logFileDirectory {
  NSString *result;

  result = [[[NSProcessInfo processInfo] environment]
                            objectForKey:@"GNUSTEP_USER_ROOT"];
  result = [result stringByAppendingPathComponent:@"logs"];
  return result;
}

- (NSString *)defaultStdoutLogFileName {
  return [[self logFileDirectory]
                stringByAppendingPathComponent:@"access_log"];
}

- (NSString *)defaultStderrLogFileName {
  return [[self logFileDirectory]
                stringByAppendingPathComponent:@"error_log"];
}

- (BOOL)taskGetsTerminatedByCommand {
  return YES;
}

- (NSString *)terminationProgramPath {
  NSString *path;

  path = @"$GNUSTEP_USER_ROOT$";
  path = [path stringByAppendingPathComponent:@"Tools"];
  path = [path stringByAppendingPathComponent:@"$GNUSTEP_HOST_CPU$"];
  path = [path stringByAppendingPathComponent:@"$GNUSTEP_HOST_OS$"];
  path = [path stringByAppendingPathComponent:@"apachectl"];

  return [path stringByReplacingVariablesWithBindings:
               [[NSProcessInfo processInfo] environment]];
}

- (NSArray *)terminationProgramArguments {
  return [NSArray arrayWithObject:@"stop"];
}

@end /* ApacheTask */
