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

#include <OGoPalm/SkyPalmSyncMachine.h>
#include <OGoPalm/SkyPalmEntryDataSource.h>
#include <OGoPalm/SkyPalmCategoryDataSource.h>
#include <OGoPalm/SkyPalmPreSync.h>
#include <OGoNHSSync/OGoNHSDeviceDataSource.h>
#include "common.h"

@interface SkyPalmSyncMachine(PrivatMethods)
- (void)checkForTimeout;
- (void)_resetLastAction;
@end

@implementation SkyPalmSyncMachine

- (id)init {
  if ((self = [super init])) {
    self->syncMode            = SYNC_MODE_SKY_OVER_PALM;
    self->onDeleteInSkyrix    = ON_DELETE_IN_SKYRIX_REALYDELETE_IN_SKYRIX;
    self->categorySyncMode    = SYNC_CATEGORY_FROM_PALM;
    self->timeoutCheckSeconds = -1;
    
    self->skyIdsOfDeletedPalmRecords =
      [[NSMutableArray alloc] initWithCapacity:8];
  }
  return self;
}

- (void)dealloc {
  [self->palmDS        release];
  [self->skyrixDS      release];
  [self->lastAction    release];
  [self->errorMessages release];
  [self->logLabel      release];
  [self->skyIdsOfDeletedPalmRecords release];
  [super dealloc];
}

/* logging */

- (void)setLogLabel:(NSString *)_label {
  ASSIGNCOPY(self->logLabel, _label);
}

- (void)logInFunction:(char *)_func
  message:(NSString *)_log, ...
{
  va_list va;
  NSString *s;
  va_start(va, _log);
  s = [[NSString alloc] initWithFormat:_log arguments:va];
  va_end(va);

  if (self->logLabel == nil)
    NSLog(@"%s%@", _func, s);
  else
    NSLog(@"[%@]%@", self->logLabel, s);
  [s release];
}

/* accessors */

- (void)setPalmDataSource:(SkyPalmDocumentDataSource *)_palmDS {
  ASSIGN(self->palmDS,_palmDS);
}
- (SkyPalmDocumentDataSource *)palmDataSource {
  return self->palmDS;
}

- (void)setSkyrixDataSource:(SkyPalmEntryDataSource *)_skyDS {
  ASSIGN(self->skyrixDS,_skyDS);
}
- (SkyPalmEntryDataSource *)skyrixDataSource {
  return self->skyrixDS;
}

- (void)setSyncMode:(int)_mode {
  self->syncMode = _mode;
}
- (int)syncMode {
  return self->syncMode;
}

- (void)setCategorySyncMode:(int)_mode {
  self->categorySyncMode = _mode;
}
- (int)categorySyncMode {
  return self->categorySyncMode;
}

- (void)setSyncWithSkyrixRecordBefore:(BOOL)_flag {
#if DEBUG
  if (_flag)
    [self logInFunction:__PRETTY_FUNCTION__
          message:@" presync enabled"];
  else
    [self logInFunction:__PRETTY_FUNCTION__
          message:@" presync disabled"];
#endif
  self->syncWithSkyrixRecordBefore = _flag;
}
- (BOOL)syncWithSkyrixRecordBefore {
  return self->syncWithSkyrixRecordBefore;
}

#if 0
- (void)setSyncWithSkyrixRecordAfter:(BOOL)_flag {
#if DEBUG
  if (_flag)
    [self logInFunction:__PRETTY_FUNCTION__
          message:@" sync with skyrix after palm-sync"];
  else
    [self logInFunction:__PRETTY_FUNCTION__
          message:@" no sync with skyrix after palm-sync"];
#endif
  self->syncWithSkyrixRecordAfter = _flag;
}
- (BOOL)syncWithSkyrixRecordAfter {
  return self->syncWithSkyrixRecordAfter;
}
#endif

- (void)setErrorMessages:(NSArray *)_mesgs {
  ASSIGN(self->errorMessages,_mesgs);
}
- (NSArray *)errorMessages {
  return (self->errorMessages != nil)
    ? self->errorMessages
    : [NSArray array];
}
- (void)_appendErrorMessage:(NSString *)_msg {
  [self setErrorMessages:[[self errorMessages] arrayByAddingObject:_msg]];
}

- (NSDictionary *)_recordsMappedByPalmId:(NSArray *)_recs {
  NSMutableDictionary *dict   = nil;
  NSEnumerator        *e      = [_recs objectEnumerator];
  id                  one     = nil;
  id                  palmId  = nil;

  dict = [NSMutableDictionary dictionaryWithCapacity:16];

  while ((one = [e nextObject])) {
    palmId = [NSNumber numberWithInt:[one palmId]];
    if ((palmId != nil) && ([palmId intValue] > 0))
      [dict takeValue:one forKey:palmId];
    else {
      NSArray *newRecs = [dict valueForKey:@"new"];
      newRecs = (newRecs == nil)
        ? [NSArray arrayWithObject:one]
        : [newRecs arrayByAddingObject:one];
      [dict takeValue:newRecs forKey:@"new"];
    }
  }
  return dict;
}

