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
#import "LSMemberToGroupAssignmentCommand.h"

@implementation LSMemberToGroupAssignmentCommand

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->members);
  RELEASE(self->changedMemberIds);
  [super dealloc];
}
#endif

// command methods

- (BOOL)_object:(id)_object isInList:(NSArray *)_list {
  NSEnumerator *listEnum  = [_list objectEnumerator];
  id           listObject = nil;
  id           pkey;

  pkey = [_object valueForKey:@"subCompanyId"];

  while ((listObject = [listEnum nextObject])) {
    id opkey = [listObject valueForKey:@"companyId"];

    if ([pkey isEqual:opkey]) return YES;
  }
  return NO;
}

- (BOOL)_object2:(id)_object isInList:(NSArray *)_list {
  NSEnumerator *listEnum  = [_list objectEnumerator];
  id           listObject = nil;
  id           pkey;

  pkey = [_object valueForKey:@"companyId"];

  while ((listObject = [listEnum nextObject])) {
    id opkey = [listObject valueForKey:@"subCompanyId"];

    if ([pkey isEqual:opkey]) return YES;
  }
  return NO;
}

- (void)_removeOldAssignmentsInContext:(id)_context {
  NSArray      *oldAssigns = nil;
  NSEnumerator *listEnum   = nil;
  id           assign      = nil; 
  id           obj         = nil;

  obj        = [self object];
  oldAssigns = [obj valueForKey:@"toCompanyAssignment"];
  listEnum   = [oldAssigns objectEnumerator];

  while ((assign = [listEnum nextObject])) {
    if (![self _object:assign isInList:self->members]) {
      [self->changedMemberIds addObject:[assign valueForKey:@"subCompanyId"]];
      LSRunCommandV(_context,        @"companyassignment", @"delete",
                    @"object",       assign,
                    @"reallyDelete", [NSNumber numberWithBool:YES],
                    nil);
    }
  }
}

- (void)_saveAssignmentsInContext:(id)_context {
  NSArray      *oldAssigns = nil;
  NSEnumerator *listEnum   = nil;
  id           newAssign   = nil; 
  id           obj         = nil;

  obj        = [self object];
  oldAssigns = [obj valueForKey:@"toCompanyAssignment"];
  listEnum   = [self->members objectEnumerator];

  while ((newAssign = [listEnum nextObject])) {
    if (![self _object2:newAssign isInList:oldAssigns]) {
      LSRunCommandV(_context,        @"companyassignment", @"new",
                    @"companyId",    [obj valueForKey:@"companyId"],
                    @"subCompanyId", [newAssign valueForKey:@"companyId"],
                    nil);
      [self->changedMemberIds addObject:[newAssign valueForKey:@"companyId"]];
    }
  }
}

- (void)_executeInContext:(id)_context {
  RELEASE(self->changedMemberIds); self->changedMemberIds = nil;

  self->changedMemberIds = [[NSMutableArray allocWithZone:[self zone]] init];
  
  LSRunCommandV(_context,     [[self object] entityName], @"get",
                @"companyId", [[self object] valueForKey:@"companyId"],
                nil);

  [self _removeOldAssignmentsInContext:_context];
  [self _saveAssignmentsInContext:_context];

  LSRunCommandV(_context,     [[self object] entityName], @"get",
                @"companyId", [[self object] valueForKey:@"companyId"],
                nil);

  LSRunCommandV(_context, @"object", @"add-log",
                @"objectId", [[self object] valueForKey:@"companyId"],
                @"logText",  @"members changed",
                @"action",   @"05_changed", nil);

  {
    int i, cnt = [self->changedMemberIds count];

    for (i=0; i<cnt; i++) {
      LSRunCommandV(_context, @"object", @"add-log",
                    @"objectId", [self->changedMemberIds objectAtIndex:i],
                    @"logText",  @"enterprises changed",
                    @"action",   @"05_changed", nil);
    }
  }
}

// initialize records

- (NSString *)entityName {
  return @"CompanyAssignment";
}

// accessors

- (void)setMembers:(NSArray *)_members {
  ASSIGN(self->members, _members);
}
- (NSArray *)members {
  return self->members;
}

// key/value coding

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"group"]) {
    [self setObject:_value];
    return;
  } else if ([_key isEqualToString:@"members"]) {
    [self setMembers:_value];
    return;
  }
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"group"])
    return [self object];
  else if ([_key isEqualToString:@"members"])
    return [self members];
  return [super valueForKey:_key];
}

@end
