/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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

#include "OGoSession.h"
#include "OGoNavigation.h"
#include "common.h"

@implementation OGoSession(JSSupport)

- (id)_jsfunc_activate:(NSArray *)_args {
  NSString *action;
  id       obj;
  
  if ([_args count] > 1) {
    action = [[_args objectAtIndex:0] stringValue];
    obj    = [_args objectAtIndex:1];
  }
  else {
    action = @"view";
    obj    = [_args objectAtIndex:0];
  }
  
  return [[self navigation] activateObject:obj withVerb:action];
}

@end /* OGoSession(JSSupport) */
