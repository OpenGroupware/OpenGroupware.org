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

#include <NGObjDOM/ODNodeRendererFactory.h>
#include <NGObjDOM/ODNodeRenderer.h>

/*
  'Live' Rendering of SkyPublisher Tags.

  Links are mapped from template space to document space.
  
  Special Tags:

    <SKYOBJ ...>

    <entity name="lt"/>
    => &lt;
    
    <ssi element="blah" attributes.../>
    => <!--#blah ....-->

    <comment>ksajfkljadsf</comment>
    => <!-- ksajfkljadsf --->
*/

@interface SkyPubNodeRenderFactory : ODNodeRendererFactory
@end

@interface SkyPubHTMLNodeRenderer : ODNodeRenderer

- (void)_appendLinkAttribute:(id)_attr ofNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx;

- (void)_appendAttributesOfNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx;

- (BOOL)isValidLink:(id)_object inContext:(WOContext *)_ctx;
- (NSString *)valueForLink:(id)_target inContext:(WOContext *)_ctx;
- (NSString *)targetTitleForLink:(id)_target inContext:(WOContext *)_ctx;

- (void)reportBrokenLink:(NSString *)_link
  inNode:(id)_node ctx:(WOContext *)_ctx;

@end

@interface SkyPubAnkerNodeRenderer : SkyPubHTMLNodeRenderer
@end

@interface SkyPubImgNodeRenderer : SkyPubHTMLNodeRenderer
@end

@interface SkyPubScriptNodeRenderer : SkyPubHTMLNodeRenderer
@end

@interface SkyPubTextAreaNodeRenderer : SkyPubHTMLNodeRenderer
@end

@interface SkyPubSSINodeRenderer : SkyPubHTMLNodeRenderer
@end

@interface SkyPubEntityNodeRenderer : SkyPubHTMLNodeRenderer
@end

@interface SkyPubCommentNodeRenderer : SkyPubHTMLNodeRenderer
@end

@interface SkyPubTextNodeRenderer : ODNodeRenderer
@end

#include "common.h"
#include "SkyPubInlineViewer.h"
#include "SkyPubComponent.h"
#include "SkyDocument+Pub.h"
#include "DOMNode+Pub.h"
#include <OGoDocuments/SkyDocuments.h>
#include <NGObjDOM/ODNamespaces.h>
#include <DOM/EDOM.h>

@implementation SkyPubNodeRenderFactory

static BOOL debugLinkChecker      = NO;
static BOOL outputInvalidLinkInfo = YES;
static BOOL coreOnInvalidLink     = NO;
static SkyPubNodeRenderFactory *singleton = nil;

- (id)init {
  if (singleton) {
    [self release];
    return [singleton retain];
  }
  self = [super init];
  singleton = [self retain];
  return self;
}

