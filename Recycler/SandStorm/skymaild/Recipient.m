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

#include "Recipient.h"
#include "common.h"

@implementation Recipient

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->email);
  RELEASE(self->header);

  [super dealloc];
}
#endif

- (NSString *)email {
  return self->email;
}
- (void)setEmail:(NSString *)_email {
  ASSIGN(self->email, _email);
}

- (NSString *)header {
  return self->header;
}
- (void)setHeader:(NSString *)_header {
  ASSIGN(self->header, _header);
}

@end // Recipient
