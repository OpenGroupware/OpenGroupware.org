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

/*
  structure of this file:

   - interface of SkyPalmPreSync-subclasses
   - implementation SkyPalmPreSync
   - implementation of SkyPalmPreSync-subclasses
*/

#include <OGoPalm/SkyPalmPreSync.h>

/* interface of SkyPalmPreSync-subclasses */
@interface SkyPalmAddressPreSync : SkyPalmPreSync
{
  NSString *preSyncMethod;
}
@end /* SkyPalmAddressPreSync */

@class NSCalendarDate;
@class NSTimeZone;

@interface SkyPalmDatePreSync : SkyPalmPreSync
{
  NSCalendarDate *fetchPeriodStart;
  NSCalendarDate *fetchPeriodEnd;
  NSArray        *companiesToFetch;
  NSTimeZone     *timeZone;
}
@end /* SkyPalmDatePreSync */

@interface SkyPalmMemoPreSync : SkyPalmPreSync
@end /* SkyPalmMemoPreSync */

@interface SkyPalmJobPreSync : SkyPalmPreSync
@end /* SkyPalmJobPreSync */

#import <Foundation/Foundation.h>
#include <OGoPalm/SkyPalmEntryDataSource.h>
#include <OGoPalm/SkyPalmConstants.h>
#include <EOControl/EOKeyGlobalID.h>
#include <EOControl/EOFetchSpecification.h>
#include <OGoDocuments/SkyDocument.h>

/* implementation SkyPalmPreSync */
@implementation SkyPalmPreSync

+ (SkyPalmPreSync *)preSyncForPalmDataSource:(SkyPalmEntryDataSource *)_ds
                                    deviceId:(NSString *)_deviceId
{
  NSString       *palmDB;
  SkyPalmPreSync *preSync = nil;
  palmDB = [_ds palmDb];
  if      ([palmDB isEqualToString:@"AddressDB"])
    preSync = [SkyPalmAddressPreSync alloc];
  else if ([palmDB isEqualToString:@"DatebookDB"])
    preSync = [SkyPalmDatePreSync alloc];
  else if ([palmDB isEqualToString:@"MemoDB"])
    preSync = [SkyPalmMemoPreSync alloc];
  else if ([palmDB isEqualToString:@"ToDoDB"])
    preSync = [SkyPalmJobPreSync alloc];
  else {
    NSLog(@"WARNING[%s]: cannot init presync for unknown palm db: %@. "
          @"pre-sync bundle-loading isnot yet implemented.",
          __PRETTY_FUNCTION__, palmDB);
    preSync = nil;
  }
  return
    [[preSync initWithPalmDataSource:_ds andDeviceId:_deviceId] autorelease];
}

- (id)init {
  if ((self = [super init])) {
    self->allowPalmOverSkyrixSync = NO;
    self->allowSkyrixOverPalmSync = YES;
    self->doAutomaticInsert       = YES;
  }
  return self;
}
- (SkyPalmPreSync *)initWithPalmDataSource:(SkyPalmEntryDataSource *)_ds
                               andDeviceId:(NSString *)_deviceId
{
  if ((self = [self init])) {
    self->palmDataSource = [_ds       retain];
    self->deviceId       = [_deviceId retain];
  }
  return self;
}

- (void)dealloc {
  [self->palmDataSource   release];
  [self->deviceId         release];
  [self->progressDelegate release];
  [super dealloc];
}

- (int)defaultSkyrixSyncType {
  return SYNC_TYPE_TWO_WAY;
}

