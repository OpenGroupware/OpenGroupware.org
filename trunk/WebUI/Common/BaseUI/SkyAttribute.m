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

#include <NGObjWeb/WODynamicElement.h>

/*
  SkyAttribute renders this:

    <td align="right" valign="top"
        width=("15%" or other constant value)
        bgcolor=config.colors_$keyColor>
      <font ..>$label</font>
    </td>
    <td align="left"
        valign="top"
        bgcolor=config.colors_$valueColor>
      <font ..>$string$content</font>
    </td>

  SkySubAttribute is the same, but predefines the config different.
  
  SkyAttribute config:
  
    config.colors_$keyColor   default: config.colors_attributeCell
    config.colors_$valueColor default: config.colors_valueCell
    config.font_color
    config.font_size
    config.font_face
*/

@interface SkyAttribute : WODynamicElement
{
  WOAssociation *label;
  WOAssociation *string;
  WOElement     *template;
  /* update */
  WOAssociation *condition;
  WOAssociation *doTR;
  
  /* static config */
  NSString      *width;          /* if nil == 15% */
  NSString      *keyColor;       /* if nil == attributeCell */
  NSString      *valueColor;     /* if nil == valueCell     */
  NSString      *keyFontColor;   /* if nil == font_color    */
  NSString      *valueFontColor; /* if nil == font_color    */
}
@end

@interface SkySubAttribute : WODynamicElement
{
  SkyAttribute *template;
}
@end

#include <OGoFoundation/WOComponent+config.h>
#include "common.h"

@implementation SkyAttribute

+ (int)version {
  return 0 + [super version];
}

- (id)initWithName:(NSString *)_name
  associations:(NSDictionary *)_config
  template:(WOElement *)_subs
{
  if ((self = [super initWithName:_name associations:_config template:_subs])) {
    WOAssociation *a;
    NSString *kc, *vc, *vfc, *kfc;
    
    self->template = [_subs retain];
    
    self->label       = OWGetProperty(_config, @"label");
    self->string      = OWGetProperty(_config, @"string");
    self->doTR        = OWGetProperty(_config, @"doTR");
    self->condition   = OWGetProperty(_config, @"condition");
    
    a = OWGetProperty(_config, @"width");
    self->width = [[a stringValueInComponent:nil] copy];
    [a release];
    a = OWGetProperty(_config, @"keyColor");
    kc = [[a stringValueInComponent:nil] copy];
    [a release];
    a = OWGetProperty(_config, @"valueColor");
    vc = [[a stringValueInComponent:nil] copy];
    [a release];
    a = OWGetProperty(_config, @"valueFontColor");
    vfc = [[a stringValueInComponent:nil] copy];
    [a release];
    a = OWGetProperty(_config, @"keyFontColor");
    kfc = [[a stringValueInComponent:nil] copy];
    [a release];

    self->keyColor = (kc == nil)
      ? (id)@"colors_attributeCell"
      : [[@"colors_" stringByAppendingString:kc] copy];
    self->valueColor = (vc == nil)
      ? (id)@"colors_valueCell"
      : [[@"colors_" stringByAppendingString:vc] copy];
    self->keyFontColor = (kfc == nil)
      ? (id)@"font_color"
      : [kfc copy];
    self->valueFontColor = (vfc == nil)
      ? (id)@"font_color"
      : [vfc copy];

    [vc  release];
    [kc  release];
    [kfc release];
    [vfc release];
  }
  return self;
}

- (void)dealloc {
  [self->string         release];
  [self->keyColor       release];
  [self->valueColor     release];
  [self->keyFontColor   release];
  [self->valueFontColor release];
  [self->label          release];
  [self->width          release];
  [self->doTR           release];
  [self->condition      release];
  [self->template       release];
  [super dealloc];
}

/* request handling */

- (void)takeValuesFromRequest:(WORequest *)_rq inContext:(WOContext *)_ctx {
  [self->template takeValuesFromRequest:_rq inContext:_ctx];
}
- (id)invokeActionForRequest:(WORequest *)_rq inContext:(WOContext *)_ctx {
  return [self->template invokeActionForRequest:_rq inContext:_ctx];
}

/* response generation */

// TODO: this should use CSS for content generation!

