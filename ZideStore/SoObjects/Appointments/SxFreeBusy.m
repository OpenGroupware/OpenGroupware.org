/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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
// $Id: SxFreeBusy.m 1 2004-08-20 11:17:52Z znek $

#include "SxFreeBusy.h"
#include "common.h"
#include "NSObject+ExValues.h"
#include <Backend/SxAptManager.h>
#include <Backend/SxFreeBusyManager.h>

#include <NGExtensions/NSCalendarDate+misc.h>
#include <EOControl/EOSortOrdering.h>
#include <LSFoundation/LSCommandContext.h>
#include <LSFoundation/LSCommandKeys.h>

@implementation SxFreeBusy

static NSArray *startDateOrdering = nil;

+ (void)initialize {
  EOSortOrdering *s;
  
  s = [EOSortOrdering sortOrderingWithKey:@"startDate"
                      selector:EOCompareAscending];
  startDateOrdering = [[NSArray alloc] initWithObjects:s, nil];
}

- (id)initWithName:(NSString *)_name inContainer:(id)_folder {
  return [self init];
}

/* accessors */

- (void)setUser:(NSString *)_user {
  ASSIGN(self->user,_user);
}
- (NSString *)user {
  return self->user;
}

- (void)setFormat:(NSString *)_format {
  ASSIGN(self->format,_format);
}
- (NSString *)format {
  return self->format;
}

- (NSString *)icalDateDescription:(NSCalendarDate *)_date {
  static NSString   *calfmt = @"%Y%m%dT%H%M00Z";
  static NSTimeZone *gmt = nil;
  if (gmt == nil)
    gmt = [[NSTimeZone timeZoneWithAbbreviation:@"GMT"] retain];
    
  [_date setTimeZone:gmt];
  return [_date descriptionWithCalendarFormat:calfmt];
}

- (void)appendICalProperty:(NSString *)_name
  value:(id)_value valueType:(NSString *)_valueType
  parameters:(NSDictionary *)_parameters
  toResponse:(id)_response inContext:(id)_ctx
  addCRLF:(BOOL)_addCRLF
{
  NSEnumerator *e;
  id           key, val;
  // add name
  [_response appendContentString:_name];

  // parameters
  e = [_parameters keyEnumerator];
  while ((key = [e nextObject])) {
    val = [_parameters objectForKey:key];
    if ([val length] > 0) {
      [_response appendContentString:@";"];
      [_response appendContentString:key];
      [_response appendContentString:@"="];
      [_response appendContentString:val];
    }
  }

  // add value
  [_response appendContentString:@":"];
  // check value type
  if ([_valueType length] == 0) {
    val = [_value stringValue];
  }
  else if ([_valueType isEqualToString:@"datetime"]) {
    if ([_value respondsToSelector:
                @selector(descriptionWithCalendarFormat:)]) {
      val = [self icalDateDescription:_value];
    }
    else
      val = [_value stringValue];
  }
  else
    val = [_value stringValue];

  [_response appendContentString:val];
  if (_addCRLF)
    [_response appendContentString:@"\r\n"];
}

- (void)_appendICalOrganizerAttribute:(NSString *)_email
  toResponse:(id)_response inContext:(id)_ctx
{
  // mh: hack!! (TODO: describe what the hack is?)
  if ([_email hasPrefix:@"SMTP:"])
    _email = [_email substringFromIndex:5];
  [self appendICalProperty:@"ORGANIZER"
        value:[@"MAILTO:" stringByAppendingString:[_email stringValue]]
        valueType:nil parameters:nil
        toResponse:_response
        inContext:_ctx
        addCRLF:YES];
}
- (void)_appendICalAttendeeAttribute:(NSString *)_email
  toResponse:(id)_response inContext:(id)_ctx
{
  // mh: hack!! (TODO: describe what the hack is?)
  if ([_email hasPrefix:@"SMTP:"])
    _email = [_email substringFromIndex:5];
  [self appendICalProperty:@"ATTENDEE"
        value:[@"MAILTO:" stringByAppendingString:[_email stringValue]]
        valueType:nil parameters:nil
        toResponse:_response
        inContext:_ctx
        addCRLF:YES];
}

