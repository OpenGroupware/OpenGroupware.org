/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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

#ifndef __SkyProjectFileManager_H__
#define __SkyProjectFileManager_H__

#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>
#import <Foundation/NSDate.h>
#import <OGoProject/SkyContentHandler.h>
#include <NGExtensions/NGFileManager.h>
#include <NGExtensions/NSFileManager+Extensions.h>


/*
  Defaults SkyProjectFileManagerErrorLogEnabled --> log all errors
           SkyProjectFileManagerAbortOnErrors   --> core on error
*/

@class NSString, NSException, NSData, NSDictionary, NSArray, NSMutableDictionary;
@class SkyProjectFileManagerCache, SkyProjectDocument;
@class EOGlobalID, EOQualifier;

typedef enum {
  FMVersioningStatus_UNKNOWN,
  FMVersioningStatus_RELEASED,
  FMVersioningStatus_EDIT
} FMVersioningStatus;

@interface SkyProjectFileManager : NGFileManager < NSCopying >
{
@protected
  SkyProjectFileManagerCache *cache;
  NSException                *lastException;
  NSString                   *notifyPathName;
  int                        lastErrorCode;
  NSMutableDictionary        *errorUserInfo;
}

- (id)initWithContext:(id)_context projectGlobalID:(EOGlobalID *)_gid;
- (id)initWithContext:(id)_context projectCode:(NSString *)_code;
- (id)initWithFileManagerCache:(SkyProjectFileManagerCache *)_cache;


/* current directory */

- (BOOL)changeCurrentDirectoryPath:(NSString *)_path;
- (NSString *)currentDirectoryPath;

/* existence & access */

- (BOOL)fileExistsAtPath:(NSString *)_path;
- (BOOL)fileExistsAtPath:(NSString *)_path isDirectory:(BOOL *)_flag;

- (BOOL)isInsertableDirectoryAtPath:(NSString *)_path;
- (BOOL)isReadableFileAtPath:(NSString *)_path;
- (BOOL)isWritableFileAtPath:(NSString *)_path;
- (BOOL)isExecutableFileAtPath:(NSString *)_path;
- (BOOL)isDeletableFileAtPath:(NSString *)_path;

/* generic stuff */

- (BOOL)changeFileAttributes:(NSDictionary *)_attrs atPath:(NSString *)_path;

- (NSDictionary *)fileAttributesAtPath:(NSString *)_path
  traverseLink:(BOOL)_followLink;

- (BOOL)contentsEqualAtPath:(NSString *)_path1 andPath:(NSString *)_path2;

/* files */

- (NSData *)contentsAtPath:(NSString *)_path;

- (BOOL)createFileAtPath:(NSString *)_path
  contents:(NSData *)_contents
  attributes:(NSDictionary *)_attrs;
- (BOOL)createFiles:(NSDictionary *)_dict atPath:(NSString *)_path;

- (BOOL)removeFileAtPath:(NSString *)_path handler:(id)_handler;
- (BOOL)removeFilesAtPaths:(NSArray *)_paths handler:(id)_handler;
- (BOOL)movePath:(NSString *)_source toPath:(NSString *)_dest
  handler:(id)_handler;

- (BOOL)movePaths:(NSArray *)_files toPath:(NSString *)_dest handler:(id)_handler;

- (BOOL)trashFilesAtPaths:(NSArray *)_path handler:(id)_handler;

/* links */

- (NSString *)pathContentOfSymbolicLinkAtPath:(NSString *)_path;
- (BOOL)createSymbolicLinkAtPath:(NSString *)_path
  pathContent:(NSString *)_targ;

/* directories */


- (BOOL)copyPath:(NSString*)_source toPath:(NSString*)_destination
  handler:_handler;
- (NSArray *)directoryContentsAtPath:(NSString *)_path;
- (NSArray *)subpathsAtPath:(NSString *)_path;
- (BOOL)createDirectoryAtPath:(NSString *)_path
  attributes:(NSDictionary *)_attr;

/* file-system (=project) */

- (NSDictionary *)fileSystemAttributesAtPath:(NSString *)_path;

- (BOOL)supportsHistoryDataSource;
- (BOOL)supportsProperties;
- (BOOL)supportsUniqueFileIds;
- (EODataSource *)dataSourceForDocumentSearchAtPath:(NSString *)_path;
- (BOOL)isSymbolicLinkEnabledAtPath:(NSString *)_path;
@end /* SkyProjectFileManager */

