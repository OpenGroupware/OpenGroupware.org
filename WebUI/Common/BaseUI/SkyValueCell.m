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

    <td align="left"
        valign=top ? "top"
        bgcolor=config.colors_valueCell>
      <font ..>$content</font>
    </td>

  SkyValueCell config:
  
    config.colors_$valueColor default: config.colors_valueCell

    config.font_color
    config.font_size
    config.font_face
   bei isEditorPage Komponenten:
    config.editFont_color
    config.editFont_size
    config.editFont_face
*/

@interface SkyValueCell : WODynamicElement
{
  WOElement *template;
  BOOL      alignTop;
  NSString  *valueColor; /* if nil == valueCell     */
}
@end

#include "common.h"
#include <OGoFoundation/WOComponent+config.h>
#include <OGoFoundation/LSWEditorPage.h>

@implementation SkyValueCell

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
    
    if ((a = OWGetProperty(_config, @"alignTop"))) {
      self->alignTop = [a boolValueInComponent:nil];
      [a release]; a= nil;
    }
    else
      self->alignTop = NO;

    a = OWGetProperty(_config, @"valueColor");
    c = [[a stringValueInComponent:nil] copy];
    [a release];

    self->valueColor = (c == nil)
      ? (id)@"colors_valueCell"
      : [[@"colors_" stringByAppendingString:c] copy];

    [c release];
    
    self->template = [_t retain];
  }
  return self;
}

- (void)dealloc {
  [self->template   release];
  [self->valueColor release];
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

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  WOComponent *c;
  NSString    *color;
  id          cfg;
  BOOL        doFont;
  
  c      = [_ctx component];
  cfg    = [c config];
  color  = [cfg valueForKey:self->valueColor];
  doFont = YES;
 
  /* open cell */
  [_response appendContentString:@"<td align=\"left\""];
  if (self->alignTop)
    [_response appendContentString:@" valign=\"top\""];
  if (color) {
    [_response appendContentString:@" bgcolor=\""];
    [_response appendContentString:[color stringValue]];
    [_response appendContentString:@"\""];
  }
  [self appendExtraAttributesToResponse:_response inContext:_ctx];
  [_response appendContentString:@">"];
  
  /* open font */

  if (doFont) {
    NSString *t;
    NSString *sizeKey, *faceKey, *colorKey;
    
    [_response appendContentString:@"<font"];

    if ([[_ctx component] isEditorPage]) {
      colorKey = @"editFont_color";
      sizeKey  = @"editFont_size";
      faceKey  = @"editFont_face";
    }
    else {
      colorKey = @"font_color";
      sizeKey  = @"font_size";
      faceKey  = @"font_face";
    }
    
    if ((t = [[cfg valueForKey:sizeKey] stringValue])) {
      [_response appendContentString:@" size='"];
      [_response appendContentString:t];
      [_response appendContentString:@"'"];
    }
    if ((t = [[cfg valueForKey:faceKey] stringValue])) {
      [_response appendContentString:@" face='"];
      [_response appendContentString:t];
      [_response appendContentString:@"'"];
    }
    
    [_response appendContentString:@">"];
  }

  /* add cell content */
  [self->template appendToResponse:_response inContext:_ctx];

  /* close font */
  
  if (doFont)
    [_response appendContentString:@"</font>"];
  
  /* close cell */
  [_response appendContentString:@"</td>"];
}

@end /* SkyValueCell */
