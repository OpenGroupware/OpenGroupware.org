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

#include "SoWCAPRenderer.h"
#include "WCAPResultSet.h"
#include <NGObjWeb/WOResponse.h>
#include <NGObjWeb/SoObjects.h>
#include "WCAPEvent.h"
#include "WCAPToDo.h"
#include <NGiCal/iCalPerson.h>
#include "common.h"

@interface WOResponse(WCAPTags)

- (void)addWCAPXmlTag:(NSString *)_tag     value:(NSString *)_value;
- (void)addWCAPPrefXmlTag:(NSString *)_tag value:(NSString *)_value;
- (void)addNSCPXmlTag:(NSString *)_tag     value:(NSString *)_value;

@end

@implementation SoWCAPRenderer

static NSTimeZone *gmt = nil;

+ (void)initialize {
  gmt = [[NSTimeZone timeZoneWithAbbreviation:@"GMT"] retain];
}

+ (id)sharedRenderer {
  static SoWCAPRenderer *renderer = nil;
  if (renderer == nil)
    renderer = [[self alloc] init];
  return renderer;
}

- (void)dealloc {
  [super dealloc];
}

/* renderer */

- (NSString *)zsProductID {
  return @"-//OpenGroupware.org/ZideStore Integration Server//EN";
}

- (NSString *)formatDate:(NSDate *)_date {
  NSCalendarDate *caldate;
  NSString *s;

  if (_date == nil) return nil;
  caldate = [[NSCalendarDate alloc] initWithTimeIntervalSince1970:
                                      [_date timeIntervalSince1970]];
  [caldate setTimeZone:gmt];
  
  // eg: '20030602T190000Z'
  s = [NSString stringWithFormat:@"%02i%02i%02iT%02i%02i%02iZ",
                [caldate yearOfCommonEra],
                [caldate monthOfYear],
                [caldate dayOfMonth],
                [caldate hourOfDay],
                [caldate minuteOfHour],
                [caldate secondOfMinute]
  ];
  [caldate release];
  return s;
}

- (NSException *)renderCheckIDInXML:(id)_cid inContext:(WOContext *)_ctx {
  WOResponse *r = [_ctx response];
  
  [r addWCAPXmlTag:@"CHECK-ID" value:[_cid boolValue] ? @"1" : @"0"];
  return nil;
}

- (NSException *)renderUserPrefsInXML:(id)_prefs inContext:(WOContext *)_ctx {
  WOResponse *r = [_ctx response];
  id user;
  NSDictionary *prefs, *sprefs;
  NSEnumerator *e;
  NSString *key;

  prefs  = [_prefs valueForKey:@"preferences"];
  sprefs = [_prefs valueForKey:@"server-preferences"];
  
  user = [[_ctx session] valueForKey:@"SoUser"];
  [self logWithFormat:@"active user: %@", user];
  
  [r addWCAPXmlTag:@"ERRNO" value:@"0"];
  
  e = [prefs keyEnumerator];
  while ((key = [e nextObject]))
    [r addWCAPPrefXmlTag:key value:[prefs valueForKey:key]];
  
  [r addWCAPPrefXmlTag:@"icsSet" 
     value:
       @"name=mygroup$calendar=lucy\\;jjones\\;jdoe"
       @"TimeZone$tzmode=specify$tz=America/Denver$mergeInDayView=true"
       @"$description="];
  
  /* server prefs */
  e = [sprefs keyEnumerator];
  while ((key = [e nextObject])) {
    [r addWCAPXmlTag:[@"SERVER-PREF-" stringByAppendingString:key]
       value:[sprefs valueForKey:key]];
  }
  
  return nil;
}

