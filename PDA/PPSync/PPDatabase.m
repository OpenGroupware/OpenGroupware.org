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

#include "PPDatabase.h"
#include "PPSyncContext.h"
#import <Foundation/Foundation.h>

#define id _pid
#include <pi-dlp.h>
#undef id

#include <netinet/in.h>

@implementation PPDatabase

+ (id)databaseWithName:(NSString *)_dbName
  flags:(unsigned int)_flags miscFlags:(unsigned int)_miscFlags
  type:(unsigned long)_type creator:(unsigned long)_creator
  version:(unsigned int)_version modificationCount:(unsigned long)_modnum
  creationDate:(NSDate *)_cdate modificationDate:(NSDate *)_mdate
  backupDate:(NSDate *)_bdate
  card:(id)_card
  syncContext:(PPSyncContext *)_sc
{
  PPDatabase *db;
  
  db = [[self alloc] init];
  db->sc   = _sc;
  db->card = _card;
  
  db->name               = [_dbName copy];

  /* flags */
  db->isReadOnly         = _flags & dlpDBFlagReadOnly ? YES : NO;
  db->isResourceDatabase = _flags & dlpDBFlagResource ? YES : NO;
  db->isAppInfoModifiedSinceLastBackup = _flags & dlpDBFlagAppInfoDirty ?YES:NO;
  db->shouldBackup       = _flags & dlpDBFlagBackup ? YES : NO;

  /* miscflags */
  db->excludeFromSync    = _miscFlags & dlpDBMiscFlagExcludeFromSync ? YES : NO;

  db->creator            = _creator;
  db->type               = _type;
  db->version            = _version;
  db->modificationCount  = _modnum;

  db->creationDate       = RETAIN(_cdate);
  db->modificationDate   = RETAIN(_mdate);
  db->backupDate         = RETAIN(_bdate);

  return AUTORELEASE(db);
}

- (void)dealloc {
  RELEASE(self->name);
  RELEASE(self->creationDate);
  RELEASE(self->modificationDate);
  RELEASE(self->backupDate);
  [super dealloc];
}

/* notifications */

- (int)decodeAppBlock:(NSData *)_block {
  return 0;
}
- (int)decodeSortBlock:(NSData *)_block {
  return 0;
}

- (void)syncContext:(PPSyncContext *)_ctx openedDatabaseWithHandle:(int)_dh {
  NSData *block;
  
  self->dbHandle = _dh;
#if DEBUG && 0
  NSLog(@"database %@ opened ..", self->name);
#endif

  block = [_ctx readAppBlockOfDatabase:self];
  [self decodeAppBlock:block];

#if 0
  block = [_ctx readSortBlockOfDatabase:self];
  [self decodeSortBlock:block];
#endif
}
- (void)syncContextClosedDatabase:(PPSyncContext *)_ctx {
  self->dbHandle = 0;
#if DEBUG && 0
  NSLog(@"database %@ closed.", self->name);
#endif
}

/* accessors */

- (void)_setDatabaseHandle:(int)_handle {
  self->dbHandle = _handle;
}
- (int)_databaseHandle {
  return self->dbHandle;
}

- (PPSyncContext *)syncContext {
  return self->sc;
}

- (int)cardNumber {
  return [[self->card objectForKey:@"number"] intValue];
}
- (BOOL)isReadOnly {
  return self->isReadOnly;
}

- (unsigned long)creator {
  return self->creator;
}
- (unsigned long)type {
  return self->type;
}
- (NSString *)creatorString {
  unsigned long c;
  c = ntohl(self->creator);
  return [NSString stringWithCString:(char *)&c length:4];
}
- (NSString *)typeString {
  unsigned long c;
  c = ntohl(self->type);
  return [NSString stringWithCString:(char *)&c length:4];
}

- (NSString *)databaseName {
  return self->name;
}

/* operations */

- (void)close {
  [self->sc closeDatabase:self];
}

/* description */

- (NSString *)propertyDescription {
  return @"";
}

- (NSString *)description {
  NSMutableString *s;
  unsigned long ul;
  char buf[5];

  s = [NSMutableString stringWithCapacity:128];
  
  [s appendFormat:@"<%@[0x%08X]: name=%@", 
       NSStringFromClass([self class]), self,
       self->name];

  ul = ntohl(self->creator);
  strncpy(buf, (char *)&ul, 4); buf[4] = '\0';
  [s appendFormat:@" creator=%s", buf];

  ul = ntohl(self->type);
  strncpy(buf, (char *)&ul, 4); buf[4] = '\0';
  [s appendFormat:@" type=%s", buf];

  [s appendString:[self propertyDescription]];

  if (self->isReadOnly)
    [s appendString:@" readOnly"];
  if (self->isResourceDatabase)
    [s appendString:@" resource"];
  if (self->dbHandle > 0)
    [s appendFormat:@" handle=%i", self->dbHandle];
  [s appendString:@">"];
  return s;
}

@end /* PPDatabase */

@implementation PPDatabase(ClassDesc2)

- (EOClassDescription *)classDescriptionNeededForEntityName:(NSString *)_name {
  return nil;
}

- (EOClassDescription *)classDescriptionNeededForClass:(Class)_class {
  return nil;
}

@end /* PPDatabase(ClassDesc2) */
