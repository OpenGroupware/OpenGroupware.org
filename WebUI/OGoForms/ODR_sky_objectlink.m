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

#include <NGObjDOM/ODNodeRenderer.h>

/*
  Usage:
    
    <var:objectlink const:url="27372"|gid="item.globalID" [const:verb="view"]/>

  This element generates a link which activates a SKYRiX object using the
  component system.
*/

@interface ODR_sky_objectlink : ODNodeRenderer
@end

#include "common.h"
#include <OGoBase/LSCommandContext+Doc.h>
#include <LSFoundation/LSCommandContext.h>
#include <OGoFoundation/OGoComponent.h>
#include <OGoFoundation/OGoSession.h>
#include <OGoFoundation/OGoNavigation.h>
#include <OGoDocuments/SkyDocumentManager.h>

@implementation ODR_sky_objectlink

- (id)invokeActionForNode:(id)_node
  fromRequest:(WORequest *)_request
  inContext:(WOContext *)_ctx
{
  if ([[_ctx elementID] isEqualToString:[_ctx senderID]]) {
    NSString   *url, *verb;
    EOGlobalID *gid;
    
    verb = [self stringFor:@"verb" node:_node ctx:_ctx];
    if ([verb length] == 0) verb = @"view";
    
    if ((url = [self stringFor:@"url" node:_node ctx:_ctx])) {
      id cmdctx;
      
      cmdctx = [(OGoSession *)[_ctx session] commandContext];
      gid    =
        [(id<SkyDocumentManager>)[cmdctx documentManager] globalIDForURL:url];
    }
    else if ((gid = [self valueFor:@"gid" node:_node ctx:_ctx])) {
      ;
    }
    else {
      gid  = nil;
    }
    
    if (gid) {
      //NSLog(@"clicked gid %@", gid);
      return [[(OGoSession *)[_ctx session] navigation]
                           activateObject:gid withVerb:verb];
    }
    else {
      return [[(OGoSession *)[_ctx session] navigation]
                     activateObject:url withVerb:verb];
    }
  }
  
  return [super invokeActionForNode:_node
                fromRequest:_request
                inContext:_ctx];
}

- (void)appendNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  NSString   *url;
  EOGlobalID *gid;
  NSString   *label;
  OGoSession *sn;
  
  sn = (id)[_ctx session];

  if ((url = [self stringFor:@"url" node:_node ctx:_ctx])) {
    id       cmdctx;
    NSString *cacheKey;
    
    cacheKey = [NSString stringWithFormat:@"_cache_sky_objectlink_%@", url];

    cmdctx = [sn commandContext];

    if ((label = [cmdctx valueForKey:cacheKey]) == nil) {
      gid =
        [(id<SkyDocumentManager>)[cmdctx documentManager] globalIDForURL:url];
    
      label = (gid)
        ? [sn labelForObject:gid]
        : url;
      
      if (label) [cmdctx takeValue:label forKey:cacheKey];
    }
  }
  else if ((gid = [self valueFor:@"gid" node:_node ctx:_ctx])) {
    label = [sn labelForObject:gid];
  }
  else {
    //[_response appendContentString:@"[missing url|gid for objectlink]"];
    return;
  }
  
  [_response appendContentString:@"<a href=\""];
  [_response appendContentString:[_ctx componentActionURL]];
  [_response appendContentCharacter:'"'];
  [_response appendContentString:@">"];
  
  [_response appendContentString:label];
  
  [_response appendContentString:@"</a>"];
}

@end /* ODR_sky_objectlink */
