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
// $Id$

#include <NGObjWeb/WODynamicElement.h>

/*
  renders this:

    <font color=config.font_color
          size=config.font_size
          face=config.font_face>
      $content
    </font>
  
  Config Attributes:

    config.font_color
    config.font_size
    config.font_face
*/

@interface SkyConfigFont : WODynamicElement
{
  WOElement *template;
}
@end

#include <OGoFoundation/WOComponent+config.h>
#include "common.h"

@implementation SkyConfigFont

+ (int)version {
  return 0 + [super version];
}

- (id)initWithName:(NSString *)_name
  associations:(NSDictionary *)_config
  template:(WOElement *)_t
{
  if ((self = [super initWithName:_name associations:_config template:_t])) {
    self->template = [_t retain];
  }
  return self;
}

- (void)dealloc {
  [self->template release];
  [super dealloc];
}

/* handling requests */

- (void)takeValuesFromRequest:(WORequest *)_rq inContext:(WOContext *)_ctx {
  [self->template takeValuesFromRequest:_rq inContext:_ctx];
}
- (id)invokeActionForRequest:(WORequest *)_rq inContext:(WOContext *)_ctx {
  return [self->template invokeActionForRequest:_rq inContext:_ctx];
}

/* generating response */

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  WOComponent *c;
  id          cfg;
  NSString    *t;
  
  c   = [_ctx component];
  cfg = [c config];

  /* open font tag */
  
  [_response appendContentString:@"<font"];
  
  if ((t = [[cfg valueForKey:@"font_color"] stringValue])) {
    [_response appendContentString:@" color=\""];
    [_response appendContentString:t];
    [_response appendContentString:@"\""];
  }
  if ((t = [[cfg valueForKey:@"font_size"] stringValue])) {
    [_response appendContentString:@" size=\""];
    [_response appendContentString:t];
    [_response appendContentString:@"\""];
  }
  if ((t = [[cfg valueForKey:@"font_face"] stringValue])) {
    [_response appendContentString:@" face=\""];
    [_response appendContentString:t];
    [_response appendContentString:@"\""];
  }
  
  [_response appendContentString:@">"];
  
  /* add fontorized content */
  [self->template appendToResponse:_response inContext:_ctx];

  /* close font */
  [_response appendContentString:@"</font>"];
}

@end /* SkyConfigFont */
