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

#ifndef __SkyProjectFolderDataSource_H__
#define __SkyProjectFolderDataSource_H__

#import <EOControl/EODataSource.h>

@class NSArray;
@class EOQualifier, EOGlobalID, EOFetchSpecification;
@class SkyProjectFileManager;                           

/**
 * @class SkyProjectFolderDataSource
 * @brief EODataSource for documents within a single project.
 *
 * Provides fetch, insert, update, and delete operations on
 * documents in a single database project folder or across an
 * entire project tree.
 *
 * Supported fetch specification hints:
 * - `fetchDeep` (BOOL) -- fetch all subdocuments from the
 *   folder (currently only from root folders).
 * - `onlySubFolderNames` (BOOL) -- return only subfolder
 *   names (uses the cache; intended for tree views).
 * - `fetchKeys` (NSArray) -- set of properties to fetch.
 *
 * @see SkyProjectFileManager
 * @see SkyProjectDocument
 * @see SkyProjectDocumentDataSource
 */

@interface SkyProjectFolderDataSource : EODataSource
{
@protected
  id                    context;
  EOGlobalID            *projectGID;
  EOGlobalID            *folderGID;
  EOFetchSpecification  *fetchSpecification;
  NSString              *path;
  BOOL                  isValid;
  SkyProjectFileManager *fileManager;
}

- (id)initWithContext:(id)_ctx
  folderGID:(EOGlobalID *)_fgid
  projectGID:(EOGlobalID *)_pgid
  path:(NSString *)_path
  fileManager:(SkyProjectFileManager *)_fm;

/* accessors */

- (BOOL)isValid;

- (void)setFetchSpecification:(EOFetchSpecification *)_fspec;
- (EOFetchSpecification *)fetchSpecification;

/* fetching */

- (NSArray *)fetchObjects;

/* modifications */

- (id)createObject;
- (void)insertObject:(id)_obj;
- (void)updateObject:(id)_obj;
- (void)deleteObject:(id)_obj;

@end

#endif /* __SkyProjectFolderDataSource_H__ */
