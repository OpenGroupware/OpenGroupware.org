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

#include <NGObjWeb/WOComponent.h>

@interface EnterValue : WOComponent
{
  id       value;
  NSString *valueType;

  /* transient */
  id item;
  id key;
}
@end

#include "common.h"

@implementation EnterValue

- (void)dealloc {
  RELEASE(self->value);
  RELEASE(self->valueType);
  RELEASE(self->item);
  RELEASE(self->key);
  [super dealloc];
}

/* notifications */

- (void)sleep {
  ASSIGN(self->item, nil);
  ASSIGN(self->key,  nil);
  [super sleep];
}

/* accessors */

- (void)setValueType:(NSString *)_valType {
  ASSIGN(self->valueType, _valType);
}
- (NSString *)valueType {
  return self->valueType;
}

- (void)setValue:(id)_val {
  ASSIGN(self->value, _val);
}
- (id)value {
  NSString *vt = [self valueType];
  if ([vt isEqualToString:@"array"]) {
    if (self->value == nil)
      return [NSArray array];
    else if ([self->value isKindOfClass:[NSArray class]])
      return self->value;
    else
      return [self->value propertyList];
  }
  else if ([vt isEqualToString:@"i4"] || [vt isEqualToString:@"int"]) {
    if (self->value == nil)
      return [NSNumber numberWithInt:0];
    else if ([self->value isKindOfClass:[NSNumber class]])
      return self->value;
    else
      return [NSNumber numberWithInt:[self->value intValue]];
  }
  else if ([vt isEqualToString:@"boolean"]) {
    if (self->value == nil)
      return [NSNumber numberWithBool:NO];
    else if ([self->value isKindOfClass:[NSNumber class]])
      return self->value;
    else
      return [NSNumber numberWithBool:[self->value boolValue]];
  }
  else if ([vt isEqualToString:@"struct"]) {
    if (self->value == nil)
      return [NSDictionary dictionary];
    else if ([self->value isKindOfClass:[NSDictionary class]])
      return self->value;
    else
      return [self->value propertyList];
  }
  else if ([vt isEqualToString:@"dateTime.iso8601"]) {
    if (self->value == nil)
      return [NSCalendarDate date];
    else if ([self->value isKindOfClass:[NSDate class]])
      return self->value;
    else {
      return [[[NSCalendarDate alloc]
                               initWithString:[self->value stringValue]]
                               autorelease];
    }
  }
  return self->value;
}

- (void)setItem:(id)_val {
  ASSIGN(self->item, _val);
}
- (id)item {
  return self->item;
}
- (void)setKey:(id)_val {
  ASSIGN(self->key, _val);
}
- (id)key {
  return self->key;
}

@end /* EnterValue */
