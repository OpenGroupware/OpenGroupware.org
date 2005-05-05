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

#include <LSFoundation/LSBaseCommand.h>

@interface LSCheckLoginCommand : LSBaseCommand
@end

#include "common.h"

@implementation LSCheckLoginCommand

// command methods

- (void)_executeInContext:(id)_context {
  NSSet        *staffList = nil;

  [self assert:([[self object] count] > 0) reason:@"no staff list is set !"];
  staffList = LSRunCommandV(_context, @"team", @"resolveaccounts",
                            @"staffList", [self object],
                            nil);
  [self setReturnValue:
        [NSNumber numberWithBool:
                  [staffList containsObject:
                             [_context valueForKey:LSAccountKey]]]];
}

/* accessors */

- (void)setStaff:(id)_staff {
  [self setObject:_staff ? [NSArray arrayWithObject:_staff] : nil];
}
- (id)staff {
  return [[self object] objectAtIndex:0];
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"object"] || [_key isEqualToString:@"staffList"])
    [self setObject:_value];
  else if ([_key isEqualToString:@"staff"])
    [self setStaff:_value];
  else {
    NSString *s;

    s = [NSString stringWithFormat:
		    @"key: %@ is not valid in domain '%@' for operation '%@'.",
		  _key, [self domain], [self operation]];
    [LSDBObjectCommandException raiseOnFail:NO object:self
                                reason:s];
  }
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"object"] || [_key isEqualToString:@"staffList"])
    return [self object];
  if ([_key isEqualToString:@"staff"])
    return [self staff];
  
  return nil;
}

@end /* LSCheckLoginCommand */
