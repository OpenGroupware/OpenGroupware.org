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

#include "SkyPubSKYOBJ.h"
#include "SkyPubResourceManager.h"
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

@implementation SkyPubSKYOBJNodeRenderer(Template)

- (void)_appendInsertvalueTemplateNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  WOComponent *parent, *child;
  NSString    *templateName;
  NSString    *tmp;
  id doc;
  
  parent = [_ctx component];

  if ((tmp = [self stringFor:@"name" node:_node ctx:_ctx]))
    templateName = tmp;
  else if ((tmp = [self stringFor:@"key" node:_node ctx:_ctx]))
    templateName = [self contextValueWithName:tmp inContext:_ctx];
  else
    templateName = @"";

  if ([[templateName pathExtension] length] == 0)
    templateName = [templateName stringByAppendingPathExtension:@"xtmpl"];
  
  doc = [(id)[_ctx component] document];
  
  child = [[[_ctx component]
                  resourceManager]
                  templateWithName:templateName
                  atPath:[doc valueForKey:@"NSFilePath"]];
  [child ensureAwakeInContext:_ctx];
  
  if (child) {
    WOContext_enterComponent(_ctx, child, nil /*self->template*/);
    [child appendToResponse:_response inContext:_ctx];
    WOContext_leaveComponent(_ctx, child);
  }
  else {
    [_response appendContentHTMLString:@"Missing Template: "];
    [_response appendContentHTMLString:templateName];
  }
}

@end /* SkyPubSKYOBJNodeRenderer(Template) */