- (ODNodeRenderer *)rendererForTextNode:(id)_domNode 
  inContext:(WOContext *)_ctx
{
  static id r = nil;
  if (r == nil) r = [[SkyPubTextNodeRenderer alloc] init];
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
      npsRenderer = [[NGClassFromString(@"SkyPubSKYOBJNodeRenderer")
                                       alloc] init];
    return npsRenderer;
  }
  
  if ([[_domNode namespaceURI] isEqualToString:XMLNS_XHTML] ||
      [[_domNode namespaceURI] isEqualToString:XMLNS_HTML40]) {
    static ODNodeRenderer *xhtmlRenderer = nil;
    
    if ([tag isEqualToString:@"ssi"]) {
      static ODNodeRenderer *aRenderer = nil;
      
      if (aRenderer == nil)
        aRenderer = [[SkyPubSSINodeRenderer alloc] init];
      return aRenderer;
    }
    if ([tag isEqualToString:@"a"]) {
      static ODNodeRenderer *aRenderer = nil;
      
      if (aRenderer == nil)
        aRenderer = [[SkyPubAnkerNodeRenderer alloc] init];
      return aRenderer;
    }
    if ([tag isEqualToString:@"script"]) {
      static ODNodeRenderer *aRenderer = nil;
      
      if (aRenderer == nil)
        aRenderer = [[SkyPubScriptNodeRenderer alloc] init];
      return aRenderer;
    }
    if ([tag isEqualToString:@"textarea"]) {
      static ODNodeRenderer *aRenderer = nil;
      
      if (aRenderer == nil)
        aRenderer = [[SkyPubTextAreaNodeRenderer alloc] init];
      return aRenderer;
    }
    if ([tag isEqualToString:@"img"]) {
      static ODNodeRenderer *imgRenderer = nil;

      if (imgRenderer == nil)
        imgRenderer = [[SkyPubImgNodeRenderer alloc] init];
      return imgRenderer;
    }
    if ([tag isEqualToString:@"entity"]) {
      static ODNodeRenderer *eRenderer = nil;
      
      if (eRenderer == nil)
        eRenderer = [[SkyPubEntityNodeRenderer alloc] init];
      return eRenderer;
    }
    if ([tag isEqualToString:@"comment"]) {
      static ODNodeRenderer *cRenderer = nil;
      
      if (cRenderer == nil)
        cRenderer = [[SkyPubCommentNodeRenderer alloc] init];
      return cRenderer;
    }
    
    if (xhtmlRenderer == nil)
      xhtmlRenderer = [[SkyPubHTMLNodeRenderer alloc] init];
    
    return xhtmlRenderer;
  }
  else if ([[_domNode namespaceURI] isEqualToString:XMLNS_OD_BIND]) {
    static ODNodeRendererFactory *factory = nil;
    id tmp;
    
    if (factory == nil)
      factory = [[NGClassFromString(@"ODBindNodeRenderFactory") alloc] init];
    
    if ((tmp = [factory rendererForNode:_domNode inContext:_ctx]))
      return tmp;
  }
  
  {
    /* not an HTML element ... */
    static ODNodeRenderer *miscRenderer = nil;

    if (miscRenderer == nil) {
      miscRenderer =
        [[NGClassFromString(@"SkyPubSourceNodeRenderer") alloc] init];
    }
    
    return miscRenderer;
  }
}

@end /* SkyPubNodeRenderFactory */

@implementation SkyPubTextNodeRenderer

- (void)appendNode:(id)_domNode
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_context
{
  NSString *txt;
  
  txt = [_domNode textValue];
#if LIB_FOUNDATION_LIBRARY
  txt = [txt stringByReplacingString:@"\r" withString:@""];
#else
#  warning FIXME: incorrect implementation on this Foundation library!
#endif

  if ([[[_domNode parentNode] nodeName] isEqualToString:@"script"])
    [_response appendContentString:txt];
  else
    [_response appendContentHTMLString:txt];
  
  if ([_domNode hasChildNodes]) {
    [self appendChildNodes:[_domNode childNodes]
          toResponse:_response
          inContext:_context];
  }
}

@end /* SkyPubTextNodeRenderer */

@implementation SkyPubHTMLNodeRenderer

- (SkyDocument *)targetDocForLink:(id)_object inContext:(WOContext *)_ctx {
  SkyDocument *doc;

  doc = nil;
  if ([_object isKindOfClass:[SkyDocument class]])
    doc = _object;
  else if ([_object isKindOfClass:[EOGlobalID class]]) {
    doc = nil;
    NSLog(@"WARNING(%s): can't handle global IDs yet ...",
          __PRETTY_FUNCTION__);
    return nil;
  }
  else {
    NSString *url;
    
    url = [_object stringValue];
    if ([url isAbsoluteURL]) return nil;
    if ([url length] == 0)   return nil;

    /* use *real* document, as links are based on templates
       not on the content */
    doc = [(SkyPubComponent *)[_ctx component] componentDocument];
    
    /* load target */
    doc = [doc pubDocumentAtPath:url];
  }
  
  return doc;
}

- (BOOL)isValidLink:(id)_object inContext:(WOContext *)_ctx {
  SkyDocument *document;
  NSString    *url;
  
  if (debugLinkChecker)
    [self logWithFormat:@"IsValidLink: %@", _object];
  
  if ([_object isKindOfClass:[SkyDocument class]])
    url = [_object valueForKey:@"NSFilePath"];
  else if ([_object isKindOfClass:[EOGlobalID class]]) {
    NSLog(@"WARNING(%s): can't handle global IDs yet ...",
          __PRETTY_FUNCTION__);
    return NO;
  }
  else
    url = [_object stringValue];

  if (debugLinkChecker)
    [self logWithFormat:@"  URL: %@", url];
  
  if ([url length] == 0)   return NO;
  if ([url isAbsoluteURL]) return YES;
  
  /* use *real* document, as links are based on templates not on the content */
  document = [(SkyPubComponent *)[_ctx component] componentDocument];
  if (document == nil) {
    /* missing doc, can't be valid ... */
#if DEBUG
    NSLog(@"%s: missing document of component %@",
          __PRETTY_FUNCTION__, [_ctx component]);
#endif
    return NO;
  }
  
  if (debugLinkChecker)
    [self logWithFormat:@"  document check link: %@", document];
  return [document pubIsValidLink:url];
}

