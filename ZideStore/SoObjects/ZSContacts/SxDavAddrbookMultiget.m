/*
  Copyright (C) 2006-2009 Helge Hess
  Copyright (C) 2006-2009 Adam Williams

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

// WORK IN PROGRESS

#include <NGObjWeb/WODirectAction.h>

/*
  CardDAV multiget REPORT

  Sample request:
  <addressbook-multiget xmlns:D="DAV:" xmlns="urn:ietf:params:xml:ns:carddav">
    <D:prop>
      <D:getetag/>
      <D:getcontenttype/>
      <address-data/>
    </D:prop>
    <D:href>/zidestore/dav/adam/Contacts/10931.vcf</D:href>
    <D:href>/zidestore/dav/adam/Contacts/10941.vcf</D:href>
    <D:href>/zidestore/dav/adam/Contacts/10951.vcf</D:href>
  </addressbook-multiget>

  Sample response:
  <D:multistatus xmlns:D="DAV:" xmlns:C="urn:ietf:params:xml:ns:carddav">
    <D:response>
      <D:href>zidestore/dav/adam/Contacts/10931.vcf</D:href>
      <D:propstat>
        <D:prop>
          <D:getetag>10931</D:getetag>
          <C:address-data>BEGIN:VCARD
            ...
            END:VCARD
          </C:address-data>
        </D:prop>
        <D:status>HTTP/1.1 200 OK</D:status>
      </D:propstat>
    </D:response>
  </D:multistatus>
*/

@class NSString, NSDate, NSArray, NSMutableArray, NSEnumerator;
@class WORequest, WOResponse, WOContext;

@interface SxDavAddrbookMultiget : WODirectAction
{
  /* nil - not requested, empty - all requested */
  NSMutableArray *ids;
  NSEnumerator   *results;
}

- (void)takeValuesFromRequest:(WORequest *)_rq inContext:(WOContext *)_ctx;
- (void)appendToResponse:(WOResponse *)_r      inContext:(WOContext *)_ctx;

- (void)takeKeyFromHref:(NSString *)_href;

- (NSEnumerator *)fetchContactsInContext:(id)_ctx;

@end

#include "SxAddressFolder.h"
#include <SaxObjC/XMLNamespaces.h>
#include <ZSBackend/SxContactManager.h>
#include "common.h"

@implementation SxDavAddrbookMultiget

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
    [self debugWithFormat:@"CardDAV Multiget on: %@", [self clientObject]];
    [self debugWithFormat:@"  ids: %@", self->ids];
  }

  // retrieve the contacts for the requested ids
  self->results = [[self fetchContactsInContext:[self context]] retain];

  // if there are no valid requested contacts make an empty enumerator
  if (self->results == nil) {
    self->results = [[[NSArray array] objectEnumerator] retain];
  }
  else if ([self->results isKindOfClass:[NSException class]]) {
    [self errorWithFormat:@"failed to fetch: %@", self->results];
    return self->results;
  }

  // build the response  
  [self appendToResponse:[[self context] response] inContext:[self context]];
  return [[self context] response];
}

/* fetching */

- (SxContactManager *)contactManagerInContext:(id)_ctx {
  return [[self clientObject] contactManagerInContext:_ctx];
}

- (NSEnumerator *)fetchContactsInContext:(id)_ctx {
  SxContactManager  *manager;
  NSArray           *contactIDs;
  LSCommandContext  *ctx;

  if (_ctx == nil)
    return nil;
    
  manager = [self contactManagerInContext:_ctx];
  
  // get an OGo commandContext so we can have a typeManager
  ctx        = [[self clientObject] commandContextInContext:[self context]];
  contactIDs = [[ctx typeManager] globalIDsForPrimaryKeys:self->ids];
  
  if ([contactIDs isNotEmpty]) {
    if ([self isDebuggingEnabled])
      [self debugWithFormat:@"got %d contacts ...", [contactIDs count]];
    
    return [manager idsAndVersionsAndVCardsForGlobalIDs:contactIDs];
  }

  [self debugWithFormat:@"got no contacts for request"];
  return nil;
}

/* generate response */

- (NSString *)hrefForContact:(id)_contact inContext:(WOContext *)_ctx {
  NSString *u;
  id pkey;

  if (![(pkey = [_contact valueForKey:@"companyId"]) isNotEmpty])
    return nil;
  
  u = [[self clientObject] baseURLInContext:_ctx];
  return [u stringByAppendingFormat:
	      ([u hasSuffix:@"/"] ? @"%@.vcf" : @"/%@.vcf"), pkey];
}

- (void)appendToResponse:(WOResponse *)_r inContext:(WOContext *)_ctx {
  id contact;
    
  [_r setContentEncoding:NSUTF8StringEncoding];
  [_r setStatus:207 /* multistatus */];
  [_r setHeader:@"text/xml; charset=\"utf-8\"" forKey:@"content-type"];
  
  /* open multistatus */
  [_r appendContentString:@"<?xml version=\"1.0\"?>\n"];
  [_r appendContentString:@"<D:multistatus xmlns:D=\"DAV:\" xmlns:C=\""];
  [_r appendContentString:XMLNS_CARDDAV];
  [_r appendContentString:@"\">\n"];
  
  /* generate events */
  while ((contact = [self->results nextObject]) != nil) {
    NSString *href;
    id vCard;
    
    if ([self isDebuggingEnabled])
      [self debugWithFormat:@"CONTACT: %@", contact];

    href  = [self hrefForContact:contact inContext:_ctx];
    vCard = [contact valueForKey:@"vCardData"];

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
    // int's can't contain XML special chars ... (no appendContentXMLString)
    // TBD: might need quotes, not sure (eg <getetag>"233:23"</getetag>)
    [_r appendContentString:[[contact valueForKey:@"companyId"] stringValue]];
    [_r appendContentString:@":"];
    [_r appendContentString:[[contact valueForKey:@"objectVersion"] stringValue]];
    [_r appendContentString:@"</D:getetag>\n"];
    
    /* content-type */
    // TBD (if requested?)
    
    /* vCard */
    if ([vCard isNotEmpty]) {
      [_r appendContentString:@"<C:address-data>"];
      [_r appendContentXMLString:[vCard stringValue]];
      [_r appendContentString:@"</C:address-data>\n"];
    }
    else {
      [self errorWithFormat:@"got no vCard data for contact: %@", contact];
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

  self->ids    = [[NSMutableArray alloc] initWithCapacity:128];
  queryElement = [[_rq contentAsDOMDocument] documentElement];
  children     = [queryElement childNodes];
  
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

  if ([_href hasSuffix:@".vcf"]) {
    key = [[_href pathComponents] lastObject];
    key = [[key componentsSeparatedByString:@"."] objectAtIndex:0];
    if ([key intValue] > 0)
      [self->ids addObject:intObj([key intValue])];
  }
  else {
    [self warnWithFormat:@"href in multiget lacks .vcf suffix"];
  }
}

/* debugging */

- (BOOL)isDebuggingEnabled {
  return debugOn;
}

@end /* SxDavAddrbookMultiget */
