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

#import "common.h"
#include <OGoFoundation/OGoFoundation.h>
#import "LSWFormLetterComponent.h"

@implementation LSWFormLetterComponent

- (id)init {
  if ((self = [super init])) {
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  [super dealloc];
}
#endif

- (NSString *)size {
  return [NSString stringWithFormat:@"%d", [[self->data content] length]];
}
                    
- (id)downloadTarget {
  return [[self context] contextID];
}

- (void)setData:(id)_data {
  self->data = _data;
}
- (id)data {
  return self->data;
}

@end
