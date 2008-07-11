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

#include <LSFoundation/LSDBObjectDeleteCommand.h>

@interface LSDeleteProjectCommand : LSDBObjectDeleteCommand
@end

#include "common.h"
 
@implementation LSDeleteProjectCommand

// command methods

- (void)_deleteRootDocumentInContext:(id)_context {
  id project  = [self object];
  id document = nil;
  
  LSRunCommandV(_context, @"project",  @"get-root-document",
                @"object",  project,
                @"relationKey", @"rootDocument", nil);

  document = [project valueForKey:@"rootDocument"];

  LSRunCommandV(_context, @"doc", @"delete",
                @"object",       document,
                @"reallyDelete", [NSNumber numberWithBool:[self reallyDelete]],
                nil);
}

- (BOOL)_deleteProjectInfo {
  // Note: project-info should be the comment of the project
  BOOL isOk        = NO; 
  id   projectInfo = nil;

  projectInfo = [[self object] valueForKey:@"toProjectInfo"];

  if ([projectInfo isNotNull]) {
    if ([self reallyDelete]) 
      isOk = [[self databaseChannel] deleteObject:projectInfo];
    else {
      [projectInfo takeValue:@"archived" forKey:@"dbStatus"];
      isOk = [[self databaseChannel] updateObject:projectInfo];
    }
  }
  [LSDBObjectCommandException raiseOnFail:isOk object:self
                              reason:[sybaseMessages description]];
  return YES;
}

- (void)_separateNotesInContext:(id)_context {
  id  notes;
  int i, cnt;

  notes  = [[self object] valueForKey:@"toNote"];

  for (i = 0, cnt = [notes count]; i < cnt; i++) {
    /*
      detach if date is assigned
      delete if nothing assigned
      access to delete notes should be granted since the notes are assigend
      to the appointment
    */
    id note = [notes objectAtIndex:i];

    if ([[note valueForKey:@"dateId"] isNotNull]) {
      // project still assigned
      LSRunCommandV(_context, @"note", @"set",
                              @"object", note, 
                              @"projectId", [EONull null],
                              @"dontCheckAccess", 
                                 [NSNumber numberWithBool:YES],
                              nil);
    } else {
        LSRunCommandV(_context, @"note", @"delete",
                                @"object", note, 
                                nil);
      }
  }

  if ([notes respondsToSelector:@selector(clear)])
    [notes clear];
}

- (BOOL)isRootPrimaryKey:(id)_key inContext:(id)_context {
  return [_key intValue] == 10000 ? YES : NO;
}

- (void)_prepareForExecutionInContext:(id)_context {
  id       obj;
  id       account;
  NSNumber *accountId;

  account   = [_context valueForKey:LSAccountKey];
  accountId = [account valueForKey:@"companyId"];
  
  [super _prepareForExecutionInContext:_context];

  if ([self reallyDelete]) {
    obj = [self object];
    
    [self assert:(([accountId isEqual:[obj valueForKey:@"ownerId"]]) ||
                  [self isRootPrimaryKey:accountId inContext:_context])
          reason:@"only project manager can delete this project!"];
    
    [self assert:(([obj valueForKey:@"teamId"] == nil) ||
                  [self isRootPrimaryKey:accountId inContext:_context])
          reason:@"project manager can only delete private projects!"];
  }
}

- (void)_executeInContext:(id)_context {

  [self _deleteProjectInfo];

  /* detach or delete notes */
  [self _separateNotesInContext:_context];

  /* delete properties */
  if ([self reallyDelete]) {
    [[_context propertyManager] removeAllPropertiesForGlobalID:
                                  [[self object] globalID]];
  }
  
  /* delete documents */
  if ([[[self object] valueForKey:@"toDocument"] count] <= 1
      && [self reallyDelete]) {
    [self _deleteRootDocumentInContext:_context];
  } 
  else {
    [[self object] takeValue:@"30_archived" forKey:@"status"];
  }

  /* delete links */
  [[_context linkManager] deleteLinksTo:(id)[[self object] globalID] type:nil];
  [[_context linkManager] deleteLinksFrom:(id)[[self object] globalID] type:nil];
  
  /* delete primary object */
  [super _executeInContext:_context];
  
  /* notify others */
  [[NSNotificationCenter defaultCenter]
    postNotificationName:@"SkyProjectDidChangeNotification"
    object:nil];
}

/* reflection for super class */

- (NSString *)entityName {
  return @"Project";
}

@end /* LSDeleteProjectCommand */
