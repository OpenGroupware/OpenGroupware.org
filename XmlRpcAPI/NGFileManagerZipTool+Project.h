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

#ifndef NGFileManagerZipTool_Project_h
#define NGFileManagerZipTool_Project_h

#include "NGFileManagerZipTool.h"

@class NSArray;
@class NSData;

/**
 * @category NGFileManagerZipTool(Project)
 *
 * Adds project-level zip support to NGFileManagerZipTool.
 * Provides -zipProjectPaths:fileManager:compressionLevel:
 * which copies the specified paths from a project file
 * manager into a local temporary directory, zips them, and
 * returns the resulting archive as NSData.
 */
@interface NGFileManagerZipTool(Project)
- (NSData *)zipProjectPaths:(NSArray *)_srcPaths
  fileManager:(id)_fileManager
  compressionLevel:(int)_level;
@end /* NGFileManagerZipTool+Project */

#endif /* NGFileManagerZipTool_Project_h */
