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

#include "SkyEnterpriseAllProjectsDataSource.h"
#include "common.h"

#include "SkyEnterpriseProjectDataSource.h"

@implementation SkyEnterpriseAllProjectsDataSource

- (id)initWithContext:(id)_ctx enterpriseId:(id)_enterpriseId {
  if ((self = [super init])) {
    self->context      = [_ctx retain];
    self->enterpriseId = [_enterpriseId retain];
  }  
  return self;
}

- (void)dealloc {
  [self->fspec        release];
  [self->context      release];
  [self->enterpriseId release];
  [self->projectDataSource release];
  [super dealloc];
}

/* accessors */

- (void)setFetchSpecification:(EOFetchSpecification *)_fSpec {
  if ([self->fspec isEqual:_fSpec]) 
    return;
  
  ASSIGNCOPY(self->fspec, _fSpec);
  [self postDataSourceChangedNotification];
}
- (EOFetchSpecification *)fetchSpecification {
  return [[self->fspec copy] autorelease];;
}

/* operations */

- (NSException *)handleFetchException:(NSException *)_exception {
  [self logWithFormat:@"ERROR: catched exception during fetch: %@", 
          _exception];
  return nil;
}

- (NSArray *)fetchObjects {
  NSArray        *sortOrderings = nil;
  EOQualifier    *qualifier     = nil;
  NSMutableArray *projects;
  id enterprise;
  
  /* could introduce hint to set this dynamically .. */
  if (self->enterpriseId == nil)
    return nil;
  
  projects = [NSMutableArray arrayWithCapacity:8];
  
  if (self->projectDataSource == nil) {
    self->projectDataSource =
      [[SkyEnterpriseProjectDataSource alloc] initWithContext:self->context
                                              companyId:self->enterpriseId];
  }
  
  NS_DURING {
    id tmp;
    
    enterprise =
      [[self->context runCommand:@"enterprise::get",
            @"gid", self->enterpriseId, nil] lastObject];
    NSAssert1(enterprise, @"couldn't get enterprise for gid %@",
              self->enterpriseId);
    
    tmp = [self->context runCommand:@"enterprise::get-fake-project",
               @"object", enterprise, nil];
    if (tmp)
      [projects addObject:tmp];
    else {
      [self debugWithFormat:@"got no fake project for enterprise: %@",
              self->enterpriseId];
    }
    
    if ((tmp = [self->projectDataSource fetchObjects]))
      [projects addObjectsFromArray:tmp];
  }
  NS_HANDLER {
    *(&projects) = nil;
    [[self handleFetchException:localException] raise];
  }
  NS_ENDHANDLER;
  
  /* apply filters and sort */
  
  if ((qualifier = [self->fspec qualifier]) != nil)
    projects = (id)[projects filteredArrayUsingQualifier:qualifier];
  if ((sortOrderings = [self->fspec sortOrderings]) != nil)
    projects = (id)[projects sortedArrayUsingKeyOrderArray:sortOrderings];
  
  return projects;
}

@end /* SkyEnterpriseAllProjectsDataSource */
