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

#include "OGoMailAddressRecord.h"
#include "common.h"

@implementation OGoMailAddressRecord

+ (id)mailRecordForEMail:(NSString *)_email andLabel:(NSString *)_label {
  return [[[self alloc] initWithEMail:_email andLabel:_label] autorelease];
}
- (id)initWithEMail:(NSString *)_email andLabel:(NSString *)_label {
  if ((self = [super init])) {
    self->email = [_email copy];
    self->label = [_label copy];
  }
  return self;
}

- (void)dealloc {
  [self->email release];
  [self->label release];
  [super dealloc];
}

/* mimic dictionary */

- (unsigned)count {
  return (self->email && self->label)
    ? 2 : ((self->email || self->label) ? 1 : 0);
}
- (id)objectForKey:(id)_key {
  return [self valueForKey:_key];
}

/* KVC */

- (id)valueForKey:(NSString *)_key {
  unsigned len;
  unichar  c1;
  
  if ((len = [_key length]) != 5)
    return [super valueForKey:_key];
  
  c1 = [_key characterAtIndex:0];
  if (c1 == 'e') {
    if ([_key isEqualToString:@"email"])
      return self->email;
  }
  else if (c1 == 'l') {
    if ([_key isEqualToString:@"label"])
      return self->label;
  }
  return nil;
}

/* NSCopying */

- (id)copyWithZone:(NSZone *)_zone {
  return [self retain];
}

/* description */

- (NSString *)description {
  NSMutableString *ms;

  ms = [NSMutableString stringWithCapacity:128];
  [ms appendFormat:@"<0x%p[%@]:", self, NSStringFromClass([self class])];
  if (self->email) [ms appendFormat:@" email='%@'", self->email];
  if (self->label) [ms appendFormat:@" label='%@'", self->label];
  [ms appendString:@">"];
  return ms;
}

@end /* OGoMailAddressRecord */
