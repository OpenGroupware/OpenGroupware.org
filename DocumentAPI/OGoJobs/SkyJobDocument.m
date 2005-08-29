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

#include "SkyJobHistoryDataSource.h"
#include "SkyJobDocument.h"
#include <OGoContacts/SkyPersonDocument.h>
#include <OGoAccounts/SkyAccountDataSource.h>
#include "common.h"

@interface SkyJobDocument(PrivateMethodes)
- (void)_registerForGID;
- (void)_setObjectVersion:(NSNumber *)_version;
- (EOKeyGlobalID *)_personGidFromId:(NSString *)_personId;
- (EOKeyGlobalID *)_teamGidFromId:(NSString *)_teamId;
- (void)_loadDocument:(id)_job;
@end /* SkyJobDocument(PrivateMethodes) */

@implementation SkyJobDocument

static BOOL debugDocRegistration = NO;

+ (int)version {
  return [super version] + 0; /* v1 */
}

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  NSAssert2([super version] == 1,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
  debugDocRegistration = [ud boolForKey:@"DebugDocumentRegistration"];
}

- (NSNotificationCenter *)notificationCenter {
  static NSNotificationCenter *nc = nil;
  if (nc == nil) nc = [[NSNotificationCenter defaultCenter] retain];
  return nc;
}

// designated initializer
- (id)initWithJob:(id)_job
  globalID:(EOGlobalID *)_gid
  dataSource:(EODataSource *)_ds
{
  if ((self = [super init])) {
    EOFetchSpecification *fSpec;
    NSArray              *attrs;
    
    self->dataSource = [_ds  retain];
    self->globalID   = [_gid retain];
    
    /* TODO: this section looks quite hackish */
    fSpec = [_ds fetchSpecification];
    attrs = [[fSpec hints] objectForKey:@"attributes"];
    self->supportedAttributes = [attrs copy];
    
    /* load infos */
    [self _loadDocument:_job];
    [self _registerForGID];
  }
  return self;
}

- (id)initWithEO:(id)_eo dataSource:(EODataSource *)_ds {
  return [self initWithJob:_eo
               globalID:[_eo valueForKey:@"globalID"]
               dataSource:_ds];
}

- (void)dealloc {
  if (self->globalID)
    [[self notificationCenter] removeObserver:self];
  
  [self->dataSource release];
  [self->globalID   release];
  
  [self->name                release];
  [self->startDate           release];
  [self->endDate             release];
  [self->keywords            release];
  [self->category            release];
  [self->jobStatus           release];
  [self->priority            release];
  [self->type                release];
  [self->creator             release];
  [self->executor            release];
  [self->objectVersion       release];
  [self->supportedAttributes release];
  [self->createComment       release];
  [self->actualWork          release];
  [self->totalWork           release];
  [self->kilometers          release];
  [self->sensitivity         release];
  [self->comment             release];
  [self->completionDate      release];
  [self->percentComplete     release];
  [self->accountingInfo      release];
  [self->associatedCompanies release];
  [self->associatedContacts  release];
  
  [super dealloc];
}

- (BOOL)isComplete {
  if (![self isValid])
    return NO;

  if (self->supportedAttributes != nil)
    return NO;

  return self->status.isComplete;
}

- (EOGlobalID *)globalID {
  return self->globalID;
}

