/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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
// $Id$

#include <LSFoundation/LSDBObjectBaseCommand.h>

@class NSArray;

@interface LSArchiveProjectCommand : LSDBObjectBaseCommand
@end

#include "common.h"

@implementation LSArchiveProjectCommand

- (void)_executeInContext:(id)_context {
  id obj = [self object];
  
  [self assert:(obj != nil) reason:@"no project object to act on"];

  LSRunCommandV(_context, @"project",  @"delete",
                @"object",       obj,
                @"reallyDelete", [NSNumber numberWithBool:NO], nil);

  LSRunCommandV(_context, @"project", @"get-jobs",
                @"object",      obj,
                @"relationKey", @"jobs", nil);
  {
    int     i, cnt;
    NSArray *jobs = nil;

    jobs = [obj valueForKey:@"jobs"];

    for (i = 0, cnt = [jobs count]; i < cnt; i++) {
      id j = [jobs objectAtIndex:i];

      LSRunCommandV(_context, @"job", @"set",
                    @"object", j,
                    @"jobStatus", LSJobArchived, nil);
      
      LSRunCommandV(_context, @"JobHistory", @"new",
                  @"jobId",      [j valueForKey:@"jobId"],
                  @"action",     LSJobArchived,
                  @"actorId",    [[_context valueForKey:LSAccountKey]
                                            valueForKey:@"companyId"],
                  @"jobStatus",  [j valueForKey:@"jobStatus"],
                  @"actionDate", [NSCalendarDate date],
                  nil);
    }    
  }
}

// initialize records

- (NSString *)entityName {
  return @"Project";
}

@end /* LSArchiveProjectCommand */
