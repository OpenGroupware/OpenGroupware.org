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

#include <OGoFoundation/OGoComponent.h>

@class NSString;

@interface OGoMenuBox : OGoComponent
{
  NSString *title;
}
@end

#include "common.h"

@implementation OGoMenuBox

- (void)dealloc {
  [self->title release];
  [super dealloc];
}

/* accessors */

- (void)setTitle:(NSString *)_s {
  ASSIGNCOPY(self->title, _s);
}
- (NSString *)title {
  return self->title;
}

/* notifications */

- (void)sleep {
  [self->title release]; self->title = nil;
  [super sleep];
}

@end /* OGoMenuBox */
