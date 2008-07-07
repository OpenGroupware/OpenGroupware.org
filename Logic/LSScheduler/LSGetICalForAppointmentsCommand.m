/*
  Copyright (C) 2002-2006 SKYRIX Software AG
  Copyright (C) 2006      Helge Hess

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

#include <LSFoundation/LSDBObjectBaseCommand.h>

/*
  This command fetches iCalender strings for globalIDs (Date)
  date-objects can also be set directly.
  It does not cache anything so far.
  Just fetches the dates and builds the iCal-Strings
  @see: RFC 2445
*/

@interface LSGetICalForAppointmentsCommand : LSDBObjectBaseCommand
{
  NSArray *apts;
  NSArray *gids;
}

@end

#include "NSString+ICal.h"
#include "common.h"
#include <NGObjWeb/WOResponse.h> // TODO: should not be done ..

@implementation LSGetICalForAppointmentsCommand

static NSTimeZone *gmt      = nil;
static NSString   *skyrixId = nil;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  if (gmt == nil) gmt = [[NSTimeZone timeZoneWithName:@"GMT"] retain];
  
  if (skyrixId == nil) {
    skyrixId = [[ud valueForKey:@"skyrix_id"] stringValue];
    skyrixId = [[NSString alloc] initWithFormat:@"skyrix://%@/%@/",
                                 [[NSHost currentHost] name],
                                 skyrixId];
  }
}
 
- (void)dealloc {
  [self->apts release];
  [self->gids release];
  [super dealloc];
}

/* build iCal */

// copy&paste from LSGetVCardForGlobalIDsCommand.m
- (void)_appendTextValue:(NSString *)_str toICal:(NSMutableString *)_iCal {
  [_iCal appendString:[_str stringByEscapingUnsafeICalCharacters]];
}

- (void)_appendDateValue:(NSCalendarDate *)_date toICal:(NSMutableString*)_s {
  NSString *s;
  char buf[32];
  
  [_date setTimeZone:gmt];
  
  snprintf(buf, sizeof(buf), "%04i%02i%02iT%02i%02i%02iZ",
	   [_date yearOfCommonEra], [_date monthOfYear], [_date dayOfMonth],
	   [_date hourOfDay], [_date minuteOfHour], [_date secondOfMinute]);
  s = [[NSString alloc] initWithCString:buf];
  [_s appendString:s];
  [s release]; s = nil;
}

- (void)_appendName:(NSString *)_name andValue:(id)_value 
  toICal:(NSMutableString *)_iCal
{
  [_iCal appendString:_name];
  [_iCal appendString:@":"];
  if ([_value isKindOfClass:[NSArray class]]) {
    unsigned cnt, i;
    
    for (i = 0, cnt = [_value count]; i < cnt; i++) {
      id value = [_value objectAtIndex:i];
      
      if (i != 0) [_iCal appendString:@","];
      if ([_value isKindOfClass:[NSCalendarDate class]])
	[self _appendDateValue:_value toICal:_iCal];
      else
	[self _appendTextValue:value toICal:_iCal];
    }
  }
  else if ([_value isKindOfClass:[NSString class]])
    [self _appendTextValue:_value toICal:_iCal];
  else if ([_value isKindOfClass:[NSCalendarDate class]]) 
    [self _appendDateValue:_value toICal:_iCal];
  else 
    [self _appendTextValue:[_value description] toICal:_iCal];
  [_iCal appendString:@"\r\n"];
}

- (void)_appendName:(NSString *)_name
  andTimelessDate:(NSCalendarDate *)_date
  toICal:(NSMutableString *)_iCal
{
  NSString *s;
  char buf[32];
  
  snprintf(buf, sizeof(buf), "%04d%02d%02d",
	   [_date yearOfCommonEra], [_date monthOfYear], [_date dayOfMonth]);
  
  _name = [_name stringByAppendingString:@";VALUE=DATE"];
  s = [[NSString alloc] initWithCString:buf];
  [self _appendName:_name andValue:s toICal:_iCal];
  [s release]; s = nil;
}

