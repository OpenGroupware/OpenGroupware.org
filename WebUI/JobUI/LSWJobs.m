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

#include <OGoFoundation/LSWContentPage.h>

@class NSString, NSArray, NSDictionary;

@interface LSWJobs : LSWContentPage
{
@private  
  NSArray      *filteredJobList;
  id           job;
  id           subJob;
  NSDictionary *selectedAttribute;
  NSString     *tabKey;
  NSString     *keywordsString;
  NSString     *timeSelection;
  unsigned     startIndex;
  BOOL         fetchJobs;
  BOOL         isDescending;
  BOOL         showMyGroups;
  id           item;
  
  NSArray      *teams;
  NSArray      *timeList;

  id           selectedTeam;
}

- (id)tabClicked;
- (void)_fetchJobs:(SEL)_sel;
- (id)filter;

@end /* LSWJobs */

#include <OGoFoundation/LSWNotifications.h>
#include <OGoFoundation/OGoSession.h>
#include <LSFoundation/OGoObjectLinkManager.h>
#include <LSFoundation/OGoObjectLink.h>
#include "common.h"

@interface NSObject(LSWJobs_PRIVATE)
- (void)setExecutant:(id)_executant;
@end

@implementation LSWJobs

static NSNumber   *YesNumber = nil;
static NSNumber   *NoNumber  = nil;
static NGMimeType *eoJobType = nil;
static BOOL       PreferredAccountsEnabled = NO;
static BOOL       LSCoreOnCommandException = NO;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  if (YesNumber == nil) YesNumber = [[NSNumber numberWithBool:YES] retain];
  if (NoNumber  == nil) NoNumber  = [[NSNumber numberWithBool:NO]  retain];
  if (eoJobType == nil) eoJobType = [[NGMimeType mimeType:@"eo/job"] retain];

  PreferredAccountsEnabled = [ud boolForKey:@"JobPreferredExecutantsEnabled"];
  LSCoreOnCommandException = [ud boolForKey:@"LSCoreOnCommandException"];
  
  if (LSCoreOnCommandException)
    NSLog(@"Note: LSCoreOnCommandException is turned on!");
}

- (id)init {
  id p;

  /* this component is a session-singleton */
  if ((p = [self persistentInstance])) {
    [self release];
    return [p retain];
  }
  
  if ((self = [super init])) {
    id tb = [[[self session] userDefaults] objectForKey:@"joblist_view"]; 
    self->tabKey = (tb != nil) ? [tb copy] : @"toDoList";
    
    [self registerAsPersistentInstance];

    self->startIndex        = 0;
    self->selectedAttribute = nil;
    self->fetchJobs         = YES;

    [self registerForNotificationNamed:LSWJobHasChanged];

    if (self->timeList != nil) {
      [self->timeList release];
      self->timeList = nil;
    }
    self->timeList = [[NSArray alloc] initWithObjects:
					@"current", @"future", nil];
    self->timeSelection = @"current";
    
    // TODO: replace with lazy call to teams
    self->teams = [[[self session] teams] retain];
  }
  return self;
}

- (void)dealloc {
  [self unregisterAsObserver];
  
  [self->filteredJobList   release];
  [self->job               release];
  [self->subJob            release];
  [self->selectedAttribute release];
  [self->tabKey            release];
  [self->keywordsString    release];
  [self->timeSelection     release];
  [self->item              release];
  [self->teams             release];
  [self->timeList          release];
  [self->selectedTeam      release];
  [super dealloc];
}

/* operations */

- (void)_fetchJobs {
  self->startIndex = 0;

  if ([self->tabKey isEqualToString:@"toDoList"])
    [self _fetchJobs:@selector(_setToDoList)];
  else if ([self->tabKey isEqualToString:@"archivedJobs"])
    [self _fetchJobs:@selector(_setArchivedJobs)];
  else if ([self->tabKey isEqualToString:@"delegatedJobs"])
    [self _fetchJobs:@selector(_setDelegetedJobs)];
  else if ([self->tabKey isEqualToString:@"palmJobs"])
    ; /* TODO: intentional fall through? */
  else
    [self _fetchJobs:@selector(_setToDoList)];
}

