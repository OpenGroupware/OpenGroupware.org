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
  OGoField

  Element inspired by old forms var:field NGObjDOM renderer. Fields are
  intended to be child elements of an OGoFieldSet.
*/

@interface OGoField : WODynamicElement
{
  WOElement     *template;
  WOAssociation *label;
}

@end

#include <OGoFoundation/OGoComponent.h>
#include <OGoFoundation/OGoEditorPage.h>
#include "common.h"

@implementation OGoField

- (id)initWithName:(NSString *)_name associations:(NSDictionary *)_a
  template:(WOElement *)_t
{
  if ((self = [super initWithName:_name associations:_a template:_t])) {
    self->label    = [[_a objectForKey:@"label"] copy];
    self->template = [_t retain];
  }
  return self;
}

- (void)dealloc {
  [self->label    release];
  [self->template release];
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

static inline void ODRAppendFont(WOResponse *_resp,
                                 NSString   *_color,
                                 NSString   *_face,
                                 NSString   *_size)
{
  [_resp appendContentString:@"<font"];
  if (_color) {
    [_resp appendContentString:@" color=\""];
    [_resp appendContentHTMLAttributeValue:_color];
    [_resp appendContentCharacter:'"'];
  }
  if (_face) {
    [_resp appendContentString:@" face=\""];
    [_resp appendContentHTMLAttributeValue:_face];
    [_resp appendContentCharacter:'"'];
  }
  if (_size) {
    [_resp appendContentString:@" size=\""];
    [_resp appendContentHTMLAttributeValue:_size];
    [_resp appendContentCharacter:'"'];
  }
  [_resp appendContentCharacter:'>'];
}

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  NSString *labelBgColor;
  NSString *contentBgColor;
  NSString *width;
  NSString *llabel;
  NSString *fc, *ff, *fs;
  id       config;
  
  /* label */
  
  llabel = [self->label stringValueInComponent:[_ctx component]];
  
  /* style settings */
  
  config = [(OGoComponent *)[_ctx component] config];
  
  if ([[_ctx component] isEditorPage]) {
    fc = [config valueForKey:@"editFont_color"];
    ff = [config valueForKey:@"editFont_face"];
    fs = [config valueForKey:@"editFont_size"];
  }
  else {
    fc = [config valueForKey:@"font_color"];
    ff = [config valueForKey:@"font_face"];
    fs = [config valueForKey:@"font_size"];
  }

  labelBgColor   = [config valueForKey:@"colors_attributeCell"];
  contentBgColor = [config valueForKey:@"colors_valueCell"];
  width          = [_ctx objectForKey:@"OGoFieldLabelWidth"];
  
  /* start row */
  
  [_response appendContentString:@"  <tr>\n"];

  /* label */

  [_response appendContentString:@"    <td valign=\"top\" align=\"right\""];
  if (labelBgColor != nil) {
    [_response appendContentString:@" bgcolor=\""];
    [_response appendContentString:labelBgColor];
    [_response appendContentCharacter:'"'];
  }
  if (width != nil) {
    [_response appendContentString:@" width=\""];
    [_response appendContentString:width];
    [_response appendContentCharacter:'"'];
  }
  [_response appendContentCharacter:'>'];
  
  ODRAppendFont(_response, fc, ff, fs);
  [_response appendContentString:@"<nobr>"];

  if ([llabel length] > 0) {
    [_response appendContentString:llabel];
    [_response appendContentString:@":"];
  }
  
  [_response appendContentString:@"</nobr></font>"];
  [_response appendContentString:@"</td>\n"];
  
  /* content */

  [_response appendContentString:@"    <td valign=\"top\""];
  if (contentBgColor != nil) {
    [_response appendContentString:@" bgcolor=\""];
    [_response appendContentString:contentBgColor];
    [_response appendContentCharacter:'"'];
  }
  [_response appendContentCharacter:'>'];
  
  [self->template appendToResponse:_response inContext:_ctx];
  [_response appendContentString:@"</td>\n"];
  
  /* close row */
  
  [_response appendContentString:@"  </tr>\n"];
}

@end /* OGoField */
