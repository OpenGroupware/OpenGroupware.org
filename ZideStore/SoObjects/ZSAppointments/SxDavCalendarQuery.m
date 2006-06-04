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
    <calendary-query xmlns:D="DAV:">
      <D:prop>
        <D:getetag/>
        <calendar-data/>
      </D:prop>
    </calendar-query>

  Sample response:
    <D:multistatus xmlns:D="DAV:">
      <D:response>
        <D:href>http://localhost/zidestore/dav/donald/Calendar/123.ics</D:href>
        <D:propstat>
          <D:status>HTTP/1.1 200 OK</D:status>
          <D:prop>
            <D:getetag>"abc:1"</D:getetag>
            <calendar-data>BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
...
END:VEVENT
END:VCALENDAR
            </calendar-data>
          </D:prop>
        </D:propstat>
      </D:response>
    </D:multistatus>
*/

@class NSString, NSDate, NSArray, NSMutableArray;
@class WORequest, WOResponse, WOContext;

@interface SxDavCalendarQuery : WODirectAction
{
  /* nil - not requested, empty - all requested */
  NSMutableArray *calendarDataFields;
  NSMutableArray *vEventDataFields;
  NSMutableArray *vTodoDataFields;
  NSMutableArray *requestedWebDAVProperties;
  
  NSString *queryType;
  NSDate   *startDate;
  NSDate   *endDate;
}

- (void)takeValuesFromRequest:(WORequest *)_rq inContext:(WOContext *)_ctx;
- (void)appendToResponse:(WOResponse *)_r      inContext:(WOContext *)_ctx;

@end

#include <NGiCal/NSCalendarDate+ICal.h>
#include <SaxObjC/XMLNamespaces.h>
#include "common.h"

@implementation SxDavCalendarQuery

static BOOL debugOn = YES;

- (void)dealloc {
  [self->queryType release];
  [self->startDate release];
  [self->endDate   release];

  [self->calendarDataFields        release];
  [self->vEventDataFields          release];
  [self->vTodoDataFields           release];
  [self->requestedWebDAVProperties release];
  [super dealloc];
}

/* action */

- (id)defaultAction {
  // TODO: remember the depth!
  [self takeValuesFromRequest:[self request] inContext:[self context]];
  
  [self debugWithFormat:@"CalDAV REPORT on: %@", [self clientObject]];
  [self debugWithFormat:@"  type: %@", self->queryType];
  if (self->startDate != nil)
    [self debugWithFormat:@"  range: %@-%@", self->startDate, self->endDate];
  
  // TODO: run query
  
  [self appendToResponse:[[self context] response] inContext:[self context]];
  return [[self context] response];
}


/* generate response */

- (void)appendToResponse:(WOResponse *)_r inContext:(WOContext *)_ctx {
  [self debugWithFormat:@"generating responses"];
  
  [_r setStatus:200 /* OK */];
  [_r setHeader:@"text/xml; charset=\"utf-8\"" forKey:@"content-type"];
  
  /* open multistatus */
  [_r appendContentString:@"<?xml version=\"1.0\"?>\n"];
  [_r appendContentString:@"<D:multistatus xmlns:D=\"DAV:\" xmlns=\""];
  [_r appendContentString:XMLNS_CALDAV];
  [_r appendContentString:@"\">\n"];
  
  /* TODO: generate responses */
  
  /* close multistatus */
  [_r appendContentString:@"</D:multistatus>"];
}


/* decoding requests */

// TODO: this is kinda bloated code because some methods in DOM are not
//       implemented yet

- (void)_loadRequestedCalDataProperties:(id<DOMElement>)_base
  list:(NSMutableArray **)_list
{
  id<DOMNodeList> children;
  unsigned i, count;
  
  [self debugWithFormat:@"  loading properties for element: %@", _base];
  
  if (*_list == nil)
    *_list = [[NSMutableArray alloc] initWithCapacity:4];
  
  children = [_base childNodes];
  for (i = 0, count = [children length]; i < count; i++) {
    id<DOMElement> node;
    NSString *n, *an;
    
    node = [children objectAtIndex:i];
    if ([node nodeType] != DOM_ELEMENT_NODE)
      continue;

    if (![[node namespaceURI] isEqualToString:XMLNS_CALDAV]) {
      [self warnWithFormat:@"unexpected XML element/namespace: %@", node];
      continue;
    }
    
    n  = [node localName];
    an = [node attribute:@"name"];
    
    if ([n isEqualToString:@"prop"] && [an isNotEmpty]) {
      /* same level property */
      [*_list addObject:an];
    }
    else if ([n isEqualToString:@"comp"] && [an isNotEmpty]) {
      if ([an isEqualToString:@"VCALENDAR"]) {
	[self _loadRequestedCalDataProperties:node 
	      list:&self->calendarDataFields];
      }
      else if ([an isEqualToString:@"VEVENT"]) {
	[self _loadRequestedCalDataProperties:node 
	      list:&self->vEventDataFields];
      }
      else if ([an isEqualToString:@"VTODO"]) {
	[self _loadRequestedCalDataProperties:node 
	      list:&self->vTodoDataFields];
      }
      else
	[self warnWithFormat:@"unexpected CalDAV component name: %@", node];
    }
    else
      [self warnWithFormat:@"unexpected CalDAV XML element: %@", node];
  }
}

