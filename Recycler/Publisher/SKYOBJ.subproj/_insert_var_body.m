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

#include "SkyPubSKYOBJ.h"
#include "common.h"
#include <DOM/EDOM.h>

@interface WOComponent(Docs)
- (id)document;
@end

@interface WOComponent(Priv)
- (id)childComponentWithName:(NSString *)_name;
@end


extern void WOContext_enterComponent
(WOContext *_ctx, WOComponent *_component, WOElement *element);
extern void WOContext_leaveComponent(WOContext *_ctx, WOComponent *_component);

@implementation SkyPubSKYOBJNodeRenderer(InsertVarBody)

- (void)_appendInsertvalueVarBodyNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  WOComponent *parent, *child;
  
  parent = [_ctx component];
  
  if ((child = [parent childComponentWithName:@"body"]) == nil) {
    /* make child ... */
    id doc;
    
    doc = [(id)[_ctx component] document];
    
    child = [[[_ctx component]
                    resourceManager]
                    pageWithName:[doc valueForKey:@"NSFilePath"]
                    languages:nil];
  }
  
  if (child) {
    WOContext_enterComponent(_ctx, child, nil /*self->template*/);
    [child appendToResponse:_response inContext:_ctx];
    WOContext_leaveComponent(_ctx, child);
  }
  else {
    [_response appendContentHTMLString:@"[did not find body to insert]"];
  }
}

@end /* SkyPubSKYOBJNodeRenderer(InsertVarBody) */

