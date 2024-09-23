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

#include "PPSyncContext.h"
#include "PPResourceDatabase.h"
#include "PPRecordDatabase.h"
#include "PPGlobalID.h"
#include "PPClassDescription.h"
#include "common.h"

#include "PPTransaction.h"

#include "pi-version.h"

@interface PPSyncContext(PrivateMethods2)

- (Class)_classForDatabaseNamed:(NSString *)_name
  creator:(unsigned long)_creator type:(unsigned long)_type;

- (PPDatabase *)databaseNamed:(NSString *)_name;

@end

@implementation PPSyncContext

- (id)initWithDescriptor:(int)_sd {
  if (_sd < 0) {
    RELEASE(self); self = nil;
    [NSException raise:@"InvalidArgumentException"
                 format:@"got invalid descriptor %i !", _sd];
  }
  self->sd     = _sd;
  self->pisock = find_pi_socket(self->sd);
  self->fsd    = ((struct pi_socket *)self->pisock)->sd;

  self->databases = NSCreateMapTable(NSObjectMapKeyCallBacks,
                                     NSObjectMapValueCallBacks,
                                     128);

  self->openDatabases    = [[NSMutableArray alloc] initWithCapacity:4];
  self->deletedDatabases = [[NSMutableArray alloc] initWithCapacity:4];

  [[NSNotificationCenter defaultCenter]
                         addObserver:self
                         selector:@selector(classDescriptionNeededForClass:)
                         name:@"EOClassDescriptionNeededForClass"
                         object:nil];
  [[NSNotificationCenter defaultCenter]
                         addObserver:self
                         selector:@selector(classDescriptionNeededForEntityName:)
                         name:@"EOClassDescriptionNeededForEntityName"
                         object:nil];

  {
    int i;
    for (i = 0; i < PPSync_MAXCARDS; i++)
      self->lastDBInfoIndex[i] = 0;
  }
  
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [EOClassDescription invalidateClassDescriptionCache];
  
  RELEASE(self->pilotTimeZone);
  RELEASE(self->cachedEntities);
  RELEASE(self->openDatabases);
  RELEASE(self->deletedDatabases);
  NSFreeMapTable(self->databases);
  RELEASE(self->cards);
  RELEASE(self->successfulSyncDate);
  RELEASE(self->lastSyncDate);
  RELEASE(self->userName);
  RELEASE(self->password);
  RELEASE(self->syncHostName);
  RELEASE(self->syncAddress);
  RELEASE(self->syncSubnetMask);
  RELEASE(self->systemName);
  if (self->sd != -1)
    pi_close(self->sd);
  [super dealloc];
}

/* accessors */

- (int)fileDescriptor {
  return self->fsd;
}

- (void)setUserName:(NSString *)_name {
  if ([_name isEqualToString:self->userName])
    return;

  self->userInfoChanged = YES;
  ASSIGN(self->userName, _name);
}
- (NSString *)userName {
  return self->userName;
}

- (void)updateLastSyncDate {
  NSDate *lastSync = [NSDate date];
  self->userInfoChanged = YES;
  ASSIGN(self->lastSyncDate,lastSync);
}
- (void)updateSuccessfulSyncDate {
  NSDate *successfulSync = [NSDate date];
  self->userInfoChanged = YES;
  ASSIGN(self->successfulSyncDate,successfulSync);
  [self updateLastSyncDate];
}

- (NSString *)password {
  return self->password;
}

- (unsigned long)systemLocale {
  return self->systemLocale;
}
- (unsigned long)systemRomVersion {
  return self->systemRomVersion;
}
- (NSString *)systemName {
  return self->systemName;
}

- (void)setPilotTimeZone:(NSTimeZone *)_tz {
  NSLog(@"setting PilotTimeZone to %@", [_tz abbreviation]);
  ASSIGN(self->pilotTimeZone, _tz);
}
- (NSTimeZone *)pilotTimeZone {
  return self->pilotTimeZone ? self->pilotTimeZone : [NSTimeZone localTimeZone];
}

- (NSArray *)availablePPDatabases {
  static NSArray *available = nil;
  if (available == nil) {
    NGBundleManager *bm;
    id              one;

    bm  = [NGBundleManager defaultBundleManager];
    one = [bm providedResourcesOfType:@"PPDatabases"];

    available = [one copy];
  }
  return available;
}
- (Class)_ppDatabaseClassForPalmDb:(NSString *)_palmDb
                           creator:(NSString *)_creator
                              type:(NSString *)_type
{
  EOQualifier *q;
  id          resource;
  NSBundle    *bundle;

  q = [EOQualifier qualifierWithQualifierFormat:
                   @"creator=%@ AND type=%@ AND name=%@",
                   _creator, _type, _palmDb];
  resource = [[self availablePPDatabases] filteredArrayUsingQualifier:q];
  if (![resource count]) {
    q = [EOQualifier qualifierWithQualifierFormat:
                     @"creator=%@ AND type=%@",
                     _creator, _type];
    resource = [[self availablePPDatabases] filteredArrayUsingQualifier:q];
  }
  resource = [resource lastObject];

  if (resource == nil) return [PPRecordDatabase class];
  {
    NSString *rname = [resource valueForKey:@"name"];
    if (([rname length]) && (![rname isEqualToString:_palmDb]))
      // name is give, so must be the same
      return [PPRecordDatabase class];
  }
  bundle = [[NGBundleManager defaultBundleManager]
                             bundleProvidingResourceOfType:@"PPDatabases"
                             matchingQualifier:q];

  if (bundle == nil) {
    NSLog(@"%s: didn't find bundle for PPDatabases: %@",
          __PRETTY_FUNCTION__, resource);
    return [PPRecordDatabase class];
  }
  if (![bundle load]) {
    NSLog(@"%s: failed to load bundle %@", __PRETTY_FUNCTION__, bundle);
    return [PPRecordDatabase class];
  }
  resource = [resource valueForKey:@"class"];
  if ([resource length]) {
    //NSLog(@"%s found %@", __PRETTY_FUNCTION__, resource);
    return NSClassFromString(resource);
  }
  return [PPRecordDatabase class];
}

/* operations */

