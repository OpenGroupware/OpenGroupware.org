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
// $Id: NGFileManagerZipTool.h 1 2004-08-20 11:17:52Z znek $

#ifndef NGFileManagerZipTool_h
#define NGFileManagerZipTool_h

#include <OGoProject/NGFileManagerCopyTool.h>

@class NSException;
@class NSString;
@class NSArray;
@class NSData;
@class NSDictionary;

@interface NGFileManagerZipTool : NGFileManagerCopyTool
{
}
- (NSException *)zipPath:(NSString *)_srcPath
  toPath:(NSString *)_toPath
  compressionLevel:(int)_level;
- (NSException *)zipPaths:(NSArray *)_srcPaths
  toPath:(NSString *)_toPath
  compressionLevel:(int)_level;
- (NSData *)dataByZippingLocalPath:(NSString *)_path
  compressionLevel:(int)_level;
@end /* NGFileManagerZipTool */

@interface NGFileManagerUnzipTool : NGFileManagerCopyTool {}
- (NSException *)unzipPath:(NSString *)_zipfile toPath:(NSString *)_toPath;
- (NSException *)unzipData:(NSData *)_data toPath:(NSString *)_toPath;
@end /* NGFileManagerUnzipTool */

@interface NGFileManagerZipInfo : NSObject
{
  id<NSObject,NGFileManager> fileManager;
}
- (void)setFileManager:(id<NSObject,NGFileManager>)_fm;
- (id<NSObject,NGFileManager>)fileManager;

- (NSDictionary *)infoOnZippedData:(NSData *)_data;
- (NSDictionary *)infoOnZipFileAtPath:(NSString *)_path;
- (NSArray *)infoListOnZippedData:(NSData *)_data;
- (NSArray *)infoListOnZipFileAtPath:(NSString *)_path;
@end /* NGFileManagerZipInfo */

#endif /* NGFileManagerZipTool_h */
