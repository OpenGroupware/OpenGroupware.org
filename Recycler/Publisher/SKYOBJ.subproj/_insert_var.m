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

@interface SkyPubSKYOBJNodeRenderer(InsertVarBody)
- (void)_appendInsertvalueVarBodyNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx;
@end

@implementation SkyPubSKYOBJNodeRenderer(InsertVar)

- (void)_appendInsertvalueVarNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  NSString *name, *format, *formatter, *separator;
  id value;
  
  name = [self stringFor:@"name" node:_node ctx:_ctx];
  if ([name length] == 0) {
    NSLog(@"%s: missing name of insertvalue-var node %@",
          __PRETTY_FUNCTION__, _node);
    return;
  }
  
  if ([name isEqualToString:@"body"]) {
    [self _appendInsertvalueVarBodyNode:_node
          toResponse:_response
          inContext:_ctx];
    return;
  }
  
  format    = [self stringFor:@"format"    node:_node ctx:_ctx];
  formatter = [self stringFor:@"formatter" node:_node ctx:_ctx];
  separator = [self stringFor:@"separator" node:_node ctx:_ctx];
  
  value = [self contextValueWithName:name inContext:_ctx];
  
  if ([value isKindOfClass:[NSArray class]])
    value = [value objectEnumerator];
  
  if ([value isKindOfClass:[NSEnumerator class]]) {
    /* multivalue, use separator */
    id   v;
    BOOL isFirst = YES;

#if DEBUG
    NSLog(@"%s: multivalue result ...", __PRETTY_FUNCTION__);
#endif
    
    while ((v = [value nextObject])) {
      if (isFirst) isFirst = NO;
      else [_response appendContentHTMLString:separator];
      
      v = [v stringValue];
      [_response appendContentHTMLString:v];
    }
  }
  else {
    /* singlevalue */
#if DEBUG && 0
    NSLog(@"%s: singlevalue result '%@' ...", __PRETTY_FUNCTION__, value);
#endif
    value = [value stringValue];
    [_response appendContentHTMLString:value];
  }
}

@end /* SkyPubSKYOBJNodeRenderer(InsertVar) */
