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

#include "ICalParser.h"
#include "ICalParser+Privates.h"
#include "ICalComponent.h"
#include "NSString+ICal.h"
#include "common.h"
#include <ical.h>

@interface NSObject(IcalConstruction)

/* returns retained object !!! */
+ (id)constructWithComponentHandle:(icalcomponent *)_comp
  parser:(ICalParser *)_parser;

@end

@implementation ICalParser

static ICalParser *parser = nil;

+ (id)iCalParser {
  if (parser == nil)
    parser = [[ICalParser alloc] init];
  return parser;
}

- (id)init {
  if (parser) {
    RELEASE(parser);
    return nil;
  }
  return self;
}

/* accessors */

- (NSStringEncoding)libicalStringEncoding {
  return NSUTF8StringEncoding;
}

/* construction */

- (void)logUnknownComponentKind:(icalcomponent *)_comp {
  NSLog(@"%s: cannot process component kind %s",
        __PRETTY_FUNCTION__,
        icalenum_component_kind_to_string(icalcomponent_isa(_comp)));
}
- (Class)componentClassForHandle:(icalcomponent *)_comp {
  Class c;

  switch (icalcomponent_isa(_comp)) {
    case ICAL_VCALENDAR_COMPONENT:
      c = NSClassFromString(@"ICalVCalendar");
      break;
    case ICAL_VFREEBUSY_COMPONENT:
      c = NSClassFromString(@"ICalVFreeBusy");
      break;
    case ICAL_VEVENT_COMPONENT:
      c = NSClassFromString(@"ICalVEvent");
      break;
    case ICAL_XROOT_COMPONENT:
      // root component for a file with multiple components
      c = NSClassFromString(@"ICalXRoot");
      break;
      
    default:
      [self logUnknownComponentKind:_comp];
      c = Nil;
      break;
  }
  return c;
}

- (NSArray *)_makeSubComponents:(icalcomponent *)_comp {
  NSMutableArray *a;
  icalcomponent  *c;
  
  a = [NSMutableArray arrayWithCapacity:16];
  
  for(c = icalcomponent_get_first_component(_comp, ICAL_ANY_COMPONENT);
      c != NULL;
      c = icalcomponent_get_next_component(_comp, ICAL_ANY_COMPONENT)) {
    
    ICalComponent *oc;
    
    oc = [self _makeObjectForComponent:c];
    if (oc) {
      [a addObject:oc];
      RELEASE(oc);
    }
  }
  
  return a;
}

- (ICalComponent *)_makeObjectForComponent:(icalcomponent *)_comp {
  if (_comp == NULL) return nil;
  
  return [[self componentClassForHandle:_comp]
                constructWithComponentHandle:_comp
                parser:self];
}

/* parsing */

- (id)parseString:(NSString *)_string {
  icalcomponent *c;
  const char    *str;
  
  str = [_string icalCString];
  
  if ((c = icalparser_parse_string(str)) == NULL)
    /* parsing failed ... */
    return nil;
  
  return [[self _makeObjectForComponent:c] autorelease];
}

- (id)parseFileAtPath:(NSString *)_path encoding:(NSStringEncoding)_enc {
  NSData   *data;
  NSString *s;
  id result;
  
  data = [[NSData alloc] initWithContentsOfMappedFile:_path];
  if (data == nil) return nil;
  
  s = [[NSString alloc] initWithData:data encoding:_enc];
  RELEASE(data);
  
  result = [self parseString:s];
  RELEASE(s);
  
  return result;;
}
- (id)parseFileAtPath:(NSString *)_path {
  return [self parseFileAtPath:_path encoding:NSUTF8StringEncoding];
}

@end /* ICalParser */
