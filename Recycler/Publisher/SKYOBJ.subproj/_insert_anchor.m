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
#include "SkyDocument+Pub.h"
#include "common.h"
#include <DOM/EDOM.h>
#include <NGObjDOM/ODNamespaces.h>

@implementation SkyPubSKYOBJNodeRenderer(InsertAnchor)

- (void)_appendAttribute:(id)_attr ofNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  if (![[_attr namespaceURI] isEqualToString:XMLNS_XHTML])
    /* not an HTML attribute .. */
    return;

  [_response appendContentString:@" "];
  [_response appendContentString:[_attr name]];
  [_response appendContentString:@"=\""];
  [_response appendContentHTMLAttributeValue:
               [self stringFor:[_attr name] node:_node ctx:_ctx]];
  [_response appendContentString:@"\""];
}

- (BOOL)_isSKYOBJAttribute:(id)_attr {
  NSString *aname;
  
  if ((aname = [_attr name]) == nil)
    return NO;
  
  if ([aname isEqualToString:@"insertvalue"])
    return YES;
  if ([aname isEqualToString:@"name"])
    return YES;
  
  return NO;
}

- (void)_appendAttributesOfNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  NSEnumerator *attrs;
  id attr;
  
  if ((attrs = [(id)[_node attributes] objectEnumerator]) == nil)
    return;
  
  while ((attr = [attrs nextObject])) {
    if ([self _isSKYOBJAttribute:attr])
      continue;
    
    [self _appendAttribute:attr ofNode:_node
          toResponse:_response inContext:_ctx];
  }
}

- (void)_appendInsertvalueAnchorNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  NSString *targetName;
  id       namedValue;
  NSString *href;
  
  targetName = [self stringFor:@"name" node:_node ctx:_ctx];
  if ([targetName length] == 0) {
    NSLog(@"%s: missing name of anchor target !", __PRETTY_FUNCTION__);
    namedValue = nil;
  }
  else if ([targetName isEqualToString:@"next"])
    namedValue = [self _nextDocumentInContext:_ctx];
  else if ([targetName isEqualToString:@"previous"])
    namedValue = [self _previousDocumentInContext:_ctx];
  else if ([targetName isEqualToString:@"parent"])
    namedValue = [self _parentDocumentInContext:_ctx];
  else {
    namedValue = [self contextValueWithName:targetName inContext:_ctx];
    
    if (namedValue == nil) {
      NSLog(@"%s: found no target named '%@'", __PRETTY_FUNCTION__,
            targetName);
    }
  }
  
  href = [namedValue isKindOfClass:[SkyDocument class]]
    ? [namedValue valueForKey:@"NSFilePath"]
    : [namedValue stringValue];
  
  if ([href length] == 0) href = nil;

  href = [self targetURLForPath:href inContext:_ctx];
  
  if (href) {
    [_response appendContentString:@"<a href=\""];
    [_response appendContentString:href];
    [_response appendContentString:@"\" "];
    [self _appendAttributesOfNode:_node toResponse:_response inContext:_ctx];
    [_response appendContentString:@">"];
  }
  
  if ([_node hasChildNodes]) {
    [self appendChildNodes:[_node childNodes]
          toResponse:_response
          inContext:_ctx];
  }
  
  if (href) [_response appendContentString:@"</a>"];
}

- (void)_appendInsertvalueImageNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  NSString    *targetName;
  SkyDocument *namedValue;
  NSString    *href;
  
  targetName = [self stringFor:@"name" node:_node ctx:_ctx];
  if ([targetName length] == 0) {
    NSLog(@"%s: missing name of anchor target !", __PRETTY_FUNCTION__);
  }
  else {
    namedValue = [self contextValueWithName:targetName inContext:_ctx];
    
    if (namedValue == nil) {
      NSLog(@"%s: found no target named '%@'", __PRETTY_FUNCTION__,
            targetName);
    }
  }
  
  if ([namedValue isKindOfClass:[SkyDocument class]])
    href = [namedValue valueForKey:@"NSFilePath"];
  else
    href = [(id)namedValue stringValue];
  
  href = [self targetURLForPath:href inContext:_ctx];
  
  if ([href length] > 0) {
    [_response appendContentString:@"<img src=\""];
    [_response appendContentString:href];
    [_response appendContentString:@"\" "];
    [self _appendAttributesOfNode:_node toResponse:_response inContext:_ctx];
    [_response appendContentString:@" />"];
  }
  
  if ([_node hasChildNodes]) {
    [self appendChildNodes:[_node childNodes]
          toResponse:_response
          inContext:_ctx];
  }
}

@end /* SkyPubSKYOBJNodeRenderer(InsertAnchor) */
