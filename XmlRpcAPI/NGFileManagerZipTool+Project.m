/*
  Copyright (C) 2000-2003 SKYRIX Software AG

  This file is part of OGo

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
// $Id: NGFileManagerZipTool+Project.m 1 2004-08-20 11:17:52Z znek $

#include "common.h"
#include "NGFileManagerZipTool+Project.h"
#include "NGUnixTool.h"

@implementation NGFileManagerZipTool(Project)

- (NSData *)zipProjectPaths:(NSArray *)_srcPaths
  fileManager:(id)_fileManager
  compressionLevel:(int)_level
{
  NSString                   *tmpPath    = nil;
  NGUnixTool                 *unixTool   = nil;
  NSEnumerator               *enumer     = nil;
  NSString                   *srcPath    = nil;
  NSData                     *zipData    = nil;

  unixTool    = [[NGUnixTool alloc] init];
  tmpPath     = [unixTool _uniquePath];

  [[NSFileManager defaultManager] createDirectoryAtPath:tmpPath attributes:nil];

  [self setSourceFileManager:(id<NSObject,NGFileManager>)_fileManager];
  [self setTargetFileManager:[NSFileManager defaultManager]];

  enumer      = [_srcPaths objectEnumerator];
  while ((srcPath = [enumer nextObject])) {
    [self copyPath:srcPath toPath:tmpPath handler:nil];
  }
  
  zipData = [self dataByZippingLocalPath:tmpPath compressionLevel:_level];
  [unixTool _removeLocalPath:tmpPath];
  RELEASE(unixTool);

  return zipData;
}

@end /* NGFileManagerZipTool(Project) */