- (NSException *)renderSessionInXML:(WOSession *)_session 
  inContext:(WOContext *)_ctx 
{
  WOResponse *r = [_ctx response];
  NSString   *fRefresh;
  id user;
  
  /* 0: full-info, 1: session-info */
  fRefresh = [[_ctx request] formValueForKey:@"refresh"];
  if (fRefresh == nil) fRefresh = @"1";
  
  user = [_session valueForKey:@"SoUser"];
  [self logWithFormat:@"active user: %@", user];
  
  [r addWCAPXmlTag:@"ERRNO"      value:@"0"];
  [r addWCAPXmlTag:@"SESSION-ID" value:[_session sessionID]];
  
  if ((user = [_session valueForKey:@"SoUser"])) {
    [r addWCAPXmlTag:@"USER-ID"     value:[user login]];
    [r addWCAPXmlTag:@"CALENDAR-ID" 
       value:[[user login] stringByAppendingString:@"/Calendar"]];
  }
  else
    [self logWithFormat:@"WARNING: no user stored in WCAP session ?"];
  return nil;
}

- (NSException *)_renderCalPropsInXML:(NSDictionary *)_ps 
  inContext:(WOContext *)_ctx 
{
  WOResponse *r = [_ctx response];
  
  [r addNSCPXmlTag:@"CALPROPS-LAST-MODIFIED"  value:@"20021208T005613Z"];
  [r addNSCPXmlTag:@"CALPROPS-CREATED"        value:@"20020913T223336Z"];
  [r addNSCPXmlTag:@"CALPROPS-READ"           value:@"999"];
  [r addNSCPXmlTag:@"CALPROPS-WRITE"          value:@"999"];
  [r addNSCPXmlTag:@"CALPROPS-RELATIVE-CALID" value:@"jdoe"];
  [r addNSCPXmlTag:@"CALPROPS-NAME"           value:@"John Doe"];
  [r addNSCPXmlTag:@"CALPROPS-LANGUAGE"       value:@"en"];
  [r addNSCPXmlTag:@"CALPROPS-PRIMARY-OWNER"  value:@"jdoe"];
  [r addNSCPXmlTag:@"CALPROPS-TZID"           value:@"Europe/Berlin"];
  [r addNSCPXmlTag:@"CALPROPS-RESOURCE"       value:@"0"];
  
  /* ACL */
  [r addNSCPXmlTag:@"CALPROPS-ACCESS-CONTROL-ENTRY" value:@"@@o^c^WDEIC^g"];
  [r addNSCPXmlTag:@"CALPROPS-ACCESS-CONTROL-ENTRY" value:@"@@o^a^RSF^g"];
  [r addNSCPXmlTag:@"CALPROPS-ACCESS-CONTROL-ENTRY" value:@"@^a^frs^g"];
  [r addNSCPXmlTag:@"CALPROPS-ACCESS-CONTROL-ENTRY" value:@"@^c^^g"];
  [r addNSCPXmlTag:@"CALPROPS-ACCESS-CONTROL-ENTRY" value:@"lucy^a^frs^"];
  [r addNSCPXmlTag:@"CALPROPS-ACCESS-CONTROL-ENTRY" value:@"lucy^c^dw^g"];
  [r addNSCPXmlTag:@"CALPROPS-ACCESS-CONTROL-ENTRY" value:@"jjones^a^rs^g"];
  [r addNSCPXmlTag:@"CALPROPS-ACCESS-CONTROL-ENTRY" value:@"jjones^c^w^g"];
  [r addNSCPXmlTag:@"CALPROPS-ACCESS-CONTROL-ENTRY" value:@"@^p^r^g"];
  [r addNSCPXmlTag:@"CALPROPS-ACCESS-CONTROL-ENTRY" value:@"lucy^p^r^g"];
  [r addNSCPXmlTag:@"CALPROPS-ACCESS-CONTROL-ENTRY" value:@"jjones^p^r^g"];
  return nil;
}

