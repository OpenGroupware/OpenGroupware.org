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

#ifndef __SkyFSDataSource_H__
#define __SkyFSDataSource_H__

#include <EOControl/EODataSource.h>

@class NSString;
@class SkyFSFileManager;
@class EOGlobalID, EOFetchSpecification;

/**
 * @class SkyFSDataSource
 * @brief EODataSource for filesystem-backed project documents.
 *
 * Provides fetch operations for documents stored in a
 * directory on the local file system. The datasource is
 * initialized with a SkyFSFileManager, a command context,
 * the project object, and a base directory path. Only
 * existing directories are accepted as the base path.
 *
 * @see SkyFSFileManager
 * @see SkyFSDocument
 * @see SkyFSFolderDataSource
 */

@interface SkyFSDataSource : EODataSource
{
  NSString             *path;
  id                   context;
  SkyFSFileManager     *fileManager;
  id                   project;
  EOFetchSpecification *fetchSpecification;
}

- (id)initWithFileManager:(SkyFSFileManager *)_fm
  context:(id)_ctx
  project:(id)_project
  path:(NSString *)_path;

@end /* SkyFSDataSource */

#endif /* __SkyFSDataSource_H__ */