- (Class)_classForDatabaseNamed:(NSString *)_name
  creator:(unsigned long)_creator type:(unsigned long)_type
{
  if (_type == 'DATA') {
    switch (_creator) {
      case 'addr': return NSClassFromString(@"PPAddressDatabase");
      case 'todo': return NSClassFromString(@"PPToDoDatabase");
      case 'date': return NSClassFromString(@"PPDatebookDatabase");
      case 'memo': return NSClassFromString(@"PPMemoDatabase");
    }
  }
  {
#if 1
    NSString        *creator;
    NSString        *type;

    _creator = ntohl(_creator);
    _type    = ntohl(_type);
    creator  = [NSString stringWithCString:(char *)&_creator length:4];
    type     = [NSString stringWithCString:(char *)&_type length:4];

    //NSLog(@"%s: looking for database %@ (creator:%@ type:%@)",
    //      __PRETTY_FUNCTION__, _name, creator, type);

    return [self _ppDatabaseClassForPalmDb:_name creator:creator type:type];
#endif
  }

  
  return [PPRecordDatabase class];
}

- (Class)_classForDatabaseNamed:(NSString *)_name
  withInfo:(struct DBInfo *)_info
  onCard:(int)_cardno
{
  if (_info->flags & dlpDBFlagResource)
    return [PPResourceDatabase class];
  else {
    return [self _classForDatabaseNamed:_name
                 creator:_info->creator
                 type:_info->type];
  }
}

- (void)prepare {
  struct SysInfo     sysInfo;
  struct NetSyncInfo nsi;
  struct PilotUser   pu;
  id tmp;
  int i, len;
  
  if ((len = dlp_OpenConduit(self->sd)) < 0)
    NSLog(@"WARNING: %@ couldn't open conduit (error=%i) !", self, len);
  
  /* read common info */

  if ((len = dlp_ReadSysInfo(self->sd, &sysInfo)) <= 0)
    NSLog(@"WARNING: %@ couldn't read system info (error=%i) !", self, len);
  else {
    self->systemRomVersion = sysInfo.romVersion;
    self->systemLocale     = sysInfo.locale;
#if ((PILOT_LINK_VERSION == 0) && (PILOT_LINK_MAJOR >= 11) || (PILOT_LINK_VERSION > 0))
    if (sysInfo.prodIDLength > 0) {
      self->systemName = [[NSString alloc] initWithCString:sysInfo.prodID
                                           length:sysInfo.prodIDLength];
    }
#else
    if (sysInfo.nameLength > 0) {
      self->systemName = [[NSString alloc] initWithCString:sysInfo.name
                                           length:sysInfo.nameLength];
    }
#endif
  }

  if ((len = dlp_ReadUserInfo(self->sd, &pu)) <= 0)
    NSLog(@"WARNING: %@ couldn't read user info (error=%i) !", self, len);
  else {
    self->userID     = pu.userID;
    self->viewerID   = pu.viewerID;
    self->lastSyncPC = pu.lastSyncPC;

    self->successfulSyncDate =
      [[NSDate alloc] initWithTimeIntervalSince1970:pu.successfulSyncDate];
    self->lastSyncDate =
      [[NSDate alloc] initWithTimeIntervalSince1970:pu.lastSyncDate];

    if (strlen(pu.username) > 0)
      self->userName = [[NSString alloc] initWithCString:pu.username];
    if (pu.passwordLength > 0) {
      self->password =
        [[NSString alloc] initWithCString:pu.password length:pu.passwordLength];
    }
  }
  
  if ((len = dlp_ReadNetSyncInfo(self->sd, &nsi)) <= 0)
    NSLog(@"WARNING: %@ couldn't read netsync info (error=%i) !", self, len);
  else {
    self->lanSyncEnabled = nsi.lanSync ? YES : NO;
    self->syncHostName   = [[NSString alloc] initWithCString:nsi.hostName];
    self->syncAddress    = [[NSString alloc] initWithCString:nsi.hostAddress];
    self->syncSubnetMask = [[NSString alloc] initWithCString:nsi.hostSubnetMask];
  }
  
  /* determine available cards */

  tmp = [NSMutableArray arrayWithCapacity:4];
  for (i = 0; i < PPSync_MAXCARDS; i++) {
    struct CardInfo ci;

    len = dlp_ReadStorageInfo(self->sd, i /*cardnumber*/, &ci);
    if (len == -5)
      /* no card with specified number */
      break;
    else if (len <= 0) {
      [NSException raise:@"PalmReadException"
                   format:@"WARNING: %@ couldn't read info of card %i !",
                     self, i];
    }
    else {
      /* process card info */
      NSMutableDictionary *d;

      if (ci.card != i) {
        NSLog(@"WARNING: retrieved card number (%i) "
              @"does not match expected one (%i) !", ci.card, i);
      }

      d = [[NSMutableDictionary alloc] initWithCapacity:16];
      [d setObject:[NSNumber numberWithInt:ci.card]    forKey:@"number"];
      [d setObject:[NSNumber numberWithInt:ci.version] forKey:@"version"];
      [d setObject:[NSDate dateWithTimeIntervalSince1970:ci.creation]
         forKey:@"creationDate"];
      [d setObject:[NSNumber numberWithUnsignedLong:ci.romSize]
         forKey:@"sizeOfROM"];
      [d setObject:[NSNumber numberWithUnsignedLong:ci.ramSize]
         forKey:@"sizeOfRAM"];
      [d setObject:[NSNumber numberWithUnsignedLong:ci.ramFree]
         forKey:@"availableRAM"];

      if (strlen(ci.name) > 0)
        [d setObject:[NSString stringWithCString:ci.name] forKey:@"name"];

      if (strlen(ci.manufacturer) > 0) {
        [d setObject:[NSString stringWithCString:ci.manufacturer]
            forKey:@"manufacturer"];
      }
      
      /* what does 'more' ? */

      //NSLog(@"%s got card %@", __PRETTY_FUNCTION__, d);
      [tmp addObject:AUTORELEASE([d copy])];
      
      /* determine databases on card */

#if 0 // TODO: what is that, debugging code? move to own method?
      { int j;
        struct DBInfo dbinfo;
      /* mh [2003-02-19]:
       *
       * going thru all databases in -prepare() 
       * takes much time since a palm device can have hundreds of
       * databases
       * each dlp_ReadDBList takes about 0.2 sec
       * with 100 databases on one card this is already 20 seconds !!
       *
       * now[2003-02-19] databases are searched on demand,
       * (see -databaseNamed() )
       * which is in worsed case as slow as loading all databases
       * (if the wanted one is the last in list)
       *
       * getting an db-handle for a dbname is pretty easy and fast
       * (using dlp_OpenDB)
       * but it seems impossible to get a dbInfo out of a db-handle
       *
       * so this going thru of all databases is neccessary
       *
       */
      for (j = lastDBInfoIndex[i]; YES; j = dbinfo.index + 1) {
        Class      dbClass;
        NSString   *dbName;
        PPDatabase *db;

        {
          //NSDate *date = [NSDate date];
          //NSLog(@"%s dlp_ReadDBList", __PRETTY_FUNCTION__);
          len = dlp_ReadDBList(self->sd, i/*ci.card*/,
                               /*dlpDBListROM |*/ dlpDBListRAM,
                               j, &dbinfo);
          //NSLog(@"%s dlp_ReadDBList took %.4fs", __PRETTY_FUNCTION__,
          //      [[NSDate date] timeIntervalSinceDate:date]);
        }
        if (len <= 0)
          break;

        lastDBInfoIndex[i] = dbinfo.index + 1;
        
        dbName  = [NSString stringWithCString:dbinfo.name];
        NSLog(@"%s: found database %@", __PRETTY_FUNCTION__, dbName);
        
        dbClass = [self _classForDatabaseNamed:dbName
                        withInfo:&dbinfo
                        onCard:i/*ci.card*/];

        db = [dbClass databaseWithName:dbName
                      flags:dbinfo.flags miscFlags:dbinfo.miscFlags
                      type:dbinfo.type creator:dbinfo.creator
                      version:dbinfo.version modificationCount:dbinfo.modnum
                      creationDate:
                        [NSDate dateWithTimeIntervalSince1970:dbinfo.createDate]
                      modificationDate:
                        [NSDate dateWithTimeIntervalSince1970:dbinfo.modifyDate]
                      backupDate:
                        [NSDate dateWithTimeIntervalSince1970:dbinfo.backupDate]
                      card:[tmp objectAtIndex:i] syncContext:self];

        if (db) {
          NSMapInsert(self->databases, dbName, db);
        }
# if DEBUG
        else {
          NSLog(@"%s: failed to init db for class: %@",
                __PRETTY_FUNCTION__, NSStringFromClass(dbClass));
        }
# endif /* DEBUG */
      }
# if DEBUG
      NSLog(@"Palm: found %i databases for card %i",
            NSCountMapTable(self->databases),
            i);
# endif /* DEBUG */
      }
#endif /* 0 */
    }
  }
  self->cards = [tmp copy];
  tmp = nil;
}

