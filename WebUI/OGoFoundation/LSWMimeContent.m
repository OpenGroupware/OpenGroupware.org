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

#include "LSWMimeContent.h"
#include "common.h"

@implementation LSWMimeContent

+ (id)mimeContent:(NSData *)_data
  ofType:(NGMimeType *)_type
  inContext:(WOContext *)_ctx
{
  return [LSWMimeContent mimeContent:_data
                         ofType:_type contentDisposition:nil
                         inContext:_ctx];
}
+ (id)mimeContent:(NSData *)_data
  ofType:(NGMimeType *)_type
  contentDisposition:(NSString *)_cd
  inContext:(WOContext *)_ctx
{
  LSWMimeContent *c = [[[self alloc] init] autorelease];
  if (c) {
    c->content            = [_data retain];
    c->type               = [_type retain];
    c->context            = [_ctx  retain];
    c->contentDisposition = [_cd retain];
  }
  return c;
}

- (void)dealloc {
  [self->context            release];
  [self->content            release];
  [self->type               release];
  [self->contentDisposition release];
  [super dealloc];
}

/* accessors */

- (NSData *)content {
  return self->content;
}
- (NGMimeType *)type {
  return self->type;
}
- (NSString *)contentDisposition {
  return self->contentDisposition;
}

- (unsigned int)contentLength {
  return [[self content] length];
}

/* response */

- (NSString *)defaultContentType {
  return @"application/octet-stream";
}

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  /* Note: this is different to generateResponse ?! */
  
  [_response setStatus:200 /* OK */];
  [_response setHeader:[self->type stringValue] forKey:@"content-type"];
  [_response setHeader:
               [NSString stringWithFormat:@"%d", [self contentLength]]
             forKey:@"content-length"];
  [_response setHeader:@"identity" forKey:@"content-encoding"];
  [_response setContent:self->content];
}

- (WOResponse *)generateResponse {
  static NSData *emptyData = nil;
  WORequest  *request;
  WOResponse *response;
  
  if (emptyData == nil)
    emptyData = [[NSData alloc] init];
  
  request  = [self->context request];
  response = [WOResponse responseWithRequest:request];
  
  [response setStatus:200 /* OK */];

  if ([self->contentDisposition length] > 0) {
    [response setHeader:self->contentDisposition
              forKey:@"content-disposition"];
  }
  
  if (self->type == nil)
    [response setHeader:[self defaultContentType] forKey:@"content-type"];
  else
    [response setHeader:[self->type stringValue] forKey:@"content-type"];
  
  [response setHeader:
               [NSString stringWithFormat:@"%d", [self contentLength]]
             forKey:@"content-length"];
  [response setHeader:@"identity" forKey:@"content-encoding"];

  if ([[request method] isEqualToString:@"HEAD"]) {
    [response setContent:emptyData];
  }
  else if ([[request method] isEqualToString:@"OPTIONS"]) {
    response = [WOResponse responseWithRequest:request];
    [response setStatus:405];
    [response setContent:emptyData];
  }
  else
    [response setContent:self->content];
  
  return response;
}

@end /* LSWMimeContent */