#if 0
/* this is the old presync/postsync
   new presync functionality is in SkyPalmPreSync
*/
- (void)_handlePreSyncOnSkyrixRecord:(SkyPalmDocument *)_rec {
  if (!self->syncWithSkyrixRecordBefore)
    return;
  
  if (([_rec hasSkyrixRecord]) && (![_rec isDeleted]))
    [_rec syncWithSkyrixRecord];
}
- (void)_handlePreSyncOnSkyrixRecords:(NSArray *)_recs {
  NSEnumerator *e;
  id           one;
  
  e  = [_recs objectEnumerator];
  while ((one = [e nextObject])) {
    [self _handlePreSyncOnSkyrixRecord:one];
    [self checkForTimeout];
  }
}
- (void)_handlePostSyncOnSkyrixRecord:(SkyPalmDocument *)_rec {
  if (!self->syncWithSkyrixRecordAfter)
    return;
  if (![_rec hasSkyrixRecord])
    return;

  [_rec syncWithSkyrixRecord];
}
#endif

- (NSDictionary *)_comparePalmRecords:(NSArray *)_palmRecs
  withSkyRecords:(NSArray *)_skyRecs
{
  // TODO: split up this huge method!
  NSMutableArray *changedInPalm     = nil;
  NSMutableArray *newInPalm         = nil;
  NSMutableArray *untouchedInPalm   = nil;
  NSMutableArray *deletedInPalm     = nil;

  NSMutableArray *changedInSkyrix   = nil;
  NSMutableArray *newInSkyrix       = nil;
  NSMutableArray *untouchedInSkyrix = nil;
  NSMutableArray *deletedInSkyrix   = nil;

  NSMutableArray *changedInBoth     = nil;
  
  NSDictionary   *skyRecordMapping  = nil;
  NSDictionary   *palmRecordMapping = nil;

  NSEnumerator   *e                 = nil;
  id             one                = nil;
  id             tmp                = nil;
  id             palmId             = nil;

  // settings vars
  changedInPalm   = [NSMutableArray array];
  newInPalm       = [NSMutableArray array];
  untouchedInPalm = [NSMutableArray array];
  deletedInPalm   = [NSMutableArray array];
  
  changedInSkyrix   = [NSMutableArray array];
  newInSkyrix       = nil;
  untouchedInSkyrix = [NSMutableArray array];
  deletedInSkyrix   = [NSMutableArray array];

  changedInBoth     = [NSMutableArray array];

  skyRecordMapping  = [self _recordsMappedByPalmId:_skyRecs];
  palmRecordMapping = [self _recordsMappedByPalmId:_palmRecs];

  // new skyrix records
  newInSkyrix      = [[skyRecordMapping valueForKey:@"new"] mutableCopy];
  AUTORELEASE(newInSkyrix);
  if (newInSkyrix == nil)
    newInSkyrix = [NSMutableArray array];

  // palm recs without palm Id
  if ((tmp = [palmRecordMapping valueForKey:@"new"]) != nil) {
    [self _appendErrorMessage:
          [NSString stringWithFormat:
                    @"WARNING!! Palm-Records without palmId: %@",
                    tmp]];
  }

  // checking palmRecs
  e = [_palmRecs objectEnumerator];
  while ((one = [e nextObject])) {
    palmId = [NSNumber numberWithInt:[one palmId]];
    if ((palmId == nil) || ([palmId intValue] < 1)) {
      [self _appendErrorMessage:
            [NSString stringWithFormat:
                      @"WARNING!! Palm-Record without palmId: %@ | %@",
                      one, (palmId == nil) ? @"<nil>" : palmId]];
      continue;
    }

    if ([one isDeleted]) {
      // deleted flag set --> palm-rec marked as deleted
      [deletedInPalm addObject:one];
      continue;
    }
    
    if ((tmp = [skyRecordMapping valueForKey:palmId]) == nil) {
      // no mapped sky record
      [newInPalm addObject:one];
      continue;
    }
    {
      // got palm and sky record
      NSString *hash;

      hash = [one generateMD5Hash];
      if (![hash isEqualToString:[tmp md5Hash]]) {
        // palm record modified
        [changedInPalm addObject:one];
        continue;
      }
    }

    // bound to skyrix record but not changed
    [untouchedInPalm addObject:tmp];
    continue;
  }

  // checking skyrixRecords
  e = [[skyRecordMapping allKeys] objectEnumerator];
  while ((palmId = [e nextObject])) {
    if ([palmId isKindOfClass:[NSString class]]) {
      // "new" key
      continue;
    }
    one = [skyRecordMapping  valueForKey:palmId];
    tmp = [palmRecordMapping valueForKey:palmId];

    if ([one isDeleted]) {
      // skyrix record is deleted
      [deletedInSkyrix addObject:one];
      continue;
    }

    if ((tmp == nil) && ([one isNew])) {
      // palmId set and new ???
      // in fact no mapped palmRecord found
      [newInSkyrix addObject:one];
      continue;
    }
    if ([one isNew]) {
      [self _appendErrorMessage:
            [NSString stringWithFormat:
                      @"WARNING!! Skyrix-Record is new and palmId is set: %@",
                      one]];
      continue;
    }

    if ([one isModified]) {
      // skyrix record is modified
      [changedInSkyrix addObject:one];
      continue;
    }

    // unchanged in skyrix
    [untouchedInSkyrix addObject:one];
    continue;
  }

  // checking both
  {
    id cp  = [changedInPalm copy];
    
    e   = [cp objectEnumerator];
    
    while ((one = [e nextObject])) {
      palmId = [NSNumber numberWithInt:[one palmId]];
      tmp    = [skyRecordMapping valueForKey:palmId];

      if ([changedInSkyrix containsObject:tmp]) {
        // changed in both
        [changedInBoth addObject:
                       [NSDictionary dictionaryWithObjectsAndKeys:
                                     one, @"palmRecord",
                                     tmp, @"skyrixRecord",
                                     nil]];
        [changedInSkyrix removeObject:tmp];
        [changedInPalm   removeObject:one];
        continue;
      }

      if ([deletedInSkyrix containsObject:tmp]) {
        // changed in palm and deleted in skyrix --> overwrite
        [deletedInSkyrix removeObject:tmp];
        continue;
      }
    }
    [cp release];
    
    cp = [changedInSkyrix copy];
    e = [cp objectEnumerator];
    
    while ((one = [e nextObject])) {
      palmId = [NSNumber numberWithInt:[one palmId]];
      tmp    = [palmRecordMapping valueForKey:palmId];

      if ([deletedInPalm containsObject:tmp]) {
        // changed in skyrix and deleted in palm --> overwrite
        [deletedInPalm removeObject:tmp];
      }
    }
    [cp release];
  }

  // look for deleted in both
  e = [deletedInPalm objectEnumerator];
  while ((one = [e nextObject])) {
    palmId = [NSNumber numberWithInt:[one palmId]];
    tmp    = [skyRecordMapping valueForKey:palmId];

    if ([deletedInSkyrix containsObject:tmp])
      [deletedInSkyrix removeObject:tmp];
  }

  tmp = [NSDictionary dictionaryWithObjectsAndKeys:
                      changedInPalm,   @"changedInPalm",
                      newInPalm,       @"newInPalm",
                      untouchedInPalm, @"untouchedInPalm",
                      deletedInPalm,   @"deletedInPalm",

                      changedInSkyrix,   @"changedInOGo",
                      newInSkyrix,       @"newInOGo",
                      untouchedInSkyrix, @"untouchedInOGo",
                      deletedInSkyrix,   @"deletedInOGo",

                      changedInBoth, @"changedInBoth",
                      nil];

  return tmp;
}

