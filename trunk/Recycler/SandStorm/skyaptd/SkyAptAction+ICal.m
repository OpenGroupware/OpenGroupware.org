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

#include "SkyAptAction.h"
#include "ICalVEvent.h"
#include <LSFoundation/LSCommandContext.h>

#import <Foundation/Foundation.h>

@implementation SkyAptAction(ICal)
// supporting ical events
- (id)updateAppointmentsFromICalEvents:(NSArray *)_events {
  NSMutableDictionary *map;
  NSMutableArray      *skyrixIds;
  NSEnumerator        *e;
  id                  one;
  id                  dm;
  id                  gid;
  id                  event;

  map       = [NSMutableDictionary dictionaryWithCapacity:[_events count]];
  skyrixIds = [NSMutableArray arrayWithCapacity:[_events count]];
  e         = [_events objectEnumerator];
  dm        = [[self commandContext] documentManager];

  while ((event = [e nextObject])) {
    [map setObject:event forKey:[event uid]];
    gid = [dm globalIDForURL:[event uid]];
    if (gid == nil) {
      NSLog(@"WARNING[%s]: failed to get gid for url: %@",
            __PRETTY_FUNCTION__, [event uid]);
    }
    else
      [skyrixIds addObject:gid];
  }

  e = [[self _aptEOsForGIDs:skyrixIds] objectEnumerator];
  while ((one = [e nextObject])) {
    event = [dm urlForGlobalID:[one valueForKey:@"globalID"]];
    event = [map valueForKey:[event stringValue]];
    if (event == nil) {
      NSLog(@"WARNING[%s]: didn't find event for fetch appointment: %@",
            __PRETTY_FUNCTION__, one);
      continue;
    }
    [self updateAppointment:one fromICalEvent:event];
  }
  return [NSNumber numberWithBool:YES];
}
- (id)updateAppointmentFromICalEvent:(ICalVEvent *)_event {
  id _id     = [_event uid];
  id apt;
  if ((apt = [self _aptEOForId:_id]) == nil)
    return [self lastError];
  return [self updateAppointment:apt fromICalEvent:_event];
}
- (id)updateAppointment:(id)_apt
          fromICalEvent:(ICalVEvent *)_event
{
  NSString *perm;
  id       apt = _apt;
  id       tmp;
  BOOL     changed = NO;
  id       _id     = [_event uid];

  perm = [apt valueForKey:@"permissions"];

  NSLog(@"%s status: %@", __PRETTY_FUNCTION__, [_event status]);
  if ([[_event status] isEqualToString:@"CANCELLED"]) {
    if ([[apt valueForKey:@"participants"] count] > 1)
      return [self removeMeFromAppointmentAction:_id :nil];
    return [self deleteAppointmentAction:_id :nil :nil];
  }

  tmp = [apt valueForKey:@"permissions"];
  if ([tmp indexOfString:@"e"] == NSNotFound) {
    [self setLastError:@"PermissionDenied" errorCode:14
          description:@"Modification of this appointment not allowed!"];
    return [self lastError];
  }

  tmp = [_event startDate];
  [tmp setTimeZone:[[apt valueForKey:@"startDate"] timeZone]];
  if (![tmp isEqual:[apt valueForKey:@"startDate"]]) {
    [apt takeValue:tmp forKey:@"startDate"];
    changed = YES;
    NSLog(@"%s %@: startDate changed: %@",
          __PRETTY_FUNCTION__, _id, tmp);
  }
  tmp = [_event endDate];
  [tmp setTimeZone:[[apt valueForKey:@"endDate"] timeZone]];
  if (![tmp isEqual:[apt valueForKey:@"endDate"]]) {
    [apt takeValue:tmp forKey:@"endDate"];
    changed = YES;
    NSLog(@"%s %@: endDate changed: %@",
          __PRETTY_FUNCTION__, _id, tmp);
  }

  tmp = [_event summary];
  if ((([tmp length]) || ([[apt valueForKey:@"title"] length])) &&
      (![tmp isEqualToString:[apt valueForKey:@"title"]])) {
    [apt takeValue:tmp forKey:@"title"];
    changed = YES;
    NSLog(@"%s %@: title changed: %@",
          __PRETTY_FUNCTION__, _id, tmp);
  }

  tmp = [_event location];
  if ((([tmp length]) || ([[apt valueForKey:@"location"] length])) &&
      (![tmp isEqualToString:[apt valueForKey:@"location"]])) {
    [apt takeValue:tmp forKey:@"location"];
    changed = YES;
    NSLog(@"%s %@: location changed: %@",
          __PRETTY_FUNCTION__, _id, tmp);
  }
  tmp = [_event description];
  {
    NSString *comment = [apt valueForKey:@"comment"];

    if ([comment indexOfString:@"\r\n"] != NSNotFound)
      comment = [[comment componentsSeparatedByString:@"\r\n"]
                          componentsJoinedByString:@"\n"];
    
    if ((([tmp length]) || ([comment length])) &&
        (![tmp isEqualToString:comment])) {
      [apt takeValue:tmp forKey:@"comment"];
      changed = YES;
      NSLog(@"%s %@: comment changed: %@",
            __PRETTY_FUNCTION__, _id, tmp);
    }
  }

  if (changed) {
    return [self _updateAppointment:apt withContext:[self commandContext]];
  }

  NSLog(@"%s: appointment %@ didn't change", __PRETTY_FUNCTION__, _id);

  return [NSNumber numberWithBool:YES];
}

- (id)createAppointmentFromICalEvent:(ICalVEvent *)_event {
  return [self createAppointmentFromICalEvent:_event aptType:nil];
}
- (id)createAppointmentFromICalEvent:(ICalVEvent *)_event
                             aptType:(NSString *)_aptType
{
  NSTimeZone          *tz   = [self timeZone];
  id                  tmp;
  NSMutableDictionary *dict =
    [NSMutableDictionary dictionaryWithCapacity:5];

  [dict takeValue:[_event summary]  forKey:@"title"];
  [dict takeValue:[_event location] forKey:@"location"];

  if ([_aptType length])
    [dict takeValue:_aptType forKey:@"appointmentType"];
  
  tmp = [_event startDate];
  [tmp setTimeZone:tz];
  [dict setObject:tmp forKey:@"startDate"];

  tmp = [_event endDate];
  [tmp setTimeZone:tz];
  [dict setObject:tmp forKey:@"endDate"];

  tmp = [_event class];
  if (![tmp isEqualToString:@"PRIVATE"])
    [dict setObject:[NSNumber numberWithInt:10003] forKey:@"viewAccessTeam"];

  return [self createAppointmentAction:dict
               :nil // automatic active account
               :[NSArray array] // no resources
               :nil // no extra write access
               :nil // no repetition information
               :[_event description]];
}

@end /* SkyAptAction(ICal) */
