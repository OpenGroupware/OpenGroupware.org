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
  SkyAttributeCell renders this:

    <td align="right" or ? "left"
        valign="top"
        width=("15%" or other constant value)
        bgcolor=config.colors_attributeCell>
      <font ..>$content</font>
    </td>

  SkyAttributeCell config:
  
    config.colors_$keyColor   default: config.colors_attributeCell
    config.font_color
    config.font_size
    config.font_face
*/

@interface SkyAttributeCell : WODynamicElement
{
  WOElement *template;
  NSString  *width;     /* if nil == 15% */
  NSString  *keyColor;  /* if nil == attributeCell */
  BOOL      alignLeft;  /* if nil == left */
  BOOL      alignCenter;
  NSString  *colspan;
}
@end

#include <OGoFoundation/WOComponent+config.h>
#include "common.h"

@implementation SkyAttributeCell

+ (int)version {
  return 1 + [super version];
}

- (id)initWithName:(NSString *)_name
  associations:(NSDictionary *)_config
  template:(WOElement *)_t
{
  if ((self = [super initWithName:_name associations:_config template:_t])) {
    WOAssociation *a;
    NSString *c;

    if ((a = OWGetProperty(_config, @"alignLeft"))) {
      self->alignLeft = [a boolValueInComponent:nil];
      [a release]; a = nil;
    }
    else
      self->alignLeft = NO;

    if ((a = OWGetProperty(_config, @"alignCenter"))) {
      self->alignCenter = [a boolValueInComponent:nil];
      [a release]; a = nil;
    }
    else
      self->alignCenter = NO;

    a = OWGetProperty(_config, @"width");
    self->width = [[a stringValueInComponent:nil] copy];
    [a release]; a = nil;
    a = OWGetProperty(_config, @"keyColor");
    c = [[a stringValueInComponent:nil] copy];
    [a release];

    a = OWGetProperty(_config, @"colspan");
    self->colspan = [[a stringValueInComponent:nil] copy];
    [a release]; a = nil;
    
    self->keyColor = (c == nil)
      ? (id)@"colors_attributeCell"
      : [[@"colors_" stringByAppendingString:c] copy];

    [c release];
    
    self->template = [_t retain];
  }
  return self;
}

- (void)dealloc {
  [self->width    release];
  [self->template release];
  [self->keyColor release];
  [self->colspan  release];
  [super dealloc];
}

/* handling request */

- (void)takeValuesFromRequest:(WORequest *)_rq inContext:(WOContext *)_ctx {
  [self->template takeValuesFromRequest:_rq inContext:_ctx];
}
- (id)invokeActionForRequest:(WORequest *)_rq inContext:(WOContext *)_ctx {
  return [self->template invokeActionForRequest:_rq inContext:_ctx];
}

/* generating response */

- (void)appendAttributeCellContentToResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  /* add cell content */
  [self->template appendToResponse:_response inContext:_ctx];
}

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  WOComponent *c;
  NSString *color;
  id          cfg;
  BOOL doFont;
  
  c      = [_ctx component];
  cfg    = [c config];
  color  = [cfg valueForKey:self->keyColor];
  doFont = YES;
  
  /* open cell */
  [_response appendContentString:
               @"<td valign=\"top\""];

  if (self->alignLeft) {
    [_response appendContentString:@" align=\"left\""];
  }
  else if (self->alignCenter) {
    [_response appendContentString:@" align=\"center\""];
  }
  else {
    [_response appendContentString:@" align=\"right\""];
  }
  
  if (self->width) {
    [_response appendContentString:@" width=\""];
    [_response appendContentString:self->width];
    [_response appendContentString:@"\""];
  }
  else {
    [_response appendContentString:@" width=\"15%\""];
  }
  if (self->colspan) {
    [_response appendContentString:@" colspan="];
    [_response appendContentString:self->colspan];
  }

  if (color) {
    [_response appendContentString:@" bgcolor=\""];
    [_response appendContentString:[color stringValue]];
    [_response appendContentString:@"\""];
  }
  [_response appendContentString:@">"];

  /* open font */

  if (doFont) {
    NSString *t;
    
    [_response appendContentString:@"<font"];
    
    if ((t = [[cfg valueForKey:@"font_size"] stringValue])) {
      [_response appendContentString:@" size='"];
      [_response appendContentString:t];
      [_response appendContentString:@"'"];
    }
    if ((t = [[cfg valueForKey:@"font_face"] stringValue])) {
      [_response appendContentString:@" face='"];
      [_response appendContentString:t];
      [_response appendContentString:@"'"];
    }
    
    [_response appendContentString:@">"];
  }
  
  /* add cell content */
  [_response appendContentString:@"<nobr>"];
  [self appendAttributeCellContentToResponse:_response inContext:_ctx];
  [_response appendContentString:@"</nobr>"];

  /* close font */

  if (doFont)
    [_response appendContentString:@"</font>"];
  
  /* close cell */
  [_response appendContentString:@"</td>"];
}

@end /* SkyAttributeCell */