- (void)_handleNewInPalm:(NSArray *)_newInPalm {
  NSEnumerator *e;
  id           one;
  
  e = [_newInPalm objectEnumerator];
  while ((one = [e nextObject])) {
    NSAutoreleasePool *pool;
    SkyPalmDocument *newDoc;
    
    pool = [[NSAutoreleasePool alloc] init];
    
    // create a new record in skyrix
    newDoc = [self->skyrixDS newDocument];
    
    [newDoc takeValuesFromDocument:one];
    // reset values
    [newDoc setIsNew:NO];
    [newDoc setIsDeleted:NO];
    [newDoc setIsArchived:NO];
    [newDoc setIsModified:NO];
    [newDoc setMd5Hash:[newDoc generateMD5Hash]];
    [newDoc clearGlobalID];
    // save without reset of flags
    [newDoc saveWithoutReset];
    //[self _handlePostSyncOnSkyrixRecord:newDoc];
    [self checkForTimeout];
    
    [pool release];
  }
}

- (void)_handleNewObjectInSkyrix:(id)one {
  SkyPalmDocument *newDoc;
  
  // create a new record on palm
  newDoc = [self->palmDS newDocument];

  // reset values of sky-rec
  [one setIsNew:NO];
  [one setIsModified:NO];
  [one setPalmId:0];
  [one setMd5Hash:[one generateMD5Hash]];
  [one saveWithoutReset];
  // creating new palm-rec
  [newDoc takeValuesFromDocument:one];
  [newDoc saveWithoutReset];
  [self _resetLastAction];
  
  [(OGoNHSDeviceDataSource *)self->palmDS 
                             mapLastInsertedToSkyId:
                               [[one globalID] keyValues][0]];
#if 0
  [self _handlePostSyncOnSkyrixRecord:one];
#endif
}

- (void)_handleNewInSkyrix:(NSArray *)_newInSkyrix {
  NSEnumerator *e;
  id           one;
  
  e = [_newInSkyrix objectEnumerator];
  while ((one = [e nextObject])) {  
    NSAutoreleasePool *pool;
    
    pool = [[NSAutoreleasePool alloc] init];
    [self _handleNewObjectInSkyrix:one];
    [pool release];
  }
}

