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
#include "ICalParser.h"
#include "NSString+ICal.h"
#include "NSCalendarDate+ICal.h"
#include "common.h"
#include <ical.h>

@implementation ICalVEvent(Construction)

- (id)initWithComponentHandle:(icalcomponent *)_comp
  parser:(ICalParser *)_parser
{
  NSMutableArray *ma;
  id             tmp;
  icalproperty   *prop;

  if (!(self = [self init]))
    return self;
  
  if ((prop = icalcomponent_get_first_property(_comp,ICAL_UID_PROPERTY)))
    self->uid = [[NSString alloc] initWithICalValueOfProperty:prop];
  if ((prop = icalcomponent_get_first_property(_comp,ICAL_URL_PROPERTY))) {
    if ((tmp = [[NSString alloc] initWithICalValueOfProperty:prop]) != nil) {
      self->url = [[NSURL alloc] initWithString:tmp];
      RELEASE(tmp);
    }
  }

  if ((prop = icalcomponent_get_first_property(_comp,ICAL_CREATED_PROPERTY)))
    self->created = [[NSCalendarDate alloc] initWithICalValueOfProperty:prop];
  if ((prop=icalcomponent_get_first_property(_comp,ICAL_LASTMODIFIED_PROPERTY)))
    self->lastModified =
      [[NSCalendarDate alloc] initWithICalValueOfProperty:prop];
  if ((prop = icalcomponent_get_first_property(_comp,ICAL_DTSTART_PROPERTY)))
    self->startDate= [[NSCalendarDate alloc] initWithICalValueOfProperty:prop];
  if ((prop = icalcomponent_get_first_property(_comp,ICAL_DTEND_PROPERTY)))
    self->endDate = [[NSCalendarDate alloc] initWithICalValueOfProperty:prop];
  if ((prop = icalcomponent_get_first_property(_comp,ICAL_DTSTAMP_PROPERTY))) {
    tmp = [[NSCalendarDate alloc] initWithICalValueOfProperty:prop];
    self->timeStamp = [tmp timeIntervalSince1970];
    RELEASE(tmp);
  }
  
  if ((prop=icalcomponent_get_first_property(_comp,ICAL_DESCRIPTION_PROPERTY)))
    {
      NSArray        *parts;
      NSEnumerator   *e;
      NSMutableArray *ma;
      
      tmp = [[NSString alloc] initWithICalValueOfProperty:prop];
      if ([tmp indexOfString:@"\\\\"] != NSNotFound) 
        parts = [tmp componentsSeparatedByString:@"\\\\"];
      else
        parts = [NSArray arrayWithObject:tmp];

      e  = [parts objectEnumerator];
      ma = [NSMutableArray array];

      while ((tmp = [e nextObject])) {
        if ([tmp indexOfString:@"\\n"] != NSNotFound) {
          tmp = [[tmp componentsSeparatedByString:@"\\n"]
                      componentsJoinedByString:@"\n"];
        }
        [ma addObject:tmp];
      }
      tmp = [ma componentsJoinedByString:@"\\"];
      self->description = [tmp copy];
    }
  if ((prop = icalcomponent_get_first_property(_comp,ICAL_GEO_PROPERTY)))
    self->geo = [[NSString alloc] initWithICalValueOfProperty:prop];
  if ((prop = icalcomponent_get_first_property(_comp,ICAL_LOCATION_PROPERTY)))
    self->location = [[NSString alloc] initWithICalValueOfProperty:prop];
  if ((prop = icalcomponent_get_first_property(_comp,ICAL_ORGANIZER_PROPERTY)))
    self->organizer = [[NSString alloc] initWithICalValueOfProperty:prop];
  if ((prop = icalcomponent_get_first_property(_comp,ICAL_PRIORITY_PROPERTY))){
    tmp = [[NSString alloc] initWithICalValueOfProperty:prop];
    self->priority = [[NSNumber alloc] initWithInt:[tmp intValue]];
  }
  if ((prop = icalcomponent_get_first_property(_comp,ICAL_SEQUENCE_PROPERTY))){
    tmp = [[NSString alloc] initWithICalValueOfProperty:prop];
    self->sequenze = [[NSNumber alloc] initWithInt:[tmp intValue]];
  }
  if ((prop = icalcomponent_get_first_property(_comp,ICAL_STATUS_PROPERTY)))
    self->status = [[NSString alloc] initWithICalValueOfProperty:prop];
  if ((prop = icalcomponent_get_first_property(_comp,ICAL_SUMMARY_PROPERTY)))
    self->summary = [[NSString alloc] initWithICalValueOfProperty:prop];
  if ((prop = icalcomponent_get_first_property(_comp,ICAL_TRANSP_PROPERTY)))
    self->transp = [[NSString alloc] initWithICalValueOfProperty:prop];

  // attendees
  ma = [NSMutableArray array];
  for (prop = icalcomponent_get_first_property(_comp, ICAL_ATTENDEE_PROPERTY);
       prop != NULL;
       prop = icalcomponent_get_next_property(_comp, ICAL_ATTENDEE_PROPERTY)){
    tmp = [[NSString alloc] initWithICalValueOfProperty:prop];
    if ([tmp length]) [ma addObject:tmp];
    RELEASE(tmp);
  }
  if ([ma count]) self->attendees = [ma copy];

  // categories
  ma = [NSMutableArray array];
  for (prop =icalcomponent_get_first_property(_comp, ICAL_CATEGORIES_PROPERTY);
       prop != NULL;
       prop =icalcomponent_get_next_property(_comp, ICAL_CATEGORIES_PROPERTY)){
    tmp = [[NSString alloc] initWithICalValueOfProperty:prop];
    if ([tmp length]) [ma addObject:tmp];
    RELEASE(tmp);
  }
  if ([ma count]) self->categories = [ma copy];

  // comments
  ma = [NSMutableArray array];
  for (prop = icalcomponent_get_first_property(_comp, ICAL_COMMENT_PROPERTY);
       prop != NULL;
       prop = icalcomponent_get_next_property(_comp, ICAL_COMMENT_PROPERTY)){
    tmp = [[NSString alloc] initWithICalValueOfProperty:prop];
    if ([tmp length]) [ma addObject:tmp];
    RELEASE(tmp);
  }
  if ([ma count]) self->comments = [ma copy];

  // contacts
  ma = [NSMutableArray array];
  for (prop = icalcomponent_get_first_property(_comp, ICAL_CONTACT_PROPERTY);
       prop != NULL;
       prop = icalcomponent_get_next_property(_comp, ICAL_CONTACT_PROPERTY)){
    tmp = [[NSString alloc] initWithICalValueOfProperty:prop];
    if ([tmp length]) [ma addObject:tmp];
    RELEASE(tmp);
  }
  if ([ma count]) self->contacts = [ma copy];

  // resources
  ma = [NSMutableArray array];
  for (prop = icalcomponent_get_first_property(_comp, ICAL_RESOURCES_PROPERTY);
       prop != NULL;
       prop = icalcomponent_get_next_property(_comp, ICAL_RESOURCES_PROPERTY)){
    tmp = [[NSString alloc] initWithICalValueOfProperty:prop];
    if ([tmp length]) [ma addObject:tmp];
    RELEASE(tmp);
  }
  if ([ma count]) self->resources = [ma copy];

  return self;
}

+ (id)constructWithComponentHandle:(icalcomponent *)_comp
  parser:(ICalParser *)_parser
{
  ICalVEvent *event =
    [[ICalVEvent alloc] initWithComponentHandle:_comp parser:_parser];
  return event;
}

@end /* ICalVEvent(Construction) */
