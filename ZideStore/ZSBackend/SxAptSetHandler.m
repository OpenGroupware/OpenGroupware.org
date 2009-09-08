/*
  Copyright (C) 2002-2005 SKYRIX Software AG

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

#include "SxAptSetHandler.h"
#include "SxAptManager.h"
#include "NGResourceLocator+ZSB.h"
#include "common.h"
#include <time.h>

@interface SxAptManager(Privates)
- (NSArray *)globalIDsForLoginAccount;
- (NSArray *)globalIDsForGroup:(id)_group;
@end

@implementation SxAptSetHandler

static NSArray *pkeyAndVersionGetAttrs = nil;
static NSArray *coreInfoGetAttrs       = nil;
static NSArray *eoExtractAttrs         = nil;
static NSArray *permissionsAttrs       = nil;
static BOOL debugOn = NO;

+ (void)initialize {
  static BOOL didInit = NO;
  NGResourceLocator *locator;
  NSUserDefaults *ud;
  NSDictionary   *plist;
  NSString       *p;
  if (didInit) return;
  didInit = YES;
  
  ud = [NSUserDefaults standardUserDefaults];
  
  locator = [NGResourceLocator zsbResourceLocator];
  p = [locator lookupFileWithName:@"AptBackendSets.plist"];
  plist = [p length] > 10
    ? [NSDictionary dictionaryWithContentsOfFile:p]
    : nil;
  if (plist == nil)
    [self logWithFormat:@"ERROR: could not load apt-backend plist: %@", p];
  
  pkeyAndVersionGetAttrs = [[plist objectForKey:@"KeyAndVersionAttrs"] copy];
  coreInfoGetAttrs       = [[plist objectForKey:@"CoreInfoAttrs"]      copy];
  eoExtractAttrs         = [[plist objectForKey:@"EOExtractAttrs"]     copy];
  permissionsAttrs       = [[NSArray arrayWithObjects:@"permissions",
                                     @"accessTeamId", nil] copy];
  didInit = YES;
  
  debugOn = [ud boolForKey:@"SxDebugAptHandler"];
}

- (id)initWithSetId:(SxAptSetIdentifier *)_setId 
  manager:(SxAptManager *)_manager
{
  if ((self = [super init])) {
    self->setId   = [_setId retain];
    self->manager = _manager;
  }
  return self;
}

- (void)dealloc {
  [self->setId release];
  [super dealloc];
}

/* accessors */

- (NSCalendarDate *)defaultStartDate {
  return [self->manager defaultStartDate];
}
- (NSCalendarDate *)defaultEndDate {
  return [self->manager defaultEndDate];
}

- (LSCommandContext *)commandContext {
  return [self->manager commandContext];
}

/* operations */

- (NSArray *)fetchAccessTeamGIDsFrom:(NSDate *)_start to:(NSDate *)_end {
  /* only fetch for proper read-access group */
  NSArray    *gids;
  EOGlobalID *cgid;
  
  cgid = ([[self->setId group] length] > 0)
    ? [self->manager globalIDForGroupWithName:[self->setId group]]
    : (EOKeyGlobalID *)[NSNull null]; /* this says "fetch private" */
  if (cgid == nil) {
    [self logWithFormat:@"got no gids for group/login %@ !", 
            [self->setId group]];
    return nil;
  }

  if (_start == nil) _start = [self defaultStartDate];
  if (_end   == nil) _end   = [self defaultEndDate];
  
  gids = [[self commandContext] runCommand:@"appointment::query",
		@"fromDate",  _start, 
		@"toDate",    _end,
		@"accessTeam", cgid,
		nil];
  if (debugOn) {
    [self logWithFormat:@"fetched %i access team %@ gids: %@", 
            [gids count], cgid, self->setId];
  }
  
  return gids;
}
- (NSArray *)fetchOverviewGIDsFrom:(NSDate *)_start to:(NSDate *)_end {
  /* include all appointments of a group/account */
  NSArray *gids;
  NSArray *cgids;
  
  cgids = ([[self->setId group] length] > 0)
    ? [self->manager globalIDsForGroup:[self->setId group]]
    : [self->manager globalIDsForLoginAccount];
  
  if (cgids == nil) {
    [self logWithFormat:@"got no gids for group/login %@ !", 
            [self->setId group]];
    return nil;
  }
  
  if (_start == nil) _start = [self defaultStartDate];
  if (_end   == nil) _end   = [self defaultEndDate];
  
  gids = [[self commandContext] runCommand:@"appointment::query",
		@"fromDate",  _start, 
		@"toDate",    _end,
		@"companies", cgids,
		nil];
  return gids;
}

- (NSArray *)fetchGIDs {
  return [self->setId isOverviewSet]
    ? [self fetchOverviewGIDsFrom:nil   to:nil]
    : [self fetchAccessTeamGIDsFrom:nil to:nil];
}