- (void)_handleChangedObjectInPalm:(id)one
  skyrixMapping:(NSDictionary *)_mappedSkyRecs
{
  id skyRec = nil;
  
  skyRec = [_mappedSkyRecs valueForKey:
                             (id)[NSNumber numberWithInt:[one palmId]]];
  if (skyRec == nil) {
    NSString *error;

    error = [NSString stringWithFormat:
                        @"WARNING!! no mapped sky rec for palm rec: %@", one];
    [self _appendErrorMessage:error];
    return;
  }
    
  // reset palm values 
  [one setIsModified:NO];
  [one setIsArchived:NO];
  [one setIsDeleted:NO];
  [one setIsNew:NO];
  [one saveWithoutReset];
  [self _resetLastAction];

  // sky-rec gets values from palm-rec
  [skyRec takeValuesFromDocument:one];
  [skyRec setIsDeleted:NO];
  [skyRec setIsArchived:NO];
  [skyRec setMd5Hash:[skyRec generateMD5Hash]];
  // increase object version manualy
  [skyRec increaseObjectVersion];
  [skyRec saveWithoutReset];
  //[self _handlePostSyncOnSkyrixRecord:skyRec];
}

- (void)_handleChangedInPalm:(NSArray *)_palmRecs
  skyrixMapping:(NSDictionary *)_mappedSkyRecs
{
  NSEnumerator *e;
  id           one;
  
  e = [_palmRecs objectEnumerator];
  while ((one = [e nextObject])) {  
    NSAutoreleasePool *pool;
    
    pool = [[NSAutoreleasePool alloc] init];
    [self _handleChangedObjectInPalm:one skyrixMapping:_mappedSkyRecs];
    [pool release];
  }
}

- (void)_handleChangedObjectInSkyrix:(id)one
  palmMapping:(NSDictionary *)_mappedPalmRecs
{
  id palmRec = nil;

  palmRec = [_mappedPalmRecs valueForKey:
                               (id)[NSNumber numberWithInt:[one palmId]]];
  if (palmRec == nil) {
    [self _appendErrorMessage:
            [NSString stringWithFormat:
                        @"WARNING!! no mapped palm rec for sky rec: %@, "
                      @"creating new palm rec",
                      one]];
    // --> create new
    palmRec = [self->palmDS newDocument];
  }

  // reset skyrix values
  [one setIsModified:NO];
  [one setMd5Hash:[one generateMD5Hash]];
  [one saveWithoutReset];

  // palm-rec gets values fro sky-rec
  [palmRec takeValuesFromDocument:one];
  [palmRec saveWithoutReset];
  [self _resetLastAction];
  //[self _handlePostSyncOnSkyrixRecord:one];
}

- (void)_handleChangedInSkyrix:(NSArray *)_skyRecs
  palmMapping:(NSDictionary *)_mappedPalmRecs
{
  NSEnumerator *e;
  id           one;
  
  e = [_skyRecs objectEnumerator];
  while ((one = [e nextObject])) {
    NSAutoreleasePool *pool;
    
    pool = [[NSAutoreleasePool alloc] init];
    [self _handleChangedObjectInSkyrix:one palmMapping:_mappedPalmRecs];
    [pool release];
  }
}

- (void)_handleDeletedObjectInPalm:(id)one
  skyrixMapping:(NSDictionary *)_mappedSkyRecs 
{
  id skyRec;
  id skyId  = nil;

  skyRec = [_mappedSkyRecs valueForKey:
                             (id)[NSNumber numberWithInt:[one palmId]]];
  if (skyRec == nil) {
    [self _appendErrorMessage:
            [NSString stringWithFormat:
                      @"WARNING!! no mapped sky rec for palm rec: %@",
                      one]];
    return;
  }
  
  // check wether skyRec was bound to a ogo rec
  skyId = [skyRec skyrixId];
  if ([skyId isNotNull])
    [self->skyIdsOfDeletedPalmRecords addObject:skyId];
  
  // palm record already deleted nothing more needed
  // [one realyDelete];
  // delete skyRec
  [skyRec realyDelete];
  [self checkForTimeout];
}

- (void)_handleDeletedInPalm:(NSArray *)_palmRecs
  skyrixMapping:(NSDictionary *)_mappedSkyRecs 
{
  NSEnumerator *e;
  id           one;

  e = [_palmRecs objectEnumerator];
  while ((one = [e nextObject])) {
    NSAutoreleasePool *pool;
    
    pool = [[NSAutoreleasePool alloc] init];
    [self _handleDeletedObjectInPalm:one skyrixMapping:_mappedSkyRecs];
    [pool release];
  }
}

- (void)_handleDeletedObjectInSkyrix:(id)one
  palmMapping:(NSDictionary *)_mappedPalmRecs
{
  id palmRec = nil;
  
  palmRec = [_mappedPalmRecs valueForKey:
                               (id)[NSNumber numberWithInt:[one palmId]]];
  if (palmRec == nil) {
    [self _appendErrorMessage:
            [NSString stringWithFormat:
                        @"WARNING!! no mapped palm rec for sky rec: %@",
                      one]];
    // --> create a palm rec to delete it
    palmRec = [self->palmDS newDocument];
    [palmRec takeValuesFromDocument:one];
    [palmRec saveWithoutReset];
    [self _resetLastAction];
  }
  
  // TODO: broken method name: 'reallyDelete'
  [one realyDelete];
  [palmRec realyDelete];
}

