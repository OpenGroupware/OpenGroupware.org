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


#include <LSFoundation/LSDBObjectBaseCommand.h>

/*
  This command fetches iCalenderStrings for globalIDs (Date)
  date-objects can also be set directly.
  It doesn't cache anything 'till now.
  Just fetches the dates and builds the iCal-Strings
  @see: rfc 2445
*/

@interface LSGetICalForAppointmentsCommand : LSDBObjectBaseCommand
{
  NSArray *apts;
  NSArray *gids;
}

@end

#include "common.h"
#include <NGObjWeb/WOResponse.h>

@implementation LSGetICalForAppointmentsCommand

static NSString   *iCalDateFmt   = @"%Y%m%dT%H%M%SZ";
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
  // some loosy comma check
  int cnt = 0;
  int i, len;
  unichar c;

  len = [_str length];
  for (i = 0; i < len; i++) {
    c = [_str characterAtIndex:i];
    if (c == ',' || c == ';' || c == '\n') cnt++;
  }

  if (cnt) {
    unichar *newStr;
    
    newStr = calloc(len+cnt+1, sizeof(unichar));
    cnt = 0;
    for (i = 0; i < len; i++) {
      c = [_str characterAtIndex:i];
      if (c == ',' || c == ';') {
        newStr[i+cnt] = '\\';
        cnt++;
      }
      else if (c == '\n') {
        newStr[i+cnt] = '\\';
        cnt++;
        c = 'n';
      }
      newStr[i+cnt] = c;
    }
    newStr[i] = 0;
    _str = [NSString stringWithCharacters:newStr length:len+cnt];
    if (newStr) free(newStr); newStr = NULL;
  }
  [_iCal appendString:_str];
}

- (void)_appendDateValue:(NSCalendarDate *)_date toICal:(NSMutableString*)_s {
  [_date setTimeZone:gmt];
  [_s appendString:[_date descriptionWithCalendarFormat:iCalDateFmt]];
}

