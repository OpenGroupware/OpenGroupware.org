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
  OGoFieldSet

  Element inspired by old forms var:fieldset NGObjDOM renderer. The children
  of this elements are supposed to be OGoField's.
*/

@interface OGoFieldSet : WODynamicElement
{
  WOElement     *template;
  WOAssociation *labelwidth;
}

@end

#include "common.h"

@implementation OGoFieldSet

- (id)initWithName:(NSString *)_name associations:(NSDictionary *)_a
  template:(WOElement *)_t
{
  if ((self = [super initWithName:_name associations:_a template:_t])) {
    self->labelwidth = [[_a objectForKey:@"labelwidth"] copy];
    self->template   = [_t retain];
  }
  return self;
}

- (void)dealloc {
  [self->labelwidth release];
  [self->template   release];
  [super dealloc];
}

/* handle request */

- (void)takeValuesFromRequest:(WORequest *)_rq inContext:(WOContext *)_ctx {
  [self->template takeValuesFromRequest:_rq inContext:_ctx];
}

- (id)invokeActionForRequest:(WORequest *)_rq inContext:(WOContext *)_ctx {
  return [self->template invokeActionForRequest:_rq inContext:_ctx];
}

/* generate response */

- (void)appendToResponse:(WOResponse *)_r inContext:(WOContext *)_ctx {
  // TODO: use CSS
  [_ctx setObject:[self->labelwidth valueInComponent:[_ctx component]]
	forKey:@"OGoFieldLabelWidth"];

  [_r appendContentString:
             @"<table border=\"0\" width=\"100%\""
             @"cellspacing=\"0\" cellpadding=\"4\">\n"];
  
  [self->template appendToResponse:_r inContext:_ctx];
  
  [_r appendContentString:@"</table>"];
  [_ctx removeObjectForKey:@"OGoFieldLabelWidth"];
}

@end /* OGoFieldSet */
