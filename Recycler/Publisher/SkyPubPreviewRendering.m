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

@interface SkyPubPreviewNodeRenderFactory : ODNodeRendererFactory
@end

@interface SkyPubHTMLPreviewNodeRenderer : ODNodeRenderer

- (void)_appendLinkAttribute:(id)_attr ofNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx;

- (void)_appendAttributesOfNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx;

@end

@interface SkyPubAnkerPreviewNodeRenderer : SkyPubHTMLPreviewNodeRenderer
@end

@interface SkyPubInputPreviewNodeRenderer : SkyPubHTMLPreviewNodeRenderer
@end

@interface SkyPubImgPreviewNodeRenderer : SkyPubHTMLPreviewNodeRenderer
@end

@interface SkyPubLinkPreviewNodeRenderer : SkyPubHTMLPreviewNodeRenderer
@end

@interface SkyPubSSIPreviewNodeRenderer : SkyPubHTMLPreviewNodeRenderer
@end

@interface SkyPubScriptPreviewNodeRenderer : SkyPubHTMLPreviewNodeRenderer
@end

@interface SkyPubNoTagPreviewNodeRenderer : SkyPubHTMLPreviewNodeRenderer
@end

@interface SkyPubPreviewTextNodeRenderer : ODNodeRenderer
@end

#include "common.h"
#include "SkyPubInlineViewer.h"
#include "SkyPubLinkManager.h"
#include "SkyPubLink+Activation.h"
#include <OGoDocuments/SkyDocuments.h>
#include <NGObjDOM/ODNamespaces.h>
#include <DOM/EDOM.h>

@implementation SkyPubPreviewNodeRenderFactory

static SkyPubPreviewNodeRenderFactory *singleton = nil;

- (id)init {
  if (singleton) {
    RELEASE(self);
    return RETAIN(singleton);
  }
  self = [super init];
  singleton = RETAIN(self);
  return self;
}

- (ODNodeRenderer *)rendererForTextNode:(id)_domNode 
  inContext:(WOContext *)_ctx
{
  static id r = nil;
  if (r == nil) r = [[SkyPubPreviewTextNodeRenderer alloc] init];
  return r;
}

- (ODNodeRenderer *)rendererForElementNode:(id)_domNode
  inContext:(WOContext *)_ctx
{
  NSString *tag;

  tag = [_domNode tagName];
  
  if ([[tag uppercaseString] isEqualToString:@"SKYOBJ"]) {
    static ODNodeRenderer *npsRenderer = nil;
    
    if (npsRenderer == nil)
      npsRenderer = [[NSClassFromString(@"SkyPubSKYOBJPreviewNodeRenderer")
                                       alloc] init];
    return npsRenderer;
  }
  
  if ([[_domNode namespaceURI] isEqualToString:XMLNS_XHTML] ||
      [[_domNode namespaceURI] isEqualToString:XMLNS_HTML40]) {
    static ODNodeRenderer *xhtmlRenderer = nil;
    
    if ([tag isEqualToString:@"ssi"]) {
      static ODNodeRenderer *aRenderer = nil;
      
      if (aRenderer == nil)
        aRenderer = [[SkyPubSSIPreviewNodeRenderer alloc] init];
      return aRenderer;
    }
    if ([tag isEqualToString:@"a"]) {
      static ODNodeRenderer *aRenderer = nil;
    
      if (aRenderer == nil)
        aRenderer = [[SkyPubAnkerPreviewNodeRenderer alloc] init];
      return aRenderer;
    }
    if ([tag isEqualToString:@"link"]) {
      static ODNodeRenderer *aRenderer = nil;
    
      if (aRenderer == nil)
        aRenderer = [[SkyPubLinkPreviewNodeRenderer alloc] init];
      return aRenderer;
    }
    if ([tag isEqualToString:@"img"]) {
      static ODNodeRenderer *imgRenderer = nil;

      if (imgRenderer == nil)
        imgRenderer = [[SkyPubImgPreviewNodeRenderer alloc] init];
      return imgRenderer;
    }
    if ([tag isEqualToString:@"input"]) {
      static ODNodeRenderer *imgRenderer = nil;

      if (imgRenderer == nil)
        imgRenderer = [[SkyPubInputPreviewNodeRenderer alloc] init];
      return imgRenderer;
    }
    if ([tag isEqualToString:@"script"]) {
      static ODNodeRenderer *imgRenderer = nil;

      if (imgRenderer == nil)
        imgRenderer = [[SkyPubScriptPreviewNodeRenderer alloc] init];
      return imgRenderer;
    }
    
    if (xhtmlRenderer == nil)
      xhtmlRenderer = [[SkyPubHTMLPreviewNodeRenderer alloc] init];
    
    return xhtmlRenderer;
  }
  else if ([[_domNode namespaceURI] isEqualToString:XMLNS_OD_BIND]) {
    static ODNodeRendererFactory *factory = nil;
    id tmp;
    
    if (factory == nil)
      factory = [[NSClassFromString(@"ODBindNodeRenderFactory") alloc] init];
    
    if ((tmp = [factory rendererForNode:_domNode inContext:_ctx]))
      return tmp;
  }
  
  {
    /* not an HTML element ... */
    static ODNodeRenderer *miscRenderer = nil;

    if (miscRenderer == nil) {
      miscRenderer =
        [[NSClassFromString(@"SkyPubSourceNodeRenderer") alloc] init];
    }
    
    return miscRenderer;
  }
}

