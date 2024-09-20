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

#include <OGoFoundation/LSWEditorPage.h>

@class NSString, NSArray, NSMutableArray, NSDictionary;

@interface LSWJobEditor : LSWEditorPage
{
@protected
  id             item;
  int            idx;
  id             project;
  BOOL           notifyExecutant;
  BOOL           isImportMode;
  BOOL           isProjectLinkMode;
  BOOL           isEnterpriseLinkMode;  
  NSArray        *notifyList;
  NSArray        *teams;

  id             team;
  id             executantSelection;
  
  NSMutableArray *resultList;

  NSString       *searchAccount;

  NSDictionary   *snapshotCopy;
  NSArray        *notifyLabels;

  BOOL           isProjectEnabled;
  NSString       *accountLabelFormat;
  int            noOfCols;

  id             referredPerson;

  NSArray        *selPrefAccounts;
}

- (void)setProject:(id)_project;
- (id)project;

@end

#include "LSWJobMailPage.h"
#include "NSArray+JobIntNums.h"
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

@implementation LSWJobEditor

static NSArray  *JobAttrsEditor_percentages = nil;
static NSArray  *JobAttrsEditor_priorities  = nil;
static NSArray  *defNotifyList   = nil;
static NSArray  *defNotifyLabels = nil;
static NSString *preferredJobExecutantLinkType = @"Preferred Job Executant";

static BOOL JobAttributesCollapsible = NO;
static BOOL PreferredAccountsEnabled = NO;
static BOOL HasSkyProject4Desktop    = NO;

+ (int)version {
  return [super version] + 1 /* v4 */;
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
				     [NSNumber numberWithInt:0],
				     [NSNumber numberWithInt:1],
				     [NSNumber numberWithInt:2],
				   nil];
  defNotifyLabels = [[NSArray alloc] initWithObjects:@"Never", @"Always",
				       @"OnAcceptDone", nil];
}

- (id)init {
  if ((self == [super init])) {
    self->isProjectEnabled = HasSkyProject4Desktop;
    self->noOfCols         = -1;
    
    self->resultList      = [[NSMutableArray alloc] initWithCapacity:16];
    self->selPrefAccounts = [[NSMutableArray alloc] initWithCapacity:16];
  }
  return self;
}