- (void)_handleDeletedInSkyrix:(NSArray *)_skyRecs
  palmMapping:(NSDictionary *)_mappedPalmRecs
{
  NSEnumerator *e;
  id           one;
  
  e = [_skyRecs objectEnumerator];
  while ((one = [e nextObject])) {
    NSAutoreleasePool *pool;
    
    pool = [[NSAutoreleasePool alloc] init];
    [self _handleDeletedObjectInSkyrix:one palmMapping:_mappedPalmRecs];
    [pool release];
  }
}

- (void)_handleChangedInBoth:(NSArray *)_both {
  NSEnumerator *e    = nil;
  id           one   = nil;
  id           palm  = nil;
  id           sky   = nil;
  
  e = [_both objectEnumerator];

  while ((one = [e nextObject])) {
    NSAutoreleasePool *pool     = [[NSAutoreleasePool alloc] init];
    palm = [one valueForKey:@"palmRecord"];
    sky  = [one valueForKey:@"skyrixRecord"];

    // palm over sky (for now)

    // reset palm values
    [palm setIsModified:NO];
    [palm setIsArchived:NO];
    [palm setIsDeleted:NO];
    [palm setIsNew:NO];
    [palm saveWithoutReset];
    [self _resetLastAction];
    
    // sky-rec gets values from palm-rec
    [sky takeValuesFromDocument:palm];
    [sky setMd5Hash:[sky generateMD5Hash]];
    [sky increaseObjectVersion];
    [sky saveWithoutReset];
    //[self _handlePostSyncOnSkyrixRecord:sky];
    RELEASE(pool);
  }
}

- (BOOL)preSyncProgress:(double)_progress {
  [self checkForTimeout];
  return YES;
}

- (void)syncRecordsWithDeviceId:(NSString *)_deviceId {
  // TODO: split up this big method
  // TODO: replace DEBUG define with some PalmDebug default
  NSArray      *skyRecords  = nil;
  NSArray      *palmRecords = nil;
  id           tmp          = nil;
  NSDictionary *compared       = nil;
  NSDictionary *mappedSkyRecs  = nil;
  NSDictionary *mappedPalmRecs = nil;

  [self checkForTimeout];

  /* new pre sync */
  if ([self syncWithSkyrixRecordBefore]) {
    SkyPalmPreSync *preSync;
    NSDate         *date;

    date = [NSDate date];
    preSync =
      [SkyPalmPreSync preSyncForPalmDataSource:[self skyrixDataSource]
                      deviceId:_deviceId];


    // set options
    [preSync setAllowPalmOverSkyrixSync:NO];
    [preSync setAllowSkyrixOverPalmSync:YES];
    [preSync setDoAutomaticInsert:YES];
    [preSync setProgressDelegate:self];

    if (![preSync preSync]) {
      NSLog(@"WARNING[%s]: presync failed. syncing with palm anyway.",
            __PRETTY_FUNCTION__);
    }

    [self logInFunction:__PRETTY_FUNCTION__
          message:@"[%@] presync took %2.3lf", 
          [[self skyrixDataSource] palmDb],
          [[NSDate date] timeIntervalSinceDate:date]];
  }
  
  //NSLog(@"%s syncing records, fetching skyrix records", __PRETTY_FUNCTION__);
  skyRecords  = [[self skyrixDataSource] fetchObjects];
  //NSLog(@"%s skyrix records fetched, fetching palm records",
  //      __PRETTY_FUNCTION__);
  [self checkForTimeout];
  palmRecords = [[self palmDataSource]   fetchObjects];
  //NSLog(@"%s palm records fetched", __PRETTY_FUNCTION__);
  //[self _resetLastAction];
  [self checkForTimeout];

  //NSLog(@"%s handling presync actions on skyrix records", __PRETTY_FUNCTION__);
  //[self _handlePreSyncOnSkyrixRecords:skyRecords];
  //NSLog(@"%s done presync actions", __PRETTY_FUNCTION__);

  mappedPalmRecs = [self _recordsMappedByPalmId:palmRecords];
  mappedSkyRecs  = [self _recordsMappedByPalmId:skyRecords];

#if DEBUG
  {
    NSString *palmDb =
      [NSString stringWithFormat:@"%10@",
                [[self skyrixDataSource] palmDb]];
    [self logInFunction:__PRETTY_FUNCTION__
          message:@"[%@] comparing records (%d in Palm and %d in Skyrix)",
          palmDb, [palmRecords count], [skyRecords count]];
  }
#endif

  compared = [self _comparePalmRecords:palmRecords withSkyRecords:skyRecords];
  // checking timeout
  [self checkForTimeout];

  /*         checking new records         */
  // new in palm
  tmp = [compared valueForKey:@"newInPalm"];
#if DEBUG
  if ([tmp count] > 0)
    [self logInFunction:__PRETTY_FUNCTION__
          message:@"      |--> checking newInPalm (%d)", [tmp count]];
#endif
  [self _handleNewInPalm:tmp];
  // new in skyrix
  tmp = [compared valueForKey:@"newInOGo"];
#if DEBUG
  if ([tmp count] > 0)
    [self logInFunction:__PRETTY_FUNCTION__
          message:@"      |--> checking newInOGo (%d)", [tmp count]];
#endif
  [self _handleNewInSkyrix:tmp];

  /*          changed records             */
  // changed on palm
  tmp = [compared valueForKey:@"changedInPalm"];
#if DEBUG
  if ([tmp count] > 0)
    [self logInFunction:__PRETTY_FUNCTION__
          message:@"      |--> checking changedInPalm (%d)", [tmp count]];
#endif
  [self _handleChangedInPalm:tmp skyrixMapping:mappedSkyRecs];
  // changed on skyrix
  tmp = [compared valueForKey:@"changedInOGo"];
#if DEBUG
  if ([tmp count] > 0)
    [self logInFunction:__PRETTY_FUNCTION__
          message:@"      |--> checking changedInOGo (%d)", [tmp count]];
#endif
  [self _handleChangedInSkyrix:tmp palmMapping:mappedPalmRecs];

  /*          deleted records             */
  // deleted in palm
  tmp = [compared valueForKey:@"deletedInPalm"];
#if DEBUG
  if ([tmp count] > 0)
    [self logInFunction:__PRETTY_FUNCTION__
          message:@"      |--> checking deletedInPalm (%d)", [tmp count]];
#endif
  [self _handleDeletedInPalm:tmp skyrixMapping:mappedSkyRecs];
  // deleted in skyrix
  tmp = [compared valueForKey:@"deletedInOGo"];
#if DEBUG
  if ([tmp count] > 0)
    [self logInFunction:__PRETTY_FUNCTION__
          message:@"      |--> checking deletedInOGo (%d)", [tmp count]];
#endif
  [self _handleDeletedInSkyrix:tmp palmMapping:mappedPalmRecs];

  /*           changed in both            */
  tmp = [compared valueForKey:@"changedInBoth"];
#if DEBUG
  if ([tmp count] > 0)
    [self logInFunction:__PRETTY_FUNCTION__
          message:@"      |--> checking changedInBoth (%d)", [tmp count]];
#endif
  [self _handleChangedInBoth:tmp];

  /* !!! Records new to Palm must still be assigend !!! */
}

