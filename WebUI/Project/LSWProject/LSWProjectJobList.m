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

#include <OGoFoundation/LSWContentPage.h>

@class EOGlobalID;

@interface LSWProjectJobList : LSWContentPage
{
@private
  EOGlobalID *projectId;
  id         project;
  id         jobs;
  NSString   *sortedKey;

  unsigned   startIndex;
  BOOL       isDescending;
  id         job;
  id         subJob;
  id         selectedAttribute;
  BOOL       showProjectReport;
  id         highestJob;
}

- (id)project;
- (id)jobs;

@end /* LSWProjectJobList */

#include "common.h"

static NSArray *_getSubJobExecutants(NSArray *_list) {
  NSMutableArray *array      = [NSMutableArray arrayWithCapacity:32];
  id             obj         = nil;
  Class          arrayClass  = [NSArray class];
  register IMP   objAtIdx;
  register IMP   addObj;  
  register int   i, cnt;

  objAtIdx = [_list methodForSelector:@selector(objectAtIndex:)];
  addObj   = [array methodForSelector:@selector(addObjectsFromArray:)];
                    
  for (i = 0, cnt = [_list count]; i < cnt; i++) {
    obj = [objAtIdx(_list, @selector(objectAtIndex:), i) valueForKey:@"jobs"];
    if ([obj isKindOfClass:arrayClass]) 
      addObj(array, @selector(addObjectsFromArray:), obj);
  }
  return array;                    
}

@implementation LSWProjectJobList

+ (void)initialize {
  NSAssert2([super version] == 3,
           @"invalid superclass (%@) version %i !",
           NSStringFromClass([self superclass]), [super version]);
}

- (id)init {
  if ((self = [super init])) {
    self->sortedKey = [@"jobStatus" retain];
  }
  return self;
}

- (void)dealloc {
  [self->projectId release];
  [self->project release];
  [self->jobs release];
  [self->sortedKey release];
  [self->job release];
  [self->subJob release];
  [self->selectedAttribute release];
  [self->highestJob release];
  [super dealloc];
}

/* activation */

- (void)_fetchJobs {
  id toJob;
  
  NSAssert(([self project] != nil), @"No project set");
  
  [self runCommand:@"project::get-jobs",
        @"object",      [self project],
        @"relationKey", @"jobs", nil];

  toJob = [[self project] valueForKey:@"jobs"];

  toJob = [self runCommand:@"job::remove-waste-jobs", @"jobs", toJob, nil];
  
  [self runCommand:@"job::get-job-executants",
          @"objects", toJob,
          @"relationKey", @"executant",
          nil];
  [self runCommand:@"job::setcreator",
          @"objects",      toJob,
          @"relationKey", @"creator",
          nil];
  [self runCommand:@"job::get-job-executants",
          @"objects",
          _getSubJobExecutants(toJob),
          @"relationKey", @"executant",
          nil];
  ASSIGN(self->jobs, toJob);
}

- (void)syncAwake {
  [super syncAwake];
  [self _fetchJobs];
}

/* accessors */

- (void)setProject:(id)_project {
  ASSIGN(self->project, _project);
}
- (id)project {
  if (self->project)
    return self->project;
  
  if (self->projectId) {
    self->project = [[self run:@"project::get",
                           @"gid", self->projectId,
                           nil] lastObject];
    
    self->project = [self->project retain];
  }
  return self->project;
}

- (void)setProjectId:(EOGlobalID *)_gid {
  ASSIGNCOPY(self->projectId, _gid);
}
- (id)projectId {
  return self->projectId;
}

- (void)setSortedKey:(NSString *)_sortedKey {
  ASSIGN(self->sortedKey,_sortedKey);
}
- (NSString *)sortedKey {
  return self->sortedKey;
}