- (NSException *)renderEventInXML:(WCAPEvent *)_event
                        inContext:(WOContext *)_ctx {
  WOResponse     *r = [_ctx response];
  NSCalendarDate *now;
  id             tmp;
  
  now = [NSCalendarDate calendarDate];

  [r appendContentString:@"<EVENT>\n"];

#if 1
  if (_event == nil) {
    NSCalendarDate *start, *end;
    NSString       *orgEMail, *orgUID;
    
    orgEMail = @"hh@skyrix.com";
    orgUID   = @"helge";
  

    /* iCal standard info */  
    [r appendContentString:@"<UID>"];
    [r appendContentString:@"3c11625900005ffe00000011000010b7"];
    [r appendContentString:@"</UID>\n"];

    [r appendContentString:@"<DTSTAMP>"];
    [r appendContentString:[self formatDate:now]];
    [r appendContentString:@"</DTSTAMP>\n"];
    [r appendContentString:@"<CREATED>"];
    [r appendContentString:[self formatDate:now]];
    [r appendContentString:@"</CREATED>\n"];
    [r appendContentString:@"<LAST-MOD>"];
    [r appendContentString:[self formatDate:now]];
    [r appendContentString:@"</LAST-MOD>\n"];
  
    [r appendContentString:@"<SUMMARY>"];
    [r appendContentString:@"blahblahblah"];
    [r appendContentString:@"</SUMMARY>\n"];
  
    [r appendContentString:@"<PRIORITY>0</PRIORITY>\n"];
    [r appendContentString:@"<SEQUENCE>0</SEQUENCE>\n"];
    [r appendContentString:@"<STATUS>CONFIRMED</STATUS>\n"];
    [r appendContentString:@"<TRANSP>OPAQUE</TRANSP>\n"];

    start = now;
    end   = [start dateByAddingYears:0 months:0 days:0
                   hours:0 minutes:45 seconds:0];
    [r appendContentString:@"<START>"];
    [r appendContentString:[self formatDate:start]];
    [r appendContentString:@"</START>\n"];
    [r appendContentString:@"<END>"];
    [r appendContentString:[self formatDate:end]];
    [r appendContentString:@"</END>\n"];
  
    [r appendContentString:@"<ORGANIZER SENT-BY=\""];
    [r appendContentString:orgEMail];
    [r appendContentString:@"\" X-NSCP-ORGANIZER-UID=\""];
    [r appendContentString:orgUID];
    [r appendContentString:@"\">"];
    [r appendContentString:orgUID];
    [r appendContentString:@"</ORGANIZER>\n"];
    /*
      ORGANIZER;SENT-BY="jdoe@sesta.com"
      ;X-NSCP-ORGANIZER-UID=jdoe
      ;X-NSCP-ORGANIZER-SENT-BY-UID=jdoe:jdoe
      ATTENDEE;ROLE=REQ-PARTICIPANT;CUTYPE=INDIVIDUAL;PARTSTAT=ACCEPTED;
      CN="John Smith";RSVP=TRUE;X-NSCP-ATTENDEE-GSE-STATUS=2:jsmith
    */
  
    /* Alarms */
    /*
      BEGIN:VALARM
      ACTION:EMAIL
      TRIGGER;VALUE=DATE-TIME:20011225T123000Z
      ATTENDEE:MAILTO:jsmith@company22.com
      END:VALARM
    */
    
  }
  else {
#endif

    iCalPerson *organizer = [_event organizer];  

    /* iCal standard info */  
    [r appendContentString:@"<UID>"];
    [r appendContentString:[_event uid]];
    [r appendContentString:@"</UID>\n"];

    [r appendContentString:@"<DTSTAMP>"];
    [r appendContentString:[self formatDate:now]];
    [r appendContentString:@"</DTSTAMP>\n"];
    [r appendContentString:@"<CREATED>"];
    [r appendContentString:[self formatDate:now]];
    [r appendContentString:@"</CREATED>\n"];
    [r appendContentString:@"<LAST-MOD>"];
    [r appendContentString:[self formatDate:now]];
    [r appendContentString:@"</LAST-MOD>\n"];
  
    [r appendContentString:@"<SUMMARY>"];
    [r appendContentString:[_event summary]];
    [r appendContentString:@"</SUMMARY>\n"];

    tmp = [_event priority];
    if (![tmp length]) tmp = @"0";
    [r appendContentString:@"<PRIORITY>"];
    [r appendContentString:tmp];
    [r appendContentString:@"</PRIORITY>\n"];
    
    tmp = [_event sequence];
    if (![tmp length]) tmp = @"0";
    [r appendContentString:@"<SEQUENCE>"];
    [r appendContentString:tmp];
    [r appendContentString:@"</SEQUENCE>\n"];
    
    [r appendContentString:@"<STATUS>CONFIRMED</STATUS>\n"];
    [r appendContentString:@"<TRANSP>OPAQUE</TRANSP>\n"];

    [r appendContentString:@"<START>"];
    [r appendContentString:[self formatDate:[_event startDate]]];
    [r appendContentString:@"</START>\n"];
    [r appendContentString:@"<END>"];
    [r appendContentString:[self formatDate:[_event endDate]]];
    [r appendContentString:@"</END>\n"];
  
    tmp = [organizer email];
    if (![tmp length]) tmp = @"no-email@no-server";
    [r appendContentString:@"<ORGANIZER SENT-BY=\""];
    [r appendContentString:tmp];
    [r appendContentString:@"\" X-NSCP-ORGANIZER-UID=\""];
    tmp = [organizer xuid];
    if (![tmp length]) tmp = @"no-xuid";
    [r appendContentString:tmp];
    [r appendContentString:@"\">"];
    [r appendContentString:tmp];
    [r appendContentString:@"</ORGANIZER>\n"];
    /*
      ORGANIZER;SENT-BY="jdoe@sesta.com"
      ;X-NSCP-ORGANIZER-UID=jdoe
      ;X-NSCP-ORGANIZER-SENT-BY-UID=jdoe:jdoe
      ATTENDEE;ROLE=REQ-PARTICIPANT;CUTYPE=INDIVIDUAL;PARTSTAT=ACCEPTED;
      CN="John Smith";RSVP=TRUE;X-NSCP-ATTENDEE-GSE-STATUS=2:jsmith
    */
  
    /* Alarms */
    /*
      BEGIN:VALARM
      ACTION:EMAIL
      TRIGGER;VALUE=DATE-TIME:20011225T123000Z
      ATTENDEE:MAILTO:jsmith@company22.com
      END:VALARM
    */
    

#if 1 
  }
#endif
  [r appendContentString:@"</EVENT>\n"];
  return nil;
}