- (int)fetchCount {
  NSArray *a;
  
  if ((a = [self fetchGIDs]) == nil)
    return -1;
  return [a count];
}

- (NSArray *)fetchGIDsFrom:(NSDate *)_from to:(NSDate *)_to {
  return [self->setId isOverviewSet]
    ? [self fetchOverviewGIDsFrom:_from to:_to]
    : [self fetchAccessTeamGIDsFrom:_from to:_to];
}

- (NSArray *)fetchPkeysAndModDatesFrom:(NSDate *)_from to:(NSDate *)_to {
  /* only fetch for proper read-access group */
  // TODO: support for last-modified in Date table
  NSArray        *gids;
  NSMutableArray *result;
  NSCalendarDate *now;
  EOGlobalID *cgid;
  unsigned   i, count;
  NSString *_group = [self->setId group];
  
  cgid = (_group)
    ? [self->manager globalIDForGroupWithName:_group]
    : (EOKeyGlobalID *)[NSNull null]; /* this says "fetch private" */
  
  gids = [[self commandContext] runCommand:@"appointment::query",
		@"fromDate",  _from, 
		@"toDate",    _to,
		@"accessTeam", cgid,
		nil];
  if (gids == nil)
    return nil;
  
  count  = [gids count];
  result = [NSMutableArray arrayWithCapacity:(count + 1)];
  now    = [NSCalendarDate date];
  for (i = 0; i < count; i++) {
    EOKeyGlobalID *gid;
    NSDictionary  *entry;
    NSDate   *modDate;
    id keys[2], vals[2];
    
    gid     = [gids objectAtIndex:i];
    modDate = now; // TODO: support for last-modified in Date table
    
    keys[0] = @"pkey";         vals[0] = [gid keyValues][0];
    keys[1] = @"lastmodified"; vals[1] = modDate;
    
    entry = [[NSDictionary alloc] initWithObjects:vals forKeys:keys count:2];
    [result addObject:entry];
    [entry release];
  }
  //[self logWithFormat:@"got: %@", result];
  return result;
}

// only valid on infos with 'permissions' and 'accessTeam' attribute
- (BOOL)checkViewPermissionForApt:(id)_apt {
  NSString *perm  = [_apt valueForKey:@"permissions"];
  // need view permissions
  if ((perm == nil) || ([perm rangeOfString:@"v"].length == 0)) return NO;
  return [[_apt valueForKey:@"accessTeamId"] isNotNull];
}
- (NSArray *)checkPermissions:(NSArray *)_infos {
  NSMutableArray *checked;
  unsigned i, max;
  id       apt;

  checked = nil;
  max     = [_infos count];
  for (i = 0; i < max; i++) {
    apt = [_infos objectAtIndex:i];
    if (![self checkViewPermissionForApt:apt]) {
      if (checked == nil) {
        checked = [NSMutableArray arrayWithCapacity:max];
        if (i) {
          [checked replaceObjectsInRange:NSMakeRange(0,0)
                   withObjectsFromArray:_infos range:NSMakeRange(0,i)];
        }
      }
    }
    else {
      // view granted
      if (checked != nil) [checked addObject:apt];
    }
  }
  return (checked != nil)
    ? (NSArray *)checked : _infos;
}

- (BOOL)shouldCheckPermissions {
  // if overview calendar of group, then check the permission
  // --> no private appointments in team-overview cache
  return (([self->setId isOverviewSet]) && ([[self->setId group] length]))
    ? YES : NO;
}

- (NSArray *)fetchDateIdAndObjectVersionForGIDs:(NSArray *)_gids {
  // returns: dateId, objectVersion
  NSArray  *infos;
  unsigned count;
  BOOL     checkPermissions;
  NSArray  *attributes;

  checkPermissions = [self shouldCheckPermissions];

  if (debugOn && checkPermissions)
    [self debugWithFormat:@"fetching permission-checked ids and versions"];
    
  attributes = checkPermissions
    ? [pkeyAndVersionGetAttrs arrayByAddingObjectsFromArray:permissionsAttrs]
    : pkeyAndVersionGetAttrs;
  if (_gids == nil) return nil;
  if ((count = [_gids count]) == 0) return [NSArray array];
  
  infos = [[self commandContext]
	         runCommand:@"appointment::get-by-globalid",
                   @"gids",       _gids,
                   @"attributes", attributes,
	         nil];
  return checkPermissions ? [self checkPermissions:infos] : infos;
}

