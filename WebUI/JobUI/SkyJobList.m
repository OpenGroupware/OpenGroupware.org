/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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

@class NSString, NSDictionary;
@class EOArrayDataSource;

@interface SkyJobList : LSWContentPage
{
@protected
  NSDictionary      *selectedAttribute;
  unsigned          startIndex;
  id                job;
  BOOL              fetchJobs;
  BOOL              isDescending;
  NSString          *sortedKey;
  EOArrayDataSource *dataSource;
}

@end /* SkyJobList */

#include "common.h"
#include <OGoFoundation/LSWNotifications.h>
#include <EOControl/EOArrayDataSource.h>

@implementation SkyJobList

static NSDictionary *iconMap = nil;

+ (void)initialize {
  // TODO: check superclass version
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  if (iconMap == nil)
    iconMap = [[ud dictionaryForKey:@"JobListIconMap"] copy];
}

- (id)init {
  if ((self = [super init])) {
    self->fetchJobs = YES;
    [self registerForNotificationNamed:LSWJobHasChanged];
    self->sortedKey = [@"jobStatus" retain];

    self->dataSource = [[EOArrayDataSource alloc] init];
  }
  return self;
}

- (void)dealloc {
  [self unregisterAsObserver];
  [self->job release];
  [self->sortedKey release];
  [self->dataSource release];
  
  [super dealloc];
}

- (void)_fetchJobs {
  NSUserDefaults    *d;
  NSAutoreleasePool *pool;
  NSMutableArray    *result;
  NSCalendarDate    *today, *future;
  unsigned int      seconds;
  id                ac;
  NSArray           *j;
  BOOL              showOverdue;
  WOSession         *s;

  s      = [self session];
  pool   = [[NSAutoreleasePool alloc] init];
  result = [NSMutableArray array];
  ac     = [s activeAccount];
  d      = [s userDefaults];

  seconds     = [[d valueForKey:@"news_filterDays"] intValue] * 86400;
  showOverdue = [d boolForKey:@"news_showOverdueJobs"];

  today  = [NSCalendarDate date];
  future = [today addTimeInterval:seconds];

  if (showOverdue) {
    // fetch all first, filter afterwards 
    j = [ac run:@"job::get-todo-jobs", nil];
#if 0    
    p = [ac run:@"job::get-todo-processes", nil];
#endif
  }
  else {
    j = [ac run:@"job::get-todo-jobs",
            @"startDate", today,
            @"endDate",   future, nil];
#if 0  
    p = [ac run:@"job::get-todo-processes",
            @"startDate", today,
            @"endDate",   future, nil];
#endif
  }

  [result addObjectsFromArray:j];
#if 0  
  [result addObjectsFromArray:p];
#endif
  
  if (showOverdue) {
    // remove all jobs with endDate later than future
    // and all jobs which are done
    unsigned max;
    id       j;

    if ((max = [result count])) {
      while (max--) {
        NSCalendarDate *endDate;
        NSString       *status;

        j = [result objectAtIndex:max];
        endDate = [j valueForKey:@"endDate"];
        status  = [j valueForKey:@"jobStatus"];
        if (([endDate earlierDate:future] == future) ||
            [status isEqualToString:@"25_done"] ||
            [status isEqualToString:@"02_rejected"] ||
            [status isEqualToString:@"30_archived"])
          [result removeObjectAtIndex:max];
      }
    }
  }

  [self runCommand:@"job::get-job-executants",
        @"objects", result,
        @"relationKey", @"executant", nil];

  [self runCommand:@"job::setcreator",
        @"objects", result,
        @"relationKey", @"creator", nil];

  [[result mappedArrayUsingSelector:@selector(objectForKey:)
        withObject:@"endDate"]
               makeObjectsPerformSelector:@selector(setTimeZone:)
               withObject:[[self session] timeZone]];

  [self->dataSource setArray:result];
  self->fetchJobs = YES;

  [pool release]; pool = nil;
}

- (void)syncAwake {
  [super syncAwake];
  
  if (self->fetchJobs)
    [self _fetchJobs];
}

- (void)syncSleep {
  self->fetchJobs = YES;
  [self->job release];  self->job  = nil;
  
  [super syncSleep];
}

//accessors  

- (void)setStart:(unsigned)_startIndex {
  self->startIndex = _startIndex;
}
- (unsigned)start {
  return self->startIndex;    
}

- (void)setSortedKey:(NSString *)_sortedKey {
  ASSIGN(self->sortedKey,_sortedKey);
}
- (NSString *)sortedKey {
  return self->sortedKey;
}

- (void)setIsDescending:(BOOL)_isDescending {
  self->isDescending = _isDescending;
}
- (BOOL)isDescending {
  return self->isDescending;    
}

- (void)setSelectedAttribute:(NSDictionary *)_selectedAttribute {
  self->selectedAttribute = _selectedAttribute;
}
- (NSDictionary *)selectedAttribute {
  return self->selectedAttribute;    
}

- (void)setJob:(id)_job {
  ASSIGN(self->job, _job);
}
- (id)job {
  return self->job;    
}

- (id)jobStatus {
  return [[self job] valueForKey:@"jobStatus"];
}

- (id)dataSource {
  return self->dataSource;
}

// --- conditionals -------------------------------------------------------

- (BOOL)endDateOutOfTime {
  NSCalendarDate *now;
  NSCalendarDate *eD;

  now = [NSCalendarDate date];
  eD  = [self->job valueForKey:@"endDate"];
  
  [now setTimeZone:[eD timeZone]];
  if ([[eD beginOfDay] compare:[now beginOfDay]] == NSOrderedAscending)
    return YES;
  return NO;
}

- (id)enddateColor {
  return [self endDateOutOfTime] ? @"#FF0000" : @"000000";
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

- (NSString *)statusIcon {
  return [iconMap objectForKey:[self jobStatus]];
}

/* actions */

- (id)refresh {
  [self _fetchJobs];
  return nil;
}

- (id)viewJob {
  return [self activateObject:self->job withVerb:@"view"];
}

/* notifications */

- (void)noteChange:(NSString *)_cn onObject:(id)_object {
  [super noteChange:_cn onObject:_object];

  if ([_cn isEqualToString:LSWJobHasChanged])
    self->fetchJobs = YES;
}

@end /* SkyJobList */
