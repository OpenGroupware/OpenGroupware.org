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

#include "SkyPubPreviewSKYOBJ.h"
#include "common.h"
#include "SkyDocument+Pub.h"
#include "PubKeyValueCoding.h"
#include <NGObjDOM/WOContext+Cursor.h>
#include <DOM/EDOM.h>

@implementation SkyPubSKYOBJPreviewNodeRenderer(_list)

- (void)_realAppendListNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  /*
    list=toclist
      alle Publikationen, Dokumente & Generischen Dokumente
      
    list=children
      alle Unterobjekte
      
    list=relatedLinks
      related Links ?

    list=objectsToRoot
      ??

    Attribute
      sortKey
      query
  */
  NSArray     *list;
  NSString    *listType;
  unsigned    i, count;
  NSString    *sortKey;
  NSString    *query;
  id doc;

  if (![_node hasChildNodes])
    /* no content to repeat ... */
    return;
  
  /* get list */
  
  listType = [_node attribute:@"list"];
  
  if ((doc = [self _folderDocumentInContext:_ctx]) == nil) {
    NSLog(@"%s: found folder doc in ctx for list '%@'", __PRETTY_FUNCTION__,
          listType);
  }
  
  list = [doc npsValueForKey:listType inContext:_ctx];
  
  /* check list */
  
  if (list == nil) {
    NSLog(@"%s: found no list for name '%@' (doc=%@)", __PRETTY_FUNCTION__,
          listType, doc);
    list = [NSArray array];
  }
  else if ([list isKindOfClass:[NSString class]]) {
    list = [(NSString *)list componentsSeparatedByString:@","];
  }
  
  sortKey = [_node attribute:@"sortedby"];
  query   = [_node attribute:@"query"];
  
  /* filter list */
  
  if ([query length] > 0) {
    EOQualifier *qualifier;
    
    qualifier = [EOQualifier qualifierWithQualifierFormat:query];
    if (qualifier == nil) 
      NSLog(@"%s: couldn't parse query '%@'", __PRETTY_FUNCTION__, query);
    else 
      list = [list filteredArrayUsingQualifier:qualifier];
  }

  /* sort list */
  
  if ([sortKey length] == 0)
    sortKey = nil;
  
  if ([sortKey length] > 0) {
    NSString       *stype;
    NSRange        r;
    EOSortOrdering *so;
    SEL            sortsel;

    r = [sortKey rangeOfString:@"."];
    if (r.length > 0) {
      stype   = [sortKey substringFromIndex:(r.location + r.length)];
      sortKey = [sortKey substringToIndex:r.location];
    }
    else
      stype = nil;
    
    sortsel = ([stype isEqualToString:@"reverse"])
      ? EOCompareDescending
      : EOCompareAscending;
    
    so = [EOSortOrdering sortOrderingWithKey:sortKey
                         selector:sortsel];

    list = [list sortedArrayUsingKeyOrderArray:[NSArray arrayWithObject:so]];
  }
  
  /* process list */

  for (i = 0, count = [list count]; i < count; i++) {
    id ctx;
    
    ctx = [list objectAtIndex:i];

    [_ctx pushCursor:ctx];
    
    [self appendChildNodes:[_node childNodes]
          toResponse:_response
          inContext:_ctx];
    
    [_ctx popCursor];
  }
}

- (void)_appendListNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  NSString *listType;
  
  listType = [_node attribute:@"list" namespaceURI:[_node namespaceURI]];
  
  [_response appendContentString:@"<font color=\"blue\">[List: "];

  if ([listType length] == 0)
    [_response appendContentString:@"type is calculated"];
  else if ([listType isEqualToString:@"toclist"])
    [_response appendContentString:@"table of contents"];
  else if ([listType isEqualToString:@"children"])
    [_response appendContentString:@"child documents"];
  else if ([listType isEqualToString:@"objectsToRoot"])
    [_response appendContentString:@"documents to root"];
  else if ([listType isEqualToString:@"relatedLinks"])
    [_response appendContentString:@"related links"];
  else if ([listType isEqualToString:@"all"])
    [_response appendContentString:@"ALL project documents"];
  else {
    [_response appendContentString:@"unknown list type: "];
    [_response appendContentHTMLString:listType];
  }
  
  [_response appendContentString:@"]:</font>"];
  
  [self _realAppendListNode:_node toResponse:_response inContext:_ctx];
}

@end /* SkyPubSKYOBJPreviewNodeRenderer(_list) */
