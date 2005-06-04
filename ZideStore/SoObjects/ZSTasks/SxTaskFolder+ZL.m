/*
  Copyright (C) 2002-2005 SKYRIX Software AG

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

#include "SxTaskFolder.h"
#include <ZSBackend/SxTaskManager.h>
#include "common.h"

@interface SxTaskFolder(UsedPrivs)
- (NSArray *)mapJobs:(NSArray *)_jobs;
@end

@implementation SxTaskFolder(ZL)

- (NSArray *)performEvoQuery:(EOFetchSpecification *)_fs inContext:(id)_ctx {
  EOQualifier *q;
  id jobs;
  
  if ((q = [_fs qualifier])) {
    /* qualifier=davLastModified > 1970-01-01T00:00:00Z */
    NSCalendarDate *modDate = nil;
    
    if ([q isKindOfClass:[EOKeyValueQualifier class]]) {
      if ([[(EOKeyValueQualifier *)q key] isEqualToString:@"davLastModified"])
	// TODO: check operation
	modDate = [(EOKeyValueQualifier *)q value];
    }
    if (modDate)
      [self logWithFormat:@"mod-date: %@", modDate];
    else
      [self logWithFormat:@"evolution query: %@", q];
  }
  
  jobs = [[self taskManagerInContext:_ctx] 
	        evoTasksOfGroup:[self group] type:[self type]];
  jobs = [[[NSArray alloc] initWithObjectsFromEnumerator:jobs] autorelease];
  jobs = [self mapJobs:jobs];
  return jobs;
}

- (id)performMsgInfoQuery:(EOFetchSpecification *)_fs inContext:(id)_ctx {
  /* messages query */
  return [self performEvoQuery:nil inContext:_ctx];
}

- (NSArray *)performZideLookTaskQuery:(EOFetchSpecification *)_fs 
  inContext:(id)_ctx 
{
  [self logWithFormat:@"ZideLook task query"];
  return [self performEvoQuery:_fs inContext:_ctx];
}

@end /* SxTaskFolder(ZL) */
