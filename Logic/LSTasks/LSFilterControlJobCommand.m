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

#import "LSFilterJobCommand.h"

@interface LSFilterControlJobCommand : LSFilterJobCommand
@end

#import "common.h"

@implementation LSFilterControlJobCommand

- (void)_prepareForExecutionInContext:(id)_context {
  if (![self jobList] || ![self executantId])
    [LSDBObjectCommandException raiseOnFail:NO object:self
                                reason:@"No JobList or no ExecutantId given!"];
  [super _prepareForExecutionInContext:(id)_context];
}

- (id)filter {
  NSMutableArray *filteredJobs = nil;
  NSEnumerator   *enumerator   = nil;
  id             job           = nil;
  
  filteredJobs = [[NSMutableArray allocWithZone:[self zone]]
                                  initWithCapacity:64];
  
  enumerator   = [[self jobList] objectEnumerator];
  while ((job = [enumerator nextObject])) {
    BOOL     isControlJob = NO;
    id       ctrlJob      = nil;
    NSString *jobStatus   = nil;

    jobStatus = [job valueForKey:@"jobStatus"];
    ctrlJob   = [job valueForKey:@"isControlJob"];
    
    if (ctrlJob != nil) {
      isControlJob = [ctrlJob boolValue];
    }
    if (isControlJob &&
        ([[job valueForKey:@"executantId"] isEqual:[self executantId]]) &&
        (![jobStatus isEqualToString:LSJobArchived]) &&
        (![jobStatus isEqualToString:LSJobDone])) {
      [filteredJobs addObject:job];
    }
  }
  return AUTORELEASE(filteredJobs);
}

@end