// category section

- (NSArray *)_mergeCategoriesFromPalm:(NSArray *)_palmRecs
                            andSkyrix:(NSArray *)_skyRecs
{
  NSDictionary *skyMapping  = [self _recordsMappedByPalmId:_skyRecs];
  NSDictionary *palmMapping = [self _recordsMappedByPalmId:_palmRecs];

  NSEnumerator *e      = nil;
  id           one     = nil;
  id           tmp     = nil;
  NSNumber     *palmId = nil;

  NSMutableArray *all = [NSMutableArray array];

  e = [[skyMapping allKeys] objectEnumerator];

  while ((one = [e nextObject])) {
    if ([one isKindOfClass:[NSString class]]) {
      // these are the new
      [all addObjectsFromArray:[skyMapping valueForKey:one]];
      continue;
    }

    palmId = (NSNumber *)one;
    one = [skyMapping valueForKey:(id)palmId];

    if ([one isModified]) {
      // skyrix record is modified --> sky over palm
      [all addObject:one];
      continue;
    }

    if ((tmp = [palmMapping valueForKey:(id)palmId]) == nil) {
      // no mapped palm entry --> delete
      continue;
    }

    if (![[tmp generateMD5Hash] isEqualToString:[one md5Hash]]) {
      // palm rec changed
      [all addObject:tmp];
      continue;
    }

    // both records unchanged
    [all addObject:one];
  }

  [self checkForTimeout];

  e = [[palmMapping allKeys] objectEnumerator];
  while ((one = [e nextObject])) {
    if ([one isKindOfClass:[NSString class]]) {
      // these are the new
      [all addObjectsFromArray:[palmMapping valueForKey:one]];
      continue;
    }

    palmId = one;
    one = [palmMapping valueForKey:(id)palmId];
    if ((tmp = [skyMapping valueForKey:(id)palmId]) == nil) {
      // no matching sky category found
      [all addObject:one];
      continue;
    }

    // matching skyrix record found
    // already added ...
  }

  return all;
}