- (void)_filterTeams {
  NSNumber       *showId;
  NSMutableArray *result     = nil;
  NSEnumerator   *enumerator = nil;
  id             obj         = nil;

  showId = (self->selectedTeam == nil)
    ? [[[self session] activeAccount] valueForKey:@"companyId"]
    : [self->selectedTeam valueForKey:@"companyId"];
  
  result = [NSMutableArray arrayWithCapacity:64];
  enumerator = [self->filteredJobList objectEnumerator];
  while ((obj = [enumerator nextObject])) {
    if (!((self->showMyGroups) && (self->selectedTeam == nil))) {
      if (![[obj valueForKey:@"executantId"] isEqual:showId])
        continue;
    }
    
    if (obj) [result addObject:obj];
  }
  ASSIGN(self->filteredJobList, result);
}

- (void)_filterTime {
  NSMutableArray *result     = nil;
  NSEnumerator   *enumerator = nil;
  id             obj         = nil;
  NSCalendarDate *now;
  BOOL           isFuture;
    
  isFuture = [self->timeSelection isEqualToString:@"future"];
  
  now = [NSCalendarDate date];
  [now setTimeZone:[[self session] timeZone]];
  
  result = [NSMutableArray arrayWithCapacity:64];

  enumerator = [self->filteredJobList objectEnumerator];
  while ((obj = [enumerator nextObject])) {
    NSCalendarDate *sd;
    
    sd = [obj valueForKey:@"startDate"];
    
    if ([sd compare:[now endOfDay]]
        == NSOrderedDescending) {
      if (isFuture)
        [result addObject:obj];
    }
    else {
      if (!isFuture)
        [result addObject:obj];
    }
  }
  ASSIGN(self->filteredJobList, result);
}

- (void)_fetchPrefExecJobs {
  OGoObjectLinkManager *lm;
  NSEnumerator         *enumerator;
  NSMutableArray       *res;
  NSArray              *links;
  id                   obj, account;
  
  lm      = [[[self session] commandContext] linkManager];
  account = [[[self session] commandContext] valueForKey:LSAccountKey];
  links   = [lm allLinksTo:(EOKeyGlobalID *)[account globalID]
		type:@"Preferred Job Executant"];
  
  [self _fetchJobs:@selector(_setToDoList)];

  links = [links map:@selector(sourceGID)];

  res  = [NSMutableArray array];
  
  enumerator = [self->filteredJobList objectEnumerator];

  while ((obj = [enumerator nextObject])) {
    if ([links containsObject:[obj globalID]])
      [res addObject:obj];
  }
  ASSIGN(self->filteredJobList, res);
}

/* notifications */

- (void)syncAwake {
  [super syncAwake];

  if (self->fetchJobs) {
    [self tabClicked];
    self->fetchJobs = NO;
  }
}

- (void)noteChange:(NSString *)_cn onObject:(id)_object {
  [super noteChange:_cn onObject:_object];
  
  if (![_cn isEqualToString:LSWJobHasChanged])
    return;
  
  if (_object) {
    id       myAccount;
    NSNumber *accountId;

    myAccount = [[self session] activeAccount];
    accountId = [myAccount valueForKey:@"companyId"];
     
    self->tabKey = [[_object valueForKey:@"executantId"] isEqual:accountId]
      ? @"toDoList" : @"delegatedJobs";
  }
  self->fetchJobs = YES;
}

/* commands */

- (NSArray *)_filterOutWasteJobs:(NSArray *)_list {
  // TODO: what are 'waste jobs'?!
  return [self runCommand:@"job::remove-waste-jobs", @"jobs", _list, nil];
}

- (void)_loadExecutantEOsIntoJobs:(NSArray *)_list {
  [self runCommand:@"job::get-job-executants",
          @"objects", _list,
          @"relationKey", @"executant", nil];
  [self runCommand:@"job::setcreator",
          @"objects",     _list,
          @"relationKey", @"creator",
        nil];
}
- (void)_loadProjectEOsIntoJobs:(NSArray *)_list {
  [self runCommand:
          @"job::get-project",
          @"objects",      self->filteredJobList,
          @"relationKey", @"toProject",
          nil];
}

- (void)_correctTimeZonesOfJobs:(NSArray *)_list {
  NSArray *dates;
  
  dates = [_list mappedArrayUsingSelector:@selector(objectForKey:)
                 withObject:@"endDate"];
  [dates makeObjectsPerformSelector:@selector(setTimeZone:)
         withObject:[[self session] timeZone]];
}

/* setup code */

- (void)_finalizeSet {
  id tmp;

  if ([self->filteredJobList count] == 0) {
    id jl = [NSArray array];
    ASSIGN(self->filteredJobList,jl);
    return;
  }
  
  tmp = [self _filterOutWasteJobs:self->filteredJobList];
  ASSIGN(self->filteredJobList, tmp);
  
  [self _loadExecutantEOsIntoJobs:self->filteredJobList];
  [self _loadProjectEOsIntoJobs:self->filteredJobList];
  [self _loadProjectEOsIntoJobs:self->filteredJobList];
  [self _correctTimeZonesOfJobs:self->filteredJobList];
}

