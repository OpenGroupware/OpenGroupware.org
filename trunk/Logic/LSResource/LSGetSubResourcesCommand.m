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

#include <LSFoundation/LSBaseCommand.h>

@interface LSGetSubResourcesCommand : LSBaseCommand
@end

#include "common.h"

@implementation LSGetSubResourcesCommand

- (void)_executeInContext:(id)_context {
  NSArray *assignList = nil;
  
  LSRunCommandV(_context, @"resource", @"get",
                @"resourceId", [[self object] valueForKey:@"resourceId"],
                nil);

  assignList = [[self object] valueForKey:@"toSubResourceAssignment"];

  if (![assignList isNotNull]) {
    [self setReturnValue:nil];
  }
  else {
    NSEnumerator   *assignEnum;
    NSMutableArray *resultList;
    id              assignment;
    
    assignEnum = [assignList objectEnumerator];
    resultList = [NSMutableArray array];
    while ((assignment = [assignEnum nextObject])) {
      id tmp;
      
      tmp = [assignment valueForKey:@"toSubResource"];
      if ([tmp isNotNull])
        [resultList addObject:tmp];
    }
    [self setReturnValue:resultList];
  }
}

- (NSString *)entityName {
  return @"Resource";
}

@end /* LSGetSubResourcesCommand */