- (void)syncCategoriesForDeviceId:(NSString *)_devId {
  NSArray  *palmCats;
  NSArray  *skyCats;

  NSArray  *mergedRecs;

  switch (self->categorySyncMode) {
    case (SYNC_CATEGORY_FROM_SKYRIX):
      skyCats  = [[self skyrixDataSource] categoriesForDevice:_devId];
      [self checkForTimeout];
      palmCats = [NSArray array];
      break;
    case (SYNC_CATEGORY_MERGE_BOTH):
      palmCats = [[self palmDataSource]   categoriesForDevice:_devId];
      [self _resetLastAction];
      skyCats  = [[self skyrixDataSource] categoriesForDevice:_devId];
      [self checkForTimeout];
      break;
    case (SYNC_CATEGORY_FROM_PALM):
    default:
      skyCats  = [NSArray array];
      palmCats = [[self palmDataSource]   categoriesForDevice:_devId];
      [self _resetLastAction];
      break;
  }

#if DEBUG
  {
    NSString *palmDb = [NSString stringWithFormat:@"%10@",
                                 [[self skyrixDataSource] palmDb]];
    [self logInFunction:__PRETTY_FUNCTION__
          message:@"[%10@] comparing categories (%d in Palm and %d in Skyrix)",
          palmDb, [palmCats count], [skyCats count]];
  }
#endif

  mergedRecs = [self _mergeCategoriesFromPalm:palmCats andSkyrix:skyCats];
  [self checkForTimeout];

#if DEBUG
  if (self->categorySyncMode == SYNC_CATEGORY_MERGE_BOTH)
    [self logInFunction:__PRETTY_FUNCTION__
          message:@"      |--> merged to %d categories", [mergedRecs count]];
#endif

  // first save in skyrix
  if (self->categorySyncMode != SYNC_CATEGORY_FROM_SKYRIX) {
    mergedRecs = [[self skyrixDataSource] saveCategories:mergedRecs
                                          forDevice:_devId];

    [self checkForTimeout];
  }
  // then in palm
  if (self->categorySyncMode != SYNC_CATEGORY_FROM_PALM) {
    [[self palmDataSource] saveCategories:mergedRecs
                           forDevice:_devId];
    [self _resetLastAction];
  }

  /* !!! Categories must still be assigned !!! */
}


// syncing

// full sync .. use only when datasources can do so
- (void)syncPalmDS:(SkyPalmDocumentDataSource *)_palmDS
      withSkyrixDS:(SkyPalmEntryDataSource *)_skyDS
         forDevice:(NSString *)_dev
{
  [self setPalmDataSource:_palmDS];
  [self setSkyrixDataSource:_skyDS];

  //  [self syncCategoriesForDeviceId:_dev];
  [self syncRecordsWithDeviceId:_dev];
}

#if 0
// record sync
- (void)syncPalmDS:(SkyPalmDocumentDataSource *)_palmDS
      withSkyrixDS:(SkyPalmEntryDataSource *)_skyDS
{

  [self setPalmDataSource:_palmDS];
  [self setSkyrixDataSource:_skyDS];

  [self syncRecords];
}
#endif


// assigning
- (EOFetchSpecification *)_fetchSpecForIds:(NSArray *)_pkeys
                                primaryKey:(NSString *)_pkey
                                    entity:(NSString *)_entity
{
  NSString    *query = nil;
  EOQualifier *qual  = nil;

  if ([_pkeys count] > 0) {
    query = [NSString stringWithFormat:@" OR %@=", _pkey];
    query = [NSString stringWithFormat:@"%@=%@", _pkey,
                      [_pkeys componentsJoinedByString:query]];
  }
  else { // fetch no recs
    query = [NSString stringWithFormat:@"%@=-1", _pkey];
  }

  qual = [EOQualifier qualifierWithQualifierFormat:query];
  
  return [EOFetchSpecification fetchSpecificationWithEntityName:_entity
                               qualifier:qual sortOrderings:nil];  
}

- (void)_extractSkyrixIds:(NSArray **)_skyIds
               andMapping:(NSDictionary **)_sky2Palm
               forListing:(NSArray *)_mapping
{
  NSMutableArray      *skyIds   = nil;
  NSMutableDictionary *sky2Palm = nil;
  NSNumber            *palmId   = nil;
  NSNumber            *skyId    = nil;

  NSEnumerator *e;
  id           one;

  skyIds   = [NSMutableArray array];
  sky2Palm = [NSMutableDictionary dictionaryWithCapacity:16];

  e = [_mapping objectEnumerator];
  while ((one = [e nextObject])) {
    palmId = [one valueForKey:@"palm_id"];
    skyId  = [one valueForKey:@"skyrix_id"];

    [skyIds addObject:skyId];
    [sky2Palm takeValue:palmId forKey:(id)skyId];
  }

  *_skyIds   = skyIds;
  *_sky2Palm = sky2Palm;
}

- (void)_assingDocs:(NSArray *)_docs
        withMapping:(NSDictionary *)_sky2Palm
{
  NSNumber            *palmId   = nil;
  NSNumber            *skyId    = nil;
  NSEnumerator        *e;
  id                  one;

  e = [_docs objectEnumerator];
  while ((one = [e nextObject])) {
    skyId  = [[[one globalID] keyValuesArray] objectAtIndex:0];
    palmId = [_sky2Palm valueForKey:(id)skyId];

    [one setPalmId:[palmId intValue]];
    [one setMd5Hash:[one generateMD5Hash]];
    [one saveWithoutReset];
  }
}

