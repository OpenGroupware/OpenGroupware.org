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

/*
  structure of this file:

   - interface of SkyPalmPostSync-subclasses
   - implementation SkyPalmPostSync
   - implementation of SkyPalmPostSync-subclasses
*/

#include <OGoPalm/SkyPalmPostSync.h>

/* interface of SkyPalmPostSync-subclasses */
@interface SkyPalmAddressPostSync : SkyPalmPostSync
{
  int createPrivate; // default: 1
}
@end /* SkyPalmPostSync */

@interface SkyPalmDatePostSync : SkyPalmPostSync
{
  id accessTeamId;         // default: null
  NSArray *writeAccessIds; // default: null  
}
@end /* SkyPalmPostSync */

@interface SkyPalmMemoPostSync : SkyPalmPostSync
@end

@interface SkyPalmJobPostSync : SkyPalmPostSync
@end

#import <Foundation/Foundation.h>
#include <OGoPalm/SkyPalmEntryDataSource.h>
#include <OGoPalm/SkyPalmConstants.h>
#include <EOControl/EOKeyGlobalID.h>
#include <EOControl/EOQualifier.h>
#include <EOControl/EOFetchSpecification.h>
#include <OGoDocuments/SkyDocument.h>
#include <LSFoundation/LSCommandKeys.h>
#include <LSFoundation/NSObject+Commands.h>


@interface SkyPalmPostSync(FetchSpecBuilding)
- (EOFetchSpecification *)_nonPrivateFetchSpecForEntity:(NSString *)_entity;
- (EOFetchSpecification *)_skyFetchSpecForEntity:(NSString *)_entity;
@end /* SkyPalmPostSync(FetchSpecBuilding) */

/* implementation SkyPalmPostSync */

@implementation SkyPalmPostSync

+ (SkyPalmPostSync *)postSyncForPalmDataSource:(SkyPalmEntryDataSource *)_ds
                                     deviceId:(NSString *)_deviceId
{
  NSString        *palmDB;
  SkyPalmPostSync *postSync = nil;
  palmDB = [_ds palmDb];
  if      ([palmDB isEqualToString:@"AddressDB"])
    postSync = [SkyPalmAddressPostSync alloc];
  else if ([palmDB isEqualToString:@"DatebookDB"])
    postSync = [SkyPalmDatePostSync alloc];
  else if ([palmDB isEqualToString:@"MemoDB"])
    postSync = [SkyPalmMemoPostSync alloc];
  else if ([palmDB isEqualToString:@"ToDoDB"])
    postSync = [SkyPalmJobPostSync alloc];
  else {
    NSLog(@"WARNING[%s]: cannot init postsync for unknown palm db: %@. "
          @"post-sync bundle-loading isnot yet implemented.",
          __PRETTY_FUNCTION__, palmDB);
    postSync = nil;
  }
  return
    [[postSync initWithPalmDataSource:_ds andDeviceId:_deviceId] autorelease];

}

- (id)init {
  if ((self = [super init])) {
    self->allowPalmOverSkyrixSync = YES;
    self->allowSkyrixOverPalmSync = NO;
    self->doAutomaticInsert       = YES;
  }
  return self;
}

// init (used by autoreleased init. dont use directly)
- (SkyPalmPostSync *)initWithPalmDataSource:(SkyPalmEntryDataSource *)_ds
                               andDeviceId:(NSString *)_deviceId
{
  if ((self = [self init])) {
    self->palmDataSource = [_ds       retain];
    self->deviceId       = [_deviceId retain];
  }
  return self;
}

- (void)dealloc {
  [self->palmDataSource release];
  [self->deviceId       release];
  [self->skyIdsOfDeleted release];
  [super dealloc];
}

- (int)defaultSkyrixSyncType {
  return SYNC_TYPE_TWO_WAY;
}

