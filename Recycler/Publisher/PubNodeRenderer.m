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

#include "PubNodeRenderer.h"
#include "SkyDocument+Pub.h"
#include "SkyPubComponent.h"
#include "PubKeyValueCoding.h"
#include <NGObjDOM/WOContext+Cursor.h>
#include <DOM/DOMNode.h>
#include "common.h"

@implementation SKYNodeRenderer

- (SkyDocument *)_folderDocumentInContext:(WOContext *)_ctx {
  SkyDocument *doc, *pdoc;
  
  if ((doc = [_ctx cursor]) == nil) {
    [[_ctx component] debugWithFormat:@"nothing stored in cursor .."];
    return nil;
  }
  
  if ([doc isKindOfClass:[WOComponent class]]) {
    [self logWithFormat:@"WARNING: ctx cursor is component, not doc !"];
    doc = [(SkyPubComponent *)doc document];
  }
  
  if ([[doc npsValueForKey:@"objType" inContext:_ctx]
            isEqualToString:@"publication"])
    return doc;
  
  if ((pdoc = [doc npsValueForKey:@"parent" inContext:_ctx]) == nil) {
    [[_ctx component]
           logWithFormat:
             @"WARNING(%s): doc %@ is no publication, but has no parent ...",
             __PRETTY_FUNCTION__, doc];
    return nil;
  }
  
  return pdoc;
}

- (id)contextValueWithName:(NSString *)_npsname inContext:(WOContext *)_ctx {
  id npsctx;
  id value;
  
  if ([_npsname length] == 0) {
#if DEBUG
    NSLog(@"%s: empty key ?!!", __PRETTY_FUNCTION__);
    abort();
#endif
    return nil;
  }
  
  npsctx = [_ctx cursor]; // usually the current document ...
  value  = [npsctx npsValueForKeyPath:_npsname inContext:_ctx];
  
  //NSLog(@"%s: key '%@' value '%@'", __PRETTY_FUNCTION__, _npsname, value);
  
  return value;
}

- (void)addUnsupportedNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  [_response appendContentString:@"[unsupported SKYOBJ: "];
  [_response appendContentHTMLString:[_node xmlStringValue]];
  [_response appendContentString:@"]"];
}

- (id)_nextDocumentInContext:(WOContext *)_ctx {
  return [self contextValueWithName:@"next" inContext:_ctx];
}
- (id)_previousDocumentInContext:(WOContext *)_ctx {
  return [self contextValueWithName:@"previous" inContext:_ctx];
}
- (id)_parentDocumentInContext:(WOContext *)_ctx {
  return [self contextValueWithName:@"parent" inContext:_ctx];
}

@end /* SKYNodeRenderer */
