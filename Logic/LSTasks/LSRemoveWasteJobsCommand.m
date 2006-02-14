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

@class NSArray;

@interface LSRemoveWasteJobsCommand : LSBaseCommand
{
  NSArray *jobs;
}

@end

#include "common.h"

@implementation LSRemoveWasteJobsCommand

- (void)dealloc {
  [self->jobs release];
  [super dealloc];
}

/* execute */

- (void)_executeInContext:(id)_context {
  NSMutableArray *myJobs, *jobsToRemove;
  unsigned int   i, cnt1;
  
  cnt1         = [self->jobs count]; 
  myJobs       = [NSMutableArray arrayWithCapacity:cnt1];
  jobsToRemove = [NSMutableArray arrayWithCapacity:4];
  
  [myJobs addObjectsFromArray:self->jobs];
  
  for (i = 0; i < cnt1; i++) {
    id  myJob;
    int j, cnt2;
    
    myJob = [myJobs objectAtIndex:i];
    
    for (j = 0, cnt2  = [[myJob valueForKey:@"jobs"] count]; j < cnt1; j++) {
      id   nextJob;
      int  k; 
      BOOL found;
      
      nextJob = [myJobs objectAtIndex:j];
      
      for (k = 0, found = NO; k < cnt2; k++) {
        id mySubJob = [[myJob valueForKey:@"jobs"] objectAtIndex:k];
    
        if ([mySubJob isEqual:nextJob]) {
          found = YES;
          break;
        }
      }
      if (found)
        [jobsToRemove addObject:nextJob];
    }
  }
  [myJobs removeObjectsInArray:jobsToRemove];
  [self setReturnValue:myJobs];
}

/* accessors */

- (void)setJobs:(NSArray *)_jobs {
  ASSIGN(self->jobs, _jobs);
}
- (NSArray *)jobs {
  return self->jobs;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"jobs"]) {
    [self setJobs:_value];
    return;
  }
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"jobs"])
    return [self jobs];
  return nil;
}

@end /* LSRemoveWasteJobsCommand */
