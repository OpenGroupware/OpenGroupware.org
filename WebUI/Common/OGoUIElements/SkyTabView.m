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
  NOTE: Does not support tab-head-creation from nested components !
  
  Please take a look at 'WETabView.m', defined in 'WEExtensions'!
*/

/*
  requires:

  corner_left.gif
  corner_right.gif

  *iconname*.gif             // *iconname* comes from SkyTabItem.icon
  *iconname*_left.gif
  *iconname*_selected.gif
*/

/*
  Usage: TODO: is this still SkyTabItem and *not* WETabItem instead?

  TabView: SkyTabView {
    selection = selection;
  }
  FirstTab: SkyTabItem {
    key    = "first";
    label  = labels.persons;
    action = personTabClicked;
  }
  SecondTab: SkyTabItem {
    key    = "second";
    label  = "labels.projects";
    action = projectsTabClicked;
  }

  <#TabView>
    <#FirstTab >content of first tab</#FirstTab>
    <#SecondTab>content of second tab</#SecondTab>
  </#TabView>
*/

#include "common.h"

@interface SkyTabView : WODynamicElement
{
  WOElement *template;
}
@end

@implementation SkyTabView

- (id)initWithName:(NSString *)_name
  associations:(NSDictionary *)_config
  template:(WOElement *)_template
{
  WOAssociation *a;
  Class         c;
  
  if ((c = NSClassFromString(@"WETabView")) == Nil) {
    NSLog(@"%s: missing WETabView class", __PRETTY_FUNCTION__);
    [self release];
    return nil;
  }

  // TODO: use CSS

#define SetAssociationValue(_key_, _value_)                                 \
             if ([_config objectForKey:_key_] == nil) {                     \
               a = [WOAssociation associationWithValue:_value_];            \
               [(NSMutableDictionary *)_config setObject:a forKey:_key_];   \
             }
  
  if ([_config objectForKey:@"bgColor"] == nil) {
    a = [WOAssociation associationWithKeyPath:@"config.colors_tabLeaf"];
    [(NSMutableDictionary *)_config setObject:a forKey:@"bgColor"];
  }
  
  SetAssociationValue(@"leftCornerIcon",  @"corner_left.gif");
  SetAssociationValue(@"rightCornerIcon", @"corner_right.gif");
  SetAssociationValue(@"fontColor",       @"black");

  if ([_config objectForKey:@"fontSize"] == nil) {
    a = [[NSClassFromString(@"SkyTabFontAssociation") alloc] init];
    [(NSMutableDictionary *)_config setObject:a forKey:@"fontSize"];
    [a release];;
  }
  
#undef SetAssociationPath
#undef SetAssociationValue
  
  self->template = [[c alloc] initWithName:_name
                              associations:_config
                              template:_template];
  return self;
}

- (void)dealloc {
  [self->template release];
  [super dealloc];
}

/* request processing */

- (void)takeValuesFromRequest:(WORequest *)_req inContext:(WOContext *)_ctx {
  [self->template takeValuesFromRequest:_req inContext:_ctx];
}

- (id)invokeActionForRequest:(WORequest *)_req inContext:(WOContext *)_ctx {
  return [self->template invokeActionForRequest:_req inContext:_ctx];
}

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  [self->template appendToResponse:_response inContext:_ctx];
}

@end /* SkyTabView */
