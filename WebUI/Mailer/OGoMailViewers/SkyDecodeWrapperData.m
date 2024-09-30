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

#include "common.h"
#include "SkyDecodeWrapperData.h"

@implementation SkyDecodeWrapperData

- (id)initWithData:(NSData *)_data encoding:(NSString *)_encoding{
  if ((self = [super init])) {
    ASSIGN(self->data, _data);
    ASSIGN(self->encoding, _encoding);
    self->len = -1;
  }
  return self;
}

- (void)dealloc {
  [self->data release];
  [self->encoding release];
  [super dealloc];
}

- (id)copyWithZone:(NSZone*)zone {
    return RETAIN(self);
}

- (NSData *)_data {
  NSData *enc;

  if (![self->data length])
    return nil;
  
  if ([self->encoding hasPrefix:@"base64"])
    enc = [self->data dataByDecodingBase64];
  else if ([self->encoding hasPrefix:@"quoted"])
    enc = [self->data dataByDecodingQuotedPrintable];
  else
    enc = self->data;

  return enc;
}

- (const void*)bytes {
  NSData *d;

  d = [self _data];
  if (self->len == -1)
    self->len = [d length];
  
  return [d bytes];
}

- (unsigned int)length {
  if (self->len == -1) {
    self->len = [[self _data] length];
  }
  return self->len;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%p[%@]: data=%@ encoding=%@",
                   self, NSStringFromClass([self class]), self->data,
                   self->encoding];
}

@end
