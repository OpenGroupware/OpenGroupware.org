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

#include <OGoFoundation/LSWViewerPage.h>

@class NSString, NSArray, NSNumber, NSDictionary;
@class OGoJobStatus;

@interface LSWJobViewer : LSWViewerPage
{
@private
  NSNumber       *jobId;
  NSNumber       *userId;         
  NSDictionary   *selectedAttribute;  
  NSString       *tabKey;
  id             item;
  id             job;
  id             jobHistory;
  id             project;
  int            startIndex;
  int            cntJobHirarchie;
  int            repIdx;
  BOOL           fetch;
  BOOL           isDescending;
  BOOL           isProjectEnabled;
  NSArray        *groups;
  OGoJobStatus   *status;
  NSString       *newComment;
}

- (void)_fetchJob;

@end

#include "common.h"
#include <OGoFoundation/LSWNotifications.h>
#include <OGoFoundation/LSWMailEditorComponent.h>
#include <LSFoundation/OGoObjectLinkManager.h>
#include <EOControl/EOKeyGlobalID.h>
#include <NGHttp/NGUrlFormCoder.h>

@interface NSObject(Private)
- (void)setFetchJobs:(BOOL)_fetchJobs;
- (BOOL)fetchJobs;
@end /* PrivateMethods */

@interface LSWJobViewer(PrivateMethods)

- (BOOL)enableEdit;

- (id)_getProject;
- (void)_getJobPersons;
- (void)_getExtendedAttributes;
- (void)_getJobHistoryActors;
- (void)_getJobExecutants;

@end /* PrivateMethods */

@implementation LSWJobViewer

static NSNumber *YesNumber = nil;
static NSNumber *NoNumber  = nil;
static NSNull   *null      = nil;
static BOOL     isLinkEnabled = NO;
static BOOL     HasRefPersons = NO;
static BOOL     HasProject    = NO;
static BOOL     PreferredAccountsEnabled = NO;

+ (void)initialize {
  NSUserDefaults  *ud = [NSUserDefaults standardUserDefaults];
  NGBundleManager *bm = [NGBundleManager defaultBundleManager];
  
  if (YesNumber == nil) YesNumber = [[NSNumber numberWithBool:YES] retain];
  if (NoNumber  == nil) NoNumber  = [[NSNumber numberWithBool:NO]  retain];
  if (null      == nil) null      = [[NSNull null] retain];
  
  isLinkEnabled            = [ud boolForKey:@"OGoTaskLinksEnabled"];
  HasRefPersons            = [ud boolForKey:@"JobReferredPersonEnabled"];
  PreferredAccountsEnabled = [ud boolForKey:@"JobPreferredExecutantsEnabled"];
  
  HasProject    = [bm bundleProvidingResource:@"SkyProject4Desktop"
		      ofType:@"WOComponents"] ? YES : NO;
}

- (id)init {
  if ((self = [super init])) {
    id acc;
    
    self->isProjectEnabled = HasProject;
    
    acc = [[self session] activeAccount];
    self->userId = [[acc valueForKey:@"companyId"] retain];
    
    self->groups = [[[acc valueForKey:@"groups"]
                          map:@selector(valueForKey:) with:@"companyId"]
                          retain];

    self->isDescending = YES;
    self->fetch        = NO;
    
    [self registerForNotificationNamed:LSWJobHasChanged];
  }
  return self;
}

- (void)dealloc {
  [self unregisterAsObserver];
  
  [self->newComment        release];
  [self->selectedAttribute release];
  [self->status     release];
  [self->jobId      release];
  [self->userId     release];
  [self->tabKey     release];
  [self->item       release];
  [self->job        release];
  [self->jobHistory release];
  [self->project    release];
  [self->groups     release];
  [super dealloc];
}

/* fetching */

- (void)_fetchJob {
  NSTimeZone *tz;
  WOSession  *sn;

  sn = [self session];

  tz = [sn timeZone];

  [self->job release];
  self->job = nil;
  self->job = [[self object] retain];
  
  if (self->jobId)
    [self->jobId release];

  self->jobId = [[self->job valueForKey:@"jobId"] retain];

  {
    BOOL didRollback;
    *(&didRollback) = NO;
    NS_DURING {
      [self _getProject];
      [self _getJobPersons];
      [self->job run:@"job::get-job-history",
           @"relationKey", @"jobHistory", nil];
      [self _getJobHistoryActors];
      [self _getJobExecutants];
      [self _getExtendedAttributes];
    }
    NS_HANDLER
      didRollback = [self rollback];
    NS_ENDHANDLER;
    
    if (didRollback)
      [self setErrorString:@"Transaction was rolled back (an error occured)."];
    else {
      if (![self commit]) {
        [self setErrorString:@"Could not commit transaction."];
        [self rollback];
      }
    }
  }

  [[self->job valueForKey:@"startDate"] setTimeZone:tz];
  [[self->job valueForKey:@"endDate"]   setTimeZone:tz];
}

