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

#ifndef __OGoPalm_SkyPalmPostSync_H__
#define __OGoPalm_SkyPalmPostSync_H__

/*
  post sync says what's todo after a sync with your palm device

  steps:
  (1) automatic insert
    - for palm-entries, which are not already assigned to ogo-entries,
      create new ogo entries.
  (2) sync palm table entries
    - sync those entries in your palm table with the corresponding ogo entries
      BUT only into ogo direction!
      -> don't allow ogo over palm sync and a two way sync, only if it would
         sync palm data into ogo data

*/

#import <Foundation/NSObject.h>

@class SkyPalmEntryDataSource;
@class NSArray;
@class SkyDocument;
@class SkyPalmDocument;

@interface SkyPalmPostSync : NSObject
{
  SkyPalmEntryDataSource *palmDataSource;
  NSString *deviceId;

  NSArray *skyIdsOfDeleted; /* ids ogo-entries bound to deleted palm records */

  /* allowed sync types */
  /* allow a palm over skyrix sync during postsync. Default: YES */
  BOOL allowPalmOverSkyrixSync;
  /* allow a skyrix over palm sync during postsync. Default: NO */
  BOOL allowSkyrixOverPalmSync;

  /* do automatic insert. Default: YES */
  BOOL doAutomaticInsert;
}

// use this method to get your post sync
+ (SkyPalmPostSync *)postSyncForPalmDataSource:(SkyPalmEntryDataSource *)_ds
                                      deviceId:(NSString *)_deviceId;

// init (used by autoreleased init. dont use directly)
- (SkyPalmPostSync *)initWithPalmDataSource:(SkyPalmEntryDataSource *)_ds
                                   andDeviceId:(NSString *)_deviceId;

// postsync
- (BOOL)postSync;

/*
  set the ids of ogo-records bound to palm records which were deleted on
  palm
*/
- (void)setSkyIdsOfDeleted:(NSArray *)_ar;

// overwritten in subclasses
/*
  this returns the Palm entries, which are to be synced with/added to your
  ogo tables
*/
- (NSArray *)fetchPalmEntriesToInsertIntoOGo;


- (SkyDocument *)createOGoEntryForPalmEntry:(SkyPalmDocument *)_doc;

/* handle assigning */
// just assign, nothing more (no saving)
- (BOOL)assignOGoEntry:(SkyDocument *)_ogoEntry
           toPalmEntry:(SkyPalmDocument *)_palmEntry;

/* switches */
- (void)setAllowPalmOverSkyrixSync:(BOOL)_flag;
- (BOOL)allowPalmOverSkyrixSync;

- (void)setAllowSkyrixOverPalmSync:(BOOL)_flag;
- (BOOL)allowSkyrixOverPalmSync;

- (void)setDoAutomaticInsert:(BOOL)_flag;
- (BOOL)doAutomaticInsert;

/* accessors */
- (NSString *)deviceId;
- (int)defaultSkyrixSyncType;

@end /* SkyPalmPostSync  */

#endif /* __OGoPalm_SkyPalmPostSync_H__ */