- (NSException *)renderTodoInXML:(WCAPToDo *)_todo
                       inContext:(WOContext *)_ctx
{
  WOResponse *r         = [_ctx response];
  iCalPerson *organizer = [_todo organizer];  
  NSCalendarDate *now;
  id             tmp;
  
  now = [NSCalendarDate calendarDate];  
  [r appendContentString:@"<TODO>"];
  
  /* iCal standard info */  
  [r appendContentString:@"<UID>"];
  [r appendContentString:[_todo uid]];
  [r appendContentString:@"</UID>\n"];

  [r appendContentString:@"<DTSTAMP>"];
  [r appendContentString:[self formatDate:now]];
  [r appendContentString:@"</DTSTAMP>\n"];
  [r appendContentString:@"<CREATED>"];
  [r appendContentString:[self formatDate:now]];
  [r appendContentString:@"</CREATED>\n"];
  [r appendContentString:@"<LAST-MOD>"];
  [r appendContentString:[self formatDate:now]];
  [r appendContentString:@"</LAST-MOD>\n"];
  
  [r appendContentString:@"<SUMMARY>"];
  [r appendContentString:[_todo summary]];
  [r appendContentString:@"</SUMMARY>\n"];

  tmp = [_todo priority];
  if (![tmp length]) tmp = @"0";
  [r appendContentString:@"<PRIORITY>"];
  [r appendContentString:tmp];
  [r appendContentString:@"</PRIORITY>\n"];
    
  tmp = [_todo sequence];
  if (![tmp length]) tmp = @"0";
  [r appendContentString:@"<SEQUENCE>"];
  [r appendContentString:tmp];
  [r appendContentString:@"</SEQUENCE>\n"];
    
  [r appendContentString:@"<STATUS>CONFIRMED</STATUS>\n"];
  [r appendContentString:@"<TRANSP>OPAQUE</TRANSP>\n"];

  [r appendContentString:@"<START>"];
  [r appendContentString:[self formatDate:[_todo startDate]]];
  [r appendContentString:@"</START>\n"];
  [r appendContentString:@"<DUE>"];
  [r appendContentString:[self formatDate:[_todo due]]];
  [r appendContentString:@"</DUE>\n"];
  
  tmp = [organizer email];
  if (![tmp length]) tmp = @"no-email@no-server";
  [r appendContentString:@"<ORGANIZER SENT-BY=\""];
  [r appendContentString:tmp];
  [r appendContentString:@"\" X-NSCP-ORGANIZER-UID=\""];
  tmp = [organizer xuid];
  if (![tmp length]) tmp = @"no-xuid";
  [r appendContentString:tmp];
  [r appendContentString:@"\">"];
  [r appendContentString:tmp];
  [r appendContentString:@"</ORGANIZER>\n"];

  tmp = [_todo percentComplete];
  if (![tmp length]) tmp = @"0";
  [r appendContentString:@"<PERCENT-COMPLETE>"];
  [r appendContentString:tmp];
  [r appendContentString:@"</PERCENT-COMPLETE>\n"];

  tmp = [_todo completed];
  if (tmp != nil) {
    [r appendContentString:@"<COMPLETED>"];
    [r appendContentString:[self formatDate:tmp]];
    [r appendContentString:@"</COMPLETED>\n"];
  }
    
  /* iCal standard info */
  /*
    UID:3c1162e200207ff600000015000010b7
    DTSTAMP:20011208T015014Z
    SUMMARY:todoA
    DTSTART:20011208T004626Z
    DUE:20020120T141500Z
    CREATED:20011208T004626Z
    LAST-MODIFIED:20011208T011000Z
    PRIORITY:0
    SEQUENCE:3
    PERCENT-COMPLETE:0
    STATUS:NEEDS-ACTION
  */
  /*
    ORGANIZER;SENT-BY="jdoe@sesta.com"
    ;X-NSCP-ORGANIZER-UID=jdoe
    ;X-NSCP-ORGANIZER-SENT-BY-UID=jdoe:jdoe
  */
  
  /* alarms */
  /*
    BEGIN:VALARM
    ACTION:EMAIL
    TRIGGER;VALUE=DATE-TIME:20020120T131500Z
    ATTENDEE:MAILTO:jsmith@company22.com
    END:VALARM
  */
  
  /* NSCP special attributes */
  /*
    X-NSCP-ORIGINAL-DTSTART:20011208T004626Z
    X-NSCP-LANGUAGE:en
    X-NSCP-DUE-TZID:America/Los_Angeles
    X-NSCP-TOMBSTONE:0
    X-NSCP-ONGOING:0
    X-NSCP-ORGANIZER-EMAIL:jdoe@sesta.com
    X-NSCP-GSE-COMPONENT-STATE;X-NSCP-GSE-COMMENT="PUBLISH-COMPLETED":
    5538
  */
  
  [r appendContentString:@"</TODO>\n"];
  return nil;
}

