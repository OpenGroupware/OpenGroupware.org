/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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

#include "PPClassDescription.h"

@implementation PPClassDescription

- (id)initWithClass:(Class)_c {
  self->recordClass = _c;
  return self;
}
- (id)initWithClass:(Class)_c creator:(long)_creator type:(long)_type {
  self->recordClass = _c;
  self->creator = _creator;
  self->type    = _type;
  return self;
}

- (long)creator {
  return self->creator;
}
- (long)type {
  return self->type;
}

- (NSString *)entityName {
  NSString *recClassName;

  recClassName = NSStringFromClass(self->recordClass);
  recClassName = [recClassName substringFromIndex:2];
  recClassName = [recClassName substringToIndex:([recClassName length] - 6)];
  recClassName = [recClassName stringByAppendingString:@"DB"];
  
  return recClassName;
}

/* description */

- (NSString *)description {
  return [NSString stringWithFormat:
                     @"<0x%08X[%@]: name=%@ creator=%04X type=%04X>",
                     self, NSStringFromClass([self class]),
                     [self entityName],
                     [self creator],
                     [self type]];
}

@end /* PPClassDescription */
