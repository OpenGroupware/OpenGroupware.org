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

#include <OGoPalm/SkyPalmDocument.h>
#include <OGoPalm/SkyPalmDocumentDataSource.h>
#include <OGoPalm/SkyPalmConstants.h>
#include <OGoPalm/SkyPalmEntryDataSource.h>
#include <OGoPalm/NGMD5Generator.h>
#include <OGoPalm/SkyPalmCategoryDocument.h>

@implementation SkyPalmDocument

- (id)init {
  if ((self = [super init])) {
    self->skyrixRecord = nil;
    self->globalID     = nil;
    self->category     = nil;
    self->skyrixId     = nil;
    self->isObserving  = NO;
    self->reloadSkyrixRecord = NO;
  }
  return self;
}

- (id)initWithDictionary:(NSDictionary *)_src
          fromDataSource:(SkyPalmDocumentDataSource *)_ds
{
  if ((self = [self init])) {
    [self _setSource:_src];
    [self _setDataSource:_ds];
    self->isSaved = (self->isNewRecord) ? NO : YES;
    if (self->isNewRecord)
      [self prepareAsNew];
  }
  return self;
}

// values of dictionary not checked
// values must be valid for a new record
- (id)initAsNewFromDictionary:(NSDictionary *)_src
               fromDataSource:(SkyPalmDocumentDataSource *)_ds
{
  if ((self = [self initWithDictionary:_src fromDataSource:_ds])) {
    self->isNewRecord = YES;
    self->isSaved     = NO;
  }
  return self;
}

- (id)initAsNewFromDataSource:(SkyPalmDocumentDataSource *)_ds
{
  return [self initWithDictionary:[NSDictionary dictionary]
               fromDataSource:_ds];
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  if (self->isObserving)
    [self _stopObserving];
  RELEASE(self->source);
  RELEASE(self->dataSource);
  
  RELEASE(self->categoryId);
  RELEASE(self->deviceId);
  RELEASE(self->md5Hash);
  RELEASE(self->globalID);
  RELEASE(self->skyrixId);
  RELEASE(self->skyrixRecord);
  RELEASE(self->category);
  [super dealloc];
}
#endif

// updating source
- (void)updateSource:(NSDictionary *)_src
      fromDataSource:(SkyPalmDocumentDataSource *)_ds
{
  if (_ds == self->dataSource)
    [self _setSource:_src];
  else {
    // _ds has no access to modifie document
  }
}

// value accessors
- (void)setCategoryId:(NSNumber *)_catId {
  ASSIGN(self->categoryId,_catId);
}
- (NSNumber *)categoryId {
  return self->categoryId;
}
- (void)setDeviceId:(NSString *)_devId {
  ASSIGN(self->deviceId,_devId);
}
- (NSString *)deviceId {
  return self->deviceId;
}
- (void)setIsDeleted:(BOOL)_flag {
  self->isDeleted = _flag;
}
- (BOOL)isDeleted {
  return self->isDeleted;
}
- (void)setIsNew:(BOOL)_flag {
  self->isNew = _flag;
}
- (BOOL)isNew {
  return self->isNew;
}
- (void)setIsArchived:(BOOL)_flag {
  self->isArchived = _flag;
}
- (BOOL)isArchived {
  return self->isArchived;
}
- (void)setIsModified:(BOOL)_flag {
  self->isModified = _flag;
}
- (BOOL)isModified {
  return self->isModified;
}
- (void)setIsPrivate:(BOOL)_flag {
  self->isPrivate = _flag;
}
- (BOOL)isPrivate {
  return self->isPrivate;
}
- (void)setMd5Hash:(NSString *)_hash {
  ASSIGN(self->md5Hash,_hash);
}
- (NSString *)md5Hash {
  return self->md5Hash;
}

- (void)setPalmId:(int)_pId {
  self->palmId = _pId;
}
- (int)palmId {
  return self->palmId;
}

- (int)objectVersion {
  return self->objectVersion;
}
- (void)increaseObjectVersion {
  self->objectVersion++;
}

- (void)setCategory:(SkyPalmCategoryDocument *)_doc {
  [self setCategoryId:[NSNumber numberWithInt:[_doc categoryIndex]]];
  ASSIGN(self->category,_doc);
}
- (SkyPalmCategoryDocument *)category {
  return self->category;
}

// additional
// changes won't be saved by category name
// --> change categoryId
- (NSString *)categoryName {
  return (self->category != nil)
    ? [self->category categoryName]
    : @"";
}

- (BOOL)isEditable {
  if ([self isArchived])
    return NO;
  return ([self isDeleted]) ? NO : YES;
}
- (BOOL)isDeletable {
  return [self isEditable];
}
- (BOOL)isUndeletable {
  if ([self isArchived])
    return NO;
  return [self isDeleted];
}