/* accessors */

- (NSString *)nameForElement:(NSString *)_element {
  // TODO: weird method name
  NSString *firstName, *lastName;
  id creator;

  if ((creator = [self->job valueForKey:_element]) == nil)
    return nil;
  
  firstName = [creator valueForKey:@"firstname"];
  lastName  = [creator valueForKey:@"name"];
  
  return [NSString stringWithFormat:@"%@%@%@",
                     firstName,
                     [firstName length] > 0 ? @" " : @"",
                     lastName
                     ];
}

- (NSString *)creatorName {
  return [self nameForElement:@"creator"];
}
- (NSString *)executantName {
  return [self nameForElement:@"executant"];
}

- (void)setNewComment:(NSString *)_value {
  ASSIGNCOPY(self->newComment, _value);
}
- (NSString *)newComment {
  return self->newComment;
}

- (BOOL)hasProject {
  return (self->project != nil);
}

- (NSUserDefaults *)defaults {
  return [[self session] userDefaults];
}

- (NSString*)priority {
  NSString *pri, *k;
  char buf[64];
  
  sprintf(buf, "priority_%d", [[self->job valueForKey:@"priority"] intValue]);
  k = [NSString stringWithCString:buf];
  
  pri = [[self labels] valueForKey:k];
  
  if (pri == nil)
    pri = [[self->job valueForKey:@"priority"] stringValue];

  return pri;
}

- (id)project {
  if (self->fetch) {
    self->fetch = NO;
    [self _fetchJob];
  }
  return self->project;
}

- (void)setSelectedAttribute:(NSDictionary *)_selectedAttribute {
  ASSIGN(self->selectedAttribute, _selectedAttribute);
}
- (NSDictionary *)selectedAttribute {
  return self->selectedAttribute;    
}

- (void)setTabKey:(NSString *)_tabKey {
  ASSIGN(self->tabKey, _tabKey);
  [[self defaults] setObject:_tabKey forKey:@"job_view"];
}
- (NSString *)tabKey {
  return self->tabKey;
}

- (void)setStart:(unsigned)_startIndex {
  self->startIndex = _startIndex;
}
- (unsigned)start {
  return self->startIndex;    
}

- (void)setIsDescending:(BOOL)_isDescending {
  self->isDescending = _isDescending;
}
- (BOOL)isDescending {
  return self->isDescending;    
}

- (id)job {
  return self->job;
}

- (void)setJobHistory:(id)_jobHistory {
  ASSIGN(self->jobHistory, _jobHistory);
}
- (id)jobHistory {
  return self->jobHistory;
}

- (void)setItem:(id)_item {
  ASSIGN(self->item, _item);
}
- (id)item {
  return self->item;
}

- (void)setRepIdx:(int)_repIdx {
  self->repIdx = _repIdx;
}
- (int)repIdx {
  return self->repIdx;
}                                

- (NSString *)jobUrl {
  WOContext *ctx;
  id        obj;
  NSString  *urlPrefix = nil;
  NSString  *url       = nil;

  ctx = [self context];
  obj = [self object];
  
  urlPrefix = [ctx urlSessionPrefix];
  url       = [[ctx request] headerForKey:@"x-webobjects-server-url"];

  if (url && [url length]) {
    return [NSString stringWithFormat:@"%@%@/viewJob?jobId=%@",
                       url, urlPrefix, [obj valueForKey:@"jobId"]];
  }
  else {
    return [NSString stringWithFormat:@"http://%@%@/viewJob?jobId=%@",
                       [[ctx request] headerForKey:@"host"],
                       urlPrefix, [obj valueForKey:@"jobId"]];
  }
}

- (NSString *)mailTo {
  return [NSString stringWithFormat:@"mailto:?body=%@", [self jobUrl]];
}