- (void)finish {
  NSEnumerator *e;
  id  entry;
  int len;

  /* sync user info */
  if (self->userInfoChanged) {
    struct PilotUser pu;
    
    pu.userID             = self->userID;
    pu.viewerID           = self->viewerID;
    pu.lastSyncPC         = self->lastSyncPC;
    pu.successfulSyncDate = [self->successfulSyncDate timeIntervalSince1970];
    pu.lastSyncDate       = [self->lastSyncDate timeIntervalSince1970];
    [self->userName getCString:pu.username maxLength:sizeof(pu.username)];
    [self->password getCString:pu.password maxLength:sizeof(pu.password)];
    pu.passwordLength = [self->password cStringLength];

    if ((len = dlp_WriteUserInfo(self->sd, &pu)) < 0)
      NSLog(@"ERROR: %@ couldn't write modified user-info: %i", self, len);
  }
  
  /* close open databases */
  
  while ([self->openDatabases count] > 0)
    [self closeDatabase:[self->openDatabases lastObject]];
  
  /* process deleted databases */
  
  e = [self->deletedDatabases objectEnumerator];
  while ((entry = [e nextObject])) {
    PPDatabase *db;

    if ((db = NSMapGet(self->databases, entry))) {
      int card;

      card = [db cardNumber];
      
      if ((len = dlp_DeleteDB(self->sd, card, (char *)[entry cString])) < 0)
        NSLog(@"ERROR: %@ couldn't delete database '%@': %i", self, db, len);
    }
    else {
      NSLog(@"ERROR: %@ delete failed, di not find database named '%@' !",
            self, entry);
    }
  }
  [self->deletedDatabases removeAllObjects];
  
  /* end sync */
  
  if (self->shallResetSystemAfterSync) {
    if ((len = dlp_ResetSystem(self->sd)) < 0)
      NSLog(@"WARNING: %@ couldn't mark for reset (error=%i) !", self, len);
  }
  
  if ((len = dlp_EndOfSync(self->sd, 0)) < 0)
    NSLog(@"WARNING: %@ couldn't finish sync (error=%i) !", self, len);
  
  /* closing socket */
  
  if (self->sd != -1) {
    pi_close(self->sd);
    self->sd = -1;
  }
}

/* database block IO */

- (NSData *)readAppBlockOfDatabase:(PPDatabase *)_db {
  char buf[0xFFFF];
  int  len;
  
  len = dlp_ReadAppBlock(self->sd, [_db _databaseHandle], 0, buf, sizeof(buf));
  if (len < 0) {
    NSLog(@"ERROR: %@ could not read app block of db %@: %i", self, _db, len);
    return nil;
  }

  return [NSData dataWithBytes:buf length:len];
}
- (BOOL)writeAppBlock:(NSData *)_block ofDatabase:(PPDatabase *)_db {
  int len;
  
  if ((_db == nil) || (_block == nil))
    return NO;

  len = dlp_WriteAppBlock(self->sd, [_db _databaseHandle],
                          [_block bytes], [_block length]);
  if (len < 0) {
    NSLog(@"WARNING: %@ couldn't write app block of db %@: %i", self, _db, len);
    return NO;
  }
  else
    return YES;
}

- (NSData *)readSortBlockOfDatabase:(PPDatabase *)_db {
  char buf[0xFFFF];
  int  len;
  
  len = dlp_ReadSortBlock(self->sd, [_db _databaseHandle], 0, buf, sizeof(buf));
  if (len < 0) {
    NSLog(@"ERROR: %@ could not read app block of db %@: %i", self, _db, len);
    return nil;
  }
  
  return [NSData dataWithBytes:buf length:len];
}
- (BOOL)writeSortBlock:(NSData *)_block ofDatabase:(PPDatabase *)_db {
  int len;
  
  if ((_db == nil) || (_block == nil))
    return NO;

  len = dlp_WriteSortBlock(self->sd, [_db _databaseHandle],
                           [_block bytes], [_block length]);
  if (len < 0) {
    NSLog(@"WARNING: %@ couldn't write app block of db %@: %i", self, _db, len);
    return NO;
  }
  else
    return YES;
}


/* databases */

