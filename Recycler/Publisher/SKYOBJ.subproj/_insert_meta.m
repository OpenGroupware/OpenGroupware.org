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
#include "common.h"
#include <DOM/EDOM.h>

@implementation SkyPubSKYOBJNodeRenderer(InsertMeta)

- (void)_appendInsertvalueMetaNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  NSString *metaName;
  NSString *key, *format, *formatter, *separator;
  id       value;
  
  metaName = [self stringFor:@"name" node:_node ctx:_ctx];
  if ([metaName length] == 0) {
    NSLog(@"%s: missing <meta> name !", __PRETTY_FUNCTION__);
    return;
  }
  
  key = [self stringFor:@"content" node:_node ctx:_ctx];
  if ([key length] > 0) {
    format    = [self stringFor:@"format"    node:_node ctx:_ctx];
    formatter = [self stringFor:@"formatter" node:_node ctx:_ctx];
    separator = [self stringFor:@"separator" node:_node ctx:_ctx];
  
    value = [self contextValueWithName:key inContext:_ctx];
  }
  else {
#if DEBUG && 0
    NSLog(@"%s: missing value for <meta name=%@>", __PRETTY_FUNCTION__,
          metaName);
#endif
    value = @"";
  }
  
  [_response appendContentString:@"<meta name=\""];
  [_response appendContentHTMLAttributeValue:metaName];
  [_response appendContentString:@"\" content=\""];

  if ([value isKindOfClass:[NSArray class]])
    value = [value objectEnumerator];
  
  if ([value isKindOfClass:[NSEnumerator class]]) {
    /* multivalue, use separator */
    id   v;
    BOOL isFirst = YES;
    
    while ((v = [value nextObject])) {
      if (isFirst) isFirst = NO;
      else [_response appendContentHTMLAttributeValue:separator];
      
      v = [v stringValue];
      [_response appendContentHTMLAttributeValue:v];
    }
  }
  else {
    /* singlevalue */
    value = [value stringValue];
    [_response appendContentHTMLAttributeValue:value];
  }
  
  [_response appendContentString:@"\" />"];
}

@end /* SkyPubSKYOBJNodeRenderer(InsertMeta) */