- (id)globalID {
  return self->globalID;
}
- (NSString *)description {
  // overwrite in subclasses
  return [NSString stringWithFormat:@"<SkyPalmDocument> %@",
                   [self globalID]];
}
- (NSString *)syncState {
  if (([self isNew]) ||
      ([self palmId] == 0))
    return @"is_new";
  if ([self isDeleted])
    return @"is_deleted";
  if ([self isModified])
    return @"is_modified";
  if ([self isArchived])
    return @"is_archived";
  return @"is_untouched";
}


- (NSNumber *)companyId {
  return [self->dataSource companyId];
}
- (NSString *)primaryKey {
  return [self->dataSource primaryKey];
}
- (BOOL)isNewRecord {
  return self->isNewRecord;
}
- (NSArray *)devices { // possible devices
  return [self->dataSource devices];
}
- (NSArray *)categories { // possible categories for current device
  return [self->dataSource categoriesForDevice:[self deviceId]];
}

- (NSString *)generateMD5Hash {
  NGMD5Generator *generator = nil;
  NSString       *src       = nil;
  NSString       *digest    = nil;

  generator = [[NGMD5Generator alloc] init];
  src       = [self _md5Source];
  [generator encodeData:[src dataUsingEncoding:NSUTF8StringEncoding]];
  digest    = [generator digestAsString];

  RELEASE(generator);
  return digest;
}

- (void)takeValuesFromDictionary:(NSDictionary *)_dict {
  // overwrite it in subclasses with call of super method
  [self setCategoryId:[_dict valueForKey:@"category_index"]];
  [self setDeviceId:  [_dict valueForKey:@"device_id"]];
  [self setIsDeleted: [[_dict valueForKey:@"is_deleted"] boolValue]];
  [self setIsNew:     [[_dict valueForKey:@"is_new"] boolValue]];
  [self setIsArchived:[[_dict valueForKey:@"is_archived"] boolValue]];
  [self setIsModified:[[_dict valueForKey:@"is_modified"] boolValue]];
  [self setIsPrivate: [[_dict valueForKey:@"is_private"] boolValue]];
  [self setSkyrixId:  [_dict valueForKey:@"skyrix_id"]];
  [self setSyncType:  [[_dict valueForKey:@"skyrix_sync"] intValue]];
  [self setSkyrixVersion: [[_dict valueForKey:@"skyrix_version"] intValue]];
  [self setSkyrixPalmVersion:
        [[_dict valueForKey:@"skyrix_palm_version"] intValue]];
  [self setMd5Hash:   [_dict valueForKey:@"md5hash"]];
  [self setPalmId:    [[_dict valueForKey:@"palm_id"] intValue]];

  self->objectVersion =
    [[_dict valueForKey:@"object_version"] intValue];
  self->skyrixPalmVersion =
    [[_dict valueForKey:@"skyrix_palm_version"] intValue];

  // no global id overwriting
  if (self->globalID == nil) {
    self->globalID = [_dict valueForKey:@"globalID"];
    RETAIN(self->globalID);
  }
  self->isNewRecord = ([self globalID] == nil)
    ? YES : NO;
}
- (NSMutableDictionary *)asDictionary {
  // overwrite in subclasses with call of super method
  NSMutableDictionary *dict = [self->source mutableCopy];

  if (self->isNewRecord)
    [dict removeObjectForKey:@"globalID"];
  else
    [self _takeValue:self->globalID
          forKey:@"globalID" toDict:dict];
  [self _takeValue:self->categoryId
        forKey:@"category_index" toDict:dict];
  [self _takeValue:self->deviceId
        forKey:@"device_id" toDict:dict];
  [self _takeValue:[NSNumber numberWithBool:self->isDeleted]
        forKey:@"is_deleted" toDict:dict];
  [self _takeValue:[NSNumber numberWithBool:self->isNew]
        forKey:@"is_new" toDict:dict];
  [self _takeValue:[NSNumber numberWithBool:self->isArchived]
        forKey:@"is_archived" toDict:dict];
  [self _takeValue:[NSNumber numberWithBool:self->isModified]
        forKey:@"is_modified" toDict:dict];
  [self _takeValue:[NSNumber numberWithBool:self->isPrivate]
        forKey:@"is_private" toDict:dict];
  [self _takeValue:self->skyrixId
        forKey:@"skyrix_id" toDict:dict];
  [self _takeValue:[NSNumber numberWithInt:self->syncType]
        forKey:@"skyrix_sync" toDict:dict];
  [self _takeValue:[NSNumber numberWithInt:self->skyrixVersion]
        forKey:@"skyrix_version" toDict:dict];
  [self _takeValue:[NSNumber numberWithInt:self->skyrixPalmVersion]
        forKey:@"skyrix_palm_version" toDict:dict];
  [self _takeValue:[self md5Hash]
        forKey:@"md5hash" toDict:dict];
  [self _takeValue:[NSNumber numberWithInt:self->palmId]
        forKey:@"palm_id" toDict:dict];
  [self _takeValue:[NSNumber numberWithInt:self->objectVersion]
        forKey:@"object_version" toDict:dict];
  
  return AUTORELEASE(dict);
}
- (void)resetFlags {
  // normaly called before save
  if (self->isNewRecord) {
    [self setIsNew:YES];
    [self setIsDeleted:NO];
    [self setIsArchived:NO];
    [self setIsModified:NO];
    [self setMd5Hash:@" "];
  }
  else {
    [self setIsModified:YES];
  }
}

