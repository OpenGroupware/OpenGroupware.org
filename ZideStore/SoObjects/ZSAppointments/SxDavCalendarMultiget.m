/*
  Copyright (C) 2006 Helge Hess

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

#include <NGObjWeb/WODirectAction.h>

/*
  CalDAV calendar-query REPORT

  Sample request:
  <calendar-multiget xmlns:D="DAV:" xmlns="urn:ietf:params:xml:ns:caldav">
    <D:prop>
      <D:getetag/>
      <calendar-data/>
    </D:prop>
    <D:href>/zidestore/dav/adam/Overview/10931.ics</D:href>
  </calendar-multiget>

  Sample response:
  <D:multistatus xmlns:D="DAV:" xmlns:C="urn:ietf:params:xml:ns:caldav">
    <D:response>
      <D:href>zidestore/dav/adam/Overview/10931.ics</D:href>
      <D:propstat>
        <D:prop>
          <D:getetag>10931</D:getetag>
          <C:calendar-data>BEGIN:VCALENDAR
            ...
            END:VCALENDAR
          </C:calendar-data>
        </D:prop>
        <D:status>HTTP/1.1 200 OK</D:status>
      </D:propstat>
    </D:response>
  </D:multistatus>
*/

@class NSString, NSDate, NSArray, NSMutableArray, NSEnumerator;
@class WORequest, WOResponse, WOContext;

@interface SxDavCalendarMultiget : WODirectAction
{
  /* nil - not requested, empty - all requested */
  NSMutableArray *ids;

  NSEnumerator *results;
}

- (void)takeValuesFromRequest:(WORequest *)_rq inContext:(WOContext *)_ctx;
- (void)appendToResponse:(WOResponse *)_r      inContext:(WOContext *)_ctx;

- (void)takeKeyFromHref:(NSString *)_href;

- (NSEnumerator *)fetchDatesInContext:(id)_ctx;

@end

#include "SxAppointmentFolder.h"
#include <NGiCal/NSCalendarDate+ICal.h>
#include <SaxObjC/XMLNamespaces.h>
#include <ZSBackend/SxAptManager.h>
#include "common.h"

@implementation SxDavCalendarMultiget

static BOOL debugOn = NO;

- (void)dealloc {
  [self->results   release];
  [self->ids       release];
  [super dealloc];
}

/* action */

- (id)defaultAction {
  
  // collect the requested ids from the request
  [self takeValuesFromRequest:[self request] inContext:[self context]];  
  if ([self isDebuggingEnabled]) {
    [self debugWithFormat:@"CalDAV Multiget on: %@", [self clientObject]];
    [self debugWithFormat:@"  ids: %@", self->ids];
  }

  // retrieve the dates for the requested ids
  self->results = [self fetchDatesInContext:[self context]];

  // if there are no valid requested dates make an empty enumerator
  if (self->results == nil) {
    self->results = [[NSArray array] objectEnumerator];
  } else if ([self->results isKindOfClass:[NSException class]]) {
      [self errorWithFormat:@"failed to fetch: %@", self->results];
      return self->results;
    }

  // buld the response  
  [self appendToResponse:[[self context] response] inContext:[self context]];
  return [[self context] response];
}

/* fetching */

- (SxAptManager *)aptManagerInContext:(id)_ctx {
  return [[self clientObject] aptManagerInContext:_ctx];
}

- (NSEnumerator *)fetchDatesInContext:(id)_ctx {
  SxAptManager      *manager;
  NSMutableArray    *dates;
  LSCommandContext  *ctx;
  id<LSTypeManager>  tm;
  id                 tmp;
  NSEnumerator      *enumerator;

  if (_ctx != nil) {
    manager = [self aptManagerInContext:_ctx];
    // get an OGo commandContext so we can have a typeManager
    ctx = [[self clientObject] commandContextInContext:[self context]];
    tm = [ctx typeManager];
    dates = [NSMutableArray arrayWithCapacity:[self->ids count]];
    enumerator = [self->ids objectEnumerator];
    // make an array of gids for each key (id) that represents
    // a valid date.  If you pass a non-date gid to the 
    // SxAptManager it will die with a signal 6.
    while ((tmp = [enumerator nextObject]) != nil) {
      tmp = [tm globalIDForPrimaryKey:tmp];
      if (tmp != nil) {
        if ([[tmp entityName] isEqualToString:@"Date"]) {
          [dates addObject:tmp];
        }
      }
    }
    if ([dates isNotEmpty]) {
      if ([self isDebuggingEnabled])
        [self debugWithFormat:@"got %d events ...", [dates count]];
      return [manager pkeysAndModDatesAndICalsForGlobalIDs:dates];
    } else [self logWithFormat:@"got no dates for request"];
  }
  return nil;
}