- (void)dealloc {
  [self->item                release];
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
  // TODO: is it important to have numbers? otherwise we have 
  //       JobAttrsEditor_sensitivities
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
  if (_flag)
    [self setExecutantSelection:self->item];
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
  ASSIGNCOPY(self->searchAccount, _str);
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
  char buf[64];
  
  snprintf(buf, sizeof(buf), "priority_%d", [self->item unsignedIntValue]);
  pri = [[self labels] valueForKey:[NSString stringWithCString:buf]];
  
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
  return (l != nil) ? l : (NSString *)@"- no project -";
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
  [self session]; // hh(2024-09-20): create if missing?
  
  self->isProjectLinkMode    = [[_type subType]
                                       isEqualToString:@"project-job"];
  self->isEnterpriseLinkMode = [[_type subType]
                                       isEqualToString:@"enterprise-job"];  
  self->isImportMode         = [[_type type] isEqualToString:@"dict"];

  if (self->teams == nil) {
    NSArray *a;
    
    // TODO: was sorted before
    a = [self runCommand:@"team::get",
	        @"returnType", intObj(LSDBReturnType_ManyObjects), 
	      nil];
    self->teams = [a retain];
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
      if ([self isInNewMode]) {
        NSCalendarDate *nowDate = [NSCalendarDate date];

        [nowDate setTimeZone:tz];

        if ([[nowDate beginOfDay] compare:[sD beginOfDay]]
            == NSOrderedDescending) {
          [error appendString:[labels valueForKey:@"error_start_before_now"]];
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

- (NSString *)emailSubjectForJobEO:(id)_job {
  NSString *subject;
  
  subject = [NSString stringWithFormat:@"%@: '%@' %@ %@",
                      [[self labels] valueForKey:@"job"],
                      [_job valueForKey:@"name"],
                      [[self labels] valueForKey:@"createLabel"],
                      [[[self session] activeAccount] valueForKey:@"login"]];
  return subject;
}
- (id)jobObjectForSend {
  id obj;
  
  obj = [self object];
  if (![obj isKindOfClass:[NSArray class]])
    return obj;
  
  return ([(NSArray *)obj count] > 0) ? [obj objectAtIndex:0] : nil;
}

- (id)sendMessage {
  id<LSWMailEditorComponent,OGoContentPage> editor;
  id obj;
  
  if ((obj = [self jobObjectForSend]) == nil) {
    [self setErrorString:@"No job found for email send!"];
    return nil;
  }
  
  /* setup email editor */
  
  editor = (id)[self pageWithName:@"LSWImapMailEditor"];
  [self enterPage:editor];
  [editor setSubject:[self emailSubjectForJobEO:obj]];
  [editor setContentWithoutSign:@""];
  
  /* add recipients */
  
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

  /* add attachments */

  [editor addAttachment:obj type:[NGMimeType mimeType:@"eo" subType:@"job"]];

  return [editor send];
}

- (void)_applyPreferredExecutantsOnJobEO:(id)job {
  NSEnumerator         *enumerator;
  id                   account, l;
  OGoObjectLinkManager *lm;
  EOKeyGlobalID        *gid;
  NSString             *teamLabel;
  
  enumerator = [self->selPrefAccounts objectEnumerator];
  lm         = [[[self session] commandContext] linkManager];
  gid        = (EOKeyGlobalID *)[job globalID];
  l          = [self labels];
  teamLabel  = [self labelForAccount:self->executantSelection];

  while ((account = [enumerator nextObject]) != nil) {
    OGoObjectLink *link;
    EOKeyGlobalID *targetGID;
    NSString      *label, *comment;
    
    /* create object link */
    
    label     = [self labelForAccount:account];
    targetGID = (EOKeyGlobalID *)[account globalID];
    link      = [[OGoObjectLink alloc] initWithSource:gid target:targetGID
				       type:preferredJobExecutantLinkType
				       label:label];
    [lm createLink:link];
    [link release]; link = nil;
    
    /* add an object log */
    
    comment = [l valueForKey:@"Add job link to %@ [team:%@]."];
    comment = [NSString stringWithFormat:comment, label, teamLabel];
    [self _addLogForGlobalID:gid action:@"05_changed" comment:comment];
  }
}

- (void)_applyValuesOnSnapshot:(id)job {
  [job takeValue:[NSNumber numberWithBool:[self isTeamSelected]]
       forKey:@"isTeamJob"];
  [job takeValue:[self->executantSelection valueForKey:@"companyId"]
       forKey:@"executantId"];
  if ([self->project isNotNull]) {
    [job takeValue:[self->project valueForKey:@"projectId"]
         forKey:@"projectId"];
  }
  else {
    [job takeValue:[NSNull null] forKey:@"projectId"];
  }
}

- (id)insertObject {
  id job;

  job = [self snapshot];
  [self _applyValuesOnSnapshot:job];
  
  job = [self _createJobWithArguments:job];
  
  if ([self preferredExecutantsEnabled])
    [self _applyPreferredExecutantsOnJobEO:job];
  
  return job;
}

- (id)updateObject {
  id job;
  
  job = [self snapshot];
  [job removeObjectForKey:@"executant"];
  [job removeObjectForKey:@"object"];
  
  [self _applyValuesOnSnapshot:job];
  
  return [self runCommand:@"job::set" arguments:job];
}

- (id)deleteObject {
  return [self runCommand:@"job::delete", 
	         @"object",       [self object],
		 @"reallyDelete", [NSNumber numberWithBool:NO],
	       nil];
}

- (id)_saveExistingJob {
  BOOL access;
  id   acManager;
  
  if (![self->executantSelection isNotNull]) {
    [self setErrorString:
            [[self labels] valueForKey:@"NoTeamAndExecutantsWasSelected"]];
    return nil;
  }

  // TODO: document, what is referredPerson?
  
  if (self->referredPerson == nil)
    return [self _save];
  
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
  return [self _save];
}

- (id)save {
  return [self isInNewMode] ? [self _save] : [self _saveExistingJob];
}

- (BOOL)hasJobAttributes {
  if (!JobAttributesCollapsible)
    return NO;

  // TODO: was: return self->referredPerson != nil > 0 ? YES : NO;
  //       what do we want here? :-)
  return self->referredPerson != nil ? YES : NO;
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

  if ((eo = [self referredPerson]) == nil)
    return nil;
  
  str = [NSMutableString stringWithCapacity:30];
  
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
	    @"Imported job is not a NSMutableDictionary %@ %@",
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

- (void)_postLinkSaveNotificationsOnJobEO:(id)obj {
  NSEnumerator *enumerator;
  
  if (!((self->isProjectLinkMode) || (self->isEnterpriseLinkMode)))
    return;
  
  if (![obj isKindOfClass:[NSArray class]])
    obj = [NSArray arrayWithObject:obj];
  
  enumerator = [obj objectEnumerator];
  while ((obj = [enumerator nextObject]) != nil) {
    NSDictionary *dict;
    
    dict = [NSDictionary dictionaryWithObjectsAndKeys:
                               [self jobUrl:obj], @"LinkUrl",
                               [obj valueForKey:@"name"],
                               @"LinkTitle",
                               @"job", @"fileType", nil];
    
    if (self->isProjectLinkMode) {
      [self postChange:LSWNewObjectLinkProjectNotificationName onObject:dict];
    }
    else if (self->isEnterpriseLinkMode) {
      [self postChange:LSWNewObjectLinkEnterpriseNotificationName
	    onObject:dict];
    }
  }
}

static BOOL _isIntKeyEq(id a, id b, NSString *key) {
  a = [a valueForKey:key];
  b = [b valueForKey:key];
  if (a == b) return YES;
  return [a intValue] == [b intValue] ? YES : NO;
}

- (NSString *)_buildCommentWithOldSnapshot:(id)sc andNewSnapshot:(id)s{
  // TODO: clean up this mess!
  NSMutableString *comment;
  NSFormatter     *form    = nil;
  BOOL startDateChanged, endDateChanged, notifyChanged;
  BOOL projectChanged, executantChanged;
  id   l, tmp;

  /* detect changes */

  startDateChanged = ![[sc valueForKey:@"startDate"]
                           isEqual:[s valueForKey:@"startDate"]];
  endDateChanged = ![[sc valueForKey:@"endDate"]
                           isEqual:[s valueForKey:@"endDate"]];

  notifyChanged  = !_isIntKeyEq(sc, s, @"notify");
  projectChanged = !_isIntKeyEq(sc, s, @"projectId");
  
  executantChanged = ![[sc valueForKey:@"executantId"]
                           isEqual:[s valueForKey:@"executantId"]];


  form = [[self session] formatDate];
  l    = [self labels];

  comment = [NSMutableString stringWithCapacity:256];
  [comment appendString:[l valueForKey:@"oldJob"]];
  [comment appendString:@"\n"];
  
  tmp = [sc valueForKey:@"name"];
  tmp = [self changeStringForLabel:@"jobName" withValue:tmp];
  [comment appendString:tmp];
  
  if (startDateChanged) {
    tmp = [form stringForObjectValue:[sc valueForKey:@"startDate"]];
    tmp = [self changeStringForLabel:@"startDate" withValue:tmp];
    [comment appendString:tmp];
  }
  if (endDateChanged) {
    tmp = [form stringForObjectValue:[sc valueForKey:@"endDate"]];
    tmp = [self changeStringForLabel:@"endDate" withValue:tmp];
    [comment appendString:tmp];
  }
  
  if (notifyChanged) {
    tmp = [sc valueForKey:@"notify"];
    tmp = [self->notifyLabels objectAtIndex:[tmp intValue]];
    tmp = [l valueForKey:tmp];
    tmp = [self changeStringForLabel:@"notifyCreator" withValue:tmp];
    [comment appendString:tmp];
  }

  if (projectChanged) {
    tmp = [self _fetchProject:[sc valueForKey:@"projectId"]];
    tmp = [tmp valueForKey:@"name"];
    tmp = [self changeStringForLabel:@"projectLabel" withValue:tmp];
    [comment appendString:tmp];
  }

  if (executantChanged) {
    tmp = [self labelForAccount:[sc valueForKey:@"executant"]];
    tmp = [self changeStringForLabel:@"executant" withValue:tmp];
    [comment appendString:tmp];
    
    // TODO: weird side effect, why is that?
    [[self object] takeValue:[EONull null] forKey:@"executant"];
  }
  [comment appendString:@"\n"];
        
  [comment appendString:[l valueForKey:@"newJob"]];
  [comment appendString:@"\n"];
  
  tmp = [s valueForKey:@"name"];
  tmp = [self changeStringForLabel:@"jobName" withValue:tmp];
  [comment appendString:tmp];
  
  if (startDateChanged) {
    tmp = [form stringForObjectValue:[s valueForKey:@"startDate"]];
    tmp = [self changeStringForLabel:@"startDate" withValue:tmp];
    [comment appendString:tmp];
  }
  if (endDateChanged) {
    tmp = [form stringForObjectValue:[s valueForKey:@"endDate"]];
    tmp = [self changeStringForLabel:@"endDate" withValue:tmp];
    [comment appendString:tmp];
  }

  if (notifyChanged) {
    tmp = [s valueForKey:@"notify"];
    tmp = [self->notifyLabels objectAtIndex:[tmp intValue]];
    tmp = [l valueForKey:tmp];
    tmp = [self changeStringForLabel:@"notifyCreator" withValue:tmp];
    [comment appendString:tmp];
  }
  
  if (projectChanged) {
    tmp = [self->project valueForKey:@"name"];
    tmp = [self changeStringForLabel:@"projectLabel" withValue:tmp];
    [comment appendString:tmp];
  }
  
  if (executantChanged) {
    tmp = [self labelForAccount:self->executantSelection];
    tmp = [self changeStringForLabel:@"executant" withValue:tmp];
    [comment appendString:tmp];
  }
  return comment;
}

- (BOOL)shouldSendMessage {
  // kinda hack
  return [[self navigation] activePage] != self ? YES : NO;
}

- (id)_save {
  if (self->isImportMode)
    return [self _saveInImportModeWithSnapshot:[self snapshot]];
  
  [self setErrorString:nil];
  [self saveAndGoBackWithCount:1];

  if ([[self errorString] length] > 0)
    return nil;
  
  if ([self shouldSendMessage]) {
    id notifyValue;
    
    notifyValue = [[self snapshot] objectForKey:@"notify"];
    
    if (self->notifyExecutant ||
	([notifyValue isNotNull] && [notifyValue intValue] == 1)) {
      
      if (![self isInNewMode]) {
	[self setExecutantSelection:
                [[self object] valueForKey:@"executant"]];
      }
      [self sendMessage];
    }

    if (![self isInNewMode]) {
      // TODO: clean up this mess!
      NSString *comment;
	
      comment = [self _buildCommentWithOldSnapshot:self->snapshotCopy
		      andNewSnapshot:[self snapshot]];
      [self _commentJobEO:[self object] comment:comment];
	
      if (![self commit]) {
	[self setErrorString:@"Could not commit jobaction command "
	      @"(rolled back) !"];
	[self rollback];
	return nil;
      }
    }
      
    [self _postLinkSaveNotificationsOnJobEO:[self object]];
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
    : (NSString *)[l valueForKey:@"noTeamSelected"];
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