// actions
- (id)saveWithoutReset {
  NSString *notiName;
  if (self->isNewRecord) {
    [self->dataSource insertObject:self];
    notiName = [self insertNotificationName];
    self->isNewRecord = NO;
  }
  else {
    [self->dataSource updateObject:self];
    notiName = [self updateNotificationName];
  }
  self->isSaved = YES;
  [[NSNotificationCenter defaultCenter]
                         postNotificationName:notiName
                         object:self];
  return self;
}

- (id)save {
  [self resetFlags];
  [self increaseObjectVersion];
  return [self saveWithoutReset];
}

- (id)revert {
  [self takeValuesFromDictionary:self->source];
  self->isSaved = (self->isNewRecord) ? NO : YES;
  if (self->isNewRecord)
    [self prepareAsNew];
  return self;
}

- (id)realyDelete {
  [self->dataSource deleteObject:self];
  [[NSNotificationCenter defaultCenter]
                         postNotificationName:[self deleteNotificationName]
                         object:self];
  self->isNewRecord = YES;
  return nil;
}
- (id)delete {
  if (![self isDeletable])
    return [NSString stringWithFormat:
                     @"Document '%@' not deletable in this state",
                     [self description]];
  
  if ([self palmId] == 0) {
    return [self realyDelete];
  }

  [self setIsDeleted:YES];
  self->isSaved = NO;
  return [self saveWithoutReset];
}

- (id)undelete {
  if (![self isUndeletable])
    return [NSString stringWithFormat:
                     @"Document '%@' not undeletable in this state",
                     [self description]];

  [self setIsDeleted:NO];
  self->isSaved = NO;
  return [self save];
}

// reload
- (id)reload {
  [self _setSource:[self->dataSource fetchDictionaryForDocument:self]];
  return nil;
}

// for skyPalmEntryDS
- (id)context {
  return [(SkyPalmEntryDataSource *)self->dataSource context];
}

// sync with other records
- (void)takeValuesFromDocument:(SkyPalmDocument *)_doc {
  [self setCategoryId:[_doc categoryId]];
  [self setDeviceId:  [_doc deviceId]];
  [self setIsPrivate: [_doc isPrivate]];
  [self setPalmId:    [_doc palmId]];

  [self setIsNew:     [_doc isNew]];
  [self setIsModified:[_doc isModified]];
  //  [self setMd5Hash:   [_doc md5hash]];
}

@end /* SkyPalmDocument */

@implementation SkyPalmDocument(PrivatMethods)

// accessors
- (void)_setSource:(NSDictionary *)_src {
  ASSIGN(self->source,_src);
  if ([[_src allKeys] count] != 0) {
    [self takeValuesFromDictionary:_src];
  }
  else 
    self->isNewRecord = YES;
}
- (void)_setDataSource:(SkyPalmDocumentDataSource *)_ds {
  ASSIGN(self->dataSource,_ds);
}

- (void)prepareAsNew {
  // overwrite in subclass with call of super method
  NSArray *devices = [self devices];

  if ((devices == nil) || ([devices count] == 0)) {
    if ([self->dataSource defaultDevice] != nil)
      devices = [NSArray arrayWithObject:[self->dataSource defaultDevice]];
  }
  
  if ((devices == nil) || ([devices count] == 0))
    //    [NSException raise:@"No vailid devices found in database"
    //                 format:@"Cannot prepare Document %@ as new", self];
    [self setDeviceId:nil];
  else
    [self setDeviceId:[devices objectAtIndex:0]];
  
  [self setCategoryId:[NSNumber numberWithInt:0]];
  [self setSkyrixId:[NSNumber numberWithInt:0]];
  [self setSyncType:SYNC_TYPE_DO_NOTHING];
  [self setSkyrixVersion:0];
  [self setSkyrixPalmVersion:0];
  [self setIsPrivate:NO];
  [self setPalmId:0];
  self->objectVersion = 0;
  
  [self resetFlags];
}

- (void)clearGlobalID {
  RELEASE(self->globalID);  self->globalID = nil;
}

