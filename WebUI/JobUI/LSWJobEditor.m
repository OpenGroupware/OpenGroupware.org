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

#include "LSWJobEditor.h"
#include "LSWJobMailPage.h"
#include "common.h"
#include <NGObjWeb/WOMailDelivery.h>
#include <OGoFoundation/LSWNotifications.h>
#include <EOControl/EOControl.h>
#include <LSFoundation/OGoObjectLinkManager.h>
#include <LSFoundation/OGoObjectLink.h>
#include <OGoFoundation/LSWMailEditorComponent.h>

#include <OGoJobs/SkyPersonJobDataSource.h>

static int compareAccounts(id e1, id e2, void* context) {
  BOOL isTeam1 = [[e1 valueForKey:@"isTeam"] boolValue];
  BOOL isTeam2 = [[e2 valueForKey:@"isTeam"] boolValue];

  if (isTeam1) {
    if (!isTeam2)
      return NSOrderedAscending;

    return [[e1 valueForKey:@"description"]
                caseInsensitiveCompare:[e2 objectForKey:@"description"]];
  }
  if (isTeam2)
    return NSOrderedDescending;

  return [[e1 valueForKey:@"name"]
              caseInsensitiveCompare:[e2 objectForKey:@"name"]];
}

@interface LSWJobEditor(Private)
- (id)_save;
- (BOOL)preferredExecutantsEnabled;
@end /* LSWJobEditor(Private) */

@interface NSArray(IntNumArray)
- (NSArray *)arrayByConvertingValuesToIntNumbers;
@end

@implementation NSArray(IntNumArray)

- (NSArray *)arrayByConvertingValuesToIntNumbers {
  unsigned i, count;
  NSMutableArray *a;

  count = [self count];
  a = [NSMutableArray arrayWithCapacity:count];
  for (i = 0; i < count; i++)
    [a addObject:[NSNumber numberWithInt:[[self objectAtIndex:i] intValue]]];
  return a;
}

@end /* NSArray(IntNumArray) */

@implementation LSWJobEditor

static NSArray *JobAttrsEditor_percentages = nil;
static NSArray *JobAttrsEditor_priorities  = nil;
static NSArray *defNotifyList   = nil;
static NSArray *defNotifyLabels = nil;

static BOOL JobAttributesCollapsible = NO;
static BOOL PreferredAccountsEnabled = NO;
static BOOL HasSkyProject4Desktop    = NO;

static inline NSNumber *Int2Number(int _nr) {
  return [NSNumber numberWithInt:_nr];
}

+ (int)version {
  return [super version] + 1;
}
+ (void)initialize {
  // TODO: check superclass version
  NSUserDefaults  *ud = [NSUserDefaults standardUserDefaults];
  NGBundleManager *bm = [NGBundleManager defaultBundleManager];
  static BOOL didInit = NO;
  if (didInit) return;
  didInit = YES;
  
  JobAttributesCollapsible = [ud boolForKey:@"JobReferredPersonEnabled"];
  PreferredAccountsEnabled = [ud boolForKey:@"JobPreferredExecutantsEnabled"];

  HasSkyProject4Desktop = [bm bundleProvidingResource:@"SkyProject4Desktop"
			      ofType:@"WOComponents"] != nil ? YES : NO;
  
  JobAttrsEditor_percentages =
    [[[ud arrayForKey:@"JobAttrsEditor_percentages"] 
          arrayByConvertingValuesToIntNumbers] copy];
  JobAttrsEditor_priorities =
    [[[ud arrayForKey:@"JobAttrsEditor_priorities"] 
          arrayByConvertingValuesToIntNumbers] copy];

  defNotifyList = [[NSArray alloc] initWithObjects:
				     Int2Number(0),
				     Int2Number(1),
				     Int2Number(2),
				   nil];
  defNotifyLabels = [[NSArray alloc] initWithObjects:@"Never", @"Always",
				       @"OnAcceptDone", nil];
}

- (id)init {
  if ((self == [super init])) {
    self->isProjectEnabled = HasSkyProject4Desktop;
    
    self->resultList = [[NSMutableArray alloc] initWithCapacity:16];
    self->noOfCols   = -1;
    self->selPrefAccounts = [[NSMutableArray alloc] initWithCapacity:16];
  }
  return self;
}

- (void)dealloc {
  [self->item                release];
  [self->parentJob           release];
  [self->project             release];
  [self->notifyList          release];
  [self->teams               release];
  [self->team                release];
  [self->executantSelection  release];
  [self->resultList          release];
  [self->searchAccount       release];
  [self->snapshotCopy        release];
  [self->notifyLabels        release];
  [self->accountLabelFormat  release];
  [self->referredPerson      release];
  [self->selPrefAccounts     release];
  [super dealloc];
}

/* accessors */

- (NSArray *)sensitivities {
  return [NSArray arrayWithObjects:
                  [NSNumber numberWithInt:1],
                  [NSNumber numberWithInt:2],
                  [NSNumber numberWithInt:3],
                  [NSNumber numberWithInt:4],
                  nil];
}

