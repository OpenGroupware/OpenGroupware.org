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

#include "LSWWarningPanel.h"
#include "common.h"
#include <OGoFoundation/WOComponent+config.h>

@implementation LSWWarningPanel

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->phrase);
  RELEASE(self->onOk);
  RELEASE(self->onCancel);
  [super dealloc];
}
#endif

// accessors

- (void)setOnOk:(NSString *)_onOk {
  ASSIGN(self->onOk, _onOk);
}
- (NSString *)onOk {
  return self->onOk;
}

- (void)setOnCancel:(NSString *)_onCancel {
  ASSIGN(self->onCancel, _onCancel);
}
- (NSString *)onCancel {
  return self->onCancel;
}

- (void)setPhrase:(NSString *)_phrase {
  ASSIGN(self->phrase, _phrase);
}
- (NSString *)phrase {
  return self->phrase;
}

- (NSString *)localPhrase {
  return [[self labels] valueForKey:self->phrase];
}

// actions

- (id)ok {
  return [self performParentAction:self->onOk];
}

- (id)cancel {
  if (self->onCancel == nil)
    return [self performParentAction:@"cancel"];
  return [self performParentAction:self->onCancel];
}

@end /* LSWWarningPanel */
