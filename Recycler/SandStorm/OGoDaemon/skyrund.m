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

#include <OGoDaemon/SDApplication.h>
#include "common.h"

int main(int argc, const char **argv, char **env) {
  NSAutoreleasePool *pool = nil;
  int               rc;
  NSArray           *args;
  NSString          *bundleName, *appName;
  
  pool = [[NSAutoreleasePool alloc] init];

#if LIB_FOUNDATION_LIBRARY
  [NSProcessInfo initializeWithArguments:(void *)argv
                 count:argc
                 environment:env];
#endif
  
  args = [[NSProcessInfo processInfo] arguments];
  if ([args count] < 2) {
    NSLog(@"usage: %@ <BundleName>", [args objectAtIndex:0]);
    exit(1);
  }
  
  bundleName = [args objectAtIndex:1];
  
  if ((rc = [SDApplication loadDaemonBundle:bundleName]) != 0)
    exit(rc);

  appName = [bundleName stringByAppendingString:@"Application"];
  
  rc = WOWatchDogApplicationMain(appName, argc, argv);
  
  RELEASE(pool); pool = nil;

  return rc;
}
