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

#ifndef __PPSync_PPSyncContext_H__
#define __PPSync_PPSyncContext_H__

#import <Foundation/NSObject.h>
#import <Foundation/NSMapTable.h>
#import "PPDataStore.h"

@class NSString, NSDate, NSArray, NSTimeZone, NSMutableSet;
@class NSMutableArray, NSData;
@class EOQualifier, EOGlobalID, EOFetchSpecification;
@class PPDatabase, PPRecordDatabase;

extern NSString      *PPStringFromCreator(unsigned long _creator);
extern NSString      *PPStringFromType(unsigned long _type);
extern unsigned long PPCreatorFromString(NSString *_creator);
extern unsigned long PPTypeFromString(NSString *_type);

#define PPSync_MAXCARDS 16

@interface PPSyncContext : PPDataStore
{
  int            sd;
  int            fsd;
  void           *pisock;
  NSTimeZone     *pilotTimeZone;
  
  /* sync state */
  BOOL           shallResetSystemAfterSync;
  NSMutableArray *deletedDatabases;
  NSMutableArray *openDatabases;
  
  /* system information */
  unsigned long  systemRomVersion;
  unsigned long  systemLocale;
  NSString       *systemName;
  
  /* user information */
  BOOL           userInfoChanged;
  unsigned long  userID;
  unsigned long  viewerID;
  unsigned long  lastSyncPC;
  NSDate         *successfulSyncDate;
  NSDate         *lastSyncDate;
  NSString       *userName;
  NSString       *password;
  
  /* net sync information */
  BOOL           lanSyncEnabled;
  NSString       *syncHostName;
  NSString       *syncAddress;
  NSString       *syncSubnetMask;

  /* cards */
  NSArray        *cards;
  // optimizing search for databases
  int lastDBInfoIndex[PPSync_MAXCARDS]; 

  /* databases */
  NSMapTable     *databases;

  /* object store */
  NSMutableSet   *cachedEntities;
}

/* accessors */

- (void)setPilotTimeZone:(NSTimeZone *)_tz;
- (NSTimeZone *)pilotTimeZone;
- (unsigned long)systemLocale;
- (unsigned long)systemRomVersion;
- (NSString *)systemName;
- (void)setUserName:(NSString *)_name;
- (NSString *)userName;

- (void)updateLastSyncDate;
- (void)updateSuccessfulSyncDate;

/* operations */

- (void)prepare;
- (void)finish;

/* databases */

- (PPDatabase *)openDatabaseNamed:(NSString *)_dbName;
- (BOOL)deleteDatabaseNamed:(NSString *)_dbName;
- (void)closeDatabase:(PPDatabase *)_db;

- (PPDatabase *)createDatabaseNamed:(NSString *)_dbName
  creator:(unsigned long)_creator type:(unsigned long)_type
  flags:(int)_flags version:(int)_version
  onCard:(int)_cardno;

- (NSArray *)databasesCreatedBy:(NSString *)_creator;
- (NSArray *)databasesWithType:(NSString *)_type;
- (NSArray *)databasesMatchingQualifier:(EOQualifier *)_qualifier;

/* logging to Pilot */

- (void)syncLogWithString:(NSString *)_str;
- (void)syncLogWithFormat:(NSString *)_fmt, ...;

/* database block IO */

- (NSData *)readAppBlockOfDatabase:(PPDatabase *)_db;
- (BOOL)writeAppBlock:(NSData *)_block ofDatabase:(PPDatabase *)_db;
- (NSData *)readSortBlockOfDatabase:(PPDatabase *)_db;
- (BOOL)writeSortBlock:(NSData *)_block ofDatabase:(PPDatabase *)_db;

/* record databases */

- (NSArray *)readRecordIDsOfDatabase:(PPRecordDatabase *)_db;

- (EOGlobalID *)insertRecord:(NSData *)_packedRecord
  intoDatabase:(PPRecordDatabase *)_db
  isPrivate:(BOOL)_flag
  categoryID:(unsigned char)_categoryID;

- (BOOL)updateRecord:(NSData *)_packedRecord
  inDatabase:(PPRecordDatabase *)_db
  flags:(int)_flags
  categoryID:(unsigned char)_categoryID
  oid:(EOGlobalID *)_oid;

- (BOOL)deleteRecord:(EOGlobalID *)_oid
  inDatabase:(PPRecordDatabase *)_db;

- (NSData *)fetchRecordByID:(EOGlobalID *)_oid
  fromDatabase:(PPRecordDatabase *)_db
  attributes:(int *)_attrs
  category:(int *)_category;

- (NSArray *)objectsWithFetchSpecification:(EOFetchSpecification *)_fspec;

/* resource databases */

/* description */

- (id)propertyList;

@end

@interface PPSyncContext(PrivateMethods)

- (id)initWithDescriptor:(int)_sd;

@end

#endif /* __PPSync_PPSyncContext_H__ */