@class NSString, NSData, NSException;
@class EODataSource;

#include <NGExtensions/NSFileManager+Extensions.h>

@interface SkyProjectFileManager(ExtendedFileManager)
  <NGFileManagerDataSources, NGFileManagerVersioning,
  NGFileManagerLocking >

+ (EOGlobalID *)projectGlobalIDForDocumentGlobalID:(EOGlobalID *)_dgid
  context:(id)_ctx;

/* accessors */

- (id)context;

- (NSArray *)readOnlyDocumentKeys;

/* feature check */

- (BOOL)supportsTrashFolderAtPath:(NSString *)_path;

/* writing */

// TODO: this does not match the NGFileManager method! Intended?
- (BOOL)writeContents:(NSData *)_content atPath:(NSString *)_path
  handler:(id)_handler;

- (NSString *)trashFolderForPath:(NSString *)_path;

/* global ids */

- (NSString *)pathForGlobalID:(EOGlobalID *)_gid;
- (EOGlobalID *)globalIDForPath:(NSString *)_path;

/*
  if useSessionCache == YES all caches will be removed after a request, else
  the caches will be exist after -flush is called or timeout is reached
*/
//hh: -setFlushOnCommit:(BOOL)_flag, -doesFlushOnCommit
/* deprecated 
   - (BOOL)useSessionCache; 
   - (void)setUseSessionCache:(BOOL)_cache;
   - (NSTimeInterval)flushTimeout;
   - (void)setFlushTimeout:(NSTimeInterval)_timeInt;
*/


@end /* SkyProjectFileManager(ExtendedFileManager) */

@interface SkyProjectFileManager(Cache)
- (void)flush;
@end


extern NSString *SkyProjectFM_MoveFailedAtPaths;

@interface SkyProjectFileManager(ErrorHandling)
- (NSException *)lastException;
- (void)setLastException:(NSException *)_exc;
- (int)lastErrorCode;
- (NSString *)lastErrorDescription;
- (NSString *)errorDescriptionForCode:(int)_code;
- (NSDictionary *)errorUserInfo;
- (BOOL)supportsExternalErrorDescription;
@end
                                      

@class SkyProjectDocument;

@interface SkyProjectFileManager(ProjectDocumentSupport)

- (SkyProjectDocument *)documentAtPath:(NSString *)_path;
- (BOOL)writeDocument:(SkyProjectDocument *)_doc toPath:(NSString *)_path;

- (SkyProjectDocument *)createDocumentAtPath:(NSString *)_path
  contents:(NSData *)_contents
  attributes:(NSDictionary *)_attrs;

@end

@interface SkyProjectFileManager(CustomRights)

- (BOOL)isOperation:(NSString *)_op allowedOnPath:(NSString *)_path;
- (NSString *)filePermissionsAtPath:(NSString *)_path;

@end /* SkyProjectFileManager(CustomRights) */

@interface SkyProjectFileManager(Datasources)
- (EODataSource *)dataSourceAtPath:(NSString *)_path;
- (EODataSource *)dataSource;
@end /* SkyProjectFileManager(Datasources) */

@interface SkyProjectFileManager(Documents)
- (NSString *)defaultProjectDocumentNamespace;
- (SkyProjectDocument *)documentAtPath:(NSString *)_path;
- (BOOL)writeDocument:(SkyProjectDocument *)_doc toPath:(NSString *)_path;
- (SkyProjectDocument *)createDocumentAtPath:(NSString *)_path
  contents:(NSData *)_contents
  attributes:(NSDictionary *)_attrs;
- (BOOL)deleteDocument:(SkyProjectDocument *)_doc;
- (BOOL)updateDocument:(SkyProjectDocument *)_doc;
@end

@interface SkyProjectFileManager(Notifications)
- (void)registerObject:(id)_obj selector:(SEL)_sel
  forUnvalidateOnPath:(NSString *)_path;

- (void)registerObject:(id)_obj selector:(SEL)_sel
  forChangeOnPath:(NSString *)_path;

- (void)registerObject:(id)_obj selector:(SEL)_sel
  forVersionChangeOnPath:(NSString *)_path;