- (void)syncAwake {
  [super syncAwake];
  
  if (self->fetch) {
    self->fetch = NO;
    [self _fetchJob];
  }
}
- (void)sleep {
  [self->status release]; self->status = nil;
  [super sleep];
}

- (void)noteChange:(NSString *)_cn onObject:(id)_object {
  [super noteChange:_cn onObject:_object];

  if ([_cn isEqualToString:LSWJobHasChanged])
    self->fetch = YES;
}

- (id)_fetchProject {
  NSArray *p = nil;

  p = [self runCommand:@"project::get",
            @"projectId", [self->job valueForKey:@"projectId"], nil];

  return ([p count] > 0) ? [p lastObject] : nil;
}

/* activation */

- (BOOL)prepareForActivationCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  id obj;
  
  if (![super prepareForActivationCommand:_command type:_type
	      configuration:_cmdCfg])
    return NO;
    
  obj = [self object];

  if ([[_type type] isEqualToString:@"eo-gid"]) {
      EOKeyGlobalID *gid;
      
      if (![[_type subType] isEqualToString:@"job"])
        return NO;
      
      gid = obj;
      obj = [[self run:@"job::get",
                     @"jobId", [gid keyValues][0], nil] lastObject];
      
      [self setObject:obj];
  }

  if ([[_type type] isEqualToString:@"objc"]) {
      EOKeyGlobalID *gid;

      if ((![[_type subType] isEqualToString:@"SkyJobDocument"]) &&
          (![[_type subType] isEqualToString:@"SkySchedulerJobDocument"]))
        return NO;
      
      gid = [obj valueForKey:@"globalID"];
      obj = [[self run:@"job::get",
                     @"jobId", [gid keyValues][0], nil] lastObject];

      [self setObject:obj];
  }

  if (self->job == nil)
    [self _fetchJob];

  {
    id tb;

    tb = [[self defaults] objectForKey:@"job_view"]; 
    self->tabKey = (tb != nil) ? RETAIN(tb) : @"attributes";
  }
  return YES;
}

/* actions */

- (id)annotateJob {
  return [self activateObject:self->job withVerb:@"annotate"];
}
- (id)archiveJob {
  return [self activateObject:self->job withVerb:@"archive"];
}
- (id)acceptJob {
  return [self activateObject:self->job withVerb:@"accept"];
}
- (id)doneJob {
  return [self activateObject:self->job withVerb:@"done"];
}
- (id)rejectJob {
  return [self activateObject:self->job withVerb:@"reject"];
}

- (id)deleteJob {
  id p;
  
  if (self->job == nil)
    return nil;
  
  [self runCommand:@"job::delete",
	  @"object",       self->job,
          @"reallyDelete", YesNumber, nil];
  p = [self pageWithName:@"LSWJobs"];
  [p setFetchJobs:YES];
  return p;
}

- (id)quickCreateComment {
  NSString *ncomment;
  
  ncomment = [[[self newComment] copy] autorelease];
  [self setNewComment:nil];
  if ([ncomment length] == 0) return nil; // do not allow empty comments
  
  /* save */
  [self->job run:@"job::jobaction", @"action", @"comment",
       @"comment", ncomment, nil];
  if (![self commit]) {
    [self setNewComment:ncomment];
    [self setErrorString:@"Could not commit comment (rolled back)!"];
    [self rollback];
    return nil;
  }
  [self postChange:LSWJobHasChanged onObject:self->job];
  
  return nil;
}

/* conditions */

- (BOOL)isOperation:(NSString *)_opmask allowedOnObject:(id)_object {
  LSCommandContext *ctx;
  SkyAccessManager *am;
  EOGlobalID       *gid;
  
  ctx = [[self session] commandContext];
  am  = [ctx accessManager];
  gid = [_object valueForKey:@"globalID"];
  return [am operation:_opmask allowedOnObjectID:gid];
}

- (BOOL)creatorIsVisible {
  return [self isOperation:@"r" 
               allowedOnObject:[[self job] valueForKey:@"creator"]];
}
- (BOOL)executantIsVisible {
  return [self isOperation:@"r" 
               allowedOnObject:[[self job] valueForKey:@"executant"]];
}

/* actions */

- (id)viewHistory {
  self->selectedAttribute = nil;
  self->startIndex        = 0;
  self->isDescending      = YES;
  return nil;
}

