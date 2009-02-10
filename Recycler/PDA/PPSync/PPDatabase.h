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

#ifndef __PPSync_PPDatabase_H__
#define __PPSync_PPDatabase_H__

#import <Foundation/NSObject.h>

@class NSString, NSDate, NSNotification;
@class EOClassDescription;
@class PPSyncContext;

@interface PPDatabase : NSObject
{
  PPSyncContext *sc;      /* non-retained */
  id            card;     /* card the db is located on */
  int           dbHandle; /* open-handle of db */

  /* database info */
  NSString      *name;
  BOOL          isReadOnly;                       /* flags */
  BOOL          isResourceDatabase;               /* flags */
  BOOL          isAppInfoModifiedSinceLastBackup; /* flags */
  BOOL          shouldBackup;                     /* flags */
  BOOL          excludeFromSync;                  /* misc-flags */
  unsigned long creator;
  unsigned long type;
  unsigned int  version;
  unsigned long modificationCount;
  NSDate        *creationDate;
  NSDate        *modificationDate;
  NSDate        *backupDate;
}

/* accessors */

- (int)cardNumber;
- (BOOL)isReadOnly;
- (unsigned long)creator;
- (unsigned long)type;
- (NSString *)creatorString;
- (NSString *)typeString;
- (NSString *)databaseName;
- (PPSyncContext *)syncContext;

/* operations */

- (void)close;

/* description */

- (NSString *)propertyDescription;

@end

@interface PPDatabase(PrivateMethods)

+ (id)databaseWithName:(NSString *)_dbName
  flags:(unsigned int)_flags miscFlags:(unsigned int)_miscFlags
  type:(unsigned long)_type creator:(unsigned long)_creator
  version:(unsigned int)_version modificationCount:(unsigned long)_modnum
  creationDate:(NSDate *)_cdate modificationDate:(NSDate *)_mdate
  backupDate:(NSDate *)_bdate
  card:(id)_card
  syncContext:(PPSyncContext *)_sc;

- (id)initWithSyncContext:(PPSyncContext *)_sc;

- (void)syncContext:(PPSyncContext *)_ctx openedDatabaseWithHandle:(int)_handle;
- (void)syncContextClosedDatabase:(PPSyncContext *)_ctx;
- (int)_databaseHandle;

@end

@interface PPDatabase(ClassDesc2)
- (EOClassDescription *)classDescriptionNeededForEntityName:(NSString *)_name;
- (EOClassDescription *)classDescriptionNeededForClass:(Class)_class;
@end

#endif /* __PPSync_PPDatabase_H__ */
