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

#include <NGObjDOM/ODNodeRendererFactory.h>
#include <NGObjDOM/ODNodeRenderer.h>

@interface SkyPubSourceNodeRenderFactory : ODNodeRendererFactory
@end

@interface SkyPubSourceNodeRenderer : ODNodeRenderer

- (void)_appendLinkAttribute:(id)_attr ofNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx;

- (void)_appendAttribute:(id)_attr ofNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx;

@end

@interface SkyPubAnkerSourceNodeRenderer : SkyPubSourceNodeRenderer
@end

@interface SkyPubImgSourceNodeRenderer : SkyPubSourceNodeRenderer
@end

@interface SkyPubSourceTextNodeRenderer : ODNodeRenderer
@end

#include "common.h"
#include "SkyPubInlineViewer.h"
#include "SkyPubLinkManager.h"
#include <OGoDocuments/SkyDocuments.h>
#include <NGObjDOM/ODNamespaces.h>
#include <DOM/EDOM.h>

@interface WOContext(UsedPrivates)
- (NSString *)activationURLForGlobalID:(EOGlobalID *)_gid verb:(NSString *)_v;
@end

@implementation SkyPubSourceNodeRenderFactory

- (ODNodeRenderer *)rendererForTextNode:(id)_domNode 
  inContext:(WOContext *)_ctx
{
  static id r = nil;
  if (r == nil) r = [[SkyPubSourceTextNodeRenderer alloc] init];
  return r;
}

- (ODNodeRenderer *)rendererForElementNode:(id)_domNode
  inContext:(WOContext *)_ctx
{
  static ODNodeRenderer *srcRenderer = nil;
  
  if ([[_domNode namespaceURI] isEqualToString:XMLNS_XHTML] ||
      [[_domNode namespaceURI] isEqualToString:XMLNS_HTML40]) {
    if ([[_domNode tagName] isEqualToString:@"a"]) {
      static ODNodeRenderer *aRenderer = nil;
      
      if (aRenderer == nil)
        aRenderer = [[SkyPubAnkerSourceNodeRenderer alloc] init];
      return aRenderer;
    }
    
    if ([[_domNode tagName] isEqualToString:@"img"]) {
      static ODNodeRenderer *imgRenderer = nil;
      
      if (imgRenderer == nil)
        imgRenderer = [[SkyPubImgSourceNodeRenderer alloc] init];
      return imgRenderer;
    }
  }
  
  if (srcRenderer == nil)
    srcRenderer = [[SkyPubSourceNodeRenderer alloc] init];
  
  return srcRenderer;
}

@end /* SkyPubSourceNodeRenderFactory */

@implementation SkyPubSourceNodeRenderer

- (void)_appendLinkAttribute:(id)_attr ofNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  NSString *key;
  NSString *value;
  NSString *s;
  id       link;
  
  link = [[[_ctx component] linkManager] linkForElementNode:_node];
  
  key   = [_attr name];
  value = [_attr value];
  
  [_response appendContentString:@" "];
  if ((s = [_node prefix])) {
    [_response appendContentString:s];
    [_response appendContentString:@":"];
  }
  [_response appendContentHTMLString:key];
  [_response appendContentString:@"=&quot;"];
  
  if ([link isAbsoluteURL]) {
    [_response appendContentString:@"<a href=\""];
    [_response appendContentString:value];
    [_response appendContentString:@"\"><font color=\"black\">"];
    [_response appendContentHTMLString:value];
    [_response appendContentString:@"</font></a>"];
  }
  else {
    EOGlobalID *tgid;
    
    if ((tgid = [link targetObjectIdentifier])) {
      NSString *url;
      
      //NSLog(@"GID: %@", tgid);
      url = [_ctx activationURLForGlobalID:tgid verb:@"view"];
      
      [_response appendContentString:@"<a href=\""];
      [_response appendContentString:url];

      [_response appendContentString:@"\"><font color=\"black\">"];
      [_response appendContentHTMLString:value];
      [_response appendContentString:@"</font></a>"];
    }
    else
      [_response appendContentHTMLString:value];
  }
  
  [_response appendContentString:@"&quot;"];
}

