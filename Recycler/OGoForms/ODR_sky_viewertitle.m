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

#include <NGObjDOM/ODR_bind_viewertitle.h>

@interface ODR_sky_viewertitle : ODR_bind_viewertitle
@end

#include "common.h"
#include <OGoFoundation/OGoComponent.h>

@implementation ODR_sky_viewertitle

- (void)appendNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  id config;

  config = [[_ctx component] config];
  
#define SetConfigValue(_value_, _key_)                                    \
     {                                                                    \
       id tmp = nil;                                                      \
        if (![self hasAttribute:_key_ node:_node ctx:_ctx] &&             \
            (tmp = [config valueForKey:_value_]))                         \
          [self forceSetString:tmp for:_key_ node:_node ctx:_ctx];        \
     }                                                                    \

  SetConfigValue(@"colors_mainButtonRow", @"bgcolor");
  SetConfigValue(@"font_color",           @"textcolor");
  SetConfigValue(@"font_face",            @"fontface");
  SetConfigValue(@"font_size",            @"fontsize");
  
  [super appendNode:_node toResponse:_response inContext:_ctx];

#undef SetConfigValue  
}

@end /* ODR_sky_viewertitle */
