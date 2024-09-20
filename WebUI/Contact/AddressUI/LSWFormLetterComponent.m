/*
  Copyright (C) 2000-2006 SKYRIX Software AG
  Copyright (C) 2006      Helge Hess

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

@class WOResponse;

@interface LSWFormLetterComponent : OGoComponent
{
  WOResponse *data;
}

@end

#include <OGoFoundation/OGoFoundation.h>
#include "common.h"

@implementation LSWFormLetterComponent

- (void)dealloc {
  [self->data release];
  [super dealloc];
}

/* accessors */

- (id)downloadTarget {
  return [[self context] contextID];
}

- (void)setData:(id)_data {
  ASSIGN(self->data, _data);
}
- (id)data {
  return self->data;
}

- (NSString *)size {
  char buf[32];
  snprintf(buf, sizeof(buf), "%ld", [[self->data content] length]);
  return [NSString stringWithCString:buf];
}

@end /* LSWFormLetterComponent */