- (NSString *)sensitivity {
  NSString *s;

  s = [@"sensitivity_" stringByAppendingString:[item stringValue]];
  return [[self labels] valueForKey:s];
}

- (void)setProject:(id)_project { 
  ASSIGN(self->project, _project);
}
- (id)project {
  return self->project;
}

- (void)setNotifyExecutant:(BOOL)_notify {
  self->notifyExecutant = _notify;
}
- (BOOL)notifyExecutant {
  return self->notifyExecutant;
}

- (void)setNotifyList:(NSArray *)_notifyList {
  ASSIGN(self->notifyList, _notifyList);
}
- (NSArray *)notifyList {
  return self->notifyList;
}

- (void)setItem:(id)_item { 
  ASSIGN(self->item, _item);
}
- (id)item {
  return self->item;
}

- (void)setExecutantSelection:(id)_ex {
  ASSIGN(self->executantSelection, _ex);
}
- (id)executantSelection {
  return self->executantSelection;
}

- (void)setIsSelected:(BOOL)_flag {
  if (_flag) {
    [self setExecutantSelection:self->item];
  }
}
- (BOOL)isSelected {
  return [self->item isEqual:self->executantSelection];
}

- (void)setTeam:(id)_id {
  ASSIGN(self->team, _id);
}
- (id)team {
  return self->team;
}

- (void)setSearchAccount:(NSString *)_str {
  ASSIGN(self->searchAccount, _str);
}
- (NSString *)searchAccount {
  return self->searchAccount;
}

- (void)setIdx:(int)_idx {
  self->idx = _idx;
}
- (int)idx {
  return self->idx;
}

- (NSString *)priorityName {
  NSString *pri;

  pri = [@"priority_" stringByAppendingFormat:@"%d", [self->item intValue]];
  pri = [[self labels] valueForKey:pri];
  
  if (pri == nil)
    pri = [self->item stringValue];
  return pri;
}

- (NSString *)notifyItem {
  NSString *s;

  s = [self->notifyLabels objectAtIndex:[self->item intValue]];
  return [[self labels] valueForKey:s];
}

- (NSDictionary *)job {
  return [self snapshot];
}

- (BOOL)isCommentMode {
  return ([self isInNewMode] || self->isImportMode);
}

- (NSString *)jobUrl:(id)_job {
  WOContext *ctx;
  NSString  *urlPrefix;
  NSString  *url;

  // TODO: use the WOContext URL generation methods!
  ctx       = [self context];
  urlPrefix = [ctx urlSessionPrefix];
  url       = [[ctx request] headerForKey:@"x-webobjects-server-url"];
  
  if (url != nil && [url length] > 0) {
    return [NSString stringWithFormat:
                     @"%@%@/wa/LSWViewAction/viewJob?jobId=%@",
                     url, urlPrefix, [_job valueForKey:@"jobId"]];
  }
  else {
    return [NSString stringWithFormat:
                     @"http://%@%@/wa/LSWViewAction/viewJob?jobId=%@",
                     [[ctx request] headerForKey:@"host"],
                     urlPrefix, [_job valueForKey:@"jobId"]];
  }
}


- (BOOL)showProjectName {
  return (self->isProjectLinkMode || self->isEnterpriseLinkMode ||
          (self->project != nil));
}

- (BOOL)showProjectSelection {
  return !(self->isProjectLinkMode || self->isEnterpriseLinkMode);
}

- (NSArray *)teams {
  return self->teams;
}

- (NSString *)noProjectLabel {
  NSString *l;

  l = [[self labels] valueForKey:@"noProject"];
  return (l != nil) ? l : @"- no project -";
}

- (BOOL)hasExecutants {
  return ([self->executantSelection isNotNull] ||
          [self->resultList count] > 0) ? YES : NO;
}

- (BOOL)hasResultList {
  return ([self->resultList count] > 0) ? YES : NO;
}

- (NSArray *)resultList {
  if (([self->resultList count] == 0) &&
      ([self->executantSelection isNotNull]))
    [self->resultList addObject:self->executantSelection];
  return self->resultList;
}

- (void)setExecutant:(id)_ex {
  [self setExecutantSelection:_ex];
}

- (BOOL)isTeamSelected {
  return [[self->executantSelection objectForKey:@"isTeam"] boolValue];
}

- (int)noOfCols {
  if (self->noOfCols == -1) {
    id  d;
    int n;
    
    d = [[[self session] userDefaults] objectForKey:@"job_no_of_cols"];
    n = [d intValue];
    self->noOfCols =  (n > 0) ? n : 3;
  }
  return self->noOfCols;
}

- (BOOL)startNewLine {
  if (self->idx == 0) return NO; // first line always exists
  return ((self->idx % [self noOfCols]) == 0) ? YES : NO;
}