@end /* SkyPubPreviewNodeRenderFactory */

@implementation SkyPubPreviewTextNodeRenderer

- (void)appendNode:(id)_domNode
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_context
{
  NSString *txt;
  
  txt = [_domNode textValue];

#if DEBUG
  if ([txt fastestEncoding] != NSISOLatin1StringEncoding) {
    NSLog(@"add non-latin1 text(enc=%i) '%@'", [txt fastestEncoding], txt);
  }
#endif
#if 0
  NSLog(@"add text(enc=%i) '%@'", [txt fastestEncoding], txt);
#endif
#if LIB_FOUNDATION_LIBRARY
  txt = [txt stringByReplacingString:@"\r" withString:@""];
#else
#  warning FIXME: incorrect implementation for this Foundation library!
#endif
  
  [_response appendContentHTMLString:txt];
  
  if ([_domNode hasChildNodes])
    [super appendNode:_domNode toResponse:_response inContext:_context];
}

@end /* SkyPubPreviewTextNodeRenderer */

@implementation SkyPubHTMLPreviewNodeRenderer

- (void)_appendLinkAttribute:(id)_attr ofNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  NSString *key;
  NSString *value;
  id       link;
  
  link = [[[_ctx component] linkManager] linkForElementNode:_node];
  
  key   = [_attr name];
  value = [self stringFor:key node:_node ctx:_ctx];
  
  /* transform link */
  
  if ([key isEqualToString:@"background"])
    value = [link downloadUrlInContext:_ctx];
  else
    value = [link skyrixUrlInContext:_ctx];
  
  /* gen attribute */
  
  [_response appendContentString:@" "];
  [_response appendContentHTMLString:key];
  [_response appendContentString:@"=\""];
  [_response appendContentString:value];
  [_response appendContentString:@"\""];
}