- (BOOL)assignOGoEntry:(SkyDocument *)_ogoEntry
           toPalmEntry:(SkyPalmDocument *)_palmEntry
{
  EOKeyGlobalID *skyrixGID;
  id            skyrixId;
  skyrixGID = (EOKeyGlobalID *)[_ogoEntry globalID];
  if (skyrixGID == nil) {
    NSLog(@"%s: skyrix document has no gid: %@",
          __PRETTY_FUNCTION__, _ogoEntry);
    return NO;
  }
  skyrixId  = [skyrixGID keyValues][0];
  [_palmEntry setSkyrixId:skyrixId];

  return YES;
}

- (BOOL)handleSkyIdOfDeletedPalmEntry:(id)_skyId {
  return YES;
}

- (BOOL)automaticDelete {
  id skyId;
  unsigned int cnt, i;
  cnt = [self->skyIdsOfDeleted count];

  for (i = 0; i < cnt; i++) {
    skyId = [self->skyIdsOfDeleted objectAtIndex:i];

    if (![self handleSkyIdOfDeletedPalmEntry:skyId]) {
        NSLog(@"%s: failed handling skyid '%@' of deleted palm entry",
              __PRETTY_FUNCTION__, skyId);
        return NO;
    }
  }

  return YES;
}


- (BOOL)automaticInsert {
  NSArray *toInsert;
  unsigned int cnt, i;
  SkyPalmDocument *palmEntry;

  toInsert = [self fetchPalmEntriesToInsertIntoOGo];
  cnt = [toInsert count];

  for (i = 0; i < cnt; i++) {
    palmEntry = [toInsert objectAtIndex:i];
    if (![palmEntry hasSkyrixRecord]) {
      /*
        (1) create a new skyrix record
        and
        (2) assign it to the palm entry
        and
        (3) force a first-time palm-over-skyrix sync
      */

      SkyDocument *newSkyrixEntry;

      /* (1) */
      newSkyrixEntry = [self createOGoEntryForPalmEntry:palmEntry];
      if (newSkyrixEntry == nil)
        // don't create a ogo entry for this palm entry
        continue;

      /* (2) */
      if (![self assignOGoEntry:newSkyrixEntry toPalmEntry:palmEntry]) {
        NSLog(@"%s: failed assigning skyrix to palm entry. "
              @"skyrix entry: %@ palm entry: %@",
              __PRETTY_FUNCTION__, newSkyrixEntry, palmEntry);
        return NO;
      }

      /* (3) */
      [palmEntry setSyncType:[self defaultSkyrixSyncType]];
      // sync for the first time and save the new ogo entry
      if ([palmEntry forcePalmOverSkyrixSync] == nil) {
        NSLog(@"%s: first time sync palm-over-skyrix failed. "
              @"skyrix entry: %@ palm entry: %@",
              __PRETTY_FUNCTION__, newSkyrixEntry, palmEntry);
        return NO;
      }
      
    }
  }
  
  return YES;
}

- (EOFetchSpecification *)_skyFetchSpecForEntity:(NSString *)_entity {
  EOQualifier *qual = nil;
  EOFetchSpecification *fSpec = nil;
  id companyId;

  companyId = [[[self->palmDataSource context] valueForKey:LSAccountKey]
                                      valueForKey:@"companyId"];
  
  qual = [EOQualifier qualifierWithQualifierFormat:
                      @"company_id=%@ AND "
                      @"device_id=%@",
                      companyId, self->deviceId];
  fSpec = 
    [EOFetchSpecification fetchSpecificationWithEntityName:_entity
                          qualifier:qual sortOrderings:nil];
  [fSpec setHints:
         [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
                       forKey:@"fetchSkyrixRecords"]];
  return fSpec;
}

- (EOFetchSpecification *)_nonPrivateFetchSpecForEntity:(NSString *)_entity {
  EOQualifier *qual = nil;
  id companyId;

  companyId = [[[self->palmDataSource context] valueForKey:LSAccountKey]
                                      valueForKey:@"companyId"];
  
  qual = [EOQualifier qualifierWithQualifierFormat:
                      @"company_id=%@ AND "
                      @"device_id=%@ AND NOT (is_private = 1)",
                      companyId, self->deviceId];
  return
    [EOFetchSpecification fetchSpecificationWithEntityName:_entity
                          qualifier:qual sortOrderings:nil];
}


