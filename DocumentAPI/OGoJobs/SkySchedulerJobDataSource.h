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

#ifndef __SkyJobs_SkySchedulerJobDataSource_H__
#define __SkyJobs_SkySchedulerJobDataSource_H__

/**
 * @class SkySchedulerJobDataSource
 * @brief Provides to-do jobs as scheduler-compatible
 *        appointment documents.
 *
 * Adapts the jobs subsystem for consumption by the
 * calendar/scheduler UI. Fetches to-do jobs for a
 * single person within a date range specified by a
 * SkyAppointmentQualifier, then wraps each job in a
 * SkySchedulerJobDocument that exposes appointment-like
 * properties (startDate, endDate, participants, etc.).
 *
 * Only handles qualifiers of type
 * SkyAppointmentQualifier with a single person/account
 * company and the "_todojob_" appointment type.
 *
 * Requires the OGoScheduler datasource bundle to be
 * loaded at initialization time.
 *
 * @see SkyPersonJobDataSource
 * @see SkyAppointmentDataSource
 */

#include <NGExtensions/EODataSource+NGExtensions.h>

@interface SkySchedulerJobDataSource : EODataSource
{
  id                   ctx;
  EOFetchSpecification *fSpec;
}

- (id)initWithContext:(id)_ctx;

@end /* SkySchedulerJobDataSource */

#endif /* __SkyJobs_SkySchedulerJobDataSource_H__ */
