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

#include "SkyPubPreviewSKYOBJ.h"
#include "common.h"
#include "SkyPubInlineViewer.h"
#include "SkyPubLinkManager.h"
#include "PubKeyValueCoding.h"
#include <OGoDocuments/SkyDocuments.h>
#include <NGObjDOM/ODNamespaces.h>
#include <DOM/EDOM.h>

@interface SkyPubSKYOBJPreviewNodeRenderer(Template)
- (void)_appendInsertvalueTemplateNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx;
@end

@interface SkyPubSKYOBJPreviewNodeRenderer(_list)
- (void)_appendListNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx;
@end

@interface SkyPubSKYOBJPreviewNodeRenderer(_condition)
- (void)_appendConditionNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx;
@end

@interface SkyPubSKYOBJPreviewNodeRenderer(InsertAnchor)
- (void)_appendInsertvalueAnchorNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx;
- (void)_appendInsertvalueImageNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx;
@end

@interface DOMElement(SKYNodeName)
- (NSString *)npsNodeType;
@end

@implementation SkyPubSKYOBJPreviewNodeRenderer

- (void)_appendInsertvalueVarNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  NSString *name, *format, *formatter, *separator;
  id value;
  
  name      = [_node attribute:@"name"];
  format    = [_node attribute:@"format"];
  formatter = [_node attribute:@"formatter"];
  separator = [_node attribute:@"separator"];
  
  if ((value = [self contextValueWithName:name inContext:_ctx]) == nil) {
#if 0
    NSLog(@"%s: no value for var-node on key '%@' ...",
          __PRETTY_FUNCTION__, name);
#endif
    value = @"";
  }
#if 0
  NSLog(@"%s: got value '%@' for key '%@'",
        __PRETTY_FUNCTION__, value, name);
#endif
  
  if ([value isKindOfClass:[NSArray class]])
    value = [value objectEnumerator];
  
  if ([value isKindOfClass:[NSEnumerator class]]) {
    /* multivalue, use separator */
    id   v;
    BOOL isFirst = YES;
    
    while ((v = [value nextObject])) {
      if (isFirst) isFirst = NO;
      else [_response appendContentHTMLString:separator];
      
      v = [v stringValue];
      [_response appendContentHTMLString:v];
    }
  }
  else {
    /* singlevalue */
    value = [self npsStringifyValue:value inContext:_ctx];
    [_response appendContentHTMLString:value];
  }
  
  if ([_node hasChildNodes]) {
    [_response appendContentHTMLString:
                 @"[ERROR: <SKYOBJ insertvalue='var'> has child nodes !]"];
  }
}

- (void)_appendInsertvalueNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  NSString *insertType;
  
  insertType = [_node attribute:@"insertvalue"];
  
  if ([insertType isEqualToString:@"var"]) {
    [self _appendInsertvalueVarNode:_node toResponse:_response inContext:_ctx];
  }
  else if ([insertType isEqualToString:@"template"]) {
    [self _appendInsertvalueTemplateNode:_node
          toResponse:_response inContext:_ctx];
  }
  else if ([insertType isEqualToString:@"anchor"]) {
    [self _appendInsertvalueAnchorNode:_node
          toResponse:_response inContext:_ctx];
  }
  else if ([insertType isEqualToString:@"image"]) {
    [self _appendInsertvalueImageNode:_node
          toResponse:_response inContext:_ctx];
  }
  else
    [self addUnsupportedNode:_node toResponse:_response inContext:_ctx];
}

- (void)_appendFrameNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  [self addUnsupportedNode:_node toResponse:_response inContext:_ctx];
}
- (void)_appendIncludetextNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  [self addUnsupportedNode:_node toResponse:_response inContext:_ctx];
}


- (void)_appendMakeanchorNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  [self addUnsupportedNode:_node toResponse:_response inContext:_ctx];
}
- (void)_appendMicronavigationNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  [self addUnsupportedNode:_node toResponse:_response inContext:_ctx];
}
- (void)_appendTableNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  [self addUnsupportedNode:_node toResponse:_response inContext:_ctx];
}
- (void)_appendToclistsortedbyNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  [self addUnsupportedNode:_node toResponse:_response inContext:_ctx];
}
- (void)_appendToctablesortedbyNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  [self addUnsupportedNode:_node toResponse:_response inContext:_ctx];
}

- (NSException *)handleException:(NSException *)_exception
  duringGenerationOfResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  NSLog(@"%s: catched exception: %@", __PRETTY_FUNCTION__, _exception);
  
  if (_response) {
    [_response appendContentString:
                 @"<font color=\"red\">Exception:</font><br/><pre>"];
    [_response appendContentString:@"Name:     "];
    [_response appendContentHTMLString:[_exception name]];
    [_response appendContentString:@"<br/>"];
    [_response appendContentString:@"Reason:   "];
    [_response appendContentHTMLString:[_exception reason]];
    [_response appendContentString:@"<br/>"];
    [_response appendContentString:@"InfoDict:\n"];
    [_response appendContentHTMLString:[[_exception userInfo] stringValue]];
    [_response appendContentString:@"</pre><br/>"];
  }
  
  return nil;
}

- (void)appendNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  NSString *nodeType;
  
  nodeType = [_node npsNodeType];

  NS_DURING {
    if ([nodeType isEqualToString:@"condition"])
      [self _appendConditionNode:_node toResponse:_response inContext:_ctx];
    else if ([nodeType isEqualToString:@"frame"])
      [self _appendFrameNode:_node toResponse:_response inContext:_ctx];
    else if ([nodeType isEqualToString:@"includetext"])
      [self _appendIncludetextNode:_node toResponse:_response inContext:_ctx];
    else if ([nodeType isEqualToString:@"insertvalue"])
      [self _appendInsertvalueNode:_node toResponse:_response inContext:_ctx];
    else if ([nodeType isEqualToString:@"list"])
      [self _appendListNode:_node toResponse:_response inContext:_ctx];
    else if ([nodeType isEqualToString:@"makeanchor"])
      [self _appendMakeanchorNode:_node toResponse:_response inContext:_ctx];
    else if ([nodeType isEqualToString:@"micronavigation"]) {
      [self _appendMicronavigationNode:_node
            toResponse:_response inContext:_ctx];
    }
    else if ([nodeType isEqualToString:@"table"])
      [self _appendTableNode:_node toResponse:_response inContext:_ctx];
    else if ([nodeType isEqualToString:@"toclistsortedby"]) {
      [self _appendToclistsortedbyNode:_node
            toResponse:_response inContext:_ctx];
    }
    else if ([nodeType isEqualToString:@"toctablesortedby"]) {
      [self _appendToctablesortedbyNode:_node
            toResponse:_response inContext:_ctx];
    }
    else {
      NSLog(@"%s: invalid SKYOBJ tag: %@ !", __PRETTY_FUNCTION__, _node);
      [_response appendContentString:@"[INVALID SKYOBJ tag, type: "];
      [_response appendContentString:nodeType];
      [_response appendContentString:@"]"];
    }
  }
  NS_HANDLER {
    [[self handleException:localException
           duringGenerationOfResponse:_response
           inContext:_ctx]
           raise];
  }
  NS_ENDHANDLER;
}

@end /* SkyPubSKYOBJPreviewNodeRenderer */
