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

#ifndef __LSWebInterface_SkyPalm_SkyPalmAssignEntry_H__
#define __LSWebInterface_SkyPalm_SkyPalmAssignEntry_H__

#include <OGoFoundation/LSWContentPage.h>
#include <OGoPalm/SkyPalmDocument.h>

@class SkyPalmEntryDataSource;

@interface SkyPalmAssignEntry : LSWContentPage
{
  SkyPalmDocument *doc;
  id              skyrixRecord;
  
  int             syncType;
  id              item;
  NSString        *activationCommand;

  // multiple selections for creation of skyrix or palm-records
  NSMutableArray         *palmRecords;
  NSMutableArray         *skyrixRecords;
  // ds for creating palm recs
  SkyPalmEntryDataSource *ds;
  NSArray                *devices;
  NSString               *deviceId;

  int             index;
}

- (id)fetchSkyrixRecord;
- (NSString *)primarySkyKey;  // primary key of skyrix record

// accessors
- (void)setSkyrixRecord:(id)_rec;
- (id)skyrixRecord;
- (void)setDoc:(SkyPalmDocument *)_doc;
- (void)setSyncType:(int)_type;
- (id)item;
- (int)index;
- (id)doc;
- (BOOL)assignToRecord;
- (BOOL)createNewRecord;
- (BOOL)createFromRecord;
- (BOOL)isSingleSelection;
- (NSString *)titleKey;

- (void)setSkyrixRecords:(NSMutableArray *)_recs;
- (NSMutableArray *)skyrixRecords;
- (void)setPalmRecords:(NSMutableArray *)_recs;
- (NSMutableArray *)palmRecords;
- (SkyPalmEntryDataSource *)dataSource;

- (NSArray *)devices;
- (void)setDeviceId:(NSString *)_deviceId;
- (NSString *)deviceId;

// actions
- (id)multipleSave;
- (id)save;
- (id)cancel;

@end

#endif /* __LSWebInterface_SkyPalm_SkyPalmAssignEntry_H__ */