- (NSString *)insertNotificationName {
  NSLog(@"%s not overwritten!!", __PRETTY_FUNCTION__);
  return nil;
}
- (NSString *)updateNotificationName {
  NSLog(@"%s not overwritten!!", __PRETTY_FUNCTION__);
  return nil;
}
- (NSString *)deleteNotificationName {
  NSLog(@"%s not overwritten!!", __PRETTY_FUNCTION__);
  return nil;
}

// methods
- (BOOL)hasValueChanged:(id)_val forKey:(id)_key {
  return ([_val isEqual:[self->source valueForKey:_key]])
    ? NO : YES;
}
- (BOOL)haveValuesChanged {
  // overwrite in subclasses if neccessary
  return (self->isSaved) ? NO : YES;
}
- (void)takeValue:(id)_val forKey:(id)_key {
  id old = [self valueForKey:_key];
  if (![old isEqual:_val]) {
    [super takeValue:_val forKey:_key];
    self->isSaved = NO;
  }
}

// overwrite and append string of super call
- (NSMutableString *)_md5Source {
  NSMutableString *src = [NSMutableString stringWithCapacity:32];

  [src appendString:[[NSNumber numberWithInt:[self palmId]] stringValue]];
  [src appendString:[[self categoryId] stringValue]];
  [src appendString:[[NSNumber numberWithBool:[self isDeleted]] stringValue]];
  [src appendString:[[NSNumber numberWithBool:[self isArchived]] stringValue]];
  [src appendString:[[NSNumber numberWithBool:[self isNew]] stringValue]];
  [src appendString:[[NSNumber numberWithBool:[self isPrivate]] stringValue]];

  return src;
}

- (void)_takeValue:(id)_val forKey:(id)_key
            toDict:(NSMutableDictionary *)_dict {
  if (_key == nil)
    return;
  if (_val == nil)
    [_dict removeObjectForKey:_key];
  else
    [_dict setObject:_val forKey:_key];
}

// comparing

- (BOOL)isEqual:(id)_other {
  if (_other == self)
    return YES;
  if (![_other isKindOfClass:[self class]])
    return NO;
  if (![[_other globalID] isEqual:[self globalID]])
    return NO;
  return YES;
}

@end /* SkyPalmDocument(PrivatMethods) */

#include <OGoJobs/SkyPersonJobDataSource.h>
#include <OGoJobs/SkyJobDocument.h>
#include <EOControl/EOKeyGlobalID.h>
#include <LSFoundation/OGoObjectLinkManager.h>
#include <LSFoundation/OGoObjectLink.h>
#include <NGExtensions/NSCalendarDate+misc.h>

@implementation SkyPalmDocument(SkyrixSync)

- (BOOL)syncPalmOverSkyrix {
  [self putValuesToSkyrixRecord:[self skyrixRecord]];
  [self saveSkyrixRecord];
  [self updateSkyrixVersions];
  return YES;
}
- (BOOL)syncSkyrixOverPalm {
  [self updateSkyrixVersions];
  [self takeValuesFromSkyrixRecord:[self skyrixRecord]];
  [self setIsModified:YES];
  return YES;
}
- (BOOL)syncDoNothing {
  [self updateSkyrixVersions];
  return YES;
}

- (int)skyrixSyncConflictHandling {
  // TODO: make this editable via defaults
  return [[[self context] userDefaults]
                 integerForKey:@"ogopalm_ogo_conflict_handling"];
  //return SYNC_SKYRIX_CONFLICT_CREATE_NEW_OGO;
}

- (int)skyrixSyncConflictNotification {
  // TODO: make this editable via defaults
  return [[[self context] userDefaults]
                 integerForKey:@"ogopalm_ogo_conflict_notification"];
  //return SYNC_SKYRIX_CONFLICT_NOTIFY_TASK;
}

- (id)createSkyrixRecordCopy {
  NSLog(@"WARNING! %s not overwritten in subclass %@",
        __PRETTY_FUNCTION__, NSStringFromClass([self class]));
  return nil;
}

- (BOOL)createNewSkyrixRecordForConflict {
  /*
    // (1) create a new skyrix record
    // (2) set sync type to 'two-way'
    // (3) assign the new skyrix record to this palm record
    // (4) force a first sync 'palm-to-skyrix'
    // (5) save sync state
   */

  /* (1) new skyrix record */
  id newSkyRecord;

  newSkyRecord = [self createSkyrixRecordCopy];
  if (newSkyRecord == nil) {
    // failed to create new skyrix record
    NSLog(@"%s: failed to create new skyrix record", __PRETTY_FUNCTION__);
    return NO;
  }

  /* (2) 'two-way' sync */
  [self setSyncType:SYNC_TYPE_TWO_WAY];
  /* (3) 'assign this new record' */
  {
    id skyId;
    skyId = [newSkyRecord globalID];
    skyId = [skyId keyValues][0];
    [self setSkyrixId:skyId];
  }
  /* (4) force 'palm-over-skyrix' */
  [self forcePalmOverSkyrixSync];

  /* (5) save sync state */
  [self updateSkyrixVersions];
  // return, that we need a save
  return YES;
}