/* generate response */

- (NSString *)hrefForEvent:(id)_event inContext:(WOContext *)_ctx {
  NSString *u;
  id pkey;

  if (![(pkey = [_event valueForKey:@"pkey"]) isNotEmpty])
    return nil;
  
  u = [[self clientObject] baseURLInContext:_ctx];
  return [u stringByAppendingFormat:
	      ([u hasSuffix:@"/"] ? @"%@.ics" : @"/%@.ics"), pkey];
}

- (void)appendToResponse:(WOResponse *)_r inContext:(WOContext *)_ctx {
  id event;
    
  [_r setContentEncoding:NSUTF8StringEncoding];
  [_r setStatus:207 /* multistatus */];
  [_r setHeader:@"text/xml; charset=\"utf-8\"" forKey:@"content-type"];
  
  /* open multistatus */
  [_r appendContentString:@"<?xml version=\"1.0\"?>\n"];
  [_r appendContentString:@"<D:multistatus xmlns:D=\"DAV:\" xmlns:C=\""];
  [_r appendContentString:XMLNS_CALDAV];
  [_r appendContentString:@"\">\n"];
  
  /* generate events */
  while ((event = [self->results nextObject]) != nil) {
    id ical, href, etag;

    href = [self hrefForEvent:event inContext:_ctx];
    etag = [event valueForKey:@"pkey"];
    ical = [event valueForKey:@"iCalData"];

    [_r appendContentString:@"  <D:response>\n"];
    [_r appendContentString:@"    <D:href>"];
    [_r appendContentXMLString:href];
    [_r appendContentString:@"</D:href>\n"];

    /* successful properties */
    [_r appendContentString:@"    <D:propstat>\n"];
    [_r appendContentString:@"      <D:status>HTTP/1.1 200 OK</D:status>\n"];
    [_r appendContentString:@"      <D:prop>\n"];
    /* etag */
    [_r appendContentString:@"<D:getetag>"];
    [_r appendContentXMLString:[etag stringValue]]; 
    [_r appendContentString:@"</D:getetag>\n"];
    /* ical */
    if ([ical isNotEmpty]) {
      [_r appendContentString:@"<C:calendar-data>"];
      [_r appendContentXMLString:@"BEGIN:VCALENDAR\r\n"];
      [_r appendContentXMLString:@"VERSION:2.0\r\n"];
      [_r appendContentXMLString:[ical stringValue]];
      [_r appendContentXMLString:@"END:VCALENDAR\r\n"];
      [_r appendContentString:@"</C:calendar-data>\n"];
    } else {
        [self errorWithFormat:@"got no iCalendar data for event: %@", event];
      }
    
    [_r appendContentString:@"      </D:prop>\n"];
    [_r appendContentString:@"    </D:propstat>\n"];
    [_r appendContentString:@"  </D:response>\n"];
  } /* end while */
  
  /* close multistatus */
  [_r appendContentString:@"</D:multistatus>"];
}

/* decoding requests */

- (void)takeValuesFromRequest:(WORequest *)_rq inContext:(WOContext *)_ctx {
  id<DOMElement>  queryElement;
  id<DOMNodeList> children;
  unsigned        i, count;

  self->ids = [NSMutableArray arrayWithCapacity:128];
  queryElement = [[_rq contentAsDOMDocument] documentElement];
  children = [queryElement childNodes];
  for (i = 0, count = [children length]; i < count; i++) {
    id<DOMElement>  node;

    node = [children objectAtIndex:i];
    if ([node nodeType] != DOM_ELEMENT_NODE)
      continue;
    if ([[node localName] isEqualToString:@"href"]) {
      id<DOMElement> href;

      href = [[node childNodes] objectAtIndex:0];
      if (href != nil)
        [self takeKeyFromHref:[href nodeValue]];
    }
  }
}

- (void)takeKeyFromHref:(NSString *)_href {
  NSString  *key;

  if ([_href hasSuffix:@".ics"]) {
    key = [[_href pathComponents] lastObject];
    key = [[key componentsSeparatedByString:@"."] objectAtIndex:0];
    if ([key intValue] > 0)
      [self->ids addObject:intObj([key intValue])];
  } else {
      [self warnWithFormat:@"href in multiget lacks .ics suffix"];
     }
}

/* debugging */

- (BOOL)isDebuggingEnabled {
  return debugOn;
}

@end /* SxDavCalendarMultiget */
