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

#include <OGoFoundation/OGoComponent.h>

// TODO: this should list the favorite projects for fast access!
// TODO: needs some cleanup
// TODO: whats the difference to SkyProjectSelections?

/*
  Usage:
    ProjectSelection: SkyProjectSelection {
      project = project;
      title   = labels.project;
      searchEnterprises = YES;
      markFirst = YES/NO; 
        -> if !selectedProject choose first found as selected 
    }
*/

@class NSString, NSMutableArray, NSArray;

@interface SkyProjectSelection : OGoComponent
{
  NSString       *title;
  NSString       *searchProjectText;
  NSString       *searchEnterpriseText;
  NSMutableArray *projects;
  id             selectedProject;
  NSString       *nilString;
  
  BOOL           searchEnterprises;
  BOOL           noProjectEnabled;
  BOOL           withoutTitles;
  BOOL           markFirst;
}
- (void)_setEnterpriseNames:(NSArray *)_enterprises;
@end

#include "common.h"

@interface NSObject(Gids)
- (EOGlobalID *)globalID;
@end

@implementation SkyProjectSelection

static int compareProjects(id project1, id project2, void *context) {
  NSString *name1 = [project1 valueForKey:@"name"];
  NSString *name2 = [project2 valueForKey:@"name"];

  name1 = (name1 == nil) ? (NSString*)@"" : name1;
  name2 = (name2 == nil) ? (NSString*)@"" : name2;

  return [name1 compare:name2];
}

static int compareEnterprises(id enterprise1, id enterprise2, void *context) {
  NSString *name1 = [enterprise1 valueForKey:@"description"];
  NSString *name2 = [enterprise2 valueForKey:@"description"];

  name1 = (name1 == nil) ? (NSString *)@"" : name1;
  name2 = (name2 == nil) ? (NSString *)@"" : name2;

  return [name1 compare:name2];
}

- (id)init {
  if ((self = [super init])) {
    self->projects = [[NSMutableArray alloc] initWithCapacity:8];
    self->title    = [[[self labels] valueForKey:@"Project"] copy];
    self->noProjectEnabled  = YES;
  }
  return self;
}

- (void)dealloc {
  [self->title                release];
  [self->projects             release];
  [self->selectedProject      release];
  [self->searchProjectText    release];
  [self->searchEnterpriseText release];
  [self->nilString            release];
  [super dealloc];
}

/* accessors */

// --- api for parent component
- (void)setTitle:(NSString *)_title {
  ASSIGNCOPY(self->title, _title);
}
- (NSString *)title {
  return self->title;
}

- (void)setProject:(id)_project {
  ASSIGN(self->selectedProject, _project);
}
- (id)project {
  if ([[self->selectedProject entityName] isEqualToString:@"Enterprise"])
    return [self->selectedProject run:@"enterprise::get-fake-project", nil];
  
  return self->selectedProject;
}

- (void)setProjectGlobalID:(EOGlobalID *)_gid {
  id fp;
  
  if ([_gid isEqual:[[self project] globalID]])
    return;
    
  fp = [[self run:@"project::get", @"gid", _gid, nil] lastObject];
  [self setProject:fp];
}
- (EOGlobalID *)projectGlobalID {
  return [[self project] globalID];
}

- (void)setSearchEnterprises:(BOOL)_flag {
  self->searchEnterprises = _flag;
}
- (BOOL)searchEnterprises {
  return self->searchEnterprises;
}

- (void)setNilString:(NSString *)_nilString {
  ASSIGN(self->nilString, _nilString);
}
- (NSString *)nilString {
  return self->nilString;
}

- (void)setNoProjectEnabled:(BOOL)_flag {
  self->noProjectEnabled = _flag;
}
- (BOOL)noProjectEnabled {
  return self->noProjectEnabled;
}

- (void)setWithoutTitles:(BOOL)_flag {
  self->withoutTitles = _flag;
}
- (BOOL)withoutTitles {
  return self->withoutTitles;
}
- (void)setMarkFirst:(BOOL)_flag {
  self->markFirst = _flag;
}
- (BOOL)markFirst {
  return self->markFirst;
}

/* accessors */

- (NSMutableArray *)projects {
  return self->projects;
}

- (void)setSearchProjectText:(NSString *)_text {
  ASSIGNCOPY(self->searchProjectText, _text);
}
- (NSString *)searchProjectText {
  return self->searchProjectText;
}

- (void)setSearchEnterpriseText:(NSString *)_text {
  ASSIGNCOPY(self->searchEnterpriseText, _text);
}
- (NSString *)searchEnterpriseText {
  return self->searchEnterpriseText;
}