- (NSString *)label_notifyConflict {
  return [NSString stringWithFormat:
                   @"conflict occured during palm sync (%@: %@)",
                   [self->dataSource palmDb], self];
}
- (NSString *)label_notifyConflictAndNewRecord {
  return [NSString stringWithFormat:
                   @"conflict occured during palm sync (%@: %@). "
                   @"new record created",
                   [self->dataSource palmDb], self];
}
- (NSString *)label_notifyConflictWithPalmOverOGo {
  return [NSString stringWithFormat:
                   @"conflict occured during palm sync (%@: %@). "
                   @"OGo changes overwriten",
                   [self->dataSource palmDb], self];
}
- (NSString *)label_notifyConflictWithOGoOverPalm {
  return [NSString stringWithFormat:
                   @"conflict occured during palm sync (%@: %@). "
                   @"Palm changes overwriten",
                   [self->dataSource palmDb], self];
}

- (NSString *)label_conflictTaskComment {
  return @"";
}

- (void)createTaskForSyncConflict:(int)_handlingType
                      oldSkyrixId:(id)_oldSkyrixRecordId
                      newSkyrixId:(id)_newSkyrixRecordId
{
  /*
    steps:
    (1) create a task title depending on handling type
    (2) create task
    (3) bind records depending on handling type to task
  */
  NSString *title   = @"Conflict occured during Palm-Sync";
  NSString *comment = @"";
  SkyJobDocument *task = nil;

  /* (1) task title */
  comment = [self label_conflictTaskComment];
  switch (_handlingType) {
    case (SYNC_SKYRIX_CONFLICT_DO_NOTHING):
      // just notify
      title = [self label_notifyConflict];
      break;
    case (SYNC_SKYRIX_CONFLICT_CREATE_NEW_OGO):
      title = [self label_notifyConflictAndNewRecord];
      break;
    case (SYNC_SKYRIX_CONFLICT_FORCEPALMOVEROGO):
      title = [self label_notifyConflictWithPalmOverOGo];
      break;
    case (SYNC_SKYRIX_CONFLICT_FORCEOGOOVERPALM):
      title = [self label_notifyConflictWithOGoOverPalm];
      break;
  }

  /* (2) create task */
  {
    EOGlobalID *accountId;
    SkyPersonJobDataSource *ds;
    NSCalendarDate *start;

    accountId = [[self->dataSource currentAccount] valueForKey:@"globalID"];
    ds =
      [[SkyPersonJobDataSource alloc] initWithContext:[self context]
                                      personId:accountId];
    task  = [ds createObject];
    start = [[NSCalendarDate date] beginOfDay];
    [task setName:title];
    [task setStatus:@"20_processing"];
    [task setStartDate:start];
    [task setEndDate:[start tomorrow]];
    if ([comment length])
      [task setCreateComment:comment];
    [task save];
  }
  /* (3) bind records */

  {
    NSString      *palmLinkLabel;
    NSString      *oldOgoLinkLabel;
    NSString      *newOgoLinkLabel;
    OGoObjectLink *pdaLink    = nil;
    OGoObjectLink *oldOGoLink = nil;
    OGoObjectLink *newOGoLink = nil;

    OGoObjectLinkManager *lm;
    
    palmLinkLabel = [NSString stringWithFormat:@"Conflicting Palm Entry: %@",
                              self];
    oldOgoLinkLabel = @"Conflicting OGo Entry";
    newOgoLinkLabel = @"New OGo Entry";
  
    pdaLink =
      [[OGoObjectLink alloc] initWithSource:(EOKeyGlobalID *)[task globalID]
                             target:[self globalID]
                             type:@"pda_conflicting_palm_entry"
                             label:palmLinkLabel];
    oldOGoLink = 
      [[OGoObjectLink alloc] initWithSource:(EOKeyGlobalID *)[task globalID]
                             target:_oldSkyrixRecordId
                             type:@"pda_conflicting_ogo_entry"
                             label:oldOgoLinkLabel];
    if (![_oldSkyrixRecordId isEqual:_newSkyrixRecordId]) {
      newOGoLink = 
        [[OGoObjectLink alloc] initWithSource:(EOKeyGlobalID *)[task globalID]
                               target:_newSkyrixRecordId
                               type:@"pda_new_ogo_entry"
                               label:newOgoLinkLabel];
    }

    lm = [[OGoObjectLinkManager alloc] initWithContext:[self context]];
    if (pdaLink    != nil) [lm createLink:pdaLink];
    if (oldOGoLink != nil) [lm createLink:oldOGoLink];
    if (newOGoLink != nil) [lm createLink:newOGoLink];

    [lm release];
    [pdaLink release];
    [oldOGoLink release];
    [newOGoLink release];
  }
}

