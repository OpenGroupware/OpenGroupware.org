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
  Following types are supported:
     "toDoJob"
     "controlJob"
     "delegatedJob"
     "archivedJob"
     "palmJob"

     e.g. type = 'toDoJob'

  hints:
     fetchGlobalIDs      YES | NO (default: NO)
*/

#ifndef __SkyJobs_SkyPersonJobDataSource_H__
#define __SkyJobs_SkyPersonJobDataSource_H__

#include <EOControl/EODataSource.h>

#define SkyDeletedJobNotification @"SkyDeletedJobNotification"
#define SkyUpdatedJobNotification @"SkyUpdatedJobNotification"
#define SkyNewJobNotification     @"SkyNewJobNotification"

@class NSString, NSException;
@class EOGlobalID, EOFetchSpecification;

@interface SkyPersonJobDataSource : EODataSource
{
  EOGlobalID           *personId;
  id                   context;
  EOFetchSpecification *fetchSpecification;
  NSException          *lastException;
}

- (id)initWithContext:(id)_ctx personId:(EOGlobalID *)_gid;
- (id)initWithContext:(id)_ctx;

/* accessors */

- (id)context;

- (void)setFetchSpecification:(EOFetchSpecification *)_fSpec;
- (EOFetchSpecification *)fetchSpecification;

@end

#endif /* __SkyJobs_SkyPersonJobDataSource_H__ */
