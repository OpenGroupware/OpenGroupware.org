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

// TODO: whats the difference to SkyProjectSelection?
/*
  Usage:
    ProjectSelections: SkyProjectSelections {
      selectedProjects  = projects;
      title             = labels.project;
      searchEnterprises = YES;
    }
*/

@class NSString, NSMutableArray, NSArray;

@interface SkyProjectSelections : OGoComponent
{
  NSString       *title;
  NSString       *searchProjectText;
  NSString       *searchEnterpriseText;
  NSMutableArray *projects;
  NSArray        *selectedProjects;
  NSString       *nilString;
  
  BOOL           searchEnterprises;
  BOOL           withoutTitles;
}
- (void)_setEnterpriseNames:(NSArray *)_enterprises;
@end

#include "common.h"

@implementation NSObject(SkyProjectSelectionsLabel)

- (NSString *)skyProjectSelectionLabel {
  if ([[self entityName] isEqualToString:@"Enterprise"]) {
    return [NSString stringWithFormat:@"<%@>",
                       [self valueForKey:@"description"]];
  }
  else
    return [self valueForKey:@"name"];
}

@end /* NSObject(SkyProjectSelectionsLabel) */

@interface NSObject(Gids)
- (EOGlobalID *)globalID;
@end

@implementation SkyProjectSelections

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

  name1 = (name1 == nil) ? (NSString*)@"" : name1;
  name2 = (name2 == nil) ? (NSString*)@"" : name2;

  return [name1 compare:name2];
}

- (id)init {
  if ((self = [super init])) {
    self->projects = [[NSMutableArray alloc] initWithCapacity:4];
    self->title    = [[[self labels] valueForKey:@"Project"] copy];
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->title);
  RELEASE(self->projects);
  RELEASE(self->selectedProjects);
  RELEASE(self->searchProjectText);
  RELEASE(self->searchEnterpriseText);
  RELEASE(self->nilString);
  [super dealloc];
}

/* operations */

- (void)_rearrangeProjects {
  if (self->selectedProjects != nil) {
    int i, cnt;
    
    cnt = [self->selectedProjects count];
    
    for (i=0; i<cnt; i++) {
      id p;

      p = [self->selectedProjects objectAtIndex:i];
      if ([self->projects containsObject:p])
        [self->projects removeObject:p];
    }
    {
      NSMutableArray *tmp;

      tmp = [[NSMutableArray alloc] initWithArray:self->selectedProjects];
      [tmp addObjectsFromArray:self->projects];

      ASSIGN(self->projects, tmp);
    }
  }
}

/* accessors */

// --- api for parent component
- (void)setTitle:(NSString *)_title {
  ASSIGNCOPY(self->title, _title);
}
- (NSString *)title {
  return self->title;
}

- (void)setSearchEnterprises:(BOOL)_flag {
  self->searchEnterprises = _flag;
}
- (BOOL)searchEnterprises {
  return self->searchEnterprises;
}

- (void)setNilString:(NSString *)_nilString {
  ASSIGNCOPY(self->nilString, _nilString);
}
- (NSString *)nilString {
  return self->nilString;
}

- (void)setWithoutTitles:(BOOL)_flag {
  self->withoutTitles = _flag;
}
- (BOOL)withoutTitles {
  return self->withoutTitles;
}

// -----------------------------

- (void)setSelectedProjects:(NSMutableArray *)_selectedProjects {
  ASSIGN(self->selectedProjects, _selectedProjects);
  if (([self->projects count] == 0) && ([_selectedProjects count] > 0))
     [self _rearrangeProjects];
}
- (NSArray *)selectedProjects {
  if (self->selectedProjects == nil)
    self->selectedProjects = [[NSArray alloc] init];
  
  return self->selectedProjects;
}

- (NSMutableArray *)projects {
  return self->projects;
}

- (NSString *)searchProjectText {
  return self->searchProjectText;
}
- (void)setSearchProjectText:(NSString *)_text {
  if (self->searchProjectText != _text) {
    RELEASE(self->searchProjectText); self->searchProjectText = nil;
    self->searchProjectText = [_text copyWithZone:[self zone]];
  }
}

- (NSString *)searchEnterpriseText {
  return self->searchEnterpriseText;
}
- (void)setSearchEnterpriseText:(NSString *)_text {
  if (self->searchEnterpriseText != _text) {
    RELEASE(self->searchEnterpriseText); self->searchEnterpriseText = nil;
    self->searchEnterpriseText = [_text copyWithZone:[self zone]];
  }
}

/* actions */

- (id)projectSearch {
  NSArray *result = nil;

  [self->projects removeAllObjects];
  
  if ([self->searchProjectText length] > 0) {
    result = [self runCommand:
                   @"project::extended-search",
                   @"operator", @"OR",
                   @"name",     self->searchProjectText,
                   @"number",   self->searchProjectText,
                   nil];
    {
      NSMutableArray *pj;

      pj = [[NSMutableArray alloc] init];
    
      [pj addObjectsFromArray:result];

      [self runCommand:
            @"project::get-owner",
            @"objects",     pj,
            @"relationKey", @"owner", nil];
      [self runCommand:
            @"project::get-team",
            @"objects",     pj,
            @"relationKey", @"team", nil];
      [self runCommand:
            @"project::get-company-assignments",
            @"objects",     pj,
            @"relationKey", @"companyAssignments", nil];

      {
        id tmp;
      
        tmp = [self runCommand:@"project::check-get-permission",
                    @"object",  pj, nil];

        if (tmp != pj) {
          RETAIN(tmp);
          RELEASE(pj);
          pj = tmp;
        }
      }
      [self->projects addObjectsFromArray:
           [pj sortedArrayUsingFunction:compareProjects context:self]];
      RELEASE(pj); pj = nil;
      [self _rearrangeProjects];
    }
    result = nil;
  }
  
  if ([self searchEnterprises]) {
    result = [self runCommand:
                     @"enterprise::extended-search",
                     @"operator",    @"OR",
                     @"description", self->searchProjectText,
                     nil];
    [self _setEnterpriseNames:result];
    result = [result sortedArrayUsingFunction:compareEnterprises context:self];
    [self->projects addObjectsFromArray:result];
    result = nil;
  }

  [self _rearrangeProjects];
  
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

  [self _rearrangeProjects];

  [self setSearchEnterpriseText:@""];
  return nil;
}

- (void)_setEnterpriseNames:(NSArray *)_enterprises {
  int i, cnt;
  
  for (i = 0, cnt = [_enterprises count]; i < cnt; i++) {
    id obj;
    
    obj = [_enterprises objectAtIndex:i];
    [obj takeValue:[obj valueForKey:@"description"] forKey:@"name"];
  }
}

@end /* SkyProjectSelections */
