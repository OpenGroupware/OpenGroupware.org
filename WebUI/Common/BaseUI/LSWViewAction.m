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

#include "LSWViewAction.h"
#include <OGoFoundation/WOSession+LSO.h>
#include <OGoFoundation/LSWNavigation.h>
#include <OGoFoundation/OGoSession.h>
#include <OGoFoundation/OGoContentPage.h>
#include <OGoBase/LSCommandContext+Doc.h>
#include <LSFoundation/LSFoundation.h>
#include <NGMime/NGMimeType.h>
#include <OGoDocuments/SkyDocuments.h>
#include <OGoDocuments/SkyDocumentManager.h>
#include "common.h"

/* 
   Note: this DA is basically deprecated - use the "activate" action instead!

   Still used in:
     LSWProjectHtmlMailPage
*/

@implementation LSWViewAction

+ (int)version {
  return 1;
}
+ (void)initialize {
  NSAssert2([super version] == 4,
	    @"invalid superclass (%@) version %i !",
	    NSStringFromClass([self superclass]), [super version]);
}

/* misc */

- (NSMutableDictionary *)commandParameters {
  NSMutableDictionary *args;
  NSEnumerator *keys;
  WORequest    *req;
  NSString     *key;

  args = [NSMutableDictionary dictionaryWithCapacity:16];
  
  req  = [self request];
  keys = [[req formValueKeys] objectEnumerator];
  while ((key = [keys nextObject])) {
    NSString *value;

    value = [req formValueForKey:key];

    if (value)
      [args setObject:value forKey:key];
  }

  [args setObject:@"AND" forKey:@"operator"];
  [args setObject:[NSNumber numberWithInt:LSDBReturnType_ManyObjects]
        forKey:@"returnType"];
  
  return args;
}

- (id)activePage {
  return [[[self session] navigation] activePage];
}

- (id)viewObject:(id)_object {
  return [[self activePage] activateObject:_object withVerb:@"view"];
}

/* error pages */

- (id<WOActionResults>)missingSessionResponse {
  id page;
  
  [self debugWithFormat:@"missing session"];

  page = [self pageWithName:@"Main"];

  return page;
}

- (id<WOActionResults>)noMatchingObjectsResponse {
  id page;

  if ((page = [[[self session] navigation] activePage]) == nil) {
    [self debugWithFormat:@"no active page is set (session=%@)",
            [[self existingSession] sessionID]];
    
    page = [self pageWithName:@"Main"];
  }
  else {
    [self debugWithFormat:@"no matching objects for URL query."];
    [page takeValue:@"No entry matched URL query." forKey:@"errorString"];
  }
  return page;
}

- (id<WOActionResults>)noActivePageResponse {
  [self debugWithFormat:@"no active page is set (session=%@)",
          [[self existingSession] sessionID]];

  return [self pageWithName:@"Main"];
}

/* operations */

- (id<WOActionResults>)viewWithCommand:(NSString *)_command {
  NSDictionary *args;
  NSArray *result;
  int resultCount;
  id  page;

  if ([self existingSession] == nil)
    return [self missingSessionResponse];

  if ((page = [self activePage]) == nil)
    return [self noActivePageResponse];
  
  args   = [self commandParameters];
  result = [[self session] runCommand:_command arguments:args];
  resultCount = [result count];
  
  if (resultCount == 0)
    return [self noMatchingObjectsResponse];

  [page takeValue:@"" forKey:@"errorString"];
  page = [self viewObject:[result objectAtIndex:0]];

  if (resultCount > 1) {
    [page takeValue:@"More than one entry matched URL query, showing the first."
          forKey:@"errorString"];
  }
  return page;
}

/* missing session */

- (id<WOActionResults>)missingSession:(NSString *)_action {
  /* 
     This add the direct-action object to the login-page for execution 
     when the login process is finished.
  */
  WOComponent *mainPage;
  
  mainPage = [self pageWithName:@"Main"];
  [mainPage takeValue:self forKey:@"directActionObject"];

  if (_action)
    [mainPage takeValue:_action forKey:@"directAction"];
  
  [self logWithFormat:@"missing session, returning main for %@", _action];
    
  return mainPage;
}

/* actions */

- (id<WOActionResults>)viewPersonAction {
  if ([self existingSession] == nil)
    return [self missingSession:@"viewPerson"];
  
  return [self viewWithCommand:@"person::get"];
}
- (id<WOActionResults>)viewEnterpriseAction {
  if ([self existingSession] == nil)
    return [self missingSession:@"viewEnterprise"];
  
  return [self viewWithCommand:@"enterprise::get"];
}
- (id<WOActionResults>)viewAppointmentAction {
  if ([self existingSession] == nil)
    return [self missingSession:@"viewAppointment"];
  
  return [self viewWithCommand:@"appointment::get"];
}
- (id<WOActionResults>)viewDateAction {
  return [self viewAppointmentAction];
}
- (id<WOActionResults>)viewNoteAction {
  if ([self existingSession] == nil)
    return [self missingSession:@"viewNote"];
  
  return [self viewWithCommand:@"note::get"];
}
- (id<WOActionResults>)viewJobAction {
  if ([self existingSession] == nil)
    return [self missingSession:@"viewJob"];
  
  return [self viewWithCommand:@"job::get"];
}

