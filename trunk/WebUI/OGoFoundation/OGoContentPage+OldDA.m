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

#include "OGoContentPage.h"
#include "WOComponent+Commands.h"
#include "OGoNavigation.h"
#include "OGoSession.h"
#include "common.h"

@implementation OGoContentPage(OldDirectActions)

- (id)_performViewDocumentActionNamed:(NSString *)_action
  parameters:(NGHashMap *)_paras
  inContext:(WOContext *)_ctx
{
  NSMutableDictionary *args;
  
  args = [[[_paras asDictionary] mutableCopy] autorelease];

  if ([args count] > 0) {
    id       doc      = nil;
    id       project  = nil;
    NSArray  *result  = nil;
    NSString *command = @"doc::get";

    [args setObject:@"AND"                             forKey:@"operator"];
    [args setObject:intObj(LSDBReturnType_ManyObjects) forKey:@"returnType"];
      
    result = [self runCommand:command arguments:args];

    if ([result count] == 1)
      doc = [result lastObject];
    else if ([result count] == 0)
      [self setErrorString:@"No entry matched URL query."];
    else {
      doc = [result objectAtIndex:0];
    }
    if (doc) {
      result = [self runCommand:@"project::get",
                     @"projectId",  [doc valueForKey:@"projectId"],
                     @"returnType", intObj(LSDBReturnType_OneObject), nil];

      if ([result count] == 1) {
        project = [result lastObject];
      }
      else {
        [self setErrorString:@"No project for document available."];
      }

      if (project) {
        BOOL isFake = [[project valueForKey:@"isFake"] boolValue];

        if (isFake) {
          NSArray *eps = nil;
            
          [self runCommand:@"project::get-enterprises",
                @"project", project, nil];
          eps = [project valueForKey:@"enterprises"];

          if ([eps count] > 0) {
            id          enterprise;
            NGMimeType  *mt;
            WOComponent *ct = nil;

            enterprise = [eps objectAtIndex:0];
            mt = [NGMimeType mimeType:@"eo" subType:@"enterprise"];
              
            [[self session] transferObject:enterprise owner:nil];
            ct = [[self session]
                        instantiateComponentForCommand:@"view"
                        type:mt
                        object:doc];
            [ct performSelector:@selector(prepareWithDoc:)
                withObject:doc];
            [[self navigation] enterPage:(id)ct];
          }
        }
        else {
          NGMimeType  *mt = [NGMimeType mimeType:@"eo" subType:@"project"];
          WOComponent *ct = nil;
            
          [[_ctx session] transferObject:project owner:self];
          ct = [[_ctx session]
                      instantiateComponentForCommand:@"view"
                      type:mt
                      object:doc];
          [ct performSelector:@selector(prepareWithDoc:) withObject:doc];
          [[self navigation] enterPage:(id)ct];
        }
      }
    }
  }
  return nil;
}

- (id)_performViewProjectActionNamed:(NSString *)_action
  parameters:(NGHashMap *)_paras
  inContext:(WOContext *)_ctx
{
  NSMutableDictionary *args = AUTORELEASE([[_paras asDictionary] mutableCopy]);
  id viewObject = nil;

  [args setObject:@"AND"                             forKey:@"operator"];
  [args setObject:intObj(LSDBReturnType_ManyObjects) forKey:@"returnType"];

  if ([args count] > 0) {
    NSArray *result    = nil;
    id      documentId = [args objectForKey:@"documentId"];

    [args removeObjectForKey:@"documentId"];

    result = [self runCommand:@"project::get" arguments:args];

    if ([result count] == 1)
      viewObject = [result lastObject];
    else if ([result count] == 0)
      [self setErrorString:@"No entry matched URL query."];
    else {
      [self setErrorString:@"More than one entry matched URL query, "
            @"showing first."];
      viewObject = [result objectAtIndex:0];
    }
    if (viewObject) {
      if (documentId) {
        [args removeObjectForKey:@"projectId"];
        [args setObject:documentId forKey:@"documentId"];
        result = [self runCommand:@"doc::get" arguments:args];

        if ([result count] > 0) {
          result = [result lastObject];
          if ([[result valueForKey:@"isFolder"] boolValue]) {
            [viewObject takeValue:result forKey:@"currentFolder"];
          }
        }
      }
      [[_ctx session] transferObject:viewObject owner:self];
      [self executePasteboardCommand:@"view"];
    }
  }
  else {
    [self logWithFormat:@"Attributes missing for direct action: %@", _action];
    [self setErrorString:@"No attributes were specified in query !"];
  }
  return nil;
}

- (id)_performViewActionNamed:(NSString *)_action
  parameters:(NGHashMap *)_paras
  inContext:(WOContext *)_ctx
{
  NSMutableDictionary *args = AUTORELEASE([[_paras asDictionary] mutableCopy]);
  id viewObject = nil;
  
  if ([args count] > 0) {
    NSArray  *result  = nil;
    NSString *command = nil;

    [args setObject:@"AND"                             forKey:@"operator"];
    [args setObject:intObj(LSDBReturnType_ManyObjects) forKey:@"returnType"];
      
    if ([_action isEqualToString:@"viewPerson"])
      command = @"person::get";
    else if ([_action isEqualToString:@"viewEnterprise"])
      command = @"enterprise::get";
    else if ([_action isEqualToString:@"viewAppointment"])
      command = @"appointment::get";
    else if ([_action isEqualToString:@"viewNote"])
      command = @"note::get";
    else if ([_action isEqualToString:@"viewJob"])
      command = @"job::get";

    if (command) {
      result = [self runCommand:command arguments:args];

      if ([result count] == 1)
        viewObject = [result lastObject];
      else if ([result count] == 0)
        [self setErrorString:@"No entry matched URL query."];
      else {
        [self setErrorString:@"More than one entry matched URL query, "
              @"showing first."];
        viewObject = [result objectAtIndex:0];
      }
    }
    else {
      [self logWithFormat:@"Cannot handle direct action: %@", _action];
      [self setErrorString:@"Cannot handle specified view URL !"];
    }
  }
  else {
    [self logWithFormat:@"Attributes missing for direct action: %@", _action];
    [self setErrorString:@"No attributes were specified in query !"];
  }
  
  if (viewObject) {
    [[_ctx session] transferObject:viewObject owner:self];
    [self executePasteboardCommand:@"view"];
  }
  return nil;
}

- (id)performActionNamed:(NSString *)_action
  parameters:(NGHashMap *)_paras
  inContext:(WOContext *)_ctx
{
  [self setErrorString:nil];
  [self syncAwake];
  
  [self debugWithFormat:@"executing old direct action %@  ..", _action];
  
  if ([_action hasPrefix:@"viewDocument"]) {
    return [self _performViewDocumentActionNamed:_action
                 parameters:_paras
                 inContext:_ctx];
  }
  if ([_action hasPrefix:@"viewProject"]) {
    return [self _performViewProjectActionNamed:_action
                 parameters:_paras
                 inContext:_ctx];
  }
  if ([_action hasPrefix:@"view"]) {
    return [self _performViewActionNamed:_action
                 parameters:_paras
                 inContext:_ctx];
  }
  return nil;
}

@end /* OGoContentPage(OldDirectActions) */