- (void)postUnvalidateNotificationForPath:(NSString *)_path;
- (void)postChangeNotificationForPath:(NSString *)_path;
- (void)postVersionChangeNotificationForPath:(NSString *)_path;
- (void)postSkyGlobalIDWasDeleted:(EOGlobalID *)_gid;
- (void)postSkyGlobalIDWasCopied:(EOGlobalID *)_gid;
@end


@interface SkyProjectFileManager(Locking)
- (BOOL)supportsVersioningAtPath:(NSString *)_path;
- (BOOL)supportsFolderDataSourceAtPath:(NSString *)_path;
- (BOOL)supportsLockingAtPath:(NSString *)_path;

- (BOOL)checkoutFileAtPath:(NSString *)_path handler:(id)_handler;
- (BOOL)releaseFileAtPath:(NSString *)_path handler:(id)_handler;
- (BOOL)rejectFileAtPath:(NSString *)_path handler:(id)_handler;
- (FMVersioningStatus)versioningStatusAtPath:(NSString *)_path;
- (BOOL)checkoutFileAtPath:(NSString *)_path version:(NSString *)_version
  handler:(id)_handler;
- (NSString *)lastVersionAtPath:(NSString *)_path;
- (NSArray *)versionsAtPath:(NSString *)_path;
- (NSData *)contentsAtPath:(NSString *)_path version:(NSString *)_version;
- (NSDictionary *)fileAttributesAtPath:(NSString *)_path
  traverseLink:(BOOL)_followLink
  version:(NSString *)_version;

@end /* SkyProjectFileManager(Locking) */

@class EOGenericRecord;

@interface SkyProjectFileManager(GenericRecordGeneration)
- (EOGenericRecord *)genericRecordForDocGID:(EOGlobalID *)_dgig;
@end /* SkyProjectFileManager(GenericRecordGeneration) */

@interface SkyProjectFileManager(Qualifier)

+ (BOOL)supportQualifier:(EOQualifier *)_qual;

+ (EOQualifier *)convertQualifier:(EOQualifier *)_qualifier
  projectId:(NSNumber *)_pid
  evalInMemory:(BOOL *)evalQual_;

+ (EOQualifier *)replaceAttributes:(EOQualifier *)_qual;
@end /* SkyProjectFileManager(Qualifier) */

@protocol SkyProjectFileManagerContext
- (NSString *)accountLogin4PersonId:(NSNumber *)_personId;
- (id)commandContext;
- (id)getAttachmentNameCommand;
- (void)setGetAttachmentNameCommand:(id)_id;
@end

@interface SkyProjectFileManager(FileAttributes)

+ (NSString *)blobNameForDocument:(id)_doc globalID:(EOGlobalID *)_gid
  realDoc:(id)_realDoc manager:(id)_manager
  projectId:(NSNumber *)_projectId
  context:(id<SkyProjectFileManagerContext>)_ctx;

+ (void)runGetAttachmentNameCommand:(id)_doc
  projectId:(NSNumber *)_projectId
  context:(id<SkyProjectFileManagerContext>)_ctx;

+ (NSDictionary *)buildFileAttrsForDoc:(NSDictionary *)_doc
  editing:(NSDictionary *)_editing
  atPath:(NSString *)_path
  isVersion:(BOOL)_isVersion
  projectId:(NSNumber *)_projectId
  fileAttrContext:(id<SkyProjectFileManagerContext>)_context;

+ (NSDictionary *)buildFileAttrsForDoc:(NSDictionary *)_doc
  editing:(NSDictionary *)_editing
  atPath:(NSString *)_path
  isVersion:(BOOL)_isVersion
  projectId:(NSNumber *)_projectId
  projectName:(NSString *)_pName
  projectNumber:(NSString *)_pNumber
  fileAttrContext:(id<SkyProjectFileManagerContext>)_context;

+ (NSString *)formatTitle:(NSString *)_title;
@end /* SkyProjectFileManager(FileAttributes) */

@interface SkyProjectFileManager(BlobHandler)
- (BOOL)supportsBlobHandler;
- (id<SkyBlobHandler>)blobHandlerAtPath:(NSString *)_path;
@end /* SkyBlobHandler(BlobHandler) */

#endif /* __SkyProjectFileManager_H__ */
