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

#include <OGoFoundation/LSWEditorPage.h>

@class NSMutableArray, NSString, NSMutableSet;

@interface SkyProjectAssignment : LSWEditorPage
{
@private
  NSMutableSet   *projectsToRemove;
  NSMutableArray *projects;
  NSMutableArray *resultList;
  NSMutableArray *removedProjects;
  NSMutableArray *addedProjects;
  NSArray        *accountProjects;
  NSString       *searchText;
  NSString       *objType;
  NSString       *viewerTitle;
  id             item;
  BOOL           showExtended;
}

@end

#include "common.h"

static int compareProjects(id p1, id p2, void *context) {
  NSString *n1, *n2;
  
  n1 = [p1 valueForKey:@"name"];
  n2 = [p2 objectForKey:@"name"];
  return [n1 caseInsensitiveCompare:n2];
}

@implementation SkyProjectAssignment

- (void)_setViewerTitle {
  NSMutableString *str;
  id eo;

  str = [NSMutableString stringWithCapacity:128];
  eo  = [self object];

  if ([self->objType isEqualToString:@"person"]) {
    /* the name of the person */
    [str appendString:[[eo valueForKey:@"name"] stringValue]];
    [str appendString:@", "];
    [str appendString:[[eo valueForKey:@"firstname"] stringValue]];

    /* add private info */
    if ([[eo valueForKey:@"isPrivate"] boolValue]) {
      [str appendString:@" ("];
      [str appendString:[[self labels] valueForKey:@"private"]];
      [str appendString:@")"];
    }

    /* add read-only info */
    if ([[eo valueForKey:@"isReadonly"] boolValue]) {
      [str appendString:@" ("];
      [str appendString:[[self labels] valueForKey:@"readonly"]];
      [str appendString:@")"];
    }
  }
  else {
    /* the name of the enterprise */
    [str appendString:[[eo valueForKey:@"description"] stringValue]];

    /* add private info */
    if ([[eo valueForKey:@"isPrivate"] boolValue]) {
      [str appendString:@" ("];
      [str appendString:[self labelForKey:@"privateLabel"]];
      [str appendString:@")"];
    }

    /* add read-only info */
    if ([[eo valueForKey:@"isReadonly"] boolValue]) {
      [str appendString:@" ("];
      [str appendString:[self labelForKey:@"readonlyLabel"]];
      [str appendString:@")"];
    }
  }
  ASSIGNCOPY(self->viewerTitle, str);
}

- (id)init {
  if ((self = [super init])) {
    self->resultList       = [[NSMutableArray alloc] initWithCapacity:4];
    self->removedProjects  = [[NSMutableArray alloc] initWithCapacity:4];
    self->addedProjects    = [[NSMutableArray alloc] initWithCapacity:4];
    self->projects         = [[NSMutableArray alloc] initWithCapacity:4];
    self->projectsToRemove = [[NSMutableSet   alloc] initWithCapacity:4];
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->objType);
  RELEASE(self->viewerTitle);
  RELEASE(self->searchText);
  RELEASE(self->resultList);
  RELEASE(self->projects);
  RELEASE(self->projectsToRemove);
  RELEASE(self->addedProjects);
  RELEASE(self->removedProjects);
  [super dealloc];
}

/* activation */

- (BOOL)prepareForActivationCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(id)_cfg
{
  if ([super prepareForActivationCommand:_command type:_type
             configuration:_cfg]) {
    id obj       = [self object];
    id myAccount = [[self session] activeAccount];

    self->objType = [[[[obj entity] name] lowercaseString] retain];
    
    [self _setViewerTitle];
    
    {
      //set projects for activeAccount
      NSAssert1(myAccount, @"no account available in session %@ ..",
                [self session]);

      RELEASE(self->accountProjects); self->accountProjects = nil;
      self->accountProjects =
        [self runCommand:@"person::get-projects",
            @"object",       myAccount,
            @"withoutKinds", [NSArray arrayWithObjects:
                                      @"00_invoiceProject",
                                      @"05_historyProject",
                                      @"10_edcProject",
                                      nil],
            nil];
      RETAIN(self->accountProjects);
    }
    {
      //set projects for eo (Person/Enterprise)
      NSArray  *pj  = nil;

      if ([self->objType isEqualToString:@"person"]) {
        if ([myAccount isEqual:obj]) {
          pj = self->accountProjects;
        }
        else {
          pj = [self runCommand:@"person::get-projects",
               @"object",       obj,
               @"withoutKinds", [NSArray arrayWithObjects:
                                         @"00_invoiceProject",
                                         @"05_historyProject",
                                         @"10_edcProject",
                                         nil],
               nil];
        }
      }
      else {
        pj = [self runCommand:@"enterprise::get-projects",
               @"object",       obj,
               nil];
      }
      if (pj != nil)
        [self->projects addObjectsFromArray:pj];
    }

    return YES;
  }
  return NO;
}

