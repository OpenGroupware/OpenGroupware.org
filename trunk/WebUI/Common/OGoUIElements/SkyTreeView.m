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

/*
  SkyTreeView
  
  This one wraps the WETreeView and preconfigures some icons.

  requires:
            treeview_vertical_13.gif
            treeview_plus_13.gif
            treeview_minus_13.gif
            treeview_plus_corner_13.gif
            treeview_minus_corner_13.gif
            treeview_leaf_13.gif
            treeview_leaf_corner_13.gif
            treeview_junction_13.gif
            treeview_corner_13.gif
            treeview_space_13.gif

  Example:

    TestTree.wod:
      --- snip ---
      TestTree: SkyTreeView {
        list    = rootList;
        item    = item;
        sublist = item.sublist;
        zoom    = treeState.isExpanded; // take a look at LSWTreeState !!!
        // if you leave out *zoom*, the tree is rendered full expanded
        // and without plus and minus icons
      };
      TreeDataCell: WETreeData {
        isTreeElement = YES;
      };
      DataCell: WETreeData {
        isTreeElement = NO;
      };

      TreeHeaderCell: WETreeHeader {
        isTreeElement = YES;
      };
      HeaderCell: WETreeHeader {
        isTreeElement = NO;
      };

      --- snap ---

    TestTree.html:
      --- snip ---
      <#TestTree>
        <!--- tree header --->
          <#TreeHeaderCell>some title</#TreeHeaderCell>
          <#HeaderCell>some title</#HeaderCell>
          <#HeaderCell>some title</#HeaderCell>

        <!-- tree content -->

          <#TreeDataCell>some content</#TreeDataCell>
          <#DataCell>some content</#DataCell>
          <#DataCell>some content</#DataCell>
      </#TreeDataCell>
      --- snap ---
*/

#include <NGObjWeb/WODynamicElement.h>

@interface SkyTreeView : WODynamicElement
{
  WOElement *template;
}
@end

#include "common.h"

@implementation SkyTreeView

- (id)initWithName:(NSString *)_name
  associations:(NSDictionary *)_config
  template:(WOElement *)_subs
{
  WOAssociation *a;
  Class         c;

  if ((c = NSClassFromString(@"WETreeView")) == Nil) {
    NSLog(@"%s: missing WETreeView class", __PRETTY_FUNCTION__);
    RELEASE(self);
    return nil;
  }

#define SetAssociationValue(_key_, _value_)                                 \
             if ([_config objectForKey:_key_] == nil) {                     \
               a = [WOAssociation associationWithValue:_value_];            \
               [(NSMutableDictionary *)_config setObject:a forKey:_key_];   \
             }                                                              \

  SetAssociationValue(@"iconWidth",       @"13");
  SetAssociationValue(@"plusIcon",        @"treeview_plus_13.gif");
  SetAssociationValue(@"minusIcon",       @"treeview_minus_13.gif");
  SetAssociationValue(@"cornerPlusIcon",  @"treeview_plus_corner_13.gif");
  SetAssociationValue(@"cornerMinusIcon", @"treeview_minus_corner_13.gif");
  SetAssociationValue(@"leafIcon",        @"treeview_leaf_13.gif");
  SetAssociationValue(@"leafCornerIcon",  @"treeview_leaf_corner_13.gif");
  SetAssociationValue(@"junctionIcon",    @"treeview_junction_13.gif");
  SetAssociationValue(@"cornerIcon",      @"treeview_corner_13.gif");  
  SetAssociationValue(@"lineIcon",        @"treeview_vertical_13.gif");
  SetAssociationValue(@"spaceIcon",       @"treeview_space_13.gif");
  
#undef SetAssociationValue

  self->template = [[c alloc] initWithName:_name
                              associations:_config
                              template:_subs];

  return self;
}

- (void)dealloc {
  [self->template release];
  [super dealloc];
}

/* handling requests */

- (void)takeValuesFromRequest:(WORequest *)_req inContext:(WOContext *)_ctx {
  [self->template takeValuesFromRequest:_req inContext:_ctx];
}

- (id)invokeActionForRequest:(WORequest *)_req inContext:(WOContext *)_ctx {
  return [self->template invokeActionForRequest:_req inContext:_ctx];
}

/* generating response */

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  [self->template appendToResponse:_response inContext:_ctx];
}

@end /* SkyTreeView */
