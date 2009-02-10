/*
  Copyright (C) 2008 Whitemice Consulting (Adam Tauno Williams)

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
#include <LSFoundation/LSFoundation.h>
#include <LSFoundation/LSCommandContext.h>
#include <ZSFrontend/SxFolder.h>
#include <ZSFrontend/SxObject.h>
#include "common.h"

@implementation SxFolder(RSS2)

/* implements "new" RSS feeds that executes Logic that returns RSS content */
- (NSString *)rssContentForFeed:(NSString *)_feed 
                      withLimit:(NSNumber *)_limit
                          atURL:(NSString *)_url
                      inContext:(LSCommandContext *)_ctx {
  NSString           *content;
  NSNumber           *accountId;

  accountId = [[_ctx valueForKey:LSAccountKey] valueForKey:@"companyId"];
  content = [_ctx runCommand:_feed,
                            @"accountId", accountId,
                            @"limit", _limit,
                            @"feedURL", _url,
                            nil];
  return content;
}

/* returns the specified Logic RSS feed as a WOResponse */
- (WOResponse *)rssContentForFeed:(NSString *)_feed
                        inContext:(id)_ctx {
  WOResponse         *response;
  WORequest          *request;
  id                  rss;
  NSMutableString    *url;
  NSNumber           *limit;
  LSCommandContext   *ctx;
  
  request  = [(WOContext *)_ctx request];
  response = [WOResponse responseWithRequest:request];
  ctx      = [[self clientObject] commandContextInContext:_ctx];
  
  // construct and store URL used to retrieve feed 
  url = [[NSMutableString alloc] init];
  [url appendString:[request headerForKey:@"x-webobjects-server-url"]];
  [url appendString:[request uri]];

  // determine limit, 150 if not specified in URL
  if ([[request formValueForKey:@"limit"] isNotNull]) {
    limit = intObj([[request formValueForKey:@"limit"] intValue]);
  } else {
      limit = intObj(150);
    }

  if ((rss = [self rssContentForFeed:_feed
                            withLimit:limit
                                atURL:url 
                            inContext:ctx]) != nil) {
    NSString *clen = [NSString stringWithFormat:@"%i", [rss length]];
    
    [response setStatus:200 /* OK */];
    [response setHeader:clen forKey:@"content-length"];
    [response setHeader: 
       @"application/rss+xml; disposition-type=text; charset=utf-8"
	               forKey:@"content-type"];
    
    [response setContent:rss];
  } else {
      [self errorWithFormat:@"got no content for feed: %@", _feed];
      [response setStatus:500 /* server error */];
    }

  return response;
}

@end /* SxFolder(RSS2) */
