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

#include "SkyPubSKYOBJ.h"
#include "common.h"
#include "SkyDocument+Pub.h"
#include "SkyPubDataSource.h"
#include "SkyPubFileManager.h"
#include "PubKeyValueCoding.h"
#include <NGObjDOM/WOContext+Cursor.h>
#include <DOM/EDOM.h>

//#define PROF 1

@implementation SkyPubSKYOBJNodeRenderer(List)

- (void)_appendListNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  /*
    list=all
      all documents in the publication
      
    list=toclist
      all publications, documents & generic documents
      
    list=children
      all subobjects
      
    list=relatedLinks
      related links ?

    list=objectsToRoot
      all objects till root

    list=path
      all subobjects of 'path'

    Attribute:
      list
      sortedby
      query
      reverse
  */
  NSAutoreleasePool   *pool;
  NSMutableDictionary *listCache;
  NSArray             *list;
  NSString            *listType;
  NSString            *sortKey;
  NSString            *query;
  NSString            *reverse;
  unsigned            i, count;
  id                  folderDoc;
  
  if (![_node hasChildNodes])
    /* no content to repeat ... */
    return;

  pool = [[NSAutoreleasePool alloc] init];
  
  listCache = [_ctx valueForKey:@"ListCache"];

  listType = [self stringFor:@"list"     node:_node ctx:_ctx];
  sortKey  = [self stringFor:@"sortedby" node:_node ctx:_ctx];
  query    = [self stringFor:@"query"    node:_node ctx:_ctx];
  reverse  = [self boolFor:@"reverse"    node:_node ctx:_ctx] ? @"YES" : @"NO";

  //NSLog(@"LIST: %@", listType);

  /* get list */
  
  if ((folderDoc = [self _folderDocumentInContext:_ctx])) {
    list = nil;
    
    if (listCache) {
      NSString *p;
      
      if ((p = [folderDoc valueForKey:@"NSFilePath"])) {
        NSString *cp;
        static int hitCount = 0, missCount = 0;
        
	cp = [listType stringByAppendingString:p];
        
        if ((list = [listCache objectForKey:cp])) {
          hitCount++;
#if LOG_CACHE
          [[_ctx component] debugWithFormat:@"list cache hit on %@ (%i vs %i)",
                            cp, hitCount, missCount];
#endif
          if (![list isNotNull])
            list = nil;
        }
        else {
          missCount++;
#if LOG_CACHE
          [[_ctx component] debugWithFormat:
                              @"list cache miss on %@ (%i vs %i)",
                              cp, hitCount, missCount];
#endif
          list = [folderDoc npsValueForKey:listType inContext:_ctx];
          [listCache setObject:list ? list : (id)[NSNull null] forKey:cp];
        }
      }
      else
        list = [folderDoc npsValueForKey:listType inContext:_ctx];
    }
    else
      list = [folderDoc npsValueForKey:listType inContext:_ctx];
  }
  
  /* check list */
  
  if (list == nil) {
    NSLog(@"%s: found no list for name %@", __PRETTY_FUNCTION__, listType);
    list = [NSArray array];
  }
  else if ([list isKindOfClass:[NSString class]]) {
    list = [(NSString *)list componentsSeparatedByString:@","];
  }
  
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
    EOSortOrdering *so;
    SEL            sortsel;
    NSRange        r;
    
    r = [sortKey rangeOfString:@"."];
    if (r.length > 0) {
      stype   = [sortKey substringFromIndex:(r.location + 1)];
      sortKey = [sortKey substringToIndex:r.location];
    }
    else
      stype = nil;
    
    if ([stype isEqualToString:@"reverse"])
      sortsel = EOCompareDescending;
    else
      sortsel = EOCompareAscending;
    
    so = [EOSortOrdering sortOrderingWithKey:sortKey
                         selector:sortsel];

    list = [list sortedArrayUsingKeyOrderArray:[NSArray arrayWithObject:so]];
  }
  
  /* process list */

  if ((count = [list count]) > 0) {
    if ([reverse boolValue]) {
      int i;
      
      for (i = (count - 1); i >= 0; i--) {
        id ctx;
      
        ctx = [list objectAtIndex:i];
        
        [_ctx pushCursor:ctx];
        
        [self appendChildNodes:[_node childNodes]
              toResponse:_response
              inContext:_ctx];
        
        [_ctx popCursor];
      }
    }
    else {
      for (i = 0; i < count; i++) {
        id ctx;
    
        ctx = [list objectAtIndex:i];

        [_ctx pushCursor:ctx];
        
        [self appendChildNodes:[_node childNodes]
              toResponse:_response
              inContext:_ctx];
        
        [_ctx popCursor];
      }
    }
  }
  
#if DEBUG && PROF
  NSLog(@"list(%@,#%d,%@): objects in pool: %d",
        listType, count, [[_ctx component] name], [pool autoreleaseCount]);
#endif
  RELEASE(pool);
}

@end /* SkyPubSKYOBJNodeRenderer(List) */