- (void)_appendICalTimestampAttributeToResponse:(id)_response
  inContext:(id)_ctx
{
  [self appendICalProperty:@"DTSTAMP"
        value:[NSCalendarDate date]
        valueType:@"datetime" parameters:nil
        toResponse:_response
        inContext:_ctx
        addCRLF:YES];
}
- (void)_appendICalDate:(NSCalendarDate *)_start name:(NSString *)_name
  toResponse:(id)_response inContext:(id)_ctx
{
  [self appendICalProperty:_name
        value:_start
        valueType:@"datetime" parameters:nil
        toResponse:_response
        inContext:_ctx
        addCRLF:YES];
}

- (void)_appendICalFreeBusyDates:(NSArray *)_dates
  from:(NSCalendarDate *)_from to:(NSCalendarDate *)_to
  toResponse:(id)_response inContext:(id)_ctx
{
  static NSDictionary *parameters = nil;
  NSEnumerator *e;
  NSDictionary *para;
  id date;
  id dstart, dend;
  id fbtype;
  NSCalendarDate *lastEnddate;

  if (parameters == nil) {
    parameters =
      [NSDictionary dictionaryWithObjectsAndKeys:
                    @"BUSY", @"FBTYPE", nil];
    parameters = [parameters retain];
  }

  lastEnddate = _from;

  e = [_dates objectEnumerator];
  while ((date = [e nextObject])) {  
    dstart = [date valueForKey:@"startDate"];
    dend   = [date valueForKey:@"endDate"];

    fbtype = [date valueForKey:@"fbtype"];
    if ([fbtype isNotNull]) {
      para = [NSDictionary dictionaryWithObject:fbtype forKey:@"FBTYPE"];
    }
    else
      para = parameters;

    date = [NSString stringWithFormat:@"%@/%@",
                     [self icalDateDescription:dstart],
                     [self icalDateDescription:dend]];

    [self appendICalProperty:@"FREEBUSY"
          value:date
          valueType:nil parameters:para
          toResponse:_response
          inContext:_ctx
          addCRLF:YES];

    if ([lastEnddate laterDate:dend] == dend)
      lastEnddate = dend;
  }
#if 0
  // outlook doesn't seem to handle any FBTYPES,
  // all is shown as BUSY
  if ([_to laterDate:lastEnddate] == _to) {
    para = [NSDictionary dictionaryWithObject:@"FREE" forKey:@"FBTYPE"];
    date = [NSString stringWithFormat:@"%@/%@",
                     [self icalDateDescription:lastEnddate],
                     [self icalDateDescription:_to]];
    [self appendICalProperty:@"FREEBUSY"
          value:date
          valueType:nil parameters:para
          toResponse:_response
          inContext:_ctx
          addCRLF:YES];
  }
#endif
}

- (void)appendICalDates:(NSArray *)_dates
  startDate:(NSCalendarDate *)_start endDate:(NSCalendarDate *)_end
  email:(NSString *)_email
  toResponse:(id)_response inContext:(id)_ctx
{
  [_response appendContentString:
             @"BEGIN:VCALENDAR\r\n"
             @"VERSION:2.0\r\n"
             @"PRODID:-//OpenGroupware.org/ZideStore/appointments v.1.2//\r\n"
             @"BEGIN:VFREEBUSY\r\n"];
  
  [self _appendICalOrganizerAttribute:_email
        toResponse:_response inContext:_ctx];
  [self _appendICalAttendeeAttribute:_email
        toResponse:_response inContext:_ctx];
  [self _appendICalTimestampAttributeToResponse:_response
        inContext:_ctx];
  [self _appendICalDate:_start name:@"DTSTART"
        toResponse:_response inContext:_ctx];
  [self _appendICalDate:_end   name:@"DTEND"
        toResponse:_response inContext:_ctx];
  [self _appendICalFreeBusyDates:_dates
        from:_start to:_end
        toResponse:_response inContext:_ctx];

  [_response appendContentString:
             @"END:VFREEBUSY\r\n"
             @"END:VCALENDAR\r\n"];
}

