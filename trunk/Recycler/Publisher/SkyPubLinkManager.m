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

#include "SkyPubLinkManager.h"
#include "SkyPubFileManager.h"
#include "SkyDocument+Pub.h"
#include "SkyPubLink.h"
#include "common.h"
#include <DOM/EDOM.h>
#include <NGObjDOM/ODNamespaces.h>

@implementation SkyPubLinkManager

- (id)initWithDocument:(SkyDocument *)_doc
  fileManager:(SkyPubFileManager *)_fileManager
{
  self->document    = RETAIN(_doc);
  self->fileManager = [[_fileManager asPubFileManager] retain];
  return self;
}
- (id)init {
  return [self initWithDocument:nil fileManager:nil];
}

- (void)dealloc {
  [self->linkCache makeObjectsPerformSelector:@selector(_resetManager)];
  RELEASE(self->fileManager);
  RELEASE(self->linkCache);
  RELEASE(self->document);
  [super dealloc];
}

/* accessors */

- (SkyDocument *)document {
  return self->document;
}
- (id)dom {
  id doc;
  
  if ((doc = [self document]) == nil)
    return nil;
  if (![doc respondsToSelector:@selector(contentAsDOMDocument)])
    return nil;
  
  return [doc contentAsDOMDocument];
}
- (SkyPubFileManager *)fileManager {
  return self->fileManager;
}

/* query */

- (NSArray *)allHTMLAnkerLinkNodes {
  static DOMQueryPathExpression *query = nil;
  NSArray *docList;
  
  if (query == nil) {
    query = [[DOMQueryPathExpression queryPathWithString:
                                       @"{http://www.w3.org/1999/xhtml}a"]
                                     retain];
  }
  
  docList = [NSArray arrayWithObject:[self dom]];
  
  return [query evaluateWithNodeList:docList];
}

- (NSArray *)allHTMLImageLinkNodes {
  static DOMQueryPathExpression *query = nil;
  NSArray *docList;
  
  if (query == nil) {
    query = [[DOMQueryPathExpression queryPathWithString:
                                       @"{http://www.w3.org/1999/xhtml}img"]
                                     retain];
  }

  docList = [NSArray arrayWithObject:[self dom]];
  
  return [query evaluateWithNodeList:docList];
}

- (NSArray *)allXLinkNodes {
  static DOMQueryPathExpression *query = nil;
  NSArray *docList;
  NSArray *nodes;

  if (query == nil) {
    query =
      [[DOMQueryPathExpression queryPathWithString:
                                 @"*[@{http://www.w3.org/1999/xlink}type]"]
                               retain];
  }
  
  docList = [NSArray arrayWithObject:[self dom]];
  
  nodes = [query evaluateWithNodeList:docList];

  // NSLog(@"FOUND XLINKS: %@", nodes);
  
  return nodes;
}

- (NSArray *)allLinks {
  NSMutableArray *nodes;
  NSMutableSet   *links;
  NSEnumerator   *e;
  id             node;
  
  nodes = [NSMutableArray arrayWithCapacity:128];
  [[self dom] addLinkNodesToArray:nodes];
  
  e     = [nodes objectEnumerator];
  links = [NSMutableSet setWithCapacity:[nodes count]];
  
  while ((node = [e nextObject])) {
    SkyPubLink *link;
    
    if ((link = [node pubLinkWithManager:self]))
      [links addObject:link];
  }
  //NSLog(@"LINKS: %@", links);
  
  return [links allObjects];
}

- (SkyPubLink *)linkForElementNode:(id)_node {
  return [_node pubLinkWithManager:self];
}

@end /* SkyPubLinkManager */