/* TODO: the following is weird, just register the default default */
- (NSString *)defaultAccountLableFormat {
  return @"$name$, $firstname$ ($login$)";
}
- (NSString *)accountLabelFormat {
  if (self->accountLabelFormat == nil) {
    NSUserDefaults *ud;
    
    ud = [[self session] userDefaults];
    self->accountLabelFormat = 
      [ud stringForKey:@"job_editor_account_format"];
    if ([self->accountLabelFormat length] == 0)
      self->accountLabelFormat = [self defaultAccountLableFormat];
    self->accountLabelFormat = [self->accountLabelFormat copy];
  }
  return self->accountLabelFormat;
}

- (NSString *)accountDescription {
  return [[self accountLabelFormat]
                stringByReplacingVariablesWithBindings:self->item
                stringForUnknownBindings:@""];
}

- (NSString *)teamDescription {
  return [NSString stringWithFormat:@"Team: %@",
                   [self->item valueForKey:@"description"]];
}

- (NSString *)labelForAccount:(id)_part {
  if ([[_part valueForKey:@"isTeam"] boolValue])
    return [_part valueForKey:@"description"];

  return [[self accountLabelFormat]
                stringByReplacingVariablesWithBindings:_part
                stringForUnknownBindings:@""];
}

- (BOOL)hasTeam {
  return (self->team == nil) ? NO : YES;
}

- (NSString *)teamName {
  return [self->item valueForKey:@"description"];
}

- (BOOL)isProjectEnabled {
  return self->isProjectEnabled;
}

- (BOOL)userIsCreator {
  return [[[[self session] activeAccount] valueForKey:@"companyId"]
                  isEqual:[[self object] valueForKey:@"creatorId"]];
}
- (BOOL)showExecutantSelection {
  if ([self isInNewMode]) return YES;
  return [self userIsCreator];
}

- (NSArray *)percentList {
  NSArray  *pList;
  id       jobPercent;
  
  pList = JobAttrsEditor_percentages;
  
  jobPercent = [[self job] valueForKey:@"percentComplete"];
  if ([jobPercent isNotNull] && ![pList containsObject:jobPercent]) {
    NSMutableArray *md;
    
    md = [pList mutableCopy];
    [md addObject:[NSNumber numberWithInt:[jobPercent intValue]]];
    pList = [md sortedArrayUsingSelector:@selector(compare:)];
    [md release];
  }
  return pList;
}

- (void)clearEditor {
  [self->item      release]; self->item      = nil;
  [self->parentJob release]; self->parentJob = nil;
  [super clearEditor];        
}

/* commands */

- (id)_fetchProject:(id)_projectId {
  NSArray *p = nil;

  p = [self runCommand:@"project::get",
            @"projectId", _projectId, nil];

  return ([p count] > 0) ? [p lastObject] : nil;
}

- (NSArray *)_resolveAccountsOfTeamEO:(id)_team {
  return [self runCommand:@"team::resolveaccounts", @"staff", _team, nil];
}

- (NSArray *)_fetchMemberEOsOfTeamEO:(id)_team {
  return [self runCommand:@"team::members", @"object", _team, nil];
}

- (NSArray *)_searchAccountEOsMatchingString:(NSString *)_s {
  return [self runCommand:@"account::extended-search",
	         @"operator",    @"OR",
                 @"name",        _s,
                 @"firstname",   _s,
                 @"description", _s,
                 @"login",       _s,
	       nil];
}

- (id)_createJobWithArguments:(NSDictionary *)_args {
  return [self runCommand:@"job::new" arguments:_args];
}

- (void)_addLogForGlobalID:(EOKeyGlobalID *)_gid 
  action:(NSString *)_action comment:(NSString *)_comment
{
  [self runCommand:@"object::add-log",
	  @"objectId", [_gid keyValues][0], 
	  @"logText", _comment,
	  @"action",  _action, nil];
}
- (void)_commentJobEO:(id)_eo comment:(NSString *)_comment {
  [self runCommand:@"job::jobaction", 
	  @"object",  _eo,
	  @"action",  @"comment",
	  @"comment", _comment,
	nil];
}

/* activation */

- (BOOL)activateForImport {
  NSMutableDictionary *snap;
  
  [self setObject:[[self session] getTransferObject]];

  snap = [[self object] mutableCopy];
  [self setSnapshot:snap];
  [snap release];
  
  self->project =
    [[self _fetchProject:[[self object] valueForKey:@"projectId"]] retain];
  return YES;
}

- (BOOL)prepareForActivationCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  // TODO: clean up!
  WOSession *sn;

  sn = [self session];
  
  self->isProjectLinkMode    = [[_type subType]
                                       isEqualToString:@"project-job"];
  self->isEnterpriseLinkMode = [[_type subType]
                                       isEqualToString:@"enterprise-job"];  
  self->isImportMode         = [[_type type] isEqualToString:@"dict"];

  if (self->teams == nil) {
    // TODO: use commands!
#warning uses [session teams]
    self->teams = [[sn teams] retain];
  }
  
  if (self->isImportMode)
    return [self activateForImport];
  
  if ((self->isProjectLinkMode) ||
      (self->isEnterpriseLinkMode))
    self->project = [[self session] getTransferObject];
  
  ASSIGN(self->notifyList,   defNotifyList);
  ASSIGN(self->notifyLabels, defNotifyLabels);
  
  return [super prepareForActivationCommand:_command type:_type
                configuration:_cmdCfg];
}