- (BOOL)handleSkyrixSyncConflict {
  // both records (palm and skyrix) changed
  /*
    possibilities:
    (1)  do nothing ;)
    (2)  create new skyrix record and link with this

    notification:
    - create a task and link all the involced records via obj_link
  */
  int handlingType;
  int conflictNotify;
  BOOL needASave = NO;
  id newSkyrixRecordId = nil;
  id oldSkyrixRecordId = nil;

  handlingType   = [self skyrixSyncConflictHandling];
  conflictNotify = [self skyrixSyncConflictNotification];

  oldSkyrixRecordId = [[[[self skyrixRecord] globalID] copy] autorelease];  

  switch (handlingType) {
    case SYNC_SKYRIX_CONFLICT_DO_NOTHING:
      // yes, realy do nothing ;)
      needASave = NO;
      break;
    case SYNC_SKYRIX_CONFLICT_CREATE_NEW_OGO:
      // create a new skyrix record
      needASave = [self createNewSkyrixRecordForConflict];
      break;
    case SYNC_SKYRIX_CONFLICT_FORCEPALMOVEROGO:
      // force palm over ogo
      needASave = [self syncPalmOverSkyrix];
      break;
    case SYNC_SKYRIX_CONFLICT_FORCEOGOOVERPALM:
      // force ogo over palm
      needASave = [self syncSkyrixOverPalm];
      break;
  }

  newSkyrixRecordId = [[[[self skyrixRecord] globalID] copy] autorelease];

  switch (conflictNotify) {
    case SYNC_SKYRIX_CONFLICT_NOTIFY_TASK:
      // create a task to notify the user
      [self createTaskForSyncConflict:handlingType
            oldSkyrixId:oldSkyrixRecordId
            newSkyrixId:newSkyrixRecordId];
      break;
  }

  return needASave;
}

- (BOOL)syncTwoWay {
  /*
    modified over unmodified
  */
  int syncState;

  syncState = [self skyrixSyncState];
  switch (syncState) {
    case SYNC_STATE_NOTHING_CHANGED:
      // do nothing
      return NO;
      break;
    case SYNC_STATE_PALM_CHANGED:
      return [self syncPalmOverSkyrix];
      break;
    case SYNC_STATE_SKYRIX_CHANGED:
      return [self syncSkyrixOverPalm];
      break;
    case SYNC_STATE_BOTH_CHANGED:
      // conflict handling
      return [self handleSkyrixSyncConflict];
    case SYNC_STATE_NEVER_SYNCED:
      // hmm, we got a problem
      NSLog(@"%s: [%@]: records have never been synced before. "
            @"sync-versions will be reseted anyway.",
            __PRETTY_FUNCTION__, self);
      return [self syncDoNothing];
      break;
  }
  return NO;
}

- (id)syncWithSkyrixRecord {
  BOOL save = NO;
  switch (self->syncType) {
    case SYNC_TYPE_DO_NOTHING:
      save = [self syncDoNothing]; 
      break;
    case SYNC_TYPE_SKY_OVER_PALM:
      save = [self syncSkyrixOverPalm];
      break;
    case SYNC_TYPE_PALM_OVER_SKY:
      save = [self syncPalmOverSkyrix];
      break;
    case SYNC_TYPE_TWO_WAY:
      save = [self syncTwoWay];
      break;
  }
  return save ? [self saveWithoutReset] : self;
}

- (int)actualSkyrixSyncAction {
  /* this method says roughly what a syncWithSkyrixRecord would do
     result of this method may be:
       SYNC_TYPE_DO_NOTHING
       SYNC_TYPE_SKY_OVER_PALM
       SYNC_TYPE_PALM_OVER_SKY
   */
  switch (self->syncType) {
    case SYNC_TYPE_DO_NOTHING:
      return SYNC_TYPE_DO_NOTHING;
      
    case SYNC_TYPE_SKY_OVER_PALM:
      return SYNC_TYPE_SKY_OVER_PALM;
      
    case SYNC_TYPE_PALM_OVER_SKY:
      return SYNC_TYPE_PALM_OVER_SKY;
      
    case SYNC_TYPE_TWO_WAY:
      // what would i do in case of a two way sync   
      switch ([self skyrixSyncState]) {
        case SYNC_STATE_NOTHING_CHANGED:
        case SYNC_STATE_NEVER_SYNCED:
          return SYNC_TYPE_DO_NOTHING;
          
        case SYNC_STATE_PALM_CHANGED:
          return SYNC_TYPE_PALM_OVER_SKY;
          
        case SYNC_STATE_SKYRIX_CHANGED:
          return SYNC_TYPE_SKY_OVER_PALM;
          
        case SYNC_STATE_BOTH_CHANGED:
          // what would i do in case of conflict
          switch ([self skyrixSyncConflictHandling]) {
            case SYNC_SKYRIX_CONFLICT_DO_NOTHING:
              return SYNC_TYPE_DO_NOTHING;
            case SYNC_SKYRIX_CONFLICT_CREATE_NEW_OGO:
              // it's not exactly this. but we create a new sky entry
              // and sync PalmOverSky
              return SYNC_TYPE_PALM_OVER_SKY;
            case SYNC_SKYRIX_CONFLICT_FORCEOGOOVERPALM:
              return SYNC_TYPE_SKY_OVER_PALM;
            case SYNC_SKYRIX_CONFLICT_FORCEPALMOVEROGO:
              return SYNC_TYPE_PALM_OVER_SKY;
          }
      }
  }
  NSLog(@"unknown sync constellation: syncType: %d "
        @"syncState: %d conflictHandling: %d",
        __PRETTY_FUNCTION__, self->syncType,
        [self skyrixSyncState], [self skyrixSyncConflictHandling]);
  
  return SYNC_TYPE_DO_NOTHING;
}

