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
#ifndef __SkyFSFileManager_Internals_H__
#define __SkyFSFileManager_Internals_H__

#include "SkyFSFileManager.h"

@interface SkyFSFileManager(Internals)

- (NSString *)_makeAbsolute:(NSString *)_path;
- (NSString *)_reconvertPath:(NSString *)_path;

- (BOOL)_saveAttributes:(NSDictionary *)_attrs forPath:(NSString *)_path
  isNew:(BOOL)_new;
- (BOOL)_updateAttributes:(NSDictionary *)_attrs forPath:(NSString *)_path;
- (BOOL)_removeAttributesForPath:(NSString *)_path;

- (NSNumber *)_loginId;
- (NSString *)_loginName;

- (NSString *)_makeAbsolute:(NSString *)_path;
- (NSString *)_reconvertPath:(NSString *)_path;
- (NSArray *)fileSystemAttributes;
- (NSDictionary *)removeFileSystemAttributes:(NSDictionary *)_attrs;
- (NSString *)attributesPath;
- (NSString *)pathForAttributeFile:(NSString *)_path
  createOnDemand:(BOOL)_create;
- (BOOL)_saveAttributes:(NSDictionary *)_attrs forPath:(NSString *)_path
  isNew:(BOOL)_new;
- (BOOL)_updateAttributes:(NSDictionary *)_attrs forPath:(NSString *)_path;
- (BOOL)_removeAttributesForPath:(NSString *)_path;
- (NSDictionary *)_attributesForPath:(NSString *)_path;
- (NSNumber *)_loginId;
- (NSString *)_loginName;
- (NSString *)_makeAbsoluteInSky:(NSString *)_path;
- (NSString *)_checkPath:(NSString *)_path;
@end /* SkyFSFileManager(Internals) */

#endif /* __SkyFSFileManager_Internals_H__ */
