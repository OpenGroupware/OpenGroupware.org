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

#import <LSFoundation/LSDBObjectDeleteCommand.h>

@interface LSDeleteProjectCommand : LSDBObjectDeleteCommand
@end

#import "common.h"
 
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
                  ([accountId intValue] == 10000))
          reason:@"only project manager can delete this project!"];
    
    [self assert:(([obj valueForKey:@"teamId"] == nil) ||
                  ([accountId intValue] == 10000))
          reason:@"project manager can only delete private projects!"];
  }
}

- (void)_executeInContext:(id)_context {
  [self _deleteProjectInfo];

  if ([[[self object] valueForKey:@"toDocument"] count] <= 1
      && [self reallyDelete]) {
    [self _deleteRootDocumentInContext:_context];
  } else {
    [[self object] takeValue:@"30_archived" forKey:@"status"];
  }
  [[NSNotificationCenter defaultCenter]
                         postNotificationName:@"SkyProjectDidChangeNotification"
                         object:nil];
  [super _executeInContext:_context];
}

- (NSString *)entityName {
  return @"Project";
}

@end
