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

#ifndef __SkyObjectInfoDaemon_SkyObjectInfoAction_PrivateMethods_H__
#define __SkyObjectInfoDaemon_SkyObjectInfoAction_PrivateMethods_H__

#include "SkyObjectInfoAction.h"

@class NSMutableArray, NSArray, NSString;
@class EOGlobalID;

@interface SkyObjectInfoAction(PrivateMethods)

- (void)_fillArray:(NSMutableArray *)_array
  withActorsForGlobalIDs:(NSArray *)_gids;
- (NSArray *)_dictionariesForLogRecords:(NSArray *)_records
  withActor:(BOOL)_withActor;
- (NSArray *)_getPersonsForGIDs:(NSArray *)_gids;
- (NSString *)_urlStringForGlobalId:(id)_gid;
- (EOGlobalID *)_globalIdForPersonWithId:(NSString *)_id;
- (void)_ensureCurrentTransactionIsCommitted;
- (id)documentManager;

@end

#endif /* __SkyObjectInfoDaemon_SkyObjectInfoAction_PrivateMethods_H__ */