- (NSString *)targetTitleForLink:(id)_target inContext:(WOContext *)_ctx {
  id doc = nil;
  
  if ((doc = [self targetDocForLink:_target inContext:_ctx]) == nil)
    return nil;
  
  return [doc valueForKey:@"NSFileSubject"];
}

- (NSString *)valueForLink:(id)_target inContext:(WOContext *)_ctx {
  WOContext   *actx;
  WOSession   *sn;
  SkyDocument *srcdoc, *targetdoc;
  NSString    *absurl, *relurl;
  NSString    *url;

  sn = nil;

  /* check application context, since during pubPreview a different context is
     used */
  
  if ((actx = [[WOApplication application] context])) {
    if (actx != _ctx) {
      if ([_ctx hasSession])
        sn = [_ctx session];
      else
        sn = [actx hasSession] ? [actx session] : nil;
    }
    else
      sn = [_ctx hasSession] ? [_ctx session] : nil;
  }
  else
    sn = [_ctx hasSession] ? [_ctx session] : nil;
  
  if ([_target isKindOfClass:[SkyDocument class]]) {
    url = [_target valueForKey:@"NSFilePath"];
  }
  else if ([_target isKindOfClass:[EOGlobalID class]]) {
    NSLog(@"WARNING(%s): can't handle global IDs yet ...",
          __PRETTY_FUNCTION__);
    return NO;
  }
  else
    url = [_target stringValue];
  
  if ([url length] == 0)    return nil;
  if ([url isAbsoluteURL])  return url;
  if ([url hasPrefix:@"#"]) return url;
  
  /* use *real* document, as links are based on templates not on the content */
  srcdoc = [(SkyPubComponent *)[_ctx component] componentDocument];
  if (srcdoc == nil)
    /* missing doc, can't be valid ... */
    return nil;
  
  /* make link absolute */
  if ((absurl = [srcdoc pubAbsoluteTargetPathForLink:url]) == nil)
    return nil;
  
  /* get the document we need to link relative to ... */
  targetdoc = [(SkyPubComponent *)[_ctx component] document];
  
  /* now create the link relative to delivered content !!! */
  relurl = [targetdoc pubRelativeTargetPathForLink:absurl];
  
  if ([relurl length] == 0) {
    NSLog(@"WARNING(%s): got empty relative link: abs '%@' relative to %@",
          __PRETTY_FUNCTION__, absurl, targetdoc);
    relurl = nil;
  }
  
  if (sn) {
    relurl = [relurl stringByAppendingFormat:@"%@%@=%@",
                       ([relurl rangeOfString:@"?"].length == 0
                        ? @"?"
                        : @"&"),
                       WORequestValueSessionID,
                       [sn sessionID]];
#if 0
    NSLog(@"session active, url: %@ ...", relurl);
#endif
  }
#if 0
  else {
    NSLog(@"no session active ...");
  }
#endif
  
  return relurl;
}

- (void)reportBrokenLink:(id)_link
  inNode:(id)_node ctx:(WOContext *)_ctx
{
  static int showBrokenLinks = -1;

  if (showBrokenLinks == -1) {
    showBrokenLinks =
      [[NSUserDefaults standardUserDefaults] boolForKey:@"ShowBrokenLinks"]
      ? 1 : 0;
  }

  if (showBrokenLinks) {
    SkyDocument *doc;

    doc = [(SkyPubComponent *)[_ctx component] componentDocument];
    
    NSLog(@"Broken link in document '%@': '%@'",
          [doc valueForKey:@"NSFilePath"],
          _link);
  }
}

- (void)_appendLinkAttribute:(id)_attr ofNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  NSString *key;
  id       value;
  NSString *url;
  
  key   = [_attr name];
  value = [self valueFor:key node:_node ctx:_ctx];
  
  if (![self isValidLink:value inContext:_ctx]) {
    [self reportBrokenLink:value inNode:_node ctx:_ctx];
    return;
  }
  
  url = [self valueForLink:value inContext:_ctx];
  [_response appendContentString:@" "];
  [_response appendContentHTMLString:key];
  [_response appendContentString:@"=\""];
  [_response appendContentString:url];
  [_response appendContentString:@"\""];
}