- (NSString *)skyrixIdUrl:(id)_plainId {
  return [skyrixId stringByAppendingString:[_plainId stringValue]];
}

/* rendering */

/*
  Component Name: "VEVENT"

  Purpose: Provide a grouping of component properties that describe an
  event.

  Format Definition: A "VEVENT" calendar component is defined by the
  following notation:

  eventc     = "BEGIN" ":" "VEVENT" CRLF
                eventprop *alarmc
               "END" ":" "VEVENT" CRLF
                  
  eventprop  = *(
                ; the following are optional,
                ; but MUST NOT occur more than once

                class / created / description / dtstart / geo /
                last-mod / location / organizer / priority /
                dtstamp / seq / status / summary / transp /
                uid / url / recurid /

                ; either 'dtend' or 'duration' may appear in
                ; a 'eventprop', but 'dtend' and 'duration'
                ; MUST NOT occur in the same 'eventprop'

                dtend / duration /

                ; the following are optional,
                ; and MAY occur more than once

                attach / attendee / categories / comment /
                contact / exdate / exrule / rstatus / related /
                resources / rdate / rrule / x-prop

                )

*/

- (BOOL)isAllDayEvent:(id)_date {
  // TODO: this should take into account the configured timezone of the user
  NSCalendarDate *start;
  NSCalendarDate *end;
  
  start = [_date valueForKey:@"startDate"];
  if (([start hourOfDay] != 0) || ([start minuteOfHour] != 0))
    return NO;
  
  end   = [_date valueForKey:@"endDate"];
  if (([end hourOfDay] != 23) || ([end minuteOfHour] != 59))
    return NO;

  return YES;
}

