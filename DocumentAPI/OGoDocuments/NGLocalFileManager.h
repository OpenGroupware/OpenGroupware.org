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

#ifndef __NGLocalFileManager_h__
#define __NGLocalFileManager_h__

#import <Foundation/NSString.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSUtilities.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSFileManager.h>
#import <EOControl/EOControl.h>
#include <NGExtensions/NGFileManager.h>
#include <OGoDocuments/SkyDocument.h>
#include <OGoDocuments/SkyDocumentFileManager.h>

@class NSNumber, NSString, NSData, NSDate, NSArray, NSMutableArray;
@class NSFileManager, NSDirectoryEnumerator;
@class EOGlobalID;
@class NGLocalFileDocument;

@interface NGLocalFileManager : NGFileManager <SkyDocumentFileManager>
{
  NSString            *rootPath;
  NSString            *cdp; // current directory path
  NSFileManager       *fm;
  BOOL                allowModifications;

  /* caches (activated if no modifications are allowed) */
  NSMutableDictionary *pathToDoc;
  NSMutableDictionary *pathToDirList;
  NSMutableDictionary *pathExists;
}

- (id)initWithRootPath:(NSString *)_root allowModifications:(BOOL)_allow;

/* cache */

- (void)flush;

/* Directory operations */
- (BOOL)changeCurrentDirectoryPath:(NSString*)_path;
- (BOOL)createDirectoryAtPath:(NSString*)_path
  attributes:(NSDictionary*)_attributes;
- (NSString *)currentDirectoryPath;

/* File operations */
- (BOOL)copyPath:(NSString *)_source
  toPath:(NSString *)_destination
  handler:(id)_handler;
- (BOOL)movePath:(NSString *)_source
  toPath:(NSString *)_destination 
  handler:(id)_handler;
- (BOOL)linkPath:(NSString *)_source
  toPath:(NSString *)_destination
  handler:(id)_handler;
- (BOOL)removeFileAtPath:(NSString *)_path handler:handler;
- (BOOL)createFileAtPath:(NSString *)_path
  contents:(NSData *)_contents
  attributes:(NSDictionary *)_attributes;

/* Getting and comparing file contents */
- (NSData *)contentsAtPath:(NSString *)_path;
- (BOOL)contentsEqualAtPath:(NSString *)_path1 andPath:(NSString *)_path2;

/* Determining access to files */
- (BOOL)fileExistsAtPath:(NSString *)_path;
- (BOOL)fileExistsAtPath:(NSString *)_path isDirectory:(BOOL *)_isDirectory;
- (BOOL)isInsertableDirectoryAtPath:(NSString *)_path;
- (BOOL)isReadableFileAtPath:(NSString *)_path;
- (BOOL)isWritableFileAtPath:(NSString *)_path;
- (BOOL)isExecutableFileAtPath:(NSString *)_path;
- (BOOL)isDeletableFileAtPath:(NSString *)_path;

/* Getting and setting attributes */
- (NSDictionary *)fileAttributesAtPath:(NSString *)_path
  traverseLink:(BOOL)_flag;
- (NSDictionary *)fileSystemAttributesAtPath:(NSString *)_path;
- (BOOL)changeFileAttributes:(NSDictionary *)_attributes
  atPath:(NSString *)_path;

/* Discovering directory contents */
- (NSArray *)directoryContentsAtPath:(NSString *)_path;
- (NSDirectoryEnumerator *)enumeratorAtPath:(NSString *)_path;
- (NSArray *)subpathsAtPath:(NSString *)_path;

/* Symbolic-link operations */
- (BOOL)createSymbolicLinkAtPath:(NSString *)_path
  pathContent:(NSString *)_otherPath;
- (NSString *)pathContentOfSymbolicLinkAtPath:(NSString *)_path;

/* Converting file-system representations */
- (const char *)fileSystemRepresentationWithPath:(NSString *)_path;
- (NSString *)stringWithFileSystemRepresentation:(const char *)_string
  length:(unsigned int)_len;

/* feature check */
- (BOOL)supportsVersioningAtPath:(NSString *)_path;
- (BOOL)supportsLockingAtPath:(NSString *)_path;
- (BOOL)supportsFolderDataSourceAtPath:(NSString *)_path;
- (BOOL)supportsFeature:(NSString *)_featureURI atPath:(NSString *)_path;

/* datasources */
- (EODataSource *)dataSourceAtPath:(NSString *)_path;
- (EODataSource *)dataSource;

/* writing */
- (BOOL)writeContents:(NSData *)_content atPath:(NSString *)_path;

/* global-IDs */
- (EOGlobalID *)globalIDForPath:(NSString *)_path;
- (NSString *)pathForGlobalID:(EOGlobalID *)_gid;

/* trash */
- (BOOL)supportsTrashFolderAtPath:(NSString *)_path;
- (NSString *)trashFolderForPath:(NSString *)_path;

/* documents */
- (NGLocalFileDocument *)documentAtPath:(NSString *)_path;
- (BOOL)writeDocument:(NGLocalFileDocument *)_doc toPath:(NSString *)_path;
- (NGLocalFileDocument *)createDocumentAtPath:(NSString *)_path
  contents:(NSData *)_contents
  attributes:(NSDictionary *)_attrs;
- (BOOL)deleteDocument:(NGLocalFileDocument *)_doc;
- (BOOL)updateDocument:(NGLocalFileDocument *)_doc;

@end /* NGLocalFileManager */

@interface NSString(NGPseudoFileManager)
- (NSString *)stringByAppendingPathComponent2:(NSString *)_path;
@end /* NSString(NGLocalFileManager) */

#endif /* __NGLocalFileManager_h__ */