- (BOOL)syncEntries {
  NSArray *palmEntries;  
  unsigned int cnt;
  unsigned int i;
  SkyPalmDocument *palmDoc;
  
  unsigned int syncAction;
  BOOL doSync;

  [self->palmDataSource setFetchSpecification:
       [self _skyFetchSpecForEntity:[self->palmDataSource entityName]]];
  palmEntries = [self->palmDataSource fetchObjects];
  cnt = [palmEntries count];
  for (i = 0; i < cnt; i++) {
    palmDoc    = [palmEntries objectAtIndex:i];
    doSync     = NO;
    if (([palmDoc hasSkyrixRecord]) &&
        (![palmDoc isDeleted]) &&
        (![palmDoc isArchived]))
      {

      syncAction = [palmDoc actualSkyrixSyncAction];

      switch (syncAction) {
        case SYNC_TYPE_PALM_OVER_SKY:
          if ([self allowPalmOverSkyrixSync])
            doSync = YES;
          break;
        case SYNC_TYPE_SKY_OVER_PALM:
          if ([self allowSkyrixOverPalmSync])
            doSync = YES;
          break;
        case SYNC_TYPE_DO_NOTHING:
          // do-nothing doesn't sync anything. but modified-flags are reseted
          doSync = YES;
      }

      if (doSync) {
        if ([palmDoc syncWithSkyrixRecord] == nil) {
          NSLog(@"WARNING[%s]: failed syncing with skyrix record "
                @"of palm entry: %@", __PRETTY_FUNCTION__, palmDoc);
          return NO;
        }
      }
    }
  }
  return YES;
}

- (NSArray *)fetchPalmEntriesToInsertIntoOGo {
  NSLog(@"ERROR[%s]: method not overwritten in subclass",
        __PRETTY_FUNCTION__);
  return nil;
}

- (SkyDocument *)createOGoEntryForPalmEntry:(SkyPalmDocument *)_doc {
  NSLog(@"ERROR[%s]: method not overwritten in subclass",
        __PRETTY_FUNCTION__);
  return nil;
}

- (void)setSkyIdsOfDeleted:(NSArray *)_ar {
  ASSIGN(self->skyIdsOfDeleted, _ar);
}
- (BOOL)doAutomaticDelete {
  return YES;
}


- (BOOL)postSync {
  BOOL result;

  /* (0) automatic delete */
  // handle dangling ogo records (of those palm entries deleted in palm) */
  if ([self doAutomaticDelete]) {
    result = [self automaticDelete];
    if (!result) {
      NSLog(@"WARNING[%s]: automatic delete failed. "
            @"post sync of table %@ wont continue.",
            __PRETTY_FUNCTION__, [self->palmDataSource palmDb]);
      return result;
    }
  }
  
  /* (1) automatic insert */
  if ([self doAutomaticInsert]) {
    result = [self automaticInsert];
    if (!result) {
      NSLog(@"WARNING[%s]: automatic instert failed. "
            @"post sync of table %@ wont continue.",
            __PRETTY_FUNCTION__, [self->palmDataSource palmDb]);
      return result;
    }
  }

  /* (2) sync existing palm entries */
  result = [self syncEntries];
  if (!result) {
    NSLog(@"WARNING[%s]: [%@] post-syncing of palm entries failed. ",
          __PRETTY_FUNCTION__, [self->palmDataSource palmDb]);
    return result;
  }

  /* (3) reset the saved state information */
  {
    NSString *key;
    NSMutableArray *ma;

    key = [NSString stringWithFormat:@"OGoPalm_%@_UpdatedInPreSyncIDs",
		    [self->palmDataSource palmDb]];
    if ((ma = [[self->palmDataSource context] valueForKey:key]) != nil)
      [ma removeAllObjects];
  }

  return YES;
}

/* switches */
- (void)setAllowPalmOverSkyrixSync:(BOOL)_flag {
  self->allowPalmOverSkyrixSync = _flag;
}
- (BOOL)allowPalmOverSkyrixSync {
  return self->allowPalmOverSkyrixSync;
}

