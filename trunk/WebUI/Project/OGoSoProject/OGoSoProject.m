/*
  Copyright (C) 2005 Helge Hess

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

#include "OGoSoProject.h"
#include "common.h"

@implementation OGoSoProject

/* accessors */

- (NSString *)entityName {
  return @"Project";
}

- (EOGlobalID *)projectGlobalIDInContext:(id)_ctx {
  return [self globalID];
}

- (id)fileManagerInContext:(id)_ctx {
  [self logWithFormat:@"TODO: return filemanager for project!"];
  return nil;
}

/* name lookup */

- (id)lookupName:(NSString *)_name inContext:(id)_ctx acquire:(BOOL)_ac {
  id p;
  
  /* check method names */
  
  if ((p = [super lookupName:_name inContext:_ctx acquire:NO]) != nil)
    return p;
  
  // TODO: check pathes
  
  // TODO: stop acquistion?
  return nil;
}

@end /* OGoSoProject */