- (id)tabClicked {
  if ([[self tabKey] isEqualToString:@"jobHistoryList"])
    return [self viewHistory];
  return nil;
}

- (id)viewCreator {
  return [self activateObject:[[self object] valueForKey:@"creator"]
	       withVerb:@"view"];
}
- (id)viewExecutant {
  return [self activateObject:[[self object] valueForKey:@"executant"]
	       withVerb:@"view"];
}
- (id)viewActor {
  return [self activateObject:[self->jobHistory valueForKey:@"actor"]
	       withVerb:@"view"];
}

- (id)viewProject {
  id projectId       = nil;
  EOKeyGlobalID *gid = nil;
  
  projectId = [self->job valueForKey:@"projectId"];
  gid = [EOKeyGlobalID globalIDWithEntityName:@"Project"
                       keys:&projectId keyCount:1
                       zone:NULL];

  if (gid) 
    return [self activateObject:gid withVerb:@"view"];
  
  return nil;
}

- (id)viewJob {
  return [self activateObject:self->item withVerb:@"view"];
}

- (BOOL)canAssignProject {
  if ([[self project] isNotNull]) return NO;
  if (!self->isProjectEnabled) return NO;
  return [self enableEdit];
}
- (BOOL)canDetachProject {
  if ([[self project] isNotNull]) 
    return [self enableEdit];
  return NO;
}

- (id)assignProject {
  if (![self canAssignProject]) {
    NSString *s;
    
    s = [[self labels] valueForKey:@"error_cannotAssignProject"];
    [self setErrorString:s];
    return nil;
  }  
  return [self activateObject:self->job withVerb:@"assign-project"];
}

- (id)detachProject {
  NSString *logText;
  
  if (![self canDetachProject]) {
    NSString *s;
    s = [[self labels] valueForKey:@"error_cannotDetachProject"];
    [self setErrorString:s];
    return nil;
  }
  logText = [NSString stringWithFormat:@"detached project %@",
                        [[self project] valueForKey:@"name"]];
  [self runCommand:@"job::detach-from-project", @"job", self->job,
        @"logText", logText, nil];
  self->fetch = YES;
  return nil;
}

- (BOOL)isCurrentJob {
  if ([[item valueForKey:@"jobId"] isEqual:self->jobId])
    return YES;
  return NO;
}

- (BOOL)moreJobs {
  if (self->repIdx == self->cntJobHirarchie)
    return NO;
  return YES;
}

- (BOOL)endDateOnTime {
  if ([[self->job valueForKey:@"endDate"] timeIntervalSinceNow] > 0)
    return YES;
  return NO;
}

- (BOOL)userIsExecutant {
  if ([[self session] activeAccountIsRoot])
    return YES;
  
  if ([[self->job valueForKey:@"isTeamJob"] boolValue]) {
    return [self->groups containsObject:
                [self->job valueForKey:@"executantId"]];
  }
  
  return [self->userId isEqual:[self->job valueForKey:@"executantId"]];
}

- (BOOL)userIsCreator {
  if ([[self session] activeAccountIsRoot])
    return YES; 

  return [self->userId isEqual:[self->job valueForKey:@"creatorId"]];
}

- (OGoJobStatus *)status {
  NSString *s;

  if (self->status)
    return self->status;
  
  s = [self->job valueForKey:@"jobStatus"];
  self->status = [[OGoJobStatus jobStatusWithString:s] retain];
  return self->status;
}

- (NSString *)statusValue {
  return [[self labels] valueForKey:[self->job valueForKey:@"jobStatus"]];
}

- (BOOL)enableAccept {
  if (![[self status] allowAcceptTransition])
    return NO;
  
  if (![self userIsExecutant])
    return NO;
  
  return YES;
}

- (BOOL)enableDone {
  if (![[self status] allowDoneTransition])
    return NO;
  
  // TODO: permissions? who is allowed to mark done?
  return YES;
}

- (BOOL)enableDelete {
  if (![[self status] allowDeleteTransition])
    return NO;
  
  return [self userIsCreator];
}

- (BOOL)enableArchive {
  if (![[self status] allowArchiveTransition])
    return NO;
  
  return [self userIsCreator];
}

- (BOOL)forbidViewProject {
  id      p   = nil;
  NSArray *pj = nil;

  if ((p = [self project]) == nil)
    return YES;
  
  pj = [self runCommand:@"project::check-get-permission",
               @"object", [NSArray arrayWithObject:p], nil];
  
  return ([pj count] == 1) ? NO : YES;
}
          
