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

#include "SkyPalmSelectableListing.h"

@interface SkyPalmAppointmentListing : SkyPalmSelectableListing
{
  NSArray *aptTypes;
}
@end /* SkyPalmSelectableListing */

#include "common.h"
#include <OGoScheduler/SkyAppointmentDocument.h>
#include <OGoFoundation/OGoSession.h>

// overwriting

@implementation SkyPalmAppointmentListing

- (void)dealloc {
  RELEASE(self->aptTypes);
  [super dealloc];
}

/* accessors */

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
  NSString *type;
  
  type = [(SkyAppointmentDocument *)[self appointment] type];
  
  if ([type length] == 0) return (NSString *)@"";
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
  if (self->aptTypes == nil)
    self->aptTypes = [[self configuredAptTypes] retain];
  return self->aptTypes;
}

- (id)_appointmentType {
  NSEnumerator *e;
  id           one;
  NSString     *wanted;
  
  e      = [[self aptTypes] objectEnumerator];
  wanted = [[self appointment] valueForKey:@"aptType"];
  
  while ((one = [e nextObject])) {
    NSString *key;
    
    key = [one valueForKey:@"type"];
    if ((![wanted length]) && [key isEqualToString:@"none"])
      return one;
    if ([wanted isEqualToString:key])
      return one;
  }
  return [NSDictionary dictionaryWithObjectsAndKeys:@"none", @"type", nil];
}

- (NSString *)aptTypeLabel {
  id       type;
  NSString *label;
  
  type = [self _appointmentType];
  if ((label = [type valueForKey:@"label"]) != nil)
    return label;
 
  label = [@"aptType_" stringByAppendingFormat:
              [[type valueForKey:@"type"] description]];
  return [[self labels] valueForKey:label];
}

@end /* SkyPalmAppointmentListing */
