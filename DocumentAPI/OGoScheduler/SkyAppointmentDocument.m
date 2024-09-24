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

#include "SkyAppointmentDocument.h"
#include "common.h"
#include <OGoAccounts/SkyAccountDocument.h>
#include <OGoBase/LSCommandContext+Doc.h>
#include "SkyAppointmentQualifier.h"
#include "SkyAptDataSource.h"

@interface SkyAppointmentDocument(Private)
- (void)_registerForGID;
- (void)_setObjectVersion:(NSNumber *)_version;
- (SkyAppointmentDocument *)_fetchParentDate;
- (void)_loadDocument:(id)_appointment;
- (EOKeyGlobalID *)_personGidFrom:(NSString *)_personId;
@end

@implementation SkyAppointmentDocumentType
@end /* SkyAppointmentDocumentType */

static BOOL debugDocRegistration = NO;

@implementation SkyAppointmentDocument

static Class    CalDateClass          = Nil;
static Class    AccountDocumentClass  = Nil;
static NSArray  *emptyArray           = nil;
static NSArray  *teamFetchAttrNames   = nil;
static NSArray  *personFetchAttrNames = nil;
static NSNumber *yesNum               = nil;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  // TODO: check parent class version!!
  
  CalDateClass         = [NSCalendarDate class];
  AccountDocumentClass = NGClassFromString(@"SkyAccountDocument");
  debugDocRegistration = [ud boolForKey:@"DebugDocumentRegistration"];
  
  if (emptyArray == nil) 
    emptyArray = [[NSArray alloc] init];
  if (yesNum == nil)
    yesNum = [[NSNumber numberWithBool:YES] retain];

  if (teamFetchAttrNames == nil) {
    teamFetchAttrNames = 
      [[NSArray alloc] initWithObjects:
			 @"globalID", @"description", @"companyId", nil];
  }
  if (personFetchAttrNames == nil) {
    personFetchAttrNames = 
      [[NSArray alloc] initWithObjects:@"globalID",
		       @"name", @"firstname",
		       @"login", @"companyId", nil];
  }
}

- (NSNotificationCenter *)notificationCenter {
  static NSNotificationCenter *nc = nil;
  if (nc == nil)
    nc = [[NSNotificationCenter defaultCenter] retain];
  return nc;
}

/*
    "notificationTime": {
    "isAttendance": {
    "isConflictDisabled": {
    "absence": {
    "resourceNames": {
    "isAbsence": {
*/

// designated initializer
- (id)initWithEO:(id)_appointment globalID:(EOGlobalID *)_gid
  dataSource:(EODataSource *)_ds
{
  if ((self = [super init])) {
    self->dataSource = [_ds  retain];
    self->globalID   = [_gid retain];
    [self _loadDocument:_appointment];
    [self _registerForGID];
    self->saveCycles = YES;
  }
  return self;
}

- (id)initWithEO:(id)_appointment dataSource:(EODataSource *)_ds {
  EOKeyGlobalID *gid;

#if 0
  if ([_appointment respondsToSelector:@selector(globalID)])
    gid = (EOKeyGlobalID *)[_appointment globalID];
  else
#endif    
  gid = [_appointment valueForKey:@"globalID"];
  
  return [self initWithEO:_appointment globalID:gid dataSource:_ds];
}

- (id)initWithGlobalID:(EOGlobalID *)_gid dataSource:(EODataSource *)_ds {
  return [self initWithEO:nil globalID:_gid dataSource:_ds];
}


- (void)dealloc {
  [[self notificationCenter] removeObserver:self];
  
  [self->dataSource         release];
  [self->globalID           release];
  [self->startDate          release];
  [self->endDate            release];
  [self->cycleEndDate       release];
  [self->title              release];
  [self->location           release];
  [self->type               release];
  [self->objectVersion      release];
  [self->parentDateId       release];
  [self->parentDate         release];
  [self->owner              release];
  [self->participants       release];
  [self->notificationTime   release];
  [self->ownerGID           release];
  [self->resourceNames      release];
  [self->permissions        release];
  [self->writeAccessList    release];
  [self->writeAccessMembers release];
  [self->accessTeamId       release];
  
  [super dealloc];
}

/* accessors */

- (BOOL)isComplete {
  if (![self isValid])
    return NO;

  return self->status.isComplete;
}

- (BOOL)isNew {
  return (self->globalID == nil) ? YES : NO;
}

