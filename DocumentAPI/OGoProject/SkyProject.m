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
// $Id$

#include "SkyProject.h"
#include "SkyProjectDataSource.h"
#include "SkyProjectTeamDataSource.h"
#include <OGoDocuments/SkyDocumentType.h>
#include "common.h"

#include <OGoAccounts/SkyAccountDocument.h>

@interface NSObject(PreventWarnings)
- (id)initWithFileManager:(id)_fm
  context:(id)_ctx
  project:(id)_project
  path:(NSString *)_path;

- (id)initWithContext:(id)_context projectGlobalID:(EOGlobalID *)_gid;

@end /* NSObject(PreventWarnings) */

@interface SkyProject(PrivateMethodes)
- (EOKeyGlobalID *)_personGidFromId:(NSString *)_personId;
- (EOKeyGlobalID *)_teamGidFromId:(NSString *)_teamId;
- (void)_loadDocument:(id)_object;
@end

@interface SkyProjectDocType : SkyDocumentType
@end

/*
  dbStatus,
  isFake,
  status
*/

@implementation SkyProject

static NSNumber *noNum = nil;
static NSNull   *null  = nil;

+ (void)initialize {
  if (noNum == nil) noNum = [[NSNumber numberWithBool:NO] retain];
  if (null  == nil) null  = [[NSNull null] retain];
}

- (id)initWithContext:(id)_ctx {
  EODataSource *ds;
  NSDictionary *dict;
  id           own;
  
  own  = [_ctx valueForKey:LSAccountKey];
  ds   = [[[SkyProjectDataSource alloc] initWithContext:_ctx] autorelease];
  dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                              noNum,                          @"isFake",
                              [own valueForKey:@"companyId"], @"ownerId",
                              null ,                          @"kind",
                              [NSDate date],                  @"startDate",
                              @"05_processing",               @"status",
                              nil];
  return [self initWithEO:(id)dict dataSource:(id)ds];
}

- (id)initWithEO:(id)_eo dataSource:(SkyProjectDataSource *)_ds {
  if ((self = [super init])) {
    NSAssert(_ds, @"missing datasource ..");
  
    self->dataSource = [_ds retain];
    self->globalID   = [[_eo valueForKey:@"globalID"] retain];
    self->accounts        = nil;
    self->removedAccounts = nil;
    [self _loadDocument:_eo];
  }
  return self;
}

- (void)dealloc {
  [self->dataSource release];
  [self->globalID   release];
  [self->name       release];
  [self->startDate  release];
  [self->endDate    release];
  [self->number     release];
  [self->kind       release];
  [self->type       release];
  [self->leader     release];
  [self->team       release];
  [self->accounts   release];
  [self->removedAccounts release];
  [self->companyAssignmentsIds release];
  [super dealloc];
}

/* */

- (SkyDocumentType *)documentType {
  static SkyProjectDocType *docType = nil;
  
  if (docType == nil)
    docType = [[SkyProjectDocType alloc] init];
  
  return docType;
}

- (BOOL)isValid {
  return self->status.isValid;
}

- (void)invalidate {
  [self->globalID      release];  self->globalID  = nil;
  [self->name          release];  self->name      = nil;
  [self->startDate     release];  self->startDate = nil;
  [self->endDate       release];  self->endDate   = nil;
  [self->number        release];  self->number    = nil;
  [self->kind          release];  self->kind      = nil;
  [self->type          release];  self->type      = nil;
  [self->leader        release];  self->leader    = nil;
  [self->team          release];  self->team      = nil;
  [self->projectStatus release];  self->projectStatus = nil;
  [self->companyAssignmentsIds release]; self->companyAssignmentsIds = nil;
  [self->accounts        release]; self->accounts  = nil;
  [self->removedAccounts release]; self->removedAccounts = nil;
  
  self->status.isValid = NO;
}