- (id<WOActionResults>)viewDocumentAction {
  NSDictionary *args;
  id  document, project;
  NSArray *result;
  int resultCount;
  id  page;
  
  if ([self existingSession] == nil)
    return [self missingSession:@"viewDocument"];
  
  if ((page = [self activePage]) == nil)
    return [self noActivePageResponse];

  /* fetch document */
  
  args   = [self commandParameters];
  result = [[self session] runCommand:@"doc::get" arguments:args];
  resultCount = [result count];

  if (resultCount == 0)
    return [self noMatchingObjectsResponse];

  document = [result objectAtIndex:0];

  result = [[self session] runCommand:@"project::get",
                             @"projectId", [document valueForKey:@"projectId"],
                             @"returnType", intObj(LSDBReturnType_OneObject),
                             nil];

  /* fetch project associated with document */

  project = ([result count] > 0) ? [result objectAtIndex:0] : nil;

  if (project == nil) {
    [self debugWithFormat:@"missing project for document %@", document];
    return [self noMatchingObjectsResponse];
  }

  /* check type of project */

  if ([[project valueForKey:@"isFake"] boolValue]) {
    NSArray *eps = nil;
            
    [[self session]
           runCommand:@"project::get-enterprises", @"project", project, nil];
    eps = [project valueForKey:@"enterprises"];

    if ([eps count] > 0) {
      id          ep;
      NGMimeType  *mt;
      WOComponent *ct = nil;

      ep = [eps objectAtIndex:0];
      mt = [NGMimeType mimeType:@"eo" subType:@"enterprise"];
              
      [[self session] transferObject:ep owner:nil];
      ct = [[self session] instantiateComponentForCommand:@"view"
                           type:mt
                           object:ep];
      [ct performSelector:@selector(prepareWithDoc:) withObject:document];
      [[[self session] navigation] enterPage:(id)ct];
    }
  }
  else {
    return [[[self session] navigation]
                   activateObject:[document globalID] withVerb:@"view"];
  }
  
  return [self activePage];
}
- (id<WOActionResults>)viewDocAction {
  return [self viewDocumentAction];
}

- (id<WOActionResults>)viewProjectAction {
  NSMutableDictionary *args;
  NSArray *result;
  int resultCount;
  id  documentId;
  id  page;
  id  viewObject;
  id  folder = nil;
  NSNumber      *pid;
  EOKeyGlobalID *gid;
  NGMimeType    *mt;
  
  if ([self existingSession] == nil)
    return [self missingSession:@"viewProject"];

  if ((page = [self activePage]) == nil)
    return [self noActivePageResponse];

  args = [self commandParameters];
  documentId = [args objectForKey:@"documentId"];
  AUTORELEASE(RETAIN(documentId));
  [args removeObjectForKey:@"documentId"];

  /* fetch project */
    
  result = [[self session] runCommand:@"project::get" arguments:args];
  resultCount = [result count];

  if (resultCount == 0)
    return [self noMatchingObjectsResponse];

  if ((viewObject = [result objectAtIndex:0])) {
    WOComponent *ct = nil;

    if (documentId) {
      [args removeObjectForKey:@"projectId"];
      [args setObject:documentId forKey:@"documentId"];

      result = [[self session] runCommand:@"doc::get" arguments:args];
      resultCount = [result count];

      if (resultCount > 0) {
        result = [result objectAtIndex:0];

        if ([[result valueForKey:@"isFolder"] boolValue]) {
          folder = result;
        }
      }
    }
    pid = [viewObject valueForKey:@"projectId"];
    gid = [EOKeyGlobalID globalIDWithEntityName:@"Project" 
                         keys:&pid keyCount:1 zone:NULL];
    
    [[self session] transferObject:gid owner:nil];

    mt = [NGMimeType mimeType:@"eo-gid" subType:@"project"];
    ct = [[self session] instantiateComponentForCommand:@"view"
                         type:mt
                         object:gid];
    if (folder != nil) {
      [ct performSelector:@selector(setDirectoryPath:)
          withObject:[folder valueForKey:@"documentId"]];
    }
    [[[self session] navigation] enterPage:(id)ct];
  }

  return [self activePage];
}

- (id<WOActionResults>)viewAction {
  /* generic view */
  NSString *type, *oid;
  
  if ((oid = [[self request] formValueForKey:@"oid"]) == nil) {
    [self logWithFormat:@"missing object id in activation-action."];
    return nil;
  }

  type = [[self session] runCommand:@"get-object-type", @"oid", oid, nil];
  if (type == nil) {
    [self logWithFormat:@"couldn't determine type of objectid %@", oid];
    return nil;
  }
  return [self performActionNamed:[@"view" stringByAppendingString:type]];
}

- (id<WOActionResults>)performActionNamed:(NSString *)_name {
  id<WOActionResults> result;
  WOSession *session;
  
  if ((session = [self existingSession]) == nil)
    return [self missingSession:_name];
  
  if ([[session navigation] activePage] == nil)
    return [self missingSession:_name];
  
  result = [super performActionNamed:_name];

  return result;
}

@end /* LSWViewAction */
