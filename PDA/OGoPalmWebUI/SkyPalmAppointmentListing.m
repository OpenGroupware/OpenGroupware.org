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

#include "SkyPalmSelectableListing.h"

@interface SkyPalmAppointmentListing : SkyPalmSelectableListing
{
  NSArray *aptTypes;
}
@end /* SkyPalmSelectableListing */

#import <Foundation/Foundation.h>
#include <OGoScheduler/SkyAppointmentDocument.h>
#include <OGoFoundation/LSWSession.h>

// overwriting

@implementation SkyPalmAppointmentListing

- (id)init {
  if ((self = [super init])) {
    self->aptTypes = nil;
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->aptTypes);
  [super dealloc];
}
#endif

- (NSArray *)appointments {
  return [self list];
}

- (void)setAppointment:(id)_apt {
  [self setItem:_apt];
}
- (id)appointment {
  return [self item];
}

- (id)chooseAppointments {
  return [self selectItems];
}
- (id)chooseAppointment {
  return [self selectItem];
}

- (NSString *)repeatTypeString {
  NSString *type = [[self appointment] type];
  if (![type length]) return (NSString *)@"";
  if ([type isEqualToString:@"daily"])
    return [[self labels] valueForKey:@"label_repeatDaily"];
  if ([type isEqualToString:@"weekly"])
    return [[self labels] valueForKey:@"label_repeatWeekly"];
  if ([type isEqualToString:@"weekday"])
    return [[self labels] valueForKey:@"label_repeatSkyrixWeekday"];
  if ([type isEqualToString:@"14_daily"])
    return [[self labels] valueForKey:@"label_repeatSkyrix14Daily"];
  if ([type isEqualToString:@"monthly"])
    return [[self labels] valueForKey:@"label_repeatSkyrixMonthly"];
  if ([type isEqualToString:@"yearly"])
    return [[self labels] valueForKey:@"label_repeatYearly"];
  return type;
}

/* appointment types */

- (NSArray *)configuredAptTypes {
  NSArray *configured = nil;
  NSArray *custom     = nil;
  configured =
    [[[self session] userDefaults]
            objectForKey:@"SkyScheduler_defaultAppointmentTypes"];
  if (configured == nil) configured = [NSArray array];
  custom =
    [[[self session] userDefaults]
            objectForKey:@"SkyScheduler_customAppointmentTypes"];
  if (custom != nil)
    configured = [configured arrayByAddingObjectsFromArray:custom];
  return configured;
}
- (NSArray *)aptTypes {
  if (self->aptTypes == nil) {
    self->aptTypes = [self configuredAptTypes];
    RETAIN(self->aptTypes);
  }
  return self->aptTypes;
}

- (id)_appointmentType {
  NSEnumerator *e      = [[self aptTypes] objectEnumerator];
  id           one     = nil;
  NSString     *wanted = [[self appointment] valueForKey:@"aptType"];
  NSString     *key    = nil;
  while ((one = [e nextObject])) {
    key = [one valueForKey:@"type"];
    if ((![wanted length]) && [key isEqualToString:@"none"])
      return one;
    else if ([wanted isEqualToString:key])
      return one;
  }
  return [NSDictionary dictionaryWithObjectsAndKeys:@"none", @"type", nil];
}

- (NSString *)aptTypeLabel {
  id       type   = [self _appointmentType];
  NSString *label = [type valueForKey:@"label"];
 
  return (label != nil)
    ? label
    : [[self labels] valueForKey:
                     [NSString stringWithFormat:@"aptType_%@",
                               [type valueForKey:@"type"]]];
}

@end /* SkyPalmAppointmentListing */
