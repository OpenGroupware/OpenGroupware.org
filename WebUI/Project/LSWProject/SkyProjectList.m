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

#include <OGoFoundation/LSWContentPage.h>

/*
  Example:

   *.wod:
   
     ProjectList: SkyProjectList {
       projects = projects;
     };

     Buttons: SkyButtons {
       onNew = newProject;
     }

   *.html:
   
     <#ProjectList>
       <#Buttons \>
     <\#ProjectList>
   
*/

@class NSArray, NSDictionary, NSString;

@interface SkyProjectList : LSWContentPage
{
  NSArray        *projects;
  id             project;
  
  NSArray        *attributes;
  NSDictionary   *selectedAttribute;
  unsigned       startIndex;
  BOOL           isDescending; 
}
@end

#import "common.h"

@implementation SkyProjectList

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->projects);
  RELEASE(self->selectedAttribute);
  RELEASE(self->project);
  RELEASE(self->attributes);
  [super dealloc];
}
#endif

- (void)syncSleep {
  RELEASE(self->project);           self->project  = nil;
  RELEASE(self->projects);          self->projects = nil;
  [super syncSleep];
}

//accessors  

// --- parent components

- (void)setProjects:(NSArray *)_projects {
  ASSIGN(self->projects, _projects);
}
- (NSArray *)projects {
  return self->projects;
}

// --------------------------------

- (void)setStart:(unsigned)_startIndex {
  self->startIndex = _startIndex;
}
- (unsigned)start {
  return self->startIndex;    
}

- (void)setIsDescending:(BOOL)_isDescending {
  self->isDescending = _isDescending;
}
- (BOOL)isDescending {
  return self->isDescending;    
}

- (void)setSelectedAttribute:(NSDictionary *)_selectedAttribute {
  ASSIGN(self->selectedAttribute, _selectedAttribute);
}
- (NSDictionary *)selectedAttribute {
  return self->selectedAttribute;    
}

- (void)setAttributes:(NSArray *)_attributes {
  ASSIGN(self->attributes, _attributes);
}
- (NSArray *)attributes {
  return self->attributes;
}

- (void)setProject:(id)_project {
  ASSIGN(self->project, _project);
}
- (id)project {
  return self->project;    
}

// --- conditionals ---------------------------------

- (BOOL)isExtendedProjectList {
  if (self->projects == nil || [self->projects count] == 0)
    return NO;
  else {
    NSArray      *teams;
    NSEnumerator *teamEnum;
    id           team      = nil;

    teams    = [self->projects valueForKey:@"team"];
    teamEnum = [teams objectEnumerator];
    
    while ((team = [teamEnum nextObject])) {
      if (team != nil) return YES;
    }
  }
  return NO;
}

// --- actions --------------------------------------

- (id)viewProject {
  if (self->project == nil)
     return nil;
  
  return [[[self session]
                 navigation]
                 activateObject:[self->project globalID]
                 withVerb:@"view"];
}

- (NSNumber *)isAccessTeamArchived {
  return [NSNumber numberWithBool:[[[self->project valueForKey:@"team"]
                                                   valueForKey:@"dbStatus"]
                                                   isEqualToString:@"archived"]];
}

- (NSNumber *)isOwnerArchived {
  return [NSNumber numberWithBool:[[[self->project valueForKey:@"owner"]
                                                   valueForKey:@"dbStatus"]
                                                   isEqualToString:@"archived"]];
}

#if 0
- (void)appendToResponse:(WOResponse *)_r inContext:(WOContext *)_ctx {
  NSAutoreleasePool *pool;
  
  pool = [[NSAutoreleasePool alloc] init];
  [super appendToResponse:_r inContext:_ctx];
  RELEASE(pool);
}
#endif

@end /* SkyProjectList */
