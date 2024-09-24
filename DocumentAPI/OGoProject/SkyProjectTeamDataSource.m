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

#include "SkyProjectTeamDataSource.h"
#include "SkyProject.h"
#include <EOControl/EOQualifier.h>
#include <EOControl/EOFetchSpecification.h>
#include <EOControl/EODataSource.h>
#include "common.h"

@interface SkyProjectTeamDataSource(PrivateMethodes)
- (NSArray *)_globalIDsForAssigments;
@end /* SkyProjectTeamDataSource(PrivateMethodes) */

@implementation SkyProjectTeamDataSource

- (id)init {
  return [self initWithProject:nil context:nil];
}
- (id)initWithProject:(SkyProject *)_project context:(id)_context { /* designated init */
  if ((self = [super init])) {
    self->project = [_project retain];
    self->context = [_context retain];
  }
  return self;
}

- (void)dealloc {
  [self->project release];
  [self->context release];
  [super dealloc];
}

/* fetching */

- (NSArray *)fetchObjects {
  EOFetchSpecification *fSpec = nil;
  EOKeyValueQualifier  *qual  = nil;
  static EODataSource  *ds    = nil;

  if (ds == nil) {
    Class clazz = NGClassFromString(@"SkyTeamDataSource");
    ds = [[clazz alloc] initWithContext:self->context];
  }

  qual  = [[EOKeyValueQualifier alloc]
                                initWithKey:@"globalID"
                                operatorSelector:EOQualifierOperatorContains
                                value:[self _globalIDsForAssigments]];
  fSpec = [EOFetchSpecification fetchSpecificationWithEntityName:@"Team"
                                qualifier:qual
                                sortOrderings:nil];
  [qual release];
  [ds setFetchSpecification:fSpec];
  return [ds fetchObjects];
}

@end /* SkyProjectTeamDataSource */

#include <EOControl/EOKeyGlobalID.h>

@implementation SkyProjectTeamDataSource(PrivateMethodes)

- (NSArray *)_globalIDsForAssigments {
  NSEnumerator   *e;
  id             one;
  NSMutableArray *ma;
  
  ma = [NSMutableArray arrayWithCapacity:16];
  e = [[self->project companyAssignmentsIds] objectEnumerator];
  
  while ((one = [e nextObject])) {
    EOKeyGlobalID *gid;
    
    gid = [EOKeyGlobalID globalIDWithEntityName:@"Team"
                         keys:&one
                         keyCount:1
                         zone:NULL];
    [ma addObject:gid];
  }
  return ma;
}

@end /* SkyProjectTeamDataSource(PrivateMethodes) */
