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

#include <LSFoundation/LSDBObjectBaseCommand.h>

@class NSArray;

@interface LSProjectsToCompanyAssignmentCommand : LSDBObjectBaseCommand
{
@private 
  NSArray *projects;
  NSArray *removedProjects;
}

@end

#import "common.h"

@implementation LSProjectsToCompanyAssignmentCommand

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->projects);
  RELEASE(self->removedProjects);
  [super dealloc];
}
#endif

// command methods

- (BOOL)_object:(id)_object isInList:(NSArray *)_list {
  NSEnumerator *listEnum;
  id           pkey;
  id           listObject;

  listEnum = [_list objectEnumerator];
  pkey     = [_object valueForKey:@"projectId"];
  
  while ((listObject = [listEnum nextObject])) {
    id opkey = [listObject valueForKey:@"projectId"];

    if ([pkey isEqual:opkey]) return YES;
  }
  return NO;
}

- (void)_removeOldAssignmentsInContext:(id)_context {
  NSEnumerator *pEnum       = nil;
  NSEnumerator *asEnum      = nil;
  NSArray      *assignments = nil;
  id           p            = nil;
  id           as           = nil; 

  pEnum = [self->removedProjects objectEnumerator];
  
  while ((p = [pEnum nextObject])) {
    assignments = [p valueForKey:@"companyAssignments"];
    asEnum = [assignments objectEnumerator];
    
    while ((as = [asEnum nextObject])) {
      if ([[[self object] valueForKey:@"companyId"]
                  isEqual:[as valueForKey:@"companyId"]]) {
        LSRunCommandV(_context,        @"projectcompanyassignment",  @"delete",
                      @"object",       as,
                      @"reallyDelete", [NSNumber numberWithBool:YES], nil);
      }
    }
  }
}

- (void)_saveAssignmentsInContext:(id)_context {
  NSArray      *oldAssignments = nil;
  NSEnumerator *pEnum          = nil;
  id           p               = nil; 
  id           obj             = [self object];

  LSRunCommandV(_context, [[self entityName] lowercaseString],
                @"get-project-assignments",
                @"object",      obj,
                @"relationKey", @"projectAssignments", nil);

  oldAssignments = [obj valueForKey:@"projectAssignments"];

  //[self logWithFormat:@"oldAssignments: %@", oldAssignments];

  pEnum = [self->projects objectEnumerator];

  while ((p = [pEnum nextObject])) {
    if (![self _object:p isInList:oldAssignments]) {
      LSRunCommandV(_context,     @"projectcompanyassignment",  @"new",
                    @"companyId", [obj valueForKey:@"companyId"],
                    @"projectId", [p valueForKey:@"projectId"],
                    @"hasAccess", [NSNumber numberWithBool:NO], nil);
    }
  }
}

- (void)_executeInContext:(id)_context {
  if (self->removedProjects) {
    [self _removeOldAssignmentsInContext:_context];
  }
  if (self->projects) {
    [self _saveAssignmentsInContext:_context];
  }
}

// accessors

- (void)setProjects:(NSArray *)_projects {
  ASSIGN(self->projects, _projects);
}
- (NSArray *)projects {
  return self->projects;
}
- (void)setRemovedProjects:(NSArray *)_removedProjects {
  ASSIGN(self->removedProjects, _removedProjects);
}
- (NSArray *)removedProjects {
  return self->removedProjects;
}

// key/value coding

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"projects"]) {
    [self setProjects:_value];
    return;
  }
  if ([_key isEqualToString:@"removedProjects"]) {
    [self setRemovedProjects:_value];
    return;
  }
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"removedProjects"])
    return [self removedProjects];
  return [super valueForKey:_key];
}

@end
