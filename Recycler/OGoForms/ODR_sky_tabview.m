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

#include <NGObjDOM/ODR_bind_tabview.h>
#include <OGoFoundation/OGoComponent.h>

@interface ODR_sky_tabview : ODR_bind_tabview
@end

#include "common.h"

@implementation ODR_sky_tabview

- (void)appendNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  id config;

  config = [[_ctx component] config];
  
#define SetAttributeValue(_value_, _key_)                                 \
        if (![self hasAttribute:_key_ node:_node ctx:_ctx])               \
          [self forceSetString:_value_ for:_key_ node:_node ctx:_ctx];    \

  SetAttributeValue(@"corner_left.gif",         @"leftcornericon");
  SetAttributeValue(@"corner_right.gif",        @"rightcornericon");
  
  SetAttributeValue(@"tab_selected.gif",        @"activebgicon");
  SetAttributeValue(@"tab_.gif",                @"bgicon");
  SetAttributeValue(@"tab_left.gif",            @"bgiconleft");
  
  SetAttributeValue(@"100",                     @"width");
  SetAttributeValue(@"22",                      @"height");
  
  SetAttributeValue(@"black",                   @"fontcolor");
  //SetAttributeValue(@"-1",                      @"fontsize");
  
  SetAttributeValue([config valueForKey:@"colors_tabLeaf"], @"bgcolor");
  
  [super appendNode:_node toResponse:_response inContext:_ctx];

#undef SetAttributeValue
}

@end /* ODR_skytabview */