- (PPDatabase *)databaseNamed:(NSString *)_name {
  PPDatabase *db = nil;

  if ((db = NSMapGet(self->databases, _name))) {
    /* database is already known .. */
    return db;
  }
  else {
    BOOL          deepSearch = NO;
    int           i;
    int           dbh, len, j, card;
    struct DBInfo dbinfo;
    
    for (j = 0; j < [self->cards count]; j++) {
      len = dlp_OpenDB(self->sd,
                       j    /* cardno */,
                       0x80 /* mode */,
                       (char *)[_name cString] /* dbname */,
                       &dbh /* dbhandle */);
      if (len >= 0) break;
    }
    card = j;
    if (len < 0) {
      /* database does not exist */
      NSLog(@"WARNING[%s]: db %@ seems not to exist! deep search ...",
            __PRETTY_FUNCTION__, _name);
      deepSearch = YES;
    }
    dlp_CloseDB(self->sd, dbh);

    ///* scan databases on card */
    if (deepSearch) {
      // going thru the cards
      i = 0; card = [self->cards count];
    }
    else {
      // just one card
      i = card;
      card ++;
    }
    for (;i<card; i++) {
      for (j = lastDBInfoIndex[i]; YES; j = dbinfo.index + 1) {
        NSString *dbName;
        Class    dbClass;

        len = dlp_ReadDBList(self->sd, i /* card */,
                             /*dlpDBListROM |*/ dlpDBListRAM,
                             j, &dbinfo);
        if (len <= 0)
          break;
        
        lastDBInfoIndex[i] = dbinfo.index + 1;
      
        dbName = [NSString stringWithCString:dbinfo.name];
          
        dbClass = [self _classForDatabaseNamed:dbName
                        withInfo:&dbinfo
                        onCard:i];
      
        db = [dbClass databaseWithName:dbName
                      flags:dbinfo.flags miscFlags:dbinfo.miscFlags
                      type:dbinfo.type creator:dbinfo.creator
                      version:dbinfo.version modificationCount:dbinfo.modnum
                      creationDate:
                      [NSDate dateWithTimeIntervalSince1970:dbinfo.createDate]
                      modificationDate:
                      [NSDate dateWithTimeIntervalSince1970:dbinfo.modifyDate]
                      backupDate:
                      [NSDate dateWithTimeIntervalSince1970:dbinfo.backupDate]
                      card:0 syncContext:self];
        if (db)
          NSMapInsert(self->databases, dbName, db);

        if ([dbName isEqualToString:_name]) {
          if (deepSearch)
            NSLog(@"%s: .. found %@ in deep search",
                  __PRETTY_FUNCTION__, _name);
          return db;
        }
      }
    }
  }
  return nil;
}

- (PPDatabase *)openDatabaseNamed:(NSString *)_dbName {
  PPDatabase *db;
  int card, mode, dh;
  int len;
  
  if ((db = [self databaseNamed:_dbName]) == nil)
    /* no such database */
    return nil;
  
  if ([self->openDatabases containsObject:db])
    return db;
  
  [self->openDatabases makeObjectsPerformSelector:@selector(close)];
  
  card = [db cardNumber];
  mode = dlpOpenRead | dlpOpenExclusive | dlpOpenSecret;
  if (![db isReadOnly]) mode |= dlpOpenWrite;
  
  len = dlp_OpenDB(self->sd, card, mode, (char *)[_dbName cString], &dh);
  if (len < 0) {
    NSString *reason = @"failed";
    
    switch (len) {
      case dlpErrTooManyOpen:
        NSLog(@"WARNING: %@ tried to open too many databases ..", self);
        reason = @"too many open databases";
      case dlpErrSystem:
        reason = @"system error";
        break;
      case dlpErrMemory:
        reason = @"memory error";
        break;
      case dlpErrParam:
        reason = @"OpenDB parameter error";
        break;
      case dlpErrNotFound:
        reason = @"did not find database";
        break;
      case dlpErrNoneOpen:
        reason = @"none open";
        break;
      case dlpErrAlreadyOpen:
        reason = @"database is already open";
        break;
      case dlpErrExists:
        reason = @"database exists";
        break;
      case dlpErrOpen:
        reason = @"database is open";
        break;
      case dlpErrDeleted:
        reason = @"database is deleted";
        break;
      case dlpErrBusy:
        reason = @"database is busy";
        break;
      case dlpErrNotSupp:
        reason = @"unsupported feature";
        break;
      case dlpErrReadOnly:
        reason = @"database is read-only";
        break;
      case dlpErrSpace:
        reason = @"missing space";
        break;
      case dlpErrLimit:
        reason = @"encountered limit";
        break;
      case dlpErrSync:
        reason = @"sync error";
        break;
      case dlpErrWrapper:
        reason = @"wrapper error";
        break;
      case dlpErrArgument:
        reason = @"OpenDB argument error";
        break;
      case dlpErrSize:
        reason = @"size error";
        break;
    }
    [NSException raise:@"PalmOpenError"
                 format:
                   @"ERROR: %@ couldn't open database '%@' "
                   @"(card %i, mode=%p): %i %@",
                   self, db, card, mode, len, reason];
    return nil;
  }
  
  [self->openDatabases addObject:db];
  [db syncContext:self openedDatabaseWithHandle:dh];
  
  return db;
}

- (void)closeDatabase:(PPDatabase *)_db {
  int handle, len;

  if (_db == nil)
    return;
  
  if (![self->openDatabases containsObject:_db]) {
    /* database is not open */
    NSLog(@"database %@ not open (open=%@) !", _db, self->openDatabases);
    return;
  }
  
  handle = [_db _databaseHandle];
  
  if ((len = dlp_CloseDB(self->sd, handle)) >= 0) {
    [self->openDatabases removeObject:_db];
    [_db syncContextClosedDatabase:self];
  }
  else {
    [NSException raise:@"PalmConnectionError"
                 format:@"WARNING: couldn't close database %@", _db];
  }
}

- (PPDatabase *)createDatabaseNamed:(NSString *)_dbName
  creator:(unsigned long)_creator type:(unsigned long)_type
  flags:(int)_flags version:(int)_version
  onCard:(int)_cardno
{
  PPDatabase *db;
  int len;

  if ((db = NSMapGet(self->databases, _dbName))) {
    int card;

    card = [db cardNumber];
    
    /* database already exists */
    if ([self->deletedDatabases containsObject:_dbName]) {
      /*
        database was marked for deletion before, so we now need to delete it
        really and recreate it afterwards ..
      */
      if ((len = dlp_DeleteDB(self->sd, card, (char *)[_dbName cString])) < 0) {
        NSLog(@"ERROR: %@ couldn't delete database '%@': %i", self, db, len);
        return nil;
      }
      [self->deletedDatabases removeObject:_dbName];
      NSMapRemove(self->databases, _dbName);
    }
    else {
      NSLog(@"ERROR: %@ database already exists '%@': %i", self, db, len);
      return nil;
    }
  }

  /* database does not exist yet or was deleted */
  return nil;
}