- (BOOL)enableEdit {
  if ([[self status] isArchived])
    return NO;
  if ([self userIsExecutant] || [self userIsCreator])
    return YES;
  return NO;
}

- (BOOL)isRejectEnabled {
  if (![[self status] allowRejectTransition])
    return NO;
  
  if ([self userIsCreator])
    /* doesn't make sense to reject an owned task? */
    return NO;
  
  return YES;
}

- (BOOL)isAnnotateEnabled {
  return [[self status] allowAnnotateTransition];
}

- (BOOL)isLogTabEnabled {
  return YES;
}
- (BOOL)isLinkTabEnabled {
  return isLinkEnabled;
}

- (NSString *)objectUrlKey {
  // can we use activate?
  return [@"wa/LSWViewAction/viewJob?jobId="
	   stringByAppendingString:
	     [[[self object] valueForKey:@"jobId"] stringValue]];
}

- (NSNumber *)isActorArchived {
  id actor = [self->jobHistory valueForKey:@"actor"];
  
  return [[actor valueForKey:@"dbStatus"] isEqualToString:@"archived"] 
    ? YesNumber : NoNumber;
}

/* privates */

- (id)_getProject {
  [self->project release]; self->project = nil;
  self->project = [[self _fetchProject] retain];
  return self->project;
}

- (void)_getJobPersons {
  [self->job run:@"job::setexecutant", @"relationKey", @"executant", nil];

  if (![[self->job valueForKey:@"executant"] isNotNull]) {
    [self->job run:@"job::setexecutantteam", @"relationKey", @"executant",
         nil];
  }

  if ([self->job valueForKey:@"creator"] == nil)
    [self->job run:@"job::setcreator", @"relationKey", @"creator", nil];
}

- (void)_getExtendedAttributes {
  OGoSession   *sn;
  id           pm;
  NSDictionary *dict;
  
  sn = (id)[self existingSession];
  pm = [[sn commandContext] propertyManager];

  dict = [pm propertiesForGlobalID:[self->job globalID]];

  if (dict != nil)
    [self->job takeValue:dict forKey:@"properties"];
}

- (void)_getJobHistoryActors {
  OGoSession   *sn;
  id           jh;      
  NSArray      *array  = [self->job valueForKey:@"jobHistory"];
  register IMP objAtIdx;
  register int i, cnt;

  sn = (id)[self existingSession];
  objAtIdx = [array methodForSelector:@selector(objectAtIndex:)];

  for (i = 0, cnt = [array count]; i < cnt; i++) {
    jh = objAtIdx(array, @selector(objectAtIndex:),i);

    if ([jh valueForKey:@"actor"] == nil)
      [jh run:@"job::setactor", @"relationKey", @"actor", nil];
  }
}

- (void)_getJobExecutants {
  id           j;
  register IMP objAtIdx;
  register int i, cnt;
  NSArray      *array;
    
  array    = [self->job valueForKey:@"jobs"];
  objAtIdx = [array methodForSelector:@selector(objectAtIndex:)];

  for (i = 0, cnt = [array count]; i < cnt; i++) {
    j = objAtIdx(array, @selector(objectAtIndex:), i);

    if ([j valueForKey:@"executant"] == nil)
      [j run:@"job::setexecutant", @"relationKey", @"executant", nil];
  }
}

/* timer functionality */

- (BOOL)hasRunningTimer {
  return ([[self job] valueForKey:@"timerDate"] != nil);
}

- (BOOL)hasNoRunningTimer {
  return ![self hasRunningTimer];
}

- (id)startTimer {
  NSCalendarDate *d;
  id cmdResult;
  id j;

  j = [self job];

  d = [NSCalendarDate date];
  [j takeValue:d forKey:@"timerDate"];
  cmdResult = [self runCommand:@"job::set" arguments:j];

  if (cmdResult != nil) {
    NSString *comment;

    comment = [NSString stringWithFormat:@"job timer started"];
    
    cmdResult = [self runCommand:@"job::jobaction",
                      @"object", j,
                      @"action", @"comment",
                      @"comment", comment,
                      nil];
  }

  [self _fetchJob];
  return nil;
}

- (int)jobTimerAddInterval {
  int addDifference;

  addDifference = 
    [[[self defaults] valueForKey:@"LSJobTimerAddDifference"] intValue];
  if (addDifference == 0)
    addDifference = 5;
  return addDifference;
}

