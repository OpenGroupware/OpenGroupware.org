/*
  Copyright (C) 2002-2005 SKYRIX Software AG

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

#include "SxAppointmentRenderer.h"
#include "common.h"

@implementation SxAppointmentRenderer

static NSTimeZone *gmt = nil;
static BOOL debugRenderer = NO;

+ (void)initialize {
  if (gmt == nil) gmt = [[NSTimeZone timeZoneWithName:@"GMT"] retain];
}

+ (id)renderer {
  return [[[self alloc] init] autorelease];
}

- (void)dealloc {
  [self->mime release];
  [self->ical release];
  [super dealloc];
}

/* rendering */

- (NSString *)productID {
  return @"OpenGroupware.org ZideStore 1.3";
}

- (NSString *)cnForAccount:(id)_acc {
  return [NSString stringWithFormat:@"%@ %@",
                   [_acc valueForKey:@"firstname"],
                   [_acc valueForKey:@"name"]];
}
- (NSString *)emailForAccount:(id)_acc {
  return [_acc valueForKey:@"email1"];
}

- (void)appendTriggerAsICal:(id)_trigger to:(NSMutableString *)_ms {
  id tmp; 
  [_ms appendString:@"TRIGGER"];

  tmp = [(NSDictionary *)_trigger objectForKey:@"valueType"];
  if (tmp)
    [_ms appendFormat:@";VALUE=%@", [tmp uppercaseString]];

  // TODO: fix this
  [_ms appendString:@";RELATED=START"];

  [_ms appendString:@":"];
  [_ms appendString:[(NSDictionary *)_trigger objectForKey:@"value"]];
  [_ms appendString:@"\r\n"];  
}
- (void)appendAttachmentAsICal:(id)_attach to:(NSMutableString *)_ms {
  id tmp; 
  [_ms appendString:@"ATTACH"];

  tmp = [(NSDictionary *)_attach objectForKey:@"valueType"];
  if (tmp)
    [_ms appendFormat:@";VALUE=%@", tmp];

  [_ms appendString:@":"];
  [_ms appendString:[(NSDictionary *)_attach objectForKey:@"value"]];
  [_ms appendString:@"\r\n"];  
}

- (void)appendAlarmAsICal:(id)_alarm to:(NSMutableString *)_ms {
  id tmp;
  
  [_ms appendString:@"BEGIN:VALARM\r\n"];

  tmp = [(NSDictionary *)_alarm objectForKey:@"action"];
  if (tmp) [_ms appendFormat:@"ACTION:%@\r\n", tmp];

  tmp = [(NSDictionary *)_alarm objectForKey:@"comment"];
  if (tmp) [_ms appendFormat:@"DESCRIPTION:%@\r\n", tmp];

  tmp = [(NSDictionary *)_alarm objectForKey:@"trigger"];
  if (tmp) [self appendTriggerAsICal:tmp to:_ms];

  tmp = [(NSDictionary *)_alarm objectForKey:@"attachment"];
  if (tmp) [self appendAttachmentAsICal:tmp to:_ms];

  [_ms appendString:@"END:VALARM\r\n"];
}

- (NSString *)checkCSVEntry:(NSString *)_entry {
  unsigned len;
  if (((len = [_entry length]) > 1) && ([_entry hasPrefix:@"'"]))
    return [_entry substringWithRange:NSMakeRange(1, len - 2)];
  return _entry;
}