- (BOOL)deleteDatabaseNamed:(NSString *)_dbName {
  PPDatabase *db;
  
  if (_dbName == nil)
    /* invalid name .. */
    return NO;
  
  if ((db = NSMapGet(self->databases, _dbName)) == NULL)
    /* no such database */
    return NO;
  
  if ([self->openDatabases containsObject:db])
    NSLog(@"WARNING: deleting open database '%@' !", _dbName);
  
  if (self->deletedDatabases == nil)
    self->deletedDatabases = [[NSMutableArray alloc] init];
  
  [self->deletedDatabases addObject:_dbName];
  
  return NO;
}

- (NSArray *)databasesMatchingQualifier:(EOQualifier *)_qualifier {
  NSMutableArray  *result;
  NSMapEnumerator e;
  NSString        *dbName;
  PPDatabase      *db;

  e = NSEnumerateMapTable(self->databases);
  result = nil;
  while (NSNextMapEnumeratorPair(&e, (void**)&dbName, (void**)&db)) {
    if ([(id<EOQualifierEvaluation>)_qualifier evaluateWithObject:db]) {
      if (result == nil) result = [NSMutableArray arrayWithCapacity:16];
      [result addObject:db];
    }
  }
  return AUTORELEASE([result copy]);
}

- (NSArray *)databasesCreatedBy:(NSString *)_creator {
  NSMutableArray  *result;
  NSMapEnumerator e;
  NSString        *dbName;
  PPDatabase      *db;

  e = NSEnumerateMapTable(self->databases);
  result = nil;
  while (NSNextMapEnumeratorPair(&e, (void**)&dbName, (void**)&db)) {
    if ([[db creatorString] isEqualToString:_creator]) {
      if (result == nil) result = [NSMutableArray arrayWithCapacity:16];
      [result addObject:db];
    }
  }
  return AUTORELEASE([result copy]);
}
- (NSArray *)databasesWithType:(NSString *)_type {
  NSMutableArray  *result;
  NSMapEnumerator e;
  NSString        *dbName;
  PPDatabase      *db;

  e = NSEnumerateMapTable(self->databases);
  result = nil;
  while (NSNextMapEnumeratorPair(&e, (void**)&dbName, (void**)&db)) {
    if ([[db typeString] isEqualToString:_type]) {
      if (result == nil) result = [NSMutableArray arrayWithCapacity:16];
      [result addObject:db];
    }
  }
  return AUTORELEASE([result copy]);
}

/* record databases */

- (NSArray *)readRecordIDsOfDatabase:(PPDatabase *)_db {
  int        len;
  int        count;
  int        offset = 0;
  recordid_t rid[10000]; /* unsigned long [] */
  NSMutableArray *ma = [NSMutableArray arrayWithCapacity:32];
  int        max;
  
  len = dlp_ReadOpenDBInfo(self->sd, [_db _databaseHandle], &max);
  if (len < 0) {
    [NSException raise:@"PalmDatabaseException"
                 format:@"Couldn't read number of records of "
                 @"database %@: %i", _db, len];
    return nil;
  }
  if (max == 0) return [NSArray array];

  while (YES) {
    len = dlp_ReadRecordIDList(self->sd, [_db _databaseHandle],
                               0      /* sort  */,
                               offset /* start */,
                               10000  /* max   */,
                               rid, &count);
    if (len < 0) {
      if (len == -5) { /* dlpErrNotFound */
        /* no *contents* in database */
        return [NSArray array];
      }
      
      [NSException raise:@"PalmDatabaseException"
                   format:@"Couldn't read record IDs of database %@: %i",
                   _db, len];
      return nil;
    }
    else if (count == 0)
      return [ma copy];
    else {
      id keys[count];
      int i;
      
      for (i = 0; i < count; i++) {
        keys[i] = [PPGlobalID ppGlobalIDForCreator:[_db creator]
                              type:[_db type]
                              databaseName:[_db databaseName]
                              uniqueID:rid[i]];
      }
      [ma addObjectsFromArray:[NSArray arrayWithObjects:keys count:count]];
      offset += count;
      if (offset == max) return [ma copy];
    }
  }
}

- (NSData *)fetchRecordByID:(EOGlobalID *)_oid
  fromDatabase:(PPRecordDatabase *)_db
  attributes:(int *)_attrs
  category:(int *)_category
{
  recordid_t rid;
  int len;
  int dummy, idx, size;
  char buffer[0xFFFF];

  if (_attrs    == NULL) _attrs    = &dummy;
  if (_category == NULL) _category = &dummy;
  
  //NSLog(@"fetching record %@", _oid);

  if (![self->openDatabases containsObject:_db]) {
    [self closeDatabase:[self->openDatabases lastObject]];
    [self openDatabaseNamed:[_db databaseName]];
  }
  
  rid = [(PPGlobalID *)_oid uniqueID];
  
  len = dlp_ReadRecordById(self->sd, [_db _databaseHandle], rid,
                           buffer, &idx, &size, _attrs, _category);
  if (len < 0) {
    NSLog(@"ERROR: %@ couldn't read record for id %@ from database %@: %i",
          self, _oid, _db, len);
    return nil;
  }

  return [NSData dataWithBytes:buffer length:len];
}

- (BOOL)updateRecord:(NSData *)_packedRecord
  inDatabase:(PPRecordDatabase *)_db
  flags:(int)_flags
  categoryID:(unsigned char)_category
  oid:(EOGlobalID *)_oid
{
  //NSData        *data;
  //int           category;
  unsigned long newId;
  int           len;
  int           dbh;
  void          *buffer;
  unsigned      bufLen;

  buffer = (void *)[_packedRecord bytes];
  bufLen = [_packedRecord length];
  dbh    = [_db _databaseHandle];
  
  //NSLog(@"writing record of length %i category %i", bufLen, _category);
  
  len = dlp_WriteRecord(self->sd, dbh, _flags,
                        [(PPGlobalID *)_oid uniqueID],
                        _category,
                        buffer, bufLen, &newId);
  if (len < 0) {
    if (len == -4) {
      NSLog(@"ERROR: %@ couldn't update record, invalid parameters: "
            @" flags=%04X uid=%d category=%i bufLen=%i",
            self, _flags, [(PPGlobalID *)_oid uniqueID], _category, bufLen);
    }
    else
      NSLog(@"ERROR: %@ couldn't update record (error=%i) !", self, len);
    return NO;
  }
  if (newId != [(PPGlobalID *)_oid uniqueID]) {
    NSLog(@"WARNING: new id %p is not equal to old id %p !",
          newId, [(PPGlobalID *)_oid uniqueID]);
  }
  return YES;
}