- (id)stopTimer {
  id cmdResult, j;
  NSCalendarDate *d, *n;
  NSString *comment;
  int diff = 0;
  int addDifference;

  addDifference = [self jobTimerAddInterval];
  j = [self job];

  d = [j valueForKey:@"timerDate"];
  n = [NSCalendarDate date];

  diff = [n timeIntervalSinceDate:d];

  if (diff > addDifference) {
    int div, aWork;

    div = diff / 60;
    if ((diff % 60) > 0) div += 1;

    comment = [NSString stringWithFormat:
                        @"timer stopped, %d %@ added to actual work",
                        div, (div > 1) ? @"minutes" : @"minute"];

    aWork = [[j valueForKey:@"actualWork"] intValue] + div;
    [j takeValue:[NSNumber numberWithInt:aWork] forKey:@"actualWork"];
  }
  else {
    comment = [NSString stringWithFormat:
                        @"timer stopped, not added to actual work"];
  }

  [j takeValue:null forKey:@"timerDate"];
  
  cmdResult = [self runCommand:@"job::set" arguments:j];

  if (cmdResult != nil)
    cmdResult = [self runCommand:@"job::jobaction",
                      @"object", j,
                      @"action", @"comment",
                      @"comment", comment, nil];
  

  [self _fetchJob];
  return nil;
}

- (id)clearTimer {
  id cmdResult;
  id j;

  j = [self job];
  
  [j takeValue:null forKey:@"timerDate"];
  
  cmdResult = [self runCommand:@"job::set" arguments:j];

  if (cmdResult != nil) {
    cmdResult = [self runCommand:@"job::jobaction",
                      @"object", j,
                      @"action", @"comment",
                      @"comment", @"timer cleared", nil];
  }
  
  [self _fetchJob];
  return nil;
}

- (NSNumber *)timerValue {
  NSCalendarDate *d;
  int div, diff = 0;
  
  d = [[self job] valueForKey:@"timerDate"];

  diff = [[NSCalendarDate date] timeIntervalSinceDate:d] / 60;

  div = diff / 60;
  if ((diff % 60) > 0) div += 1;
  
  return [NSNumber numberWithInt:div];
}

- (NSDictionary *)_jobProperties {
  return [self->job valueForKey:@"properties"];
}

- (BOOL)hasReferredPerson {
  if (!HasRefPersons)
    return NO;
  
  if ([[self _jobProperties] objectForKey:@"{person}referredPerson"])
    return YES;

  return NO;
}
- (NSString *)referredPersonLink {
  return [[self _jobProperties] objectForKey:@"{person}referredPerson"];
}
- (NSString *)referredPersonLabel {
  NSString *str, *referredPerson;
  NGHashMap *map;
  NSArray   *array;

  referredPerson = 
    [[self _jobProperties] objectForKey:@"{person}referredPerson"];
  
  array = [referredPerson componentsSeparatedByString:@"?"];

  if ([array count] < 2)
    return referredPerson;
  
  str = [array objectAtIndex:1];
  // TODO: find out about that
  map = NGDecodeUrlFormParameters([str cString], [str length]);
  str = [map objectForKey:@"label"];
  
  if ([str length] == 0)
    str = referredPerson;

  return str;
}

- (void)_initJobRefExec {
  OGoObjectLinkManager *lm;
  NSArray              *array;
  
  if ([self->job valueForKey:@"prefExec"] != nil)
    return;

  lm = [[[self session] commandContext] linkManager];
  array = [lm allLinksFrom:(EOKeyGlobalID *)[self->job globalID]
              type:@"Preferred Job Executant"];
  if (array == nil)
    array = [NSArray array];
  
  [job takeValue:array forKey:@"prefExec"];
}

- (BOOL)preferredExecutantsEnabled {
  return PreferredAccountsEnabled;
}

- (BOOL)hasPrefExec {
  if (![self  preferredExecutantsEnabled])
    return NO;

  [self _initJobRefExec];
  return ([[self->job valueForKey:@"prefExec"] count] > 0) ? YES : NO;
}

- (NSString *)prefExec {
  [self _initJobRefExec];

  return [[[self->job valueForKey:@"prefExec"] map:@selector(label)]
                      componentsJoinedByString:@"; "];
}
@end /* LSWJobViewer */