- (void)_appendCoreAptData:(id)_date toICal:(NSMutableString *)_iCal {
  // CATEGORIES, CLASS, COMMENT, DESCRIPTION, LOCATION,
  // PRIORITY, RESOURCES, STATUS, SUMMARY, DTEND, DTSTART,
  // TRANSP, RELATED-TO, UID,
  // CREATED, DTSTAMP, LAST-MODIFIED, SEQUENCE
  NSString *tmp;

  if ([(tmp = [[_date valueForKey:@"keywords"] stringValue]) isNotEmpty]) {
    [self _appendName:@"CATEGORIES" 
	  andValue:[tmp componentsSeparatedByString:@","]
	  toICal:_iCal];
  }
  
  /* class */
  if ([(tmp = [_date valueForKey:@"sensitivity"]) isNotNull]) {
    if ([tmp intValue] == 0 /* undefined */)
      tmp = @"PUBLIC";
    else if ([tmp intValue] == 1 /* personal */ || 
	     [tmp intValue] == 2 /* private  */)
      tmp = @"PRIVATE";
    else if ([tmp intValue] == 3 /* confidential */)
      tmp = @"CONFIDENTIAL";
    else {
      [self errorWithFormat:@"unknown sensitivity: %@", tmp];
      tmp = nil;
    }
    if (tmp != nil) [self _appendName:@"CLASS" andValue:tmp toICal:_iCal];
  }
  
  if ([(tmp = [[_date valueForKey:@"location"] stringValue]) isNotEmpty])
    [self _appendName:@"LOCATION" andValue:tmp toICal:_iCal];
  
  if ([(tmp = [[_date valueForKey:@"importance"] stringValue]) isNotEmpty])
    [self _appendName:@"PRIORITY" andValue:tmp toICal:_iCal];
  
  if ([(tmp = [[_date valueForKey:@"resourceNames"] stringValue]) isNotEmpty]){
    [self _appendName:@"RESOURCES" 
	  andValue:[tmp componentsSeparatedByString:@", "]
	  toICal:_iCal];
  }
  
  [self _appendName:@"STATUS" andValue:@"CONFIRMED" toICal:_iCal];
  
  if ([(tmp = [[_date valueForKey:@"title"] stringValue]) isNotEmpty])
    [self _appendName:@"SUMMARY" andValue:tmp toICal:_iCal];
  
  // COMMENT
  // DESCRIPTION
  if ([(tmp = [[_date valueForKey:@"comment"] stringValue]) isNotEmpty])
    [self _appendName:@"DESCRIPTION" andValue:tmp toICal:_iCal];

  {
    NSCalendarDate *start;
    NSCalendarDate *end;
    
    start = [_date valueForKey:@"startDate"];
    end   = [_date valueForKey:@"endDate"];
    if ([self isAllDayEvent:_date]) {
      end = [[end tomorrow] beginOfDay]; /* different range */
      
      if ([start isNotNull])
	[self _appendName:@"DTSTART" andTimelessDate:start toICal:_iCal];
      if ([end isNotNull]) 
	[self _appendName:@"DTEND" andTimelessDate:end toICal:_iCal];
    }
    else {
      if ([start isNotNull])
        [self _appendName:@"DTSTART" andValue:start toICal:_iCal];
      if ([end isNotNull]) 
        [self _appendName:@"DTEND" andValue:end toICal:_iCal];
    }
    
  }

  // TRANSP (Free/Busy) & X-MICROSOFT-CDO-BUSYSTATUS
  if ([(tmp = [_date valueForKey:@"fbtype"]) isNotNull]) {
    [self _appendName:@"TRANSP" andValue:tmp toICal:_iCal];
    if ([tmp isEqualToString:@"TRANSPARENT"])
      tmp = @"FREE";
    else tmp = @"BUSY";
    [self _appendName:@"X-MICROSOFT-CDO-BUSYSTATUS"
             andValue:tmp
               toICal:_iCal];
  } else {
      tmp = [_date valueForKey:@"isConflictDisabled"];
      if ((tmp != nil) && ([tmp intValue] == 1)) {
        [self _appendName:@"TRANSP" andValue:@"TRANSPARENT" toICal:_iCal];
        [self _appendName:@"X-MICROSOFT-CDO-BUSYSTATUS"
                 andValue:@"FREE"
                   toICal:_iCal];
      } else {
          [self _appendName:@"TRANSP" andValue:@"OPAQUE" toICal:_iCal];
          [self _appendName:@"X-MICROSOFT-CDO-BUSYSTATUS"
                   andValue:@"BUSY"
                     toICal:_iCal];
        }
    }
  
  // RELATED-TO
  if ([(tmp = [_date valueForKey:@"parentDateId"]) isNotNull])
    [self _appendName:@"RELATED-TO" andValue:[self skyrixIdUrl:tmp]
          toICal:_iCal];
  // UID
  if ([(tmp = [_date valueForKey:@"dateId"]) isNotNull])
    [self _appendName:@"UID" andValue:[self skyrixIdUrl:tmp] toICal:_iCal];

  [_iCal appendString:@"CREATED:20030710T120000Z\r\n"];
  if ([(tmp = [_date valueForKey:@"lastModified"]) isNotNull]) {
    tmp = [NSCalendarDate dateWithTimeIntervalSince1970:[tmp doubleValue]];
    if (tmp != nil)
      [self _appendName:@"LAST-MODIFIED" andValue:tmp toICal:_iCal];
  }
  [self _appendName:@"DTSTAMP" andValue:[NSCalendarDate date] toICal:_iCal];

  /* X attributes */

  // X-MICROSOFT-CDO-IMPORTANCE
  if ([(tmp = [_date valueForKey:@"importance"]) isNotNull]) {
    int priority = [tmp intValue];
    if ((priority < 5) && (priority > 0)) {
      [self _appendName:@"X-MICROSOFT-CDO-IMPORTANCE" 
               andValue:@"2"
                 toICal:_iCal];
    } else if ((priority < 9) && (priority > 0)) {
        [self _appendName:@"X-MICROSOFT-CDO-IMPORTANCE" 
                 andValue:@"1"
                   toICal:_iCal];
      } else {
          [self _appendName:@"X-MICROSOFT-CDO-IMPORTANCE" 
                   andValue:@"0"
                     toICal:_iCal];
        }
  } /* end X-MICROSOFT-CDO-IMPORTANCE */

  [_iCal appendString:@"X-MICROSOFT-CDO-INSTTYPE:0\r\n"];
  
  [_iCal appendString:@"X-MICROSOFT-CDO-ALLDAYEVENT:"];
  if ([self isAllDayEvent:_date])
    [_iCal appendString:@"TRUE\r\n"];
  else
    [_iCal appendString:@"FALSE\r\n"];
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

  static NSArray *csvColumns = nil;

  unsigned numLines, i, numColumns, k;
  NSString *line;
  NSArray  *lines;
  NSArray  *columns;
  id       tmp;
  NSMutableArray      *ma;
  NSMutableDictionary *alarm;
  NSMutableDictionary *trigger;
  NSMutableDictionary *attach;

  if (csvColumns == nil) {
    csvColumns =
      [[NSArray alloc] initWithObjects:
                       @"action", @"comment",
                       @"valueType", @"value", // trigger
                       @"valueType", @"value", // attach
                       @"lastACK", // mozilla X-MOZ-LASTACK hack
                       nil];
  }

  lines    = [_csv componentsSeparatedByString:@"\n"];
  numLines = [lines count];

  if (!numLines) return [NSArray array];

  ma = [NSMutableArray arrayWithCapacity:numLines];

  for (i = 0; i < numLines; i++) {
    line       = [lines objectAtIndex:i];
    columns    = [line componentsSeparatedByString:@","];
    numColumns = [columns count];
    k          = 0;

    alarm   = [NSMutableDictionary dictionaryWithCapacity:7];
    trigger = [NSMutableDictionary dictionaryWithCapacity:2];
    attach  = [NSMutableDictionary dictionaryWithCapacity:2];

    // action
    // comment
    // trigger-type
    // trigger-value
    // attach-type
    // attach-value
    // lastACK (X-MOZ-LASTACK Mozilla extended attribute)
    while ((numColumns > k) && (k < 7)) {
      tmp = [self checkCSVEntry:[columns objectAtIndex:k]];
      if ([tmp isNotEmpty]) {
        switch (k) {
          case 0: case 1: case 6:
            [alarm setObject:tmp   forKey:[csvColumns objectAtIndex:k]]; break;
          case 2: case 3:
            [trigger setObject:tmp forKey:[csvColumns objectAtIndex:k]]; break;
          case 4: case 5:
            [attach setObject:tmp  forKey:[csvColumns objectAtIndex:k]]; break;
        }
      }
      k++;
    }
    if ([trigger count]) [alarm setObject:trigger forKey:@"trigger"];
    if ([attach count])  [alarm setObject:attach  forKey:@"attachment"];
    if ([alarm count])   [ma addObject:alarm];
  }

  return ma;
}