- (NSArray *)attributesForNamespace:(NSString *)_namespace {
  return nil;
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

/* accessors */

- (void)setName:(NSString *)_name {
  ASSIGNCOPY_IFNOT_EQUAL(self->name, _name, self->status.isEdited);
}
- (NSString *)name {
  return self->name;
}

- (void)setStartDate:(NSCalendarDate *)_startDate {
  ASSIGNCOPY_IFNOT_EQUAL(self->startDate, _startDate, self->status.isEdited);
}
- (NSCalendarDate *)startDate {
  return self->startDate;
}

- (void)setEndDate:(NSCalendarDate *)_endDate {
  ASSIGNCOPY_IFNOT_EQUAL(self->endDate, _endDate, self->status.isEdited);
}
- (NSCalendarDate *)endDate {
  return self->endDate;
}

- (void)setKeywords:(NSString *)_keywords {
  ASSIGNCOPY_IFNOT_EQUAL(self->keywords, _keywords, self->status.isEdited);
}
- (NSString *)keywords {
  return self->keywords;
}

- (void)setCategory:(NSString *)_category {
  ASSIGNCOPY_IFNOT_EQUAL(self->category, _category, self->status.isEdited);
}
- (NSString *)category {
  return self->category;
}

- (void)setStatus:(NSString *)_status {
  ASSIGNCOPY_IFNOT_EQUAL(self->jobStatus, _status, self->status.isEdited);
}
- (NSString *)status {
  return self->jobStatus;
}

- (void)setPriority:(NSNumber *)_priority {
  ASSIGNCOPY_IFNOT_EQUAL(self->priority, _priority, self->status.isEdited);
}
- (NSNumber *)priority {
  return self->priority;
}

- (void)setActualWork:(NSNumber *)_actualWork {
  ASSIGNCOPY_IFNOT_EQUAL(self->actualWork, _actualWork, self->status.isEdited);
}
- (NSNumber *)actualWork {
  return self->actualWork;
}

- (void)setTotalWork:(NSNumber *)_totalWork {
  ASSIGNCOPY_IFNOT_EQUAL(self->totalWork, _totalWork, self->status.isEdited);
}
- (NSNumber *)totalWork {
  return self->totalWork;
}

- (void)setKilometers:(NSNumber *)_kilometers {
  ASSIGNCOPY_IFNOT_EQUAL(self->kilometers, _kilometers, self->status.isEdited);
}
- (NSNumber *)kilometers {
  return self->kilometers;
}

- (void)setSensitivity:(NSNumber *)_sensitivity {
  ASSIGNCOPY_IFNOT_EQUAL(self->sensitivity, _sensitivity,
                         self->status.isEdited);
}
- (NSNumber *)sensitivity {
  return self->sensitivity;
}

- (void)setComment:(NSString *)_comment {
  ASSIGNCOPY_IFNOT_EQUAL(self->comment, _comment, self->status.isEdited);
}
- (NSString *)comment {
  return self->comment;
}

- (void)setCompletionDate:(NSCalendarDate *)_completionDate {
  ASSIGNCOPY_IFNOT_EQUAL(self->completionDate, _completionDate,
                         self->status.isEdited);
}
- (NSCalendarDate *)completionDate {
  return self->completionDate;
}

- (void)setPercentComplete:(NSNumber *)_percentComplete {
  ASSIGNCOPY_IFNOT_EQUAL(self->percentComplete, _percentComplete,
                         self->status.isEdited);
}
- (NSNumber *)percentComplete {
  return self->percentComplete;
}

- (void)setAccountingInfo:(NSString *)_accountingInfo {
  ASSIGNCOPY_IFNOT_EQUAL(self->accountingInfo, _accountingInfo,
                         self->status.isEdited);
}
- (NSString *)accountingInfo {
  return self->accountingInfo;
}

- (void)setAssociatedCompanies:(NSString *)_associatedCompanies {
  ASSIGNCOPY_IFNOT_EQUAL(self->associatedCompanies, _associatedCompanies,
                         self->status.isEdited);
}
- (NSString *)associatedCompanies {
  return self->associatedCompanies;
}

- (void)setAssociatedContacts:(NSString *)_associatedContacts {
  ASSIGNCOPY_IFNOT_EQUAL(self->associatedContacts, _associatedContacts,
                         self->status.isEdited);
}
- (NSString *)associatedContacts {
  return self->associatedContacts;
}

- (void)setType:(NSString *)_type {
  ASSIGNCOPY_IFNOT_EQUAL(self->type, _type, self->status.isEdited);
}
- (NSString *)type {
  return self->type;
}

- (NSNumber *)objectVersion {
  return self->objectVersion;
}

- (void)setCreator:(SkyDocument *)_creator {
  id inputId   = nil;
  id currentId = nil;

  inputId = [[(EOKeyGlobalID *)[_creator globalID] keyValuesArray] lastObject];

  if ([self->creator isKindOfClass:[SkyDocument class]])
    currentId = [self->creator globalID];

  currentId = [[(EOKeyGlobalID *)currentId keyValuesArray] lastObject];

  if (![currentId isEqual:inputId]) {
    [self->creator release]; self->creator = nil;
    self->creator = (id)[self _personGidFromId:inputId];
    self->creator = [self->creator retain];
    self->status.isEdited = YES;
  }
}

- (SkyDocument *)creator {
  if (![self->creator isKindOfClass:[EOGlobalID class]])
    return self->creator;
  
  {
    Class                clazz;
    NSString             *creatorId = nil;
    EODataSource         *ds;
    EOQualifier          *qual;
    EOFetchSpecification *fspec;

    creatorId = [[(EOKeyGlobalID *)self->creator keyValuesArray] lastObject];
    clazz = NSClassFromString(@"SkyAccountDataSource");
    ds    = [(SkyAccountDataSource *)[clazz alloc] 
				     initWithContext:[self context]];
    qual  = [[EOKeyValueQualifier alloc]
                                  initWithKey:@"companyId"
                                  operatorSelector:EOQualifierOperatorEqual
                                  value:creatorId];

    fspec = [EOFetchSpecification fetchSpecificationWithEntityName:@"Person"
                                  qualifier:qual
                                  sortOrderings:nil];
    [ds setFetchSpecification:fspec];
    [qual release]; qual = nil;
    [self->creator release]; self->creator = nil;
    self->creator = [[ds fetchObjects] lastObject];
    self->creator = [self->creator retain];
  }
  return self->creator;
}

- (void)setExecutor:(SkyDocument *)_executor {
  id inputId   = nil;
  id currentId = nil;

  inputId = [[(EOKeyGlobalID *)[_executor globalID] keyValuesArray]
                             lastObject];

  if ([self->executor isKindOfClass:[SkyDocument class]])
    currentId = [self->executor globalID];

  currentId = [[(EOKeyGlobalID *)currentId keyValuesArray] lastObject];

  if (![currentId isEqual:inputId]) {
    [self->executor release];
    self->executor = (id)[self _personGidFromId:inputId];
    self->executor = [self->executor retain];
    self->status.isEdited = YES;
  }
}

- (SkyDocument *)executor {
  if ([self->executor isKindOfClass:[EOGlobalID class]]) {
    Class                clazz;
    NSString             *executorId = nil;
    EODataSource         *ds;
    EOQualifier          *qual;
    EOFetchSpecification *fspec;
    NSString             *entityName;
    NSString             *dsName;

    if (!self->isTeamJob) {
      entityName = @"Person";
      dsName = @"SkyAccountDataSource";
    }
    else {
      entityName = @"Team";
      dsName = @"SkyTeamDataSource";
    }

    executorId = [[(EOKeyGlobalID *)self->executor keyValuesArray] lastObject];

    clazz = NSClassFromString(dsName);
    ds    = [(SkyAccountDataSource *)[clazz alloc] 
				     initWithContext:[self context]];
    qual  = [[EOKeyValueQualifier alloc]
                                  initWithKey:@"companyId"
                                  operatorSelector:EOQualifierOperatorEqual
                                  value:executorId];
    
    fspec = [EOFetchSpecification fetchSpecificationWithEntityName:entityName
                                  qualifier:qual
                                  sortOrderings:nil];

    [ds setFetchSpecification:fspec];
    [qual release]; qual = nil;
    [self->executor release]; self->executor = nil;
    
    self->executor = [[ds fetchObjects] lastObject];
    self->executor = [self->executor retain];
  }
  return self->executor;
}

// only valid if job is not saved yet
- (void)setCreateComment:(NSString *)_comment {
  if (self->globalID == nil)
    ASSIGNCOPY_IFNOT_EQUAL(self->createComment,_comment,self->status.isEdited);
}
- (NSString *)createComment {
  return self->createComment;
}

- (EODataSource *)historyDataSource {
  EODataSource *ds;
  
  ds = [[SkyJobHistoryDataSource alloc] initWithContext:[self context]
                                 jobId:[self globalID]];
  return [ds autorelease];
}

- (NSDictionary *)asDict {
  NSMutableDictionary *dict;
  NSNumber            *jobId;

  dict  = [NSMutableDictionary dictionaryWithCapacity:16];
  jobId = [[(EOKeyGlobalID *)self->globalID keyValuesArray] lastObject];

  if (jobId != nil) [dict setObject:jobId forKey:@"jobId"];

  if (self->isTeamJob)
    [dict takeValue:[NSNumber numberWithBool:self->isTeamJob]
                              forKey:@"isTeamJob"];
  [dict takeValue:[self name]      forKey:@"name"];
  [dict takeValue:[self startDate] forKey:@"startDate"];
  [dict takeValue:[self endDate]   forKey:@"endDate"];
  [dict takeValue:[self keywords]  forKey:@"keywords"];
  [dict takeValue:[self category]  forKey:@"category"];
  [dict takeValue:[self status]    forKey:@"jobStatus"];
  [dict takeValue:[self priority]  forKey:@"priority"];
  [dict takeValue:[self actualWork] forKey:@"actualWork"];
  [dict takeValue:[self totalWork]  forKey:@"totalWork"];
  [dict takeValue:[self kilometers] forKey:@"kilometers"];

  [dict takeValue:[self sensitivity]         forKey:@"sensitivity"];
  [dict takeValue:[self comment]             forKey:@"comment"];
  [dict takeValue:[self completionDate]      forKey:@"completionDate"];
  [dict takeValue:[self percentComplete]     forKey:@"percentComplete"];
  [dict takeValue:[self accountingInfo]      forKey:@"accountingInfo"];
  [dict takeValue:[self associatedCompanies] forKey:@"associatedCompanies"];
  [dict takeValue:[self associatedContacts]  forKey:@"associatedContacts"];

  if ([self isAttributeSupported:@"creator"]) {
    id creatorId = self->creator;

    if ([creatorId isKindOfClass:[SkyDocument class]])
      creatorId = [creatorId globalID];

    creatorId = [[(EOKeyGlobalID *)creatorId keyValuesArray] lastObject];
    [dict takeValue:creatorId forKey:@"creatorId"];
  }
  if ([self isAttributeSupported:@"executor"]) {
    id executorId = self->executor;

    if ([executorId isKindOfClass:[SkyDocument class]])
      executorId = [executorId globalID];

    executorId = [[(EOKeyGlobalID *)executorId keyValuesArray] lastObject];
    [dict takeValue:executorId forKey:@"executantId"];
  }
  
  if ((self->globalID == nil) && (self->createComment != nil))
    [dict takeValue:self->createComment forKey:@"comment"];
  
  return dict;
}

- (EODataSource *)dataSource {
  return self->dataSource;
}

/* document validity */

- (BOOL)isNew {
  return (self->globalID == nil);
}
- (BOOL)isValid {
  return self->status.isValid;
}

- (void)invalidate {
  [self->globalID      release]; self->globalID = nil;
  [self->name          release]; self->name     = nil;
  [self->startDate     release]; self->startDate = nil;
  [self->endDate       release]; self->endDate   = nil;
  [self->keywords      release]; self->keywords  = nil;
  [self->category      release]; self->category  = nil;
  [self->jobStatus     release]; self->jobStatus = nil;
  [self->priority      release]; self->priority  = nil;
  [self->type          release]; self->type      = nil;
  [self->creator       release]; self->creator   = nil;
  [self->executor      release]; self->executor = nil;
  [self->objectVersion release]; self->objectVersion = nil;
  [self->createComment release]; self->createComment = nil;
  [self->actualWork    release]; self->actualWork = nil;
  [self->totalWork     release]; self->totalWork = nil;
  [self->kilometers    release]; self->kilometers = nil;

  [self->sensitivity         release]; self->sensitivity         = nil;
  [self->comment             release]; self->comment             = nil;
  [self->completionDate      release]; self->completionDate      = nil;
  [self->percentComplete     release]; self->percentComplete     = nil;
  [self->accountingInfo      release]; self->accountingInfo      = nil;
  [self->associatedCompanies release]; self->associatedCompanies = nil;
  [self->associatedContacts  release]; self->associatedContacts  = nil;
  
  self->status.isValid = NO;
}

- (BOOL)isEdited {
  return (self->globalID == nil || self->status.isEdited);
}

/* equality */

- (BOOL)isEqual:(id)_other {
  if (_other == self)
    return YES;
  
  if (![_other isKindOfClass:[self class]])
    return NO;
  
  if (![[_other globalID] isEqual:[self globalID]])
    return NO;

  /* docs have same global-id, but could be in different editing state .. */
  
  if (![_other isEdited] && ![self isEdited])
    return YES;
  
  return NO;
}

/* actions */

- (NSException *)logException:(NSException *)_exception {
  NSLog(@"%s: catched exception: %@", __PRETTY_FUNCTION__, _exception);
  return nil;
}

- (BOOL)save {
  BOOL result = YES;
  
  NS_DURING {
    if (self->globalID == nil)
      [self->dataSource insertObject:self];
    else
      [self->dataSource updateObject:self];
  }
  NS_HANDLER {
    result = NO;
    [[self logException:localException] raise];
  }
  NS_ENDHANDLER;
  
  return result;
}

- (BOOL)delete {
  BOOL result = YES;
  
  NS_DURING
    [self->dataSource deleteObject:self];
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
    // TODO: shouldn't we return NO here?
  }
  else {
    id obj;

    obj = [[[self context] runCommand:@"object::get-by-globalid",
                @"gid", [self globalID], nil] lastObject];
    [self _loadDocument:obj];
  }
  return YES;
}

