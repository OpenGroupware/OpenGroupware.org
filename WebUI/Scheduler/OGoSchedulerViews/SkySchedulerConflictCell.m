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

#include <OGoFoundation/OGoComponent.h>

@class NSString, NSArray, NSNumber;

@interface SkySchedulerConflictCell : OGoComponent
{
  id       appointment;
  id       conflict;
  NSString *type;
  NSArray  *participantIds;
  
  id       actual;
  id       item;
  NSNumber *flagCache;
  BOOL     showFullNames;
}

@end

#include "common.h"
#include "SkyAppointmentFormatter.h"
#include <OGoFoundation/OGoSession.h>

@implementation SkySchedulerConflictCell

- (id)init {
  if ((self = [super init])) {
    NSUserDefaults *ud;

    ud = [[self session] userDefaults];
    self->showFullNames =
      [ud boolForKey:@"scheduler_overview_full_names"];
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->appointment);
  RELEASE(self->conflict);
  RELEASE(self->type);
  RELEASE(self->participantIds);
  RELEASE(self->actual);
  RELEASE(self->item);
  RELEASE(self->flagCache);
  [super dealloc];
}

/* accessors */

- (void)setAppointment:(id)_apt {
  ASSIGN(self->appointment, _apt);
}
- (id)appointment {
  return self->appointment;
}

- (void)setConflict:(id)_conflict {
  ASSIGN(self->conflict,_conflict);
}
- (id)conflict {
  return self->conflict;
}

- (void)setType:(NSString *)_type {
  ASSIGN(self->type,_type);
  RELEASE(self->actual); self->actual = nil;
}
- (NSString *)type {
  return self->type;
}

- (void)setParticipantIds:(NSArray *)_ids {
  ASSIGN(self->participantIds,_ids);
}
- (NSArray *)participantIds {
  return self->participantIds;
}

- (id)actual {
  if (self->actual == nil) {
    if ([self->type hasSuffix:@"Appointment"])
      ASSIGN(self->actual, self->appointment);
    else if ([self->type hasSuffix:@"Conflict"])
      ASSIGN(self->actual, self->conflict);
  }
  return self->actual;
}

- (void)setItem:(id)_item {
  ASSIGN(self->item,_item);
  RELEASE(self->flagCache); self->flagCache = nil;
}
- (id)item {
  return self->item;
}

/* additional accessors */

- (NSString *)participant {
  id label = nil;
  
  if ([[self->item valueForKey:@"isTeam"] boolValue]) {
    label = [self->item valueForKey:@"description"];
  }
  else if ([[self->item valueForKey:@"isAccount"] boolValue]) {
    label = [self->item valueForKey:@"login"];
  }
  else {
    label = [self->item valueForKey:@"name"];
  }

  if (![label isNotNull])
    label = @"*";

  return label;
}

- (NSArray *)resources {
  NSString *resourceNames;
  resourceNames = [[self actual] valueForKey:@"resourceNames"];

  if (![resourceNames isNotNull])
    return [NSArray array];

  return [resourceNames componentsSeparatedByString:@", "];
}

/* conditional */

- (BOOL)doesPartConflict:(id)_part {
  NSNumber *pid;

  pid = [_part valueForKey:@"companyId"];
  return ([self->participantIds containsObject:pid])
    ? YES : NO;
}
- (BOOL)doesAnyParticipantConflict {
  NSEnumerator *e = [[[self actual] valueForKey:@"participant"]
                            objectEnumerator];
  id           one;

  while ((one = [e nextObject])) {
    if ([self doesPartConflict:one]) return YES;
  }
  return NO;
}


- (BOOL)doesResourceConflict:(id)_res {
  NSArray *resources;

  resources = [[self->appointment valueForKey:@"resourceNames"]
                                  componentsSeparatedByString:@", "];
  return ([resources containsObject:_res])
    ? YES : NO;
}
- (BOOL)doesAnyResourceConflict {
  NSEnumerator *e;
  NSArray      *all;
  id           one;

  e   = [[self resources] objectEnumerator];
  all = [[self->appointment valueForKey:@"resourceNames"]
                            componentsSeparatedByString:@", "];
  
  while ((one = [e nextObject])) {
    if ([all containsObject:one]) return YES;
  }
  return NO;
}

- (BOOL)isParticipantConflicting {
  if (self->flagCache == nil) {
    NSNumber *flag;
    flag = [NSNumber numberWithBool:
                     [self doesPartConflict:self->item]];
    ASSIGN(self->flagCache,flag);
  }
  return [self->flagCache boolValue];
}
- (BOOL)isResourceConflicting {
  if (self->flagCache == nil) {
    NSNumber *flag;
    flag = [NSNumber numberWithBool:
                     [self doesResourceConflict:self->item]];
    ASSIGN(self->flagCache,flag);
  }
  return [self->flagCache boolValue];
}

- (BOOL)showParticipantsCell {
  if ([[self type] hasSuffix:@"Conflict"]) return YES;
  return NO;
}
- (BOOL)showResourceCell {
  if ([[self type] hasSuffix:@"Conflict"]) return YES;
  return NO;
}

- (BOOL)listResources {
  if ([[self type] hasSuffix:@"Appointment"]) return YES;
  return NO;
}
- (BOOL)listParticipants {
  if ([[self type] hasSuffix:@"Appointment"]) return YES;
  return NO;
}

/* formatting */

- (SkyAppointmentFormatter *)participantFormatter {
  SkyAppointmentFormatter *f;
  f = [SkyAppointmentFormatter formatterWithFormat:@"%P"];
  [f setShowFullNames:self->showFullNames];
  return f;
}
- (SkyAppointmentFormatter *)resourceFormatter {
  return [SkyAppointmentFormatter formatterWithFormat:@"%R"];
}


@end
