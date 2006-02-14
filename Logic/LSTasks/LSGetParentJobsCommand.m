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

// DEPRECATED

#include "LSGetParentJobsCommand.h"
#include "common.h"

@implementation LSGetParentJobsCommand

- (void)dealloc {
  [self->jobs release];
  [super dealloc];
}

/* command methods */

- (void)_executeInContext:(id)_context {
  [self warnWithFormat:
	  @"this command is deprecated (nothing was executed)"];
  return;
}

/* accessors */

- (id)job {
  NSAssert([self->jobs isNotEmpty], @"no jobs in array");
  return [self->jobs objectAtIndex:0];
}

- (void)setJobs:(NSArray *)_jobs {
  ASSIGN(self->jobs, _jobs);
}
- (NSArray *)jobs {
  return self->jobs;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"job"]) {
    [self setJobs:[NSArray arrayWithObject:_value]];
    return;
  }
  if ([_key isEqualToString:@"jobs"]) {
    [self setJobs:_value];
    return;
  }
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"job"])
    return [self job];
  if ([_key isEqualToString:@"jobs"])
    return [self jobs];
  return nil;
}

@end /* LSGetParentJobsCommand */
