/*
  Copyright (C) 2000-2003 SKYRIX Software AG

  This file is part of OGo

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

#include "FilterEntry.h"
#include "common.h"

@implementation FilterEntry

- (id)initWithString:(NSString *)_string
         headerField:(NSString *)_headerField
          filterKind:(NSString *)_filterKind
{
  if ((self = [super init])) {
    [self setString:_string];
    [self setFilterKind:_filterKind];
    [self setHeaderField:_headerField];
  }
  return self;
}

+ filterEntryWithString:(NSString *)_string
            headerField:(NSString *)_headerField
             filterKind:(NSString *)_filterKind
{
  FilterEntry *e = [[FilterEntry alloc] initWithString:_string
                                        headerField:_headerField
                                        filterKind:_filterKind];
  return AUTORELEASE(e);
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->string);
  RELEASE(self->headerField);
  RELEASE(self->filterKind);

  [super dealloc];
}
#endif

- (void)setString:(NSString *)_str {
  ASSIGN(self->string, _str);
}
- (NSString *)string {
  if ( [[self filterKind] isEqualToString:@"ends with"] &&
       ![self->string hasPrefix:@"*"] )
    return [self->string stringByPrependingString:@"*"];
  if ( [[self filterKind] isEqualToString:@"begins with"] &&
       ![self->string hasSuffix:@"*"] )
    return [self->string stringByAppendingString:@"*"];

  return self->string;
}

- (void)setHeaderField:(NSString *)_str {
  if ([_str isEqualToString:@"from"] ||
      [_str isEqualToString:@"to"] ||
      [_str isEqualToString:@"cc"] ||
      [_str isEqualToString:@"subject"])
    ASSIGN(self->headerField, _str);
  else
    NSLog(@"%s: Illegal value: \"%@\"", __PRETTY_FUNCTION__, _str);
}
- (NSString *)headerField {
  return self->headerField;
}

- (void)setFilterKind:(NSString *)_str {
  if ([_str isEqualToString:@"contains"] ||
      [_str isEqualToString:@"doesn`t contain"] ||
      [_str isEqualToString:@"is"] ||
      [_str isEqualToString:@"isn`t"] ||
      [_str isEqualToString:@"begins with"] ||
      [_str isEqualToString:@"ends with"])
    ASSIGN(self->filterKind, _str);
  else
    NSLog(@"%s: Illegal value: \"%@\"", __PRETTY_FUNCTION__, _str);
}
- (NSString *)filterKind {
  return self->filterKind;
}

- (NSString *)description {
  return [NSString stringWithFormat:
                   @"<%@> filterKind=%@, string=%@, headerField=%@",
                   NSStringFromClass([self class]),
                   [self filterKind], [self string], [self headerField]];
}

@end // FilterEntry
