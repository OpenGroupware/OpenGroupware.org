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

#ifndef __SkyPalmDocument_H__
#define __SkyPalmDocument_H__

#import <Foundation/Foundation.h>

@class SkyPalmDocumentDataSource, SkyPalmCategoryDocument;

@interface SkyPalmDocument : NSObject
{
  NSDictionary              *source; // dicitionary with cached original values
  SkyPalmDocumentDataSource *dataSource; // dataSource of document
  BOOL                      isNewRecord; // is a new document
  BOOL                      isSaved; // is document saved

  BOOL                      isObserving;
  BOOL                      reloadSkyrixRecord;

  // values
  NSNumber                  *categoryId;
  NSString                  *deviceId;
  BOOL                      isDeleted;
  BOOL                      isNew;
  BOOL                      isArchived;
  BOOL                      isModified;
  BOOL                      isPrivate;
  NSString                  *md5Hash;
  int                       palmId;
  id                        globalID;
  
  id                        skyrixId;
  int                       syncType;
  int                       skyrixVersion;

  int                       objectVersion;
  int                       skyrixPalmVersion;

  id                        skyrixRecord;

  SkyPalmCategoryDocument   *category;
}

// initalizing
- (id)initWithDictionary:(NSDictionary *)_src
          fromDataSource:(SkyPalmDocumentDataSource *)_ds;
- (id)initAsNewFromDictionary:(NSDictionary *)_src
               fromDataSource:(SkyPalmDocumentDataSource *)_ds;
- (id)initAsNewFromDataSource:(SkyPalmDocumentDataSource *)_ds;

// methods
- (NSMutableDictionary *)asDictionary;
- (void)updateSource:(NSDictionary *)_src
      fromDataSource:(SkyPalmDocumentDataSource *)_ds;

// values
- (void)setCategoryId:(NSNumber *)_catId;
- (NSNumber *)categoryId;

- (void)setDeviceId:(NSString *)_devId;
- (NSString *)deviceId;

- (NSNumber *)companyId;

- (NSString *)primaryKey;

- (id)globalID;

- (void)setMd5Hash:(NSString *)_hash;
- (NSString *)md5Hash;

- (void)setIsNew:(BOOL)_flag;
- (BOOL)isNew;

- (void)setIsModified:(BOOL)_flag;
- (BOOL)isModified;

- (void)setIsArchived:(BOOL)_flag;
- (BOOL)isArchived;

- (void)setIsDeleted:(BOOL)_flag;
- (BOOL)isDeleted;

- (void)setIsPrivate:(BOOL)_flag;
- (BOOL)isPrivate;

- (void)setPalmId:(int)_pId;
- (int)palmId;

- (int)objectVersion;
- (void)increaseObjectVersion;

- (BOOL)isEditable;
- (NSString *)syncState;
- (NSString *)generateMD5Hash;

// category document
- (SkyPalmCategoryDocument *)category;

// editing helper
- (NSArray *)devices;    // fetches possible devices
- (NSArray *)categories; // fetches possible categories
- (id)context;


// action flags
- (BOOL)isDeletable;
- (BOOL)isUndeletable;

// actions
- (void)resetFlags;  // called before save
- (id)save;     // saves actual values
- (id)saveWithoutReset;  // doesn't reset flags
- (id)revert;   // resets values
- (id)delete;   // sets isDeleted flag to YES
- (id)realyDelete; // realy deletes record
- (id)undelete; // sets isDeleted flag to NO
- (id)reload;   // reloads record from dataSource

// sync with other records
- (void)takeValuesFromDocument:(SkyPalmDocument *)_doc;

@end /* SkyPalmDocument */

@interface SkyPalmDocument(PrivatMethods)
- (void)prepareAsNew;
- (void)clearGlobalID; // clear global ID
- (NSString *)insertNotificationName;
- (NSString *)updateNotificationName;
- (NSString *)deleteNotificationName;

// helper
- (void)_takeValue:(id)_val forKey:(id)_key
            toDict:(NSMutableDictionary *)_dict;

- (NSMutableString *)_md5Source;

- (void)_setSource:(NSDictionary *)_src;
- (void)_setDataSource:(SkyPalmDocumentDataSource *)_ds;


@end /* SkyPalmDocument(PrivatMethods) */

@interface SkyPalmDocument(SkyrixSync)

- (BOOL)canAssignSkyrixRecord;
- (BOOL)canSynchronizeWithSkyrixRecord;
- (BOOL)canCreateSkyrixRecord;

- (id)syncWithSkyrixRecord;  // syncs with skyrix record
// a twoWay sync can only be performed, if there was an initial sync
- (id)forcePalmOverSkyrixSync; // force sync tho' sync type may be different
- (id)forceSkyrixOverPalmSync; 

- (void)saveSkyrixRecord;  // saves skyrix record
- (void)updateSkyrixVersions;    // update the saved version skyrix record

// skyrix record assigment
- (void)setSkyrixId:(id)_sId;
- (NSNumber *)skyrixId;
- (void)setSyncType:(int)_type;
- (int)syncType;

/**
  returns the type of action which would be called, if you call
  -syncWithSkyrixRecord. it depends upon the skyrixSyncType and the state
  of the palm and the skyrix entry
*/
- (int)actualSkyrixSyncAction;

- (void)setSkyrixVersion:(int)_version;
- (int)skyrixVersion;     // last-sync version of ogo record
- (void)setSkyrixPalmVersion:(int)_version;
- (int)skyrixPalmVersion; // last-sync version of palm record

- (void)takeValuesFromSkyrixRecord:(id)_skyrixRecord;
- (void)putValuesToSkyrixRecord:(id)_skyrixRecord;
- (BOOL)_hasSkyrixRecordBinding;
- (BOOL)hasSkyrixRecord;
- (id)skyrixRecord;
- (id)fetchSkyrixRecord;

- (void)_observeSkyrixRecord:(id)_skyrixRecord;
- (void)_dropSkyrixRecord; // only release skyrixrecord assignment
- (void)_stopObserving;

- (void)_bulkFetch_setSkyrixRecord:(id)_skyrixRecord; // during bulk fetch

- (int)skyrixSyncState;  // sync state with skyrix record

@end /* SkyPalmDocument(SkyrixSync) */

@interface SkyPalmDocumentSelection : NSObject
{
  NSMutableArray *all; // all records
}

+ (SkyPalmDocumentSelection *)selectionWithDocs:(NSArray *)_docs;

- (NSArray *)docs;
- (void)addDocs:(NSArray *)_docs;
- (void)addDoc:(SkyPalmDocument *)_doc;
- (void)clearSelection;

@end /* SkyPalmDocumentSelection */

#endif /* __SkyPalmDocument_H__ */
