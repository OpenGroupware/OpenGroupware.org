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
#ifndef __SkyFSFileManager_H__
#define __SkyFSFileManager_H__

#include <NGExtensions/NGExtensions.h>

@class NSFileManager, NSString, NSDictionary, NSDistributedLock, NSException;
@class SkyDocument;

@interface SkyFSFileManager : NGFileManager
{
  NSFileManager *fileManager;
  NSString      *workingPath;
  NSDictionary  *fileSystemAttributes;
  id            project;
  id            context;

  NSDistributedLock *lock;

  NSException *lastException;
}

- (id)initWithContext:(id)_context projectGlobalID:(EOGlobalID *)_gid;
- (id)initWithContext:(id)_context project:(id)_project;

- (BOOL)movePaths:(NSArray *)_src toPath:(NSString *)_d handler:(id)_handler;

- (BOOL)supportsHistoryDataSource;
- (BOOL)supportsProperties;
- (BOOL)supportsUniqueFileIds;
- (EODataSource *)dataSourceForDocumentSearchAtPath:(NSString *)_path;
- (BOOL)isSymbolicLinkEnabledAtPath:(NSString *)_path;

- (SkyDocument *)documentAtPath:(NSString *)_path;


- (BOOL)createDirectoryAtPath:(NSString *)_path attributes:(NSDictionary *)_at;

/* file operations */

- (BOOL)copyPath:(NSString *)_s toPath:(NSString *)_d handler:(id)_handler;
- (BOOL)movePath:(NSString *)_s toPath:(NSString *)_d handler:(id)_handler;
- (BOOL)linkPath:(NSString *)_s toPath:(NSString *)_d handler:(id)_handler;

- (BOOL)removeFileAtPath:(NSString *)_path handler:(id)_handler;

- (BOOL)createFileAtPath:(NSString *)_path contents:(NSData *)_contents
  attributes:(NSDictionary *)_attributes;

/* getting and comparing file contents */

- (NSData *)contentsAtPath:(NSString *)_path;
- (BOOL)contentsEqualAtPath:(NSString *)_path1 andPath:(NSString *)_path2;

/* determining access to files */

- (BOOL)fileExistsAtPath:(NSString *)_path isDirectory:(BOOL*)_isDirectory;
- (BOOL)isReadableFileAtPath:(NSString *)_path;
- (BOOL)isWritableFileAtPath:(NSString *)_path;
- (BOOL)isExecutableFileAtPath:(NSString *)_path;
- (BOOL)isDeletableFileAtPath:(NSString *)_path;

/* Getting and setting attributes */

- (NSDictionary *)fileAttributesAtPath:(NSString *)_p traverseLink:(BOOL)_flag;
- (NSDictionary *)fileSystemAttributesAtPath:(NSString *)_p;
- (BOOL)changeFileAttributes:(NSDictionary *)_attributes atPath:(NSString *)_p;

/* discovering directory contents */

- (NSArray *)directoryContentsAtPath:(NSString *)_path;
- (NSDirectoryEnumerator *)enumeratorAtPath:(NSString *)_path;
- (NSArray *)subpathsAtPath:(NSString *)_path;

/* symbolic-link operations */

- (BOOL)createSymbolicLinkAtPath:(NSString *)_p pathContent:(NSString *)_dpath;
- (NSString *)pathContentOfSymbolicLinkAtPath:(NSString *)_path;

/* feature check */

- (BOOL)supportsFeature:(NSString *)_featureURI atPath:(NSString *)_path;

/* writing */

- (BOOL)writeContents:(NSData *)_content atPath:(NSString *)_path;

/* global-IDs */

- (EOGlobalID *)globalIDForPath:(NSString *)_path;
- (NSString *)pathForGlobalID:(EOGlobalID *)_gid;

/* trash */

- (BOOL)supportsTrashFolderAtPath:(NSString *)_path;
- (NSString *)trashFolderForPath:(NSString *)_path;

@end /* SkyFSFileManager */

@interface SkyFSFileManager(Lock)

- (NSDistributedLock *)lock;
- (BOOL)tryLock;
- (void)breakLock;
- (void)unlock;
- (NSDate *)lockDate;

@end /*  SkyFSFileManager(Lock) */

@interface SkyFSFileManager(Exception)

- (void)resetLastException;
- (NSException *)lastException;
- (void)setLastException:(NSException *)_exc;

@end /* SkyFSFileManager(Exception) */

@interface SkyFSException : NSException

+ (id)reason:(NSString *)_reason;
+ (id)reason:(NSString *)_reason userInfo:(NSDictionary *)_info;

- (id)initWithReason:(NSString *)_reason
  userInfo:(NSDictionary *)_info;

@end /* SkyFSException : NSException */


#endif /* __SkyFSFileManager_H__ */