- (NSArray *)jobs {
  if ([self->sortedKey length]) {
    EOSortOrdering *so;
    SEL            sel;
    NSArray        *sorted;

    sel = (self->isDescending) ? EOCompareDescending : EOCompareAscending;
    so = [EOSortOrdering sortOrderingWithKey:self->sortedKey selector:sel];
    sorted = [NSArray arrayWithObject:so];
    sorted = [self->jobs sortedArrayUsingKeyOrderArray:sorted];
    ASSIGN(self->jobs, sorted);
  }
  return self->jobs;
}

- (void)setSubJob:(id)_subJob {
  ASSIGN(self->subJob, _subJob);
}
- (id)subJob {
  return self->subJob;
}

- (void)setJob:(id)_job {
  ASSIGN(self->job, _job);
}
- (id)job {
  return self->job;
}

- (void)setSelectedAttribute:(id)_attr {
  ASSIGN(self->selectedAttribute, _attr);
}
- (id)selectedAttribute {
  return self->selectedAttribute;
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

- (BOOL)endDateOutOfTimeBool {
  NSCalendarDate *now;
  NSCalendarDate *eD;

  now = [NSCalendarDate date];
  eD  = [self->job valueForKey:@"endDate"];
  
  [now setTimeZone:[eD timeZone]];
  if ([[eD beginOfDay] compare:[now beginOfDay]] == NSOrderedAscending)
    return YES;
  return NO;
}

- (id)jobStatus {
  return [[self job] valueForKey:@"jobStatus"];
}

- (id)priority  {
  return [[self job] valueForKey:@"priority"];
}

- (NSString *)statusIcon {
  static NSDictionary *iconMap = nil;

  if (iconMap == nil) {
    iconMap = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    @"led_red.gif",    @"00_created",
                                    @"led_yellow.gif", @"20_processing",
                                    @"led_green.gif",  @"25_done",
                                    @"led_red.gif",    @"02_rejected",
                                    @"led_dark.gif",   @"30_archived",
                                    nil];
  }
  return [iconMap valueForKey:[self jobStatus]];
}

- (id)enddateColor {
  return [self endDateOutOfTimeBool] ? @"#FF0000" : @"000000";
}

- (BOOL)creatorIsVisible {
  id am, gid;

  am  = [[[self session] commandContext] accessManager];
  gid = [[[self job] valueForKey:@"creator"] valueForKey:@"globalID"];

  return [am operation:@"r" allowedOnObjectID:gid];
}

- (BOOL)executantIsVisible {
  id  am, gid;
  
  am  = [[[self session] commandContext] accessManager];
  gid = nil;
  
  if ([[[self job] valueForKey:@"isTeamJob"] boolValue])
    return YES;

  gid = [[[self job] valueForKey:@"executant"] valueForKey:@"globalID"];
  return [am operation:@"r" allowedOnObjectID:gid];
}

- (void)setShowProjectReport:(BOOL)_showReport {
  self->showProjectReport = _showReport;
}
- (BOOL)showProjectReport {
  return self->showProjectReport;
} 

- (void)setHighestJob:(id)_job {
  ASSIGN(self->highestJob, _job);
}
- (id)highestJob {
  return self->highestJob;
}

/* access control */

- (BOOL)isEditDisabled {
  BOOL isEnabled;
  id sn, accountId, obj;

  sn        = [self session];
  accountId = [[sn activeAccount] valueForKey:@"companyId"];
  obj       = [self project];

  isEnabled = (([accountId isEqual:[obj valueForKey:@"ownerId"]]) ||
               ([sn activeAccountIsRoot]));

  return !isEnabled;
}

/* actions */

- (id)viewJob {
  return [self activateObject:self->job withVerb:@"view"];
}

- (id)viewSubJob {
  return [self activateObject:self->subJob withVerb:@"view"];
}

- (NSString *)jobImportCallBack {
  /* only set import callback when edit permission is set */
  return [self isEditDisabled] ? nil : @"import";
}

- (id)newJob {
  id ct = nil;
  id sn = nil;

  sn = [self session];
  
  [sn removeTransferObject];

  ct = [sn instantiateComponentForCommand:@"new"
           type:[NGMimeType mimeType:@"eo/job"]];

  [ct takeValue:[self project] forKey:@"project"];
  [[sn navigation] enterPage:ct];

  return nil;
}