- (void)syncAwake {
  [super syncAwake];
  
  [self->removedProjects removeAllObjects];
  [self->addedProjects   removeAllObjects];
}

- (void)syncSleep {
  self->item = nil;
  [self->removedProjects removeAllObjects];
  [self->addedProjects   removeAllObjects];
  [super syncSleep];
}

- (id)invokeActionForRequest:(WORequest *)_request inContext:(WOContext *)_ctx {
  int i, count;

  [self _ensureSyncAwake];
  
  // projects selected in resultList
  for (i = 0, count = [self->addedProjects count]; i < count; i++) {
    id  proj;
    id  pkey;
    int j, count2;

    proj = [self->addedProjects objectAtIndex:i];
    pkey = [proj valueForKey:@"projectId"];

    if (pkey == nil) {
      NSLog(@"ERROR(%@): invalid pkey of project %@", self, proj);
      continue;
    }
    for (j = 0, count2 = [self->projects count]; j < count2; j++) {
      id opkey;

      opkey = [[self->projects objectAtIndex:j] valueForKey:@"projectId"];
      if ([opkey isEqual:pkey]) { // already in array
        pkey = nil;
        break;
      }
    }

    if (pkey) {
      [self->projects addObject:proj];
      [self->resultList removeObject:proj];
    }
  }

  // projects not selected in projects list
  for (i = 0, count = [self->removedProjects count]; i < count; i++) {
    id  proj;
    id  pkey;
    int j, count2, removeIdx = -1;

    proj = [self->removedProjects objectAtIndex:i];
    pkey = [proj valueForKey:@"projectId"];

    if (pkey == nil) {
      NSLog(@"ERROR(%@): invalid pkey of project %@", self, proj);
      continue;
    }

    for (j = 0, count2 = [self->projects count]; j < count2; j++) {
      id opkey;

      opkey = [[self->projects objectAtIndex:j] valueForKey:@"projectId"];
      if ([opkey isEqual:pkey]) { // found in array
        removeIdx = j;
        break;
      }
    }

    if (removeIdx != -1) {
      [self->projects removeObjectAtIndex:removeIdx];
      [self->resultList addObject:proj];
    }
  }
  return [super invokeActionForRequest:_request inContext:_ctx];
}

/* accessors */

- (NSArray*)attributesList {
  NSMutableArray      *myAttr;
  NSMutableDictionary *myDict1;

  myAttr  = [NSMutableArray arrayWithCapacity:4];
  myDict1 = [[NSMutableDictionary alloc] initWithCapacity:2];
  [myDict1 takeValue:@"name" forKey:@"key"];
  [myAttr addObject: myDict1];
  [myDict1 release];
  if (self->showExtended) {
    NSMutableDictionary *myDict2;
    
    myDict2 = [[NSMutableDictionary alloc] initWithCapacity:4];
    [myDict2 takeValue:@"number" forKey:@"key"];
    [myDict2 takeValue:@" (" forKey:@"prefix"];
    [myDict2 takeValue:@")" forKey:@"suffix"];
    [myAttr addObject:myDict2];
    [myDict2 release];
  }
  return myAttr;
}

- (void)setShowExtended:(BOOL)_flag {
  self->showExtended = _flag;
}
- (BOOL)showExtended {
  return self->showExtended;
}

- (void)setRemovedProjects:(NSMutableArray*)_removed {
  ASSIGN(self->removedProjects,_removed);
  [self->projectsToRemove addObjectsFromArray:self->removedProjects];
}

- (NSMutableArray*)removedProjects {
  return self->removedProjects;
}

- (void)setAddedProjects:(NSMutableArray*)_added {
  ASSIGN(self->addedProjects,_added);
}

- (NSMutableArray*)addedProjects {
  return self->addedProjects;
}

- (void)setItem:(id)_item {
  self->item = _item;
}
- (id)item {
  return self->item;
}

