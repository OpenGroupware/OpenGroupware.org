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

#ifndef __SkyPalmSyncMachine_H__
#define __SkyPalmSyncMachine_H__

#define SYNC_MODE_SKY_OVER_PALM 0
#define SYNC_MODE_PALM_OVER_SKY 1
#define SYNC_MODE_DO_NOTHING    2

#define ON_DELETE_IN_SKYRIX_REALYDELETE_IN_SKYRIX 0
#define ON_DELETE_IN_SKYRIX_ARCHIVE_IN_SKYRIX     1

#define ON_DELETE_IN_PALM_REALYDELETE_IN_SKYRIX 0
#define ON_DELETE_IN_PALM_ARCHIVE_IN_SKYRIX     1

#define SYNC_CATEGORY_FROM_PALM 0
#define SYNC_CATEGORY_FROM_SKYRIX 1
#define SYNC_CATEGORY_MERGE_BOTH 2

#import <Foundation/Foundation.h>

@class SkyPalmEntryDataSource, SkyPalmDocumentDataSource;

@interface SkyPalmSyncMachine : NSObject
{
  // sources
  SkyPalmDocumentDataSource *palmDS;
  SkyPalmEntryDataSource    *skyrixDS;

  // cache
  // timeout-check
  NSDate                    *lastAction;

  // options
  int                       syncMode;
  int                       onDeleteInSkyrix;
  int                       categorySyncMode;

  int                       timeoutCheckSeconds;

  BOOL                      syncWithSkyrixRecordBefore;
  //BOOL                      syncWithSkyrixRecordAfter;

  // errors
  NSArray                   *errorMessages;
  NSString                  *logLabel;
  NSMutableArray            *skyIdsOfDeletedPalmRecords;
}

- (void)setPalmDataSource:(SkyPalmDocumentDataSource *)_palmDS;
- (SkyPalmDocumentDataSource *)palmDataSource;

- (void)setSkyrixDataSource:(SkyPalmEntryDataSource *)_skyDS;
- (SkyPalmEntryDataSource *)skyrixDataSource;

- (void)setSyncMode:(int)_mode;
- (int)syncMode;

- (void)setCategorySyncMode:(int)_mode;
- (int)categorySyncMode;

- (void)setSyncWithSkyrixRecordBefore:(BOOL)_flag;
- (BOOL)syncWithSkyrixRecordBefore;

//- (void)setSyncWithSkyrixRecordAfter:(BOOL)_flag;
//- (BOOL)syncWithSkyrixRecordAfter;

- (NSArray *)errorMessages;
- (void)setLogLabel:(NSString *)_label;

// syncing
- (void)syncRecordsWithDeviceId:(NSString *)_deviceId;
- (void)syncPalmDS:(SkyPalmDocumentDataSource *)_palmDS
      withSkyrixDS:(SkyPalmEntryDataSource *)_skyDS
         forDevice:(NSString *)_dev;
- (void)syncCategoriesForDeviceId:(NSString *)_devId;

// assigning
- (void)assignRecords:(NSArray *)_mapping;
- (void)assignCategories:(NSArray *)_mapping;

- (NSArray *)skyIdsOfDeletedPalmRecords;


@end

#endif /* __SkyPalmSyncMachine_H__ */