- (BOOL)isValid {
  return self->status.isValid;
}

- (void)invalidate {
  [self->globalID           release]; self->globalID           = nil;
  [self->startDate          release]; self->startDate          = nil;
  [self->endDate            release]; self->endDate            = nil;
  [self->cycleEndDate       release]; self->cycleEndDate       = nil;
  [self->title              release]; self->title              = nil;
  [self->location           release]; self->location           = nil;
  [self->type               release]; self->type               = nil;
  [self->objectVersion      release]; self->objectVersion      = nil;
  [self->parentDateId       release]; self->parentDateId       = nil;
  [self->parentDate         release]; self->parentDate         = nil;
  [self->comment            release]; self->comment            = nil;
  [self->participants       release]; self->participants       = nil;
  [self->notificationTime   release]; self->notificationTime   = nil;
  [self->resourceNames      release]; self->resourceNames      = nil;
  [self->permissions        release]; self->permissions        = nil;
  [self->writeAccessList    release]; self->writeAccessList    = nil;
  [self->writeAccessMembers release]; self->writeAccessMembers = nil;
  [self->accessTeamId       release]; self->accessTeamId       = nil;
  
  self->status.isValid = NO;
}

- (BOOL)isEdited {
  return (self->globalID == nil || self->status.isEdited) ? YES : NO;
}

- (EOGlobalID *)globalID {
  return self->globalID;
}
- (void)_setGlobalID:(id)_gid {
  if (self->globalID == nil)
    ASSIGN(self->globalID,_gid);
}

- (id)context {
  if (self->dataSource)
    return [(id)self->dataSource context];
  
#if DEBUG
  NSLog(@"WARNING(%s): document %@ has no datasource/context !!",
        __PRETTY_FUNCTION__, self);
#endif
  return nil;
}

- (SkyDocumentType *)documentType {
  static SkyAppointmentDocumentType *docType = nil;
  
  if (docType == nil)
    docType = [[SkyAppointmentDocumentType alloc] init];

  return docType;
}

/* accessors */

- (void)setStartDate:(NSCalendarDate *)_date {
  if (![_date isNotNull]) _date = nil;
  NSParameterAssert(_date == nil || [_date isKindOfClass:CalDateClass]);
  ASSIGNCOPY_IFNOT_EQUAL(self->startDate, _date, self->status.isEdited);
}
- (NSCalendarDate *)startDate {
  return self->startDate;
}
- (void)setEndDate:(NSCalendarDate *)_date {
  if (![_date isNotNull]) _date = nil;
  NSParameterAssert(_date == nil || [_date isKindOfClass:CalDateClass]);
  ASSIGNCOPY_IFNOT_EQUAL(self->endDate, _date, self->status.isEdited);
}
- (NSCalendarDate *)endDate {
  return self->endDate;
}

- (void)setCycleEndDate:(NSCalendarDate *)_date {
  if (![_date isNotNull]) _date = nil;
  NSParameterAssert(_date == nil || [_date isKindOfClass:CalDateClass]);
  ASSIGNCOPY_IFNOT_EQUAL(self->cycleEndDate, _date, self->status.isEdited);
}
- (NSCalendarDate *)cycleEndDate {
  return self->cycleEndDate;
}

- (void)setParticipants:(NSArray *)_participants {
  ASSIGNCOPY_IFNOT_EQUAL(self->participants, _participants,
                         self->status.isEdited);
}
- (NSArray *)participants {
  return self->participants;
}

- (void)setNotificationTime:(NSNumber *)_notificationTime {
  ASSIGNCOPY_IFNOT_EQUAL(self->notificationTime, _notificationTime,
                         self->status.isEdited);
}
- (NSNumber *)notificationTime {
  return self->notificationTime;
}

- (void)setResourceNames:(NSString *)_names {
  ASSIGNCOPY_IFNOT_EQUAL(self->resourceNames, _names, self->status.isEdited);
}
- (NSString *)resourceNames {
  return self->resourceNames;
}

- (void)setTitle:(NSString *)_title {
  ASSIGNCOPY_IFNOT_EQUAL(self->title, _title, self->status.isEdited);
}
- (NSString *)title {
  return self->title; // "title"
}

- (void)setLocation:(NSString *)_location {
  ASSIGNCOPY_IFNOT_EQUAL(self->location, _location, self->status.isEdited);
}
- (NSString *)location {
  return self->location; // "location"
}

