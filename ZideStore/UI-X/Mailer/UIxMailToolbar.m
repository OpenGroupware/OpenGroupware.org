/*
  Copyright (C) 2004 SKYRIX Software AG

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
// $Id$

#include <SOGoUI/UIxComponent.h>

@class NSArray, NSDictionary;

@interface UIxMailToolbar : UIxComponent
{
  NSArray      *toolbarConfig;
  NSArray      *toolbarGroup;
  NSDictionary *buttonInfo;
}
@end

#include <SOGo/SoObjects/Mailer/SOGoMailBaseObject.h>
#include "common.h"
#include <NGObjWeb/SoComponent.h>

@implementation UIxMailToolbar

- (void)dealloc {
  [self->toolbarGroup  release];
  [self->toolbarConfig release];
  [self->buttonInfo    release];
  [super dealloc];
}

/* notifications */

- (void)sleep {
  [self->toolbarGroup  release]; self->toolbarGroup  = nil;
  [self->toolbarConfig release]; self->toolbarConfig = nil;
  [self->buttonInfo    release]; self->buttonInfo    = nil;
  [super sleep];
}

/* accessors */

- (void)setToolbarGroup:(id)_group {
  ASSIGN(self->toolbarGroup, _group);
}
- (id)toolbarGroup {
  return self->toolbarGroup;
}

- (void)setButtonInfo:(id)_info {
  ASSIGN(self->buttonInfo, _info);
}
- (id)buttonInfo {
  return self->buttonInfo;
}

/* toolbar */

- (id)toolbarConfig {
  id tmp;
  
  if (self->toolbarConfig != nil)
    return [self->toolbarConfig isNotNull] ? self->toolbarConfig : nil;
  
  tmp = [[self clientObject] lookupName:@"toolbar" inContext:[self context]
			     acquire:NO];
  if ([tmp isKindOfClass:[NSException class]]) {
    [self errorWithFormat:
            @"not toolbar configuration found on SoObject: %@ (%@)",
            [self clientObject], [[self clientObject] soClass]];
    self->toolbarConfig = [[NSNull null] retain];
    return nil;
  }
  self->toolbarConfig = [tmp retain];
  return self->toolbarConfig;
}

/* labels */

- (NSString *)buttonLabel {
  WOResourceManager *rm;
  NSArray           *languages;
  WOContext         *ctx;
  NSString          *key, *label;

  key = [[self buttonInfo] valueForKey:@"label"];
  
  /* lookup languages */
  
  ctx = [self context];
  languages = [ctx hasSession]
    ? [[ctx session] languages]
    : [[ctx request] browserLanguages];

  /* lookup resource manager */
  
  if ((rm = [self resourceManager]) == nil)
    rm = [[WOApplication application] resourceManager];
  if (rm == nil)
    [self warnWithFormat:@"missing resource manager!"];
  
  /* lookup string */
  
  label = [rm stringForKey:key inTableNamed:nil withDefaultValue:key
              languages:languages];
  return label;
}

@end /* UIxMailToolbar */