- (void)setSupportedAttributes:(NSArray *)_attrs {
  ASSIGN(self->supportedAttributes, _attrs);
}
- (NSArray *)supportedAttributes {
  return self->supportedAttributes;
}

- (BOOL)isAttributeSupported:(NSString *)_attr {
  return (self->supportedAttributes == nil)
    ? YES
    : [self->supportedAttributes containsObject:_attr];
}

/* private */

- (void)_registerForGID {
  if (debugDocRegistration) {
    [self logWithFormat:
	  @"WARNING(%s): register document in notification-center",
          __PRETTY_FUNCTION__];
  }
  
  if (self->globalID == nil)
    return;
  
  [[self notificationCenter] addObserver:self selector:@selector(invalidate)
			     name:SkyGlobalIDWasDeleted object:self->globalID];
}

- (void)_setObjectVersion:(NSNumber *)_version {
  ASSIGNCOPY_IFNOT_EQUAL(self->objectVersion,_version,self->status.isEdited);
}

- (void)_setGlobalID:(id)_gid {
  if (self->globalID) 
    return;

  ASSIGN(self->globalID,_gid);
  [self->createComment release]; self->createComment = nil;
  [self _registerForGID];
}

- (EOKeyGlobalID *)_gidFromId:(NSString *)_aid withEntity:(NSString *)_entity {
  if (_aid == nil)
    return nil;

  return [EOKeyGlobalID globalIDWithEntityName:_entity
			keys:&_aid keyCount:1
			zone:NULL];
}