- (void)setType:(NSString *)_type {
  ASSIGNCOPY_IFNOT_EQUAL(self->type, _type, self->status.isEdited);
}
- (NSString *)type {
  return self->type; // "type" # weekday,daily,14_daily,
  // 4_weekly,weekly,monthly,yearly    
}

- (void)setAptType:(NSString *)_type {
  ASSIGNCOPY_IFNOT_EQUAL(self->aptType, _type, self->status.isEdited);
}
- (NSString *)aptType {
  return self->aptType;
}

- (void)setComment:(NSString *)_comment {
  ASSIGNCOPY_IFNOT_EQUAL(self->comment, _comment, self->status.isEdited);
}
- (NSString *)comment {
  return self->comment; //
}

- (void)setOwner:(SkyDocument *)_owner {
  id inputId   = nil;
  id currentId = nil;

  inputId   = [[(EOKeyGlobalID *)[_owner globalID] keyValuesArray] lastObject];
  currentId = [[(EOKeyGlobalID *)self->ownerGID keyValuesArray] lastObject];

  if ([currentId isEqual:inputId])
    return;
  
  [self->owner    release]; self->owner    = nil;
  [self->ownerGID release]; self->ownerGID = nil;

  self->ownerGID = [[self _personGidFrom:inputId] retain];
  self->status.isEdited = YES;
}

- (SkyDocument *)owner {
  if (!(self->owner == nil && self->ownerGID != nil))
    return self->owner;
      
  self->owner = [[AccountDocumentClass alloc] 
		  initWithGlobalID:self->ownerGID context:[self context]];
  return self->owner;
}
- (EOGlobalID *)ownerGID {
  return self->ownerGID;
}

- (NSNumber *)objectVersion {
  return self->objectVersion;
}

- (void)setWriteAccess:(NSArray *)_accessIds {
  [self setWriteAccessList:[_accessIds componentsJoinedByString:@","]];
}
- (NSArray *)writeAccess {
  if ([self->writeAccessList length] == 0) 
    return emptyArray;
  
  return [self->writeAccessList componentsSeparatedByString:@","];
}
- (void)setWriteAccessList:(NSString *)_writeAccessList {
  if ([_writeAccessList isEqual:self->writeAccessList])
    return;

  ASSIGN(self->writeAccessList,_writeAccessList);
  [self->writeAccessMembers release]; self->writeAccessMembers = nil;
  self->status.isEdited = YES;
}
- (NSString *)writeAccessList {
  return self->writeAccessList;
}

- (NSArray *)writeAccessMembers {
  NSMutableArray *persons, *teams;
  NSEnumerator   *e;
  id one, ctx, dm;
  
  if (self->writeAccessMembers)
    return self->writeAccessMembers;

  persons = [NSMutableArray array];
  teams   = [NSMutableArray array];
  e       = [[self writeAccess] objectEnumerator];
  ctx     = [self context];
  dm      = [ctx documentManager];

  while ((one = [e nextObject])) {
    one = [dm globalIDForURL:one];
    if ([[one entityName] isEqualToString:@"Person"])
      [persons addObject:one];
    else if ([[one entityName] isEqualToString:@"Team"])
      [teams addObject:one];
    else {
      NSLog(@"WARNING[%s]:Invalid id in access list",
            __PRETTY_FUNCTION__, one);
    }
  }
  self->writeAccessMembers = emptyArray;
  if ([persons count] > 0) {
    id tmp;
    
    tmp = [ctx runCommand:@"person::get-by-globalid",
               @"gids",       persons,
               @"attributes", personFetchAttrNames, nil];
    self->writeAccessMembers =
      [self->writeAccessMembers arrayByAddingObjectsFromArray:tmp];
  }
  if ([teams count] > 0) {
    id tmp;
    
    tmp = [ctx runCommand:@"team::get-by-globalid",
               @"gids",       teams,
               @"attributes", teamFetchAttrNames, nil];
    self->writeAccessMembers =
      [self->writeAccessMembers arrayByAddingObjectsFromArray:tmp];
  }
  self->writeAccessMembers = [self->writeAccessMembers retain];
  return self->writeAccessMembers;
}

- (void)setAccessTeamId:(id)_teamId {
  ASSIGNCOPY_IFNOT_EQUAL(self->accessTeamId,_teamId, self->status.isEdited);
}
- (id)accessTeamId {
  return self->accessTeamId;
}

