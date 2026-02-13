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

#ifndef __SkyLogDataSource_H__
#define __SkyLogDataSource_H__

#include <EOControl/EODataSource.h>

/**
 * @class SkyLogDataSource
 * @brief Data source for log entries attached to an object.
 *
 * SkyLogDataSource fetches and creates log entries
 * (SkyLogDocument instances) associated with a specific
 * database object identified by its EOGlobalID. It uses
 * the "object::get-logs" and "object::add-log" Logic
 * commands via the LSCommandContext.
 *
 * Fetched results can be filtered and sorted through an
 * optional EOFetchSpecification. New log documents are
 * created pre-filled with the target object's ID and the
 * current account.
 *
 * @see SkyLogDocument
 * @see EODataSource
 */

@class EOGlobalID, EOFetchSpecification;

@interface SkyLogDataSource : EODataSource
{
  id         context;
  EOGlobalID *globalID;

  EOFetchSpecification *fspec;
}

- (id)initWithContext:(id)_context
             globalID:(EOGlobalID *)_gid;

- (void)setFetchSpecification:(EOFetchSpecification *)_fspec;
- (EOFetchSpecification *)fetchSpecification;

- (EOGlobalID *)globalID;
- (id)context;

@end /* SkyLogDataSource */

#endif /* __SkyLogDataSource_H__ */