- (EOKeyGlobalID *)_teamGidFromId:(NSString *)_teamId {
  return [self _gidFromId:_teamId withEntity:@"Team"];
}

- (EOKeyGlobalID *)_personGidFromId:(NSString *)_personId {
  return [self _gidFromId:_personId withEntity:@"Person"];
}

- (void)_loadDocument:(id)_job {
  [self setName:     [_job valueForKey:@"name"]];
  [self setStartDate:[_job valueForKey:@"startDate"]];
  [self setEndDate:  [_job valueForKey:@"endDate"]];

  [self setKeywords: [_job valueForKey:@"keywords"]];
  [self setCategory: [_job valueForKey:@"category"]];
  [self setStatus:   [_job valueForKey:@"jobStatus"]];
  [self setPriority: [_job valueForKey:@"priority"]];
  [self setType:     [_job valueForKey:@"type"]];      //comes from dataSource
  [self setActualWork:[_job valueForKey:@"actualWork"]];
  [self setTotalWork:[_job valueForKey:@"totalWork"]];
  [self setKilometers:[_job valueForKey:@"kilometers"]];

  [self setSensitivity:[_job valueForKey:@"sensitivity"]];
  [self setComment:[_job valueForKey:@"jobComment"]];
  [self setCompletionDate:[_job valueForKey:@"completionDate"]];
  [self setPercentComplete:[_job valueForKey:@"percentComplete"]];
  [self setAccountingInfo:[_job valueForKey:@"accountingInfo"]];
  [self setAssociatedContacts:[_job valueForKey:@"associatedContacts"]];
  [self setAssociatedCompanies:[_job valueForKey:@"associatedCompanies"]];
  
  [self _setObjectVersion:[_job valueForKey:@"objectVersion"]];
  
  if ([self isAttributeSupported:@"creator"]) {
    ASSIGN(self->creator, (id)nil);
    self->creator = 
      [[self _personGidFromId:[_job valueForKey:@"creatorId"]] retain];
  }
  if ([self isAttributeSupported:@"executor"]) {
    [self->executor release]; self->executor = nil;
    
    if ([[_job valueForKey:@"isTeamJob"] boolValue]) {
      self->isTeamJob = YES;
      self->executor =
        (id)[self _teamGidFromId:[_job valueForKey:@"executantId"]];
    }
    else
      self->executor =
        (id)[self _personGidFromId:[_job valueForKey:@"executantId"]];
    self->executor = [self->executor retain];
  }
  [self->createComment release]; self->createComment = nil;
  
  self->status.isComplete = (self->supportedAttributes == nil) ? YES : NO;
  self->status.isValid    = YES;
  self->status.isEdited   = NO;
}

