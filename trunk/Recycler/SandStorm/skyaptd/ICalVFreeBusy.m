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

#include "ICalVFreeBusy.h"
#include "ICalFreeBusy.h"
#include "NSCalendarDate+ICal.h"
#include "common.h"

@implementation ICalVFreeBusy

- (id)initWithOrganizer:(id)_organizer
  timeRange:(NSCalendarDate *)_from:(NSCalendarDate *)_to
  timeStamp:(NSTimeInterval)_ts
  freeBusyProperties:(NSArray *)_fb
{
  if ((self = [super init])) {
    self->startDate     = [_from copy];
    self->endDate       = [_to   copy];
    self->timeStamp     = _ts;
    self->freeBusyProps = [_fb shallowCopy];

    if (_organizer) {
      _organizer = [[_organizer stringValue] lowercaseString];
      if (![_organizer isEqualToString:@"unknown"])
        self->organizer = RETAIN(_organizer);
    }
  }
  return self;
}
- (id)init {
  return [self initWithOrganizer:nil timeRange:nil:nil timeStamp:0.0
               freeBusyProperties:nil];
}

- (void)dealloc {
  RELEASE(self->rstatus);
  RELEASE(self->comments);
  RELEASE(self->attendees);
  RELEASE(self->url);
  RELEASE(self->uid);
  RELEASE(self->organizer);
  RELEASE(self->startDate);
  RELEASE(self->endDate);
  RELEASE(self->freeBusyProps);
  [super dealloc];
}

/* accessors */

- (NSString *)externalName {
  return @"VFREEBUSY";
}

- (NSArray *)subComponents {
  /* VFreeBusy has no subcomponents */
  return nil;
}

- (NSTimeInterval)timeStamp {
  return self->timeStamp;
}
- (NSCalendarDate *)timeStampAsDate {
  if (self->timeStamp <= 0.0) return nil;
  return [NSCalendarDate dateWithTimeIntervalSince1970:self->timeStamp];
}

- (NSCalendarDate *)startDate {
  return self->startDate;
}
- (NSCalendarDate *)endDate {
  return self->endDate;
}

- (id)organizer {
  return self->organizer;
}

- (NSArray *)freeBusyProperties {
  return self->freeBusyProps;
}

- (NSTimeZone *)timeZone {
  return nil;
}

/* description */

- (NSString *)icalStringForProperties {
  NSMutableString *ms;
  NSEnumerator    *e;
  ICalFreeBusy    *p;
  NSTimeZone      *tz;

  tz = [self timeZone];
  ms = [NSMutableString stringWithCapacity:64];
  
  if (self->organizer) {
    [ms appendString:@"ORGANIZER:"];
    [ms appendString:[self->organizer icalString]];
    [ms appendString:@"\r\n"];
  }
  else
    [ms appendString:@"ORGANIZER:Unknown\r\n"];
  
  if (self->timeStamp > 0.0) {
    [ms appendString:@"DTSTAMP:"];
    [ms appendString:[[self timeStampAsDate] icalStringWithTimeZone:tz]];
    [ms appendString:@"\r\n"];
  }

  if (self->startDate) {
    [ms appendString:@"DTSTART:"];
    [ms appendString:[self->startDate icalStringWithTimeZone:tz]];
    [ms appendString:@"\r\n"];
  }
  if (self->endDate) {
    [ms appendString:@"DTEND:"];
    [ms appendString:[self->endDate icalStringWithTimeZone:tz]];
    [ms appendString:@"\r\n"];
  }
  
  e = [self->freeBusyProps objectEnumerator];
  while ((p = [e nextObject])) {
    [ms appendString:@"FREEBUSY"];
    if ([p isFree])
      [ms appendString:@";FBTYPE=FREE"];
    else if ([p isBusy]) {
      if ([p isBusyUnavailable])
        [ms appendString:@";FBTYPE=BUSY-UNAVAILABLE"];
      else if ([p isBusyTentative])
        [ms appendString:@";FBTYPE=BUSY-TENTATIVE"];
    }
    [ms appendString:@":"];
    [ms appendString:[p icalString]];
    [ms appendString:@"\r\n"];
  }
  
  return ms;
}

@end /* ICalVFreeBusy */