- (NSArray *)parseAlarmsCSV:(NSString *)_csv {
  // see SxAppointmentMessageParser for format
  // TODO: do a better parsing
  /*
   * format:
   * action,comment,trigger-type,trigger-value,attach-type,attach-value
   */

  unsigned numLines, i, numColumns, k;
  NSString *line;
  NSArray  *lines;
  NSArray  *columns;
  id       tmp;
  NSMutableArray      *ma;
  NSMutableDictionary *alarm;
  NSMutableDictionary *trigger;
  NSMutableDictionary *attach;

  lines    = [_csv componentsSeparatedByString:@"\n"];
  numLines = [lines count];

  if (!numLines) return [NSArray array];

  ma = [NSMutableArray arrayWithCapacity:numLines];

  for (i = 0; i < numLines; i++) {
    line       = [lines objectAtIndex:i];
    columns    = [line componentsSeparatedByString:@","];
    numColumns = [columns count];
    k          = 0;

    alarm   = [NSMutableDictionary dictionaryWithCapacity:4];
    trigger = [NSMutableDictionary dictionaryWithCapacity:2];
    attach  = [NSMutableDictionary dictionaryWithCapacity:2];

    // action
    if (numColumns > k) {
      tmp = [self checkCSVEntry:[columns objectAtIndex:k]];
      if ([tmp length])
        [alarm setObject:tmp forKey:@"action"];
      k++;
    }

    // comment
    if (numColumns > k) {
      tmp = [self checkCSVEntry:[columns objectAtIndex:k]];
      if ([tmp length])
        [alarm setObject:tmp forKey:@"comment"];
      k++;
    }

    // trigger-type
    if (numColumns > k) {
      tmp = [self checkCSVEntry:[columns objectAtIndex:k]];
      if ([tmp length])
        [trigger setObject:tmp forKey:@"valueType"];
      k++;
    }
    // trigger-value
    if (numColumns > k) {
      tmp = [self checkCSVEntry:[columns objectAtIndex:k]];
      if ([tmp length])
        [trigger setObject:tmp forKey:@"value"];
      k++;
    }

    // attach-type
    if (numColumns > k) {
      tmp = [self checkCSVEntry:[columns objectAtIndex:k]];
      if ([tmp length])
        [attach setObject:tmp forKey:@"valueType"];
      k++;
    }
    // attach-value
    if (numColumns > k) {
      tmp = [self checkCSVEntry:[columns objectAtIndex:k]];
      if ([tmp length])
        [attach setObject:tmp forKey:@"value"];
      k++;
    }

    if ([trigger count])
      [alarm setObject:trigger forKey:@"trigger"];
    if ([attach count])
      [alarm setObject:attach forKey:@"attachment"];

    if ([alarm count])
      [ma addObject:alarm];
  }

  return ma;
}

- (void)appendAlarmsAsICal:(NSArray *)_alarms to:(NSMutableString *)_ms {
  unsigned i, max;
  id alarm;
  max     = [_alarms count];
  for (i = 0; i < max; i++) {
    alarm = [_alarms objectAtIndex:i];
    [self appendAlarmAsICal:alarm to:_ms];
  }
}


- (void)appendAttendeeAsICal:(id)_participant to:(NSMutableString *)_ms {
  id   role, rsvp, cn, email, state;
  BOOL isTeam;
  
  role   = [_participant valueForKey:@"role"];
  isTeam = [[_participant valueForKey:@"isTeam"] boolValue];
  rsvp   = [_participant valueForKey:@"rsvp"];
  state  = [_participant valueForKey:@"partStatus"];

  if (isTeam) {
    cn = [_participant valueForKey:@"description"];
    email = cn;
  }
  else {
    NSString *tmp;
      
    if ((tmp = [_participant valueForKey:@"firstname"]) != nil)
      cn = [tmp stringByAppendingString:@" "];
    else
      cn = @"";

    if ((tmp = [_participant valueForKey:@"name"]) != nil)
      cn = [cn stringByAppendingString:tmp];

    if ([cn length] == 0)
      cn = @"No Name";
    
    email = ((tmp = [_participant valueForKey:@"email1"]) != nil)
      ? tmp
      : cn;
  }
  
  [_ms appendString:@"ATTENDEE;CUTYPE=\""];
  
  // TODO: add support for resources !
  [_ms appendString:isTeam ? @"GROUP" : @"INDIVIDUAL"];
  
  [_ms appendString:@"\";PARTSTAT=\""];
  [_ms appendString:([state length] > 0) ? state : @"NEEDS-ACTION"];
  
  [_ms appendString:@"\";ROLE=\""];
  [_ms appendString:([role length] > 0) ? role : @"OPT-PARTICIPANT"];
  
  [_ms appendString:@"\";RSVP=\""];
  [_ms appendString:[rsvp boolValue] ? @"TRUE" : @"FALSE"];
  
  [_ms appendFormat:@"\";CN=\"%@\":MAILTO:%@\r\n", cn, email];
}

- (void)appendAttendeesAsICal:(NSArray *)_parts to:(NSMutableString *)_ms {
  unsigned i, max;
  id part;
  max     = [_parts count];
  for (i = 0; i < max; i++) {
    part = [_parts objectAtIndex:i];
    [self appendAttendeeAsICal:part to:_ms];
  }
}