- (void)setAllowSkyrixOverPalmSync:(BOOL)_flag {
  self->allowSkyrixOverPalmSync = _flag;
}
- (BOOL)allowSkyrixOverPalmSync {
  return self->allowSkyrixOverPalmSync;
}

- (void)setDoAutomaticInsert:(BOOL)_flag {
  self->doAutomaticInsert = _flag;
}
- (BOOL)doAutomaticInsert {
  return self->doAutomaticInsert;
}


- (NSString *)deviceId {
  return self->deviceId;
}


@end /* SkyPalmPostSync */

#include <OGoPalm/SkyPalmAddressDocument.h>
#include <OGoContacts/SkyPersonDataSource.h>
#include <OGoContacts/SkyEnterpriseDataSource.h>
#include <OGoContacts/SkyPersonDocument.h>
#include <OGoContacts/SkyEnterpriseDocument.h>
#include <NGExtensions/NSNull+misc.h>

/* implementation SkyPalmPostSync-subclass */
@implementation SkyPalmAddressPostSync

- (id)init {
  if ((self = [super init])) {
    self->createPrivate = -1;
  }
  return self;
}

#if 0
- (BOOL)createPrivateRecords {
  if (self->createPrivate == -1) {
    id flag;
    NSUserDefaults *ud;
    ud = [[self->palmDataSource context] userDefaults];
    flag = [ud stringForKey:@"SkyPalm_AddressPostSync_createPrivate"];
    self->createPrivate = (flag != nil) ? [flag intValue] : 1;
  }
  return self->createPrivate ? YES : NO;
}
#endif

- (NSString *)postSyncMethod {
  NSUserDefaults *ud;
  NSString       *method;
  
  ud = [[self->palmDataSource context] userDefaults];
  method = [ud stringForKey:@"SkyPalm_AddressImportPalmData"];
  return [method isNotEmpty] ? method : (NSString *)@"sync_non_private";
}

- (NSArray *)fetchPalmEntriesToInsertIntoOGo {
  NSString *method;

  method = [self postSyncMethod];
  if ([method isEqualToString:@"sync_nothing"])
    return [NSArray array];
  else if ([method isEqualToString:@"sync_all"]) {
    return [self->palmDataSource fetchObjects];
  }
  else if ([method isEqualToString:@"sync_non_private"]) {
    NSString *entity = [self->palmDataSource entityName];

    [self->palmDataSource setFetchSpecification:
         [self _nonPrivateFetchSpecForEntity:entity]];

    return [self->palmDataSource fetchObjects];
  }
  else {
    NSLog(@"%s: unknown address post sync method: %@",
          __PRETTY_FUNCTION__, method);
  }
  return [NSArray array];
}

- (NSString *)suggestSkyrixTypeForPalmAddress:
  (SkyPalmAddressDocument *)_addressDoc
{
  // as default we want a person
  NSString *type = @"person";

  // if firstname and lastname are not set and company is set
  // we choose 'enterprise' as type
  if ((![[_addressDoc lastname] length]) && 
      (![[_addressDoc firstname] length]) &&
      ([[_addressDoc company] length])) {
    type = @"enterprise";
  }
  return type;
}

- (SkyDocument *)createOGoEntryForPalmEntry:(SkyPalmDocument *)_doc {
  SkyCompanyDocument *newCompany = nil;
  id ctx;
  NSString *type;

  ctx  = [self->palmDataSource context];
  type = [self suggestSkyrixTypeForPalmAddress:(SkyPalmAddressDocument *)_doc];
  
  if ([type isEqualToString:@"person"]) {
    SkyPersonDataSource  *ds =
      [[[SkyPersonDataSource alloc] initWithContext:ctx] autorelease];
    newCompany = [ds createObject];
    [(SkyPersonDocument *)newCompany
                          setName:
                          @"new person created during palm postsync"];
  }
  else if ([type isEqualToString:@"enterprise"]) {
    SkyEnterpriseDataSource  *ds =
      [[[SkyEnterpriseDataSource alloc] initWithContext:ctx] autorelease];
    newCompany = [ds createObject];
    [(SkyEnterpriseDocument *)newCompany
                              setName:
                              @"new enterprise created during palm postsync"];
  }

  return [newCompany save] ? newCompany : (SkyCompanyDocument *)nil;
}

