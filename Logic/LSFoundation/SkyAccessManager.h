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
// $Id: SkyAccessManager.h 1 2004-08-20 11:17:52Z znek $

#ifndef __OGo_LSFoundation_SkyAccessManager__
#define __OGo_LSFoundation_SkyAccessManager__

#import <Foundation/NSObject.h>

@class NSString, NSArray, NSMutableDictionary, NSDictionary;
@class EOGlobalID;
@class LSCommandContext;

extern NSString *SkyAccessFlagsDidChange;

@interface SkyAccessManager : NSObject
{
@private
  LSCommandContext    *context; /* not retained */
  NSMutableDictionary *accessHandlers;

  BOOL commitTransaction;
}

- (id)initWithContext:(LSCommandContext *)_ctx;

- (BOOL)operation:(NSString *)_operation
  allowedOnObjectID:(EOGlobalID *)_oid;

- (BOOL)operation:(NSString *)_operation
  allowedOnObjectIDs:(NSArray *)_oids;

- (BOOL)operation:(NSString *)_operation
  allowedOnObjectID:(EOGlobalID *)_oid
  forAccessGlobalID:(EOGlobalID *)_accountID;

- (BOOL)operation:(NSString *)_operation
  allowedOnObjectIDs:(NSArray *)_oids
  forAccessGlobalID:(EOGlobalID *)_accountID;

- (NSArray *)objects:(NSArray *)_oids
  forOperation:(NSString *)_str;

- (NSArray *)objects:(NSArray *)_oids
  forOperation:(NSString *)_str
  forAccessGlobalID:(EOGlobalID *)_accessGID;

/* access operations */

- (NSString *)allowedOperationsForObjectId:(EOGlobalID *)_objId
  accessGlobalID:(EOGlobalID *)_accessId;
- (NSString *)deniedOperationsForObjectId:(EOGlobalID *)_objId
  accessGlobalID:(EOGlobalID *)_accessId;

/* returns a dictionary with accessGIDs as keys and operation as values */

- (NSDictionary *)allowedOperationsForObjectIds:(NSArray *)_objIds;
- (NSDictionary *)deniedOperationsForObjectIds:(NSArray *)_objIds;

- (NSDictionary *)allowedOperationsForObjectIds:(NSArray *)_objIds
  accessGlobalIDs:(NSArray *)_accessIds;

- (NSDictionary *)deniedOperationsForObjectIds:(NSArray *)_objIds
  accessGlobalIDs:(NSArray *)_accessIds;

- (NSDictionary *)allowedOperationsForObjectId:(EOGlobalID *)_objId;

- (NSDictionary *)deniedOperationsForObjectId:(EOGlobalID *)_objId;

- (BOOL)setOperation:(NSString *)_operation
  onObjectID:(EOGlobalID *)_objId
  forAccessGlobalID:(EOGlobalID *)_accessId;

- (BOOL)setOperations:(NSDictionary *)_operations
  onObjectID:(EOGlobalID *)_objId;

- (NSMutableDictionary *)objectId2AccessCache;

@end

#endif /* __OGo_LSFoundation_SkyAccessManager__ */

