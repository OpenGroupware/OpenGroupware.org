/*
  Copyright (C) 2005 SKYRIX Software AG

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

#include <NGObjWeb/WODynamicElement.h>

/*
  OGoEmbedExternalLink

  Fetch some external page using HTTP and embed the result into the current
  page.
  
  Example:
    EmbedPHP: OGoEmbedExternalLink {
      url      = "http://192.168.1.18/phptest/index.php";
      ?login   = session.activeAccount.login;
      ?loginid = session.activeAccount.companyId;
      ?ogosid  = session.sessionID;
    }
*/

@interface OGoEmbedExternalLink : WODynamicElement
{
  WOAssociation *url;
  WOElement     *template;
  NSDictionary  *queryParameters;  /* associations beginning with ? */
}

@end

#include <NGExtensions/NSString+Ext.h>
#include "common.h"

@interface WOElement(UsedPrivates_QueryString)

extern NSDictionary *OWExtractQueryParameters(NSDictionary *_set);

- (NSString *)queryStringForQueryDictionary:(NSDictionary *)_queryDict
  andQueryParameters:(NSDictionary *)_paras
  inContext:(WOContext *)_ctx;

@end

@implementation OGoEmbedExternalLink

static BOOL debugOn = NO;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  debugOn = [ud boolForKey:@"OGoDebugEmbedExternalLink"];
}

- (id)initWithName:(NSString *)_name
  associations:(NSDictionary *)_config
  template:(WOElement *)_t
{
  if ((self = [super initWithName:_name associations:_config template:_t])) {
    self->url      = [[_config objectForKey:@"url"] copy];
    self->template = [_t retain];
    
    self->queryParameters = OWExtractQueryParameters(_config);
  }
  return self;
}

- (void)dealloc {
  [self->queryParameters release];
  [self->template release];
  [self->url      release];
  [super dealloc];
}

/* HTTP client objects */

- (WOHTTPConnection *)connectionInContext:(WOContext *)_ctx {
  WOHTTPConnection *connection;
  id lurl;
  
  lurl = [self->url valueInComponent:[_ctx component]];
  if (![lurl isNotNull])
    return nil;
  
  if ([lurl isKindOfClass:[NSString class]]) {
    if (![lurl isAbsoluteURL]) {
      if (![(NSString *)lurl hasPrefix:@"/"]) {
	[self logWithFormat:@"ERROR: invalid URL: %@", lurl];
	return nil;
      }
      
      lurl = [@"http://127.0.0.1" stringByAppendingString:lurl];
    }
  }
  
  connection = [[WOHTTPConnection alloc] initWithURL:lurl];
  return [connection autorelease];
}

- (WORequest *)requestInContext:(WOContext *)_ctx {
  static NSDictionary *headers = nil;
  WORequest *rq;
  NSString  *uri, *queryString;
  id lurl;
  
  if (headers == nil) {
    headers = [[NSDictionary alloc] initWithObjectsAndKeys:
				      @"1", @"x-ogo-embed-link", nil];
  }

  queryString = [self queryStringForQueryDictionary:nil
                      andQueryParameters:self->queryParameters
                      inContext:_ctx];
  
  lurl = [self->url valueInComponent:[_ctx component]];
  if (![lurl isNotNull])
    return nil;

  if ([lurl isKindOfClass:[NSString class]] && [lurl isAbsoluteURL])
    lurl = [NSURL URLWithString:lurl];
  
  if ([lurl isKindOfClass:[NSURL class]])
    uri = [lurl path];
  else
    uri = [lurl stringValue];
  
  if ([queryString length] > 0) {
    uri = [uri stringByAppendingString:@"?"];
    uri = [uri stringByAppendingString:queryString];
  }
  
  rq = [[WORequest alloc] initWithMethod:@"GET"
			  uri:uri httpVersion:@"HTTP/1.0"
			  headers:headers
			  content:nil userInfo:nil];
  return [rq autorelease];
}

/* generate response */

- (void)appendResponse:(WOResponse *)_in toResponse:(WOResponse *)_out
  inContext:(WOContext *)_ctx
{
  NSString *content;
  
  if ((content = [_in contentAsString]) != nil)
    [_out appendContentString:content];
  else {
    [self logWithFormat:
	    @"ERROR: could not get string content of response: %@", _in];
  }
}

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  WOHTTPConnection *http;
  WORequest        *request;
  
  http    = [self connectionInContext:_ctx];
  request = [self requestInContext:_ctx];

  [self debugWithFormat:@"will fetch %@ on %@ ...", request, http];
  
  if (http != nil && request != nil && [http sendRequest:request]) {
    WOResponse *response;
    
    if ((response = [http readResponse]) != nil) {
      [self appendResponse:response toResponse:_response inContext:_ctx];
    }
    else {
      [_response appendContentString:@"<!-- could not embed link -->"];
      [self logWithFormat:@"ERROR: could not read response for embedding!"];
    }
  }
  else {
    [_response appendContentString:@"<!-- could not embed link -->"];
    [self logWithFormat:@"ERROR: could not fetch link for embedding!"];
  }
  
  [self->template appendToResponse:_response inContext:_ctx];
}

/* debugging */

- (BOOL)isDebuggingEnabled {
  return debugOn;
}

@end /* OGoEmbedExternalLink */
