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

/*
  LSMemberToGroupAssignmentCommand
  eg: team::set-members
  
  TODO: document
*/

#include "LSMemberToGroupAssignmentCommand.h"
#include "common.h"

@implementation LSMemberToGroupAssignmentCommand

- (void)dealloc {
  [self->members          release];
  [self->changedMemberIds release];
  [super dealloc];
}

/* command methods */

- (BOOL)_object:(id)_object isInList:(NSArray *)_list {
  NSEnumerator *listEnum;
  id           listObject;
  NSNumber     *pkey;

  pkey = [_object valueForKey:@"subCompanyId"];
  
  listEnum  = [_list objectEnumerator];
  while ((listObject = [listEnum nextObject])) {
    NSNumber *opkey;
    
    opkey = [listObject valueForKey:@"companyId"];
    if ([pkey isEqual:opkey]) return YES;
  }
  return NO;
}

- (BOOL)_object2:(id)_object isInList:(NSArray *)_list {
  NSEnumerator *listEnum;
  id           listObject;
  NSNumber     *pkey;

  pkey = [_object valueForKey:@"companyId"];
  
  listEnum  = [_list objectEnumerator];
  while ((listObject = [listEnum nextObject])) {
    NSNumber *opkey;

    opkey = [listObject valueForKey:@"subCompanyId"];
    if ([pkey isEqual:opkey]) return YES;
  }
  return NO;
}

- (void)_removeOldAssignmentsInContext:(id)_context {
  NSArray      *oldAssigns;
  NSEnumerator *listEnum;
  id           assign; 
  id           obj;

  obj        = [self object];
  oldAssigns = [obj valueForKey:@"toCompanyAssignment"];
  listEnum   = [oldAssigns objectEnumerator];

  while ((assign = [listEnum nextObject]) != nil) {
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
  NSArray      *oldAssigns;
  NSEnumerator *listEnum;
  id           newAssign; 
  id           obj;

  obj        = [self object];
  oldAssigns = [obj valueForKey:@"toCompanyAssignment"];
  listEnum   = [self->members objectEnumerator];

  while ((newAssign = [listEnum nextObject]) != nil) {
    if ([self _object2:newAssign isInList:oldAssigns])
      continue;

    LSRunCommandV(_context,        @"companyassignment", @"new",
                    @"companyId",    [obj valueForKey:@"companyId"],
                    @"subCompanyId", [newAssign valueForKey:@"companyId"],
                    nil);
    [self->changedMemberIds addObject:[newAssign valueForKey:@"companyId"]];
  }
}

- (void)_addLogsInContext:(LSCommandContext *)_context {
  unsigned i, cnt;

  LSRunCommandV(_context, @"object", @"add-log",
                @"objectId", [[self object] valueForKey:@"companyId"],
                @"logText",  @"members changed",
                @"action",   @"05_changed", nil);

  for (i = 0, cnt = [self->changedMemberIds count]; i < cnt; i++) {
    LSRunCommandV(_context, @"object", @"add-log",
                  @"objectId", [self->changedMemberIds objectAtIndex:i],
                  @"logText",  @"contact or team connection changed",
                  @"action",   @"05_changed", nil);
  }
}

- (void)_regetObjectInContext:(LSCommandContext *)_context {
  LSRunCommandV(_context,     [[self object] entityName], @"get",
                @"companyId", [[self object] valueForKey:@"companyId"],
                nil);
}

- (void)_executeInContext:(id)_context {
  
  // TODO: this belongs to -prepare...?
  [self->changedMemberIds release]; self->changedMemberIds = nil;
  self->changedMemberIds = [[NSMutableArray alloc] initWithCapacity:4];
  
  [self _regetObjectInContext:_context];

  /* check access */
  // TODO: this should really be done in the access-handler, that is,
  //       an own operation for company<>company changes instead of
  //       using 'w'
  
  if ([[[self object] entityName] isEqualToString:@"Team"]) {
    OGoAccessManager *am;
    
    am = [_context accessManager];
    [self assert:[am operation:@"w" 
                     allowedOnObjectID:[[self object] valueForKey:@"globalID"]]
          reason:@"permission denied"];
  }
  
  /* perform changes */
  
  [self _removeOldAssignmentsInContext:_context];
  [self _saveAssignmentsInContext:_context];
  
  [self _regetObjectInContext:_context];
  
  [self _addLogsInContext:_context];
}

/* initialize records */

- (NSString *)entityName {
  return @"CompanyAssignment";
}

/* accessors */

- (void)setMembers:(NSArray *)_members {
  ASSIGN(self->members, _members);
}
- (NSArray *)members {
  return self->members;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"group"]) {
    [self setObject:_value];
    return;
  }
  if ([_key isEqualToString:@"members"]) {
    [self setMembers:_value];
    return;
  }
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"group"])
    return [self object];
  if ([_key isEqualToString:@"members"])
    return [self members];
  return [super valueForKey:_key];
}

@end /* LSMemberToGroupAssignmentCommand */
