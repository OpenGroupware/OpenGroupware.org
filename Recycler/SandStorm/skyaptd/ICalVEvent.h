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

#ifndef __ICal2_ICalVEvent_H__
#define __ICal2_ICalVEvent_H__

#include <ICalComponent.h>
#include <ical.h>

@class NSString, NSArray, NSURL, NSCalendarDate, NSNumber;

@interface ICalVEvent : ICalComponent
{
  NSString *uid;
  NSURL    *url;
  NSString *class;

  NSCalendarDate *created;
  NSCalendarDate *lastModified;
  NSCalendarDate *startDate;
  NSCalendarDate *endDate;
  NSTimeInterval timeStamp;

  NSString       *description;
  NSString       *geo;
  NSString       *location;
  id             organizer;
  NSNumber       *priority;
  NSNumber       *sequenze;
  NSString       *status;
  NSString       *summary;
  NSString       *transp;

  NSArray        *attendees;  // strings
  NSArray        *categories; // strings
  NSArray        *comments;   // strings
  NSArray        *contacts;   // strings
  NSArray        *resources;  // strings
  
  /*
    recurrenceId, duration
    attach, exdate, exrule, rstatus, related, rdate, rrule, x-prop
   */
}

/* accessors */
- (NSString *)uid;
- (NSURL *)url;
- (NSString *)class;

- (NSCalendarDate *)created;
- (NSCalendarDate *)lastModified;
- (NSCalendarDate *)startDate;
- (NSCalendarDate *)endDate;
- (NSTimeInterval)timeStamp;
- (NSCalendarDate *)timeStampAsDate;

- (NSString *)description;
- (NSString *)geo;
- (NSString *)location;
- (id)organizer;
- (NSNumber *)priority;
- (NSNumber *)sequenze;
- (NSString *)status;
- (NSString *)summary;
- (NSString *)transp; // TRANSPARENT / OPAQUE

- (NSArray *)attendees;
- (NSArray *)categories;
- (NSArray *)comments;
- (NSArray *)contacts;
- (NSArray *)resources;

@end /* ICalVEvent */

#endif /* __ICal2_ICalVEvent_H__ */