- (void)_appendAttributesOfNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  id attrs;
  id attr;
  id link;

  if ((attrs = [(NSArray *)[_node attributes] objectEnumerator]) == nil)
    /* no attributes ... */
    return;
  
  link = [[[_ctx component] linkManager] linkForElementNode:_node];
  
  while ((attr = [attrs nextObject])) {
    NSString *attrName;

    attrName = [[attr name] lowercaseString];

    if ([attrName hasPrefix:@"on"]) {
      /* filter out JavaScript attributes ... */
      continue;
    }
    
    if (link) {
      if ([attrName isEqualToString:[link linkAttribute]] &&
          [[attr namespaceURI] isEqualToString:
                                 [link linkAttributeNamespace]]) {
        //NSLog(@"link match: %@", link);
        if ([link isValid]) {
          [self _appendLinkAttribute:attr ofNode:_node
                toResponse:_response inContext:_ctx];
        }
        else {
          [_response appendContentString:@" invalidlink=\""];
          [_response appendContentHTMLAttributeValue:attrName];
          [_response appendContentString:@"="];
          [_response appendContentHTMLAttributeValue:[link linkValue]];
          [_response appendContentString:@" \""];
        }
        continue;
      }
    }
    [_response appendContentString:@" "];
    [_response appendContentString:attrName];
    [_response appendContentString:@"=\""];
    [_response appendContentHTMLAttributeValue:
                 [self stringFor:attrName node:_node ctx:_ctx]];
    [_response appendContentString:@"\""];
  }
}

- (BOOL)isHiddenHTMLTag:(NSString *)_tag inContext:(WOContext *)_ctx {
  if ([_tag length] > 3) {
    if ([_tag isEqualToString:@"html"]) return YES;
    if ([_tag isEqualToString:@"body"]) return YES;
    if ([_tag isEqualToString:@"head"]) return YES;
    if ([_tag isEqualToString:@"meta"]) return YES;
    if ([_tag isEqualToString:@"title"]) return YES;
    if ([_tag isEqualToString:@"base"]) return YES;
    if ([_tag isEqualToString:@"link"]) return YES;
  }
  return NO;
}

- (void)appendNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  NSString *tagName;
  
  tagName = [_node tagName];
  
  if ([self isHiddenHTMLTag:tagName inContext:_ctx])
    tagName = nil;
  
  if (tagName) {
    [_response appendContentString:@"<"];
    [_response appendContentString:tagName];
    [self _appendAttributesOfNode:_node toResponse:_response inContext:_ctx];
  }
  
  if ([_node hasChildNodes]) {
    if (tagName)
      [_response appendContentString:@">"];
    
    /* append child elements */
    [super appendNode:(id)_node
           toResponse:_response
           inContext:_ctx];

    if (tagName) {
      [_response appendContentString:@"</"];
      [_response appendContentString:tagName];
      [_response appendContentString:@">"];
    }
  }
  else {
    if (tagName) [_response appendContentString:@" />"];
  }
}

@end /* SkyPubHTMLPreviewNodeRenderer */

@implementation SkyPubAnkerPreviewNodeRenderer

@end /* SkyPubAnkerPreviewNodeRenderer */

@implementation SkyPubImgPreviewNodeRenderer

- (void)appendNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  id link;
  
  if ((link = [[[_ctx component] linkManager] linkForElementNode:_node])){
    NSString *downloadURL;
    NSString *alt;
    
    alt = nil;
    
    downloadURL = [link downloadUrlInContext:_ctx];
    
    if ([link isAbsoluteURL])
      alt = downloadURL;
    
    if ([link isValid]) {
      [_response appendContentString:@"<a href=\""];
      [_response appendContentString:[link skyrixUrlInContext:_ctx]];
      [_response appendContentString:@"\">"];
    
      [_response appendContentString:@"<img src=\""];
      [_response appendContentString:downloadURL];
      if ([alt length] > 0) {
        [_response appendContentString:@"\" alt=\""];
        [_response appendContentString:alt];
      }
      [_response appendContentString:@"\" border='0' />"];
    
      [_response appendContentString:@"</a>"];
    }
    else {
      [_response appendContentHTMLString:@"[img tag with invalid src="];
      [_response appendContentHTMLString:[link linkValue]];
      [_response appendContentHTMLString:@"]"];
    }
  }
  else {
    [_response appendContentHTMLString:@"[img tag without link ??]"];
  }
}

@end /* SkyPubImgPreviewNodeRenderer */

@implementation SkyPubInputPreviewNodeRenderer

