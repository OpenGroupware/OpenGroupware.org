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

#include "SkyAptAction.h"
#import <Foundation/Foundation.h>
#include <LSFoundation/LSFoundation.h>
#include <NGExtensions/NGExtensions.h>

@implementation SkyAptAction(AppointmentBindings)

static NSString *_personName(id self, id _person) {
  NSMutableString *str   = nil;

  str = [NSMutableString stringWithCapacity:64];    

  if (_person != nil) {
    id n = [_person valueForKey:@"name"];
    id f = [_person valueForKey:@"firstname"];

    if (f != nil) {
      [str appendString:f];
       [str appendString:@" "];
    }
    if (n != nil) {
      [str appendString:n];
    }
  }
  return str;
}

static NSDictionary *_bindingForAppointment(id self, id obj) {
  NSMutableDictionary *bindings = nil;
  id                  c         = nil;
  NSString            *title    = nil;
  NSString            *location = nil;
  NSString            *resNames = nil;
  NSString            *format   = nil;
  NSCalendarDate      *sd       = nil;
  NSCalendarDate      *ed       = nil;

  format = [[[self commandContext] valueForKey:LSUserDefaultsKey]
                   stringForKey:@"scheduler_mail_template_date_format"];
  sd = [obj valueForKey:@"startDate"];
  if (format != nil && sd != nil && ![sd isNotNull] == NO) {
    [sd setCalendarFormat:format];
  }
  ed = [obj valueForKey:@"endDate"];
  if (format != nil && ed != nil && ![ed isNotNull] == NO) {
    [ed setCalendarFormat:format];
  }

  bindings = [[NSMutableDictionary alloc] initWithCapacity:8];
  [bindings setObject:sd forKey:@"startDate"];
  [bindings setObject:ed forKey:@"endDate"];
  
  if ((title = [obj valueForKey:@"title"]))
    [bindings setObject:title forKey:@"title"];
  if ((location = [obj valueForKey:@"location"]))
    [bindings setObject:location forKey:@"location"];
  if ((resNames = [obj valueForKey:@"location"]))
    [bindings setObject:resNames forKey:@"resourceNames"];        

  if ((c = [obj valueForKey:@"comment"]))
    [bindings setObject:c forKey:@"comment"];
  else
    [bindings setObject:@"" forKey:@"comment"];
          
  { /* set creator */
    id cId = [obj valueForKey:@"ownerId"];
    if (cId != nil) {
      id c = [[self commandContext]
                    runCommand:@"account::get", @"companyId", cId, nil];
      if ([c isKindOfClass:[NSArray class]])
        c = [c lastObject];
      [bindings setObject:_personName(self, c) forKey:@"creator"];
    }
  }
  { /* set participants */
    NSEnumerator    *enumerator = [[obj valueForKey:@"participants"]
                                        objectEnumerator];
    id              part        = nil;
    NSMutableString *str        = nil;
          
    while ((part = [enumerator nextObject])) {
      if (str == nil)
        str = [[NSMutableString alloc] initWithCapacity:128];
      else
        [str appendString:@", "];

      if ([[part valueForKey:@"isTeam"] boolValue] == YES)
        [str appendString:[part valueForKey:@"description"]];
      else
        [str appendString:_personName(self, part)];
    }
    if (str != nil) {
      [bindings setObject:str forKey:@"participants"];
      RELEASE(str); str = nil;
    }
  }
  return AUTORELEASE(bindings);
}

- (NSDictionary *)bindingsForAppointment:(id)_date {
  return _bindingForAppointment(self, _date);
}

@end /* SkyAptAction(AppointmentBindings) */
