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

#include <NGObjWeb/WODynamicElement.h>

/*
  TODO: document what it does and where it is used
*/

@interface OGoPageButton : WODynamicElement
{
  WOElement *template;
}

@end

@interface OGoSavePageButton : OGoPageButton
@end

@interface OGoCancelPageButton : OGoPageButton
@end

@interface OGoCustomPageButton : OGoPageButton
{
  WOAssociation *labelKey;
}

@end

#include "common.h"
#include <OGoFoundation/OGoComponent.h>

@implementation OGoPageButton

- (id)initWithName:(NSString *)_name
  associations:(NSDictionary *)_config
  template:(WOElement *)_t
{
  if ((self = [super initWithName:_name associations:_config template:_t])) {
    self->template = [_t retain];
  }
  return self;
}

- (void)dealloc {
  [self->template release];
  [super dealloc];
}

/* generate response */

- (NSString *)labelKeyInContext:(WOContext *)_ctx {
  return nil;
}
- (NSString *)labelInContext:(WOContext *)_ctx {
  NSString *lk;
  
  lk = [self labelKeyInContext:_ctx];
  return [[[_ctx component] labels] valueForKey:lk];
}

- (BOOL)writeFormButtonInContext:(WOContext *)_ctx {
  if (![_ctx isInForm])
    return NO;
  
  return YES;
}

- (void)appendToResponse:(WOResponse *)_r inContext:(WOContext *)_ctx {
}

@end /* OGoPageButton */

@implementation OGoSavePageButton

- (NSString *)labelKeyInContext:(WOContext *)_ctx {
  return @"save";
}

@end /* OGoSavePageButton */

@implementation OGoCancelPageButton

- (NSString *)labelKeyInContext:(WOContext *)_ctx {
  return @"cancel";
}

@end /* OGoCancelPageButton */

@implementation OGoCustomPageButton

- (id)initWithName:(NSString *)_name
  associations:(NSDictionary *)_config
  template:(WOElement *)_t
{
  if ((self = [super initWithName:_name associations:_config template:_t])) {
    self->labelKey = [[_config objectForKey:@"labelKey"] retain];
  }
  return self;
}

- (void)dealloc {
  [self->labelKey release];
  [super dealloc];
}

- (NSString *)labelKeyInContext:(WOContext *)_ctx {
  return [self->labelKey stringValueInComponent:[_ctx component]];
}

@end /* OGoCustomPageButton */
