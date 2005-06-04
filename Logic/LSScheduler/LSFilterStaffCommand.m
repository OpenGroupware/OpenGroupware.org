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

#include <LSFoundation/LSDBArrayFilterCommand.h>

@class NSArray;

@interface LSFilterStaffCommand : LSDBArrayFilterCommand
{
@private
  NSArray *staffList;
}

- (void)setStaffList:(NSArray *)_staffList;
- (NSArray *)staffList;
- (void)setStaff:(id)_staff;
- (id)staff;

@end

#include "common.h"

@implementation NSObject(AppointmentFilterStaff)

- (BOOL)filterStaffWithSpec:(id)_ctx {
  NSSet *staffList, *assignments;

  staffList   = [NSSet setWithArray:[[_ctx valueForKey:@"staffList"]
                                           valueForKey:@"companyId"]];
  assignments = [NSSet setWithArray:
                         [[self valueForKey:@"toDateCompanyAssignment"]
                                valueForKey:@"companyId"]];

  return [staffList intersectsSet:assignments] ? YES : NO;
#if 0
  assignEnum  = [assignments objectEnumerator];
  
  while ((assignment = [assignEnum nextObject])) {
    NSEnumerator *listEnum;
    id           staff = nil;
    
    listEnum = [staffList objectEnumerator];
    
    while ((staff = [listEnum nextObject])) {
      if ([assignment isEqual:staff])
        return YES;
    }
  }
  return NO;
#endif
}

@end /* NSObject(AppointmentFilterStaff) */

@implementation LSFilterStaffCommand

- (void)dealloc {
  [self->staffList release];
  [super dealloc];
}

/* command methods */

- (BOOL)_object:(id)_object isInList:(NSArray *)_list {
  NSEnumerator *listEnum  = [_list objectEnumerator];
  id           listObject = nil;
  id           pkey;

  pkey = [_object valueForKey:@"companyId"];

  while ((listObject = [listEnum nextObject])) {
    id opkey;

    opkey = [listObject valueForKey:@"companyId"];

    if ([pkey isEqual:opkey]) return YES;
  }
  return NO;
}

- (void)_prepareForExecutionInContext:(id)_context {
  NSMutableDictionary *staffDict    = nil;
  NSEnumerator        *staffEnum    = nil;
  id                  staff         = nil;

  [self assert:([self->staffList count] > 0)
        reason:@"no staff list is set !"];

  staffDict = [[NSMutableDictionary allocWithZone:[self zone]] init];
  staffEnum = [self->staffList objectEnumerator];

  while ((staff = [staffEnum nextObject])) {
    NSArray *furtherStaff = nil;
    
    if ([[staff valueForKey:@"isTeam"] boolValue]) {
      [staffDict takeValue:staff forKey:[staff valueForKey:@"companyId"]];

      furtherStaff = LSRunCommandV(_context, @"team", @"members",
                                   @"team", staff, nil);
    }
    else if ([[staff valueForKey:@"isAccount"] boolValue]) {
      [staffDict takeValue:staff forKey:[staff valueForKey:@"companyId"]];

      if (staff) {
        furtherStaff = [_context runCommand:@"account::teams",
                                   @"object", staff, nil];
      }
      else
        furtherStaff = nil;
    }
    
    {
      NSEnumerator *furtherStaffEnum = [furtherStaff objectEnumerator];
      id           furtherStaff      = nil;

      while ((furtherStaff = [furtherStaffEnum nextObject])) {
        id pkey = [furtherStaff valueForKey:@"companyId"];
        
        [staffDict takeValue:furtherStaff forKey:pkey];
      }      
    }
  }

  AUTORELEASE(self->staffList); self->staffList = nil;
  self->staffList = [[staffDict allValues] copy];
  
  RELEASE(staffDict); staffDict = nil;
}

- (BOOL)includeObjectInResult:(id)_object {
  return [_object filterStaffWithSpec:self];
}

// accessors

- (void)setDateList:(NSArray *)_dateList {
  [self setObject:_dateList];
}
- (NSArray *)dateList {
  return [self object];
}

- (void)setStaffList:(NSArray *)_staffList {
  ASSIGN(self->staffList, _staffList);
}
- (NSArray *)staffList {
  return self->staffList;
}
 
- (void)setStaff:(id)_staff {
  NSArray *list = _staff ? [NSArray arrayWithObject:_staff] : nil;
  ASSIGN(self->staffList, list);
}
- (id)staff {
  return [self->staffList objectAtIndex:0];
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"object"] || [_key isEqualToString:@"dateList"])
    [self setObject:_value];
  else  if ([_key isEqualToString:@"staffList"])
    [self setStaffList:_value];
  else  if ([_key isEqualToString:@"staff"])
    [self setStaff:_value];
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

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"object"] || [_key isEqualToString:@"dateList"])
    return [self object];
  if ([_key isEqualToString:@"staffList"])
    return [self staffList];
  if ([_key isEqualToString:@"staff"])
    return [self staff];

  return nil;
}

@end /* LSFilterStaffCommand */
