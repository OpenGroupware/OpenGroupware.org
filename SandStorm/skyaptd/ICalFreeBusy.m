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

#include "ICalFreeBusy.h"
#include "NSCalendarDate+ICal.h"
#include "common.h"

@implementation ICalFreeBusy

- (id)initWithTimeRange:(NSCalendarDate *)_from:(NSCalendarDate *)_to
  fbType:(ICalFreeBusyType)_fbtype
{
  if ((self = [super init])) {
    if (_from == nil || _to == nil) {
      RELEASE(self);
      return nil;
    }

    self->fbType    = _fbtype == 0 ? ICAL_FBTYPE_BUSY : _fbtype;
    self->startDate = [_from copy];
    self->endDate   = [_to   copy];
  }
  return self;
}
- (id)init {
  return [self initWithTimeRange:nil:nil fbType:0];
}

- (void)dealloc {
  RELEASE(self->startDate);
  RELEASE(self->endDate);
  [super dealloc];
}

/* accessors */

- (NSString *)externalName {
  return @"FREEBUSY";
}

/* parameters */

- (BOOL)isFree {
  return self->fbType == ICAL_FBTYPE_FREE;
}
- (BOOL)isBusy {
  return
    self->fbType == ICAL_FBTYPE_BUSY ||
    self->fbType == ICAL_FBTYPE_BUSYUNAVAILABLE ||
    self->fbType == ICAL_FBTYPE_BUSYTENTATIVE;
}
- (BOOL)isBusyUnavailable {
  return self->fbType == ICAL_FBTYPE_BUSYUNAVAILABLE;
}
- (BOOL)isBusyTentative {
  return self->fbType == ICAL_FBTYPE_BUSYTENTATIVE;
}

/* value */

- (NSCalendarDate *)startDate {
  return self->startDate;
}
- (NSCalendarDate *)endDate {
  return self->endDate;
}

/* comparing */

- (int)compare:(id)_other {
  return [self->startDate compare:[_other startDate]];
}

/* description */

- (NSString *)icalStringWithTimeZone:(NSTimeZone *)_tz {
  NSMutableString *ms;
  
  ms = [NSMutableString stringWithCapacity:32];
  [ms appendString:[self->startDate icalStringWithTimeZone:_tz]];
  [ms appendString:@"/"];
  [ms appendString:[self->endDate icalStringWithTimeZone:_tz]];
  return ms;
}

@end /* ICalFreeBusy */
