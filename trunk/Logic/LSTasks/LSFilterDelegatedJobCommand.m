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

#import "LSFilterJobCommand.h"

@interface LSFilterDelegatedJobCommand : LSFilterJobCommand
@end

#import "common.h"

@implementation LSFilterDelegatedJobCommand

- (void)_prepareForExecutionInContext:(id)_context {
  if (![self jobList] || ![self creatorId])
    [LSDBObjectCommandException raiseOnFail:NO object:self
                                reason:@"No jobList or no creatorId given!"];
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
    BOOL isControlJob  = NO;
    id   ctrlJob        = nil;
    NSString *jobStatus = [job valueForKey:@"jobStatus"];

    ctrlJob = [job valueForKey:@"isControlJob"];
    if (ctrlJob != nil) {
      isControlJob = [ctrlJob boolValue];
    }
    if (!isControlJob &&
        ([[job valueForKey:@"creatorId"] isEqual:[self creatorId]]) &&
        (![jobStatus isEqualToString:LSJobArchived]) &&
        (![jobStatus isEqualToString:LSJobDone])) {
      [filteredJobs addObject:job];
    }
  }
  return AUTORELEASE(filteredJobs);
}

@end