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

#include "ICalVCalendar.h"
#include "ICalParser+Privates.h"
#include "NSString+ICal.h"
#include "common.h"
#include <ical.h>

@implementation ICalVCalendar(Construction)

+ (id)constructWithComponentHandle:(icalcomponent *)_comp
  parser:(ICalParser *)_parser
{
  ICalVCalendar *cal;
  NSString *pid = nil;
  int mav = -1, miv = -1;
  icalproperty_method m = 0;
  icalproperty *prop;
  
  NSAssert(icalcomponent_isa(_comp) == ICAL_VCALENDAR_COMPONENT,
           @"got component of invalid kind ...");

  if ((prop = icalcomponent_get_first_property(_comp, ICAL_METHOD_PROPERTY)))
    m = icalproperty_get_method(prop);
  
  if ((prop = icalcomponent_get_first_property(_comp, ICAL_PRODID_PROPERTY)))
    pid = [[NSString alloc] initWithICalValueOfProperty:prop];
  
  if ((prop = icalcomponent_get_first_property(_comp, ICAL_VERSION_PROPERTY))){
    const char *v;
    
    if ((v = icalproperty_get_version(prop))) {
      char buf[strlen(v) + 10];
      char *p;
      
      strcpy(buf, v);
      
      if ((p = index(buf, '.'))) {
        *p = '\0';
        mav = atoi(buf);
        miv = atoi(p + 1);
      }
      else
        mav = atoi(v);
    }
    else {
      NSLog(@"%s: got version property, but no value ???",
            __PRETTY_FUNCTION__);
    }
  }
  
  cal = [[self alloc] initWithMethod:m
                      productId:pid version:mav:miv
                      subComponents:[_parser _makeSubComponents:_comp]];
  
  RELEASE(pid);
  
  return cal;
}

@end /* ICalVCalendar(Construction) */
