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
#include "ICalParser.h"
#include "NSString+ICal.h"
#include "NSCalendarDate+ICal.h"
#include "common.h"
#include <ical.h>

@implementation ICalVFreeBusy(Construction)

+ (id)constructWithComponentHandle:(icalcomponent *)_comp
  parser:(ICalParser *)_parser
{
  ICalVFreeBusy *vfb;
  NSTimeInterval ts = 0.0;
  NSCalendarDate *from = nil, *to  = nil;
  NSString       *org  = nil, *luid = nil;
  NSMutableArray *fb   = nil;
  NSTimeZone     *tz   = nil;
  NSURL          *lurl  = nil;
  icalproperty   *prop;
  
  /* process simple properties */
  
  if ((prop = icalcomponent_get_first_property(_comp,ICAL_ORGANIZER_PROPERTY)))
    org = [[NSString alloc] initWithICalValueOfProperty:prop];
  
  if ((prop = icalcomponent_get_first_property(_comp,ICAL_UID_PROPERTY)))
    luid = [[NSString alloc] initWithICalValueOfProperty:prop];
  
  if ((prop = icalcomponent_get_first_property(_comp,ICAL_URL_PROPERTY))) {
    NSString *s;
    
    if ((s = [[NSString alloc] initWithICalValueOfProperty:prop])) {
      lurl = [[NSURL URLWithString:s] retain];
      RELEASE(s);
    }
  }
  
  if ((prop = icalcomponent_get_first_property(_comp,ICAL_DTSTART_PROPERTY)))
    from = [[NSCalendarDate alloc] initWithICalValueOfProperty:prop];
  
  if ((prop = icalcomponent_get_first_property(_comp,ICAL_DTEND_PROPERTY)))
    to = [[NSCalendarDate alloc] initWithICalValueOfProperty:prop];
  else if ((prop =
            icalcomponent_get_first_property(_comp, ICAL_DURATION_PROPERTY))){
    if (from) {
      to = [from dateByApplyingICalDuration:icalproperty_get_duration(prop)];
    }
    else {
      NSLog(@"WARNING(%s): got a duration, but no startdate ...",
            __PRETTY_FUNCTION__);
    }
  }
  
  if ((prop = icalcomponent_get_first_property(_comp,ICAL_DTSTAMP_PROPERTY))) {
    NSCalendarDate *d;
    
    d = [[NSCalendarDate alloc] initWithICalValueOfProperty:prop];
    ts = [d timeIntervalSince1970];
    RELEASE(d);
  }
  
  /* process freebusy props */
  for (prop = icalcomponent_get_first_property(_comp, ICAL_FREEBUSY_PROPERTY);
       prop != NULL;
       prop = icalcomponent_get_next_property(_comp, ICAL_FREEBUSY_PROPERTY)){
    ICalFreeBusy   *fbp;
    NSCalendarDate *from, *to;
    struct icalperiodtype pt;
    icalparameter         *para;
    icalparameter_fbtype  fbtype;
    
    if (fb == nil) fb = [[NSMutableArray alloc] initWithCapacity:16];
    
    para = icalproperty_get_first_parameter(prop, ICAL_FBTYPE_PARAMETER);
    if (para)
      fbtype = icalparameter_get_fbtype(para);
    else
      fbtype = ICAL_FBTYPE_BUSY;
    
    pt = icalproperty_get_freebusy(prop);
    from = [[NSCalendarDate alloc] initWithICalTime:pt.start timeZone:tz];
    to   = [[NSCalendarDate alloc] initWithICalTime:pt.end   timeZone:tz];
    
    fbp = [[ICalFreeBusy alloc] initWithTimeRange:from:to fbType:fbtype];
    if (fbp) {
      [fb addObject:fbp];
      RELEASE(fbp);
    }
    
    RELEASE(from);
    RELEASE(to);
  }
  
  /* construct object */
  
  vfb = [[self alloc] initWithOrganizer:org
                      timeRange:from:to
                      timeStamp:ts
                      freeBusyProperties:fb];
  RELEASE(from);
  RELEASE(to);
  RELEASE(lurl);
  RELEASE(luid);
  RELEASE(org);
  RELEASE(fb);
  return vfb;
}

@end /* ICalVFreeBusy(Construction) */
