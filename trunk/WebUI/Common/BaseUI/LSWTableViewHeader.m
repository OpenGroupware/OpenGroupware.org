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

@class WOAssociation, WOElement;

/* NOTE: This element is DEPRECATED - use SkyTableView instead! */

@interface LSWTableViewHeader : WODynamicElement
{
  WOAssociation *title;
  WOAssociation *bgcolor;
  WOAssociation *textColor;
  WOAssociation *textFace;
  WOAssociation *textSize;
  WOAssociation *isOnFirstPage; /* is first page active ? */
  WOAssociation *isOnLastPage;  /* is last page active ?  */
  WOAssociation *firstIcon;
  WOAssociation *firstIconBlind;
  WOAssociation *firstLabel;
  WOAssociation *lastIcon;
  WOAssociation *lastIconBlind;
  WOAssociation *lastLabel;
  WOAssociation *nextIcon;
  WOAssociation *nextIconBlind;
  WOAssociation *nextLabel;
  WOAssociation *prevIcon;
  WOAssociation *prevIconBlind;
  WOAssociation *prevLabel;
  WOElement     *template;      /* contains the action-buttons */
}
@end

#include "LSWTableView.h"
#include "common.h"

@implementation LSWTableViewHeader

- (id)initWithName:(NSString *)_name
  associations:(NSDictionary *)_config
  template:(WOElement *)_t
{
  if ((self = [super initWithName:_name associations:_config template:_t])) {
    self->title         = OWGetProperty(_config, @"title");
    self->bgcolor       = OWGetProperty(_config, @"bgcolor");
    self->textColor     = OWGetProperty(_config, @"textColor");
    self->textFace      = OWGetProperty(_config, @"textFace");
    self->textSize      = OWGetProperty(_config, @"textSize");
    self->isOnFirstPage = OWGetProperty(_config, @"isOnFirstPage");
    self->isOnLastPage  = OWGetProperty(_config, @"isOnLastPage");
    self->firstIcon     = OWGetProperty(_config, @"firstIcon");
    self->firstIconBlind= OWGetProperty(_config, @"firstIconBlind");
    self->firstLabel    = OWGetProperty(_config, @"firstLabel");
    self->lastIcon      = OWGetProperty(_config, @"lastIcon");
    self->lastIconBlind = OWGetProperty(_config, @"lastIconBlind");
    self->lastLabel     = OWGetProperty(_config, @"lastLabel");
    self->nextIcon      = OWGetProperty(_config, @"nextIcon");
    self->nextIconBlind = OWGetProperty(_config, @"nextIconBlind");
    self->nextLabel     = OWGetProperty(_config, @"nextLabel");
    self->prevIcon      = OWGetProperty(_config, @"prevIcon");
    self->prevIconBlind = OWGetProperty(_config, @"prevIconBlind");
    self->prevLabel     = OWGetProperty(_config, @"prevLabel");
    
    self->template  = [_t retain];
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->firstIcon);
  RELEASE(self->firstIconBlind);
  RELEASE(self->firstLabel);
  RELEASE(self->lastIcon);
  RELEASE(self->lastIconBlind);
  RELEASE(self->lastLabel);
  RELEASE(self->nextIcon);
  RELEASE(self->nextIconBlind);
  RELEASE(self->nextLabel);
  RELEASE(self->prevIcon);
  RELEASE(self->prevIconBlind);
  RELEASE(self->prevLabel);
  RELEASE(self->isOnFirstPage);
  RELEASE(self->isOnLastPage);
  RELEASE(self->textSize);
  RELEASE(self->textFace);
  RELEASE(self->textColor);
  RELEASE(self->title);
  RELEASE(self->bgcolor);
  RELEASE(self->template);
  [super dealloc];
}

/* responder */

static inline void
_encodeNavLink(WOResponse *_response, WOContext *_ctx,
               WOResourceManager *rm, NSArray *languages,
               NSString *action,
               BOOL isBlind, NSString *icon, NSString *label)
{
  /* open anker */
  if (!isBlind) {
    [_ctx appendElementIDComponent:action];
    [_response appendContentString:@"<a href=\""];
    [_response appendContentString:[_ctx componentActionURL]];
    [_response appendContentString:@"\">"];
  }

  /* anker content */
  
  if (icon) {
    /* icon image */
    NSString *iconUri;

    iconUri = [rm urlForResourceNamed:icon inFramework:nil languages:
                  languages request:[_ctx request]];
    if (iconUri == nil)
      NSLog(@"%s: did not find resource %@", __PRETTY_FUNCTION__, icon);

    [_response appendContentString:@"<img border=\"0\" src=\""];
    [_response appendContentString:iconUri];
    [_response appendContentCharacter:'"'];
      
    if (label) {
      [_response appendContentString:@" alt=\""];
      [_response appendContentHTMLAttributeValue:label];
      [_response appendContentCharacter:'"'];
    }
      
    [_response appendContentString:
                 @" onMouseOut=\"window.status='OpenGroupware.org';"
                 @"return true\""];
    if (label && !isBlind) {
      [_response appendContentString:@" onMouseOver=\"window.status='"];
      [_response appendContentHTMLAttributeValue:label];
      [_response appendContentString:@"'; return true\""];
    }
    else {
      [_response appendContentString:
                   @" onMouseOver=\"window.status='OpenGroupware.org';"
                   @"return true\""];
    }
    
    [_response appendContentString:@" />"];
  }
  else if (label) {
    [_response appendContentString:label];
  }

  /* close anker */
  if (!isBlind) {
    [_response appendContentString:@"</a>"];
    [_ctx deleteLastElementIDComponent];
  }
}