- (BOOL)prepareForNewCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  WOSession *sn;
  id        job;
  id        pJob = nil;
  NSCalendarDate *now;
  
  now = [NSCalendarDate date];
  sn  = [self session];
  job = [self snapshot];
  
  [job takeValue:now forKey:@"startDate"];
  {
    NSCalendarDate *date;
    id  tmp;
    int days;
    
    tmp = [[sn userDefaults] objectForKey:@"job_defaultDuration"];
    if (tmp == nil) days = 7;
    else {
      days = [tmp intValue];
      if (days < 0) days = 7;
    }
    date = [now dateByAddingYears:0 months:0 days:days
                 hours:0 minutes:0 seconds:0];
    [job takeValue:date forKey:@"endDate"];
  }
  
  [job takeValue:[NSNumber numberWithInt:3] forKey:@"priority"];
  
  if (!self->isProjectLinkMode && !self->isEnterpriseLinkMode) {
    pJob = [sn getTransferObject];
    
    if (pJob != nil) {
      id p;
      
      p = [self _fetchProject:[pJob valueForKey:@"projectId"]];
      self->project = [p retain];;
      
      [job takeValue:pJob forKey:@"toParentJob"];
      [job takeValue:[pJob valueForKey:@"jobId"] forKey:@"parentJobId"];
      self->parentJob = [pJob retain];
    }
  }

  ASSIGN(self->executantSelection, [[self session] activeAccount]);
  
  return YES;
}

- (BOOL)prepareForEditCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  id job;
  id obj;
  id p;
  
  job = [self snapshot];
  obj = [self object];
  p   = [self _fetchProject:[obj valueForKey:@"projectId"]];
  
  RELEASE(self->executantSelection);
  self->executantSelection = [obj valueForKey:@"executant"];
  RETAIN(self->executantSelection);
  [job takeValue:self->executantSelection forKey:@"executant"];

  ASSIGN(self->project, p);
  self->snapshotCopy = [[self snapshot] copyWithZone:[self zone]];

  return YES;
}

/* accessors */

- (NSArray *)priorities {
  return JobAttrsEditor_priorities;
}

- (BOOL)checkPreferredExecutantsConstraintsForSave {
        NSArray      *acc;
        id            obj;
        NSEnumerator *enumerator;
	
  if (![self preferredExecutantsEnabled])
    return YES;
  if ([self->selPrefAccounts count] == 0)
    return YES;

  if (![[self->executantSelection entityName] isEqual:@"Team"]) {
    NSString *s;
    
    s = [[self labels] valueForKey:
		  @"Preferred executants allowed only if executant is a team"];
    [self setErrorString:s];
    return NO;
  }
  
  acc = [self _resolveAccountsOfTeamEO:self->executantSelection];
  enumerator = [self->selPrefAccounts objectEnumerator];
  
  while ((obj = [enumerator nextObject])) {
    NSString *s;
    
    if ([acc containsObject:obj])
      continue;
    
    s = @"Preferred executant %@ is not in selected team %@.";
    s = [NSString stringWithFormat:[[self labels] valueForKey:s],
		    [self labelForAccount:obj],
		    [self labelForAccount:self->executantSelection]];
    [self setErrorString:s];
  }
  return YES;
}
- (BOOL)checkConstraintsForSave {
  // TODO: fix this huge method
  NSMutableString *error = nil;
  id              labels = nil;
  id              job    = nil;
  NSTimeZone      *tz    = nil;
  NSString        *n     = nil;
  NSCalendarDate  *sD    = nil;
  NSCalendarDate  *eD    = nil;

  tz  = [[self session] timeZone];
  job = [self snapshot];
  n   = [job valueForKey:@"name"];
  sD  = [job valueForKey:@"startDate"];
  eD  = [job valueForKey:@"endDate"];

  labels = [self labels];
  error  = [NSMutableString stringWithCapacity:128];
  
  if (![n isNotNull]) {
    [error appendString:[labels valueForKey:@"error_no_name"]];
  }
  else if (![sD isNotNull]) {
    [error appendString:[labels valueForKey:@"error_no_start_date"]];
  }
  else if (![eD isNotNull]) {
    [error appendString:[labels valueForKey:@"error_no_end_date"]];
  }
  else {
    [sD setTimeZone:tz];
    [eD setTimeZone:tz];

    if ([[sD beginOfDay] compare:[eD beginOfDay]] == NSOrderedDescending) {
      [error appendString:[labels valueForKey:@"error_end_before_start"]];
    }
    else {
      id p;
      
      if ([self isInNewMode]) {
        NSCalendarDate *nowDate = [NSCalendarDate date];

        [nowDate setTimeZone:tz];

        if ([[nowDate beginOfDay] compare:[sD beginOfDay]]
            == NSOrderedDescending) {
          [error appendString:[labels valueForKey:@"error_start_before_now"]];
        }
        p = self->project;
      }
      else {
        p =  [[self object] valueForKey:@"toParentJob"];

        if (![p isNotNull] ||
            [[p valueForKey:@"isControlJob"] boolValue]) {
          p = self->project;
        }
      }
    }
  }
  if ([error length] > 0) {
    [self setErrorString:error];
    return NO;
  }

  if (![self checkPreferredExecutantsConstraintsForSave])
    return NO;
  
  [self setErrorString:nil];
  return [super checkConstraintsForSave];
}
  
