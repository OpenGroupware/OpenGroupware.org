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

#import <LSFoundation/LSDBObjectBaseCommand.h>

@class NSArray;

@interface LSGroupToMemberAssignmentCommand : LSDBObjectBaseCommand
{
@private 
  NSArray *groups;
}

@end

#include "common.h"

@implementation LSGroupToMemberAssignmentCommand

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->groups);
  [super dealloc];
}
#endif

// command methods

- (BOOL)_object:(id)_object isInList:(NSArray *)_list {
  NSEnumerator *listEnum  = [_list objectEnumerator];
  id           listObject = nil;
  id           pkey;

  pkey = [_object valueForKey:@"companyId"];

  while ((listObject = [listEnum nextObject])) {
    id opkey = [listObject valueForKey:@"companyId"];

    if ([pkey isEqual:opkey]) return YES;
  }
  return NO;
}

static BOOL _objectIsNoEnterprise(LSGroupToMemberAssignmentCommand *self,
                                  id _context,
                                  id _obj) {
  NSArray *e = nil;

  e = LSRunCommandV(_context, @"enterprise", @"get",
                    @"companyId", [_obj valueForKey:@"companyId"],
                    @"checkAccess", [NSNumber numberWithBool:NO],
                    nil);

  return ([e count] > 0) ? NO : YES;
}

- (void)_removeOldAssignmentsInContext:(id)_context {
  NSArray      *oldAssignments = nil;
  NSEnumerator *listEnum       = nil;
  id           assignment      = nil;
  id           obj             = nil;

  obj            = [self object];
  oldAssignments = [obj valueForKey:@"toCompanyAssignment1"];
  listEnum       = [oldAssignments objectEnumerator];

  while ((assignment = [listEnum nextObject])) {
    if ((![self _object:assignment isInList:self->groups]) &&
        (_objectIsNoEnterprise(self, _context, assignment))) {
      LSRunCommandV(_context,        @"companyassignment", @"delete",
                    @"object",       assignment,
                    @"reallyDelete", [NSNumber numberWithBool:YES],
                    nil);
    }
  }
}

- (void)_saveAssignmentsInContext:(id)_context {
  NSArray      *oldAssignments = nil;
  NSEnumerator *listEnum       = nil;
  id           newAssignment   = nil; 
  id           obj             = nil;

  obj            = [self object];
  oldAssignments = [obj valueForKey:@"toCompanyAssignment1"];
  listEnum       = [self->groups objectEnumerator];

  while ((newAssignment = [listEnum nextObject])) {
    if (![self _object:newAssignment isInList:oldAssignments]) {
      LSRunCommandV(_context,        @"companyassignment", @"new",
                    @"subCompanyId", [obj valueForKey:@"companyId"],
                    @"companyId",    [newAssignment valueForKey:@"companyId"],
                    nil);
    }
  }
}

- (void)_executeInContext:(id)_context {
  LSRunCommandV(_context,     [[self object] entityName], @"get",
                @"companyId", [[self object] valueForKey:@"companyId"],
                @"checkAccess", [NSNumber numberWithBool:NO],
               nil);

  [self _removeOldAssignmentsInContext:_context];
  [self _saveAssignmentsInContext:_context];

  LSRunCommandV(_context,     [[self object] entityName], @"get",
                @"companyId", [[self object] valueForKey:@"companyId"],
                @"checkAccess", [NSNumber numberWithBool:NO],
                nil);

}

// initialize records

- (NSString *)entityName {
  return @"CompanyAssignment";
}

// accessors
 
- (void)setGroups:(NSArray *)_groups {
  ASSIGN(self->groups, _groups);
}
- (NSArray *)groups {
  return self->groups;
}

// key/value coding

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"member"]) {
    [self setObject:_value];
    return;
  } else if ([_key isEqualToString:@"groups"]) {
    [self setGroups:_value];
    return;
  }
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"member"])
    return [self object];
  else if ([_key isEqualToString:@"groups"])
    return [self groups];
  return [super valueForKey:_key];
}

@end
