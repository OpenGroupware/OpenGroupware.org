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
// $Id$

#ifndef NGFileManagerTarTool_h
#define NGFileManagerTarTool_h

#include <OGoProject/NGFileManagerCopyTool.h>

@class NSException;
@class NSString;
@class NSArray;
@class NSData;
@class NSDictionary;

@interface NGFileManagerTarTool : NGFileManagerCopyTool
{
}
- (NSException *)tarPath:(NSString *)_srcPath toPath:(NSString *)_toPath;
- (NSException *)tarPaths:(NSArray *)_srcPaths toPath:(NSString *)_toPath;
- (NSData *)dataByTaringLocalPath:(NSString *)_path;
@end /* NGFileManagerTarTool */

@interface NGFileManagerUntarTool : NGFileManagerCopyTool {}
- (NSException *)untarPath:(NSString *)_tarfile toPath:(NSString *)_toPath;
- (NSException *)untarData:(NSData *)_data toPath:(NSString *)_toPath;
@end /* NGFileManagerUntarTool */

@interface NGFileManagerTarInfo : NSObject
{
  id<NSObject,NGFileManager> fileManager;
}
- (void)setFileManager:(id<NSObject,NGFileManager>)_fm;
- (id<NSObject,NGFileManager>)fileManager;

- (NSDictionary *)infoOnTaredData:(NSData *)_data;
- (NSDictionary *)infoOnTarFileAtPath:(NSString *)_path;
- (NSArray *)infoListOnTaredData:(NSData *)_data;
- (NSArray *)infoListOnTarFileAtPath:(NSString *)_path;
@end /* NGFileManagerTarInfo */

#endif /* NGFileManagerTarTool_h */
