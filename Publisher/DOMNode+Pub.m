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

#include "DOMNode+Pub.h"
#include <NGObjDOM/ODNamespaces.h>
#include "common.h"

@implementation DOMNode(LinkElems)

- (BOOL)isHTMLElementLink {
  return NO;
}
- (NSString *)htmlLinkAttribute {
  return nil;
}

- (BOOL)isXLink {
  return NO;
}

- (BOOL)isElementLink {
  return NO;
}

- (void)addLinkNodesToArray:(NSMutableArray *)_array {
  if ([self isElementLink])
    [_array addObject:self];
  
  if ([self hasChildNodes]) {
    NSEnumerator *e;
    id node;
    
    e = [(id)[self childNodes] objectEnumerator];
    while ((node = [e nextObject]))
      [node addLinkNodesToArray:_array];
  }
}

@end /* DOMNode(LinkElems) */

@implementation DOMElement(LinkElems)

- (BOOL)isHTMLElementLink {
#define HTML_LINK_ELEM_COUNT 3
  static NSSet *htmlLinkTags = nil;
  static NSString *links[HTML_LINK_ELEM_COUNT] = {
    @"link", @"form", @"area"
  };
  NSString *tn;

  if (!([[self namespaceURI] isEqualToString:XMLNS_XHTML] ||
        [[self namespaceURI] isEqualToString:XMLNS_HTML40]))
    /* only XHTML nodes can be XHTML links ... ;-) */
    return NO;
  
  if ([self hasAttribute:@"background" namespaceURI:@"*"])
    return YES;
  if ([self hasAttribute:@"src" namespaceURI:@"*"])
    return YES;
  if ([self hasAttribute:@"href" namespaceURI:@"*"])
    return YES;
  
  if (htmlLinkTags == nil) {
    htmlLinkTags =
      [[NSSet alloc] initWithObjects:links count:HTML_LINK_ELEM_COUNT];
  }
  
  tn = [self tagName];
  if ([tn isEqualToString:@"script"]) {
    if ([self hasAttribute:@"src" namespaceURI:@"*"])
      return YES;
    else
      return NO;
  }
  
  return [htmlLinkTags containsObject:[self tagName]];
}
- (NSString *)htmlLinkAttribute {
  static NSString *tagToAttr[] = {
    @"a",      @"href",
    @"img",    @"src",
    @"input",  @"src",
    @"form",   @"action",
    @"area",   @"href",
    @"script", @"src",
    @"link",   @"href",
    nil, nil
  };
  NSString *tag;
  unsigned i;

  if (!([[self namespaceURI] isEqualToString:XMLNS_XHTML] ||
        [[self namespaceURI] isEqualToString:XMLNS_HTML40]))
    /* only XHTML nodes can have XHTML link attributes ... ;-) */
    return NO;
  
  tag = [self tagName];
  for (i = 0; tagToAttr[i] != nil; i += 2) {
    if ([tag isEqualToString:tagToAttr[i]])
      return tagToAttr[(i + 1)];
  }
  
  if ([self hasAttribute:@"background" namespaceURI:@"*"])
    return @"background";
  
  return nil;
}

- (BOOL)isXLink {
  if (![self hasAttribute:@"type" namespaceURI:XMLNS_XLINK])
    /* xlink need to have a xlink:type attribute ... */
    return NO;
  
  return YES;
}

- (BOOL)isElementLink {
  if ([self isHTMLElementLink])
    return YES;
  if ([self isXLink])
    return YES;

  return NO;
}

@end /* DOMElement(LinkElems) */

#include "SkyPubLink.h"

@implementation DOMElement(Links)

- (SkyPubLink *)pubLinkWithManager:(id)_manager {
  if ([self isHTMLElementLink]) {
    NSString *tag;
    
    tag = [self tagName];
    
    if ([tag isEqualToString:@"a"])
      return [SkyPubAnkerLink linkWithNode:self manager:_manager];
    if ([tag isEqualToString:@"link"])
      return [SkyPubLinkLink linkWithNode:self manager:_manager];
    if ([tag isEqualToString:@"img"])
      return [SkyPubImgLink linkWithNode:self manager:_manager];
    if ([tag isEqualToString:@"form"])
      return [SkyPubFormLink linkWithNode:self manager:_manager];
    if ([tag isEqualToString:@"input"])
      return [SkyPubInputLink linkWithNode:self manager:_manager];
    
    if ([tag isEqualToString:@"script"])
      return [SkyPubScriptLink linkWithNode:self manager:_manager];
    
    if ([self hasAttribute:@"background" namespaceURI:XMLNS_XHTML] ||
        [self hasAttribute:@"background" namespaceURI:XMLNS_HTML40]) {
      if ([tag isEqualToString:@"body"]  ||
          [tag isEqualToString:@"table"] ||
          [tag isEqualToString:@"tr"]    ||
          [tag isEqualToString:@"td"]) {
        return [SkyPubBGImgLink linkWithNode:self manager:_manager];
      }
    }
    
#warning fixme, dont use ankerlink ...
    return [SkyPubAnkerLink linkWithNode:self manager:_manager];
  }
  else if ([self isXLink]) {
    /* XLink */
    return [SkyPubXLink linkWithNode:self manager:_manager];
  }
  
  return nil;
}

@end /* DOMElement(Links) */
