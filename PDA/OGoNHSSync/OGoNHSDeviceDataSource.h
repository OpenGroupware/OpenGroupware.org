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

#ifndef __OGoNHSDeviceDataSource_H__
#define __OGoNHSDeviceDataSource_H__

#include <OGoPalm/SkyPalmDocumentDataSource.h>

@class PPTransaction, PPSyncContext, LSCommandContext;
@class LSCommandContext;

@interface OGoNHSDeviceDataSource : SkyPalmDocumentDataSource
{
  PPTransaction    *tx;
  PPSyncContext    *ppSync;
  
  NSString         *deviceId;
  NSNumber         *companyId;
  NSString         *palmDb;

  NSMutableArray   *newPalmIds;

  // for fetching deleted objs
  LSCommandContext *ctx;

  id               lastInsertedGID;
}

+ (id)dataSourceWithTransaction:(PPTransaction *)_tx
  deviceId:(NSString *)_deviceId
  companyId:(NSNumber *)_companyId
  palmDb:(NSString *)_palmDb;

- (void)prepareSync;
- (NSArray *)newSkyPalmMapping;
- (void)setCommandContext:(LSCommandContext *)_ctx;

- (BOOL)syncCategories; // DEF: YES

- (void)mapLastInsertedToSkyId:(id)_skyId;

@end

#endif /* __OGoNHSDeviceDataSource_H__ */
