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

@interface LSWTableViewAttributeRow : WODynamicElement
{
  WOAssociation *list;    /* list of attributes */
  WOAssociation *item;    /* current attribute */
  /* the following are dependend on item */
  WOAssociation *bgcolor;
  WOAssociation *textColor;
  WOAssociation *textFace;
  WOAssociation *textSize;
  WOAssociation *label;
  WOAssociation *isSortable;
  WOAssociation *orderIcon;
  WOAssociation *orderIconLabel;
}
@end

@implementation LSWTableViewAttributeRow

- (id)initWithName:(NSString *)_name
  associations:(NSDictionary *)_config
  template:(WOElement *)_subs
{
  if ((self = [super initWithName:_name associations:_config template:_subs])) {
    self->list           = OWGetProperty(_config, @"list");
    self->item           = OWGetProperty(_config, @"item");
    self->bgcolor        = OWGetProperty(_config, @"bgcolor");
    self->textColor      = OWGetProperty(_config, @"textColor");
    self->textFace       = OWGetProperty(_config, @"textFace");
    self->textSize       = OWGetProperty(_config, @"textSize");
    self->label          = OWGetProperty(_config, @"label");
    self->isSortable     = OWGetProperty(_config, @"isSortable");
    self->orderIcon      = OWGetProperty(_config, @"orderIcon");
    self->orderIconLabel = OWGetProperty(_config, @"orderIconLabel");
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->orderIconLabel);
  RELEASE(self->orderIcon);
  RELEASE(self->isSortable);
  RELEASE(self->label);
  RELEASE(self->textSize);
  RELEASE(self->textFace);
  RELEASE(self->textColor);
  RELEASE(self->bgcolor);
  RELEASE(self->item);
  RELEASE(self->list);
  [super dealloc];
}
#endif

/* responder */

static inline void _applyIndex(LSWTableViewAttributeRow *self,
                               NSArray *array, WOComponent *sComponent,
                               unsigned _idx) {
#if 0
  if (self->index)
    [self->index setUnsignedIntValue:_idx inComponent:sComponent];
#endif

  if (self->item) {
    unsigned count = [array count];

    if (_idx < count) {
      [self->item setValue:[array objectAtIndex:_idx]
                  inComponent:sComponent];
    }
    else {
      [sComponent logWithFormat:
                    @"WARNING: array did change, index is invalid."];
      [self->item setValue:nil inComponent:sComponent];
    }
  }
}

- (id)invokeActionForRequest:(WORequest *)_request inContext:(WOContext *)_ctx {
  id result = nil;
  id idxId  = [_ctx currentElementID];

  if (idxId) {
    NSArray     *array;
    WOComponent *sComponent;
    int idx = [idxId intValue];

    sComponent = [_ctx component];
    [_ctx consumeElementID]; // consume index-id

    array = [self->list valueInComponent:sComponent];
    _applyIndex(self, array, sComponent, idx);

    // invoke action
    if ([sComponent respondsToSelector:@selector(sort)])
      result = [sComponent performSelector:@selector(sort)];
    else {
      NSLog(@"WARNING: %@ does not respond to -sort", sComponent);
      return nil;
    }
  }
  else {
    [[_ctx session]
           logWithFormat:@"%@: missing index id in URL !", self];
  }
  return result;
}

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  WOComponent       *sComponent;
  WOResourceManager *rm;
  NSArray           *languages;
  NSArray           *sList;
  int               i, count;
  NSString          *sC, *sF, *sS;
  BOOL              hasFont;

  sComponent = [_ctx component];
  rm         = [[_ctx application] resourceManager];
  languages  = [[_ctx session] languages];
  sC = [self->textColor stringValueInComponent:sComponent];
  sF = [self->textFace  stringValueInComponent:sComponent];
  sS = [self->textSize  stringValueInComponent:sComponent];
  hasFont = (sC || sF || sS) ? YES : NO;
  
  sList = [self->list valueInComponent:sComponent];
  count = [sList count];

  /* open row */
  [_response appendContentString:@"<tr>"];

  [_ctx appendZeroElementIDComponent]; /* repetition index */
  
  /* attribute repetition */
  for (i = 0; i < count; i++) {
    BOOL sIsSortable;

    /* set current attribute in component */
    [self->item setValue:[sList objectAtIndex:i] inComponent:sComponent];

    /* determine if attribute is sortable (requires images in cell) */
    sIsSortable = [self->isSortable boolValueInComponent:sComponent];

    /* attribute cell */
    [_response appendContentString:@"<td valign=\"baseline\""];
    if (self->bgcolor) {
      [_response appendContentString:@" bgcolor=\""];
      [_response appendContentHTMLAttributeValue:
                   [self->bgcolor stringValueInComponent:sComponent]];
      [_response appendContentCharacter:'"'];
    }
    [_response appendContentString:@"><nobr>"];

    if (hasFont)
      [self appendFontToResponse:_response color:sC face:sF size:sS];

    /* real cell content */
    {
      /* add sort-order icon if attribute is sortable */
      if (sIsSortable) {
        NSString *iconUri;
        
        /* OrderingImage (link) */
        [_response appendContentString:@"<a href=\""];
        [_response appendContentString:[_ctx componentActionURL]];
        [_response appendContentString:@"\">"];

        iconUri = [self->orderIcon stringValueInComponent:sComponent];
        iconUri = [rm urlForResourceNamed:iconUri inFramework:nil
                      languages:languages request:[_ctx request]];

        if (iconUri == nil) {
          NSLog(@"%s: did not find resource %@", __PRETTY_FUNCTION__,
                [self->orderIcon valueInComponent:sComponent]);
        }

        [_response appendContentString:@"<img align='top' border='0' src=\""];
        [_response appendContentString:iconUri];
        [_response appendContentCharacter:'"'];
        
        if (self->orderIconLabel) {
          NSString *l;

          if ((l = [self->orderIconLabel stringValueInComponent:sComponent])) {
            [_response appendContentString:@" alt=\""];
            [_response appendContentHTMLAttributeValue:l];
            [_response appendContentString:@"\" onMouseOver=\"window.status='"];
            [_response appendContentHTMLAttributeValue:l];
            [_response appendContentString:@"'; return true\""];
          }
        }
        else {
          [_response appendContentString:
                       @" onMouseOver=\"window.status='sort column';"
                       @"return true\""];
        }

        [_response appendContentString:
                     @" onMouseOut=\"window.status='SKYRIX';"
                     @"return true\""];

        [_response appendContentString:@" />"];
        
        [_response appendContentString:@"</a> "];
      }
      
      /* add label (not HTML escaped) */
      if (self->label) {
        [_response appendContentString:@"<b>"];
        [_response appendContentString:
                   [self->label stringValueInComponent:sComponent]];
        [_response appendContentString:@"</b>"];
      }
    }
    
    if (hasFont) [_response appendContentString:@"&nbsp;</font>"];
    /* close attribute cell */
    [_response appendContentString:@"</nobr></td>"];

    [_ctx incrementLastElementIDComponent]; /* repetition index */
  }

  [_ctx deleteLastElementIDComponent]; /* repetition index */
  
  /* close row */
  [_response appendContentString:@"</tr>"];
}

@end /* LSWTableViewAttributeRow */