- (NSString *)changeStringForLabel:(NSString *)_labelName
  withValue:(id)_value
{
  NSString *label;

  label = [[self labels] valueForKey:_labelName];
  return [NSString stringWithFormat:@"%@: %@\n", label, _value];
}

/* notifications */

- (NSString *)insertNotificationName {
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  
  [nc postNotificationName:SkyNewJobNotification object:nil];

  return LSWJobHasChanged;
}

- (NSString *)updateNotificationName {
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  
  [nc postNotificationName:SkyUpdatedJobNotification object:nil];

  return LSWJobHasChanged;
}

- (NSString *)deleteNotificationName {
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  
  [nc postNotificationName:SkyDeletedJobNotification object:nil];

  return LSWJobHasChanged;
}

/* actions */

- (id)search {
  NSArray *result = nil;

  [self setErrorString:nil];
  [self->resultList removeAllObjects];
  
  if (![self->team isNotNull]) { /* Search accounts with searchAccount field */
    result = [self _searchAccountEOsMatchingString:self->searchAccount];
    if (result != nil)
      [self->resultList addObjectsFromArray:result];
  }
  else { /* take accounts from team */    
    NSArray *acc;

    if ([[[self->executantSelection globalID] entityName] isEqual:@"Team"]) {
      ASSIGN(self->executantSelection, nil);
      [self->resultList removeObject:self->executantSelection];
    }
    
    acc = [self _resolveAccountsOfTeamEO:self->team];
    if (acc != nil)
      [self->resultList addObjectsFromArray:acc];

    if (![self->resultList containsObject:self->team])
      [self->resultList addObject:self->team];
  }
  if (self->executantSelection &&
      ![self->resultList containsObject:self->executantSelection])
    [self->resultList addObject:self->executantSelection];

  [self->resultList sortUsingFunction:compareAccounts context:NULL];
    
  if ([self->resultList count] > 0)
    self->executantSelection = [[self->resultList objectAtIndex:0] retain];
  
  return nil;
}

- (id)sendMessage {
  id<LSWMailEditorComponent,LSWContentPage> editor;
  NSString *subject = nil;
  id       obj;
  
  obj      = [self object];
  if ([obj isKindOfClass:[NSArray class]]) {
    if ([(NSArray *)obj count] > 0) {
      obj = [obj objectAtIndex:0];
    }
    else {
      [self logWithFormat:@"WARNING: No job found"];
      return nil;
    }
  }

  editor = (id)[self pageWithName:@"LSWImapMailEditor"];
  [self enterPage:editor];

  subject = [NSString stringWithFormat:@"%@: '%@' %@ %@",
                      [[self labels] valueForKey:@"job"],
                      [obj valueForKey:@"name"],
                      [[self labels] valueForKey:@"createLabel"],
                      [[[self session] activeAccount] valueForKey:@"login"]];

  [editor setSubject:subject];
  [editor setContentWithoutSign:@""];

  if ([self isTeamSelected]) {
    NSArray *m = [self->executantSelection valueForKey:@"members"];
    int     i, cnt = 0;

    if (m == nil)
      m = [self _fetchMemberEOsOfTeamEO:self->executantSelection];
    
    for (i = 0, cnt = [m count]; i < cnt; i++)
      [editor addReceiver:[m objectAtIndex:i] type:@"to"];
  }
  else 
    [editor addReceiver:self->executantSelection type:@"to"];

  [editor addAttachment:obj type:[NGMimeType mimeType:@"eo" subType:@"job"]];

  return [editor send];
}

