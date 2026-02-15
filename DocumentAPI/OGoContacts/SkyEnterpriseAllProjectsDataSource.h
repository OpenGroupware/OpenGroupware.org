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

#ifndef __SkyEnterpriseAllProjectsDataSource_H__
#define __SkyEnterpriseAllProjectsDataSource_H__

/**
 * @class SkyEnterpriseAllProjectsDataSource
 * @brief Fetches all projects for an enterprise,
 *        including the "fake" enterprise project.
 *
 * Combines the enterprise's own implicit project
 * (obtained via "enterprise::get-fake-project") with
 * the explicitly assigned projects fetched through a
 * SkyEnterpriseProjectDataSource.
 *
 * Supports qualifier filtering and sort orderings
 * from the fetch specification.
 *
 * @see SkyEnterpriseProjectDataSource
 * @see SkyProjectDataSource
 */

#include <NGExtensions/EODataSource+NGExtensions.h>
#include "common.h"

@class EOFetchSpecification;

@interface SkyEnterpriseAllProjectsDataSource : EODataSource
{
  EOFetchSpecification *fspec;
  id           context;
  id           enterpriseId;
  EODataSource *projectDataSource;
}

- (id)initWithContext:(id)_ctx enterpriseId:(id)_enterpriseId;

@end

#endif /* __SkyEnterpriseAllProjectsDataSource_H__ */