- (BOOL)deleteRecord:(EOGlobalID *)_oid
  inDatabase:(PPRecordDatabase *)_db
{
  int dbh;
  int len;

  dbh = [_db _databaseHandle];
  len = dlp_DeleteRecord(self->sd, dbh, 0 /* all ? */,
                         [(PPGlobalID *)_oid uniqueID]);
  if (len < 0) {
    NSLog(@"ERROR: %@ couldn't delete record %@ (error=%i) !", self, _oid, len);
    return NO;
  }
  return YES;
}

- (EOGlobalID *)insertRecord:(NSData *)_packedRecord
  intoDatabase:(PPRecordDatabase *)_db
  isPrivate:(BOOL)_flag
  categoryID:(unsigned char)_category
{
  //NSData        *data;
  //int           category;
  int           flags;
  unsigned long newId;
  int           len;
  int           dbh;
  void          *buffer;
  unsigned      bufLen;

  buffer = (void *)[_packedRecord bytes];
  bufLen = [_packedRecord length];
  dbh    = [_db _databaseHandle];
  flags  = _flag ? dlpRecAttrSecret : 0;
  
  //NSLog(@"writing record of length %i category %i", bufLen, _category);
  
  len = dlp_WriteRecord(self->sd, dbh, flags, 0 /* record-id */,
                        [_db indexOfCategoryWithID:_category],
                        buffer, bufLen, &newId);
  if (len < 0) {
    NSLog(@"WARNING: %@ couldn't insert record (error=%i) !", self, len);
    if (len == -4) {
      NSLog(@"category id is %i, idx is %i, name=%@",
            _category,
            [_db indexOfCategoryWithID:_category],
            [_db categoryForID:_category]);
    }
    return nil;
  }

  return [PPGlobalID ppGlobalIDForCreator:[_db creator]
                     type:[_db type]
                     databaseName:[_db databaseName]
                     uniqueID:newId];
}

- (NSArray *)objectsWithFetchSpecification:(EOFetchSpecification *)_fspec {
  PPRecordDatabase *db;
  EOQualifier *q;
  NSArray     *so;
  NSArray     *all;
  
  if ((db = (id)[self databaseNamed:[_fspec entityName]]) == nil)
    return nil;
  
  all = [db registeredObjects];
  
  if ((q = [_fspec qualifier]))
    all = [all filteredArrayUsingQualifier:q];
  
  if ((so = [_fspec sortOrderings]))
    all = [all sortedArrayUsingKeyOrderArray:so];
  
  return all;
}

/* logging to Pilot */

- (void)syncLogWithString:(NSString *)_str {
  int len;

  if ((len = dlp_AddSyncLogEntry(self->sd, (char *)[_str cString])) < 0)
    NSLog(@"WARNING: %@ could not add sync log: %@", self, _str);
}

- (void)syncLogWithFormat:(NSString *)_fmt, ... {
  va_list  va;
  NSString *s;
  
  va_start(va, _fmt);
  s = [NSString stringWithFormat:_fmt arguments:va];
  va_end(va);

  [self syncLogWithString:s];
}

/* description */

- (id)propertyList {
  NSMutableDictionary *d;
  d = [NSMutableDictionary dictionaryWithCapacity:128];

  [d setObject:[NSNumber numberWithUnsignedLong:self->systemRomVersion]
     forKey:@"systemRomVersion"];
  [d setObject:[NSNumber numberWithUnsignedLong:self->systemLocale]
     forKey:@"systemLocale"];
  if (self->systemName)
    [d setObject:self->systemName forKey:@"systemName"];

  /* netsync info */
  
  [d setObject:[NSNumber numberWithBool:self->lanSyncEnabled]
     forKey:@"lanSyncEnabled"];
  if (self->syncHostName)
    [d setObject:self->syncHostName forKey:@"syncHostName"];
  if (self->syncAddress)
    [d setObject:self->syncAddress forKey:@"syncAddress"];
  if (self->syncSubnetMask)
    [d setObject:self->syncSubnetMask forKey:@"syncSubnetMask"];

  /* user info */
  
  [d setObject:[NSNumber numberWithUnsignedLong:self->userID] forKey:@"userID"];
  [d setObject:[NSNumber numberWithUnsignedLong:self->viewerID]
     forKey:@"viewerID"];
  [d setObject:[NSNumber numberWithUnsignedLong:self->lastSyncPC]
     forKey:@"lastSyncPC"];

  if (self->successfulSyncDate)
    [d setObject:self->successfulSyncDate forKey:@"successfulSyncDate"];
  if (self->lastSyncDate)
    [d setObject:self->lastSyncDate forKey:@"lastSyncDate"];
  if (self->userName)
    [d setObject:self->userName forKey:@"userName"];

  [d setObject:[NSNumber numberWithBool:[self->password length] > 0 ? YES : NO]
     forKey:@"hasPassword"];

  /* card info */

  if (self->cards)
    [d setObject:self->cards forKey:@"cards"];

  return d;
}

- (NSString *)description {
  NSMutableString *s;

  s = [NSMutableString stringWithCapacity:128];
  [s appendFormat:@"<%@[%p]:", NSStringFromClass([self class]), self];
  [s appendFormat:@" user=%@", self->userName];
  if (self->lanSyncEnabled)
    [s appendString:@" lanSync"];
  [s appendString:@">"];
  return s;
}

@end /* PPSyncContext */

@implementation PPSyncContext(EOObjectStore)

/* open databases */

- (void)_ensureDatabaseIsOpen:(PPRecordDatabase *)_db {
  if ([self->openDatabases containsObject:_db])
    return;

  [self closeDatabase:[self->openDatabases lastObject]];
  [self openDatabaseNamed:[_db databaseName]];
}

/* initialization */

- (void)initializeObject:(id)_object
  withGlobalID:(EOGlobalID *)_oid
  ppTransaction:(PPTransaction *)_ec
{
}

/* faults */

- (id)faultForGlobalID:(EOGlobalID *)_oid ppTransaction:(PPTransaction *)_ec{
  //Class            dbClass;
  PPRecordDatabase *db;
  id               eo;
  
  if ((eo = [_ec objectForGlobalID:_oid]))
    return eo;
  
  if ((db = (PPRecordDatabase *)[self databaseNamed:[_oid entityName]]) == nil)
    NSLog(@"did not find database %@", [_oid entityName]);
  
  if ((eo = [db faultForGlobalID:_oid])) {
    [_ec recordObject:eo globalID:_oid];
    return eo;
  }
  
  return nil;
}