- (NSException *)renderFetchResultInXML:(NSArray *)_results 
  inContext:(WOContext *)_ctx 
{
  WOResponse *r = [_ctx response];
  //  NSEnumerator *e;
  //  id obj;
  
  [self _renderCalPropsInXML:nil inContext:_ctx];
#if 0
  e = [_results objectEnumerator];
  while ((obj = [e nextObject])) {
  }
#endif
  [self renderEventInXML:nil inContext:_ctx];
  //[self renderTodoInXML:nil  inContext:_ctx];
  
  [r addWCAPXmlTag:@"ERRNO" value:@"0"];
  return nil;
}

- (NSException *)renderResultSetInXML:(WCAPResultSet *)_set 
  inContext:(WOContext *)_ctx 
{
  WOResponse *r = [_ctx response];
  NSEnumerator *e;
  id obj;
  
  [self _renderCalPropsInXML:[_set properties] inContext:_ctx];

  //NSLog(@"%s rendering result set with %d entries",
  //      __PRETTY_FUNCTION__, [[_set result] count]);

  e = [_set resultEnumerator];
  while ((obj = [e nextObject])) {
    if ([obj isKindOfClass:[WCAPEvent class]])
      [self renderEventInXML:obj inContext:_ctx];
    else if ([obj isKindOfClass:[WCAPToDo class]])
      [self renderTodoInXML:obj inContext:_ctx];
    else {
      NSLog(@"%s: unable to render object of class: [%@]",
            __PRETTY_FUNCTION__, NSStringFromClass([obj class]));
    }
  }
  
  [r addWCAPXmlTag:@"ERRNO" value:@"0"];
  return nil;
}