- (id)insertObject {
  id job;

  job = [self snapshot];
  
  if ([self isTeamSelected]) { /* a team is the executant */
    [job takeValue:[self->executantSelection valueForKey:@"companyId"]
         forKey:@"executantId"];
    [job takeValue:[NSNumber numberWithBool:YES] forKey:@"isTeamJob"];

    if (([job valueForKey:@"parentJobId"] != nil) &&
        [[job valueForKey:@"parentJobId"] isNotNull]) {
      NSString *dComment = nil;

      dComment = [NSString stringWithFormat:@"%@ %@: %@",
                           [[self labels] valueForKey:@"subJobLabel"],
                           [self->team valueForKey:@"description"],
                           [job valueForKey:@"name"]];

      [job takeValue:dComment forKey:@"divideComment"];
    }
    if ([self->project isNotNull]) {
      [job takeValue:self->project forKey:@"project"];
    }
  }
  else { /* only one executant */
    id ex  = self->executantSelection;
    
    [job takeValue:[ex valueForKey:@"companyId"] forKey:@"executantId"];
    [job takeValue:[NSNumber numberWithBool:NO] forKey:@"isTeamJob"];

    if (([job valueForKey:@"parentJobId"] != nil) &&
        [[job valueForKey:@"parentJobId"] isNotNull]) {
      NSString *dComment = nil;

      dComment = [NSString stringWithFormat:@"%@ %@: %@",
                           [[self labels] valueForKey:@"subJobLabel"],
                           [ex valueForKey:@"login"],
                           [job valueForKey:@"name"]];

      [job takeValue:dComment forKey:@"divideComment"];
    }
    if (self->project) {
      [job takeValue:self->project forKey:@"project"];
    }
  }
  job = [self _createJobWithArguments:job];
  
  if ([self preferredExecutantsEnabled]) {
    NSEnumerator         *enumerator;
    id                   obj, l;
    OGoObjectLinkManager *lm;
    EOGlobalID           *gid;
    NSString             *teamLabel;
    
    enumerator = [self->selPrefAccounts objectEnumerator];
    lm         = [[[self session] commandContext] linkManager];
    gid        = [job globalID];
    l          = [self labels];
    teamLabel  = [self labelForAccount:self->executantSelection];

    while ((obj = [enumerator nextObject])) {
      OGoObjectLink *link;
      NSString      *label;

      label = [self labelForAccount:obj];
      link  = [[OGoObjectLink alloc] initWithSource:(EOKeyGlobalID *)gid
                                     target:(EOKeyGlobalID *)[obj globalID]
                                     type:@"Preferred Job Executant"
                                     label:label];
      [lm createLink:link];
      [link release]; link = nil;
      
      [self _addLogForGlobalID:(EOKeyGlobalID *)gid action:@"created"
	    comment:[NSString stringWithFormat:
				[l valueForKey:
				     @"Add job link to  %@ [team:%@]."],
			      label, teamLabel]];
    }
  }
  return job;
}

- (id)updateObject {
  id job;
  
  job = [self snapshot];
  [job removeObjectForKey:@"executant"];
  [job removeObjectForKey:@"object"];
  
  [job takeValue:[self->executantSelection valueForKey:@"companyId"]
       forKey:@"executantId"];

  if ([self isTeamSelected])
    [job takeValue:[NSNumber numberWithBool:YES] forKey:@"isTeamJob"];
  else
    [job takeValue:[NSNumber numberWithBool:NO] forKey:@"isTeamJob"];

  if ([self->project isNotNull]) {
    [job takeValue:[self->project valueForKey:@"projectId"]
         forKey:@"projectId"];
  }
  else {
    [job takeValue:[NSNull null] forKey:@"projectId"];
  }

  return [self runCommand:@"job::set" arguments:job];
}

- (id)deleteObject {
  return [self runCommand:@"job::delete", 
	         @"object", [self object],
		 @"reallyDelete", [NSNumber numberWithBool:NO],
	       nil];
}

- (id)save {
  if ([self isInNewMode]) {
    // TODO: move to own method?
    if (![self->executantSelection isNotNull]) {
      [self setErrorString:
            [[self labels] valueForKey:@"NoTeamAndExecutantsWasSelected"]];
      return nil;
    }

    if (self->referredPerson != nil) {
      BOOL access;
      id   acManager;

      acManager = [[[self session] commandContext] accessManager];
      access    = [acManager operation:@"rw"
                             allowedOnObjectID:
                             [self->referredPerson globalID]
                             forAccessGlobalID:
                             [self->executantSelection globalID]];
      if (!access) {
        [self setWarningOkAction:@"editAccessAndSave"];
        [self setWarningPhrase:[[self labels] valueForKey:@"AccessWarning"]];
        [self setIsInWarningMode:YES];
        return nil;
      }
    }
  }
  return [self _save];
}

- (BOOL)hasJobAttributes {
  if (!JobAttributesCollapsible)
    return NO;

  return self->referredPerson != nil > 0 ? YES : NO;
}

- (void)setReferredPerson:(NSString *)_per {
  ASSIGN(self->referredPerson, _per);
}
- (id)referredPerson {
  return self->referredPerson;
}

- (NSString *)referredPersonLabel {
  NSMutableString *str;
  id              eo;
  NSString        *fn;

  eo     = [self referredPerson];

  if (eo == nil)
    return nil;
  
  str    = [[[NSMutableString alloc] initWithCapacity:30] autorelease];

  [str appendString:[[eo valueForKey:@"name"] stringValue]];

  fn = [eo valueForKey:@"firstname"];
  
  if ([fn isNotNull] && [[fn stringValue] length] > 0) {
    [str appendString:@", "];
    [str appendString:[fn stringValue]];
  }
  return str;
}

