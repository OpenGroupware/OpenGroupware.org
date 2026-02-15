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

#ifndef _NGUNIXTOOL_H
#define _NGUNIXTOOL_H

#import "common.h"
#include <unistd.h>

/**
 * @class NGUnixTool
 *
 * Helper class that provides configurable paths to common
 * Unix command-line utilities (zip, unzip, zipinfo, rm,
 * diff, tar) and convenience methods for working with
 * temporary files and directories.
 *
 * Tool paths are resolved from NSUserDefaults and can be
 * overridden at runtime. Both class and instance accessors
 * are provided. The class also offers methods to create
 * unique temporary file paths, write NSData to temporary
 * files, and recursively remove local paths via the
 * configured rm tool.
 */
@interface NGUnixTool: NSObject {
}
+ (NSString *)pathToZipTool;
+ (NSString *)pathToUnzipTool;
+ (NSString *)pathToZipInfoTool;
+ (NSString *)pathToRmTool;
+ (NSString *)pathToDiffTool;
+ (NSString *)pathToTarTool;
- (NSString *)pathToZipTool;
- (NSString *)pathToUnzipTool;
- (NSString *)pathToZipInfoTool;
- (NSString *)pathToRmTool;
- (NSString *)pathToDiffTool;
- (NSString *)pathToTarTool;

- (NSString *)_uniquePath;
- (NSString *)_uniqueFileWithData:(NSData *)_data;
- (BOOL)_removeLocalPath:(NSString *)_path;
@end

#endif