- (id)forceSkyrixOverPalmSync {
  BOOL save = NO;
  save = [self syncSkyrixOverPalm];
  return save ? [self saveWithoutReset] : self;
}
- (id)forcePalmOverSkyrixSync {
  BOOL save = NO;
  save = [self syncPalmOverSkyrix];
  return save ? [self saveWithoutReset] : self;
}

- (void)saveSkyrixRecord {
  NSLog(@"%s not overwritten!!", __PRETTY_FUNCTION__);
}

// skyrix version management
- (BOOL)canSynchronizeWithSkyrixRecord {
  return [self hasSkyrixRecord];
}

- (NSNumber *)skyrixRecordVersion {
  return [[self skyrixRecord] valueForKey:@"objectVersion"];
}
- (void)updateSkyrixVersions {
  /* update versions of the last sync ogo <-> ogo-palm */
  id vers = [self skyrixRecordVersion];
  if (vers != nil)
    [self setSkyrixVersion:[vers intValue]];
  [self setSkyrixPalmVersion:[self objectVersion]];
}
- (int)skyrixSyncState {
  id  vers = nil;
  int oVers;
  int lastOVers;
  int skyVers;
  int lastSkyVers;

  if (![self hasSkyrixRecord])
    return SYNC_STATE_NOTHING_CHANGED;

  oVers     = [self objectVersion];
  lastOVers = [self skyrixPalmVersion];

  vers = [self skyrixRecordVersion];
  if (vers == nil) {
    // no skyrix version available
    return (oVers != lastOVers)
      ? SYNC_STATE_PALM_CHANGED
      : SYNC_STATE_NOTHING_CHANGED;
  }
  // get the current skyrix version and the version at the last sync
  skyVers     = [vers intValue];
  lastSkyVers = [self skyrixVersion];
  
  // if lastSkyVers == 0 it seems like it has never been synced before
  if (lastSkyVers == 0)
    return SYNC_STATE_NEVER_SYNCED;
  
  if (oVers == lastOVers) {
    // palm record didn't change since last sync
    return (skyVers == lastSkyVers)
      ? SYNC_STATE_NOTHING_CHANGED : SYNC_STATE_SKYRIX_CHANGED;
  }
  else {
    // palm record change since last sync

    // ###### SPECIAL CASE ############
    // if i'm in postsync record might have been synced in presync
    // -> lastSkyVers would have been reseted
    //
    if (skyVers == lastSkyVers) {
      NSString *key;
      NSArray  *updatedInPreSync;

      key = [NSString stringWithFormat:@"OGoPalm_%@_UpdatedInPreSyncIDs",
		      [self->dataSource palmDb]];

      updatedInPreSync = [[self context] valueForKey:key];

      if (updatedInPreSync != nil) {
	id pId;

	pId = [NSNumber numberWithInt:[self palmId]];
      	
	if ([updatedInPreSync containsObject:pId]) {
	  // -> both changed
	  // [mh]
	  // set a marker so this state is remebered after next save
	  // ok. a bit of a hack .. but it works
	  [self setSkyrixVersion:lastSkyVers-1];
	  [self saveWithoutReset];
	  return SYNC_STATE_BOTH_CHANGED;
	}
      }
      return SYNC_STATE_PALM_CHANGED;
    }
    /// ###############################
    
    // palm and ogo record did change since last sync
    return SYNC_STATE_BOTH_CHANGED;
  }
  
}

// skyrix record assigment
- (void)setSkyrixId:(id)_sId {
  ASSIGN(self->skyrixId,_sId);
  self->reloadSkyrixRecord = YES;
}
- (NSNumber *)skyrixId {
  return self->skyrixId;
}
- (void)setSyncType:(int)_type {
  self->syncType = _type;
}
- (int)syncType {
  if (![self _hasSkyrixRecordBinding])
    return -1;
  return self->syncType;
}