- (void)setSelectedProjects:(NSMutableArray *)_selectedProjects {
  unsigned int cnt = [_selectedProjects count];

  if (cnt == 0) {
    [self->selectedProject release]; 
    self->selectedProject = nil;
  }
  else if (cnt == 1) {
    id obj = [_selectedProjects lastObject];
    ASSIGN(self->selectedProject, obj);
  }
  else
    [self logWithFormat:@"WARNING: more than one selectedProject"];
}
- (NSMutableArray *)selectedProjects {
  return (self->selectedProject != nil)
    ? [NSMutableArray arrayWithObject:self->selectedProject]
    : [NSMutableArray array];
}

/* commands */

- (NSArray *)_findProjectEOsWithString:(NSString *)_str {
  NSArray *result;
  
  result = [self runCommand:@"project::extended-search",
                   @"operator", @"OR", @"name", _str, @"number", _str, nil];
  return result;
}
- (NSArray *)_findEnterpriseEOsWithString:(NSString *)_str {
  NSArray *result;
  
  result = [self runCommand:@"enterprise::extended-search",
                   @"operator", @"OR", @"description", _str, nil];
  return result;
}

- (void)_fetchProjectRelations:(NSArray *)_projects {
  [self runCommand:
            @"project::get-owner",
            @"objects",     _projects,
            @"relationKey", @"owner", nil];
  [self runCommand:
            @"project::get-team",
            @"objects",     _projects,
            @"relationKey", @"team", nil];
  [self runCommand:
            @"project::get-company-assignments",
            @"objects",     _projects,
            @"relationKey", @"companyAssignments", nil];
}

- (NSArray *)_validatePermissionsOfProjectEOs:(NSArray *)_projects {
  // TODO: 'object' as key?
  return [self runCommand:@"project::check-get-permission",
                 @"object", _projects, nil];
}

/* actions */

- (id)projectSearch {
  // TODO: split up this huge method!
  NSArray *result = nil;

  [self->projects removeAllObjects];
  
  if ([self->searchProjectText length] > 0) {
    NSMutableArray *pj;
    id tmp;
    
    result = [self _findProjectEOsWithString:self->searchProjectText];

    pj = [[NSMutableArray alloc] init];
    
    [pj addObjectsFromArray:result];
    [self _fetchProjectRelations:pj];
    
    tmp = [self _validatePermissionsOfProjectEOs:pj];
    if (tmp != pj) {
      tmp = [tmp retain];
      [pj release];
      pj = tmp;
    }
    
    [self->projects addObjectsFromArray:
           [pj sortedArrayUsingFunction:compareProjects context:self]];
    [pj release]; pj = nil;
    
    result = nil;
  }
  
  if ([self searchEnterprises]) {
    result = [self _findEnterpriseEOsWithString:self->searchProjectText];
    [self _setEnterpriseNames:result];
    result = [result sortedArrayUsingFunction:compareEnterprises context:self];
    [self->projects addObjectsFromArray:result];
    result = nil;
  }
  
  if (self->selectedProject != nil) {
    if ([self->projects containsObject:self->selectedProject])
      [self->projects removeObject:self->selectedProject];
    [self->projects insertObject:self->selectedProject atIndex:0];
  }
  else if (self->markFirst && ([self->projects count] > 0)) {
    self->selectedProject = [[self->projects objectAtIndex:0] retain];
  }
  [self setSearchProjectText:@""];
  return nil;
}

- (id)enterpriseSearch {
  NSArray *result   = nil;

  [self->projects removeAllObjects];
  
  if ([self->searchEnterpriseText length] > 0) {
    result = [self runCommand:
                   @"enterprise::extended-search",
                   @"operator",    @"OR",
                   @"description", self->searchEnterpriseText,
                   nil];
  }
  if (result) {
    [self _setEnterpriseNames:result];
    result = [result sortedArrayUsingFunction:compareEnterprises context:self];
    [self->projects addObjectsFromArray:result];
  }
  if (self->selectedProject != nil) {
    if ([self->projects containsObject:self->selectedProject])
      [self->projects removeObject:self->selectedProject];
    [self->projects insertObject:self->selectedProject atIndex:0];
  }
  else if (self->markFirst && ([self->projects count] > 0)) {
    self->selectedProject = [[self->projects objectAtIndex:0] retain];
  }
  [self setSearchEnterpriseText:@""];
  return nil;
}

- (void)_setEnterpriseNames:(NSArray *)_enterprises {
  unsigned i, cnt;
  
  for (i = 0, cnt = [_enterprises count]; i < cnt; i++) {
    id obj = [_enterprises objectAtIndex:i];
    
    [obj takeValue:[obj valueForKey:@"description"] forKey:@"name"];
  }
}

@end /* SkyProjectSelection */
