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

#ifndef __OGoPalm_SkyPalmPreSync_H__
#define __OGoPalm_SkyPalmPreSync_H__

/*
  pre sync says what's todo before a sync with your palm device

  steps:
  (1) automatic insert
    - look for ogo data with a given qualifier/filter and add this data
      to your palm tables:
      e.g. add all appointments, you take part,  within a period of time
      to your palm dates.
  (2) sync palm table entries
    - sync those entries in your palm table with the corresponding ogo entries
      BUT only into palm direction!
      -> don't allow palm over ogo sync and a two way sync, only if it would
         sync sky data into palm data

*/

#import <Foundation/NSObject.h>

@class SkyPalmEntryDataSource;
@class NSArray;
@class SkyDocument;
@class SkyPalmDocument;

@interface SkyPalmPreSync : NSObject
{
  SkyPalmEntryDataSource *palmDataSource;
  NSString *deviceId;
  id       progressDelegate;

  /* allowed sync types */
  /* allow a palm over skyrix sync during presync. Default: NO */
  BOOL allowPalmOverSkyrixSync;
  /* allow a skyrix over palm sync during presync. Default: YES */
  BOOL allowSkyrixOverPalmSync;

  /* do automatic insert. Default: YES */
  BOOL doAutomaticInsert;
}

// use this method to get your pre sync
+ (SkyPalmPreSync *)preSyncForPalmDataSource:(SkyPalmEntryDataSource *)_ds
                                    deviceId:(NSString *)_deviceId;

// init (used by autoreleased init. dont use directly)
- (SkyPalmPreSync *)initWithPalmDataSource:(SkyPalmEntryDataSource *)_ds
                               andDeviceId:(NSString *)_deviceId;

// presync
- (BOOL)preSync;

// overwritten in subclasses
/*
  this returns the OGo entries, which are to be synced with/added to your
  palm table
*/
- (NSArray *)fetchOGoEntriesToPreSync;

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

- (void)setProgressDelegate:(id)_delegate;

/* accessors */
- (NSString *)deviceId;
- (int)defaultSkyrixSyncType;

@end /* SkyPalmPreSync  */

@interface NSObject(SkyPalmPreSync_Progress)

- (BOOL)preSyncProgress:(double)_progress;

@end /* NSObject(SkyPalmPreSync_Progress) */


#endif /* __OGoPalm_SkyPalmPreSync_H__ */
