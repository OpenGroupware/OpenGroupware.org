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
#include <LSFoundation/LSDBObjectBaseCommand.h>

@interface LSParticipantsIntersectionCommand : LSDBObjectBaseCommand
{
@private
  NSArray *staffList;
}

@end

@implementation LSParticipantsIntersectionCommand

// command methods

- (void)_executeInContext:(id)_context {
  NSMutableSet *accountSet;
  NSMutableSet *participantSet;
  
  accountSet     = [[NSMutableSet allocWithZone:[self zone]] init];
  participantSet = [[NSMutableSet allocWithZone:[self zone]] init];

  [participantSet addObjectsFromArray:
                    LSRunCommandV(_context,
                                  @"team", @"resolveaccounts",
                                  @"staffList", [self object], nil)];

  [accountSet addObjectsFromArray:
                LSRunCommandV(_context,
                              @"team", @"resolveaccounts",
                              @"staffList", self->staffList, nil)];

  [participantSet intersectSet:accountSet];
  [self setReturnValue:[participantSet allObjects]];
  RELEASE(participantSet); participantSet = nil;
  RELEASE(accountSet);     accountSet = nil;
}

// accessors

- (void)setStaffList:(id)_staffList {
  ASSIGN(self->staffList, _staffList);
}
- (id)staffList {
  return self->staffList;
}

- (void)setStaff:(id)_staff {
  [self setStaffList:_staff ? [NSArray arrayWithObject:_staff] : nil];
}
- (id)staff {
  return [self->staffList objectAtIndex:0];
}

// key/value coding

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"object"]
      || [_key isEqualToString:@"participants"]) {
    [self setObject:_value];
    return;
  }
  else if ([_key isEqualToString:@"staffList"]) {
    [self setStaffList:_value];
    return;
  }
  else if ([_key isEqualToString:@"staff"]) {
    [self setStaff:_value];
    return;
  }
  else {
    [LSDBObjectCommandException raiseOnFail:NO object:self
                                reason:
                                [NSString stringWithFormat:
                                          @"key: %@ is not valid in domain '%@' "
                                          @"for operation '%@'.",
                                          _key, [self domain],
                                          [self operation]]];
  }
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"object"] || [_key isEqualToString:@"participants"])
    return [self object];
  else if ([_key isEqualToString:@"staff"])
    return [self staff]; 
  else if ([_key isEqualToString:@"staffList"])
    return [self staffList]; 
  else
    return nil;
}

@end
