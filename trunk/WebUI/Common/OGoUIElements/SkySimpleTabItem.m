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
  The SkySimpleTabItem behaves similiar to the SkyTabItem, but does
  not require any images. So you just have to assign a 'label' and a 'key',
  e.g.:

  TabItem: SkySimpleTabItem {
    key    = "key";
    label  = "label";
    action = "tabClicked";
  }

  The SkySimpleTabItem does not support javaScript!!!
  
  Please also take a look at 'SkyTabView.m' and 'WETabView.m'!
*/

#include "common.h"

@interface SkySimpleTabItem : WODynamicElement
{
  WOElement *template;
}
@end

@interface SkyTabItem : SkySimpleTabItem /* replace img based TabItems ... */
@end

@implementation SkyTabItem
@end

@implementation SkySimpleTabItem

- (id)initWithName:(NSString *)_name
  associations:(NSDictionary *)_config
  template:(WOElement *)_template
{
  WOAssociation *a;
  Class         c;

  if ((c = NSClassFromString(@"WETabItem")) == Nil) {
    NSLog(@"ERROR(%s): missing WETabItem class", __PRETTY_FUNCTION__);
    [self release];
    return nil;
  }
  
#define SetAssociationValue(_key_, _value_)                                 \
             if ([_config objectForKey:_key_] == nil) {                     \
               a = [WOAssociation associationWithValue:_value_];            \
               [(NSMutableDictionary *)_config setObject:a forKey:_key_];   \
             }                                                              \
 
  SetAssociationValue(@"asBackground",     @"1");
  SetAssociationValue(@"width",            @"100");
  SetAssociationValue(@"height",           @"22");
  SetAssociationValue(@"tabIcon",          @"tab_.gif");
  SetAssociationValue(@"leftTabIcon",      @"tab_left.gif");
  SetAssociationValue(@"selectedTabIcon",  @"tab_selected.gif");

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

/* processing requests */

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

@end /* SkySimpleTabItem */