- (id)renderAppointmentAsICal:(id)_eo timezone:(NSTimeZone *)_tz {
  static NSString *iCalDateFmt   = @"%Y%m%dT%H%M%SZ";
  static NSString *iCalTZDateFmt = @"%Z:%Y%m%dT%H%M%S";
  static NSString *skyrixId      = nil;
  NSCalendarDate *date;
  NSString *t;
  NSString *dateFmt;
  id       owner;

  NSLog(@"WARNING%s: SxAppointmentRenderer deprecated. "
        @"use command appointment::get-ical", __PRETTY_FUNCTION__);

  if (skyrixId == nil) {
    skyrixId = [[NSUserDefaults standardUserDefaults]
                                valueForKey:@"skyrix_id"];
    skyrixId = [[NSString alloc] initWithFormat:@"skyrix://%@/%@/",
                                 [[NSHost currentHost] name],
                                 skyrixId];
  }
  
  if (self->ical == nil)
    self->ical = [[NSMutableString alloc] initWithCapacity:1024];
  else
    [self->ical setString:@""];

  dateFmt = (_tz != nil) ? iCalTZDateFmt : iCalDateFmt;
  
  /* event */
  [self->ical appendString:@"BEGIN:VEVENT\r\n"];
  
  owner = [_eo valueForKey:@"owner"];
  if (owner == nil) {
    owner = [NSDictionary dictionaryWithObjectsAndKeys:
                          [_eo valueForKey:@"ownerId"], @"name",
                          [_eo valueForKey:@"ownerId"], @"email1",
                          nil];
  }
  [self->ical appendFormat:@"ORGANIZER;CN=\"%@\":MAILTO:%@\r\n",
        [self cnForAccount:owner], [self emailForAccount:owner]];
  
  /* evo writes GUID, eg "{7C0FB320-1CEB-45B6-A520-B7B2708DE489}" */
  [self->ical appendFormat:@"UID:%@\r\n",
       [skyrixId stringByAppendingFormat:@"%@", [_eo valueForKey:@"dateId"]]];
  
  /* 20:30-21:00 GMT */
  date = [_eo valueForKey:@"startDate"];
  if (_tz != nil) [date setTimeZone:_tz];
  else [date setTimeZone:gmt];
  
  t = [date descriptionWithCalendarFormat:dateFmt];
  if (_tz != nil)
    [self->ical appendFormat:@"DTSTART;TZID=%@\r\n", t];
  else
    [self->ical appendFormat:@"DTSTART:%@\r\n", t];
  
  date = [_eo valueForKey:@"endDate"];
  if (_tz != nil) [date setTimeZone:_tz];
  else [date setTimeZone:gmt];
  [date setTimeZone:_tz];
  t = [date descriptionWithCalendarFormat:dateFmt];
  if (_tz != nil)
    [self->ical appendFormat:@"DTSTART;TZID=%@\r\n", t];
  else
    [self->ical appendFormat:@"DTSTART:%@\r\n", t];
  
  t = [_eo valueForKey:@"title"];
  if ([t isNotNull]) [self->ical appendFormat:@"SUMMARY:%@\r\n", t];
  
  t = [_eo valueForKey:@"location"];
  if ([t isNotNull]) [self->ical appendFormat:@"LOCATION:%@\r\n", t];
  
  t = [_eo valueForKey:@"comment"];
  if ([t isNotNull]) {
    [self->ical appendFormat:@"DESCRIPTION:%@\r\n",
	[t stringByReplacingString:@"\n" withString:@"\\N"]];
  }
  
  [self->ical appendFormat:@"SEQUENCE:%i\r\n", 
        [[_eo valueForKey:@"objectVersion"] intValue]];
  
  [self->ical appendFormat:@"PRIORITY:%i\r\n", 0 /*[self priority]*/];

  // TODO: rather use sensitivity
  /*
    "OlSensitivity" for Appointment and Task items in MSDN:
    0 - normal
    1 - personal
    2 - private
    3 - confidential
  */
  t = [_eo valueForKey:@"accessTeamId"];
  t = ([t intValue] > 1000) ? @"PUBLIC" : @"PRIVATE";
  [self->ical appendFormat:@"CLASS:%@\r\n", t /*[self aptClass]*/];
  
  //[self->ical appendFormat:@"STATUS:%@\r\n", @"" /*[self status]*/];
  //[self->ical appendFormat:@"TRANSP:%@\r\n", @"" /*[self transp]*/];
  
  /*
    'TRANSP' says whether the event is included in FreeBusy processing, is
    either: OPAQUE or TRANSPARENT and can be selected in Evolution (2.2)
    using the "show time as busy" checkbox
  */
  [self->ical appendString:@"TRANSP:OPAQUE\r\n"];
  
  // TODO:
  [self->ical appendString:@"CREATED:20030113T191908Z\r\n"];
  [self->ical appendString:@"LAST-MODIFIED:20030113T191912Z\r\n"];
  [self->ical appendString:@"DTSTAMP:20030113T191908Z\r\n"];
  
  [self->ical appendFormat:@"X-MICROSOFT-CDO-IMPORTANCE:%i\r\n",
      0 /* [self importance] */];
  [self->ical appendString:@"X-MICROSOFT-CDO-BUSYSTATUS:BUSY\r\n"];
  [self->ical appendString:@"X-MICROSOFT-CDO-INSTTYPE:0\r\n"];
  
  //if (![self isAllDayEvent])
  [self->ical appendString:@"X-MICROSOFT-CDO-ALLDAYEVENT:FALSE\r\n"];
  //else [self->ical appendString:@"X-MICROSOFT-CDO-ALLDAYEVENT:TRUE\r\n"];

  [self appendAttendeesAsICal:
	  [(NSDictionary *)_eo objectForKey:@"participants"] 
	to:self->ical];

  {
    id tmp = [_eo valueForKey:@"evoReminder"];
    if (tmp)
      [self appendAlarmsAsICal:[self parseAlarmsCSV:tmp] to:self->ical];
  }
  
  [self->ical appendString:@"END:VEVENT\r\n"];
  
  if (debugRenderer)
    [self logWithFormat:@"generated iCal:\n---\n%@\n---", self->ical];
  
  return [[self->ical copy] autorelease];
}

