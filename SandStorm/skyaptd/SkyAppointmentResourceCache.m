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

#include "SkyAppointmentResourceCache.h"

#import <Foundation/Foundation.h>
#include <LSFoundation/LSFoundation.h>
#include <EOControl/EOKeyGlobalID.h>

// 30 minutes
#define SKYAPTRESCACHE_UPDATE_TIMEOUT 1800

@interface SkyAppointmentResourceCache(PrivateInit)
- (id)initWithContext:(LSCommandContext *)_context;
- (void)_initialFetchWithContext:(id)_context;
@end /* SkyAppointmentResourceCache(PrivateInit) */

@interface SkyAppointmentResourceCache(PrivateMethods)
- (NSDictionary *)_asDBDict:(NSDictionary *)_dict;
- (NSDictionary *)_buildDict:(id)_vals withContext:(id)_context;
- (void)_updateCacheWithContext:(id)_context;
- (void)_fetchObjectsWithContext:(id)_context;
@end /* SkyAppointmentResourceCache(PrivateMethods) */

@implementation SkyAppointmentResourceCache

- (id)init {
  if ((self = [super init])) {
    self->map           = [[NSMutableDictionary alloc] initWithCapacity:16];
    self->removed       = [[NSMutableArray alloc] initWithCapacity:8];
    self->changed       = [[NSMutableArray alloc] initWithCapacity:8];
    self->fetchDate     = nil;
    self->updateTimeout = SKYAPTRESCACHE_UPDATE_TIMEOUT;
  }
  return self;
}

- (id)initWithContext:(LSCommandContext *)_context {
  if ((self = [self init])) {
    [self _initialFetchWithContext:_context];
  }
  return self;
}

- (void)dealloc {
  if (([self->removed count]) || ([self->changed count])) {
    NSLog(@"WARNING[%s]: deallocating with unsaved changes ("
          @"%i removed, %i changed)", __PRETTY_FUNCTION__,
          [self->removed count], [self->changed count]);
  }
  RELEASE(self->map);
  RELEASE(self->removed);
  RELEASE(self->changed);
  RELEASE(self->fetchDate);
  [super dealloc];
}

- (void)_initialFetchWithContext:(id)_context {
  NSLog(@"%s initial fetch", __PRETTY_FUNCTION__);
  [self _fetchObjectsWithContext:_context];
}

static SkyAppointmentResourceCache *defaultCache = nil;
+ (SkyAppointmentResourceCache *)cacheWithCommandContext:(id)_context
{
  if ((defaultCache == nil)) {
    defaultCache =
      [[SkyAppointmentResourceCache alloc] initWithContext:_context];
  }

  return defaultCache;
}

- (void)checkUpdateWithContext:(id)_context {
  if ((self->fetchDate == nil) ||
      ([self->fetchDate timeIntervalSinceNow] < -self->updateTimeout)) {
    [self _updateCacheWithContext:_context];
  }
}
- (void)flushWithContext:(id)_context {
  [self _updateCacheWithContext:_context];
}


- (NSArray *)allObjectsWithContext:(id)_context {
  [self checkUpdateWithContext:_context];
  return [self->map allValues];
}
- (NSArray *)allCategoriesWithContext:(id)_context {
  NSMutableArray *cats = [NSMutableArray array];
  NSEnumerator   *e    = [[self allObjectsWithContext:_context]
                                objectEnumerator];
  id             one;

  while ((one = [e nextObject])) {
    one = [one valueForKey:@"category"];
    if (([one length]) && (![cats containsObject:one])) [cats addObject:one];
  }
  one = [cats copy];
  return AUTORELEASE(one);
}
- (BOOL)insertAppointmentResource:(NSString *)_name
                         category:(NSString *)_category
                            email:(NSString *)_email
                     emailSubject:(NSString *)_emailSubject
                 notificationTime:(NSNumber *)_number
                          context:(id)_context
{
  id dict = [NSMutableDictionary dictionaryWithCapacity:5];
  id result;

  [self checkUpdateWithContext:_context];

  if (![_name length]) {
    NSLog(@"ERROR[%s]: cannot create appointmentresource with empty name",
          __PRETTY_FUNCTION__);
    return NO;
  }
  [dict setObject:_name forKey:@"name"];
  if ([_category length]) [dict setObject:_category forKey:@"category"];
  if ([_email length])    [dict setObject:_email    forKey:@"email"];
  if ([_emailSubject length]) [dict setObject:_emailSubject
                                    forKey:@"emailSubject"];
  if ([_number intValue] > 0) [dict setObject:_number
                                    forKey:@"notificationTime"];

  result = [_context runCommand:@"appointmentresource::new" arguments:dict];
  if (result == nil) {
    NSLog(@"ERROR[%s]: failed to create appointmentresource: %@",
          __PRETTY_FUNCTION__, dict);
    return NO;
  }
  else {
    id pKey = [result valueForKey:@"appointmentResourceId"];
    [self->map setObject:[self _buildDict:result withContext:_context]
         forKey:pKey];
  }
  return YES;
}