- (void)_appendAttribute:(id)_attr ofNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  NSString *attrName;
  NSString *np, *ap;
  
  attrName = [_attr name];
  np       = [_node prefix];
  ap       = [_attr prefix];
  
  [_response appendContentString:@" "];
  if (!([np isEqualToString:ap] ||
        (np == nil && ap == nil))) {
    if ([ap length] > 0) {
      [_response appendContentString:ap];
      [_response appendContentString:@":"];
    }
  }
  [_response appendContentHTMLString:attrName];
  [_response appendContentString:@"=&quot;"];
  [_response appendContentHTMLString:[_attr value]];
  [_response appendContentString:@"&quot;"];
}

- (void)_appendAttributesOfNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  NSEnumerator *attrs;
  id       attr;
  id       link;
  NSString *nsuri, *prefix;
  
  prefix = [_node prefix];
  nsuri  = [_node namespaceURI];
  
  if ((attrs = [(NSArray *)[_node attributes] objectEnumerator]) == nil)
    return;
  
  link = [[[_ctx component] linkManager] linkForElementNode:_node];
  
  while ((attr = [attrs nextObject])) {
    if (link) {
      if ([[attr name] isEqualToString:[link linkAttribute]] &&
          [[attr namespaceURI] isEqualToString:
                                 [link linkAttributeNamespace]]) {
        //NSLog(@"link match: %@", link);
        [self _appendLinkAttribute:attr ofNode:_node
              toResponse:_response inContext:_ctx];
      }
      else {
        [self _appendAttribute:attr ofNode:_node
              toResponse:_response inContext:_ctx];
      }
    }
    else {
      [self _appendAttribute:attr ofNode:_node
            toResponse:_response inContext:_ctx];
    }
  }
}

- (NSString *)_colorForNode:(id)_node {
  NSString *nsuri;
  
  if ([[[_node nodeName] uppercaseString] isEqualToString:@"SKYOBJ"])
    return @"red";

  nsuri = [_node namespaceURI];
  
  if ([nsuri isEqualToString:XMLNS_XHTML] ||
      [nsuri isEqualToString:XMLNS_HTML40])
    return @"brown";
  
  if ([nsuri isEqualToString:XMLNS_OD_BIND])
    return @"#666666";
  
  if ([nsuri isEqualToString:XMLNS_MS_OFFICE_OFFICE] ||
      [nsuri isEqualToString:XMLNS_MS_OFFICE_WORD])
    return @"#FF0000";
  
  return @"green";
}

- (void)appendNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  NSString *prefix;
  
  [_response appendContentString:@"<font color=\""];
  [_response appendContentString:[self _colorForNode:_node]];
  [_response appendContentString:@"\">&lt;"];

  prefix = [_node prefix];
  
  if ([prefix length] > 0) {
    [_response appendContentString:prefix];
    [_response appendContentString:@":"];
  }
  [_response appendContentHTMLString:[_node tagName]];
  
  [self _appendAttributesOfNode:_node
        toResponse:_response
        inContext:_ctx];
  
  if (![_node hasChildNodes]) {
    [_response appendContentString:@"/&gt;</font>"];
  }
  else {
    [_response appendContentString:@"&gt;</font>"];
    
    /* append child elements */
    [super appendNode:(id)_node
           toResponse:_response
           inContext:_ctx];
    
    [_response appendContentString:@"<font color=\""];
    [_response appendContentString:[self _colorForNode:_node]];
    [_response appendContentString:@"\">&lt;/"];
    if ([prefix length] > 0) {
      [_response appendContentString:prefix];
      [_response appendContentString:@":"];
    }
    [_response appendContentHTMLString:[_node tagName]];
    [_response appendContentString:@"&gt;</font>"];
  }
}

@end /* SkyPubSourceNodeRenderer */

@implementation SkyPubSourceTextNodeRenderer

- (void)appendNode:(id)_domNode
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_context
{
  NSString *txt;
  
  txt = [_domNode textValue];
#if LIB_FOUNDATION_LIBRARY
  txt = [txt stringByReplacingString:@"\r" withString:@""];
#else
#  warning FIXME: incorrect implementation for this Foundation library!
#endif
  
  [_response appendContentHTMLString:txt];
  
  if ([_domNode hasChildNodes]) {
    [super appendChildNodes:[_domNode childNodes]
           toResponse:_response inContext:_context];
  }
}

@end /* SkyPubSourceTextNodeRenderer */

@implementation SkyPubAnkerSourceNodeRenderer

@end /* SkyPubAnkerSourceNodeRenderer */

@implementation SkyPubImgSourceNodeRenderer

@end /* SkyPubImgSourceNodeRenderer */