- (NSString *)referredPersonAction {
  NSDictionary *dict;

  if (self->referredPerson == nil)
    return nil;

  dict = [NSDictionary dictionaryWithObjectsAndKeys:
                       [self->referredPerson valueForKey:@"companyId"],
                       @"companyId",
                       [self referredPersonLabel], @"label", nil];
  
  return [[self context]
                directActionURLForActionNamed:@"LSWViewAction/viewPerson"
                queryDictionary:dict];
}

- (id)editAccessAndSave {
  id       acManager;

  [self setIsInWarningMode:NO];
  
  acManager = [[[self session] commandContext] accessManager];

  if (![acManager setOperation:@"rw"
                  onObjectID:[self->referredPerson globalID]
                  forAccessGlobalID:[self->executantSelection globalID]]) {
    [self setErrorString:@"CouldntSetAccessRights"];
    return nil;
  }
  
  return [self _save];
}

- (id)_saveInImportModeWithSnapshot:(id)s {
  /* called by _save */
  id obj    = [self object];      
  id projId = nil;

  NSAssert2([obj isKindOfClass:[NSMutableDictionary class]],
	    @"Imported job isn`t a NSMutableDictionary %@ %@",
	    [obj class], obj);

  [obj addEntriesFromDictionary:s];
  projId = [self->project valueForKey:@"projectId"];

  NSAssert(projId != nil, @"no projectId");
  [obj takeValue:projId forKey:@"projectId"];

  return [self leavePage];
}
- (void)_processInsertProperties {
  id           pm;
  NSDictionary *dic;
  
  if (![self hasJobAttributes])
    return;
  if (self->referredPerson == nil)
    return;
  
  pm = [[[self session] commandContext] propertyManager];

  dic = [NSDictionary dictionaryWithObjectsAndKeys:
                          [self referredPersonAction],
                          @"{person}referredPerson", nil];
  [pm takeProperties:dic namespace:nil globalID:[[self object] globalID]];
}

