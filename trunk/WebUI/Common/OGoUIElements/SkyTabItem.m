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

#if USE_IMG_TAB_ITEM
@interface SkyTabItem : WODynamicElement
{
  WOElement *template;
}
@end
#endif

#if USE_IMG_TAB_ITEM

@implementation SkyTabItem

- (id)initWithName:(NSString *)_name
  associations:(NSDictionary *)_config
  template:(WOElement *)_template
{
  SkyTabAssociation *a;
  WOAssociation     *icon;
  Class             c;

  if ((c = NSClassFromString(@"WETabItem")) == Nil) {
    NSLog(@"%s: missing WETabItem class", __PRETTY_FUNCTION__);
    [self release];
    return nil;
  }

  if ((icon = [_config objectForKey:@"icon"])) {
#define SetTabIcon(_key_, _suffix_)                                         \
    {                                                                       \
      a = [[SkyTabAssociation alloc] initWithIcon:icon andSuffix:_suffix_]; \
      [a autorelease];                                                      \
      [(NSMutableDictionary *)_config setObject:a forKey:_key_];            \
    }                                                                       \

    SetTabIcon(@"tabIcon",         @".gif");
    SetTabIcon(@"leftTabIcon",     @"_left.gif");
    SetTabIcon(@"selectedTabIcon", @"_selected.gif");

#undef SetTabIcon
  }
  self->template = [[c alloc] initWithName:_name
                              associations:_config
                              template:_template];
  return self;
}

- (void)dealloc {
  [self->template release];
  [super dealloc];
}

- (void)takeValuesFromRequest:(WORequest *)_req inContext:(WOContext *)_ctx {
  [self->template takeValuesFromRequest:_req inContext:_ctx];
}

- (id)invokeActionForRequest:(WORequest *)_req inContext:(WOContext *)_ctx {
  return [self->template invokeActionForRequest:_req inContext:_ctx];
}

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  [self->template appendToResponse:_response inContext:_ctx];
}

@end /* SkyTabItem */

#endif /* USE_IMG_TAB_ITEM */