- (void)_appendAlarmData:(id)_date toICal:(NSMutableString *)_iCal {
  // ACTION, REPEAT, TRIGGER,
  NSArray *alarms;
  int i, cnt;
  id  tmp;
  
  tmp    = [_date valueForKey:@"evoReminder"];
  if (![tmp isNotNull]) tmp = @"";  
  alarms = [self parseAlarmsCSV:tmp];
  
  cnt = [alarms count];
  for (i = 0; i < cnt; i++) {
    NSDictionary *alarm;
    
    alarm = [alarms objectAtIndex:i];
  
    [_iCal appendString:@"BEGIN:VALARM\r\n"];
    
    if ((tmp = [alarm objectForKey:@"action"]))
      [self _appendName:@"ACTION" andValue:tmp toICal:_iCal];
    if ((tmp = [alarm objectForKey:@"comment"]))
      [self _appendName:@"DESCRIPTION" andValue:tmp toICal:_iCal];
    if ((tmp = [alarm objectForKey:@"lastACK"]))
      [self _appendName:@"X-MOZ-LASTACK" andValue:tmp toICal:_iCal];

    if ((tmp = [alarm objectForKey:@"trigger"])) {
      id       v   = [tmp valueForKey:@"value"];
      NSString *vt = [tmp valueForKey:@"valueType"];
      
      if ([vt isNotEmpty]) {
	vt = [NSString stringWithFormat:@"TRIGGER;VALUE=%@;RELATED=START",
		       [vt uppercaseString]];
      }
      else
	vt = @"TRIGGER;RELATED=START";
      
      [self _appendName:vt andValue:v toICal:_iCal];
    }

    if ((tmp = [alarm objectForKey:@"attachment"])) {
      id       v   = [tmp valueForKey:@"value"];
      NSString *vt = [tmp valueForKey:@"valueType"];
      [self _appendName:[vt isNotEmpty]
            ? [@"ATTACH;VALUE=" stringByAppendingString:vt]
            : (NSString *)@"ATTACH"
            andValue:v toICal:_iCal];
    }

    [_iCal appendString:@"END:VALARM\r\n"];
  }
}

