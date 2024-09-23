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

#include "OGoMailAddressRecordResult.h"
#include "common.h"

@implementation OGoMailAddressRecordResult

- (void)dealloc {
  [self->emails release];
  [self->email  release];
  [self->header release];
  [super dealloc];
}

/* accessors */

- (void)setEMails:(NSArray *)_mails {
  ASSIGN(self->emails, _mails);
}
- (void)setHeader:(NSString *)_header {
  ASSIGNCOPY(self->header, _header);
}
- (void)setEMail:(id)_email {
  ASSIGN(self->email, _email);
}

/* mimic dictionary */

- (unsigned)count {
  return [self->emails count];
}
- (id)objectForKey:(id)_key {
  return [self valueForKey:_key];
}

/* KVC */

- (id)valueForKey:(NSString *)_key {
  unsigned len;
  unichar  c1;
  
  if ((len = [_key length]) == 0)
    return [super valueForKey:_key];

  if (len != 5 && len != 6)
    return [super valueForKey:_key];
  
  c1 = [_key characterAtIndex:0];
  if (c1 == 'e') {
    if (len == 5 && [_key isEqualToString:@"email"])
      return self->email;
    if (len == 6 && [_key isEqualToString:@"emails"])
      return self->emails;
  }
  else if (c1 == 'h') {
    if ([_key isEqualToString:@"header"])
      return self->header;
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
  [ms appendFormat:@"<%p[%@]:", self, NSStringFromClass([self class])];
  if (self->email)  [ms appendFormat:@" email='%@'",  self->email];
  if (self->header) [ms appendFormat:@" header='%@'", self->header];
  if (self->emails) [ms appendFormat:@" emails=%@",   self->emails];
  [ms appendString:@">"];
  return ms;
}

@end /* OGoMailAddressRecordResult */