/* EOGenericRecord */

/* compatibility with EOGenericRecord (is deprecated!!!)*/

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  NSAssert1((_key != nil), @"%s: key is nil", __PRETTY_FUNCTION__);
  if (_value == nil)
    return;
  
  if (![self isValid]) {
    [NSException raise:@"invalid job document"
                 format:@"cannot takeValue:forKey:%@, document %@ is invalid",
                   _key, self];
    return;
  }
  if (![self isComplete]) {
    [NSException raise:@"job document is not complete, use reload"
		 format:
		   @"cannot takeValue:forKey:%@, document %@ is incomplete",
                   _key, self];
    return;
  }
  if ([_key isEqualToString:@"name"])
    [self setName:_value];
  else if ([_key isEqualToString:@"startDate"])
    [self setStartDate:_value];
  else if ([_key isEqualToString:@"endDate"])
    [self setEndDate:_value];
  else if ([_key isEqualToString:@"keywords"])
    [self setKeywords:_value];
  else if ([_key isEqualToString:@"category"])
    [self setCategory:_value];
  else if ([_key isEqualToString:@"status"])
    [self setStatus:_value];
  else if ([_key isEqualToString:@"priority"])
    [self setPriority:_value];
  else if ([_key isEqualToString:@"type"])
    [self setType:_value];
  else if ([_key isEqualToString:@"creator"])
    [self setCreator:_value];
  else if ([_key isEqualToString:@"executor"])
    [self setExecutor:_value];

  else if ([_key isEqualToString:@"completionDate"])
    [self setCompletionDate:_value];
  else if ([_key isEqualToString:@"sensitivity"])
    [self setSensitivity:_value];
  else if ([_key isEqualToString:@"percentComplete"])
    [self setPercentComplete:_value];
  else if ([_key isEqualToString:@"actualWork"])
    [self setActualWork:_value];
  else if ([_key isEqualToString:@"totalWork"])
    [self setTotalWork:_value];
  else if ([_key isEqualToString:@"kilometers"])
    [self setKilometers:_value];
  else if ([_key isEqualToString:@"accountingInfo"])
    [self setAccountingInfo:_value];
  else {
    NSLog(@"ERROR(%s): unknown key: %@ (value: %@)",
          __PRETTY_FUNCTION__, _key, _value);
  }
}

- (id)valueForKey:(NSString *)_key {
  if ([self respondsToSelector:NSSelectorFromString(_key)])
    return [self performSelector:NSSelectorFromString(_key)];
  else if ([_key isEqualToString:@"globalID"])
    return self->globalID;

  return nil;
}

/* description */

- (void)appendAttributesToDescription:(NSMutableString *)_md {
  [super appendAttributesToDescription:_md];

  if (self->status.isEdited)   [_md appendString:@" edited"];
  if (self->status.isValid)    [_md appendString:@" valid"];
  if (self->status.isComplete) [_md appendString:@" complete"];

  if (self->supportedAttributes) {
    [_md appendFormat:@" attrs=%@",
	 [self->supportedAttributes componentsJoinedByString:@","]];
  }
  
  if (self->dataSource) {
    [_md appendFormat:@" ds=0x%08X[%@]", 
	   self->dataSource, NSStringFromClass([self->dataSource class])];
  }
  
  if (self->isTeamJob) [_md appendString:@" team-task"];
}

@end /* SkyJobDocument */