- (void)setParentDateId:(NSNumber *)_pId {
  ASSIGNCOPY_IFNOT_EQUAL(self->parentDateId,_pId, self->status.isEdited);
}
- (NSNumber *)parentDateId {
  return self->parentDateId;
}
- (BOOL)hasParentDate {
  if (self->parentDateId == nil)
    return NO;
  if ([self->parentDateId intValue] < 10000)
    return NO;
  return YES;
}
- (SkyAppointmentDocument *)parentDate {
  if (self->parentDate == nil)
    self->parentDate = [[self _fetchParentDate] retain];
  
  return self->parentDate;
}

- (NSString *)permissions {
  return self->permissions;
}

- (NSDictionary *)asDict {
  NSMutableDictionary *dict;
  NSNumber            *appId;

  dict  = [NSMutableDictionary dictionaryWithCapacity:16];
  appId = [[(EOKeyGlobalID *)self->globalID keyValuesArray] lastObject];

  if (appId != nil) {
    [dict setObject:appId forKey:@"dateId"];
    if (([self type] != nil) && ([self parentDateId] == nil))
      [dict setObject:[NSNumber numberWithBool:self->saveCycles]
            forKey:@"setAllCyclic"];
  }

  [dict takeValue:[self startDate]    forKey:@"startDate"];
  [dict takeValue:[self endDate]      forKey:@"endDate"];
  [dict takeValue:[self cycleEndDate] forKey:@"cycleEndDate"];
  [dict takeValue:[self title]        forKey:@"title"];
  [dict takeValue:[self location]     forKey:@"location"];
  [dict takeValue:[self type]         forKey:@"type"];
  [dict takeValue:[self aptType]      forKey:@"aptType"];
  [dict takeValue:[self parentDateId] forKey:@"parentDateId"];
  [dict takeValue:[self comment]      forKey:@"comment"];

  if (self->accessTeamId != nil)
    [dict takeValue:self->accessTeamId forKey:@"accessTeamId"];

  [dict takeValue:self->writeAccessList forKey:@"writeAccessList"];
  
  if (self->participants != nil)
    [dict takeValue:self->participants forKey:@"participants"];
  if (self->notificationTime != nil)
    [dict takeValue:self->notificationTime forKey:@"notificationTime"];
  if (self->resourceNames != nil)
    [dict takeValue:self->resourceNames forKey:@"resourceNames"];

  /* it's forbidden to set the owner explicitly !!! */

  return dict;
}

- (EODataSource *)dataSource {
  return self->dataSource;
}

- (void)setSaveCycles:(BOOL)_flag {
  self->saveCycles = _flag;
}
- (BOOL)saveCycles {
  return self->saveCycles;
}

/* actions */

- (void)logException:(NSException *)_exception {
  NSLog(@"%s: catched exception: %@", __PRETTY_FUNCTION__, _exception);
}

- (BOOL)save {
  BOOL result = YES;
  
  NS_DURING
    if (self->globalID == nil) {
      [self->dataSource insertObject:self];
    }
    else {
      [self->dataSource updateObject:self];
    }
  NS_HANDLER {
    result = NO;
    [self logException:localException];
  }
  NS_ENDHANDLER;
  
  return result;
}

- (BOOL)delete {
  BOOL result = YES;
  
  NS_DURING {
    [self->dataSource deleteObject:self];
  }
  NS_HANDLER {
    result = NO;
    [self logException:localException];
  }
  NS_ENDHANDLER;
  
  return result;
}

- (BOOL)reload {
  if (![self isValid])
    return NO;

  if ([self globalID] == nil) {
    [self invalidate];
  }
  else {
    id obj;

    obj = [[[self context] runCommand:@"object::get-by-globalid",
                           @"gid", [self globalID], nil] lastObject];
    [self _loadDocument:obj];
  }
  return YES;
}

/* Private */

- (void)_registerForGID {
  if (debugDocRegistration) {
    NSLog(@"++++++++++++++++++ Warning: register Document"
          @" in NotificationCenter(%s)",
          __PRETTY_FUNCTION__);
  }
  
  if (self->globalID == nil)
    return;
  
  [[self notificationCenter] addObserver:self selector:@selector(invalidate)
			     name:SkyGlobalIDWasDeleted object:self->globalID];
}
- (void)_setObjectVersion:(NSNumber *)_version {
  ASSIGNCOPY_IFNOT_EQUAL(self->objectVersion, _version, self->status.isEdited);
}
- (void)_setPermissions:(NSString *)_permissions {
  ASSIGNCOPY_IFNOT_EQUAL(self->permissions,_permissions,self->status.isEdited);
}

