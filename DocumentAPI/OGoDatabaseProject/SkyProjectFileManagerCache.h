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

#ifndef __SkyProjectFileManagerCache_H__
#define __SkyProjectFileManagerCache_H__

#import <Foundation/Foundation.h>
#import "SkyProjectFileManager.h"

@class NSMutableDictionary, NSString, NSDictionary, NSData;
@class EOGlobalID, EOQualifier;
@class SkyProjectFileManager, SkyAccessManager;

/*
  Defaults:

  SkyProjectFileManagerUseSessionCache YES/NO // syncronize FileManager
                                              //flush with context flush

  if (!SkyProjectFileManagerUseSessionCache) {
    SkyProjectFileManagerFlushTimeout n    // flush cache all n seconds after
                                           // the last flush
    
    SkyProjectFileManagerClickTimeout n    // flush cache after n seconds
                                           // of inactivity
                                               
    SkyProjectFileManagerCacheTimeout n    // flush cache after n seconds
                                           // after the last project manager
                                           // released
  }
*/

@interface SkyProjectFileManagerCache : NSObject <SkyProjectFileManagerContext>
{
  id context;
  id project;
  
  /* caching */
  NSString            *cachePrefix;
  BOOL                useSessionCache;

  NSTimeInterval      flushTimeout;
  NSTimeInterval      cacheTimeout;
  NSTimeInterval      clickTimeout;

  int                 managerRegister;
  NSMutableDictionary *fileManagerCache;
  
  NSTimer             *flushTimer;
  NSTimer             *cacheTimer;
  NSTimer             *clickTimer;

  /* notifications */
  NSDictionary        *notifyUserInfo;
  NSString            *changeNotifyName;
  NSString            *unvalidateNotifyName;
  NSString            *versionNotifyName;
  
  BOOL                commitTransaction;

  SkyAccessManager    *accessManager;


  /* caching */
  id getAttachmentNameCommand;
}

+ (id)cacheWithContext:(id)_context projectGlobalID:(EOGlobalID *)_gid;

- (id)initWithContext:(id)_context projectGlobalID:(EOGlobalID *)_gid;

- (id)context;
- (id)project;

- (void)registerManager:(SkyProjectFileManager *)_manager;
- (void)removeManager:(SkyProjectFileManager *)_manager;
- (void)flushWithManager:(SkyProjectFileManager *)_manager;


- (BOOL)isInsertableDirectoryAtPath:(NSString *)_path
  manager:(SkyProjectFileManager *)_manager;

- (BOOL)isReadableFileAtPath:(NSString *)_path
  manager:(SkyProjectFileManager *)_manager;

- (BOOL)isUnlockableFileAtPath:(NSString *)_path
  manager:(SkyProjectFileManager *)_manager;

- (BOOL)isWritableFileAtPath:(NSString *)_path
  manager:(SkyProjectFileManager *)_manager;
  
- (BOOL)isExecutableFileAtPath:(NSString *)_path
  manager:(SkyProjectFileManager *)_manager;
  
- (BOOL)isDeletableFileAtPath:(NSString *)_path
  manager:(SkyProjectFileManager *)_manager;
  
- (BOOL)isOperation:(NSString *)_op allowedOnPath:(NSString *)_path
  manager:(SkyProjectFileManager *)_manager;

- (NSString *)filePermissionsAtPath:(NSString *)_path
  manager:(SkyProjectFileManager *)_manager;

- (BOOL)folder:(NSString *)_folder hasSubFolder:(NSString *)_subFolder
  manager:(SkyProjectFileManager *)_manager;

- (NSArray *)searchChildsForFolder:(NSString *)_path
  deep:(BOOL)_deep
  qualifier:(EOQualifier *)_qualifier
  manager:(id)_manager;

@end /* SkyProjectFileManagerCache */

@interface SkyProjectFileManagerCache(Caching)

- (NSArray *)childAttributesAtPath:(NSString *)_path manager:(id)_manager;
- (NSArray *)childFileNamesAtPath:(NSString *)_path manager:(id)_manager;
- (NSDictionary *)fileAttributesAtPath:(NSString *)_path manager:(id)_manager;
- (EOGlobalID *)gidForPath:(NSString *)_path manager:(id)_manager;
- (NSString *)pathForGID:(EOGlobalID *)_gid manager:(id)_manager;
- (id)genericRecordForGID:(EOGlobalID *)_gid manager:(id)_manager;
- (id)genericRecordForFileName:(NSString *)_path manager:(id)_manager;
- (id)genericRecordForAttrs:(NSDictionary *)_attrs manager:(id)_manager;
- (NSDictionary *)versionAttrsAtPath:(NSString *)_path
  version:(NSString *)_version manager:(id)_manager;
- (NSArray *)allVersionAttrsAtPath:(NSString *)_path manager:(id)_manager;

@end /* SkyProjectFileManager(Caching) */

@interface SkyProjectFileManagerCache(Settings)

- (BOOL)useSessionCache;
- (void)setUseSessionCache:(BOOL)_cache;
- (NSTimeInterval)flushTimeout;
- (void)setFlushTimeout:(NSTimeInterval)_timeInt;
- (NSTimeInterval)clickTimeout;
- (void)setClickTimeout:(NSTimeInterval)_timeInt;
- (NSTimeInterval)cacheTimeout;
- (void)setCacheTimeout:(NSTimeInterval)_timeInt;
- (void)initSessionCache;
- (void)rejectClickTimer;
- (void)startClickTimer;
- (void)initClickTimer;
- (void)initFlushTimer;
- (void)initCacheTimer;
- (void)flush;

@end /* SkyProjectFileManagerCache(Settings) */

#endif