/*
 attendee   = "ATTENDEE" attparam ":" cal-address CRLF

     attparam   = *(

                ; the following are optional,
                ; but MUST NOT occur more than once

                (";" cutypeparam) / (";"memberparam) /
                (";" roleparam) / (";" partstatparam) /
                (";" rsvpparam) / (";" deltoparam) /
                (";" delfromparam) / (";" sentbyparam) /
                (";"cnparam) / (";" dirparam) /
                (";" languageparam) /

                ; the following is optional,
                ; and MAY occur more than once

                (";" xparam)

                )
*/

- (NSString *)cnForAttendee:(id)_attendee {
  NSString *cn = nil, *tmp;
  
  if ([(tmp = [_attendee valueForKey:@"firstname"]) isNotEmpty])
    cn = tmp;
  
  if ([(tmp = [_attendee valueForKey:@"name"]) isNotEmpty]) {
    if ([cn isNotEmpty]) {
      cn = [cn stringByAppendingString:@" "];
      cn = [cn stringByAppendingString:tmp];
    }
    else
      cn = tmp;
  }

  return cn;
}

- (void)_appendAttendees:(id)_date toICal:(NSMutableString *)_iCal {
  // ATTENDEE, ORGANIZER
  NSArray  *parts;
  unsigned cnt, i;
  id       ownerId;
  
  parts   = [_date valueForKey:@"participants"];
  ownerId = [_date valueForKey:@"ownerId"];

  if (![parts isNotEmpty]) {
    [self warnWithFormat:@"no participants in appointment: %@",
	  [_date valueForKey:@"dateId"]];
  }
  
  for (i = 0, cnt = [parts count]; i < cnt; i++) { 
    NSMutableString *ms;
    NSString *role, *rsvp, *cn, *email, *state;
    NSString *tmp;
    NSNumber *companyId;
    id       participant;
    BOOL     isTeam;
    
    participant = [parts objectAtIndex:i];
    role      = [participant valueForKey:@"role"];
    isTeam    = [[participant valueForKey:@"isTeam"] boolValue];
    rsvp      = [participant valueForKey:@"rsvp"];
    state     = [participant valueForKey:@"partStatus"];
    companyId = [participant valueForKey:@"companyId"];
    
    if (isTeam) {
      cn    = [participant valueForKey:@"description"];
      email = [participant valueForKey:@"email"];
      if (![email isNotNull] || ![email isNotEmpty]) {
	[self warnWithFormat:@"using CN as email for team: %@", cn];
	email = cn;
      }
    }
    else {
      NSString *tmp;
      
      cn = [self cnForAttendee:participant];
      if (![cn isNotEmpty]) {
	cn = nil;
	[self warnWithFormat:@"got not CN for participant record: %@", 
	        participant];
      }
      
      if ([(tmp = [participant valueForKey:@"email1"]) isNotEmpty])
	email = tmp;
      else if ([(tmp = [participant valueForKey:@"email"]) isNotEmpty])
	email = tmp;
      else {
	[self warnWithFormat:@"using CN as email: '%@'", cn];
	email = cn;
      }
    }
    
    if (![state isNotEmpty]) state = @"NEEDS-ACTION";
    if (![role  isNotEmpty]) role  = @"OPT-PARTICIPANT";

    ms = [[NSMutableString alloc] initWithCapacity:256];
    [ms appendString:@"ATTENDEE"];
    
    [ms appendString:@";CUTYPE=\""];
    [ms appendString:isTeam ? @"GROUP" : @"INDIVIDUAL"];
    [ms appendString:@"\""];

    if (state != nil) {
      [ms appendString:@";PARTSTAT=\""];
      [ms appendString:state];
      [ms appendString:@"\""];
    }
    if (role != nil) {
      [ms appendString:@";ROLE=\""];
      [ms appendString:role];
      [ms appendString:@"\""];
    }

    [ms appendString:@";RSVP=\""];
    [ms appendString:[rsvp boolValue] ? @"TRUE" : @"FALSE"];
    [ms appendString:@"\""];

    if ([cn isNotEmpty]) {
      [ms appendString:@";CN=\""];
      [ms appendString:cn];
      [ms appendString:@"\""];
    }
    
    [self _appendName:ms andValue:[@"MAILTO:" stringByAppendingString:email]
          toICal:_iCal];
    [ms release]; ms = nil;
   
    // Create the ORGANIZER attribute from the current participant
    // if that participant is the creator of the appointment
    if (([companyId intValue] == [ownerId intValue]) &&
        ([companyId intValue] != 0)) {
      tmp = [[NSString alloc] initWithFormat:@"ORGANIZER;CN=\"%@\"", cn];
      [self _appendName:tmp
            andValue:   [@"MAILTO:" stringByAppendingString:email]
            toICal:_iCal];
      [tmp release]; tmp = nil;
    }
  }
  
  // TODO: add owner if it isn't a participant!
}

