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

#include "common.h"

/*
  renders this:

    <b><i><u><small>
    <font color=config.font_color
          size=config.font_size
          face=config.font_face>
      $content
    </font>
    </small></u></i></b>
  
  Config Attributes:
    config.font_color
    config.font_size
    config.font_face
*/

@interface SkyRichString : WODynamicElement
{
  WOElement *template;
}
@end

@implementation SkyRichString

- (id)initWithName:(NSString *)_name
  associations:(NSDictionary *)_config
  template:(WOElement *)_template
{
  WOAssociation *a;
  Class         c;

  if ((c = NGClassFromString(@"WERichString")) == Nil) {
    NSLog(@"%s: missing WERichString class", __PRETTY_FUNCTION__);
    [self release];
    return nil;
  }
  
#define SetAssociationValue(_key_, _value_)                                 \
             if ([_config objectForKey:_key_] == nil) {                     \
               a = [WOAssociation associationWithValue:_value_];            \
               [(NSMutableDictionary *)_config setObject:a forKey:_key_];   \
             }                                                              \

#define SetAssociationPath(_key_, _path_)                                   \
             if ([_config objectForKey:_key_] == nil) {                     \
               a = [WOAssociation associationWithKeyPath:_path_];           \
               [(NSMutableDictionary *)_config setObject:a forKey:_key_];   \
             }                                                              \
  
  SetAssociationPath(@"color", @"config.font_color");
  SetAssociationPath(@"size",  @"config.font_size");
  SetAssociationPath(@"face",  @"config.font_face");

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

/* handle requests (TODO: is a forward really necessary?) */

- (void)takeValuesFromRequest:(WORequest *)_req inContext:(WOContext *)_ctx {
  [self->template takeValuesFromRequest:_req inContext:_ctx];
}

- (id)invokeActionForRequest:(WORequest *)_req inContext:(WOContext *)_ctx {
  return [self->template invokeActionForRequest:_req inContext:_ctx];
}

/* generate response */

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  [self->template appendToResponse:_response inContext:_ctx];
}

@end /* SkyRichString */