/* job report additions */

- (NSNumber *)sumForAttribute:(NSString *)_attribute {
  NSEnumerator *jobEnum;
  id curJob, j;
  int sum = 0, high = 0;

  j = [self jobs];

  if ([j count] == 0)
    return nil;
  
  jobEnum = [j objectEnumerator];
  while ((curJob = [jobEnum nextObject])) {
    int cur;
    
    cur = [[curJob valueForKey:_attribute] intValue];

    if (cur > high) {
      [self setHighestJob:curJob];
      high = cur;
    }
    sum += cur;
  }
  return [NSNumber numberWithInt:sum];
}

- (NSString *)stringForAttribute:(NSString *)_attr
  withUnitLabel:(NSString *)_label
{
  id l;
  NSNumber *s;
  double c, percent;

  l = [self labels];

  if ((s = [self sumForAttribute:_attr]) == nil) {
    return [l valueForKey:@"noJobAssociated"];
  }
  else if ([s intValue] == 0) {
    return [l valueForKey:[NSString stringWithFormat:@"no%@Data",
                                    _attr]];
  }
  else {
    c = [[[self highestJob] valueForKey:_attr] doubleValue];
    percent = (c / [s doubleValue]) * 100;
  }
  
  return [NSString stringWithFormat:@"%@ %@ %@ %i %@, %.0f %@ (%.0f %%) %@ %@",
                   s, [l valueForKey:_label],
                   [l valueForKey:@"in"], [[self jobs] count],
                   [l valueForKey:@"jobsLabel"], c,
                   [l valueForKey:_label], percent,
                   [l valueForKey:@"in"], [l valueForKey:@"jobLabel"]];
}

- (NSString *)actualWorkString {
  return [self stringForAttribute:@"actualWork"
               withUnitLabel:@"minutesLabel"];
}

- (NSString *)totalWorkString {
  return [self stringForAttribute:@"totalWork"
               withUnitLabel:@"minutesLabel"];
}

- (NSString *)kilometersString {
  return [self stringForAttribute:@"kilometers"
               withUnitLabel:@"kilometersLabel"];
}

- (NSString *)percentCompleteString {
  NSString *result;
  NSNumber *s;
  id l;
  double c, i;

  l = [self labels];

  if ((s = [self sumForAttribute:@"percentComplete"]) == nil) {
    return [l valueForKey:@"noJobAssociated"];
  }
  else if ([s intValue] == 0) {
    return [l valueForKey:@"nopercentData"];
  }
  else {
    c = [[[self highestJob] valueForKey:@"percentComplete"] doubleValue];
    i = [s doubleValue] / [[self jobs] count];
  }
  
  result = [NSString stringWithFormat:@"%.0f %@ %@ %i %@",
                     i, [l valueForKey:@"percent"],
                     [l valueForKey:@"in"], [[self jobs] count],
                     [l valueForKey:@"jobsLabel"]];


  if (c < 100)
    return [result stringByAppendingFormat:@", %.0f %@ %@ %@",
                   c,
                   [l valueForKey:@"percent"],
                   [l valueForKey:@"in"], [l valueForKey:@"jobLabel"]];
  else
    return [result stringByAppendingFormat:@", %@ %@ %@",
                   [l valueForKey:@"25_done"],
                   [l valueForKey:@"in"], [l valueForKey:@"jobLabel"]];
}

- (NSString *)jobHref {
  NSDictionary *dict;

  dict = [NSDictionary dictionaryWithObjectsAndKeys:
                       [[self session] sessionID], @"wosid", 
                       [[self context] contextID], @"cid",
                       [self->highestJob valueForKey:@"jobId"], @"jobId",
                       nil];
  return [[self context] directActionURLForActionNamed:@"LSWViewAction/viewJob"
                         queryDictionary:dict];
}

@end /* LSWProjectJobList */
