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

#include <OGoPalmUI/SkyPalmAssignEntry.h>

@interface SkyPalmAssignJob : SkyPalmAssignEntry
{
  NSArray *jobs;
}
@end /* SkyPalmAssignJob */

#import <Foundation/Foundation.h>
#include <OGoFoundation/OGoFoundation.h>
#include <LSFoundation/LSFoundation.h>
#include <EOControl/EOQualifier.h>
#include <EOControl/EOFetchSpecification.h>
#include <EOControl/EOSortOrdering.h>
#include <EOControl/EOKeyGlobalID.h>
#include <NGExtensions/EODataSource+NGExtensions.h>

#include <OGoJobs/SkyPersonJobDataSource.h>
#include <OGoPalm/SkyPalmConstants.h>
#include <OGoPalm/SkyPalmJobDocument.h>
#include <OGoPalm/SkyPalmEntryDataSource.h>

#include <OGoJobs/SkyJobDocument.h>
#include <OGoJobs/SkyPersonJobDataSource.h>

@implementation SkyPalmAssignJob

- (id)init {
  if ((self = [super init])) {
    self->jobs = nil;
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->jobs);
  [super dealloc];
}
#endif

// accessors

- (EOQualifier *)_qualifierForPalmDS {
  id actualId = [[self doc] globalID];

  if (actualId != nil) {
    actualId = [[actualId keyValuesArray] objectAtIndex:0];
  }
  if ((actualId != nil) && ([actualId intValue] > 0)) {
    return [EOQualifier qualifierWithQualifierFormat:
                        @"skyrix_id > 0 AND is_deleted=0 AND is_archived=0 "
                        @"AND NOT (palm_todo_id=%@) "
                        @"AND device_id=%@", actualId, [self deviceId]];
  }
  return [EOQualifier qualifierWithQualifierFormat:
                      @"skyrix_id > 0 AND is_deleted=0 AND is_archived=0 "
                      @"AND device_id=%@", [self deviceId]];
}
- (EOFetchSpecification *)_fetchSpecForPalmDS {
  return [EOFetchSpecification fetchSpecificationWithEntityName:@"palm_todo"
                               qualifier:[self _qualifierForPalmDS]
                               sortOrderings:nil];
}
- (LSCommandContext *)_commandContext {
  return [(id)[self session] commandContext];
}
- (SkyPalmDocumentDataSource *)_palmDataSource {
  SkyPalmEntryDataSource *das;
  das = [SkyPalmEntryDataSource dataSourceWithContext:[self _commandContext]
                                forPalmDb:@"ToDoDB"];

  return (SkyPalmDocumentDataSource *)das;
}
- (NSArray *)_assignedJobIds {
  SkyPalmDocumentDataSource *das    = [self _palmDataSource];
  NSEnumerator              *all    = nil;
  id                        one     = nil;
  NSMutableArray            *jobIds = nil;
  [das setFetchSpecification:[self _fetchSpecForPalmDS]];
  all = [[das fetchObjects] objectEnumerator];
  jobIds = [NSMutableArray array];
  while ((one = [all nextObject])) {
    [jobIds addObject:[one skyrixId]];
  } 
  return jobIds;
}

- (NSArray *)_filterJobsWithoutBindings:(NSArray *)_src {
  NSArray        *assignedIds = [self _assignedJobIds];
  NSEnumerator   *all         = nil;
  id             one          = nil;
  NSMutableArray *filtered    = nil;
  NSNumber       *jobId       = nil;

  all      = [_src objectEnumerator];
  filtered = [NSMutableArray array];

  while ((one = [all nextObject])) {
    jobId = [one valueForKey:@"jobId"];
    if (jobId == nil) {
      jobId =
        [[[one valueForKey:@"globalID"] keyValuesArray] objectAtIndex:0];
      if (jobId == nil) {
        NSLog(@"%s couldn't get jobId of record", __PRETTY_FUNCTION__,
              one);
        continue;
      }
    }
    if ([assignedIds containsObject:jobId])
      continue;
    
    [filtered addObject:one];
  }
  return filtered;
}

