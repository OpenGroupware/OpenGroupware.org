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

/* DEFAULT RENDERER to be replaced */

#import <NGObjDOM/ODNodeRendererFactorySet.h>

@class NSMutableDictionary;

@interface SkyNodeRendererSet : ODNodeRendererFactorySet
{
  NSMutableDictionary *tagToRenderer; // cache
}

@end

#include <NGObjDOM/ODNodeRenderer.h>
#include <DOM/DOM.h>
#include "common.h"
#include <NGObjDOM/ODNamespaces.h>

@implementation SkyNodeRendererSet

+ (int)version {
  return [super version] + 0 /* v1 */;
}
+ (void)initialize {
  NSAssert2([super version] == 1,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
}

- (id)init {
  if ((self = [super init])) {
    id tmp;
    
    tmp = [[NSClassFromString(@"ODXHTMLNodeRenderFactory") alloc] init];
    [self registerFactory:tmp forNamespaceURI:XMLNS_XHTML];
    RELEASE(tmp);
    
    tmp = [[NSClassFromString(@"ODXULNodeRenderFactory") alloc] init];
    [self registerFactory:tmp forNamespaceURI:XMLNS_XUL];
    RELEASE(tmp);
    
    tmp = [[NSClassFromString(@"ODBindNodeRenderFactory") alloc] init];
    [self registerFactory:tmp forNamespaceURI:XMLNS_OD_BIND];
    RELEASE(tmp);
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->tagToRenderer);
  [super dealloc];
}

/* accessors */

- (ODNodeRenderer *)textNodeRendererForNode:(id)_domNode {
  static id r = nil;
  if (r == nil) r = [[NSClassFromString(@"ODRNodeText") alloc] init];
  return r;
}

- (ODNodeRenderer *)elementNodeRendererForNode:(id)_domNode {
  ODNodeRenderer *tagRenderer = nil;
  NSString *key, *nsuri;

  nsuri = [_domNode namespaceURI];

  key = [NSString stringWithFormat:@"{%@}%@",
                    nsuri,
                    [_domNode tagName]];
  
  if ((tagRenderer = [self->tagToRenderer objectForKey:key])) {
    //NSLog(@"render cache hit");
    return tagRenderer;
  }
  //NSLog(@"render cache miss");

  tagRenderer = nil;
  
  if ([nsuri isEqualToString:XMLNS_XHTML]) {
    static id<ODNodeRendererFactory> rf = nil;
    if (rf == nil)
      rf = [[NSClassFromString(@"ODXHTMLNodeRenderFactory") alloc] init];

    tagRenderer = [rf rendererForNode:_domNode inContext:nil];
  }
  else if ([nsuri isEqualToString:XMLNS_XUL]) {
    static id<ODNodeRendererFactory> rf = nil;
    if (rf == nil)
      rf = [[NSClassFromString(@"ODXULNodeRenderFactory") alloc] init];
    
    tagRenderer = [rf rendererForNode:_domNode inContext:nil];
  }
  else if ([nsuri isEqualToString:XMLNS_OD_BIND]) {
    NSString *rendererName;
    static id<ODNodeRendererFactory> worf   = nil;
    static id<ODNodeRendererFactory> bindrf = nil;
    
    if (worf == nil)
      worf = [[NSClassFromString(@"ODWONodeRenderFactory") alloc] init];
    if (bindrf == nil)
      bindrf = [[NSClassFromString(@"ODBindNodeRenderFactory") alloc] init];
    
    rendererName = [_domNode tagName];
#if LIB_FOUNDATION_LIBRARY
    rendererName = [rendererName stringByReplacingString:@"-" withString:@"_"];
#else
#  warning FIXME: incorrect implementation on this Foundation library!
#endif
    rendererName = [@"ODR_sky_" stringByAppendingString:rendererName];
    tagRenderer = [[[NSClassFromString(rendererName) alloc] init] autorelease];
    
    if (tagRenderer == nil)
      tagRenderer = [bindrf rendererForNode:_domNode inContext:nil];      
    if (tagRenderer == nil)
      tagRenderer = [worf rendererForNode:_domNode inContext:nil];
  }
  else {
    static id r = nil;
    if (r == nil)
      r = [[NSClassFromString(@"ODRGenericTag") alloc] init];
    tagRenderer = r;
  }
  
  if (tagRenderer) {
    if (self->tagToRenderer == nil)
      self->tagToRenderer = [[NSMutableDictionary alloc] initWithCapacity:32];
    [self->tagToRenderer setObject:tagRenderer forKey:key];
  }
  
#if DEBUG
  else {
    NSLog(@"WARNING(%s): did not find renderer for %@",
          __PRETTY_FUNCTION__, key);
  }
#endif
  
  return tagRenderer;
}

- (ODNodeRenderer *)rendererForNode:(id)_domNode inContext:(id)_ctx {
  static id r = nil;

  switch ([_domNode nodeType]) {
    case DOM_TEXT_NODE:
    case DOM_CDATA_SECTION_NODE:
      return [self textNodeRendererForNode:_domNode];
      
    case DOM_ELEMENT_NODE:
      return [self elementNodeRendererForNode:_domNode];
      
    default:
      if (r == nil)
        r = [[NSClassFromString(@"ODNodeRenderer") alloc] init];
      return r;
  }
}

@end /* SkyNodeRendererSet */