- (BOOL)isComplete {
  if ([self isValid] == NO)
    return NO;
  
  return YES;
}

- (void)_setGlobalID:(id)_gid {
  if (self->globalID == nil)
    ASSIGN(self->globalID, _gid);
}
- (EOGlobalID *)globalID {
  return self->globalID;
}

- (NSNumber *)projectId {
  if (self->globalID) {
    return [(EOKeyGlobalID *)self->globalID keyValues][0];
  }
  return nil;
}

- (id)context {
  return [self->dataSource context];
}

/* accessors */

- (void)setName:(NSString *)_name {
  ASSIGNCOPY_IFNOT_EQUAL(self->name, _name, self->status.isEdited);
}
- (NSString *)name {
  return self->name;
}

- (void)setUrl:(NSString *)_url {
  ASSIGN(self->url, _url);
}
- (NSString *)url {
  return self->url;
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

- (void)setNumber:(NSString *)_number {
  ASSIGNCOPY_IFNOT_EQUAL(self->number, _number, self->status.isEdited);
}
- (NSString *)number  {
  return self->number;
}

- (void)setKind:(NSString *)_kind {
  ASSIGNCOPY_IFNOT_EQUAL(self->kind, _kind, self->status.isEdited);
}
- (NSString *)kind  {
  return self->kind;
}

/* leader */
- (void)setLeader:(SkyDocument *)_leader {
  //  id inputId   = nil;
  //  id currentId = nil;

  if (![self->leader isEqual:_leader]) {

    if ([self->leader isKindOfClass:[EOGlobalID class]]) {
      if (![[[(EOKeyGlobalID *)self->leader keyValuesArray] lastObject]
                           isEqual:[[(EOKeyGlobalID *)[_leader globalID]
                                                      keyValuesArray] lastObject]]) {
        self->status.isEdited = YES;
      }
    }
    else {
      self->status.isEdited = YES;
    }
    ASSIGN(self->leader, _leader);
  }
#if 0 // HH says: someone explain that!
  inputId = [[(EOKeyGlobalID *)[_leader globalID] keyValuesArray] lastObject];

  if ([self->leader isKindOfClass:[SkyDocument class]])
    currentId = [self->leader globalID];

  currentId = [[(EOKeyGlobalID *)currentId keyValuesArray] lastObject];

  if (![currentId isEqual:inputId]) {
    [self->leader release]; self->leader = nil;
    self->leader = [(id)[self _personGidFromId:inputId] retain];
    self->status.isEdited = YES;
  }
#endif  
}

- (SkyDocument *)leader {
  static Class         docClazz   = Nil;
  static EODataSource  *ds        = nil;
  EOGlobalID           *leaderGid = nil;
  id                   eo         = nil;
  
  if (![self->leader isKindOfClass:[EOGlobalID class]])
    return self->leader;

  if (docClazz == Nil)
    docClazz = NSClassFromString(@"SkyAccountDocument");
    
  if (ds == nil) {
    Class clazz = Nil;

    clazz = NSClassFromString(@"SkyAccountDataSource");
    ds    = [[clazz alloc] initWithContext:[self context]];
  }

  leaderGid = (EOGlobalID *)self->leader;

  eo = [[[self context] runCommand:@"object::get-by-globalID",
			@"gid", leaderGid, nil] lastObject];

  [self->leader release]; self->leader = nil;
  self->leader = [[docClazz alloc] initWithAccount:eo globalID:leaderGid
				   dataSource:ds];
  return self->leader;
}

/* team */

- (void)setTeam:(SkyDocument *)_team {
  id inputId   = nil;
  id currentId = nil;

  inputId = [[(EOKeyGlobalID *)[_team globalID] keyValuesArray] lastObject];

  if ([self->team isKindOfClass:[SkyDocument class]])
    currentId = [self->team globalID];

  currentId = [[(EOKeyGlobalID *)currentId keyValuesArray] lastObject];

  if (![currentId isEqual:inputId]) {
    [self->team release]; self->team = nil;
    self->team = [(id)[self _teamGidFromId:inputId] retain];
    self->status.isEdited = YES;
  }
}

- (SkyDocument *)team {
  Class                clazz;
  NSString             *teamId = nil;
  EODataSource         *ds;
  EOQualifier          *qual;
  EOFetchSpecification *fspec;
  
  if (![self->team isKindOfClass:[EOGlobalID class]])
    return self->team;

  teamId = [[(EOKeyGlobalID *)self->team keyValuesArray] lastObject];
  clazz = NSClassFromString(@"SkyTeamDataSource");
  ds    = [[clazz alloc] initWithContext:[self context]];
  qual  = [[EOKeyValueQualifier alloc]
                                  initWithKey:@"companyId"
                                  operatorSelector:EOQualifierOperatorEqual
                                  value:teamId];

  fspec = [EOFetchSpecification fetchSpecificationWithEntityName:@"Team"
				qualifier:qual
				sortOrderings:nil];
  [ds setFetchSpecification:fspec];
  [qual       release];
  [self->team release]; self->team = nil;
  self->team = [[[ds fetchObjects] lastObject] retain];
  
  return self->team;
}

- (void)setProjectAccounts:(NSArray *)_accounts {
  ASSIGN(self->projectAccounts, _accounts);
}

- (void)setStatus:(NSString *)_status {
  ASSIGN(self->projectStatus,_status);
}
- (NSString *)status {
  return self->projectStatus;
}

- (NSArray *)companyAssignmentsIds {
  return self->companyAssignmentsIds;
}

- (EODataSource *)teamDataSource {
  EODataSource *tds =
    [[SkyProjectTeamDataSource alloc] initWithProject:self
                                      context:[self context]];
  return AUTORELEASE(tds);
}

- (id)fileManager {
  Class class;

  NSLog(@"WARNING[%s] depricated ...", __PRETTY_FUNCTION__);

  if (!(class = NSClassFromString(@"SkyProjectFileManager")))
    class = NSClassFromString(@"SkyFSFileManager");
  
  return [[[class alloc] initWithContext:[self context]
                         projectGlobalID:[self globalID]] autorelease];
}

- (id)documentDataSource {
  Class class;
  id fm;
  
  NSLog(@"WARNING[%s] deprecated ...", __PRETTY_FUNCTION__);

  if ((class = NSClassFromString(@"SkyDocumentDataSource"))) {
    return [[[class alloc] initWithContext:[self context]
                           projectGlobalID:[self globalID]] autorelease];
  }
  if ((class = NSClassFromString(@"SkyFSDataSource")) == Nil)
    return nil;
  
  if ((fm = [self fileManager]) == nil) 
    return nil;
    
  return [[[class alloc] initWithFileManager:fm
			 context:[self context]
			 project:self
			 path:@"/"] autorelease];
}

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

/* key-value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  NSAssert1((_key != nil), @"%s: key is nil", __PRETTY_FUNCTION__);
  if (_value == nil)
    return;
  else if (![self isValid]) {
    [NSException raise:@"invalid job document"
                 format:@"cannot takeValue:forKey:%@, document %@ is invalid",
                 _key, self];
    return;
  }
  else if (![self isComplete]) {
    [NSException raise:@"job document is not complete, use reload"
               format:@"cannot takeValue:forKey:%@, document %@ is incomplete",
                   _key, self];
    return;
  }
  else if ([_key isEqualToString:@"name"])
    [self setName:_value];
  else if ([_key isEqualToString:@"startDate"])
    [self setStartDate:_value];
  else if ([_key isEqualToString:@"endDate"])
    [self setEndDate:_value];
  else if ([_key isEqualToString:@"leader"])
    [self setLeader:_value];
  else if ([_key isEqualToString:@"team"])
    [self setTeam:_value];
  else if ([_key isEqualToString:@"number"])
    [self setNumber:_value];
  else if ([_key isEqualToString:@"kind"])
    [self setKind:_value];
  else if ([_key isEqualToString:@"url"])
    [self setUrl:_value];
  else if ([_key isEqualToString:@"accounts"]) {
    [self setProjectAccounts:_value];
  }
  else if ([_key isEqualToString:@"type"]) {
    ASSIGN(self->type, _value);
  }
}

- (id)valueForKey:(NSString *)_key {
  if ([self respondsToSelector:NSSelectorFromString(_key)])
    return [self performSelector:NSSelectorFromString(_key)];
  
  if ([_key isEqualToString:@"type"])
    return (self->type) ? self->type : (id)null;
  if ([_key isEqualToString:@"projectId"])
    return [[(EOKeyGlobalID *)self->globalID keyValuesArray] lastObject];
  if ([_key isEqualToString:@"leaderName"])
    return [[self leader] valueForKey:@"login"];
  if ([_key isEqualToString:@"accounts"])
    return self->projectAccounts;
  if ([_key isEqualToString:@"url"])
    return self->url;

  return nil;
}

- (NSString *)description {
  NSString *str;

  str = [super description];

  str = [str stringByAppendingFormat:@" leader globalID %@; type:%@; "
             @"leader %@ url: %@",
             self->globalID, self->type, self->leader, self->url];
  return str;
}

// rwid
// changes will take efect after save
- (void)addAccount:(SkyDocument *)_account withAccess:(NSString *)_access {
  if ((_account != nil) && (_access != nil)) {
    if (self->accounts == nil)
      self->accounts = [[NSMutableDictionary alloc] initWithCapacity:8];
    [self->accounts setObject:_access forKey:_account];
  }
}
- (void)removeAccount:(SkyDocument *)_account {
  if (_account != nil) {
    if (self->removedAccounts == nil)
      self->removedAccounts = [[NSMutableArray alloc] init];
    [self->removedAccounts addObject:_account];
  }
}

- (NSDictionary *)asDict {
  // TODO: split up this method?
  NSMutableDictionary *dict;
  NSNumber            *projectId;

  dict      = [NSMutableDictionary dictionaryWithCapacity:16];
  projectId = [[(EOKeyGlobalID *)self->globalID keyValuesArray] lastObject];

  if (projectId != nil)
    [dict setObject:projectId forKey:@"projectId"];

  [dict takeValue:[self name]      forKey:@"name"];
  [dict takeValue:[self startDate] forKey:@"startDate"];
  [dict takeValue:[self endDate]   forKey:@"endDate"];
  [dict takeValue:[self number]    forKey:@"number"];
  [dict takeValue:[self kind]      forKey:@"kind"];
  [dict takeValue:[self url]       forKey:@"url"];
  {
    id s = [self status];
    [dict takeValue:s?s:@"05_processing" forKey:@"status"];
  }

  [dict takeValue:noNum forKey:@"isFake"];

  {
    id leaderId = self->leader;

    if ([leaderId isKindOfClass:[SkyDocument class]])
      leaderId = [leaderId globalID];

    leaderId = [[(EOKeyGlobalID *)leaderId keyValuesArray] lastObject];
    [dict takeValue:leaderId forKey:@"ownerId"];
  }

  {
    id teamId = self->team;

    if ([teamId isKindOfClass:[SkyDocument class]])
      teamId = [teamId globalID];

    teamId = [[(EOKeyGlobalID *)teamId keyValuesArray] lastObject];
    [dict takeValue:teamId forKey:@"teamId"];
  }

  {
    NSEnumerator   *e   = [self->accounts keyEnumerator];
    id             one  = nil;
    NSMutableArray *all = [NSMutableArray array];
    id             tmp  = nil;

    // adding accounts
    while ((one = [e nextObject])) {
      tmp = [(SkyAccountDocument *)one asEO];
      [tmp takeValue:[self->accounts valueForKey:one] forKey:@"accessRight"];
      [all addObject:tmp];
    }

    if ([all count])
      [dict takeValue:all forKey:@"accounts"];

    e   = [self->removedAccounts objectEnumerator];
    all = [NSMutableArray array];

    while ((one = [e nextObject])) {
      [all addObject:[one asEO]];
    }
    if ([all count])
      [dict takeValue:all forKey:@"removedAccounts"];
  }
  return dict;
}

- (BOOL)reload {
  NSArray *array;
  id obj;
  
  if ([self isValid] == NO)
    return NO;

  if ([self globalID] == nil) {
    [self invalidate];
    return YES;
  }

  obj = [[[self context] runCommand:@"object::get-by-globalid",
			 @"gid", [self globalID], nil] lastObject];
  array = [NSArray arrayWithObject:obj];
    
  [[self context] runCommand:@"project::get-company-assignments",
                    @"objects",     array,
                    @"relationKey", @"companyAssignments", nil];

  [[self context] runCommand:@"project::get-team",
                    @"objects", array, @"relationKey", @"team", nil];
  
  [[self context] runCommand:@"project::get-owner",
                    @"objects", array, @"relationKey", @"owner", nil];

  [self _loadDocument:obj];
  return YES;
}

@end /* SkyProject */

@implementation SkyProjectDocType
@end /* SkyProjectDocType */


@implementation SkyProject(PrivateMethods)

- (EOKeyGlobalID *)_personGidFromId:(NSString *)_personId {
  EOKeyGlobalID *result = nil;
  id values[1];
  
  if (_personId == nil)
    return nil;

  values[0] = _personId;
  result    = [EOKeyGlobalID globalIDWithEntityName:@"Person"
			     keys:values keyCount:1
			     zone:[self zone]];
  return result;
}

- (EOKeyGlobalID *)_teamGidFromId:(NSString *)_teamId{
  EOKeyGlobalID *result = nil;
  id values[1];
  
  if (_teamId == nil)
    return nil;

  values[0] = _teamId;
  result    = [EOKeyGlobalID globalIDWithEntityName:@"Team"
			     keys:values keyCount:1
			     zone:[self zone]];
  return result;
}

- (void)_loadDocument:(id)_object {
  [self setName:      [_object valueForKey:@"name"]];
  [self setStartDate: [_object valueForKey:@"startDate"]];
  [self setEndDate:   [_object valueForKey:@"endDate"]];
  [self setNumber:    [_object valueForKey:@"number"]];
  [self setKind:      [_object valueForKey:@"kind"]];
  [self setStatus:    [_object valueForKey:@"status"]];
  [self setUrl:       [_object valueForKey:@"url"]];
  
  if (![self->type isNotNull]) {
    [self->type release]; self->type = nil;
    self->type = [[_object valueForKey:@"type"] copy];
  }

  [self->leader release]; self->leader = nil;
  self->leader = 
    [[self _personGidFromId:[_object valueForKey:@"ownerId"]] copy];
  
  [self->team release]; self->team = nil;
  self->team = [[self _teamGidFromId:[_object valueForKey:@"teamId"]] copy];
  
  [self->accounts        release]; self->accounts = nil;
  [self->removedAccounts release]; self->removedAccounts = nil;

  [self->companyAssignmentsIds release];
  self->companyAssignmentsIds = [_object valueForKey:@"companyAssignments"];
  self->companyAssignmentsIds =
    [[self->companyAssignmentsIds valueForKey:@"companyId"] retain];
  
  self->status.isValid     = YES;
  self->status.isComplete  = YES;
  self->status.isEdited    = NO;
}

- (EOGlobalID *)leader_id {
  return (id)self->leader;
}
- (EOGlobalID *)team_id {
  return (id)self->team;
}

@end /* SkyProject(PrivateMethodes) */