@end /* SkyPalmAddressPostSync */

#include <OGoScheduler/SkyAppointmentDocument.h>
#include <OGoScheduler/SkyAppointmentDataSource.h>
#include <OGoPalm/SkyPalmDateDocument.h>

@implementation SkyPalmDatePostSync

- (void)dealloc {
  [self->accessTeamId   release];
  [self->writeAccessIds release];
  [super dealloc];
}

- (id)accessTeamId {
  if (self->accessTeamId == nil) {
    NSUserDefaults *ud;
    ud = [[self->palmDataSource context] userDefaults];
    self->accessTeamId =
      [ud stringForKey:@"ogopalm_default_scheduler_read_access_team"];
    self->accessTeamId = [self->accessTeamId length]
      ? [[NSNumber numberWithInt:[self->accessTeamId intValue]] retain]
      : [[NSNull null] retain]; 
  }
  return [self->accessTeamId isNotNull] ? self->accessTeamId : nil;
}

- (NSArray *)writeAccessIds {
  if (self->writeAccessIds == nil) {
    NSUserDefaults *ud;
    id tmp;
    ud = [[self->palmDataSource context] userDefaults];
    self->writeAccessIds =
      [ud arrayForKey:@"ogopalm_default_scheduler_write_access_accounts"];
    tmp = 
      [ud arrayForKey:@"ogopalm_default_scheduler_write_access_teams"];
    if (tmp == nil) {
      if (self->writeAccessIds == nil) self->writeAccessIds = [NSArray array];
    }
    else {
      if (self->writeAccessIds == nil) self->writeAccessIds = tmp;
      else {
        self->writeAccessIds =
          [self->writeAccessIds arrayByAddingObjectsFromArray:tmp];
      }
    }
    self->writeAccessIds = [self->writeAccessIds retain];
  }
  return self->writeAccessIds;
}

- (NSString *)postSyncMethod {
  NSUserDefaults *ud;
  NSString *method;
  
  ud     = [[self->palmDataSource context] userDefaults];
  method = [ud stringForKey:@"SkyPalm_DatesPostSyncMethod"];
  return [method isNotEmpty] ? method : (NSString *)@"sync_non_private";
}

- (NSArray *)fetchPalmEntriesToInsertIntoOGo {
  NSString *method;

  method = [self postSyncMethod];
  if ([method isEqualToString:@"sync_nothing"])
    return [NSArray array];
  else if ([method isEqualToString:@"sync_all"]) {
    return [self->palmDataSource fetchObjects];
  }
  else if ([method isEqualToString:@"sync_non_private"]) {
    NSString *entity = [self->palmDataSource entityName];
    [self->palmDataSource setFetchSpecification:
         [self _nonPrivateFetchSpecForEntity:entity]];

    return [self->palmDataSource fetchObjects];
  }
  else {
    NSLog(@"%s: unknown date post sync method: %@",
          __PRETTY_FUNCTION__, method);
  }
  return [NSArray array];
}

- (SkyDocument *)createOGoEntryForPalmEntry:(SkyPalmDocument *)_doc {
  SkyAppointmentDocument *newApt = nil;
  SkyAppointmentDataSource *ds;
  id ctx;

  {
    SkyPalmDateDocument *palmDate = (SkyPalmDateDocument *)_doc;
    if ([palmDate repeatType] != REPEAT_TYPE_SINLGE) {
      if (![[palmDate repeatEnddate] isNotNull]) {
        // repetition with no repeat enddate
        // -> ogo cannot handle that yet
        // TODO
        NSLog(@"%s: ignoring palm date without repeat-enddate in post-sync",
              __PRETTY_FUNCTION__);
        return nil;
      }
    }
  }

  ctx = [self->palmDataSource context];
  ds  = [[SkyAppointmentDataSource alloc] initWithContext:ctx];
  newApt = [ds createObject];
  [ds release]; ds = nil;
   
  if (newApt != nil) {      
    [(id)newApt setTitle:@"new appointment created during palm postsync"];
      
    [newApt setWriteAccess:[self writeAccessIds]];
    [newApt setAccessTeamId:[self accessTeamId]];
  }
  return [newApt save] ? newApt : (SkyAppointmentDocument *)nil;
}