/* renderer main hooks */

- (NSException *)renderObjectInXML:(id)_object inContext:(WOContext *)_ctx {
  NSException *error;
  WOResponse  *r;
  
  error = nil;
  
  r = [_ctx response];
  [r setHeader:@"text/xml" forKey:@"content-type"];
  [r appendContentString:@"<iCalendar>\n"];
  [r appendContentString:@"<iCal version=\"2.0\" prodid=\""];
  [r appendContentXMLString:[self zsProductID]];
  [r appendContentString:@"\">\n"];
  
  // TODO: create appropriate model classes ...
  if ([_object isKindOfClass:[WOSession class]])
    error = [self renderSessionInXML:_object inContext:_ctx];

  else if ([_object isKindOfClass:[NSArray class]])
    error = [self renderFetchResultInXML:_object inContext:_ctx];

  else if ([_object isKindOfClass:[WCAPResultSet class]])
    error = [self renderResultSetInXML:_object inContext:_ctx];
  
  else if ([[_object valueForKey:@"preferences"] isNotNull])
    error = [self renderUserPrefsInXML:_object inContext:_ctx];

  else if ([_object isKindOfClass:[NSNumber class]])
    error = [self renderCheckIDInXML:_object inContext:_ctx];

  else {
    [self logWithFormat:@"unknown WCAP object: %@", _object];
    error = [NSException exceptionWithHTTPStatus:500 /* server error */
                         reason:@"shall render unknown WCAP object !"];
  }
  
  [r appendContentString:@"</iCal>\n"];  
  [r appendContentString:@"</iCalendar>\n"];
  
  return error;
}

- (NSException *)renderObject:(id)_object inContext:(WOContext *)_ctx {
  NSString *fFmtOut;
  
  fFmtOut = [[_ctx request] formValueForKey:@"fmt-out"];
  if ([fFmtOut length] == 0) fFmtOut = @"text/javascript";
  [self logWithFormat:@"render WCAP object: %@ (fmt=%@)", _object, fFmtOut];
  
  if (![fFmtOut hasPrefix:@"text/xml"]) {
    [self logWithFormat:@"requested WCAP result in '%@'", fFmtOut];
    return [NSException exceptionWithHTTPStatus:501 /* not implemented */
                        reason:@"ZideStore can only render WCAP XML"];
  }
  
  return [self renderObjectInXML:_object inContext:_ctx];
}
- (BOOL)canRenderObject:(id)_object inContext:(WOContext *)_ctx {
  [self logWithFormat:@"shall render WCAP object: %@", _object];
  return YES;
}

@end /* SoWCAPRenderer */

@implementation WOResponse(WCAPTags)

- (void)addWCAPXmlTag:(NSString *)_tag value:(NSString *)_value {
  [self appendContentString:@"<X-NSCP-WCAP-"];
  [self appendContentString:_tag];
  if ([_value length] == 0) {
    [self appendContentString:@"/>"];
  }
  else {
    [self appendContentString:@">"];
    
    [self appendContentXMLString:_value];
    
    [self appendContentString:@"</X-NSCP-WCAP-"];
    [self appendContentString:_tag];
    [self appendContentString:@">\n"];
  }
}
- (void)addWCAPPrefXmlTag:(NSString *)_tag value:(NSString *)_value {
  [self addWCAPXmlTag:[@"PREF-" stringByAppendingString:_tag]
        value:_value];
}

- (void)addNSCPXmlTag:(NSString *)_tag value:(NSString *)_value {
  [self appendContentString:@"<X-NSCP-"];
  [self appendContentString:_tag];
  if ([_value length] == 0) {
    [self appendContentString:@"/>"];
  }
  else {
    [self appendContentString:@">"];
    
    [self appendContentXMLString:_value];
    
    [self appendContentString:@"</X-NSCP-"];
    [self appendContentString:_tag];
    [self appendContentString:@">\n"];
  }
}

@end /* WOResponse(WCAPTags) */
