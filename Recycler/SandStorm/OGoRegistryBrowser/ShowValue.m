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

#include "ShowValue.h"
#include "common.h"
#include "RunMethod.h"
#include <SxComponents/SxXmlRpcComponent.h>
#include <SxComponents/SxComponentMethodSignature.h>

@implementation ShowValue

- (void)dealloc {
  RELEASE(self->value);
  RELEASE(self->sxComponent);
  [super dealloc];
}

/* notifications */

/* accessors */

- (void)setValue:(id)_val {
  ASSIGN(self->value, _val);
}
- (id)value {
  return self->value;
}

- (void)setNestingLevel:(int)_i {
  self->nestingLevel = _i;
}
- (int)nestingLevel {
  return self->nestingLevel;
}
- (int)nextNestingLevel {
  return self->nestingLevel + 1;
}

- (BOOL)isSimpleType:(id)_value {
  if ([_value isKindOfClass:[NSArray class]])
    return NO;
  if ([_value isKindOfClass:[NSDictionary class]])
    return NO;
  if ([_value isKindOfClass:[NSException class]])
    return NO;
  return YES;
}
- (BOOL)isSimpleType {
  return [self isSimpleType:self->value];
}
- (NSString *)valueType {
  if ([self->value isKindOfClass:[NSString class]])
    return @"string";
  if ([self->value isKindOfClass:[NSArray class]])
    return @"array";
  if ([self->value isKindOfClass:[NSDictionary class]])
    return @"struct";
  if ([self->value isKindOfClass:[NSNumber class]])
    return @"i4";
  if ([self->value isKindOfClass:[NSDate class]])
    return @"dateTime.iso8601";
  if ([self->value isKindOfClass:[NSException class]])
    return @"fault";

  return nil;
}

- (BOOL)showRelatedMethods {
  if (![self isSimpleType])    return NO;
  if ([self nestingLevel] > 0) return NO;
  return YES;
}

/* accessors */

- (void)setSxComponent:(SxXmlRpcComponent *)_component {
  ASSIGN(self->sxComponent, _component);
}
- (SxXmlRpcComponent *)sxComponent {
  return self->sxComponent;
} 

/* actions */

@end /* ShowValue */