- (void)_loadRequestedCalDataProperties:(id<DOMElement>)_props {
  [self debugWithFormat:@"loading caldata properties: %@", _props];
  
  self->calendarDataFields = [[NSMutableArray alloc] initWithCapacity:4];
  [self _loadRequestedCalDataProperties:_props list:&self->calendarDataFields];
}

- (void)_loadRequestedProperties:(id<DOMElement>)_props {
  id<DOMNodeList> children;
  unsigned i, count;
  
  [self debugWithFormat:@"loading properties: %@", _props];
  
  children = [_props childNodes];
  for (i = 0, count = [children length]; i < count; i++) {
    id<DOMElement> node;
    NSString *n, *ns;
    
    node = [children objectAtIndex:i];
    if ([node nodeType] != DOM_ELEMENT_NODE)
      continue;

    n  = [node localName];
    ns = [node namespaceURI];

    if ([ns isEqualToString:XMLNS_CALDAV]) {
      if ([n isEqualToString:@"calendar-data"])
	[self _loadRequestedCalDataProperties:node];
      else
	[self warnWithFormat:@"unexpected CalDAV XML element: %@", node];
    }
    else if ([ns isEqualToString:XMLNS_WEBDAV]) {
      if (self->requestedWebDAVProperties == nil) {
	self->requestedWebDAVProperties =
	  [[NSMutableArray alloc] initWithCapacity:4];
      }
      [self->requestedWebDAVProperties addObject:n];
    }
    else
      [self warnWithFormat:@"unexpected XML element/namespace: %@", node];
  }
}

- (id<DOMElement>)_elementNamed:(NSString *)_k inParent:(id<DOMElement>)_e {
  id<DOMNodeList> children;
  unsigned i, count;
  
  if (![_e hasChildNodes])
    return nil;
  
  children = [_e childNodes];
  for (i = 0, count = [children length]; i < count; i++) {
    id<DOMElement> node;
    
    node = [children objectAtIndex:i];
    if ([node nodeType] != DOM_ELEMENT_NODE)
      continue;
    
    if ([_k isEqualToString:[node localName]])
      return node;
  }
  return nil;
}

- (void)_loadCalDAVFilter:(id<DOMElement>)_filter {
  // Note: we ignore namespace here to avoid some DOM bugs ...
  id<DOMElement> element;
  NSString *an;

  [self debugWithFormat:@"loading filter: %@", _filter];
  
  /* first we should get a <comp-filter name="VCALENDAR"> */
  
  element = [self _elementNamed:@"comp-filter" inParent:_filter];
  if (element == nil) {
    [self debugWithFormat:@"no filter specified: %@", _filter];
    return;
  }
  if (![(an = [element attribute:@"name"]) isEqualToString:@"VCALENDAR"]) {
    [self errorWithFormat:@"unsupported top-level filter: %@", _filter];
    return;
  }
  
  /* next we should get the component we want (our querytype) */
  
  element = [self _elementNamed:@"comp-filter" inParent:element];
  if (element == nil) {
    [self debugWithFormat:@"no specific component filter: %@", _filter];
    return;
  }
  if (![(an = [element attribute:@"name"]) isNotEmpty]) {
    [self errorWithFormat:@"got no CalDAV query type: %@", _filter];
    return;
  }
  self->queryType = [an copy]; /* this is VTODO, VEVENT etc */
  
  /* check whether a timerange was specified */
  
  if ((element = [self _elementNamed:@"time-range" inParent:element]) != nil) {
    if ([(an = [element attribute:@"start"]) isNotEmpty]) {
      self->startDate =
	[[NSCalendarDate calendarDateWithICalRepresentation:an] copy];
    }
    if ([(an = [element attribute:@"end"]) isNotEmpty]) {
      self->endDate =
	[[NSCalendarDate calendarDateWithICalRepresentation:an] copy];
    }
  }
}

- (void)takeValuesFromRequest:(WORequest *)_rq inContext:(WOContext *)_ctx {
  id<DOMElement>  queryElement;
  id<DOMNodeList> children;
  unsigned i, count;
  
  queryElement = [[_rq contentAsDOMDocument] documentElement];
  [self debugWithFormat:@"process DOM root: %@", queryElement];
  
  children = [queryElement childNodes];
  for (i = 0, count = [children length]; i < count; i++) {
    id<DOMElement> node;
    NSString *n, *ns;
    
    node = [children objectAtIndex:i];
    if ([node nodeType] != DOM_ELEMENT_NODE)
      continue;

    n  = [node localName];
    ns = [node namespaceURI];
    
    if ([ns isEqualToString:XMLNS_WEBDAV]) {
      if ([n isEqualToString:@"prop"])
	[self _loadRequestedProperties:node];
      else
	[self warnWithFormat:@"unexpected WebDAV XML element: %@", node];
    }
    else if ([ns isEqualToString:XMLNS_CALDAV]) {
      if ([n isEqualToString:@"filter"])
	[self _loadCalDAVFilter:node];
      else
	[self warnWithFormat:@"unexpected CalDAV XML element: %@", node];
    }
    else
      [self warnWithFormat:@"unexpected XML element/namespace: %@", node];
  }
}

/* debugging */

- (BOOL)isDebuggingEnabled {
  return debugOn;
}

@end /* SxDavCalendarQuery */