/*
 *  Array looks like this:
 *  mapping = (
 *    {   palm_id   = <palm_id>;
 *        skyrix_id = <skyrix_id>;
 *    },
 *    ...
 *  );
 *
 */

//  SkyrixDS must be set
- (NSArray *)_seperateIds:(NSArray *)_ids
               primaryKey:(NSString *)_pk
                   entity:(id)_entity
               dataSource:(id)_ds
{
  NSMutableArray *result;
  int            maxCount = 200;
  int            idCnt, currentPos;

  idCnt  = [_ids count];
  result = [NSMutableArray arrayWithCapacity:idCnt];
  currentPos = 0;

  while (currentPos < idCnt) {
    NSArray *sub;
    int     idx;

    idx = (currentPos+maxCount>idCnt)?idCnt-currentPos:maxCount;

    sub = [_ids subarrayWithRange:NSMakeRange(currentPos, idx)];

    currentPos +=maxCount;

    [_ds setFetchSpecification:[self _fetchSpecForIds:sub
                                    primaryKey:_pk
                                    entity:_entity]];
    [result addObjectsFromArray:[_ds fetchObjects]];
  }
  return result;
}
  

- (void)assignRecords:(NSArray *)_mapping {
  NSMutableArray         *skyIds   = nil;
  NSMutableDictionary    *sky2Palm = nil;  
  SkyPalmEntryDataSource *ds;

  ds = [self skyrixDataSource];

#if DEBUG
  if ([_mapping count] > 0) {
    NSString *palmDb = [NSString stringWithFormat:@"%10@",
                                 [ds palmDb]];
    [self logInFunction:__PRETTY_FUNCTION__
          message:@"[%10@] assigning records (%d)", palmDb, [_mapping count]];
  }
#endif

  [self _extractSkyrixIds:&skyIds andMapping:&sky2Palm forListing:_mapping];

#if 0
  [ds setFetchSpecification:[self _fetchSpecForIds:skyIds
                                  primaryKey:[ds primaryKey]
                                  entity:[ds entityName]]];
  [self _assingDocs:[ds fetchObjects] withMapping:sky2Palm];
#else
  [self _assingDocs:[self _seperateIds:skyIds primaryKey:[ds primaryKey]
                          entity:[ds entityName] dataSource:ds]
        withMapping:sky2Palm];
#endif

}

// takes a new category ds with context of skyrixDS
- (void)assignCategories:(NSArray *)_mapping {
  SkyPalmCategoryDataSource *ds;
  NSMutableArray            *skyIds   = nil;
  NSMutableDictionary       *sky2Palm = nil;
  SkyPalmEntryDataSource    *eds;

  eds = [self skyrixDataSource];

#if DEBUG
  if ([_mapping count] > 0) {
    NSString *palmDb = [NSString stringWithFormat:@"%10@", [eds palmDb]];
    [self logInFunction:__PRETTY_FUNCTION__
          message:@"[%10@] assigning categories (%d)",
          palmDb, [_mapping count]];
  }
#endif

  [self _extractSkyrixIds:&skyIds andMapping:&sky2Palm forListing:_mapping];

  ds  = [SkyPalmCategoryDataSource dataSourceWithContext:[eds context]
                                   forPalmTable:[eds palmDb]];
  
#if 0
  [ds setFetchSpecification:[self _fetchSpecForIds:skyIds
                                  primaryKey:@"palm_category_id"
                                  entity:@"palm_category"]];
  [self _assingDocs:[ds fetchObjects] withMapping:sky2Palm];
#else
  [self _assingDocs:[self _seperateIds:skyIds
                          primaryKey:@"palm_category_id"
                          entity:@"palm_category" dataSource:ds]
        withMapping:sky2Palm];
#endif
}

- (NSArray *)skyIdsOfDeletedPalmRecords {
  return self->skyIdsOfDeletedPalmRecords;
}


@end /* SkyPalmSyncMachine */

@implementation SkyPalmSyncMachine(PrivatMethods)

- (void)_resetLastAction {
  RELEASE(self->lastAction);
  self->lastAction = [[NSDate date] copy];
}

- (int)timeoutCheckSeconds {
  if (self->timeoutCheckSeconds == -1) {
    self->timeoutCheckSeconds =
      [[[NSUserDefaults standardUserDefaults]
                        objectForKey:@"OGoPalmSync_timeoutCheckSeconds"]
                        intValue];
    if (self->timeoutCheckSeconds < 1)
      self->timeoutCheckSeconds = 2; // default
  }
  return self->timeoutCheckSeconds;
}

- (void)checkForTimeout {
  // lets check for timeout every 15 seconds
  // should be enough
  int check = [self timeoutCheckSeconds];
  if ((self->lastAction == nil) ||
      ([self->lastAction timeIntervalSinceNow] < -check)) {
    [[self palmDataSource] dotLog]; // print a single dot
    [self _resetLastAction];
    //#if DEBUG
#if 0
    NSLog(@"%s preventing timeout after %d secs.",
          __PRETTY_FUNCTION__, check);
#endif
  }
}

@end /* SkyPalmSyncMachine(PrivatMethods) */
