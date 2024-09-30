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

/*
  supported JS functions:
  
    DataSource getJobDataSource([cache=YES])
*/

#include "SkyPersonDocument.h"
#include <OGoJobs/SkyPersonJobDataSource.h>
#include <NGExtensions/EOCacheDataSource.h>
#include "common.h"

@interface SkyPersonDocument(JobDataSource)
- (EODataSource *)jobDataSource;
@end

@implementation SkyPersonDocument(JobDataSource)

- (EODataSource *)jobDataSource {
  EODataSource *ds = nil;
  Class clazz;

  if ((clazz = NGClassFromString(@"SkyPersonJobDataSource")) == Nil) {
    NSLog(@"WARNING(%s): did not find person-job datasource ..",
          __PRETTY_FUNCTION__);
    return nil;
  }
  
  ds = [[clazz alloc]
               initWithContext:[self context]
               personId:[self globalID]];
  
  return [ds autorelease];
}

@end /* SkyPersonDocument(JobDataSource) */

@implementation SkyPersonDocument(JobJSSupport)

- (id)_jsfunc_getJobDataSource:(NSArray *)_args {
  EODataSource *jds;
  unsigned count;
  BOOL     doCache = YES;

  if ((jds = [self jobDataSource]) == nil)
    return nil;
  
  if ((count = [_args count]) > 0)
    doCache = [[_args objectAtIndex:0] boolValue];
  
  if (doCache)
    jds = [[[EOCacheDataSource alloc] initWithDataSource:jds] autorelease];
  
  return jds;
}

@end /* SkyPersonDocument(JobJSSupport) */