/* fetching */

- (void)_fetchDatabaseNamed:(NSString *)_db
  ppTransaction:(PPTransaction *)_ec
{
  PPRecordDatabase *db;
  
  if (self->cachedEntities == nil)
    self->cachedEntities = [[NSMutableSet alloc] init];
  
  if ((db = (PPRecordDatabase *)[self openDatabaseNamed:_db])) {
    NSEnumerator *oids;
    EOGlobalID   *oid;
    
    oids = [[self readRecordIDsOfDatabase:db] objectEnumerator];
    
    while ((oid = [oids nextObject])) {
      id fault;
      
      fault = [self faultForGlobalID:oid ppTransaction:_ec];
      //NSLog(@"got fault %@ for oid %@", fault, oid);
    }
    
    [self closeDatabase:db];

    [self->cachedEntities addObject:_db];
  }
  else
    NSLog(@"couldn't open database named %@", _db);
}

- (NSArray *)objectsWithFetchSpecification:(EOFetchSpecification *)_fspec
  ppTransaction:(PPTransaction *)_ec
{
  NSString    *entityName;
  EOQualifier *qualifier, *delQual;
  NSArray     *objects;

  delQual = [[EOKeyValueQualifier alloc]
                                  initWithKey:@"isDeleted"
                                  operatorSelector:EOQualifierOperatorEqual
                                  value:[NSNumber numberWithBool:NO]];
  AUTORELEASE(delQual);
  
  entityName = [_fspec entityName];
  qualifier  = [_fspec qualifier];
  
  if (![self->cachedEntities containsObject:entityName]) {
    /* need to retrieve objects from Pilot */
    [self _fetchDatabaseNamed:entityName ppTransaction:_ec];
  }
  
  objects =
    [(PPRecordDatabase *)[self databaseNamed:entityName] registeredObjects];

  if (qualifier) {
    qualifier =
      [[EOAndQualifier alloc] initWithQualifiers:qualifier, delQual, nil];
    AUTORELEASE(qualifier);
  }
  else
    qualifier = delQual;
  
  objects = [objects filteredArrayUsingQualifier:qualifier];
  
  return objects;
}

/* saving changes */

- (BOOL)_processChangesInDatabase:(PPRecordDatabase *)_db
  insertedObjects:(NSArray *)_inserted
  deletedObjects:(NSArray *)_deleted
  updatedObjects:(NSArray *)_updated
  ppTransaction:(PPTransaction *)_ec
{
  NSEnumerator *e;
  id eo;
#if 0 
  NSLog(@"process db-changes\n"
        @"  inserted: %@\n  deleted: %@\n  updated: %@\n in db %@",
        _inserted, _deleted, _updated, _db);
#endif
  [self _ensureDatabaseIsOpen:_db];
  
  /* perform inserts */
  if ((e = [_inserted objectEnumerator])) {
    NSMutableDictionary *keyMap;
    
    keyMap = [[NSMutableDictionary alloc] init];
    
    while ((eo = [e nextObject])) {
      EOGlobalID *old;
      
      old = [_ec globalIDForObject:eo];
      
      if (![_db insertRecord:eo]) {
        NSLog(@"FAILED to insert %@", eo);
        [NSException raise:@"PPInsertException"
                     format:@"Couldn't insert eo %@", eo];
      }
      else {
        EOGlobalID *new;
        
        new = [_db globalIDForObject:eo];
        [keyMap setObject:new forKey:old];
      }
    }
    
    [[NSNotificationCenter defaultCenter]
                           postNotificationName:@"EOGlobalIDChanged"
                           object:self
                           userInfo:keyMap];
    AUTORELEASE(keyMap);
  }
  
  /* perform updates */
  if ((e = [_updated objectEnumerator])) {
    while ((eo = [e nextObject])) {
      if (![_db storeRecord:eo])
        NSLog(@"FAILED to store %@", eo);
#if 0
      else
        NSLog(@"stored record %@", eo);
#endif
    }
  }
  
  /* perform deletes */
  if ((e = [_deleted objectEnumerator])) {
    while ((eo = [e nextObject])) {
      if (![_db deleteRecord:eo])
        NSLog(@"FAILED to delete record %@", eo);
    }
  }

  /* cleanup db */
  dlp_CleanUpDatabase(self->sd, [_db _databaseHandle]);
  
  /* done */
  return YES;
}

- (NSString *)_entityNameForRecord:(id)_rec {
  PPClassDescription *cd = nil;
  cd = [[PPClassDescription alloc] initWithClass:[_rec class]];
  AUTORELEASE(cd);
  return [cd entityName];
}

