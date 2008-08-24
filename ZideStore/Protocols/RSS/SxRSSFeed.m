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

#include <NGObjWeb/WOComponent.h>
#include <LSFoundation/LSFoundation.h>
#include <LSFoundation/LSCommandContext.h>
#include <ZSFrontend/SxFolder.h>
#include <ZSFrontend/SxObject.h>

@interface SxRSSFeed : WOComponent
{
  id          feedContent, feedURL, accountId;
  NSNumber   *limit;
}

@end

#include "common.h"

@implementation SxRSSFeed

- (void)dealloc {
  [self->feedContent release];
  [self->accountId   release];
  [self->feedURL     release];
  [self->limit       release];
  [super dealloc];
}

- (NSNumber *)accountId {
  return self->accountId;
}

- (void)setAccountId:(NSNumber *)_accountId {
  ASSIGNCOPY(self->accountId, _accountId);
}

- (NSString *)feedContent {
  return self->feedContent;
}

- (void)setFeedContent:(NSString *)_content {
  ASSIGNCOPY(self->feedContent, _content);
}

- (NSString *)feedURL {
  return self->feedURL;
}

- (void)setFeedURL:(NSString *)_feedURL {
  ASSIGNCOPY(self->feedURL, _feedURL);
}

- (NSNumber *)limit {
  return self->limit;
}

- (void)setLimit:(NSNumber *)_limit {
  ASSIGNCOPY(self->limit, _limit);
}

/* feeds */

- (void)delegatedActionsFeedWithContext:(LSCommandContext *)_ctx {
    [self setFeedContent:[_ctx runCommand:@"job::get-delegated-rss",
                                 @"accountId", accountId,
                                 @"limit", [self limit],
                                 @"feedURL", [self feedURL],
                                 nil]];
}

/* folder */

- (id<WOActionResults>)defaultAction {
  LSCommandContext   *ctx;
  NSString           *feedName;
  WORequest          *request;

  if ([feedContent isNotNull]) {
    [self->feedContent release];
    self->feedContent = nil;
  }

  ctx = [[self clientObject] commandContextInContext:[self context]];
  if ([ctx isNotNull]) {
    id             tmp;

    request = [[self context] request];
   
    // construct and store URL used to retrieve feed 
    tmp = [[NSMutableString alloc] init];
    [tmp appendString:[request headerForKey:@"x-webobjects-server-url"]];
    [tmp appendString:[request uri]];
    [self setFeedURL:tmp];

    // determine limit, 150 if not specified in URL
    tmp = [request formValueForKey:@"limit"];
    if ([tmp isNotNull]) {
      [self setLimit:intObj([tmp intValue])];
    } else {
        [self setLimit:intObj(150)];
      }

    // get feed name from URL
    feedName = [request formValueForKey:@"feed"];
    [self setAccountId:[[ctx valueForKey:LSAccountKey] valueForKey:@"companyId"]];

    // invoke the requested feed
    if ([feedName isEqualTo:@"delegatedActions"]) {
      [self delegatedActionsFeedWithContext:ctx];
    }
  }
  return self;
}

/* generating response */
- (void)appendToResponse:(WOResponse *)_r inContext:(WOContext *)_ctx {
  [_r setHeader:@"text/xml" forKey:@"content-type"];
  [_r appendContentString:[self feedContent]];
}

@end /* SxRSSFeed */