- (void)_appendAttributesOfNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  id attrs;
  id attr;
  NSString *linkAttr;
  NSString *tagName;
  
  if ((attrs = [(id)[_node attributes] objectEnumerator]) == nil)
    /* no attributes ... */
    return;
  
  tagName  = [_node tagName];
  linkAttr = [_node htmlLinkAttribute];
  
  while ((attr = [attrs nextObject])) {
    NSString *value;
    NSString *attrName;
    
    attrName = [attr name];
    
    if ([linkAttr isEqualToString:attrName]) {
      [self _appendLinkAttribute:attr ofNode:_node
            toResponse:_response inContext:_ctx];
      continue;
    }
    
    value = [self stringFor:attrName node:_node ctx:_ctx];
    
    [_response appendContentString:@" "];
    [_response appendContentString:attrName];
    [_response appendContentString:@"=\""];
    [_response appendContentHTMLAttributeValue:value];
    [_response appendContentString:@"\""];
  }
}

- (BOOL)isHiddenHTMLTag:(NSString *)_tag inContext:(WOContext *)_ctx {
  /*
    This is used to hide top-level elements in content. Top-level elements
    are only allowed in templates !!!
  */
  if ([(SkyPubComponent *)[_ctx component] isTemplate])
    /* no hidden tags in templates .. */
    return NO;
  
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
    [_response appendContentString:[_node tagName]];
    [self _appendAttributesOfNode:_node toResponse:_response inContext:_ctx];
  }
  
  if ([_node hasChildNodes]) {
    if (tagName) [_response appendContentString:@">"];
    
    /* append child elements */
    [self appendChildNodes:[_node childNodes]
          toResponse:_response
          inContext:_ctx];
    
    if (tagName) {
      [_response appendContentString:@"</"];
      [_response appendContentString:[_node tagName]];
      [_response appendContentString:@">"];
    }
  }
  else {
    if (tagName) [_response appendContentString:@" />"];
  }
}

@end /* SkyPubHTMLNodeRenderer */

@implementation SkyPubAnkerNodeRenderer

- (void)appendNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  id       target;
  BOOL     isInvalid;

  isInvalid = NO;
  
  if ((target = [self valueFor:@"href" node:_node ctx:_ctx])) {
    if (![self isValidLink:target inContext:_ctx])
      isInvalid = YES;
  }
  else {
    NSString *name;
    
    name = [self valueFor:@"name" node:_node ctx:_ctx];
    if ([name length] == 0)
      isInvalid = YES;
  }
  
  if (isInvalid) {
    /* invalid anker, just add contents */
    
    [self reportBrokenLink:[target stringValue] inNode:_node ctx:_ctx];
    if (outputInvalidLinkInfo) {
      [_response appendContentString:@"<!-- a with invalid href: '"];
      [_response appendContentHTMLString:[target stringValue]];
      [_response appendContentString:@"' -->"];
    }
    if ([_node hasChildNodes]) {
      [self appendChildNodes:[_node childNodes]
            toResponse:_response
            inContext:_ctx];
    }
    return;
  }
  
  [super appendNode:_node toResponse:_response inContext:_ctx];
}

@end /* SkyPubAnkerNodeRenderer */

@implementation SkyPubImgNodeRenderer

