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

#include "WCAPResultSet.h"
#import <Foundation/Foundation.h>

@implementation WCAPResultSet

+ (id)resultSetWithProperties:(NSDictionary *)_properties
                       result:(NSArray *)_result
{
  id set;

  set = [[WCAPResultSet alloc] initWithProperties:_properties
                               result:_result];

  return [set autorelease];
}

- (id)initWithProperties:(NSDictionary *)_properties
                  result:(NSArray *)_result
{
  if ((self = [super init])) {
    self->properties = [_properties retain];
    self->result     = [_result     retain];
  }
  return self;
}

- (NSDictionary *)properties {
  return self->properties;
}
- (NSArray *)result {
  return self->result;
}
- (NSEnumerator *)resultEnumerator {
  return [self->result objectEnumerator];
}

- (BOOL)isEqual:(id)_other {
  WCAPResultSet *other;
  if (self == _other) return YES;
  if (_other == nil) return NO;
  if (![_other isKindOfClass:[WCAPResultSet class]]) return NO;
  other = (WCAPResultSet *)_other;
  return ([self->result isEqualToArray:[other result]] &&
          [self->properties isEqualToDictionary:[other properties]]);
}

@end /* WCAPResultSet */
