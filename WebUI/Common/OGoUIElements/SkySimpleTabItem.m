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
  The `SkySimpleTabItem` behaves similiar to the `SkyTabItem`, but does
  not require any images. So you just have to assign a 'label' and a 'key',
  e.g.:
  ```
  TabItem: SkySimpleTabItem {
    key    = "key";
    label  = "label";
    action = "tabClicked";
  }
  ```

  The `SkySimpleTabItem` does not support `javaScript`!!!
  
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

static NSDictionary *defAssocs = nil;
static Class        baseClass  = Nil;

+ (void)initialize {
  NSMutableDictionary *md;

  if ((baseClass = NGClassFromString(@"WETabItem")) == Nil)
    NSLog(@"ERROR(%s): missing WETabItem class", __PRETTY_FUNCTION__);
  
  md = [[NSMutableDictionary alloc] initWithCapacity:8];
  
  [md setObject:[WOAssociation associationWithValue:@"tab_.gif"]
      forKey:@"tabIcon"];
  [md setObject:[WOAssociation associationWithValue:@"tab_left.gif"]
      forKey:@"leftTabIcon"];
  [md setObject:[WOAssociation associationWithValue:@"tab_selected.gif"]
      forKey:@"selectedTabIcon"];
  [md setObject:[WOAssociation associationWithValue:@"1"]
      forKey:@"asBackground"];
  
  [md setObject:[WOAssociation associationWithKeyPath:@"config.tab_fixwidth"]
      forKey:@"width"];
  [md setObject:[WOAssociation associationWithKeyPath:@"config.tab_fixheight"]
      forKey:@"height"];
  
  defAssocs = [md copy];
  [md release];
}

- (id)initWithName:(NSString *)_name associations:(NSDictionary *)_config
  template:(WOElement *)_template
{
  [(id)_config addEntriesFromDictionary:defAssocs];
  
  // TODO: should we just release 'self' and return the object?
  self->template = [[baseClass alloc] initWithName:_name
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
