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
// $Id$

#include "EllipsisFormatter.h"
#include "common.h"

@implementation EllipsisFormatter

- (id)initWithFormat:(NSString *)_format {
  if ((self = [super init])) {
    self->format = [_format copy];
  }
  return self;
}
- (id)initWithString:(NSString *)_fmt {
  return [self initWithFormat:_fmt];
}
- (id)init {
  return [self initWithFormat:@"128"];
}
- (id)initWithPropertyList:(id)_plist {
  if (_plist == nil || [_plist isKindOfClass:[NSString class]])
    return [self initWithString:_plist];
  
  [self release];
  return nil;
}

- (void)dealloc {
  [self->format release];
  [super dealloc];
}

/* operations */

- (NSString *)stringForObjectValue:(id)_object {
  NSString *s;
  unsigned maxlen;
  
  if (![_object isNotNull])
    return @"";
  
  if ((maxlen = [self->format intValue]) < 5)
    maxlen = 5;
  
  s = [_object stringValue];
  if ([s length] <= maxlen)
    return s;
  
  s = [[s substringToIndex:(maxlen - 3)] stringByAppendingString:@"..."];
  return s;
}

@end /* EllipsisFormatter */
