/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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
// $Id$

#include "SkyPubSKYOBJ.h"
#include "SkyPubResourceManager.h"
#include "PubKeyValueCoding.h"
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

@implementation SkyPubSKYOBJNodeRenderer(IncludeText)

static BOOL debugIncludeText = NO;

- (void)_appendIncludetextNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  WOComponent *parent, *child;
  id       doc;
  NSString *docPath, *ipath;
  
  ipath = [self stringFor:@"includetext" node:_node ctx:_ctx];
  doc   = [(id)[_ctx component] document];

  if ([ipath isAbsolutePath])
    docPath = ipath;
  else {
    docPath = [doc valueForKey:@"NSFilePath"];
    
    if (![[doc valueForKey:NSFileType] isEqualToString:NSFileTypeDirectory])
      docPath = [docPath stringByDeletingLastPathComponent];
    
    docPath = [docPath stringByAppendingPathComponent:ipath];
  }

  if (debugIncludeText) {
    [self logWithFormat:@"including path %@", docPath];

    [_response appendContentString:@"<!-- includetext: "];
    [_response appendContentHTMLString:ipath];
    [_response appendContentString:@" document "];
    [_response appendContentHTMLString:docPath];
    [_response appendContentHTMLString:@" relative to "];
    [_response appendContentString:[doc valueForKey:@"NSFilePath"]];
    [_response appendContentString:@" -->"];
  }
  
  parent = [_ctx component];
  
  child = [[parent resourceManager]
                   pageWithName:docPath
                   languages:nil];
  
  if (child) {
    WOContext_enterComponent(_ctx, child, nil /*self->template*/);
    [child appendToResponse:_response inContext:_ctx];
    WOContext_leaveComponent(_ctx, child);
  }
  else {
    [_response appendContentHTMLString:@"[did not find text to include]"];
  }
}

@end /* SkyPubSKYOBJNodeRenderer(IncludeText) */
