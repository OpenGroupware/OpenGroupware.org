/*
  Copyright (C) 2004-2005 SKYRIX Software AG

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

#include <OGoFoundation/OGoComponent.h>

/*
  OGoProjectQuicklist

  TODO: document what it does.
*/

@class EODataSource;

@interface OGoProjectQuicklist : OGoComponent
{
  EODataSource *dataSource;
  NSArray *projects;
  id project;
  id selectedProject;
}

- (void)setSelectedProject:(id)_selectedProject;
- (id)selectedProject;

@end

#include "common.h"

@implementation OGoProjectQuicklist

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self->projects        release];
  [self->dataSource      release];
  [self->project         release];
  [self->selectedProject release];
  [super dealloc];
}

/* cache */

- (void)resetDataSourceCaches {
  /* reset dependend objects */
  [self setSelectedProject:nil];
  ASSIGN(self->projects, nil);
}

/* notifications */

- (void)dataSourceChanged:(NSNotification *)_n {
  [self resetDataSourceCaches];
}

/* accessors */

- (void)setDataSource:(EODataSource *)_ds {
  if (self->dataSource == _ds)
    return;
  
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  ASSIGN(self->dataSource, _ds);
  [self resetDataSourceCaches];
  
  [[NSNotificationCenter defaultCenter] 
    addObserver:self selector:@selector(dataSourceChanged:)
    name:EODataSourceDidChangeNotification object:self->dataSource];
}
- (EODataSource *)dataSource {
  return self->dataSource;
}

static NSComparisonResult sortByName(id obj1, id obj2, void *data) {
  if (obj1 == obj2)
    return NSOrderedSame;
  
  obj1 = [obj1 valueForKey:@"name"];
  obj2 = [obj2 valueForKey:@"name"];
  
  return [obj1 caseInsensitiveCompare:obj2];
}

- (NSArray *)projects {
  EODataSource *ds;
  NSArray *pdocs;
  
  if (self->projects != nil)
    return self->projects;
  
  ds    = [self dataSource];
  pdocs = [ds fetchObjects];
  pdocs = [pdocs sortedArrayUsingFunction:sortByName context:NULL];
  
  self->projects = [pdocs retain];
  if ([self->projects count] > 0)
    [self setSelectedProject:[[self projects] objectAtIndex:0]];
  
  return self->projects;
}
- (BOOL)hasProjects {
  return [[self projects] count] > 0 ? YES : NO;
}

- (void)setProject:(id)_project {
  ASSIGN(self->project, _project);
}
- (id)project {
  return self->project;
}

- (void)setSelectedProject:(id)_selectedProject {
  ASSIGN(self->selectedProject, _selectedProject);
}
- (id)selectedProject {
  return self->selectedProject;
}

- (id)selectedProjectEO {
  NSDictionary *attrs;
  
  // TODO: hack to get EO
  attrs = [[(SkyProject *)[self selectedProject] fileManager] 
            fileSystemAttributesAtPath:@"/"];
  return [attrs valueForKey:@"object"];
}

/* notifications */

- (void)sleep {
  [self setProject:nil];
  ASSIGN(self->projects, nil);
  [super sleep];
}

/* actions */

- (id)selectProject {
  [self setSelectedProject:[self project]];
  return nil;
}

@end /* OGoProjectQuicklist */