- (NSArray *)_sortOrderings {
  return [NSArray arrayWithObject:
                  [EOSortOrdering sortOrderingWithKey:@"name"
                                  selector:EOCompareAscending]];
}
- (EOFetchSpecification *)_fetchSpec {
  EOQualifier *qual = nil;

  qual = [EOQualifier qualifierWithQualifierFormat:
                      @"type='toDoJob'"];
  return [EOFetchSpecification fetchSpecificationWithEntityName:@"job"
                               qualifier:qual
                               sortOrderings:[self _sortOrderings]];
}
// only fetching todo jobs
- (void)_fetchJobs {
  SkyPersonJobDataSource *das   = nil;
  id                     curGID = nil;
  id                     ctx    = nil;

  curGID = [[(id)[self session] activeAccount] valueForKey:@"globalID"];
  ctx    = [(id)[self session] commandContext];
  das    =
    [[SkyPersonJobDataSource alloc] initWithContext:ctx
                                    personId:curGID];
  [das setFetchSpecification:[self _fetchSpec]];

  RELEASE(self->jobs);
  self->jobs = [das fetchObjects];
  self->jobs = [self _filterJobsWithoutBindings:self->jobs];
  RETAIN(self->jobs);
  RELEASE(das);
}

- (id)search {
  RELEASE(self->jobs); self->jobs = nil;
  return nil;
}

- (NSArray *)jobs {
  if (self->jobs == nil) {
    [self _fetchJobs];
  }
  return self->jobs;
}

- (id)job {
  return [self skyrixRecord];
}

// conditions
- (BOOL)hasJob {
  return ([self job] != nil) ? YES : NO;
}
- (BOOL)hasJobs {
  return ([[self skyrixRecords] count] > 0) ? YES : NO;
}
- (BOOL)hasJobOrJobs {
  if ([self hasJob])
    return YES;
  if ([self hasJobs])
    return YES;
  return NO;
}
- (BOOL)canSave {
  return (([self hasJob])  ||
          ([self hasJobs]) ||
          ([self createNewRecord]))
    ? YES : NO;
}

// actions
- (id)changeJob {
  [self setSkyrixRecord:nil];
  [self->skyrixRecords removeAllObjects];
  return nil;
}

- (id)selectJob {
  [self setSkyrixRecord:self->item];
  return nil;
}
- (id)selectJobs {
  if ([self->skyrixRecords count] == 1)
    [self setSkyrixRecord:[self->skyrixRecords lastObject]];
  return nil;
}

// overwriting
- (id)fetchSkyrixRecord {
  return [[self doc] skyrixRecord];
}

- (NSString *)primarySkyKey {
  return @"jobId";
}
- (SkyPalmJobDocument *)newPalmDoc {
  return (SkyPalmJobDocument *)[[self dataSource] newDocument];
}

- (id)newSkyrixRecordForPalmDoc:(SkyPalmDocument *)_doc {
  id                     ctx    = nil;
  SkyPersonJobDataSource *das   = nil;
  id                     rec    = nil;
  id                     person = nil;

  ctx    = [(id)[self session] commandContext];
  person = [ctx valueForKey:LSAccountKey];
  das    =
    [[SkyPersonJobDataSource alloc]
                             initWithContext:ctx
                             personId:[person valueForKey:@"companyId"]];
  rec = [das createObject];
  [_doc putValuesToSkyrixRecord:rec];
  [(SkyJobDocument *)rec save];
  
  RELEASE(das);
  return rec;
}

- (id)save {
  if (([self createNewRecord]) && ([self isSingleSelection])) {
    [self setSkyrixRecord:[self newSkyrixRecordForPalmDoc:[self doc]]];
  }
  return [super save];
}

@end /* SkyPalmAssignJob */