- (NSArray *)fetchCoreInfoForGIDs:(NSArray *)_gids {
  // returns: title, location, end/startdate, sensitivity
  NSMutableArray *gidMiss;
  NSMutableArray *result;
  NSArray  *keys;
  NSArray  *infos;
  NSArray  *attributes;
  BOOL     checkPermissions;
  unsigned i, count;
  
  if (_gids == nil) return nil;
  if ((count = [_gids count]) == 0) return [NSArray array];

  checkPermissions = [self shouldCheckPermissions];
  attributes = checkPermissions
    ? [coreInfoGetAttrs arrayByAddingObjectsFromArray:permissionsAttrs]
    : coreInfoGetAttrs;
  
  // TODO: is ordering of result considered significant ? we return unsorted
  
  if (debugOn) [self debugWithFormat:@"check cache ..."];
  
  /* fetch current version info */
  keys = [self fetchDateIdAndObjectVersionForGIDs:_gids];
  if ((count = [keys count]) == 0) return keys;
  
  gidMiss = nil;
  result = [NSMutableArray arrayWithCapacity:(count + 1)];
  
  for (i = 0; i < count; i++) {
    NSDictionary *info;
    id pkeyNum;
    int pkey, version;
    
    info    = [keys objectAtIndex:i];
    pkeyNum = [info objectForKey:@"dateId"];
    pkey    = [pkeyNum intValue];
    version = [[info objectForKey:@"objectVersion"] intValue];
    
      EOKeyGlobalID *gid;
      
      if (gidMiss == nil)
        gidMiss = [[NSMutableArray alloc] initWithCapacity:count];
      gid = [EOKeyGlobalID globalIDWithEntityName:@"Date"
                           keys:&pkeyNum keyCount:1
                           zone:NULL];
      [gidMiss addObject:gid];
  }
  
  if (gidMiss == nil) {
    if (debugOn) [self debugWithFormat:@"full cache hit !"];
    return result;
  }
  
  /* fill cache */
  
  if (debugOn) {
    [self debugWithFormat:@"need to fetch %i gids (cache misses)", 
            [gidMiss count]];
  }
  infos = [[self commandContext]
	         runCommand:@"appointment::get-by-globalid",
                   @"gids",       gidMiss,
                   @"attributes", attributes,
	         nil];
  if ((count = [infos count]) == 0)
    return result;

  for (i = 0; i < count; i++) {
    NSDictionary *info;
    
    info = [infos objectAtIndex:i];

    if ((!checkPermissions) ||
        ([self checkViewPermissionForApt:info])) {
      [result addObject:info];
    }
  }
  
  return result;
}
- (NSArray *)fetchCoreInfo {
  // returns: title, location, end/startdate, sensitivity
  return [self fetchCoreInfoForGIDs:[self fetchGIDs]];
}

/* generation */

- (int)refreshInterval {
  static int ref = -1;
  if (ref == -1) {
    ref = [[[NSUserDefaults standardUserDefaults] 
             objectForKey:@"ZLFolderRefresh"] intValue];
  }
  return ref > 0 ? ref : 300; /* every five minutes */
}
- (int)generationOfSet {
  /* 
     This is used by ZideLook to track folder changes.
     TODO: implement folder-change detection ... (snapshot of last
     id/version set contained in the folder)
  */
  return (time(NULL) - 1047000000) / [self refreshInterval];
}

/* set */

static int dateIdCompare(id date1, id date2, void *self){
  return [(NSNumber *)[(NSDictionary *)date1 objectForKey:@"pkey"] 
		      compare:[(NSDictionary *)date2 objectForKey:@"pkey"]];
}

- (NSString *)idsAndVersionsCSV {
  /*
    Returns a string in the format:
      (id:version\n)*

    TODO: should do:
      - ask cache manager whether it's time to check updates set
        - if not => cacheManager -idsAndVersionsCSV
      ..
  */
  NSMutableString *ms;
  NSArray  *gids, *dates;
  unsigned i, max;
  
  gids = [self fetchGIDs];
  if (gids == nil)       return nil;
  if ([gids count] == 0) return @"";
  
  dates = [self fetchDateIdAndObjectVersionForGIDs:gids];
  if (dates == nil) return nil;
  if ((max = [dates count]) == 0) return @"";
  
  /* sort dates to ensure set identity */
  dates = [dates sortedArrayUsingFunction:dateIdCompare context:self];
  
  if (debugOn)
    [self debugWithFormat:@"[ids and versions] processing %i apts", max];
  ms = [NSMutableString stringWithCapacity:(max * 10)];
  for (i = 0; i < max; i++) {
    NSDictionary *date;
    
    date = [dates objectAtIndex:i];
    [ms appendString:[[date objectForKey:@"dateId"] stringValue]];
    [ms appendString:@":"];
    [ms appendString:[[date objectForKey:@"objectVersion"] stringValue]];
    if (i != (max - 1)) /* TODO: check, not for the last ? */
      [ms appendString:@"\n"];
  }
  
  return ms;
}

@end /* SxAptSetHandler */