- (void)_appendXMLDates:(NSArray *)_dates
  startDate:(NSCalendarDate *)_start endDate:(NSCalendarDate *)_end
  options:(NSDictionary *)_opts
  toResponse:(id)_response inContext:(id)_ctx
{
  NSMutableSet *activeDates = [NSMutableSet setWithCapacity:8];
  int interval;

  unsigned max, i;
  id date;
  NSCalendarDate *start, *end, *cur, *curEnd;

  interval = [[_opts objectForKey:@"interval"] intValue];
  if (interval < 10) interval = 30; // minutes

#if 0
  if (![_dates count]) {
    [_response appendContentString:@"c"];
    return;
  }
#endif

  max    = [_dates count];
  cur    = _start;
  i      = 0;

  while (([_end earlierDate:cur] == cur) && (![_end isEqual:cur])) {
    // end of period
    curEnd = [cur dateByAddingYears:0 months:0 days:0
                  hours:0 minutes:interval seconds:0];
    // check active dates
    if ([activeDates count]) {
      NSEnumerator *e = [[activeDates allObjects] objectEnumerator];

      while ((date = [e nextObject])) {
        start = [date objectForKey:@"startDate"];
        end   = [date objectForKey:@"endDate"];

        if (([start earlierDate:curEnd] == curEnd) ||
            ([start isEqual:curEnd]) ||
            ([end earlierDate:cur] == end) ||
            ([end isEqual:cur])) {
          // start after end of period or ends before start of period
          [activeDates removeObject:date];
        }
      }
    }
    
    // fill active dates
    for (; i < max; i++) {
      date  = [_dates objectAtIndex:i];
      start = [date objectForKey:@"startDate"];
      end   = [date objectForKey:@"endDate"];

      if (([start laterDate:curEnd] == curEnd) &&
          ([end laterDate:cur] == end)) {
        // start before end of period or ends after start of period
        [activeDates addObject:date];
      }
      else {
        // stop filling activeDates
        break;
      }
    }

    if ([activeDates count]) {
      id busyType = [[activeDates anyObject] valueForKey:@"busyType"];
      if ([busyType isNotNull])
        busyType = [busyType stringValue];
      else
        busyType = @"2"; // BUSY
      // here do more stuff for other busy types
      [_response appendContentString:busyType]; 
    }
    else {
      [_response appendContentString:@"0"]; // FREE
    }

    // next date
    cur    = curEnd;
  }
}
  

- (void)appendXMLDates:(NSArray *)_dates
  startDate:(NSCalendarDate *)_start endDate:(NSCalendarDate *)_end
  email:(NSString *)_email options:(NSDictionary *)_opts
  toResponse:(id)_response inContext:(id)_ctx
{

  if ([_email hasPrefix:@"SMPT:"])
    _email = [_email substringFromIndex:5];

  [_response appendContentString:
             @"<a:response xmlns:a=\"WM\">\r\n"
             @"  <a:recipient>\r\n"
             @"    <a:item><a:displayname>"];
  [_response appendContentString:_email];
  [_response appendContentString:@"</a:displayname>"];
  [_response appendContentString:@"<a:email type=\"SMTP\">"];
  [_response appendContentString:_email];
  [_response appendContentString:@"</a:email>"];
  [_response appendContentString:@"<a:type>1</a:type>"];

  
  [_response appendContentString:@"<a:fbdata>"];

  [self _appendXMLDates:_dates
        startDate:_start
        endDate:_end
        options:_opts
        toResponse:_response inContext:_ctx];

  [_response appendContentString:
             @"</a:fbdata></a:item>\r\n"
             @"  </a:recipients>\r\n"
             @"</a:response>"];
}

#if 0
- (SxAptManager *)aptManagerInContext:(id)_ctx {
  return [SxAptManager managerWithContext:[self commandContextInContext:_ctx]];
}
#endif
- (SxFreeBusyManager *)freeBusyManager {
  return [SxFreeBusyManager freeBusyManager];
}

- (NSCalendarDate *)defaultStartDate {
  return [[NSCalendarDate date] dateByAddingYears:0 months:-2 days:0];
}
- (NSCalendarDate *)defaultEndDate {
  return [[NSCalendarDate date] dateByAddingYears:0 months:2 days:0];
}

