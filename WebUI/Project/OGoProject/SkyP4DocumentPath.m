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

#include <NGObjWeb/WODynamicElement.h>

/*
  This dynamic elements renders a project navigation, eg
  
    <Project> / <blah> / blub
  
  for a given document.
*/

@interface SkyP4DocumentPath : WODynamicElement
{
  WOAssociation *fileManager;
  WOAssociation *documentId;
  WOAssociation *currentPath;
  WOAssociation *document;
  WOAssociation *action;
  WOElement     *template;
}

@end

#include "common.h"

@implementation SkyP4DocumentPath

- (id)initWithName:(NSString *)_name
  associations:(NSDictionary *)_assocs
  template:(WOElement *)_templ
{
  if ((self = [super initWithName:_name associations:_assocs template:_templ])) {
    self->fileManager = [[_assocs objectForKey:@"fileManager"] copy];
    self->documentId  = [[_assocs objectForKey:@"documentId"]  copy];
    self->currentPath = [[_assocs objectForKey:@"currentPath"] copy];
    self->action      = [[_assocs objectForKey:@"action"]      copy];
    self->document    = [[_assocs objectForKey:@"document"]    copy];

    self->template = RETAIN(_templ);
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->template);
  RELEASE(self->action);
  RELEASE(self->currentPath);
  RELEASE(self->fileManager);
  RELEASE(self->documentId);
  [super dealloc];
}

- (NSArray *)_pathComponentsInContext:(WOContext *)_ctx {
  id         fm;
  EOGlobalID *dgid;
  NSString   *dpath;
  id         doc;

  if ((doc = [self->document valueInComponent:[_ctx component]]) == nil) {
    if ((fm = [self->fileManager valueInComponent:[_ctx component]]) == nil)
      return nil;
  
    if ((dgid = [self->documentId valueInComponent:[_ctx component]]) == nil) {
      [[_ctx component] debugWithFormat:
                        @"%s: missing document gid for docpath ..",
                        __PRETTY_FUNCTION__];
      return nil;
    }
  
    if ((dpath = [fm pathForGlobalID:dgid]) == nil) {
      [[_ctx component] debugWithFormat:@"%s: got no path for document gid %@",
                        __PRETTY_FUNCTION__,
                        dgid];
      return nil;
    }
  }
  else { //self->document != nil
    dpath = [doc path];
  }
  
  return [dpath pathComponents];
}

- (id)invokeActionForRequest:(WORequest *)_request inContext:(WOContext *)_ctx {
  id result;
  id idxId;

  if ((idxId  = [_ctx currentElementID])) {
    int idx;
    unsigned i, count;
    NSArray  *dpaths;
    NSString *cp;
    
    idx = [idxId intValue];
    [_ctx consumeElementID]; // consume index-id

    /* this updates the element-id path */
    [_ctx appendElementIDComponent:idxId];
    
    dpaths = [self _pathComponentsInContext:_ctx];
    
    cp = nil;
    for (i = 0, count = [dpaths count]; (i < count) && (i <= idx); i++) {
      NSString *pc;
      
      pc = [dpaths objectAtIndex:i];
      cp = (i == 0) ? pc : [cp stringByAppendingPathComponent:pc];
    }
    
    [self->currentPath setStringValue:cp inComponent:[_ctx component]];
    
    result = [self->action valueInComponent:[_ctx component]];
    
    [_ctx deleteLastElementIDComponent];
  }
  else {
    [[_ctx session]
           logWithFormat:@"%s: %@: MISSING INDEX ID in URL !",
             __PRETTY_FUNCTION__,
             self];
  }
  
  return result;
}

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  id         fm;
  NSArray    *dpaths;
  unsigned   i, count;
  NSString   *cp;

  if ((fm = [self->fileManager valueInComponent:[_ctx component]]) == nil) {
    [_response appendContentString:@"[missing filemanager]"];
    [[_ctx component] logWithFormat:@"missing filemanager for docpath .."];
    return;
  }
  
  if ((dpaths = [self _pathComponentsInContext:_ctx]) == nil) {
    [_response appendContentString:@"[missing paths]"];
    [[_ctx component] logWithFormat:@"missing paths for docpath .."];
    return;
  }
  
  [_ctx appendZeroElementIDComponent];

  for (i = 0, count = [dpaths count]; i < count; i++) {
    NSString *pc;

    pc = [dpaths objectAtIndex:i];
    cp = i == 0 ? pc : [cp stringByAppendingPathComponent:pc];
    
    [self->currentPath setStringValue:cp inComponent:[_ctx component]];
    
    if ((i == 0) && [pc isEqualToString:@"/"]) {
      pc = [[fm fileSystemAttributesAtPath:@"/"]
                objectForKey:@"NSFileSystemName"];
      if (pc == nil) pc = @"/";
    }
    
    if (i == (count - 1)) {
      /* last element */
      [_response appendContentString:@"<b>"];
      [_response appendContentHTMLString:pc];
      [self->template appendToResponse:_response inContext:_ctx];
      [_response appendContentString:@"</b>"];
    }
    else {
      [_response appendContentString:@"<a href=\""];
      [_response appendContentString:[_ctx componentActionURL]];
      [_response appendContentString:@"\" title=\""];
      [_response appendContentHTMLAttributeValue:pc];
      [_response appendContentString:@"\""];
      [_response appendContentCharacter:'>'];
      
      [_response appendContentHTMLString:pc];
      
      [self->template appendToResponse:_response inContext:_ctx];
      
      [_response appendContentString:@"</a>"];

      [_response appendContentHTMLString:@"/"];
    }
    
    [_ctx incrementLastElementIDComponent];
  }
  [_ctx deleteLastElementIDComponent];
}

@end /* SkyP4DocumentPath */

#include "common.h"