- (id)appointmentAsEO:(EOGlobalID *)_gid {
  id app;
  id ctx;
  ctx = [self->palmDataSource context];
  app = [ctx runCommand:@"appointment::get-by-globalid", @"gid", _gid, nil];
  return app;
}

- (BOOL)updateParticipants:(NSArray *)_participants
		      ofEO:(id)_eo
		   logText:(NSString *)_logText
	     activeAccount:(id)_ac;
{
  id ac;
  id ctx;

  ac = _ac;
  ctx = [self->palmDataSource context];

  [ctx runCommand:@"appointment::set-participants",
       @"participants", _participants,
       @"object", _eo, nil];
    
  if (![ctx commit]) {
    NSLog(@"%s: Could not commit transaction", __PRETTY_FUNCTION__);
    return NO;
  }
  else {

    _logText = [_logText stringByAppendingString:[ac valueForKey:@"name"]];
    [ctx runCommand:@"object::add-log",
	 @"logText",     _logText,
	 @"action",      @"05_changed",
	 @"objectToLog", _eo, nil];
    
  }
  return YES;
}

- (BOOL)handleSkyIdOfDeletedPalmEntry:(id)_skyId {
  id gid;
  id apt;
  id ac;
  NSMutableArray *parts;
  
  /*
    steps:
    (1) : fetch matching ogo appointment
    (2) : if this user is the only one -> delete apt
    (3) : if not -> remove user as participant
  */

  ac = [[self->palmDataSource context] valueForKey:LSAccountKey];

  /* 1 */
  gid = [NSNumber numberWithInt:[_skyId intValue]];
  gid = [EOKeyGlobalID globalIDWithEntityName:@"Date"
		       keys:&gid keyCount:1 zone:NULL];
  apt = [self appointmentAsEO:gid];
  if (apt == nil) {
    // seems apt is already deleted
    return YES;
  }

  /* 2 */
  parts = [[[apt valueForKey:@"participants"] mutableCopy] autorelease];
  if ([parts count] == 1) {
    id part;
    id user;

    part = [parts lastObject];
    user = [ac valueForKey:@"companyId"];

    if ([[part valueForKey:@"companyId"] intValue] != [user intValue]) {
      // user is not participant -> there's nothing i can do
      return YES;
    }

    // user is the only participant -> delete the appointment
    {
      id result;

      result = [[self->palmDataSource context]
		 runCommand:
		   @"appointment::delete",
		 @"object", apt,
		 @"deleteAllCyclic",
		 [NSNumber numberWithBool:NO], // not deleting all
		 @"reallyDelete",    [NSNumber numberWithBool:YES],
		 nil];

      if (result == nil) {
	NSLog(@"%s: failed to delete ogo-apt: %@. continuing postsync.",
	      __PRETTY_FUNCTION__, apt);
      }

      return YES;

    }
  }

  /* 3 */
  if ([parts containsObject:ac]) {
    
    while ([parts containsObject:ac]) {
      [parts removeObject:ac];
    }
    
    if (![self updateParticipants:parts ofEO:apt
	       logText:@"Participant removed itself by deleting Palm-Date: "
	       activeAccount:ac]) {
      NSLog(@"%s: failed to remove participant %@",
	    __PRETTY_FUNCTION__, [ac valueForKey:@"name"]);
    }

  }
  

  
  return YES;
}


@end /* SkyPalmDatePostSync */

@implementation SkyPalmMemoPostSync
- (NSArray *)fetchPalmEntriesToInsertIntoOGo {
  // no automatic insert support yet
  return [NSArray array];
}
@end /* SkyPalmMemoPostSync */

@implementation SkyPalmJobPostSync
- (NSArray *)fetchPalmEntriesToInsertIntoOGo {
  // no automatic insert support yet
  return [NSArray array];
}
@end /* SkyPalmJobPostSync */