/* setup list */

- (id)_activeAccountEO {
  return [(OGoSession *)[self session] activeAccount];
}

- (void)_setToDoList {
  NSAutoreleasePool *pool;
  NSMutableArray    *result;
  id      ac;
  NSArray *j;

  pool   = [[NSAutoreleasePool alloc] init];
  
  result = [NSMutableArray array];
  ac = [self _activeAccountEO];
  if ((j = [ac run:@"job::get-todo-jobs", nil]))
    [result addObjectsFromArray:j];
  
  [self->filteredJobList release]; self->filteredJobList = nil;
  self->filteredJobList = [result copy]; // retain filteredJobList
  [pool release];
}

- (void)_setControlJobs {
  [self->filteredJobList release]; self->filteredJobList = nil;  
  self->filteredJobList =
    [[[self _activeAccountEO] run:@"job::get-control-jobs",nil] retain];
}

- (void)_setDelegetedJobs {
  [self->filteredJobList release]; self->filteredJobList = nil;  
  self->filteredJobList =
    [[[self _activeAccountEO] run:@"job::get-delegated-jobs", nil] 
      retain];
}

- (void)_setArchivedJobs {
  [self->filteredJobList release]; self->filteredJobList = nil;  
  self->filteredJobList =
    [[[self _activeAccountEO] run:@"job::get-archived-jobs", nil]
      retain];
}

- (void)_handleException:(NSException *)_exc {
  NSString *s;
  
  [self logWithFormat:
           @"command exception:\n"
           @"  name=  %@\n  reason=%@\n  info=  %@",
          [_exc name], [_exc reason], [_exc userInfo]];
  s = [[NSString alloc] initWithFormat:@"%@ %@",[_exc name], [_exc reason]];
  [self setErrorString:s];
  [s release];
  
  if (LSCoreOnCommandException) {
    [self logWithFormat:
            @"dumping core because LSCoreOnCommandException is turned on!"];
    abort();
  }
}

- (void)_fetchJobs:(SEL)_sel {
  BOOL isOk = YES;

  [self setErrorString:nil];

  NS_DURING {
    [self performSelector:_sel];
    [self _finalizeSet];
  }
  NS_HANDLER {
    [self _handleException:localException];
    isOk = NO;
  }
  NS_ENDHANDLER;

  if (isOk) {
    if (![self commit]) {
      [self logWithFormat:@"%s: commit failed !", __PRETTY_FUNCTION__];
      [self rollback];
    }
  }
  else {
    [self logWithFormat:@"%s: command failed !", __PRETTY_FUNCTION__];
    [self rollback];
  }
}

- (void)_filterForKeywords {
  NSMutableArray  *result;
  NSMutableString *str;
  NSArray         *fields;
  NSString        *field     = nil;
  NSEnumerator    *jobEnum;
  NSEnumerator    *fieldEnum = nil;
  NSRange         r;
  id              j;

  if ([self->keywordsString length] == 0)
    return;
  
  result    = [NSMutableArray arrayWithCapacity:16];
  str       = [NSMutableString stringWithCapacity:32];
  [str appendString:self->keywordsString];

  jobEnum   = [self->filteredJobList objectEnumerator];
  fields    = [str componentsSeparatedByString:@","];

  while ((j = [jobEnum nextObject])) {
    BOOL     found = NO;
    NSString *kw;
    
    kw        = [j valueForKey:@"keywords"];
    fieldEnum = [fields objectEnumerator];
    
    while ((kw != nil) && (field = [fieldEnum nextObject])) {
      r = [kw rangeOfString:field options:NSCaseInsensitiveSearch];

      if (r.length > 0) {
	found = YES;
      }
      else {
	found = NO;
	break;
      }
    }
    if (found) [result addObject:j];
  }
  ASSIGN(self->filteredJobList, result);
}

/* actions */

- (id)filter {
  if ([self->tabKey isEqualToString:@"prefExeJobs"]) {
    [self _fetchPrefExecJobs];
  }
  else {
    [self _fetchJobs];
    if ([self->tabKey isEqualToString:@"toDoList"]) {
      [self _filterTeams];
      [self _filterTime];
    }
    else if ([self->tabKey isEqualToString:@"delegatedJobs"]) {
      [self _filterTime];
    }
  }
  [self _filterForKeywords];
  return nil;
}