- (NSString *)defaultEmailWithContext:(id)_ctx {
  id cmdctx;
  id login;

  cmdctx = [self commandContextInContext:_ctx];
  if (cmdctx != nil) {
    login  = [cmdctx valueForKey:LSAccountKey];
    login  = [[cmdctx runCommand:@"person::get",
                      @"companyId", [login valueForKey:@"companyId"],
                      nil] lastObject];
    return [login valueForKey:@"email1"];
  }
  return nil;
}

- (id)GETAction:(id)_ctx {
  /*
    Query Parameter:
      start
      end
      u
      interval
      format
      server   - Outlook
      name     - Outlook
  */
  WORequest      *request;
  WOResponse     *response;
  NSCalendarDate *from, *to;
  NSArray  *dates;
  NSString *usr, *fmt, *val;
  id       interval;
  
  request = [(WOContext *)_ctx request];
  
  val  = [request formValueForKey:@"start"];
  from = [NSCalendarDate dateWithExDavString:val];
  val  = [request formValueForKey:@"end"];
  to   = [NSCalendarDate dateWithExDavString:val];
  if (from == nil) from = [self defaultStartDate];
  if (to == nil)   to   = [self defaultEndDate];
  
  usr      = [request formValueForKey:@"u"];
  interval = [request formValueForKey:@"interval"];
  fmt      = [request formValueForKey:@"format"];
  
  if ([usr length] == 0) {
    // for outlook default url:
    // http://my.zidestore.de:80/exchange/so/m/public/freebusy?
    // name=%NAME%&server=%SERVER%
    NSString *name, *server;
    
    name   = [request formValueForKey:@"name"];
    server = [request formValueForKey:@"server"];
    
    if ([server length] > 0 && [name length] > 0) {
      usr = [NSString stringWithFormat:@"%@@%@", name, server];
      fmt = @"vfb";
    }
  }
  
  if ([fmt length] == 0) {
    fmt = self->format;
    if ([fmt length] == 0)
      fmt = @"xml";
  }
  
  if ([usr length] == 0) usr = self->user;
  if ([usr length] == 0) usr = [self defaultEmailWithContext:_ctx];
  
  if (from == nil || to == nil || usr == nil) {
    WOResponse *response = [(WOContext *)_ctx response];
    [response setStatus:400]; /* bad request */
    if (from == nil) [response appendContentString:@"got no start date !\n"];
    if (to   == nil) [response appendContentString:@"got no end date !\n"];
    if (usr  == nil) [response appendContentString:@"got no user-key !\n"];
    return response;
  }
  
  /* todo generate freebusy entries */
#if 0
  dates = [[self aptManagerInContext:_ctx] 
                 freeBusyDataForUser:usr
                 from:from to:to];
#else
  dates = [[self freeBusyManager]
                 freeBusyDataForEmail:usr
                 from:from to:to];
#endif

  if ([dates isKindOfClass:[NSException class]]) {
    return dates;
  }
  else if (dates == nil) {
    WOResponse *response = [(WOContext *)_ctx response];
    [response setStatus:400]; /* bad request */
    [response appendContentString:@"got no result for freebusy request"];
    [self logWithFormat:@"bad freebusy request: from:%@ to:%@ user:%@",
            from, to , usr];
    return response;
  }
  
  dates    = [dates sortedArrayUsingKeyOrderArray:startDateOrdering];
  response = [(WOContext *)_ctx response];
  
  if ([fmt isEqualToString:@"iCal"] ||
      [fmt isEqualToString:@"ics"]  ||
      [fmt isEqualToString:@"vfb"]) {
    /* do ical */
    
    [response setHeader:@"text/calendar"
              forKey:@"content-type"];
    
#if 0 /* what about that ? required or not ? */
    [response setHeader:@"inline; filename=freebusy.cvs"
              forKey:@"content-disposition"];
#endif
    [self appendICalDates:dates
          startDate:from endDate:to email:usr
          toResponse:response inContext:_ctx];
  }
  else {
    /* do xml */
    [response setHeader:@"text/html" forKey:@"content-type"];

    [self appendXMLDates:dates
          startDate:from endDate:to email:usr
          options:[NSDictionary dictionaryWithObjectsAndKeys:
                                  interval, @"interval", nil]
          toResponse:response inContext:_ctx];
  }
  
  return response;
}

@end /* SxFreeBusy */
