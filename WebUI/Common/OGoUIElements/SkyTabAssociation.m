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

#include <NGObjWeb/WOAssociation.h>

@interface SkyTabAssociation : WOAssociation
{
  WOAssociation *icon;
  NSString      *suffix;
}
@end

#include "common.h"

@implementation SkyTabAssociation

- (id)initWithIcon:(WOAssociation *)_icon andSuffix:(NSString *)_suffix {
  if ((self = [super init])) {
    self->icon   = [_icon   retain];
    self->suffix = [_suffix retain];
  }
  return self;
}
- (void)dealloc {
  [self->icon   release];
  [self->suffix release];
  [super dealloc];
}

- (id)valueInComponent:(WOComponent *)_cmp {
  NSString *img;

  img = [self->icon stringValueInComponent:_cmp];
  img = [@"tab_" stringByAppendingString:img];
  img = [img stringByAppendingString:self->suffix];
  return img;
}

@end /* SkyTabAssociation */