- (void)appendNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  id       target;
  NSString *href;
  NSString *alt;
  
  target = [self valueFor:@"src" node:_node ctx:_ctx];
  
  if (![self isValidLink:target inContext:_ctx]) {
    NSString *alt;
    
    [self reportBrokenLink:target inNode:_node ctx:_ctx];
    if (outputInvalidLinkInfo)
      [_response appendContentString:@"<!-- img tag with invalid link -->"];
    alt = [self stringFor:@"alt" node:_node ctx:_ctx];
    if ([alt length] > 0) [_response appendContentHTMLString:alt];
    return;
  }
  
  alt  = [self stringFor:@"alt" node:_node ctx:_ctx];
  href = [self valueForLink:target inContext:_ctx];
  
  if ([alt length] == 0)
    alt = [self targetTitleForLink:target inContext:_ctx];
  
  if (coreOnInvalidLink && ([href length] > 0)) {
    printf("aborting, because core-on-invalid-link is enabled !\n");
    abort();
  }
  
  [_response appendContentString:@"<img src=\""];
  [_response appendContentString:href];
  [_response appendContentString:@"\""];
  
  if ([alt length] > 0) {
    [_response appendContentString:@" alt=\""];
    [_response appendContentString:alt];
    [_response appendContentString:@"\""];
  }
  
  /* attributes */
  {
    NSEnumerator *attrs;
    id attr;
      
    attrs = [(id)[_node attributes] objectEnumerator];
    while ((attr = [attrs nextObject])) {
      NSString *attrName;
      NSString *value;
        
      if ((attrName = [attr name]) == nil)   continue;
      if ([attrName isEqualToString:@"src"]) continue;
      if ([attrName isEqualToString:@"alt"]) continue;
      
      value = [self stringFor:attrName node:_node ctx:_ctx];
        
      [_response appendContentString:@" "];
      [_response appendContentString:attrName];
      [_response appendContentString:@"=\""];
      [_response appendContentHTMLAttributeValue:value];
      [_response appendContentString:@"\""];
    }
  }
  
  [_response appendContentString:@" />"];
}

@end /* SkyPubImgNodeRenderer */

@implementation SkyPubScriptNodeRenderer

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
  
  [_response appendContentString:@"<script"];
  [self _appendAttributesOfNode:_node toResponse:_response inContext:_ctx];
  [_response appendContentString:@">"];
  
  /* append child elements */
  if ([_node hasChildNodes]) {
    [_response appendContentString:@"<!-- hide\n"];
    [self appendChildNodes:[_node childNodes]
          toResponse:_response
          inContext:_ctx];
    [_response appendContentString:@" // -->"];
  }
  
  /* always close tag */
  [_response appendContentString:@"</script>"];
}

@end /* SkyPubScriptNodeRenderer */

@implementation SkyPubTextAreaNodeRenderer

- (void)appendNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  /*
    WARNING: HTML browser do not understand <textArea /> !!!
    TEXTAREA tags always
    need to be closed !!!
  */
  [_response appendContentString:@"<textarea"];
  [self _appendAttributesOfNode:_node toResponse:_response inContext:_ctx];
  [_response appendContentString:@">"];
  
  /* append child elements */
  if ([_node hasChildNodes]) {
    [self appendChildNodes:[_node childNodes]
          toResponse:_response
          inContext:_ctx];
  }
  [_response appendContentString:@"</textarea>"];
}

@end /* SkyPubTextAreaNodeRenderer */

@implementation SkyPubSSINodeRenderer

- (void)appendNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  NSString     *element;
  NSEnumerator *attrs;
  id           attr;
  
  element = [_node attribute:@"element"];
  if ([element length] == 0) {
    [_response appendContentString:@"<!-- missing name of SSI -->"];
    return;
  }

  [_response appendContentString:@"<!--#"];
  [_response appendContentString:element];

  /* attributes */
  attrs = [(id)[_node attributes] objectEnumerator];
  while ((attr = [attrs nextObject])) {
    NSString *attrName;
        
    if ((attrName = [attr name]) == nil)       continue;
    if ([attrName isEqualToString:@"element"]) continue;
    
    [_response appendContentString:@" "];
    [_response appendContentString:attrName];
    [_response appendContentString:@"=\""];
    [_response appendContentHTMLAttributeValue:
                 [self stringFor:attrName node:_node ctx:_ctx]];
    [_response appendContentString:@"\""];
  }
  
  [_response appendContentString:@" -->"];
}

@end /* SkyPubSSINodeRenderer */

@implementation SkyPubEntityNodeRenderer

- (void)appendNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  NSString *entityName;
  
  if ((entityName = [_node attribute:@"name"])) {
    [_response appendContentString:@"&"];
    [_response appendContentString:entityName];
    [_response appendContentString:@";"];
  }
}

@end /* SkyPubEntityNodeRenderer */

@implementation SkyPubCommentNodeRenderer

- (void)appendNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  if ([_node hasChildNodes]) {
    [_response appendContentString:@"<!-- "];
    [self appendChildNodes:[_node childNodes]
          toResponse:_response inContext:_ctx];
    [_response appendContentString:@" -->"];
  }
}

@end /* SkyPubCommentNodeRenderer */
