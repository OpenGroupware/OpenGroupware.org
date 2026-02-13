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

#ifndef __SkySimpleProjectFolderDataSource_H__
#define __SkySimpleProjectFolderDataSource_H__

#include <EOControl/EODataSource.h>

/**
 * @class SkySimpleProjectFolderDataSource
 * @brief Searches project folder contents using a
 *        qualifier-based file manager lookup.
 *
 * Wraps a SkyProjectFolderDataSource and uses the
 * underlying SkyProjectFileManager to search for
 * child documents in a folder, optionally performing
 * deep (recursive) searches.
 *
 * Fetch specification hints:
 *   - fetchDeep: YES|NO (default: NO)
 *
 * Supports fetch limits and sort orderings from the
 * fetch specification.
 *
 * @see SkyProjectFolderDataSource
 * @see SkyProjectFileManager
 */

@class EOFetchSpecification;
@class SkyProjectFolderDataSource;

@interface SkySimpleProjectFolderDataSource : EODataSource
{
@protected
  SkyProjectFolderDataSource *source;
  EOFetchSpecification       *fetchSpecification;
}

- (id)initWithFolderDataSource:(SkyProjectFolderDataSource *)_ds;

@end

#endif /* __SkySimpleProjectFolderDataSource_H__ */
