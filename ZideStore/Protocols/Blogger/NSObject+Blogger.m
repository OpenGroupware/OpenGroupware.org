/*
  Copyright (C) 2004 SKYRIX Software AG

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

#include "NSObject+Blogger.h"
#include "common.h"
#include <NGObjWeb/SoObjects.h>

@implementation NSObject(Blogger)

- (NSDictionary *)bloggerBlogInfoInContext:(id)_ctx {
  /* keys: url, blogid, blogName */
  NSString *url, *bid, *bname;
  
  bname = [self davDisplayName];
  url   = [self baseURLInContext:_ctx];
  bid   = [self nameInContainer];
  
  return [NSDictionary dictionaryWithObjectsAndKeys:
			 url,   @"url",
		         bid,   @"blogid",
		         bname, @"blogName",
		       nil];
}

- (NSArray *)bloggerFetchAllBlogInfosInContext:(id)_ctx {
  NSMutableArray *infos;
  NSArray  *keys;
  unsigned i, count;
  
  if ((keys = [self toManyRelationshipKeys]) == nil) {
    [self logWithFormat:@"no container keys."];
    return nil;
  }
  
  if ((count = [keys count]) == 0) {
    [self logWithFormat:@"empty set of container keys."];
    return [NSArray array];
  }
  
  infos = [NSMutableArray arrayWithCapacity:count];
  for (i = 0; i < count; i++) {
    NSDictionary *info;
    NSString     *name;
    id           blog;
    
    name = [keys objectAtIndex:i];
    blog = [self lookupName:name inContext:_ctx acquire:NO];
    if (![blog isNotNull])
      continue;
    
    info = [blog bloggerBlogInfoInContext:_ctx];
    if (![info isNotNull])
      continue;

    [infos addObject:info];
  }
  
  return infos;
}

- (id)lookupBlogWithID:(NSString *)_blogID inContext:(id)_ctx {
  return [self lookupName:_blogID inContext:_ctx acquire:NO];
}

@end /* NSObject(Blogger) */