// fetching parent
- (EOQualifier *)_qualifierForParent {
  SkyAppointmentQualifier *qual;
  NSTimeZone              *tz;

  qual = [[[SkyAppointmentQualifier alloc] init] autorelease];
  tz   = [[self startDate] timeZone];
  if (tz == nil) tz = [NSTimeZone localTimeZone];
  [qual setTimeZone:tz];

  return qual;
}
- (NSDictionary *)_hintsForParent {
  NSNumber      *pid = [self parentDateId];
  EOKeyGlobalID *gid;

  gid = [EOKeyGlobalID globalIDWithEntityName:@"Date"
                       keys:&pid keyCount:1 zone:NULL];
  return [NSDictionary dictionaryWithObjectsAndKeys:
			 yesNum, @"SkyReturnDocs",
                         [NSArray arrayWithObject:gid], @"FetchGIDs",
                       nil];
}
- (EOFetchSpecification *)_fetchSpecForParent {
  EOFetchSpecification *fspec;
  
  fspec = 
    [EOFetchSpecification fetchSpecificationWithEntityName:@"Date"
                          qualifier:[self _qualifierForParent]
                          sortOrderings:nil];
  [fspec setHints:[self _hintsForParent]];
  return fspec;
}
- (EODataSource *)_dataSourceForParent {
  SkyAptDataSource *ds = nil;
  
  ds = [[[SkyAptDataSource alloc] init] autorelease];
  [ds setContext:[self context]];
  [ds setFetchSpecification:[self _fetchSpecForParent]];
  return ds;
}
- (SkyAppointmentDocument *)_fetchParentDate {
  EODataSource *ds = nil;
  if (![self hasParentDate])
    return nil;

  ds = [self _dataSourceForParent];
  return [[ds fetchObjects] lastObject];
}

- (void)_loadDocument:(id)_object {

  [self _setPermissions:   [_object valueForKey:@"permissions"]];

  [self setStartDate:      [_object valueForKey:@"startDate"]];
  [self setEndDate:        [_object valueForKey:@"endDate"]];
  [self setCycleEndDate:   [_object valueForKey:@"cycleEndDate"]];
  
  if ([self->permissions rangeOfString:@"v"].length == 0) {
    [self setTitle:          @"*"];
    [self setLocation:       @"*"];
    [self setComment:        @"*"];
    [self setResourceNames:  @"*"];
    [self setParticipants:   emptyArray];
  }
  else {
    [self setTitle:          [_object valueForKey:@"title"]];
    [self setLocation:       [_object valueForKey:@"location"]];
    [self setParticipants:   [_object valueForKey:@"participants"]];
    [self setResourceNames:  [_object valueForKey:@"resourceNames"]];
    [self setComment:        [_object valueForKey:@"comment"]];
  }
  [self setType:           [_object valueForKey:@"type"]];
  [self setAptType:        [_object valueForKey:@"aptType"]];
  [self _setObjectVersion: [_object valueForKey:@"objectVersion"]];
  [self setParentDateId:   [_object valueForKey:@"parentDateId"]];
  [self setNotificationTime: [_object valueForKey:@"notificationTime"]];
  [self setWriteAccessList:[_object valueForKey:@"writeAccessList"]];
  [self setAccessTeamId:   [_object valueForKey:@"accessTeamId"]];

  [self->owner    release]; self->owner    = nil;
  [self->ownerGID release]; self->ownerGID = nil;

  self->ownerGID = 
    [[self _personGidFrom:[_object valueForKey:@"ownerId"]] retain];
  
  self->status.isComplete = YES;
  self->status.isValid    = YES;
  self->status.isEdited   = NO;

  [self->parentDate release]; self->parentDate = nil;
}

- (EOKeyGlobalID *)_personGidFrom:(NSString *)_personId {
  EOKeyGlobalID *result = nil;
  id values[1];
  
  if (_personId == nil)
    return nil;

  values[0] = _personId;
  result    = [EOKeyGlobalID globalIDWithEntityName:@"Person"
                             keys:values
                             keyCount:1
                             zone:[self zone]];
  return result;
}

/* EOGenericRecord */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"writeAccessList"])
    [self setWriteAccessList:_value];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"writeAccessList"])
    return [self writeAccessList];
  return [super valueForKey:_key];
}

@end /* SkyAppointmentDocument */