- (int)syncTypeForSkyrixRecord:(SkyDocument *)_skyRecord {
  return [self defaultSkyrixSyncType];
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

- (void)updateProgress:(double)_progress {
  [self->progressDelegate preSyncProgress:_progress];
}

- (BOOL)automaticInsert {
  NSArray *toInsert;
  NSArray *assignedIDs;
  unsigned int cnt;
  unsigned int i;
  SkyDocument   *skyrixEntry;
  EOKeyGlobalID *skyrixGID;
  id            skyrixId;

  toInsert    = [self fetchOGoEntriesToPreSync];
  assignedIDs =
    [self->palmDataSource assignedSkyrixIdsForDeviceId:[self deviceId]];

  //NSLog(@"%s got assigned ids: %@",
  //      __PRETTY_FUNCTION__, [assignedIDs componentsJoinedByString:@", "]);

  cnt = [toInsert count];
  for (i = 0; i < cnt; i++) {
    skyrixEntry = [toInsert objectAtIndex:i];
    skyrixGID   = (EOKeyGlobalID *)[skyrixEntry globalID];

    [self updateProgress:((double)i)/(double)cnt];
    
    if (skyrixGID != nil) {
      skyrixId = [skyrixGID keyValues][0];
      // check wether the skyrix entry is already assigned
      if (![assignedIDs containsObject:skyrixId]) {
        // skyrix entry is not yet assigned to palm
        SkyPalmDocument *newPalmEntry;

        //NSLog(@"%s: adding skyrix entry with id: %@",
        //      __PRETTY_FUNCTION__, skyrixId);

        // create a new palm entry
        newPalmEntry = [self->palmDataSource newDocument];
        [newPalmEntry setDeviceId:[self deviceId]];
        
        // assign the skyrix entry
        if (![self assignOGoEntry:skyrixEntry toPalmEntry:newPalmEntry]) {
          NSLog(@"%s: failed assigning skyrix to palm entry. "
                @"skyrix entry: %@ palm entry: %@",
                __PRETTY_FUNCTION__, skyrixEntry, newPalmEntry);
          return NO;
        }        
        [newPalmEntry setSyncType:[self syncTypeForSkyrixRecord:skyrixEntry]];
        
        // sync for the first time and save the new palm entry
        if ([newPalmEntry forceSkyrixOverPalmSync] == nil) {
          NSLog(@"%s: first time sync skyrix-over-palm failed. "
                @"skyrix entry: %@ palm entry: %@",
                __PRETTY_FUNCTION__, skyrixEntry, newPalmEntry);
          return NO;
        }
      }
    }
  }
  return YES;
}

- (EOFetchSpecification *)setFetchSkyrixRecordsFlag:(BOOL)_flag
   inFetchSpec:(EOFetchSpecification *)_fSpec
{
  EOFetchSpecification *fSpec;
  NSDictionary *hints;
  fSpec = [[_fSpec copy] autorelease];
  hints = [fSpec hints];

  if (hints == nil) {
    hints = 
      [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:_flag]
                    forKey:@"fetchSkyrixRecords"];
  }
  else {
    NSMutableDictionary *md;
    md = [[hints mutableCopy] autorelease];
    [md setObject:[NSNumber numberWithBool:_flag]
        forKey:@"fetchSkyrixRecords"];
    hints = md;
  }
  [fSpec setHints:hints];
  return fSpec;
}

