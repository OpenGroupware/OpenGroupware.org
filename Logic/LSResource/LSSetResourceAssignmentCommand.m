/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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
// $Id$

#include <LSFoundation/LSDBObjectNewCommand.h>

@class NSArray;

@interface LSSetResourceAssignmentCommand : LSDBObjectNewCommand
{
  NSArray *subResources;
}

@end

#include "common.h"

@interface LSSetResourceAssignmentCommand(PrivateMethods)
- (void)setSubResources:(NSArray *)_subResources;
- (NSArray *)subResources;
@end

@implementation LSSetResourceAssignmentCommand

- (void)dealloc {
  [self->subResources release];
  [super dealloc];
}

/* operation */

- (BOOL)_resource:(id)_resource isInAssignmentList:(NSArray *)_list {
  NSEnumerator *assignmentEnum;
  NSNumber     *resourceId;
  id           myAssignment;
  
  assignmentEnum = [_list objectEnumerator];
  resourceId     = [_resource valueForKey:@"resourceId"];
  while ((myAssignment = [assignmentEnum nextObject])) {
    if ([resourceId isEqual:[myAssignment valueForKey:@"subResourceId"]])
      return YES;
  }
  return NO;
}

- (BOOL)_assignment:(id)_assignment isInResourceList:(NSArray *)_list {
  // TODO: looks like a DUP of the method above?
  NSEnumerator *resourceEnum;
  NSNumber     *resourceId;
  id           myResource;
  
  resourceEnum = [_list objectEnumerator];
  resourceId   = [_assignment valueForKey:@"subResourceId"];
  while ((myResource = [resourceEnum nextObject])) {
    if ([resourceId isEqual:[myResource valueForKey:@"resourceId"]])
      return YES;
  }
  return NO;
}

- (void)_removeOldAssignmentsInContext:(id)_context {
  NSArray      *oldAssignments;
  NSEnumerator *listEnum;
  id            assignment;
  
  oldAssignments = [[self object] valueForKey:@"toSubResourceAssignment"];
  listEnum       = [oldAssignments objectEnumerator];

  while ((assignment = [listEnum nextObject])) {
    LSDBObjectDeleteCommand *dCmd = nil;
    
    if ([self _assignment:assignment isInResourceList:self->subResources])
      continue;
      
    dCmd = LSLookupCommandV(@"resourceassignment", @"delete",
                            @"object", assignment, nil);
    [dCmd setReallyDelete:YES];
    [dCmd runInContext:_context];
  }
}

- (void)_saveAssignmentsInContext:(id)_context {
  NSNumber     *resourceId;
  NSArray      *oldAssignments;
  NSEnumerator *listEnum;
  id           newResource;
  
  resourceId     = [[self object] valueForKey:@"resourceId"];
  oldAssignments = [[self object] valueForKey:@"toSubResourceAssignment"];
  listEnum       = [self->subResources objectEnumerator];

  while ((newResource = [listEnum nextObject])) {
    if ([self _resource:newResource isInAssignmentList:oldAssignments])
      continue;
    
    LSRunCommandV(_context,
                  @"resourceassignment", @"new",
                  @"superResourceId",    resourceId,
                  @"subResourceId", [newResource valueForKey:@"resourceId"],
                  nil);
  }
  [self setReturnValue:[self object]];
}


- (void)_prepareForExecutionInContext:(id)_context {
}


- (void)_executeInContext:(id)_context {
  [self _removeOldAssignmentsInContext:_context];
  [self _saveAssignmentsInContext:_context];
}

- (NSString*)entityName {
  return @"Resource";
}

/* accessors */

- (void)setSubResources:(NSArray*)_subResources {
  ASSIGN(self->subResources, _subResources);
}
- (NSArray*)subResources {
  return self->subResources;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"subResources"]) {
    [self setSubResources:_value];
    return;
  }
  if ([_key isEqualToString:@"object"]) {
    [self setObject:_value];
    return;
  }
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"subResources"]) {
    return [self subResources];
  }
  else if ([_key isEqualToString:@"object"])
    return [self object];
  return [super valueForKey:_key];
}

@end /* LSSetResourceAssignmentCommand */