- (void)appendTimeZoneAsICal:(NSTimeZone *)_tz
                      atDate:(NSCalendarDate *)_date
                          to:(NSMutableString *)_ical
{
  int offset;
  int hours, minutes;
  offset = [_tz secondsFromGMTForDate:_date];
  minutes  = offset  / 60;
  hours    = minutes / 60;
  minutes -= (hours * 60);
  minutes  = abs(minutes);
  
  [_ical appendString:@"BEGIN:VTIMEZONE\r\n"];
  
  [_ical appendFormat:@"TZID:%@\r\n", [_tz abbreviationForDate:_date]];
  [_ical appendString:@"BEGIN:STANDARD\r\n"];
  [_ical appendString:@"DTSTART:19000101T000000\r\n"];
  [_ical appendString:@"RDATE:19000101T000000\r\n"];
  [_ical appendString:@"TZOFFSETFROM:-0000\r\n"];
  [_ical appendFormat:@"TZOFFSETTO:%+03d%02d\r\n", hours, minutes];
  [_ical appendFormat:@"TZNAME:%@\r\n", [_tz timeZoneName]];
  [_ical appendString:@"END:STANDARD\r\n"];
  
  [_ical appendString:@"END:VTIMEZONE\r\n"];
}

- (id)renderAppointmentAsMIME:(id)_eo timezone:(NSTimeZone *)_tz {
  if (self->mime == nil)
    self->mime = [[NSMutableString alloc] initWithCapacity:1024];
  else
    [self->mime setString:@""];
  
  /* header */
#if 0
  [self->mime appendString:
	 @"thread-index: AcK7OKhPOB/XO+v7SFCdO0Vhe7wWOA==\r\n"];
#endif
  [self->mime appendString:@"Thread-Topic: test\r\n"];
  [self->mime appendString:@"MIME-Version: 1.0\r\n"];
  [self->mime appendString:
	 @"Content-Type: text/calendar; charset=\"utf-8\"\r\n"];
  [self->mime appendString:@"Content-Transfer-Encoding: 8bit\r\n"];
  [self->mime appendString:
	 @"content-class: urn:content-classes:appointment\r\n"];
#if 0
  [self->mime appendString:
	@"X-MimeOLE: Produced By Microsoft Exchange V6.0.4417.0\r\n"];
#endif
  
  [self->mime appendFormat:@"Subject: %@\r\n", [_eo valueForKey:@"title"]];
  [self->mime appendString:@"Importance: normal\r\n"]; // TODO
  [self->mime appendString:@"Priority: normal\r\n"]; // TODO
  
  [self->mime appendString:@"\r\n"];
  
  /* body */
  [self->mime appendString:@"BEGIN:VCALENDAR\r\n"];
  [self->mime appendString:@"METHOD:REQUEST\r\n"];
  [self->mime appendString:@"PRODID:"];
  [self->mime appendString:[self productID]];
  [self->mime appendString:@"\r\n"];
  [self->mime appendString:@"VERSION:2.0\r\n"];
  if (_tz != nil) {
    NSCalendarDate *date, *tmp;    
    date = [NSCalendarDate date];
    tmp = [NSCalendarDate dateWithYear:[date yearOfCommonEra]
                          month:1 day:1 hour:1 minute:0 second:0
                          timeZone:_tz];
    [self appendTimeZoneAsICal:_tz atDate:tmp to:self->mime];
    tmp = [NSCalendarDate dateWithYear:[date yearOfCommonEra]
                          month:7 day:1 hour:1 minute:0 second:0
                          timeZone:_tz];
    [self appendTimeZoneAsICal:_tz atDate:tmp to:self->mime];
  }
  [self->mime appendString:[self renderAppointmentAsICal:_eo timezone:_tz]];
  [self->mime appendString:@"END:VCALENDAR"];
  
  //[self logWithFormat:@"send ical msg:\n%@", self->mime];
  return [[self->mime copy] autorelease];
}

