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
#include "SkyPubInlineViewer.h"
#include "SkyDocument+Pub.h"
#include "SkyPubFileManager.h"
#include "SkyPubComponent.h"
#include "PubKeyValueCoding.h"
#include "common.h"
#include <NGExtensions/NSProcessInfo+misc.h>
#include <OGoDocuments/SkyDocuments.h>
#include <NGObjDOM/ODNamespaces.h>
#include <DOM/EDOM.h>

@interface SkyPubSKYOBJNodeRenderer(MicroNav)
- (void)_appendMicronavigationNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx;
@end

@interface SkyPubSKYOBJNodeRenderer(InsertMeta)
- (void)_appendInsertvalueMetaNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx;
@end

@interface SkyPubSKYOBJNodeRenderer(InsertAnchor)
- (void)_appendInsertvalueAnchorNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx;
- (void)_appendInsertvalueImageNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx;
@end

@interface SkyPubSKYOBJNodeRenderer(InsertVar)
- (void)_appendInsertvalueVarNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx;
@end

@interface SkyPubSKYOBJNodeRenderer(Condition)
- (void)_appendConditionNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx;
@end

@interface SkyPubSKYOBJNodeRenderer(Template)
- (void)_appendInsertvalueTemplateNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx;
@end

@interface SkyPubSKYOBJNodeRenderer(IncludeText)
- (void)_appendIncludetextNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx;
@end

@interface SkyPubSKYOBJNodeRenderer(List)
- (void)_appendListNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx;
@end

@interface SkyPubSKYOBJNodeRenderer(Document)
- (void)_appendDocumentNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx;
@end

static int profile = -1;

@implementation DOMElement(SKYNodeName)

- (NSString *)npsNodeType {
  if ([self hasAttribute:@"condition" namespaceURI:@"*"])
    return @"condition";
  else if ([self hasAttribute:@"frame" namespaceURI:@"*"])
    return @"frame";
  else if ([self hasAttribute:@"includetext" namespaceURI:@"*"])
    return @"includetext";
  else if ([self hasAttribute:@"insertvalue" namespaceURI:@"*"])
    return @"insertvalue";
  else if ([self hasAttribute:@"list" namespaceURI:@"*"])
    return @"list";
  else if ([self hasAttribute:@"document" namespaceURI:@"*"])
    return @"document";
  else if ([self hasAttribute:@"makeanchor" namespaceURI:@"*"])
    return @"makeanchor";
  else if ([self hasAttribute:@"micronavigation" namespaceURI:@"*"])
    return @"micronavigation";
  else if ([self hasAttribute:@"table" namespaceURI:@"*"])
    return @"table";
  else if ([self hasAttribute:@"toclistsortedby" namespaceURI:@"*"])
    return @"toclistsortedby";
  else if ([self hasAttribute:@"toctablesortedby" namespaceURI:@"*"])
    return @"toctablesortedby";
  
  return nil;
}

@end /* DOMNode(SKYNodeName) */

@implementation SkyPubSKYOBJNodeRenderer

- (NSString *)targetURLForPath:(NSString *)_path inContext:(WOContext *)_ctx{
  SkyPubComponent *pubc;
  SkyDocument     *baseDoc, *targetdoc;
  NSString        *absurl, *relurl;
  
  if ([_path length] == 0)   return nil;
  if ([_path isAbsoluteURL]) return _path;

  pubc = (SkyPubComponent *)[_ctx component];
  
  /* get the document we need to link relative to ... */
  if ((baseDoc = [pubc document]) == nil)
    /* missing doc, can't be valid ... */
    return nil;
  
  /* make link absolute */
  if ((absurl = [baseDoc pubAbsoluteTargetPathForLink:_path]) == nil)
    return nil;
  
  /* get the document we need to link relative to ... */
  targetdoc = [pubc document];
  
  /* now create the link relative to delivered content !!! */
  relurl = [targetdoc pubRelativeTargetPathForLink:absurl];
  
  if ([relurl length] == 0) {
    NSLog(@"WARNING(%s): got empty relative link: abs '%@' relative to %@",
          __PRETTY_FUNCTION__, absurl, targetdoc);
    relurl = nil;
  }
  return relurl;
}

- (void)_appendInsertvalueNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  NSString *insertType;
  
  insertType = [_node attribute:@"insertvalue"];
  
  if ([insertType isEqualToString:@"var"]) {
    [self _appendInsertvalueVarNode:_node toResponse:_response inContext:_ctx];
    return;
  }
  if ([insertType isEqualToString:@"meta"]) {
    [self _appendInsertvalueMetaNode:_node
          toResponse:_response inContext:_ctx];
    return;
  }
  if ([insertType isEqualToString:@"template"]) {
    [self _appendInsertvalueTemplateNode:_node
          toResponse:_response inContext:_ctx];
    return;
  }
  if ([insertType isEqualToString:@"anchor"]) {
    [self _appendInsertvalueAnchorNode:_node
          toResponse:_response inContext:_ctx];
    return;
  }
  if ([insertType isEqualToString:@"image"]) {
    [self _appendInsertvalueImageNode:_node
          toResponse:_response inContext:_ctx];
    return;
  }
  
  [self addUnsupportedNode:_node toResponse:_response inContext:_ctx];
}

- (void)_appendFrameNode:(id)_node
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

- (void)appendNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  static int nesting = 0;
  NSAutoreleasePool *pool;
  NSDate            *date;
  unsigned          vsizeStart;
  NSString *nodeType;
  
  if (profile == -1) {
    profile = [[NSUserDefaults standardUserDefaults]
                               boolForKey:@"ProfileSKYOBJ"] ? 1 : 0;
  }
  
  if (profile) {
    date       = [NSDate date];
    vsizeStart = [[NSProcessInfo processInfo] virtualMemorySize];
  }
  else {
    date = nil;
    vsizeStart = 0;
  }

  nesting++;
  pool = [[NSAutoreleasePool alloc] init];

  nodeType = [_node npsNodeType];
  
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
  else if ([nodeType isEqualToString:@"document"])
    [self _appendDocumentNode:_node toResponse:_response inContext:_ctx];
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
    NSLog(@"%s: invalid SKYOBJ tag:\n  %@\n  %@", __PRETTY_FUNCTION__,
          _node, [_node xmlStringValue]);
    [_response appendContentString:@"[INVALID SKYOBJ tag]"];
  }
  
  [pool release];
  nesting--;
  
  if (profile) {
    int i;
    
    for (i = 0; i < nesting; i++)
      printf("  ");
    
    printf("SKYOBJ(%s): %.3fs, memdiff=%d\n",
           [[_node npsNodeType] cString],
           [[NSDate date] timeIntervalSinceDate:date],
           [[NSProcessInfo processInfo] virtualMemorySize] - vsizeStart
           );
  }
}

@end /* SkyPubSKYOBJNodeRenderer */