- (NSArray *)projects {
  return [self->projects sortedArrayUsingFunction:compareProjects context:NULL];
}
- (NSArray *)resultList {
  return [self->resultList sortedArrayUsingFunction:compareProjects
              context:NULL];
}

- (BOOL)isListNotEmpty {
  return ( ([self->resultList count] > 0) && ([self->projects count] > 0) )
    ? YES : NO;
}

- (void)setSearchText:(NSString *)_text {
  if (self->searchText != _text) {
    RELEASE(self->searchText); self->searchText = nil;
    self->searchText = [_text copyWithZone:[self zone]];
  }
}
- (NSString *)searchText {
  return self->searchText;
}

- (NSString *)viewerTitle {
  return self->viewerTitle;
}

- (BOOL)hasProjectSelection {
  return ([self->projects count] + [self->resultList count]) > 0 ? YES : NO;
}

- (int)noOfCols {
  id  d = [[[self session] userDefaults] objectForKey:@"projects_no_of_cols"];
  int n = [d intValue];
  
  return (n > 0) ? n : 2;
}

// notifications

- (NSString *)updateNotificationName {
  return LSWUpdatedProjectNotificationName;
}

// actions

// removing duplicate entries

- (void)removeDuplicateProjectListEntries {
  int i, count;

  for (i = 0, count = [self->projects count]; i < count; i++) {
    int j, count2;
    id  pkey;

    pkey = [[self->projects objectAtIndex:i] valueForKey:@"projectId"];
    if (pkey == nil) continue;

    for (j = 0, count2 = [self->resultList count]; j < count2; j++) {
      id proj = [self->resultList objectAtIndex:j];

      if ([[proj valueForKey:@"projectId"] isEqual:pkey]) {
        [self->resultList removeObjectAtIndex:j];
        break; // must break, otherwise 'count2' will be invalid
      }
    }
  }
}

- (id)search {
  [self->resultList removeAllObjects];

  if (self->searchText != nil && [self->searchText length] > 0) {
    id              ac;
    NSMutableArray  *result;
    NSMutableString *str;
    NSArray         *fields    = nil;
    NSEnumerator    *pEnum     = nil;
    NSEnumerator    *fieldEnum = nil;
    NSString        *field     = nil;
    id              p          = nil;

    ac         = [[self session] activeAccount];
    result    = [NSMutableArray arrayWithCapacity:16];
    str       = [NSMutableString stringWithCapacity:32];
    
    [str appendString:self->searchText];
    fields = [NSArray arrayWithObjects:@"name", @"number", nil];
    pEnum  = [self->accountProjects objectEnumerator];

    while ((p = [pEnum nextObject])) {
      fieldEnum = [fields objectEnumerator];
      
      while ((field = [fieldEnum nextObject])) {
        NSString *s = [[p valueForKey:field] stringValue];;

        if (s == nil)
	  continue;
	
	s = [s lowercaseString];
	if ([s rangeOfString:[str lowercaseString]].length > 0) {
	  [result addObject:p];
	  break;
        }
      }
    }
    if (result) [self->resultList addObjectsFromArray:result];
    [self removeDuplicateProjectListEntries];
  }
  return nil;
}

- (id)save {
  id       obj  = [self object];
  NSString *cmd = [self->objType stringByAppendingString:@"::assign-projects"];

  NSLog(@"%@", [obj run:cmd, @"projects",         self->projects,
                @"removedProjects" , self->projectsToRemove, nil]);

  NSLog(@"save: >%@< >%@< >%@<", cmd, self->projects, self->projectsToRemove);

  if (![self commit]) {
    [self rollback];
    return nil;
  }
  [self postChange:LSWUpdatedProjectNotificationName onObject:obj];
  [[NSNotificationCenter defaultCenter]
                         postNotificationName:
                         @"SkyProjectDidChangeNotification"
                         object:obj];
  [self leavePage];
  return nil;
}

- (id)newProject {
  WOSession   *sn = [self session];
  NGMimeType  *mt = [NGMimeType mimeType:@"eo" subType:@"project"];
  WOComponent *ct = nil;

  ct = [sn instantiateComponentForCommand:@"new" type:mt];
  [ct takeValue:[self object] forKey:@"company"];
  
  [self leavePage];
  [self enterPage:(id)ct];
  return nil;
}

@end  
