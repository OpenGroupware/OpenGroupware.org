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

#include <OGoFoundation/LSWEditorPage.h>

@interface SkyAptDeletePanel : LSWEditorPage
{
  BOOL     deleteAllCyclic;
  unsigned goBackWithCount;
}

@end

#include "common.h"
#include <OGoFoundation/OGoSession.h>
#include <OGoScheduler/SkyAptDataSource.h>
#include <OGoFoundation/LSWNotifications.h>

@implementation SkyAptDeletePanel

- (id)init {
  if ((self = [super init])) {
    self->goBackWithCount = 1;
  }
  return self;
}

/* activation */

- (BOOL)_prepareObject:(id)_object type:(NGMimeType *)_type {
  id         apt;
  EOGlobalID *gid;
    
  apt = _object;

  if ([[_type type] isEqualToString:@"eo-gid"]) {
    gid = apt;
    apt = nil;
      
    if (![[_type subType] isEqualToString:@"appointment"] &&
        ![[_type subType] isEqualToString:@"date"])
      return NO;
      
    apt = [self runCommand:@"appointment::get-by-globalid", @"gid", gid, nil];
      
    if (apt == nil)
      return NO;
      
    [self setObject:apt];
  }
  else
    gid = [apt globalID];

    /* check access */
  {
    NSString *perms;

    perms = [self runCommand:@"appointment::access", @"gid", gid, nil];
    
    if ([perms rangeOfString:@"d"].length == 0) {
      [self setErrorString:@"No permission to delete appointment !"];
      return NO;
    }
  }    
  NSAssert(apt, @"no appointment is set !");
  return YES;
}

- (BOOL)prepareForActivationCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  id tmp;
  
  tmp = [(id)[self session] getTransferObject];

  if ([tmp isKindOfClass:[EOGlobalID class]])
    return [self _prepareObject:tmp type:_type];
  
  if ([super prepareForActivationCommand:_command
             type:_type configuration:_cmdCfg]) {
    return [self _prepareObject:[self object] type:_type];
  }
  return NO;
}

/* accessors */

- (BOOL)isCyclic {
  return [[[self object] valueForKey:@"type"] isNotNull];
}

- (NSString *)deleteNotificationName {
  // TODO: this one is weird?!
  NSNotificationCenter *nc;

  nc = [NSNotificationCenter defaultCenter];
  
  [nc postNotificationName:SkyDeletedAppointmentNotification object:nil];
  
  return LSWDeletedAppointmentNotificationName;
}

/* accessors */

- (void)setGoBackWithCount:(unsigned)_goBackWithCount {
  self->goBackWithCount = _goBackWithCount;
}
- (unsigned)goBackWithCount {
  return self->goBackWithCount;
}

/* implementation */

- (id)deleteObject {
  id result;

  [self debugWithFormat:@"%s: called with %@", __PRETTY_FUNCTION__,
          [self object]];
  
  result = [self runCommand:
                 @"appointment::delete",
                 @"object",          [self object],
                 @"deleteAllCyclic",
                 [NSNumber numberWithBool:self->deleteAllCyclic],
                 @"reallyDelete",    [NSNumber numberWithBool:YES],
                 nil];
  return result;
}

/* actions */

- (id)delete {
  return [self deleteAndGoBackWithCount:self->goBackWithCount];
}
- (id)deleteAllCyclic {
  self->deleteAllCyclic = YES;
  return [self deleteAndGoBackWithCount:self->goBackWithCount];
}

@end /* SkyAptDeletePanel */