- (void)_appendFontTagWithColor:(NSString *)_color
  toResponse:(WOResponse *)_response inContext:(WOContext *)_ctx
{
  WOComponent *c;
  id          cfg;
  NSString    *t;
  
  c   = [_ctx component];
  cfg = [c config];
  
  [_response appendContentString:@"<font"];
  
  if ((t = [[cfg valueForKey:_color] stringValue])) {
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
}

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  WOComponent *c;
  id          cfg;
  NSString    *color;
  NSString    *s;
  BOOL        cond;
  
  c   = [_ctx component];
  cfg = [c config];

  /* gen first cell */
  
  color = [cfg valueForKey:self->keyColor];
  
  /* if condition */
  cond = (self->condition)
    ? [[self->condition valueInComponent:c] boolValue]
    : YES;

  if (!cond)
    /* do not encode */
    return;
  
  {
    /* <TR> tag? */
    if (self->doTR)
      if ([[self->doTR valueInComponent:c]boolValue])
         [_response appendContentString:@"<TR>"];

    /* open cell */
    [_response appendContentString:
                 @"<td valign=\"top\" align=\"right\""];
    if (self->width) {
      [_response appendContentString:@" width=\""];
      [_response appendContentString:self->width];
      [_response appendContentString:@"\""];
    }
    else {
      [_response appendContentString:@" width=\"15%\""];
    }
    if (color) {
      [_response appendContentString:@" bgcolor=\""];
      [_response appendContentString:[color stringValue]];
      [_response appendContentString:@"\""];
    }
    [_response appendContentString:@">"];
  
    /* open font tag */
    [self _appendFontTagWithColor:self->keyFontColor
          toResponse:_response inContext:_ctx];
    
    /* label */
    s = [self->label stringValueInComponent:c];
    [_response appendContentString:@"<nobr>"];
    [_response appendContentHTMLString:s];
    [_response appendContentString:@":</nobr>"];
    
    /* close font tag */
    [_response appendContentString:@"</font>"];
  
    /* close cell */
    [_response appendContentString:@"</td>"];

  
    /* gen value cell */
  
    color = [cfg valueForKey:self->valueColor];
  
    [_response appendContentString:@"<td align=\"left\" valign=\"top\""];
    if (color) {
      [_response appendContentString:@" bgcolor=\""];
      [_response appendContentString:[color stringValue]];
      [_response appendContentString:@"\""];
    }
    [_response appendContentString:@">"];
  
    /* open font tag */
    [self _appendFontTagWithColor:self->valueFontColor
          toResponse:_response inContext:_ctx];
  
    /* content */
    if ((s = [self->string stringValueInComponent:c]))
      [_response appendContentHTMLString:s];
    [self->template appendToResponse:_response inContext:_ctx];

    /* close font tag */
    [_response appendContentString:@"</font>"];

    /* close cell */
    [_response appendContentString:@"&nbsp;</td>"];

    /* </TR> tag? */
    if (self->doTR) {
      if ([[self->doTR valueInComponent:c] boolValue])
         [_response appendContentString:@"</tr>"];
    }
  }
}

@end /* SkyAttribute */

@implementation SkySubAttribute

+ (int)version {
  return 0 + [super version];
}

- (id)initWithName:(NSString *)_name
  associations:(NSDictionary *)_config
  template:(WOElement *)_subs
{
  WOAssociation       *assoc;
  NSMutableDictionary *cfg;

  cfg = [[_config mutableCopy] autorelease];

  if ((assoc = [cfg objectForKey:@"keyColor"]) == nil) {
    assoc = [WOAssociation associationWithValue:@"subAttributeCell"];
    [cfg setObject:assoc forKey:@"keyColor"];
  }
  if ((assoc = [cfg objectForKey:@"valueColor"]) == nil) {
    assoc = [WOAssociation associationWithValue:@"subValueCell"];
    [cfg setObject:assoc forKey:@"valueColor"];
  }
  
  self->template = [[SkyAttribute alloc] initWithName:_name
                                         associations:cfg
                                         template:_subs];
  
  self = [super initWithName:_name associations:_config
                template:self->template];
  return self;
}
- (void)dealloc {
  [self->template release];
  [super dealloc];
}

/* forward WO methods */

- (void)takeValuesFromRequest:(WORequest *)_rq inContext:(WOContext *)_ctx {
  [self->template takeValuesFromRequest:_rq inContext:_ctx];
}

- (id)invokeActionForRequest:(WORequest *)_rq inContext:(WOContext *)_ctx {
  return [self->template invokeActionForRequest:_rq inContext:_ctx];
}

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  [self->template appendToResponse:_response inContext:_ctx];
}

@end /* SkySubAttribute */