- (id)wrapICalStringInMIME:(id)_iCal
               appointment:(id)_eo
                  timezone:(NSTimeZone *)_tz
{
  if (self->mime == nil)
    self->mime = [[NSMutableString alloc] initWithCapacity:1024];
  else
    [self->mime setString:@""];
  
  /* header */
#if 0
  [self->mime appendString:
	 @"thread-index: AcK7OKhPOB/XO+v7SFCdO0Vhe7wWOA==\r\n"];
#endif
  [self->mime appendString:@"Thread-Topic: test\r\n"];
  [self->mime appendString:@"MIME-Version: 1.0\r\n"];
  [self->mime appendString:
	 @"Content-Type: text/calendar; charset=\"utf-8\"\r\n"];
  [self->mime appendString:@"Content-Transfer-Encoding: 8bit\r\n"];
  [self->mime appendString:
	 @"content-class: urn:content-classes:appointment\r\n"];
#if 0
  [self->mime appendString:
	@"X-MimeOLE: Produced By Microsoft Exchange V6.0.4417.0\r\n"];
#endif
  
  [self->mime appendFormat:@"Subject: %@\r\n", [_eo valueForKey:@"title"]];
  [self->mime appendString:@"Importance: normal\r\n"]; // TODO
  [self->mime appendString:@"Priority: normal\r\n"]; // TODO
  
  [self->mime appendString:@"\r\n"];
  
  /* body */
  [self->mime appendString:@"BEGIN:VCALENDAR\r\n"];
  [self->mime appendString:@"METHOD:REQUEST\r\n"];
  [self->mime appendString:@"PRODID:"];
  [self->mime appendString:[self productID]];
  [self->mime appendString:@"\r\n"];
  [self->mime appendString:@"VERSION:2.0\r\n"];
  if (_tz != nil) {
    NSCalendarDate *date, *tmp;    
    date = [NSCalendarDate date];
    tmp = [NSCalendarDate dateWithYear:[date yearOfCommonEra]
                          month:1 day:1 hour:1 minute:0 second:0
                          timeZone:_tz];
    [self appendTimeZoneAsICal:_tz atDate:tmp to:self->mime];
    tmp = [NSCalendarDate dateWithYear:[date yearOfCommonEra]
                          month:7 day:1 hour:1 minute:0 second:0
                          timeZone:_tz];
    [self appendTimeZoneAsICal:_tz atDate:tmp to:self->mime];
  }
  [self->mime appendString:_iCal];
  [self->mime appendString:@"END:VCALENDAR"];
  
  return [[self->mime copy] autorelease];
}

/* DEPRECATED */

- (id)renderAppointmentAsICal:(id)_eo {
  NSTimeZone *tz;
  
  tz = [[_eo valueForKey:@"startDate"] timeZone];
  return [self renderAppointmentAsICal:_eo timezone:tz];
}
- (id)renderAppointmentAsMIME:(id)_eo {
  NSTimeZone *tz;
  tz = [[_eo valueForKey:@"startDate"] timeZone];
  return [self renderAppointmentAsMIME:_eo timezone:nil];
}

@end /* SxAppointmentRenderer */
