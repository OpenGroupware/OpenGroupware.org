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

#include <NGObjDOM/ODR_bind_tableview.h>
#include <OGoFoundation/OGoComponent.h>

@interface ODR_sky_tableview : ODR_bind_tableview
@end

//#define PROFILE 1

#include "common.h"

@implementation ODR_sky_tableview

static Class lastCtxClass = Nil;
static IMP   setObjForKey = NULL;

static void
_SetConfigValue(ODR_sky_tableview *self, id cfg, WOContext *_ctx,
                NSString *_attr_, NSString *_key_)
{
  register NSString *tmp;
  
  if ((tmp = [cfg valueForKey:_attr_])) {
    if (lastCtxClass != *(Class *)_ctx) {
      lastCtxClass = *(Class *)_ctx;
      setObjForKey = [_ctx methodForSelector:@selector(setObject:forKey:)];
    }
    
    if (setObjForKey)
      setObjForKey(_ctx, @selector(setObject:forKey:), tmp, _key_);
    else
      [_ctx setObject:tmp forKey:_key_];
  }
}
static void
_SetLabelValue(ODR_sky_tableview *self, id labels, WOContext *_ctx,
               NSString *_attr_, NSString *_key_)
{
  register NSString *tmp;
  
  if ((tmp = [labels valueForKey:_attr_])) {
    if (lastCtxClass != *(Class *)_ctx) {
      lastCtxClass = *(Class *)_ctx;
      setObjForKey = [_ctx methodForSelector:@selector(setObject:forKey:)];
    }
    
    if (setObjForKey)
      setObjForKey(_ctx, @selector(setObject:forKey:), tmp, _key_);
    else
      [_ctx setObject:tmp forKey:_key_];
  }
}

- (void)_setConfigDefaults:(id)_node inContext:(WOContext *)_ctx {
  id cfg;
  id labels;
  BEGIN_PROFILE;

  cfg    = [[_ctx component] config];
  labels = [[_ctx component] labels];
  
#define SetConfigValue(_attr_, _key_) \
  _SetConfigValue(self, cfg, _ctx, _attr_, _key_)

#define SetLabelValue(_attr_, _key_) \
  _SetLabelValue(self, labels, _ctx, _attr_, _key_)
  
  [_ctx setObject:@"first.gif"           forKey:ODRTableView_first];
  [_ctx setObject:@"first_blind.gif"     forKey:ODRTableView_first_blind];
  [_ctx setObject:@"previous.gif"        forKey:ODRTableView_previous];
  [_ctx setObject:@"previous_blind.gif"  forKey:ODRTableView_previous_blind];
  [_ctx setObject:@"next.gif"            forKey:ODRTableView_next];
  [_ctx setObject:@"next_blind.gif"      forKey:ODRTableView_next_blind];
  [_ctx setObject:@"last.gif"            forKey:ODRTableView_last];
  [_ctx setObject:@"last_blind.gif"      forKey:ODRTableView_last_blind];
  [_ctx setObject:@"expanded.gif"        forKey:ODRTableView_openedIcon];
  [_ctx setObject:@"collapsed.gif"       forKey:ODRTableView_closedIcon];
  [_ctx setObject:@"minus.gif"           forKey:ODRTableView_minusIcon];
  [_ctx setObject:@"plus.gif"            forKey:ODRTableView_plusIcon];

  PROFILE_CHECKPOINT("icons A");
  
  [_ctx setObject:@"downward_sorted.gif" forKey:ODRTableView_downwardIcon];
  [_ctx setObject:@"upward_sorted.gif"   forKey:ODRTableView_upwardIcon];
  [_ctx setObject:@"non_sorted.gif"      forKey:ODRTableView_nonSortIcon];

  PROFILE_CHECKPOINT("icons B");
  
  SetConfigValue(@"colors_tableViewHeaderCell",    ODRTableView_titleColor);
  SetConfigValue(@"colors_tableViewAttributeCell", ODRTableView_headerColor);
  SetConfigValue(@"colors_tableViewFooterCell",    ODRTableView_footerColor);
  SetConfigValue(@"colors_tableViewGroupCell",     ODRTableView_groupColor);
  SetConfigValue(@"colors_evenRow",                ODRTableView_evenColor);
  SetConfigValue(@"colors_oddRow",                 ODRTableView_oddColor);
  SetConfigValue(@"font_color",                    ODRTableView_fontColor);
  SetConfigValue(@"font_face",                     ODRTableView_fontFace);
  SetConfigValue(@"font_size",                     ODRTableView_fontSize);

  PROFILE_CHECKPOINT("colors, fonts");
  
  SetLabelValue(@"of",         ODRTableView_ofLabel);
  SetLabelValue(@"to",         ODRTableView_toLabel);
  SetLabelValue(@"first",      ODRTableView_firstLabel);
  SetLabelValue(@"previous",   ODRTableView_previousLabel);
  SetLabelValue(@"next",       ODRTableView_nextLabel);
  SetLabelValue(@"last",       ODRTableView_lastLabel);
  SetLabelValue(@"page",       ODRTableView_pageLabel);
  SetLabelValue(@"sortColumn", ODRTableView_sortLabel);
  
  PROFILE_CHECKPOINT("labels");
  
  // SetConfigInContext(@"selectAllIcon",   ODRTableView_select_all);
  // SetConfigInContext(@"deselectAllIcon", ODRTableView_deselect_all);
  
  // minusResizeIcon   = "minus.gif";
  // plusResizeIcon    = "plus.gif";
#undef SetConfigValue
#undef SetLabelValue

  END_PROFILE;
}

@end /* ODR_sky_tableview */