- (void)_appendName:(NSString *)_name andValue:(id)_value 
  toICal:(NSMutableString *)_iCal
{
  [_iCal appendString:_name];
  [_iCal appendString:@":"];
  if ([_value isKindOfClass:[NSArray class]]) {
    int cnt, i;
    for (i = 0, cnt = [_value count]; i < cnt; i++)
      [self _appendTextValue:[_value objectAtIndex:i] toICal:_iCal];
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
  NSString *str;
  str = [NSString stringWithFormat:@"%04d%02d%02d",
                  [_date yearOfCommonEra],
                  [_date monthOfYear],
                  [_date dayOfMonth]];
  [self _appendName:_name andValue:str toICal:_iCal];
}

- (NSString *)skyrixIdUrl:(id)_plainId {
  return [skyrixId stringByAppendingFormat:@"%@", _plainId];
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

- (void)_appendCoreAptData:(id)_date toICal:(NSMutableString *)_iCal {
  // CATEGORIES, CLASS, COMMENT, DESCRIPTION, LOCATION,
  // PRIORITY, RESOURCES, STATUS, SUMMARY, DTEND, DTSTART,
  // TRANSP, RELATED-TO, UID,
  // CREATED, DTSTAMP, LAST-MODIFIED, SEQUENCE
  NSString *tmp;

  if ([(tmp = [[_date valueForKey:@"keywords"] stringValue]) length] > 0)
    [self _appendName:@"CATEGORIES" andValue:tmp toICal:_iCal];
  
  /* class */
  tmp = ([(tmp = [_date valueForKey:@"accessTeamId"]) isNotNull])
    ? @"PUBLIC"
    : @"PRIVATE";
  [self _appendName:@"CLASS" andValue:tmp toICal:_iCal];
  
  if ([(tmp = [[_date valueForKey:@"location"] stringValue]) length])
    [self _appendName:@"LOCATION" andValue:tmp toICal:_iCal];
  
  if ([(tmp = [[_date valueForKey:@"importance"] stringValue]) length] > 0)
    [self _appendName:@"PRIORITY" andValue:tmp toICal:_iCal];
  
  if ([(tmp = [[_date valueForKey:@"resourceNames"] stringValue]) length] > 0)
    [self _appendName:@"RESOURCES" andValue:tmp toICal:_iCal];
  
  [self _appendName:@"STATUS" andValue:@"CONFIRMED" toICal:_iCal];
  
  if ([(tmp = [[_date valueForKey:@"title"] stringValue]) length] > 0)
    [self _appendName:@"SUMMARY" andValue:tmp toICal:_iCal];
  
  // COMMENT
  // DESCRIPTION
  if ([(tmp = [[_date valueForKey:@"comment"] stringValue]) length] > 0)
    [self _appendName:@"DESCRIPTION" andValue:tmp toICal:_iCal];

  {
    NSCalendarDate *start;
    NSCalendarDate *end;
    start = [_date valueForKey:@"startDate"];
    end   = [_date valueForKey:@"endDate"];
    if (([start hourOfDay] == 0) &&
        ([start minuteOfHour] == 0) &&
        ([end hourOfDay] == 23) &&
        ([end minuteOfHour] == 59)) {
      // all day apt
      end = [[end tomorrow] beginOfDay];
    if ([end isNotNull]) 
      [self _appendName:@"DTEND" andTimelessDate:end toICal:_iCal];
    if ([start isNotNull])
      [self _appendName:@"DTSTART" andTimelessDate:start toICal:_iCal];
    }
    else {
      if ([end isNotNull]) 
        [self _appendName:@"DTEND" andValue:end toICal:_iCal];
      if ([start isNotNull])
        [self _appendName:@"DTSTART" andValue:start toICal:_iCal];
    }
    
  }

  [self _appendName:@"TRANSP" andValue:@"OPAQUE" toICal:_iCal];
  
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

  // X attributes
  if (![(tmp = [_date valueForKey:@"importance"]) isNotNull]) tmp = @"0";
  [self _appendName:@"X-MICROSOFT-CDO-IMPORTANCE" andValue:tmp toICal:_iCal];
  if (![(tmp = [_date valueForKey:@"fbtype"]) isNotNull])     tmp = @"BUSY";
  [self _appendName:@"X-MICROSOFT-CDO-BUSYSTATUS" andValue:tmp toICal:_iCal];
  [_iCal appendString:@"X-MICROSOFT-CDO-INSTTYPE:0\r\n"];
  [_iCal appendString:@"X-MICROSOFT-CDO-ALLDAYEVENT:FALSE\r\n"];
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

    alarm   = [NSMutableDictionary dictionaryWithCapacity:4];
    trigger = [NSMutableDictionary dictionaryWithCapacity:2];
    attach  = [NSMutableDictionary dictionaryWithCapacity:2];

    // action
    // comment
    // trigger-type
    // trigger-value
    // attach-type
    // attach-value
    while ((numColumns > k) && (k < 6)) {
      tmp = [self checkCSVEntry:[columns objectAtIndex:k]];
      if ([tmp length]) {
        switch (k) {
          case 0: case 1:
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

    if ((tmp = [alarm objectForKey:@"trigger"])) {
      id v  = [tmp valueForKey:@"value"];
      id vt = [tmp valueForKey:@"valueType"];
      [self _appendName:(vt != nil)
            ? [NSString stringWithFormat:@"TRIGGER;VALUE=%@;RELATED=START",
                        [vt uppercaseString]]
            : @"TRIGGER;RELATED=START"
            andValue:v toICal:_iCal];
    }

    if ((tmp = [alarm objectForKey:@"attachment"])) {
      id v  = [tmp valueForKey:@"value"];
      id vt = [tmp valueForKey:@"valueType"];
      [self _appendName:(vt != nil)
            ? [NSString stringWithFormat:@"ATTACH;VALUE=%@", vt]
            : @"ATTACH"
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

- (void)_appendAttendees:(id)_date toICal:(NSMutableString *)_iCal {
  // ATTENDEE, ORGANIZER
  //
  NSArray *parts;
  id participant;
  int cnt, i;
  id ownerId;

  parts   = [_date valueForKey:@"participants"];
  ownerId = [_date valueForKey:@"ownerId"];
    
  cnt = [parts count];
  for (i = 0; i < cnt; i++) { 
    id   role, rsvp, cn, email, state;
    id   companyId;
    BOOL isTeam;

    participant = [parts objectAtIndex:i];
    role      = [participant valueForKey:@"role"];
    isTeam    = [[participant valueForKey:@"isTeam"] boolValue];
    rsvp      = [participant valueForKey:@"rsvp"];
    state     = [participant valueForKey:@"partStatus"];
    companyId = [participant valueForKey:@"companyId"];

    if (isTeam) {
      cn    = [participant valueForKey:@"description"];
      email = [participant valueForKey:@"email"];
      if (![email length]) email = cn;
    }
    else {
      NSString *tmp;
      
      if ((tmp = [participant valueForKey:@"firstname"]) != nil)
        cn = [tmp stringByAppendingString:@" "];
      else
        cn = @"";

      if ((tmp = [participant valueForKey:@"name"]) != nil)
        cn = [cn stringByAppendingString:tmp];
      
      if ([cn length] == 0) cn = @"No Name";
    
      email = ((tmp = [participant valueForKey:@"email1"]) != nil)
        ? tmp : cn;
    }

    [self _appendName:
          [NSString stringWithFormat:
                    @"ATTENDEE;CUTYPE=\"%@\";PARTSTAT=\"%@\""
                    @";ROLE=\"%@\";RSVP=\"%@\";CN=\"%@\"",
                    isTeam               ? @"GROUP" : @"INDIVIDUAL",
                    ([state length] > 0) ? state    : @"NEEDS-ACTION",
                    ([role length] > 0)  ? role     : @"OPT-PARTICIPANT",
                    [rsvp boolValue]     ? @"TRUE"  : @"FALSE",
                    cn]
          andValue:[NSString stringWithFormat:@"MAILTO:%@", email]
          toICal:_iCal];
    
    if (([companyId intValue] == [ownerId intValue]) &&
        ([companyId intValue] != 0)) 
      [self _appendName:[NSString stringWithFormat:@"ORGANIZER;CN=\"%@\"", cn]
            andValue:   [NSString stringWithFormat:@"MAILTO:%@", email]
            toICal:_iCal];
  }
    
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
                       nil];
  }
  return aptAttributes;
}

- (NSArray *)particpantAttributes {
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
              @"attributes",   [self particpantAttributes],
              @"appointments", dates,
              @"groupBy",      @"dateId",
              nil];
  if ([participants count]) {
    NSEnumerator *e;
    id apt;
    e = [dates objectEnumerator];
    while ((apt = [e nextObject])) {
      id dateId = [apt valueForKey:@"dateId"];
      id parts  = [participants valueForKey:dateId];
      if (parts == nil) parts = [NSArray array];
      [apt takeValue:parts forKey:@"participants"];
    }
  }
  return dates;
}

/* execute */

- (void)_executeInContext:(id)_context {
  int     cnt;

  if (self->apts == nil) {
    self->apts = [[self _fetchAppointmentsInContext:_context] retain];
  }

  if ((cnt = [self->apts count])) {
    NSMutableArray *result;
    id record;

    result    = [[NSMutableArray alloc] initWithCapacity:cnt];

    while (cnt--) {
      record = [self->apts objectAtIndex:cnt];
      record = [self _iCalForDate:record inContext:_context];
      if (record) [result addObject:record];
      else {
        NSLog(@"%s: failed building iCal for record: %@", record);
      }
    }
    
    [self setReturnValue:result];
    [result release];
  }
  else
    [self setReturnValue:[NSArray array]];
}

// accessors

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

- (void)takeValue:(id)_value forKey:(id)_key {
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

- (id)valueForKey:(id)_key {
  id v;
  
  if ([_key isEqualToString:@"gid"])
    v = [self globalID];
  else if ([_key isEqualToString:@"gids"])
    v = [self globalIDs];
  else if (([_key isEqualToString:@"appointments"]) ||
           ([_key isEqualToString:@"dates"]) ||
           ([_key isEqualToString:@"objects"]))
    v = [self appointments];
  else if (([_key isEqualToString:@"appointment"]) ||
           ([_key isEqualToString:@"date"]) ||
           ([_key isEqualToString:@"object"]))
    v = [self appointment];
  else 
    v = [super valueForKey:_key];
  
  return v;
}

@end /* LSGetICalForAppointmentsCommand */
