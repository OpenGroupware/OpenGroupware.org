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

#import <NGObjWeb/WODynamicElement.h>
#include "LSWTableView.h"
#include "common.h"

@class WOAssociation, WOElement;

@interface LSWViewerTitle : WODynamicElement
{
  WOAssociation *title;
  WOAssociation *icon;      /* title icon                           */
  WOAssociation *iconLabel;  
  WOAssociation *iconCond;  
  WOAssociation *bgcolor;   /* def: config.colors_mainButtonRow     */
  WOAssociation *textColor; /* def: config.font_color               */
  WOAssociation *textFace;  /* def: config.font_face                */
  WOAssociation *textSize;  /* def: config.font_size                */
  WOAssociation *colspan;   /* if set, this encodes a row def: 2    */
  WOAssociation *gentable;  /* generate a table if colspan is set ? */
  WOElement     *template;  /* contains the action-buttons          */
}
@end

@implementation LSWViewerTitle

- (id)initWithName:(NSString *)_name
  associations:(NSDictionary *)_config
  template:(WOElement *)_subs
{
  if ((self = [super initWithName:_name associations:_config template:_subs])) {
    static Class AssocClass = Nil;

    if (AssocClass == Nil)
      AssocClass = [WOAssociation class];
    
    self->title     = OWGetProperty(_config, @"title");
    self->icon      = OWGetProperty(_config, @"icon");
    self->iconLabel = OWGetProperty(_config, @"iconLabel");
    self->iconCond  = OWGetProperty(_config, @"iconCond");
    self->bgcolor   = OWGetProperty(_config, @"bgcolor");
    self->textColor = OWGetProperty(_config, @"textColor");
    self->textFace  = OWGetProperty(_config, @"textFace");
    self->textSize  = OWGetProperty(_config, @"textSize");
    self->colspan   = OWGetProperty(_config, @"colspan");
    self->gentable  = OWGetProperty(_config, @"gentable");
    self->template  = RETAIN(_subs);
    
    if (self->bgcolor == nil) {
      self->bgcolor =
        [[AssocClass associationWithKeyPath:
                       @"config.colors_mainButtonRow"] retain];
    }
    if (self->textColor == nil) {
      self->textColor = [[AssocClass associationWithKeyPath:
                                       @"config.font_color"] retain];
    }
    if (self->textFace == nil) {
      self->textFace =
        [[AssocClass associationWithKeyPath:@"config.font_face"] retain];
    }
    if (self->textSize == nil) {
      self->textSize =
        [[AssocClass associationWithKeyPath:@"config.font_size"] retain];
    }
    if (self->colspan == nil) {
      self->colspan =
        [[AssocClass associationWithValue:[NSNumber numberWithInt:2]] retain];
    }
  }
  return self;
}

- (void)dealloc {
  [self->colspan   release];
  [self->gentable  release];
  [self->textSize  release];
  [self->textFace  release];
  [self->textColor release];
  [self->title     release];
  [self->iconCond  release];
  [self->iconLabel release];
  [self->icon      release];
  [self->bgcolor   release];
  [self->template  release];
  [super dealloc];
}

/* responder */

- (id)invokeActionForRequest:(WORequest *)_request inContext:(WOContext *)_ctx {
  return [self->template invokeActionForRequest:_request inContext:_ctx];
}

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  WOComponent *sComponent;
  NSString    *sC, *sF, *sS;
  BOOL        hasFont, hasIcon, lGenTable, bIconCond;
  NSString    *sIcon, *sIconLabel;
  
  sComponent = [_ctx component];
  lGenTable  = [self->gentable boolValueInComponent:sComponent];
  sC = [self->textColor stringValueInComponent:sComponent];
  sF = [self->textFace  stringValueInComponent:sComponent];
  sS = [self->textSize  stringValueInComponent:sComponent];
  

  sIcon      = [self->icon      stringValueInComponent:sComponent];
  sIconLabel = [self->iconLabel stringValueInComponent:sComponent];
  bIconCond  = [self->iconCond  boolValueInComponent:sComponent];

  hasIcon = [sIcon length] ? YES : NO;
  hasFont = (sC || sF || sS) ? YES : NO;
  
  if (self->colspan) {
    if (lGenTable) {
      [_response appendContentString:
                   @"<table id=\"vt1\" width=\"100%\" border=\"0\" "
                   @"cellpadding=\"4\" cellspacing=\"0\">"];
    }
    
    [_response appendContentString:@"<tr"];
    if (self->bgcolor) {
      [_response appendContentString:@" bgcolor=\""];
      [_response appendContentHTMLAttributeValue:
                   [self->bgcolor stringValueInComponent:sComponent]];
      [_response appendContentCharacter:'"'];
    }
    [_response appendContentCharacter:'>'];
    
    [_response appendContentString:@"<td colspan=\""];
    [_response appendContentString:
                 [self->colspan stringValueInComponent:sComponent]];
    [_response appendContentString:@"\">"];
  }
  
  [_response appendContentString:
               @"<table id=\"vt2\" width=\"100%\" border=\"0\" "
               @"cellpadding=\"0\" cellspacing=\"0\">"];
  
  [_response appendContentString:@"<tr"];
  if (self->bgcolor) {
    [_response appendContentString:@" bgcolor=\""];
    [_response appendContentHTMLAttributeValue:
                 [self->bgcolor stringValueInComponent:sComponent]];
    [_response appendContentCharacter:'"'];
  }
  [_response appendContentCharacter:'>'];

  /* label cell */
  {
    [_response appendContentString:@"<td valign=\"top\">"];

    if (hasFont)
      [self appendFontToResponse:_response color:sC face:sF size:sS];
    [_response appendContentString:@"<b>"];

    if (hasIcon && bIconCond) {
      NSString *iconUrl;

      iconUrl = [[[_ctx application] resourceManager]
                        urlForResourceNamed:sIcon
                        inFramework:nil
                        languages:[[_ctx session] languages]
                        request:[_ctx request]];
      if (iconUrl == nil) {
        NSLog(@"%@: did not find resource %@", self, sIcon);
        iconUrl = sIcon;
      }
      [_response appendContentString:@"<img border=\"0\" src=\""];
      [_response appendContentHTMLAttributeValue:iconUrl];
      [_response appendContentCharacter:'"'];
  
      if ([sIconLabel length]) {
        [_response appendContentString:@" alt=\""];
        [_response appendContentHTMLAttributeValue:sIconLabel];
        [_response appendContentCharacter:'"'];
        [_response appendContentString:@" name=\""];
        [_response appendContentHTMLAttributeValue:sIconLabel];
        [_response appendContentCharacter:'"'];
      }
      [_response appendContentString:@" />&nbsp;"];
    }
    
    if (self->title) {
      [_response appendContentHTMLString:
                   [self->title stringValueInComponent:sComponent]];
    }
    
    [_response appendContentString:
                 hasFont ? @"</b>&nbsp</font></td>" : @"</b>&nbsp;</td>"];
  }

  /* button cell */
  {
    [_response appendContentString:@"<td align=\"right\">"];
    
    /* add template (usually action buttons) */
    [self->template appendToResponse:_response inContext:_ctx];
    
    [_response appendContentString:@"</td>"];
  }

  /* close row & table */
  [_response appendContentString:@"</tr></table>"];

  if (self->colspan) {
    [_response appendContentString:@"</td></tr><tr><td colspan=\""];
    [_response appendContentString:
                 [self->colspan stringValueInComponent:sComponent]];
    [_response appendContentString:@"\"></td></tr>"];
    if (lGenTable)
      [_response appendContentString:@"</table>"];
  }
}

@end /* LSWViewerTitle */