- (void)saveChangesInTransaction:(PPTransaction *)_ec {
  NSArray             *inserted, *updated, *deleted;
  NSMutableDictionary *entityToChange;
  NSEnumerator        *e;
  NSString            *entityName;
  id                  object;
  //NSException         *exc;

  /* store user-info changes */
  
  if (self->userInfoChanged) {
    struct PilotUser pu;
    int r;
    
    pu.userID             = self->userID;
    pu.viewerID           = self->viewerID;
    pu.lastSyncPC         = self->lastSyncPC;
    pu.successfulSyncDate = [self->successfulSyncDate timeIntervalSince1970];
    pu.lastSyncDate       = [self->lastSyncDate timeIntervalSince1970];
    
    [self->userName getCString:pu.username maxLength:128];
    [self->password getCString:pu.password maxLength:128];
    pu.passwordLength = [self->password cStringLength];
    
    r = dlp_WriteUserInfo(self->sd, &pu);
    if (r < 0) {
      NSLog(@"Could not write userinfo: %i", r);
    }
    self->userInfoChanged = NO;
  }
  
  /* retrieve changed records from transaction */
  
  inserted = [_ec insertedObjects];
  updated  = [_ec updatedObjects];
  deleted  = [_ec deletedObjects];
  
  /* group changes by database */

  entityToChange = [NSMutableDictionary dictionaryWithCapacity:16];
  
  e = [inserted objectEnumerator];
  while ((object = [e nextObject])) {
    NSMutableDictionary *idict;
    NSMutableArray      *ia;
    NSString *entityName;
    
    entityName = [object entityName];
    if (entityName == nil)
      entityName = [self _entityNameForRecord:object];
    
    if ((idict = [entityToChange objectForKey:entityName]) == nil) {
      idict = [[NSMutableDictionary alloc] initWithCapacity:4];
      [idict setObject:[NSMutableArray array] forKey:@"inserted"];
      [entityToChange setObject:idict forKey:entityName];
      RELEASE(idict);
    }
    ia = [idict objectForKey:@"inserted"];
    [ia addObject:object];
  }
  
  e = [deleted objectEnumerator];
  while ((object = [e nextObject])) {
    NSMutableDictionary *idict;
    NSMutableArray      *ia;
    NSString *entityName;
    
    entityName = [object entityName];
    if (entityName == nil)
      entityName = [self _entityNameForRecord:object];
    
    if ((idict = [entityToChange objectForKey:entityName]) == nil) {
      idict = [[NSMutableDictionary alloc] initWithCapacity:4];
      [idict setObject:[NSMutableArray array] forKey:@"deleted"];
      [entityToChange setObject:idict forKey:entityName];
      RELEASE(idict);
    }
    ia = [idict objectForKey:@"deleted"];
    [ia addObject:object];
  }
  
  e = [updated objectEnumerator];
  while ((object = [e nextObject])) {
    NSMutableDictionary *idict;
    NSMutableArray      *ia;
    NSString            *entityName;
    
    entityName = [object entityName];
    if (entityName == nil)
      entityName = [self _entityNameForRecord:object];
    
    if ((idict = [entityToChange objectForKey:entityName]) == nil) {
      idict = [[NSMutableDictionary alloc] initWithCapacity:4];
      [idict setObject:[NSMutableArray array] forKey:@"updated"];
      [entityToChange setObject:idict forKey:entityName];
      RELEASE(idict);
    }
    ia = [idict objectForKey:@"updated"];
    [ia addObject:object];
  }

  /* ensure that all new objects are valid */
  
  e = [entityToChange keyEnumerator];
  while ((entityName = [e nextObject])) {
    PPRecordDatabase *db;
    NSArray          *a;
    NSDictionary     *cinfo;
    // int dbh;
    
    db = (PPRecordDatabase *)[self databaseNamed:entityName];
    
    if (db == nil) {
      /* entity does not exist in Palm, create one if possible */
      PPClassDescription *cd;
      int len, dbh;
      
      cd = (id)[PPClassDescription classDescriptionForEntityName:entityName];
      
      if ([cd creator] == 0) {
        NSLog(@"cannot save changes to database %@", entityName);
        NSLog(@"class description: %@", cd);
        continue;
      }

      /* close open databases */
      
      while ([self->openDatabases count] > 0)
        [self closeDatabase:[self->openDatabases lastObject]];
      
      len = dlp_CreateDB(self->sd /* connection */,
                         [cd creator],
                         [cd type],
                         0 /* cardno */,
                         0 /* flags */,
                         0 /* version */,
                         [entityName cString] /* name */,
                         &dbh /* dbhandle */);
      if (len < 0) {
        NSLog(@"Could not create database %@ (card %i): %i",
              entityName, 0, len);
        NSLog(@"cannot save changes to database %@", entityName);
        NSLog(@"class description: %@", cd);
        continue;
      }
      NSLog(@"Created database %@ on Palm.", entityName);
      dlp_CloseDB(self->sd, dbh);

      if ((db = (id)[self databaseNamed:entityName]) == nil) {
        NSLog(@"couldn't find newly created database %@", entityName);
        NSLog(@"cannot save changes to database %@", entityName);
        NSLog(@"class description: %@", cd);
        continue;
      }
    }

    /* perform validity check on inserted objects */
    
    cinfo = [entityToChange objectForKey:entityName];
    a = [cinfo objectForKey:@"inserted"];
    if ([a count] > 0) {
      NSEnumerator *e = [a objectEnumerator];
      id o;
      NSMutableArray *excs = nil;

      while ((o = [e nextObject])) {
        NSException *exc;
        
        [o setDatabase:db];
        if ((exc = [o validateForInsert])) {
          if (excs == nil) excs = [NSMutableArray array];
          [excs addObject:exc];
        }
      }
      if ([excs count] == 1)
        [[excs objectAtIndex:0] raise];
      else if ([a count] > 1) {
        NSException *e;
        
        e = [NSException aggregateExceptionWithExceptions:excs];
        [e raise];
      }
    }
  }
  
  /* perform changes */
  
  e = [entityToChange keyEnumerator];
  while ((entityName = [e nextObject])) {
    PPRecordDatabase *db;
    //int dbh;
    NSDictionary *cinfo;
    
    db = (PPRecordDatabase *)[self databaseNamed:entityName];
    if (db == nil) continue;

    cinfo = [entityToChange objectForKey:entityName];
    
    [self _processChangesInDatabase:db
          insertedObjects:[cinfo objectForKey:@"inserted"]
          deletedObjects:[cinfo objectForKey:@"deleted"]
          updatedObjects:[cinfo objectForKey:@"updated"]
          ppTransaction:_ec];
  }
  
  //NSLog(@"processed changes %@ ..", entityToChange);
}

/* notifications */

- (void)classDescriptionNeededForEntityName:(NSNotification *)_notification {
  NSString *entityName;

  entityName = [_notification object];
  //NSLog(@"asked for class description of entity %@", entityName);
}
- (void)classDescriptionNeededForClass:(NSNotification *)_notification {
  Class              c;
  NSMapEnumerator    e;
  NSString           *dbName;
  PPDatabase         *db;
  EOClassDescription *cd;
  
  c = [_notification object];
  
  e = NSEnumerateMapTable(self->databases);
  while (NSNextMapEnumeratorPair(&e, (void*)&dbName, (void*)&db)) {
    if ((cd = [db classDescriptionNeededForClass:c]))
      break;
  }
  if (cd) {
    [EOClassDescription registerClassDescription:cd forClass:c];
    //NSLog(@"got class description %@ for class %@", cd, c);
  }
  else {
    NSLog(@"got no class description for class %@", c);
  }
}

@end /* PPSyncContext(EOObjectStore) */

NSString *PPStringFromCreator(unsigned long _creator) {
  unsigned long cl;
  cl = ntohl(_creator);
  return [NSString stringWithCString:(void *)&cl length:4];
}
NSString *PPStringFromType(unsigned long _type) {
  unsigned long cl;
  cl = ntohl(_type);
  return [NSString stringWithCString:(void *)&cl length:4];
}

unsigned long PPCreatorFromString(NSString *_creator) {
  unsigned long cl;

  [_creator getCString:(void*)&cl maxLength:4];
  return htonl(cl);
}
unsigned long PPTypeFromString(NSString *_type) {
  unsigned long cl;

  [_type getCString:(void*)&cl maxLength:4];
  return htonl(cl);
}
