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
#include "SkyDocument+Pub.h"
#include "common.h"
#include <DOM/EDOM.h>
#include <NGObjDOM/ODNamespaces.h>

@implementation SkyPubSKYOBJPreviewNodeRenderer(InsertAnchor)

- (void)_appendAttribute:(id)_attr ofNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  if (![[_attr namespaceURI] isEqualToString:XMLNS_XHTML])
    /* not an HTML attribute .. */
    return;

  [_response appendContentString:[_attr name]];
  [_response appendContentString:@"=\""];
  [_response appendContentHTMLAttributeValue:[_attr value]];
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
  
  if ((attrs = [(NSArray *)[_node attributes] objectEnumerator]) == nil)
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
  NSString    *targetName;
  SkyDocument *namedValue;
  NSString    *href;
  
  targetName = [_node attribute:@"name"];
  if ([targetName length] == 0) {
    NSLog(@"%s: missing name of anchor target !", __PRETTY_FUNCTION__);
  }
  else if ([targetName isEqualToString:@"next"]) {
    namedValue = [self _nextDocumentInContext:_ctx];
  }
  else if ([targetName isEqualToString:@"previous"]) {
    namedValue = [self _previousDocumentInContext:_ctx];
  }
  else if ([targetName isEqualToString:@"parent"]) {
    namedValue = [self _parentDocumentInContext:_ctx];
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
  
  if ([href length] == 0) href = nil;
  
  //href = [self targetURLForPath:href inContext:_ctx];
  
  [_response appendContentString:@"<font color=\"blue\">[Anchor: "];
  [_response appendContentHTMLString:href];
  [_response appendContentString:@" </font>"];
  
  if ([_node hasChildNodes]) {
    [self appendChildNodes:[_node childNodes]
          toResponse:_response
          inContext:_ctx];
  }
  
  [_response appendContentString:@"<font color=\"blue\">]:</font>"];
}

- (void)_appendInsertvalueImageNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  NSString    *targetName;
  SkyDocument *namedValue;
  NSString    *href;
  
  targetName = [_node attribute:@"name"];
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
  
  //href = [self targetURLForPath:href inContext:_ctx];

  [_response appendContentString:@"<font color=\"blue\">[Image: "];
  [_response appendContentHTMLString:href];
  [_response appendContentString:@"]:</font>"];
  
  if ([_node hasChildNodes]) {
    [self appendChildNodes:[_node childNodes]
          toResponse:_response
          inContext:_ctx];
  }
}

@end /* SkyPubSKYOBJPreviewNodeRenderer(InsertAnchor) */