- (id)_save {
  // TODO: split up this huge method
  id s;
  
  s = [self snapshot];
  
  if (self->isImportMode)
    return [self _saveInImportModeWithSnapshot:s];
  
  [self setErrorString:nil];
  [self saveAndGoBackWithCount:1];

  if ([[self errorString] length] > 0)
    return nil;

  if ([[self navigation] activePage] != self) {
      id notifyValue;

      notifyValue = [s objectForKey:@"notify"];

      if (self->notifyExecutant ||
          ([notifyValue isNotNull] && [notifyValue intValue] == 1)) {

        if (![self isInNewMode]) 
          [self setExecutantSelection:
                [[self object] valueForKey:@"executant"]];
        [self sendMessage];
      }

      if (![self isInNewMode]) {
	// TODO: clean up this mess!
        NSMutableString *comment = nil;
        id              l        = nil;
        id              form     = nil;
        id              sc       = nil;
        BOOL nameChanged;
        BOOL startDateChanged;
        BOOL endDateChanged;
        BOOL notifyChanged;
        BOOL projectChanged;
        BOOL executantChanged;

        sc = self->snapshotCopy;
        
        nameChanged = ![[sc valueForKey:@"name"]
                            isEqual:[s valueForKey:@"name"]];

        startDateChanged = ![[sc valueForKey:@"startDate"]
                                 isEqual:[s valueForKey:@"startDate"]];

        endDateChanged = ![[sc valueForKey:@"endDate"]
                               isEqual:[s valueForKey:@"endDate"]];

        notifyChanged = [[sc valueForKey:@"notify"] intValue] !=
                        [[s valueForKey:@"notify"] intValue];

        projectChanged = [[sc valueForKey:@"projectId"] intValue] !=
                         [[s valueForKey:@"projectId"] intValue];

        executantChanged = ![[sc valueForKey:@"executantId"]
                                 isEqual:[s valueForKey:@"executantId"]];

        form = [[self session] formatDate];
        l = [self labels];

        comment = [NSMutableString stringWithCapacity:256];

        [comment appendString:[l valueForKey:@"oldJob"]];
        [comment appendString:@"\n"];

        [comment appendString:
                 [self changeStringForLabel:@"jobName"
                       withValue:[sc valueForKey:@"name"]]];

        if (startDateChanged) {
          id sDate;

          sDate = [form stringForObjectValue:[sc valueForKey:@"startDate"]];
          
          [comment appendString:[self changeStringForLabel:@"startDate"
                                      withValue:sDate]];
        }

        if (endDateChanged) {
          id endDate;

          endDate = [form stringForObjectValue:[sc valueForKey:@"endDate"]];
          
          [comment appendString:[self changeStringForLabel:@"endDate"
                                      withValue:endDate]];
        }

        if (notifyChanged) {
          id notify;

          notify = [l valueForKey:
                      [self->notifyLabels objectAtIndex:
                           [[sc valueForKey:@"notify"] intValue]]];

          [comment appendString:[self changeStringForLabel:@"notifyCreator"
                                      withValue:notify]];
        }

        if (projectChanged) {
          id chProject;

          chProject = [[self _fetchProject:[sc valueForKey:@"projectId"]]
                           valueForKey:@"name"];

          [comment appendString:[self changeStringForLabel:@"projectLabel"
                                      withValue:chProject]];
        }

        if (executantChanged) {
          id executant;

          executant = [self labelForAccount:[sc valueForKey:@"executant"]];

          [comment appendString:[self changeStringForLabel:@"executant"
                                      withValue:executant]];

          [[self object] takeValue:[EONull null] forKey:@"executant"];
        }
        [comment appendString:@"\n"];
        
        [comment appendString:[l valueForKey:@"newJob"]];
        [comment appendString:@"\n"];

        [comment appendString:[self changeStringForLabel:@"jobName"
                                    withValue:[s valueForKey:@"name"]]];
        
        if (startDateChanged) {
          id sDate;

          sDate = [form stringForObjectValue:[s valueForKey:@"startDate"]];
          
          [comment appendString:[self changeStringForLabel:@"startDate"
                                      withValue:sDate]];
        }

        if (endDateChanged) {
          id endDate;

          endDate = [form stringForObjectValue:[s valueForKey:@"endDate"]];
          
          [comment appendString:[self changeStringForLabel:@"endDate"
                                      withValue:endDate]];
        }

        if (notifyChanged) {
          id notify;

          notify = [l valueForKey:
                      [self->notifyLabels objectAtIndex:
                           [[s valueForKey:@"notify"] intValue]]];

          [comment appendString:[self changeStringForLabel:@"notifyCreator"
                                      withValue:notify]];
        }

        if (projectChanged) {
          id chProject;

          chProject = [self->project valueForKey:@"name"];

          [comment appendString:[self changeStringForLabel:@"projectLabel"
                                      withValue:chProject]];
        }

        if (executantChanged) {
          id executant;

          executant = [self labelForAccount:self->executantSelection];

          [comment appendString:[self changeStringForLabel:@"executant"
                                      withValue:executant]];
        }
        
	[self _commentJobEO:[self object] comment:comment];
	
        if (![self commit]) {
          [self setErrorString:@"Couldn't commit jobaction command "
                @"(rolled back) !"];
          [self rollback];
          return nil;
        }
      }

      if ((self->isProjectLinkMode) || (self->isEnterpriseLinkMode)) {
        NSEnumerator *enumerator = nil;
        id           obj         = nil;

        obj = [self object];

        if (![obj isKindOfClass:[NSArray class]]) {
          [self logWithFormat:@"WARNING: object is no array"];
          obj = [NSArray arrayWithObject:obj];
        }

        enumerator = [obj objectEnumerator];

        while ((obj = [enumerator nextObject])) {
          NSDictionary *dict;
          
          dict = [NSDictionary dictionaryWithObjectsAndKeys:
                               [self jobUrl:obj], @"LinkUrl",
                               [obj valueForKey:@"name"],
                               @"LinkTitle",
                               @"job", @"fileType", nil];

          if (self->isProjectLinkMode)
            [self postChange:LSWNewObjectLinkProjectNotificationName
                  onObject:dict];
          else
            if (self->isEnterpriseLinkMode)
              [self postChange:LSWNewObjectLinkEnterpriseNotificationName
                    onObject:dict];
        }
      }
  }
  
  if ([self isInNewMode] && [[self object] globalID] != nil)
    [self _processInsertProperties];
  
  return nil;
}

- (BOOL)preferredExecutantsEnabled {
  return PreferredAccountsEnabled;
}

- (void)setSelPrefAccounts:(id)_o {
  ASSIGN(self->selPrefAccounts, _o);
}
- (NSArray *)selPrefAccounts {
  return self->selPrefAccounts;
}

- (NSArray *)prefAccountList {
  if (self->team == nil)
    return nil;
  
  return [self _resolveAccountsOfTeamEO:self->team];
}

- (NSString *)searchPreferredAccountsLabel {
  NSString *fmt, *s;
  id l;
  
  l   = [self labels];
  fmt = [l valueForKey:@"searchPreferredAccounts"];
  s   = (self->team != nil)
    ? [self labelForAccount:self->team]
    : [l valueForKey:@"noTeamSelected"];
  return [NSString stringWithFormat:fmt, s];
}

/* KVC */

- (void)takeValue:(id)_v forKey:(id)_key {
  // TODO: why is that?! should be mapped automatically?!
  if ([_key isEqualToString:@"referredPerson"])
    [self setReferredPerson:_v];
  else
    [super takeValue:_v forKey:_key];
}

@end /* LSWJobEditor */