- (NSString *)_iCalForDate:(id)_date inContext:(id)_context {
  NSMutableString *iCal;

  iCal = [NSMutableString stringWithCapacity:32];
  [iCal appendString:@"BEGIN:VEVENT\r\n"];

  [self _appendCoreAptData:_date toICal:iCal];

  [self _appendAlarmData:_date toICal:iCal];
  [self _appendAttendees:_date toICal:iCal];
  
  [iCal appendString:@"END:VEVENT\r\n"];
  
  return iCal;
}


- (NSArray *)appointmentAttributes {
  static NSArray *aptAttributes = nil;

  if (aptAttributes == nil) {
    aptAttributes =
      [[NSArray alloc] initWithObjects:
                       @"dateId",             @"globalID",
                       @"title",              @"location",
                       @"startDate",          @"endDate",
                       @"cycleEndDate",       @"ownerId",
                       @"accessTeamId",       @"notificationTime",
                       @"type", /* repetition type */ @"title",
                       @"aptType",            @"resourceNames",
                       @"calendarName",       @"sourceUrl",
                       @"fbtype",             @"sensitivity",
                       @"busyType",           @"importance",
                       @"lastModified",       @"evoReminder",
                       @"olReminder",         @"keywords",
                       @"associatedContacts", @"objectVersion",
                       @"comment",            @"parentDateId", 
                       @"isConflictDisabled", nil];
  }
  return aptAttributes;
}

- (NSArray *)participantAttributes {
  static NSArray *partAttributes = nil;
  if (partAttributes == nil) {
    partAttributes =
      [[NSArray alloc] initWithObjects:
                       @"dateId",         @"companyId",
                       @"partStatus",     @"role",
                       @"comment",        @"rsvp",
                       
                       @"team.members",
                       @"team.companyId",
                       @"team.email",
                       @"team.description",
                       @"team.isTeam",
                       
                       @"person.globalID",
                       @"person.companyID",
                       @"person.firstname",
                       @"person.name",                       
                       @"person.extendedAttributes", // for email
                       
                       nil];
  }
  return partAttributes;
}

