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

#include "LSNewAppointmentCommand.h"

@interface LSNewAppointmentFromVEventCommand : LSNewAppointmentCommand
{
  id vEvent;
}

- (void)setVEvent:(id)_event;
- (id)vEvent;

@end /* LSNewAppointmentFromVEventCommand */

#include <NGiCal/iCalEvent.h>
#include <NGiCal/iCalPerson.h>
#include <NGiCal/iCalAttachment.h>
#include <NGiCal/iCalTrigger.h>
#include <NGiCal/iCalAlarm.h>
#include <LSFoundation/LSCommandKeys.h>
#include <NGExtensions/NSCalendarDate+misc.h>
#include "common.h"

@implementation LSNewAppointmentFromVEventCommand

- (id)rsvpValue:(NSString *)_rsvp {
  _rsvp = [_rsvp lowercaseString];
  return [NSNumber numberWithBool:[_rsvp isEqualToString:@"true"]];
}

- (id)partStatusValue:(NSString *)_partStat {
  if ([_partStat hasPrefix:@"NEEDS"])
    return @"NEEDS-ACTION";
  return _partStat;
}

- (id)roleValue:(NSString *)_role {
  if ([_role hasPrefix:@"REQ-PART"])
    return @"REQ-PARTICIPANT";
  if ([_role hasPrefix:@"OPT-PART"])
    return @"OPT-PARTICIPANT";
  if ([_role hasPrefix:@"NON-PART"])
    return @"NON-PARTICIPANT";
  return _role;
}

- (id)processPerson:(iCalPerson *)_person {
  NSMutableDictionary *record;
  id tmp;

  record = [NSMutableDictionary dictionaryWithCapacity:8];
  if ((tmp = [_person email]))    [record setObject:tmp forKey:@"email"];
  if ((tmp = [_person cn]))       [record setObject:tmp forKey:@"cn"];
  if ((tmp = [_person xuid]))     [record setObject:tmp forKey:@"xuid"];
  
  if ((tmp = [_person rsvp]))
    [record setObject:[self rsvpValue:tmp] forKey:@"rsvp"];
  
  if ((tmp = [_person partStat]))
    [record setObject:[self partStatusValue:tmp] forKey:@"partStat"];
  
  if ((tmp = [_person role]))
    [record setObject:[self roleValue:tmp] forKey:@"role"];
  
  return record;
}

- (id)processTrigger:(iCalTrigger *)_trigger {
  NSMutableDictionary *record;
  id tmp;

  record = [NSMutableDictionary dictionaryWithCapacity:2];
  if ((tmp = [_trigger valueType])) [record setObject:tmp forKey:@"valueType"];
  if ((tmp = [_trigger value]))     [record setObject:tmp forKey:@"value"];

  return record;
}

- (id)processAttachment:(iCalAttachment *)_attach {
  NSMutableDictionary *record;
  id tmp;

  record = [NSMutableDictionary dictionaryWithCapacity:2];
  if ((tmp = [_attach valueType])) [record setObject:tmp forKey:@"valueType"];
  if ((tmp = [_attach value]))     [record setObject:tmp forKey:@"value"];

  return record;
}

- (id)processAlarm:(iCalAlarm *)_alarm {
  NSMutableDictionary *record;
  id tmp;

  record = [NSMutableDictionary dictionaryWithCapacity:4];
  if ((tmp = [_alarm comment])) [record setObject:tmp forKey:@"comment"];
  if ((tmp = [_alarm action]))  [record setObject:tmp forKey:@"action"];
  if ((tmp = [_alarm trigger])) [record setObject:[self processTrigger:tmp]
                                        forKey:@"trigger"];
  if ((tmp = [_alarm attach]))  [record setObject:[self processAttachment:tmp]
                                        forKey:@"attachment"];

  return record;
}

// TODO: implement and use this
- (NSString *)toCSVValue:(id)_val {
  NSString        *source;

  if (_val == nil) return nil;
  if (![(source = [_val stringValue]) length]) return @"";

  return nil;
}

- (id)alarmsToCSV:(NSArray *)_alarms {
  /*
   * format:
   * action,comment,trigger-type,trigger-value,attach-type,attach-value
   *
   */
  NSMutableString *ms;
  unsigned        i, max;
  
  max = [_alarms count];
  if (max == 0) return @"";
  
  ms = [NSMutableString stringWithCapacity:32];
  for (i = 0; i < max; i++) {
    NSDictionary *alarm, *trigger, *attach;
    id tmp;
    
    alarm   = [_alarms objectAtIndex:i];
    trigger = [alarm objectForKey:@"trigger"];
    attach  = [alarm objectForKey:@"attachment"];

    tmp = [alarm objectForKey:@"action"];
    if ([tmp isNotEmpty]) [ms appendFormat:@"'%@'", tmp];
    else [ms appendString:@""];

    tmp = [alarm objectForKey:@"comment"];
    if ([tmp isNotEmpty]) [ms appendFormat:@",'%@'", tmp];
    else [ms appendString:@","];

    
    tmp = [trigger objectForKey:@"valueType"];
    if ([tmp isNotEmpty]) [ms appendFormat:@",'%@'", tmp];
    else [ms appendString:@","];
    
    tmp = [trigger objectForKey:@"value"];
    if ([tmp isNotEmpty]) [ms appendFormat:@",'%@'", tmp];
    else [ms appendString:@","];
    
    tmp = [attach objectForKey:@"valueType"];
    if ([tmp isNotEmpty]) [ms appendFormat:@",'%@'", tmp];
    else [ms appendString:@","];
    
    tmp = [attach objectForKey:@"value"];
    if ([tmp isNotEmpty]) [ms appendFormat:@",'%@'", tmp];
    else [ms appendString:@","];
    
    [ms appendString:@"\n"];
  }
  
  return ms;
}

