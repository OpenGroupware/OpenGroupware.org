/*
  Copyright (C) 2000-2008 SKYRIX Software AG

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

#include <LSFoundation/OGoAccessHandler.h>

@interface OGoJobAccessHandler : OGoAccessHandler
@end

#include "common.h"

@interface OGoAccessHandler(Internals)
- (BOOL)_checkGIDs:(NSArray *)_ids;
@end

@implementation OGoJobAccessHandler

static BOOL debugOn = NO;
static BOOL IgnoreAccess = NO;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

  debugOn = [ud boolForKey:@"SkyAccessManagerDebug"];
  debugOn = YES;
}

- (NSArray *)getJobsForGIDs:(NSArray *)_gids {
  id                  *jobs, *gids, obj;
  int                 gidCnt, jobCnt;
  NSMutableDictionary *jobCache;
  NSEnumerator        *enumerator;
  NSArray             *array;
  jobCache = [[self context] valueForKey:@"_cache_job_access"];
  if (jobCache == nil) {
    jobCache = [NSMutableDictionary dictionaryWithCapacity:64];
    [[self context] takeValue:jobCache forKey:@"_cache_job_access"];
  }
  jobs = calloc([_gids count] + 1, sizeof(id));
  gids  = calloc([_gids count] + 1, sizeof(id));

  gidCnt = 0;
  jobCnt = 0;

  enumerator = [_gids objectEnumerator];

  while ((obj = [enumerator nextObject]) != nil) {
    id job;
    
    if ((job = [jobCache objectForKey:[obj keyValues][0]])) {
      jobs[jobCnt] = job;
      jobCnt++;
    }
    else {
      gids[gidCnt] = obj;
      gidCnt++;
    }
  }
  if (gidCnt > 0) {
    array = [NSArray arrayWithObjects:gids count:gidCnt];
    array = [[self context] runCommand:@"job::get-by-globalid",
                            @"noAccessCheck", [NSNumber numberWithBool:YES],
                            @"gids", array, nil];

    [[self context] runCommand:@"job::get-executant-jobs",
                @"objects",     array,
                @"relationKey", @"companyAssignments", nil];
    enumerator = [array objectEnumerator];

    while ((obj = [enumerator nextObject]) != nil) {
      EOKeyGlobalID *kid;

      kid = [obj valueForKey:@"globalID"];
      
      [jobCache setObject:obj forKey:[kid keyValues][0]];
      jobs[jobCnt] = obj;
      jobCnt++;
    }
  }
  array = [NSArray arrayWithObjects:jobs count:jobCnt];
  if (jobs != NULL) free(jobs); jobs = NULL;
  if (gids != NULL) free(gids); gids  = NULL;
  return array;
}

+ (void)setIgnoreAccess:(BOOL)_b {
  IgnoreAccess = _b;
}

- (BOOL)operation:(NSString *)_operation
  allowedOnObjectIDs:(NSArray *)_oids
  forAccessGlobalID:(EOGlobalID *)_accessGID
{
  // there are no real access rights implemented for jobs
  if (debugOn)
    [self logWithFormat:@"Returning static YES for %@ operation on %d jobs", 
                        _operation, [_oids count]];
  return YES;
}

- (NSArray *)objects:(NSArray *)_oids
  forOperation:(NSString *)_operation
  forAccessGlobalID:(EOGlobalID *)_pgid
{
  if (debugOn)
    [self logWithFormat:@"Returning all objects for operation %@ on %d jobs", 
                        _operation, [_oids count]];
  return _oids;
}

- (NSArray *)_entityNames {
  static NSArray *entityNames = nil;

  if (entityNames == nil) {
    id name;

    name        = @"Job";
    entityNames = [[NSArray alloc] initWithObjects:&name count:1];
  }
  return entityNames;
}

@end