- (void)setSkyrixVersion:(int)_version {
  self->skyrixVersion = _version;
}
- (int)skyrixVersion {
  return self->skyrixVersion;
}
- (void)setSkyrixPalmVersion:(int)_version {
  self->skyrixPalmVersion = _version;
}
- (int)skyrixPalmVersion {
  return self->skyrixPalmVersion;
}

- (void)takeValuesFromSkyrixRecord:(id)_skyrixRecord {
  NSLog(@"%s not overwritten!!", __PRETTY_FUNCTION__);
}
- (void)putValuesToSkyrixRecord:(id)_skyrixRecord {
  NSLog(@"%s not overwritten!!", __PRETTY_FUNCTION__);
}

- (id)fetchSkyrixRecord {
  NSLog(@"%s not overwritten!!", __PRETTY_FUNCTION__);
  return nil;
}
- (void)_dropSkyrixRecord {
  if (self->skyrixRecord == nil)
    return;

  // remove all assignments to skyrixRecord
  RELEASE(self->skyrixRecord); self->skyrixRecord = nil;
  if (self->isObserving)
    [self _stopObserving];
}

- (void)_observeSkyrixRecord:(id)_skyrixRecord {
  NSLog(@"%s not overwritten!!", __PRETTY_FUNCTION__);
}
- (void)_stopObserving {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  self->isObserving = NO;
}

- (void)skyrixRecordChanged {
  // force reload of record
  self->reloadSkyrixRecord = YES;
}
- (void)skyrixRecordDeleted {
  [self setSkyrixId:[NSNumber numberWithInt:0]];
  [self setSyncType:SYNC_TYPE_DO_NOTHING];
  [self saveWithoutReset];
}

- (BOOL)_hasSkyrixRecordBinding {
  if ((self->skyrixRecord != nil) ||
      ((self->skyrixId != nil) && ([self->skyrixId intValue] > 10000)))
    return YES;
  return NO;
}
- (BOOL)hasSkyrixRecord {
  if (![self _hasSkyrixRecordBinding])
    return NO;
  if ([self skyrixRecord] != nil)
    return YES;

  // no skyrix record though a record is bound
  // skyrix record is deleted or no longer available
  // -> delete this record
  [self setSkyrixId:0];
  [self setSyncType:SYNC_TYPE_DO_NOTHING];
  [self delete];
  return NO;
}
- (BOOL)canAssignSkyrixRecord {
  return [self isEditable];
}
- (BOOL)canCreateSkyrixRecord {
  return (([self canAssignSkyrixRecord]) && (![self hasSkyrixRecord]))
    ? YES : NO;
}

- (id)skyrixRecord {
  if (self->reloadSkyrixRecord) {
    [self _dropSkyrixRecord];
    self->reloadSkyrixRecord = NO;
  }
  
  if (self->skyrixRecord == nil) {
    if ([self _hasSkyrixRecordBinding]) {
      self->skyrixRecord = [self fetchSkyrixRecord];
      RETAIN(self->skyrixRecord);
      [self _observeSkyrixRecord:self->skyrixRecord];
    }
  }
  return self->skyrixRecord;
}

// during bulk fetch
- (void)_bulkFetch_setSkyrixRecord:(id)_skyrixRecord {
  if (self->skyrixRecord != _skyrixRecord) {
    if (self->reloadSkyrixRecord || self->skyrixRecord != nil) {
      [self _dropSkyrixRecord];
      self->reloadSkyrixRecord = NO;
    }
    ASSIGN(self->skyrixRecord, _skyrixRecord);
    [self _observeSkyrixRecord:_skyrixRecord];
  }
  else if (self->reloadSkyrixRecord) {
    self->reloadSkyrixRecord = NO;
  }
}


@end /* SkyPalmDocument(SkyrixSync) */

@implementation SkyPalmDocumentSelection

- (id)init {
  if ((self = [super init])) {
    self->all = [[NSMutableArray alloc] init];
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->all);
  [super dealloc];
}
#endif

- (Class)mustBeClass {
  return [SkyPalmDocument class];
}
- (void)addDoc:(SkyPalmDocument *)_doc {
  if ([_doc isKindOfClass:[self mustBeClass]])
    [self->all addObject:_doc];
}
- (void)addDocs:(NSArray *)_docs {
  NSEnumerator *e  = [_docs objectEnumerator];
  id           one = nil;
  while ((one = [e nextObject]))
    [self addDoc:one];
}
- (void)clearSelection {
  [self->all removeAllObjects];
}

+ (SkyPalmDocumentSelection *)selectionWithDocs:(NSArray *)_docs {
  SkyPalmDocumentSelection *sel = [[SkyPalmDocumentSelection alloc] init];
  [sel addDocs:_docs];
  return AUTORELEASE(sel);
}

- (NSArray *)docs {
  return self->all;
}

@end /* SkyPalmDocumentSelection */
