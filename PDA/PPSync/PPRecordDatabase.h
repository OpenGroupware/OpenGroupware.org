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

#ifndef __PPSync_PPRecordDatabase_H__
#define __PPSync_PPRecordDatabase_H__

#include <PPSync/PPDatabase.h>
#import <Foundation/NSMapTable.h>

@class NSData, NSString, NSException;
@class EOGlobalID;

@interface PPRecordDatabase : PPDatabase
{
  NSMapTable *oidToRecord;
  NSMapTable *recordToOid;

  NSString      *categories[15];
  unsigned char categoryIDs[15];
}

/* accessors */

- (unsigned char)indexOfCategoryWithID:(unsigned char)_cid;
- (NSString *)categoryAtIndex:(int)_idx;
- (int)indexOfCategory:(NSString *)_category;
- (NSString *)categoryForID:(unsigned char)_cid;
- (unsigned char)categoryIDAtIndex:(int)_idx;
- (NSArray *)categories;

/* object registry */

- (id)objectForGlobalID:(EOGlobalID *)_oid;
- (EOGlobalID *)globalIDForObject:(id)_object;
- (id)faultForGlobalID:(EOGlobalID *)_oid;
- (void)recordObject:(id)_object globalID:(EOGlobalID *)_oid;
- (NSArray *)registeredObjects;

/* decoding */

- (int)decodeAppBlock:(NSData *)_block;

/* store operations */

- (BOOL)insertRecord:(id)_eo;
- (BOOL)storeRecord:(id)_eo;
- (BOOL)deleteRecord:(id)_eo;

@end

@interface NSObject(PPRecord)
- (void)awakeFromDatabase:(PPRecordDatabase *)_db
  objectID:(EOGlobalID *)_oid
  attributes:(int)_attrs
  category:(int)_category
  data:(NSData *)_data;
@end

@interface PPRecord : NSObject
{
  PPRecordDatabase *db;
  unsigned long uid;
  NSString      *category;
  BOOL          isPrivate;
  BOOL          isDeleted;
  BOOL          isDirty;
  BOOL          isArchived;
}

- (void)setDatabase:(PPRecordDatabase *)_db;

- (void)awakeFromDatabase:(PPRecordDatabase *)_db
  objectID:(EOGlobalID *)_oid
  attributes:(int)_attrs
  category:(int)_category
  data:(NSData *)_data;

/* accessors */

- (BOOL)isPrivate;
- (BOOL)isDeleted;
- (BOOL)isArchived;

- (void)setIsDirty:(BOOL)_flag;
- (BOOL)isDirty;

- (void)setCategory:(NSString *)_category;
- (NSString *)category;
- (NSException *)validateCategory:(NSString *)_category;

/* description */

- (NSString *)propertyDescription;

@end

@interface PPRecord(PalmTyping)
+ (long)palmCreator;
+ (long)palmType;
@end

#endif /* __PPSync_PPRecordDatabase_H__ */
