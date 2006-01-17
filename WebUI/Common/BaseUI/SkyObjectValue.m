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

#include <NGObjWeb/NGObjWeb.h>

/*
  SkyObjectValue
  
  TODO: where is it used? describe what it does.
*/

@class WOAssociation;

@interface SkyObjectValue : WODynamicElement
{
@protected
  // WODynamicElement: extraAttributes
  // WODynamicElement: otherTagString
  
  WOAssociation *object; // object which will be tested whether archived or not
  WOAssociation *value;  // displayed value
  WOAssociation *action; // for Hyperlinks
  WOAssociation *bold;   // display non archived as bold
  /*
    <var:if condition=object.dbStatus; value='archived'; negate=YES;>
      <font color = config.font_color
            face  = config.font_face
            size  = config.font_size>
        value
      </font>
    </var:if>
    <var:if condition=object.dbStatus value='archived'>
      <font color = config.colors_deleted_object 
            face  = config.font_face
            size  = config.font_size>
        value
      </font>
    </var:if>
  */    
}

@end /* SkyObjectValue */

#include <NGObjWeb/WODynamicElement.h>
#include <OGoFoundation/WOComponent+config.h>
#include "common.h"

@implementation SkyObjectValue

- (id)initWithName:(NSString *)_name
  associations:(NSDictionary *)_config
  template:(WOElement *)_c
{
  if ((self = [super initWithName:_name associations:_config template:_c])) {
    self->object = OWGetProperty(_config, @"object");
    self->value  = OWGetProperty(_config, @"value");
    self->action = OWGetProperty(_config, @"action");
    self->bold   = OWGetProperty(_config, @"bold");

    if (self->object == nil) {
      [self warnWithFormat:
	      @"missing 'object' association in element %@ !", _name];
    }
    if (self->value == nil) {
      [self warnWithFormat:
	      @"missing 'value' association in element %@ !", _name];
    }
  }
  return self;
}

- (void)dealloc {
  [self->value  release];
  [self->object release];
  [self->action release];
  [self->bold   release];
  [super dealloc];
}

/* processing requests */

- (id)invokeActionForRequest:(WORequest *)_rq inContext:(WOContext *)_ctx {
  if (self->action != nil)
    return [self->action valueInComponent:[_ctx component]];
  return nil;
}

/* generating response */

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  WOComponent *c;
  NSString    *t = nil;
  NSString    *v;
  id          cfg;
  BOOL        isArchived;
  BOOL        b;
  BOOL        isLink;
  
  c = [_ctx component];
  v = [self->value stringValueInComponent:c];
  
  if (![v isNotEmpty])
    return;
  
  cfg = [c config];
  
  b = (self->bold != nil) ? [[self->bold valueInComponent:c] boolValue] : NO;
  
  isArchived = [[[self->object valueInComponent:c] valueForKey:@"dbStatus"]
                               isEqualToString:@"archived"];
  isLink     = ((!isArchived) && (self->action != nil)) ? YES : NO;

  /* open font tag */
  [_response appendContentString:@"<font"]; 
  if (isArchived) {
    if ((t = [[cfg valueForKey:@"colors_deleted_object"] stringValue])) {
      [_response appendContentString:@" color=\""];
      [_response appendContentString:t];
      [_response appendContentString:@"\""];
    }
  }
  else {
    if ((t = [[cfg valueForKey:@"font_color"] stringValue])) {
      [_response appendContentString:@" color=\""];
      [_response appendContentString:t];
      [_response appendContentString:@"\""];
    }
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
  
  if (isLink) {
    [_response appendContentString:@"<a href=\""];
    [_response appendContentString:[_ctx componentActionURL]]; 
    [_response appendContentString:@"\">"];
  }
  
  if (b) [_response appendContentString:@"<b>"];
  [_response appendContentString:v];
  if (b)      [_response appendContentString:@"</b>"];
  if (isLink) [_response appendContentString:@"</a>"];
  [_response appendContentString:@"</font>"];
}

/* description */

- (NSString *)associationDescription {
  NSMutableString *str;

  str = [NSMutableString stringWithCapacity:64];
  if (self->object) [str appendFormat:@" object=%@", self->object];
  if (self->value)  [str appendFormat:@" value=%@",  self->value];
  return str;
}

@end /* SkyObjectValue */