/* fetch appointments */
- (NSArray *)_fetchAppointmentsInContext:(id)_context {
  NSDictionary *participants;
  NSArray      *dates;
  
  dates =
    [_context runCommand:@"appointment::get-by-globalid",
              @"gids",         self->gids,
              @"attributes",   [self appointmentAttributes], nil];
  participants =
    [_context runCommand:@"appointment::list-participants",
              @"attributes",   [self participantAttributes],
              @"appointments", dates,
              @"groupBy",      @"dateId",
              nil];
  
  if ([participants count] > 0) {
    NSEnumerator *e;
    id apt;
    
    e = [dates objectEnumerator];
    while ((apt = [e nextObject]) != nil) {
      NSNumber *dateId;
      NSArray  *parts;
      
      dateId = [apt valueForKey:@"dateId"];
      parts  = [participants objectForKey:dateId];
      if (parts == nil) parts = [NSArray array];
      [apt takeValue:parts forKey:@"participants"];
    }
  }
  return dates;
}

/* execute */

- (void)_executeInContext:(id)_context {
  NSMutableArray *result;
  int cnt;
  
  if (self->apts == nil)
    self->apts = [[self _fetchAppointmentsInContext:_context] retain];
  else
    [self debugWithFormat:@"Note: appointments already fetched?"];
  
  if ((cnt = [self->apts count]) == 0) {
    [self setReturnValue:[NSArray array]];
    return;
  }

  result = [[NSMutableArray alloc] initWithCapacity:cnt];
    
  while (cnt--) {
    NSString *ical;
    id record;
    
    record = [self->apts objectAtIndex:cnt];
    
    if ((ical = [self _iCalForDate:record inContext:_context]) != nil) {
      [result addObject:ical];
    }
    else {
      [self errorWithFormat:@"failed building iCal for record: '%@'", 
	      record];
      [result addObject:[NSNull null]];
    }
  }
  
  [self setReturnValue:result];
  [result release]; result = nil;
}

/* accessors */

- (void)setGlobalIDs:(NSArray *)_gids {
  ASSIGN(self->gids,_gids);
}
- (NSArray *)globalIDs {
  return self->gids;
}

- (void)setGlobalID:(EOGlobalID *)_gid {
  [self setGlobalIDs:[NSArray arrayWithObject:_gid]];
}
- (EOGlobalID *)globalID {
  return [[self globalIDs] lastObject];
}

- (void)setAppointments:(NSArray *)_apts {
  ASSIGN(self->apts, _apts);
}
- (NSArray *)appointments {
  return self->apts;
}
- (void)setAppointment:(id)_apt {
  [self setAppointments:[NSArray arrayWithObject:_apt]];
}
- (id)appointment {
  return [[self appointments] lastObject];
}

/* key-value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"gid"])
    [self setGlobalID:_value];
  else if ([_key isEqualToString:@"gids"])
    [self setGlobalIDs:_value];
  else if (([_key isEqualToString:@"appointments"]) ||
           ([_key isEqualToString:@"dates"]) ||
           ([_key isEqualToString:@"objects"]))
    [self setAppointments:_value];
  else if (([_key isEqualToString:@"appointment"]) ||
           ([_key isEqualToString:@"date"]) ||
           ([_key isEqualToString:@"object"]))
    [self setAppointment:_value];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"gid"])
    return [self globalID];

  if ([_key isEqualToString:@"gids"])
    return [self globalIDs];

  if ([_key isEqualToString:@"appointments"] ||
      [_key isEqualToString:@"dates"] ||
      [_key isEqualToString:@"objects"])
    return [self appointments];
  if ([_key isEqualToString:@"appointment"] ||
      [_key isEqualToString:@"date"] ||
      [_key isEqualToString:@"object"])
    return [self appointment];

  return [super valueForKey:_key];
}

@end /* LSGetICalForAppointmentsCommand */