- (void)_detectAllDayInContext:(id)_context {
  NSCalendarDate *start;
  NSCalendarDate *end;

  start = [self valueForKey:@"startDate"];
  end   = [self valueForKey:@"endDate"];

  if (([start hourOfDay] == 0) &&
      ([start minuteOfHour] == 0) &&
      ([end hourOfDay] == 0) &&
      ([end minuteOfHour] == 0) &&
      (![start isDateOnSameDay:end])) {
    end = [end dateByAddingYears:0 months:0 days:0
               hours:0 minutes:-1 seconds:0];
    if (end) [self takeValue:end forKey:@"endDate"];
  }
}

- (void)_prepareForExecutionInContext:(id)_context {
  iCalEvent *event;
  id        tmp;

  event = (iCalEvent *)[self vEvent];
  [self assert:(event != nil) reason:@"missing vevent"];

  if ([(tmp = [event summary]) isNotNull]) {
    [self takeValue:tmp forKey:@"title"];
  }
  else {
    /* Apple iCal can be configured so that the summary is not posted */
    [self takeValue:@"-" forKey:@"title"];
    [self debugWithFormat:
            @"no iCalendar summary provided, using default title."];
  }
  
  if ((tmp = [event startDate]))[self takeValue:tmp forKey:@"startDate"];
  if ((tmp = [event endDate]))  [self takeValue:tmp forKey:@"endDate"];

  if ((tmp = [event location])) [self takeValue:tmp forKey:@"location"];
  if ((tmp = [event uid]))      [self takeValue:tmp forKey:@"sourceUrl"];
  if ((tmp = [event comment]))  [self takeValue:tmp forKey:@"comment"];
  if ((tmp = [event priority])) [self takeValue:tmp forKey:@"importance"];

  [self _detectAllDayInContext:_context];
  
  if ([(tmp = [event accessClass]) isNotNull]) {
    // DUP in LSUpdateAppointmentWithVEventCommand
    int sensitivity;

    if ([tmp isEqualToString:@"PUBLIC"])
      sensitivity = 0;
    else if ([tmp isEqualToString:@"PRIVATE"])
      sensitivity = 2;
    else if ([tmp isEqualToString:@"PERSONAL"]) /* non-standard */
      sensitivity = 1;
    else if ([tmp isEqualToString:@"CONFIDENTIAL"]) /* non-standard */
      sensitivity = 3;
    else if ([tmp length] == 0)
      sensitivity = -1;
    else {
      [self errorWithFormat:@"unknown iCal class: '%@'", tmp];
      sensitivity = -1;
    }
    if (sensitivity >= 0) {
      [self takeValue:[NSNumber numberWithInt:sensitivity] 
	    forKey:@"sensitivity"];
    }
  }
  
  if ([(tmp = [event attendees]) isNotNull]) {
    unsigned max = [tmp count];
    if (max) {
      NSMutableArray *persons = [NSMutableArray arrayWithCapacity:max];
      unsigned       i;
      id             one;
      for (i = 0; i < max; i++) {
        one = [self processPerson:[tmp objectAtIndex:i]];
        if (one)
          [persons addObject:one];
        else 
          [self logWithFormat:@"failed processing person: %@",
                [tmp objectAtIndex:i]];
      }
      [self takeValue:persons forKey:@"participants"];
    }
  }
  
  if ([[self valueForKey:@"participants"] count] == 0) {
    [self takeValue:
	    [NSArray arrayWithObject:[_context valueForKey:LSAccountKey]]
          forKey:@"participants"];
  }

  
  if ([(tmp = [event alarms]) isNotNull]) {
    unsigned max;
    
    if ((max = [tmp count]) > 0) {
      NSMutableArray *alarms;
      unsigned       i;
      id             one;
      
      alarms = [NSMutableArray arrayWithCapacity:max];
      for (i = 0; i < max; i++) {
        one = [self processAlarm:[tmp objectAtIndex:i]];
        if (one)
          [alarms addObject:one];
        else 
          [self logWithFormat:@"failed processing alarm: %@",
                [tmp objectAtIndex:i]];
      }
      [self takeValue:[self alarmsToCSV:alarms] forKey:@"evoReminder"];
    }
    else
      [self takeValue:@"" forKey:@"evoReminder"];
  }


  [super _prepareForExecutionInContext:_context];
}

- (id)initForOperation:(NSString *)_operation inDomain:(NSString *)_domain {
  if ((self = [super initForOperation:_operation inDomain:_domain])) {
    [self takeValue:@"Appointment created with VEvent" forKey:@"logText"];
  }
  return self;
}


/* accessors */

- (void)setVEvent:(id)_event {
  ASSIGN(self->vEvent,_event);
}
- (id)vEvent {
  return self->vEvent;
}

/* KVC */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"vevent"]) {
    [self setVEvent:_value];
    return;
  }
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"vevent"])
    return [self vEvent];
  return [super valueForKey:_key];
}

@end /* LSNewAppointmentFromVEventCommand */
