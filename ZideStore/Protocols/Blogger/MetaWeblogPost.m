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

@class NSString, NSDictionary;

@interface MetaWeblogPost : MetaWeblogAction
{
  NSDictionary *entry;
  BOOL         doPublish;
}

@end

#include "NSObject+Blogger.h"
#include "common.h"

@implementation MetaWeblogPost

- (void)dealloc {
  [self->entry  release];
  [super dealloc];
}

/* accessors */

- (void)setEntry:(NSDictionary *)_entry {
  ASSIGNCOPY(self->entry, _entry);
}
- (NSDictionary *)entry {
  return self->entry;
}

- (void)setDoPublish:(BOOL)_flag {
  self->doPublish = _flag;
}
- (int)doPublish {
  return self->doPublish;
}

/* actions */

- (id)newPostAction {
  /* 
     return String postid of new post 
  */
  NSDictionary *e;
  id blog;

  if ((blog = [self blog]) == nil) {
    return [NSException exceptionWithName:@"MissingBlog"
			reason:@"did not find specified blog!" userInfo:nil];
  }
  if ((e = [self entry]) == nil) {
    return [NSException exceptionWithName:@"MissingEntry"
			reason:@"did not specify the entry parameter?!"
			userInfo:nil];
  }
  
  return [blog bloggerPostEntryWithTitle:[e valueForKey:@"title"]
	       description:[e valueForKey:@"description"]
	       creationDate:[e valueForKey:@"dateCreated"]
	       inContext:[self context]];
}

- (id)editPostAction {
  [self logWithFormat:@"%@ edit post %@: %@", 
	  [self login], [self postID], [self entry]];
  return [NSException exceptionWithName:@"NotImplemented"
		      reason:@"not implemented"
		      userInfo:nil];
}

- (id)getPostAction {
  /*
    keys: userid, dateCreated, postid, description, title, link, permaLink,
          mt_excerpt, mt_text_more, mt_allow_comments, mt_allow_pings, 
          mt_convert_breaks, mt_keywords
  */
  id p;
  
  [self logWithFormat:@"%@ get post: %@",  [self login], [self postID]];

  if ((p = [self post]) == nil) {
    return [NSException exceptionWithName:@"DidNotFindPost"
			reason:@"did not find specified post!"
			userInfo:nil];
  }
  
  return [p bloggerPostInfoInContext:[self context]];
}

@end /* MetaWeblogPost */
