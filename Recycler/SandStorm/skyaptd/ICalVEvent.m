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

#include "ICalVEvent.h"

#include "NSCalendarDate+ICal.h"
#include "NSString+ICal.h"
#include "common.h"

@implementation ICalVEvent

- (id)init {
  if ((self = [super init])) {
    self->uid   = nil;
    self->url   = nil;
    self->class = nil;

    self->created = self->lastModified = self->startDate = self->endDate = nil;
    self->timeStamp = 0.0;

    self->description = self->geo = self->location = self->organizer = nil;
    self->priority = self->sequenze = nil;
    self->status = self->summary = self->transp = nil;

    self->attendees = self->categories = self->comments =
      self->contacts = self->resources = nil;
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->uid);
  RELEASE(self->url);
  RELEASE(self->class);

  RELEASE(self->created);
  RELEASE(self->lastModified);
  RELEASE(self->startDate);
  RELEASE(self->endDate);

  RELEASE(self->description);
  RELEASE(self->geo);
  RELEASE(self->location);
  RELEASE(self->organizer);
  RELEASE(self->priority);
  RELEASE(self->sequenze);
  RELEASE(self->status);
  RELEASE(self->summary);
  RELEASE(self->transp);

  RELEASE(self->attendees);
  RELEASE(self->categories);
  RELEASE(self->comments);
  RELEASE(self->contacts);
  RELEASE(self->resources);
  [super dealloc];
}

/* accessors */

- (NSString *)externalName {
  return @"VEVENT";
}

- (NSArray *)subComponents {
  /* VFreeBusy has no subcomponents */
  return nil;
}


- (NSString *)uid   { return self->uid; }
- (NSURL *)url      { return self->url; }
- (NSString *)class { return self->class; }

- (NSCalendarDate *)created      { return self->created; }
- (NSCalendarDate *)lastModified { return self->lastModified; }
- (NSCalendarDate *)startDate    { return self->startDate; }
- (NSCalendarDate *)endDate      { return self->endDate; }
- (NSTimeInterval)timeStamp      { return self->timeStamp; }
- (NSCalendarDate *)timeStampAsDate {
  if (self->timeStamp <= 0.0) return nil;
  return [NSCalendarDate dateWithTimeIntervalSince1970:self->timeStamp];
}

- (NSString *)description { return self->description; }
- (NSString *)geo      { return self->geo; }
- (NSString *)location { return self->location; }
- (id)organizer        { return self->organizer; }
- (NSNumber *)priority { return self->priority; }
- (NSNumber *)sequenze { return self->sequenze; }
- (NSString *)status   { return self->status; }
- (NSString *)summary  { return self->summary; }
- (NSString *)transp   { return self->transp; }

- (NSArray *)attendees  { return self->attendees; }
- (NSArray *)categories { return self->categories; }
- (NSArray *)comments   { return self->comments; }
- (NSArray *)contacts   { return self->contacts; }
- (NSArray *)resources  { return self->resources; }

@end /* ICalVEvent */