- (id)invokeActionForRequest:(WORequest *)_rq inContext:(WOContext *)_ctx {
  NSString *eid;
  BOOL forward = YES;

  eid = [_ctx currentElementID];

  if ([eid isEqual:@"next"])          forward = NO;
  else if ([eid isEqual:@"previous"]) forward = NO;
  else if ([eid isEqual:@"first"])    forward = NO;
  else if ([eid isEqual:@"last"])     forward = NO;
  
  if (!forward) {
    WOComponent *sComponent = [_ctx component];
    SEL sel;

    eid = [eid stringByAppendingString:@"Block"];
    sel = NSSelectorFromString(eid);
    
    if ([sComponent respondsToSelector:sel])
      return [sComponent performSelector:sel];
    else {
      NSLog(@"WARNING: %@ does not respond to -%@", sComponent, eid);
      return nil;
    }
  }
  else {
    id result;
    [_ctx appendElementIDComponent:eid];
    result = [self->template invokeActionForRequest:_rq inContext:_ctx];
    [_ctx deleteLastElementIDComponent];
    return result;
  }
}

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  WOResourceManager *rm;
  NSArray           *languages;
  WOComponent       *sComponent = [_ctx component];
  NSString          *sC, *sF, *sS;
  BOOL              hasFont, onFirst, onLast;

  rm        = [[_ctx application] resourceManager];
  languages = [[_ctx session] languages];
  sC = [self->textColor stringValueInComponent:sComponent];
  sF = [self->textFace  stringValueInComponent:sComponent];
  sS = [self->textSize  stringValueInComponent:sComponent];
  hasFont = (sC || sF || sS) ? YES : NO;

  onFirst = [self->isOnFirstPage boolValueInComponent:sComponent];
  onLast  = [self->isOnLastPage  boolValueInComponent:sComponent];
  
  [_response appendContentString:
               @"<table width=\"100%\" border=\"0\" cellpadding=\"4\" "
               @"cellspacing=\"0\"><tr>"];
  
  /* LeftHeaderCell */
  {
    [_response appendContentString:@"<td align=\"left\""];
    if (self->bgcolor) {
      [_response appendContentString:@" bgcolor=\""];
      [_response appendContentHTMLAttributeValue:
                 [self->bgcolor stringValueInComponent:sComponent]];
      [_response appendContentString:@"\""];
    }
    [_response appendContentCharacter:'>'];
    
    if (self->title) {
      if (hasFont)
        [self appendFontToResponse:_response color:sC face:sF size:sS];
      [_response appendContentString:@"<b>"];

      /* title */
      [_response appendContentHTMLString:
                   [self->title stringValueInComponent:sComponent]];

      [_response appendContentString:@"</b>"];
      if (hasFont) [_response appendContentString:@"</font>"];
    }
    else {
      [_response appendContentString:@"&nbsp;"];
    }
    [_response appendContentString:@"</td>"];
  }

  /* RightHeaderCell */
  {
    BOOL doEncode, isBlind;
    
    [_response appendContentString:@"<td align=\"right\" colspan=\"2\""];
    if (self->bgcolor) {
      [_response appendContentString:@" bgcolor=\""];
      [_response appendContentHTMLAttributeValue:
                 [self->bgcolor stringValueInComponent:sComponent]];
      [_response appendContentString:@"\""];
    }
    [_response appendContentCharacter:'>'];




    if (hasFont)
      [self appendFontToResponse:_response color:sC face:sF size:sS];


    [_response appendContentString:
                 @"<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\">"
                 @"<tr>"];    
    
    /* backwards scrollers */
    
    doEncode = (onFirst && !onLast) || (!onFirst);
    isBlind  = (onFirst && !onLast);
    if (doEncode) {
      [_response appendContentString:@"<td valign=\"middle\">"];
      _encodeNavLink(_response, _ctx, rm, languages, @"first",
                     isBlind,
                     [isBlind ? self->firstIconBlind : self->firstIcon
                          stringValueInComponent:sComponent],
                     [self->firstLabel stringValueInComponent:sComponent]);
      [_response appendContentString:@"</td><td valign=\"middle\">"];      
      _encodeNavLink(_response, _ctx, rm, languages, @"previous",
                     isBlind,
                     [isBlind ? self->prevIconBlind : self->prevIcon
                              stringValueInComponent:sComponent],
                     [self->prevLabel stringValueInComponent:sComponent]);
      [_response appendContentString:@"</td>"];      
    }

    /* add template (action buttons) */
    [_response appendContentString:@"<td valign=\"middle\">"];
    [self->template appendToResponse:_response inContext:_ctx];
    [_response appendContentString:@"</td>"];
    
    /* forward scrollers */   
    doEncode = (onLast && !onFirst) || (!onLast);
    isBlind  = (onLast && !onFirst);
    if (doEncode) {
      [_response appendContentString:@"<td valign=\"middle\">"];      
      _encodeNavLink(_response, _ctx, rm, languages, @"next",
                     isBlind,
                     [isBlind ? self->nextIconBlind : self->nextIcon
                              stringValueInComponent:sComponent],
                     [self->nextLabel stringValueInComponent:sComponent]);
      [_response appendContentString:@"</td><td valign=\"middle\">"];      
      _encodeNavLink(_response, _ctx, rm, languages, @"last",
                     isBlind,
                     [isBlind ? self->lastIconBlind : self->lastIcon
                              stringValueInComponent:sComponent],
                     [self->lastLabel stringValueInComponent:sComponent]);
      [_response appendContentString:@"</td>"];
    }
    [_response appendContentString:@"</tr></table>"];
    
    if (hasFont) [_response appendContentString:@"</font>"];
    
    [_response appendContentString:@"</td>"];
  }

  [_response appendContentString:@"</tr></table>"];
}

@end /* LSWTableViewHeader */