- (void)appendNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  id link;
  
  if ((link = [[[_ctx component] linkManager] linkForElementNode:_node])){
    NSString *downloadURL;
    NSString *alt;
    
    alt = nil;
    
    downloadURL = [link downloadUrlInContext:_ctx];
    
    if ([link isAbsoluteURL])
      alt = downloadURL;
    
    if ([link isValid]) {
      [_response appendContentString:@"<a href=\""];
      [_response appendContentString:[link skyrixUrlInContext:_ctx]];
      [_response appendContentString:@"\">"];
      
      [_response appendContentString:@"<img src=\""];
      [_response appendContentString:downloadURL];
      if ([alt length] > 0) {
        [_response appendContentString:@"\" alt=\""];
        [_response appendContentString:alt];
      }
      [_response appendContentString:@"\" border='0' />"];
      
      [_response appendContentString:@"</a>"];
    }
    else {
      [_response appendContentHTMLString:@"[input tag with invalid src="];
      [_response appendContentHTMLString:[link linkValue]];
      [_response appendContentHTMLString:@"]"];
    }
  }
  else {
    [super appendNode:_node toResponse:_response inContext:_ctx];
  }
}

@end /* SkyPubInputPreviewNodeRenderer */

@implementation SkyPubLinkPreviewNodeRenderer

- (void)appendNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  [_response appendContentHTMLString:@"[HTML link tag]"];
  
  if ([_node hasChildNodes])
    [_response appendContentHTMLString:@" WARNING: link has child-nodes !"];
}

@end /* SkyPubLinkPreviewNodeRenderer */

@implementation SkyPubSSIPreviewNodeRenderer

- (void)appendNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  NSString     *element;
  NSEnumerator *attrs;
  id           attr;
  
  element = [_node attribute:@"element"];
  if ([element length] == 0) {
    [_response appendContentHTMLString:@"<!-- missing name of SSI -->"];
    return;
  }

  [_response appendContentHTMLString:@"<!--#"];
  [_response appendContentHTMLString:element];
  
  /* attributes */
  attrs = [(NSArray *)[_node attributes] objectEnumerator];
  while ((attr = [attrs nextObject])) {
    NSString *attrName;
        
    if ((attrName = [attr name]) == nil)       continue;
    if ([attrName isEqualToString:@"element"]) continue;
    
    [_response appendContentHTMLString:@" "];
    [_response appendContentHTMLString:attrName];
    [_response appendContentHTMLString:@"=\""];
    [_response appendContentHTMLAttributeValue:
                 [self stringFor:attrName node:_node ctx:_ctx]];
    [_response appendContentHTMLString:@"\""];
  }
  
  [_response appendContentHTMLString:@" -->"];
}

@end /* SkyPubSSIPreviewNodeRenderer */

@implementation SkyPubNoTagPreviewNodeRenderer

- (void)appendNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  /* append child elements */
  if ([_node hasChildNodes]) {
    [super appendNode:(id)_node
           toResponse:_response
           inContext:_ctx];
  }
}

@end /* SkyPubNoTagPreviewNodeRenderer */

@implementation SkyPubScriptPreviewNodeRenderer

- (void)appendNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  /*
    WARNING: HTML browser do not understand <script /> !!! Script tags always
    need to be closed !!!
  */
  
  if ([[self valueFor:@"runat" node:_node ctx:_ctx] isEqual:@"server"]) {
    /* server side JavaScript */
    return;
  }
  
  [_response appendContentHTMLString:@"<script"];
  [self _appendAttributesOfNode:_node toResponse:_response inContext:_ctx];
  [_response appendContentHTMLString:@">"];
  
  /* append child elements */
  if ([_node hasChildNodes]) {
    [_response appendContentHTMLString:@"<!-- hide\n"];
    
    [self appendChildNodes:[_node childNodes]
          toResponse:_response
          inContext:_ctx];
    
    [_response appendContentHTMLString:@" // -->"];
  }
  
  /* always close tag */
  [_response appendContentHTMLString:@"</script>"];
}

@end /* SkyPubScriptPreviewNodeRenderer */