- (BOOL)syncEntries {
  NSArray *palmEntries;  
  unsigned int cnt;
  unsigned int i;
  SkyPalmDocument *palmDoc;
  NSMutableArray *whereOgoHasChanged = nil;
  
  unsigned int syncAction;
  BOOL doSync;
  BOOL ogoEntryChanged;

  /* set fetch sky records flag */
  [self->palmDataSource setFetchSpecification:
       [self setFetchSkyrixRecordsFlag:YES
             inFetchSpec:[self->palmDataSource fetchSpecification]]];
  
  palmEntries = [self->palmDataSource fetchObjects];

  /* reset fetch sky records flag */
  [self->palmDataSource setFetchSpecification:
       [self setFetchSkyrixRecordsFlag:NO
             inFetchSpec:[self->palmDataSource fetchSpecification]]];
  
  cnt = [palmEntries count];
  for (i = 0; i < cnt; i++) {
    palmDoc    = [palmEntries objectAtIndex:i];
    doSync     = NO;
    ogoEntryChanged = NO;

    [self updateProgress:((double)i)/(double)cnt];
    
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
	    // skyrix-entry changed (in case of a two way sync)
	    ogoEntryChanged = YES;
            doSync = YES;
          break;
        case SYNC_TYPE_DO_NOTHING:
          // do-nothing doesn't sync anything. but modified-flags are reseted
          doSync = YES;
      }

      if (ogoEntryChanged && doSync) {
	if (whereOgoHasChanged == nil) {
	  NSString *key;

	  key = [NSString stringWithFormat:@"OGoPalm_%@_UpdatedInPreSyncIDs",
			  [self->palmDataSource palmDb]];
	  whereOgoHasChanged = [NSMutableArray array];
	  [[self->palmDataSource context]
	          takeValue:whereOgoHasChanged
	          forKey:key];

	}
	[whereOgoHasChanged addObject:
			    [NSNumber numberWithInt:[palmDoc palmId]]];
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

- (NSArray *)fetchOGoEntriesToPreSync {
  NSLog(@"ERROR[%s]: method not overwritten in subclass",
        __PRETTY_FUNCTION__);
  return nil;
}

/* the pre sync */
- (BOOL)preSync {
  BOOL result;
  /* (1) automatic insert */
  if ([self doAutomaticInsert]) {
    result = [self automaticInsert];
    if (!result) {
      NSLog(@"WARNING[%s]: automatic instert failed. "
            @"pre sync of table %@ wont continue.",
            __PRETTY_FUNCTION__, [self->palmDataSource palmDb]);
      return result;
    }
  }

  /* (2) sync existing palm entries */
  result = [self syncEntries];
  if (!result) {
    NSLog(@"WARNING[%s]: [%@] pre-syncing of palm entries failed. ",
          __PRETTY_FUNCTION__, [self->palmDataSource palmDb]);
    return result;
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

- (void)setProgressDelegate:(id)_delegate {
  ASSIGN(self->progressDelegate,_delegate);
}


- (NSString *)deviceId {
  return self->deviceId;
}

@end /* implementation SkyPalmPreSync */


#include <OGoPalm/SkyPalmAddressDocument.h>
#include <OGoContacts/SkyPersonDataSource.h>
#include <OGoContacts/SkyEnterpriseDataSource.h>
#include <EOControl/EOQualifier.h>
#include <EOControl/EOFetchSpecification.h>
#include <LSFoundation/LSCommandKeys.h>

/* implementation SkyPalmPreSync-subclasses */
@implementation SkyPalmAddressPreSync

- (void)dealloc {
  [self->preSyncMethod release];
  [super dealloc];
}


// overwriting assign method
- (BOOL)assignOGoEntry:(SkyDocument *)_ogoEntry
           toPalmEntry:(SkyPalmDocument *)_palmEntry
{
  SkyPalmAddressDocument *palmAddressDoc;
  NSString *skyrixType;
  EOKeyGlobalID *skyrixGID;
  
  if (![super assignOGoEntry:_ogoEntry toPalmEntry:_palmEntry])
    return NO;

  palmAddressDoc = (SkyPalmAddressDocument *)_palmEntry;
  
  skyrixGID  = (EOKeyGlobalID *)[_ogoEntry globalID];
  skyrixType = [skyrixGID entityName];

  // assign a person record
  if ([skyrixType isEqualToString:@"Person"]) {
    [palmAddressDoc setSkyrixType:@"person"];
  }

  // assign a enterprise record
  else if ([skyrixType isEqualToString:@"Enterprise"]) {
    [palmAddressDoc setSkyrixType:@"enterprise"];
  }
  
  else {
    NSLog(@"%s: unknown skyrix address entity: %@", skyrixType);
    return NO;
  }
  
  return YES;
}



- (NSString *)palmAddressPreSyncMethod {
  if (self->preSyncMethod == nil) {
    NSUserDefaults *ud;
    NSString       *method;

    ud = [[self->palmDataSource context] userDefaults];
    method = [ud stringForKey:@"SkyPalm_AddressPreSyncMethod"];
    method = [method length] ? method : (NSString *)@"sync_favorites";
    self->preSyncMethod = [method retain];
  }
  return self->preSyncMethod;
}

- (BOOL)syncWithFavorites {
  return [[self palmAddressPreSyncMethod]
                isEqualToString:@"sync_favorites"];
}
- (BOOL)syncWithOwnedContacts {
  return [[self palmAddressPreSyncMethod]
                isEqualToString:@"sync_owned_contacts"];
}
- (BOOL)dontSyncWithContacts {
  return [[self palmAddressPreSyncMethod]
                isEqualToString:@"sync_nothing"];
}

/* fetching favorites */
- (NSArray *)fetchFavoritePersons {
  SkyPersonDataSource  *personDS;
  NSArray              *favorites;
  EOQualifier          *qual;
  EOFetchSpecification *fSpec;
  id ctx;

  ctx      = [self->palmDataSource context];

  favorites = [[ctx userDefaults] objectForKey:@"person_favorites"];
  if (![favorites count])
    return [NSArray array];

  // build qualifier
  qual = [[EOKeyValueQualifier alloc]
                               initWithKey:@"companyId"
                               operatorSelector:EOQualifierOperatorEqual
                               value:favorites];
  fSpec = [[EOFetchSpecification alloc] init];
  [fSpec setQualifier:qual];

  personDS = [[SkyPersonDataSource alloc] initWithContext:ctx];
  [personDS setFetchSpecification:fSpec];

  // fetch 
  favorites = [personDS fetchObjects];
  
  [qual     release];
  [fSpec    release];
  [personDS release];

  return favorites;
}
- (NSArray *)fetchFavoriteEnterprises {
  SkyEnterpriseDataSource *enterpriseDS;
  NSArray                 *favorites;
  EOQualifier             *qual;
  EOFetchSpecification    *fSpec;
  id ctx;

  ctx      = [self->palmDataSource context];

  favorites = [[ctx userDefaults] objectForKey:@"enterprise_favorites"];
  if (![favorites count])
    return [NSArray array];

  // build qualifier
  qual = [[EOKeyValueQualifier alloc]
                               initWithKey:@"companyId"
                               operatorSelector:EOQualifierOperatorEqual
                               value:favorites];
  fSpec = [[EOFetchSpecification alloc] init];
  [fSpec setQualifier:qual];

  enterpriseDS = [[SkyEnterpriseDataSource alloc] initWithContext:ctx];
  [enterpriseDS setFetchSpecification:fSpec];

  // fetch 
  favorites = [enterpriseDS fetchObjects];
  
  [qual         release];
  [fSpec        release];
  [enterpriseDS release];

  return favorites;
}

- (NSArray *)fetchFavorites {
  NSMutableArray *contacts;
  NSArray *persons;
  NSArray *enterprises;

  persons     = [self fetchFavoritePersons];
  enterprises = [self fetchFavoriteEnterprises];

  contacts = [NSMutableArray arrayWithCapacity:
                             [persons count]+
                             [enterprises count]+
                             1];
  if ([persons count])
    [contacts addObjectsFromArray:persons];
  if ([enterprises count])
    [contacts addObjectsFromArray:enterprises];
  
  return contacts;
}

/* fetching owned contacts */
- (NSArray *)fetchOwnedPersons {
  SkyPersonDataSource  *personDS;
  NSArray              *persons;
  EOQualifier          *qual;
  EOFetchSpecification *fSpec;
  id ctx;
  id userId;

  ctx    = [self->palmDataSource context];
  userId = [[ctx valueForKey:LSAccountKey] valueForKey:@"companyId"];

  // build qualifier
  qual = [[EOKeyValueQualifier alloc]
                               initWithKey:@"ownerId"
                               operatorSelector:EOQualifierOperatorEqual
                               value:userId];
  fSpec =
    [EOFetchSpecification fetchSpecificationWithEntityName:@"Person"
                          qualifier:qual sortOrderings:nil];

  personDS = [[SkyPersonDataSource alloc] initWithContext:ctx];
  [personDS setFetchSpecification:fSpec];

  // fetch 
  persons = [personDS fetchObjects];

  [qual     release];
  [personDS autorelease];
  
  return persons;
}
- (NSArray *)fetchOwnedEnterprises {
  SkyEnterpriseDataSource *enterpriseDS;
  NSArray                 *enterprises;
  EOQualifier             *qual;
  EOFetchSpecification    *fSpec;
  id ctx;
  id userId;

  ctx    = [self->palmDataSource context];
  userId = [[ctx valueForKey:LSAccountKey] valueForKey:@"companyId"];

  // build qualifier
  qual = [[EOKeyValueQualifier alloc]
                               initWithKey:@"ownerId"
                               operatorSelector:EOQualifierOperatorEqual
                               value:userId];
  fSpec =
    [EOFetchSpecification fetchSpecificationWithEntityName:@"Enterprise"
                          qualifier:qual sortOrderings:nil];
  
  enterpriseDS = [[SkyEnterpriseDataSource alloc] initWithContext:ctx];
  [enterpriseDS setFetchSpecification:fSpec];

  // fetch 
  enterprises = [enterpriseDS fetchObjects];

  [qual         release];
  [enterpriseDS autorelease];

  return enterprises;
}
- (NSArray *)fetchOwnedContacts {
  NSMutableArray *contacts;
  NSArray *persons;
  NSArray *enterprises;

  persons     = [self fetchOwnedPersons];
  enterprises = [self fetchOwnedEnterprises];

  contacts = [NSMutableArray arrayWithCapacity:
                             [persons count]+
                             [enterprises count]+
                             1];
  if ([persons count])
    [contacts addObjectsFromArray:persons];
  if ([enterprises count])
    [contacts addObjectsFromArray:enterprises];
  
  return contacts;
}

- (NSArray *)fetchOGoEntriesToPreSync {
  if ([self syncWithFavorites]) {
    return [self fetchFavorites];
  }
  else if ([self syncWithOwnedContacts]) {
    return [self fetchOwnedContacts];
  }
  else if ([self dontSyncWithContacts]) {
    return [NSArray array];
  }
  else {
    NSLog(@"%s: unknown address preSync-method: %@",
          __PRETTY_FUNCTION__, [self palmAddressPreSyncMethod]);
  }
  return [NSArray array];
}

@end /* SkyPalmAddressPreSync */

#include <OGoScheduler/SkyAppointmentDocument.h>
#include <OGoScheduler/SkyAppointmentQualifier.h>
#include <OGoScheduler/SkyAppointmentDataSource.h>
#include <EOControl/EOSortOrdering.h>
#include <NGExtensions/EODataSource+NGExtensions.h>

@implementation SkyPalmDatePreSync

- (void)dealloc {
  [self->fetchPeriodStart release];
  [self->fetchPeriodEnd   release];
  [self->companiesToFetch release];
  [self->timeZone         release];
  [super dealloc];
}

- (int)syncTypeForSkyrixRecord:(SkyDocument *)_skyRecord {
  NSString *perm;
  perm = [(SkyAppointmentDocument *)_skyRecord permissions];
  return [perm indexOfString:@"e"] == NSNotFound
    ? /* not editable */ SYNC_TYPE_SKY_OVER_PALM
    : [self defaultSkyrixSyncType];
}

- (NSTimeZone *)timeZone {
  if (self->timeZone == nil) {    
    NSUserDefaults *ud;
    NSString       *abbrev;
    ud = [[self->palmDataSource context] userDefaults];

    abbrev = [ud objectForKey:@"timezone"];
  
    if (abbrev != nil)
      self->timeZone = [NSTimeZone timeZoneWithAbbreviation:abbrev];

    if (self->timeZone == nil)
      self->timeZone = [NSTimeZone timeZoneWithAbbreviation:@"MET"];

    self->timeZone = [self->timeZone retain];
  }
  return self->timeZone;
}
- (int)distancePast {
  return [[[self->palmDataSource
                context]
                userDefaults]
                integerForKey:@"SkyPalm_DatePreSync_daysPast"];
}
- (int)distanceFuture {
  return [[[self->palmDataSource
                context]
                userDefaults]
                integerForKey:@"SkyPalm_DatePreSync_daysFuture"];
}

- (NSCalendarDate *)fetchPeriodStart {
  if (self->fetchPeriodStart == nil) {
    NSCalendarDate *now;
    int distPast;

    distPast = [self distancePast];
    if (distPast <= 0) distPast = 10;
    
    now = [NSCalendarDate date];
    [now setTimeZone:[self timeZone]];
    self->fetchPeriodStart =
      [[now dateByAddingYears:0 months:0 days:-distPast
            hours:0 minutes:0 seconds:0] retain];
  }
  return self->fetchPeriodStart;
}
- (NSCalendarDate *)fetchPeriodEnd {
  if (self->fetchPeriodEnd == nil) {
    NSCalendarDate *now;
    int distFuture;

    distFuture = [self distanceFuture];
    if (distFuture <= 0) distFuture = 10;
    
    now = [NSCalendarDate date];
    [now setTimeZone:[self timeZone]];
    self->fetchPeriodEnd =
      [[now dateByAddingYears:0 months:0 days:distFuture
            hours:0 minutes:0 seconds:0] retain];
  }
  return self->fetchPeriodEnd;
}

- (NSArray *)_buildGIDsForIds:(NSArray *)_ids
               withEntityName:(NSString *)_eName
{
  NSMutableArray *ma;
  unsigned int i, cnt;
  id gid;
  cnt = [_ids count];
  ma  = [NSMutableArray arrayWithCapacity:cnt+1];
  for (i = 0; i < cnt; i++) {
    gid = [_ids objectAtIndex:i];
    gid = [EOKeyGlobalID globalIDWithEntityName:_eName
                         keys:&gid keyCount:1 zone:nil];
    [ma addObject:gid];
  }
  return ma;
}

- (NSArray *)companyGIDsToFetch {
  if (self->companiesToFetch == nil) {
    id ctx;
    NSUserDefaults *ud;
    NSArray *teamsToFetch;
    NSArray *personsToFetch;

    ctx = [self->palmDataSource context];
    ud  = [ctx userDefaults];
    teamsToFetch   = [ud arrayForKey:@"SkyPalm_DatePreSync_fetchTeams"];
    if (teamsToFetch == nil)   teamsToFetch   = [NSArray array];
    personsToFetch = [ud arrayForKey:@"SkyPalm_DatePreSync_fetchPersons"];
    if (personsToFetch == nil) personsToFetch = [NSArray array];

    personsToFetch =
      [personsToFetch arrayByAddingObject:
                      [[ctx valueForKey:LSAccountKey]
                            valueForKey:@"companyId"]];

    teamsToFetch =
      [self _buildGIDsForIds:teamsToFetch   withEntityName:@"Team"];
    personsToFetch =
      [self _buildGIDsForIds:personsToFetch withEntityName:@"Person"];

    if (teamsToFetch == nil)   teamsToFetch   = [NSArray array];
    if (personsToFetch == nil) personsToFetch = [NSArray array];

    self->companiesToFetch =
      [[teamsToFetch arrayByAddingObjectsFromArray:personsToFetch] retain];
  }
  //NSLog(@"%s: Fetching company gids: %@", __PRETTY_FUNCTION__,
  //      self->companiesToFetch);
  return self->companiesToFetch;
}


/* building datasource/qualifier/fetchspec */
- (SkyAppointmentQualifier *)_qualifierFrom:(NSCalendarDate *)_from
                                         to:(NSCalendarDate *)_to
{
  SkyAppointmentQualifier *qual = nil;
  qual = [[SkyAppointmentQualifier alloc] init];
  [qual setStartDate:_from];
  [qual setEndDate:_to];
  [qual setTimeZone:[self timeZone]];
  [qual setCompanies:[self companyGIDsToFetch]];
  [qual setResources:[NSArray array]];
  return [qual autorelease];
}
- (NSArray *)_attributesWanted {
  return [NSArray arrayWithObjects:
                  @"dateId", @"parentDateId", @"startDate",
                  @"endDate", @"cycleEndDate", @"type", @"aptType", 
                  @"title", @"globalID", @"permissions",
                  @"participants.login", @"comment",
                  @"location", @"accessTeamId", @"writeAccessList",
                  nil];
}
- (NSArray *)_sortOrderings {
  return [NSArray arrayWithObject:
                  [EOSortOrdering sortOrderingWithKey:@"startDate"
                                  selector:EOCompareAscending]];
}
- (NSDictionary *)_hints {
  return [NSDictionary dictionaryWithObjectsAndKeys:
                       [self _attributesWanted],      @"attributes",
                       nil];
}
- (EOFetchSpecification *)_fetchSpecFrom:(NSCalendarDate *)_from
                                      to:(NSCalendarDate *)_to
{
  EOFetchSpecification *fspec =
    [EOFetchSpecification fetchSpecificationWithEntityName:@"Date"
                          qualifier:[self _qualifierFrom:_from to:_to]
                          sortOrderings:[self _sortOrderings]];
  [fspec setHints:[self _hints]];
  return fspec;
}
- (LSCommandContext *)_commandContext {
  return [self->palmDataSource context];
}
- (SkyAppointmentDataSource *)_dataSourceFrom:(NSCalendarDate *)_from
                                           to:(NSCalendarDate *)_to
{
  SkyAppointmentDataSource *das;
  das = [(SkyAppointmentDataSource *)[SkyAppointmentDataSource alloc]
                                     initWithContext:[self _commandContext]];
  [das setFetchSpecification:[self _fetchSpecFrom:_from to:_to]];

  return AUTORELEASE(das);
}
- (NSArray *)_searchAptsFrom:(NSCalendarDate *)_from
                          to:(NSCalendarDate *)_to
{
  SkyAppointmentDataSource *das = [self _dataSourceFrom:_from to:_to];
  NSEnumerator             *e   = [[das fetchObjects] objectEnumerator];
  id                       one;
  NSMutableArray           *ma  = [NSMutableArray array];
  NSString                 *perms;

  while ((one = [e nextObject])) {
    perms = [one valueForKey:@"permissions"];
    if (([[one valueForKey:@"title"] length]) ||  // can see title --> allowed
        ((perms) && ([perms indexOfString:@"v"] != NSNotFound)) ||
        ([[one valueForKey:@"isViewAllowed"] boolValue]))
      [ma addObject:one];
  }
  one = [ma copy];
  return AUTORELEASE(one);
}

- (BOOL)doImportOGoDates {
  NSUserDefaults *ud;
  BOOL doInsert = NO;
  ud = [[self->palmDataSource context] userDefaults];
  doInsert = [ud boolForKey:@"SkyPalm_DatesImportOGoData"];
  return doInsert;
}

- (NSArray *)filterCycleDates:(NSArray *)_src {
  NSMutableArray *filtered;
  NSMutableArray *repIds;
  NSEnumerator   *e;
  id             one;
  NSNumber       *parentDateId;

  e        = [_src objectEnumerator];
  filtered = [NSMutableArray array];
  repIds   = [NSMutableArray array];
  
  while ((one = [e nextObject])) {
    if ([one hasParentDate]) 
      parentDateId = [one parentDateId];    
    else
      parentDateId = [one valueForKey:@"dateId"];
    if (parentDateId == nil)
      parentDateId =
        [(EOKeyGlobalID *)[one valueForKey:@"globalID"] keyValues][0];
    
    if ([repIds containsObject:parentDateId]) continue;
    [repIds addObject:parentDateId];
    [filtered addObject:one];
  }
  return filtered;
}

- (NSArray *)fetchOGoEntriesToPreSync {
  if ([self doImportOGoDates]) {
    NSArray *result;
    result = [self _searchAptsFrom:[self fetchPeriodStart]
		   to:[self fetchPeriodEnd]];
    result = [self filterCycleDates:result];
    return result;
  }
  return [NSArray array];
}

@end /* SkyPalmDatePreSync */

@implementation SkyPalmMemoPreSync
- (NSArray *)fetchOGoEntriesToPreSync {
  // TODO: do something
  return [NSArray array];
}
@end /* SkyPalmMemoPreSync */

@implementation SkyPalmJobPreSync
- (NSArray *)fetchOGoEntriesToPreSync {
  // TODO: do something
  return [NSArray array];
}
@end /* SkyPalmJobPreSync */
