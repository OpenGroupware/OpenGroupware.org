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

#import <NGObjWeb/WODynamicElement.h>
#include "LSWTableView.h"
#include "common.h"

@class WOAssociation, WOElement;

@interface LSWTableViewFooter : WODynamicElement
{
  WOAssociation *bgcolor;
  WOAssociation *textColor;
  WOAssociation *textFace;
  WOAssociation *textSize;
  WOAssociation *label;       /* label shown in the left         */
  WOAssociation *pageLabel;   /* label shown in the right        */
  WOAssociation *toLabel;     /* label in '1 <to> 10 of 100'     */
  WOAssociation *ofLabel;     /* label in '1 to 10 <of> 100'     */
  WOAssociation *pageIndex;   /* number of current page          */
  WOAssociation *pageCount;   /* number of pages                 */
  WOAssociation *firstIndex;  /* index of first object displayed */
  WOAssociation *lastIndex;   /* index of last object displayed  */
  WOAssociation *count;       /* number of objects               */
}

@end

@implementation LSWTableViewFooter

- (id)initWithName:(NSString *)_name
  associations:(NSDictionary *)_config
  template:(WOElement *)_subs
{
  if ((self = [super initWithName:_name associations:_config template:_subs])) {
    self->bgcolor    = OWGetProperty(_config, @"bgcolor");
    self->textColor  = OWGetProperty(_config, @"textColor");
    self->textFace   = OWGetProperty(_config, @"textFace");
    self->textSize   = OWGetProperty(_config, @"textSize");
    self->label      = OWGetProperty(_config, @"label");
    self->pageLabel  = OWGetProperty(_config, @"pageLabel");
    self->toLabel    = OWGetProperty(_config, @"toLabel");
    self->ofLabel    = OWGetProperty(_config, @"ofLabel");
    self->pageIndex  = OWGetProperty(_config, @"pageIndex");
    self->pageCount  = OWGetProperty(_config, @"pageCount");
    self->firstIndex = OWGetProperty(_config, @"firstIndex");
    self->lastIndex  = OWGetProperty(_config, @"lastIndex");
    self->count      = OWGetProperty(_config, @"count");
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->count);
  RELEASE(self->firstIndex);
  RELEASE(self->lastIndex);
  RELEASE(self->pageIndex);
  RELEASE(self->pageCount);
  RELEASE(self->ofLabel);
  RELEASE(self->toLabel);
  RELEASE(self->label);
  RELEASE(self->pageLabel);
  RELEASE(self->textSize);
  RELEASE(self->textFace);
  RELEASE(self->textColor);
  RELEASE(self->bgcolor);
  [super dealloc];
}
#endif

/* responder */

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  WOComponent *sComponent = [_ctx component];
  NSString    *sC, *sF, *sS;
  BOOL        hasFont;

  sC = [self->textColor stringValueInComponent:sComponent];
  sF = [self->textFace  stringValueInComponent:sComponent];
  sS = [self->textSize  stringValueInComponent:sComponent];
  hasFont = (sC || sF || sS) ? YES : NO;
  
  [_response appendContentString:
               @"<TABLE WIDTH=\"100%\" BORDER=0 CELLPADDING=1 CELLSPACING=0>\n"
               @"  <TR>\n"];

  /* LeftFooterCell */
  {
    [_response appendContentString:@"<TD ALIGN=left"];
    if (self->bgcolor) {
      [_response appendContentString:@" BGCOLOR=\""];
      [_response appendContentHTMLAttributeValue:
                 [self->bgcolor stringValueInComponent:sComponent]];
      [_response appendContentString:@"\""];
    }
    [_response appendContentCharacter:'>'];

    if (hasFont)
      [self appendFontToResponse:_response color:sC face:sF size:sS];
    [_response appendContentString:@"<SMALL>"];

    /* add label */
    if (self->label) {
      [_response appendContentHTMLString:
                   [self->label stringValueInComponent:sComponent]];
      [_response appendContentHTMLString:@": "];
    }

    /* add first object index */
    if (self->firstIndex) {
      [_response appendContentHTMLString:
                   [self->firstIndex stringValueInComponent:sComponent]];
      
      /* separator */
      if (self->toLabel) {
        [_response appendContentCharacter:' '];
        [_response appendContentHTMLString:
                   [self->toLabel stringValueInComponent:sComponent]];
        [_response appendContentCharacter:' '];
      }
      else
        [_response appendContentHTMLString:@" .. "];
      
      /* add last object index */
      if (self->lastIndex) {
        [_response appendContentHTMLString:
                   [self->lastIndex stringValueInComponent:sComponent]];
      }
    }
    
    /* add object count */
    if (self->count) {
      /* separator */
      if (self->firstIndex) {
        if (self->ofLabel) {
          [_response appendContentCharacter:' '];
          [_response appendContentHTMLString:
                       [self->ofLabel stringValueInComponent:sComponent]];
          [_response appendContentCharacter:' '];
        }
        else
          [_response appendContentHTMLString:@" ["];
      }
      
      [_response appendContentHTMLString:
                   [self->count stringValueInComponent:sComponent]];

      if (self->ofLabel == nil)
        [_response appendContentHTMLString:@"]"];
    }
    
    [_response appendContentString:@"</SMALL>"];
    if (hasFont) [_response appendContentString:@"</FONT>"];
    [_response appendContentString:@"</TD>"];
  }

  /* RightFooterCell */
  {
    [_response appendContentString:@"<TD ALIGN=right"];
    if (self->bgcolor) {
      [_response appendContentString:@" BGCOLOR=\""];
      [_response appendContentHTMLAttributeValue:
                 [self->bgcolor stringValueInComponent:sComponent]];
      [_response appendContentString:@"\""];
    }
    [_response appendContentCharacter:'>'];

    if (hasFont)
      [self appendFontToResponse:_response color:sC face:sF size:sS];
    [_response appendContentString:@"<SMALL>"];

    /* add page label */
    if (self->pageLabel) {
      [_response appendContentHTMLString:
                   [self->pageLabel stringValueInComponent:sComponent]];
      [_response appendContentHTMLString:@": "];
    }

    /* add current page index */
    if (self->pageIndex) {
      [_response appendContentHTMLString:
                   [self->pageIndex stringValueInComponent:sComponent]];
    }

    if ((self->pageIndex != nil) && (self->pageCount != nil))
      [_response appendContentHTMLString:@" / "];
    
    /* add total page count */
    if (self->pageCount) {
      [_response appendContentHTMLString:
                   [self->pageCount stringValueInComponent:sComponent]];
    }

    [_response appendContentString:@"</SMALL>"];
    if (hasFont) [_response appendContentString:@"</FONT>"];
    [_response appendContentString:@"</TD>"];
  }

  [_response appendContentString:@"  </TR>\n</TABLE>"];
}

@end /* LSWTableViewFooter */
