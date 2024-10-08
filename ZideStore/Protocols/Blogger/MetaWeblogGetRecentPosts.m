/*
  Copyright (C) 2004 Helge Hess

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

#include "MetaWeblogAction.h"

@interface MetaWeblogGetRecentPosts : MetaWeblogAction
{
  int numberOfPosts;
}

@end

#include "NSObject+Blogger.h"
#include "common.h"

@implementation MetaWeblogGetRecentPosts

- (void)dealloc {
  [super dealloc];
}

/* accessors */

- (void)setNumberOfPosts:(int)_value {
  self->numberOfPosts = _value;
}
- (int)numberOfPosts {
  return self->numberOfPosts;
}

/* fetching entries */

- (NSArray *)fetchEntries {
  NSMutableArray *ma;
  WOContext *ctx;
  NSArray   *names;
  unsigned  i, count;
  id        blog;
  
  if ((blog = [self blog]) == nil)
    return nil;
  
  [self logWithFormat:@"TODO: fetch recent entries: %@", blog];
  
  ctx   = [self context];
  names = [blog bloggerPostIDsInContext:ctx];
  count = [names count];
  ma    = [NSMutableArray arrayWithCapacity:count];
  
  for (i = 0; i < count; i++) {
    id entry;
    
    entry = [blog lookupName:[names objectAtIndex:i] inContext:ctx acquire:NO];
    if (![entry isNotNull])
      continue;
    
    entry = [entry bloggerPostInfoInContext:ctx];
    if (![entry isNotNull])
      continue;
    
    [ma addObject:entry];
    if ([ma count] >= [self numberOfPosts]) /* limit count */
      break;
  }
  return ma;
}

/* actions */

- (id)defaultAction {
  [self logWithFormat:@"%@ get recent posts of blog %@ / %d: %@", 
	  [self login], [self blogID], [self numberOfPosts], 
	  [self clientObject]];
  return [self fetchEntries];
}

@end /* MetaWeblogGetRecentPosts */
