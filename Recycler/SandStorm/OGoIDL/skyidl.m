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

#include <OGoIDL/SkyIDLSaxBuilder.h>
#include <OGoIDL/SkyIDLInterface.h>
#include "common.h"

int main(int argc, char **argv, char **env) {
  NSEnumerator      *paths;
  NSString          *path;
  NSAutoreleasePool *pool;
  
#if LIB_FOUNDATION_LIBRARY
  [NSProcessInfo initializeWithArguments:argv count:argc environment:env];
#endif

  pool = [[NSAutoreleasePool alloc] init];

  /* parse */

  paths = [[[NSProcessInfo processInfo] arguments] objectEnumerator];
  [paths nextObject];
  while ((path = [paths nextObject])) {
    NSAutoreleasePool *pool;
    SkyIDLInterface   *interface;
    NSDate            *date;
    NSTimeInterval    duration;

    pool = [[NSAutoreleasePool alloc] init];

    date = [NSDate date];

    interface = [SkyIDLSaxBuilder parseInterfaceFromContentsOfFile:path];
    
    duration  = [[NSDate date] timeIntervalSinceDate:date];
    NSLog(@"parsed in %.6fs", duration);
    NSLog(@"interface is %@", [interface methodNames]);
   
    RELEASE(pool);
  }
  RELEASE(pool);

  exit(0);
  return 0;
}