- (BOOL)updateAppointmentResource:(EOGlobalID *)_gid
                         category:(NSString *)_category
                            email:(NSString *)_email
                     emailSubject:(NSString *)_emailSubject
                 notificationTime:(NSNumber *)_number
                          context:(id)_context
{
  id pKey = nil;
  id old  = nil;
  id dict = nil;

  [self checkUpdateWithContext:_context];

  pKey = [(EOKeyGlobalID *)_gid keyValues][0];
  old  = [self->map valueForKey:pKey];

  if (old == nil) {
    NSLog(@"ERROR[%s]: couldn not update unknown appointmentresource: %@",
          __PRETTY_FUNCTION__, _gid);
    return NO;
  }

  dict = [old mutableCopy];
  
  if ([_category length]) [dict setObject:_category forKey:@"category"];
  else [dict removeObjectForKey:@"category"];

  if ([_email length]) [dict setObject:_email forKey:@"email"];
  else [dict removeObjectForKey:@"email"];

  if ([_emailSubject length]) [dict setObject:_emailSubject
                                    forKey:@"emailSubject"];
  else [dict removeObjectForKey:@"emailSubject"];

  if ([_number intValue] > 0) [dict setObject:_number
                                    forKey:@"notificationTime"];
  else [dict removeObjectForKey:@"notificationTime"];

  old = [dict copy];
  RELEASE(dict);
  [self->map setObject:old forKey:pKey];
  [self->changed addObject:pKey];
  RELEASE(old);
  return YES;
}
- (BOOL)deleteAppointmentResource:(EOGlobalID *)_gid
                          context:(id)_context
{
  id pKey;
  id old, dict;

  [self checkUpdateWithContext:_context];
  pKey = [(EOKeyGlobalID *)_gid keyValues][0];
  old  = [self->map valueForKey:pKey];

  if (old == nil) {
    NSLog(@"ERROR[%s]: cannot delete unknown appointmentresource: %@",
          __PRETTY_FUNCTION__, _gid);
    return NO;
  }
  
  dict = [self _asDBDict:old];
  [dict takeValue:_gid forKey:@"globalID"];
  [self->removed addObject:dict];
  [self->map removeObjectForKey:pKey];
  return YES;
}

@end /* SkyAppointmentResourceCache */

@implementation SkyAppointmentResourceCache(PrivateMethods)

- (NSDictionary *)_buildDict:(id)_vals withContext:(id)_context {
  NSMutableDictionary *md = [NSMutableDictionary dictionaryWithCapacity:6];
  id                  tmp;

  tmp = [_vals valueForKey:@"name"];
  if (tmp != nil) [md setObject:tmp forKey:@"name"];
  tmp = [_vals valueForKey:@"category"];
  if (tmp != nil) [md setObject:tmp forKey:@"category"];
  tmp = [_vals valueForKey:@"email"];
  if (tmp != nil) [md setObject:tmp forKey:@"email"];
  tmp = [_vals valueForKey:@"emailSubject"];
  if (tmp != nil) [md setObject:tmp forKey:@"emailSubject"];
  tmp = [_vals valueForKey:@"notificationTime"];
  if (tmp != nil) [md setObject:tmp forKey:@"notificationTime"];

  tmp = [_vals valueForKey:@"globalID"];
  tmp = [[_context documentManager] urlForGlobalID:tmp];
  if (tmp != nil) [md setObject:tmp forKey:@"id"];
  else {
    NSLog(@"WARNING[%s]: failed to create url for appointmentresource: %@",
          __PRETTY_FUNCTION__, _vals);
  }

  tmp = [md copy];
  return AUTORELEASE(tmp);
}

- (void)_fetchObjectsWithContext:(id)_context {
  NSArray      *all;
  NSEnumerator *e;
  id           one;
  id           pKey;
  
  [self->map removeAllObjects];

  all = [_context runCommand:
                  @"appointmentresource::get",
                  @"returnType",
                  [NSNumber numberWithInt:LSDBReturnType_ManyObjects],
                  nil];
  e   = [all objectEnumerator];
  while ((one = [e nextObject])) {
    pKey = [one valueForKey:@"appointmentResourceId"];
    [self->map setObject:[self _buildDict:one withContext:_context]
         forKey:pKey];
  }

  RELEASE(self->fetchDate);
  self->fetchDate = [[NSDate date] copy];
}

- (EOKeyGlobalID *)_gidForPrimaryKey:(NSNumber *)_pKey {
  id keys[1];
  keys[0] = _pKey;
  return [EOKeyGlobalID globalIDWithEntityName:@"AppointmentResource"
                        keys:keys keyCount:1 zone:NULL];
}

- (NSDictionary *)_asDBDict:(NSDictionary *)_dict {
  id dict = [_dict mutableCopy];
  return AUTORELEASE(dict);
}
- (void)_updateCacheWithContext:(id)_context {
  NSEnumerator *e;
  id           one;

  NSLog(@"%s updating cache", __PRETTY_FUNCTION__);

  e = [self->removed objectEnumerator];
  while ((one = [e nextObject])) {
    [_context runCommand:@"appointmentresource::delete" arguments:one];
  }
  [self->removed removeAllObjects];

  e = [self->changed objectEnumerator];
  while ((one = [e nextObject])) {
    id gid = [self _gidForPrimaryKey:one];
    one    = [self->map valueForKey:one];
    one    = [self _asDBDict:one];
    if (one != nil) {
      [one takeValue:gid forKey:@"globalID"];
      [_context runCommand:@"appointmentresource::set" arguments:one];
    }
  }
  [self->changed removeAllObjects];

  [self _fetchObjectsWithContext:_context];
}

@end /* SkyAppointmentResourceCache(PrivateMethods) */