- (id)tabClicked {
  self->startIndex = 0;

  if ([self->tabKey isEqualToString:@"prefExeJobs"]) {
    [self _fetchPrefExecJobs];
  }
  else {
    [self _fetchJobs];

    if ([self->tabKey isEqualToString:@"toDoList"]) {
      [self _filterTeams];
      [self _filterTime];
    }
    else if ([self->tabKey isEqualToString:@"delegatedJobs"]) {
      [self _filterTime];
    }
  }
  return nil;
}

- (id)viewPalmJob {
  id page = nil;

  page = [self pageWithName:@"SkyPalmJobViewer"];
  [page setObject:self->job];

  return page;
}

/* accessors */

- (void)setJob:(id)_job {
  ASSIGN(self->job, _job);
}
- (id)job {
  return self->job;
}

- (void)setShowMyGroups:(BOOL)_flag {
  self->showMyGroups = _flag;
}
- (BOOL)showMyGroups {
  return self->showMyGroups;
}

- (void)setSubJob:(id)_subJob {
  ASSIGN(self->subJob, _subJob);
}
- (id)subJob {
  return self->subJob;
}

- (void)setSelectedAttribute:(NSDictionary *)_selectedAttribute {
  ASSIGN(self->selectedAttribute, _selectedAttribute);
}
- (NSDictionary *)selectedAttribute {
  return self->selectedAttribute;    
}

- (void)setTabKey:(NSString *)_tabKey {
  ASSIGN(self->tabKey, _tabKey);
  [[[self session] userDefaults] setObject:_tabKey forKey:@"joblist_view"];
}
- (NSString *)tabKey {
  return self->tabKey;
}

- (void)setItem:(id)_item {
  ASSIGN(self->item, _item);
}
- (id)item {
  return self->item;
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

- (NSArray *)teams {
  return self->teams;
}

- (NSArray *)timeList {
  return self->timeList;
}

- (void)setSelectedTeam:(id)_team {
  ASSIGN(self->selectedTeam, _team);
}
- (id)selectedTeam {
  return self->selectedTeam;
}

- (void)setTimeSelection:(NSString *)_time {
  ASSIGN(self->timeSelection, _time);
}
- (NSString *)timeSelection {
  return self->timeSelection;
}

- (void)setKeywordsString:(NSString *)_keywordsString {
  ASSIGN(self->keywordsString, _keywordsString);
}
- (NSString *)keywordsString {
  return self->keywordsString;
}

- (void)setFetchJobs:(BOOL)_fetchJobs {
  self->fetchJobs = _fetchJobs;
}
- (BOOL)fetchJobs {
  return self->fetchJobs;
}

- (NSArray *)filteredJobList {
  return self->filteredJobList;
}

- (BOOL)needGroupCheckBox {
  return (!(self->selectedTeam)) ? YES : NO;
}

/* action */

- (NSNumber *)endDateOutOfTime {
  NSCalendarDate *now = [NSCalendarDate date];
  NSCalendarDate *eD  = [self->job valueForKey:@"endDate"];

  [now setTimeZone:[eD timeZone]];
  if ([[eD beginOfDay] compare:[now beginOfDay]] == NSOrderedAscending)
    return YesNumber;
  return NoNumber;
}

- (id)viewJob {
  return [self activateObject:self->job withVerb:@"view"];
}
- (id)newJob {
  WOComponent *ct = nil;
  
  [[self session] removeTransferObject];
  ct = [[self session] instantiateComponentForCommand:@"new" type:eoJobType];
  [ct setExecutant:[self _activeAccountEO]];
  if (ct) [self enterPage:(id)ct];
  return ct;
}

- (NSString *)timeLabel {
  return [[self labels] valueForKey:self->item];
}

- (int)blockSize {
  id sn = [self session];
  return [[[sn userDefaults] objectForKey:@"job_blocksize"] intValue];
}

- (BOOL)isContactEOArchived:(id)_eo {
  return [@"archived" isEqual:[_eo valueForKey:@"dbStatus"]];
}

- (NSNumber *)isCreatorArchived {
  return [self isContactEOArchived:[self->job valueForKey:@"creator"]]
    ? YesNumber : NoNumber;
}
- (NSNumber *)isExecutantArchived {
  return [self isContactEOArchived:[self->job valueForKey:@"executant"]]
    ? YesNumber : NoNumber;
}

- (BOOL)preferredExecutantsEnabled {
  return PreferredAccountsEnabled;
}

@end /* LSWJobs */
