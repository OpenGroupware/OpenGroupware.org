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

#import <Foundation/Foundation.h>
#include "ICalParser.h"
#include "ICalComponent.h"
#include "ICalProperty.h"

int main(int argc, char **argv, char **env)  {
  NSAutoreleasePool *pool;
  NSEnumerator      *args;
  NSString          *arg;
  ICalParser        *parser;
  
  [NSProcessInfo initializeWithArguments:argv count:argc environment:env];
  
  pool = [[NSAutoreleasePool alloc] init];
  parser = [ICalParser iCalParser];
  
  args = [[[NSProcessInfo processInfo] arguments] objectEnumerator];
  [args nextObject]; // process name ...

  while ((arg = [args nextObject])) {
    NSAutoreleasePool *pool2;
    ICalComponent *component;
    
    pool2 = [[NSAutoreleasePool alloc] init];

    if ((component = [parser parseFileAtPath:arg]) == nil) {
      NSLog(@"couldn't parse file: %@", arg);
      continue;
    }
    
    NSLog(@"component: %@", component);
    NSLog(@"  subcomponents: %@", [component subComponents]);
    
    printf("%s", [[component icalString] cString]);
    
    RELEASE(pool2);
  }
  
  RELEASE(pool);
  return 0;
}
