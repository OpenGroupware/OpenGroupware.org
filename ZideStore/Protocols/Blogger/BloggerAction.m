/*
  Copyright (C) 2004-2005 SKYRIX Software AG

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

#include "BloggerAction.h"
#include "NSObject+Blogger.h"
#include "common.h"

@implementation BloggerAction

- (void)dealloc {
  [self->postID   release];
  [self->blogID   release];
  [self->login    release];
  [self->password release];
  [self->appID    release];
  [super dealloc];
}

/* accessors */

- (void)setAppID:(NSString *)_value {
  ASSIGN(self->appID, _value);
}
- (NSString *)appID {
  return self->appID;
}

- (void)setBlogID:(NSString *)_value {
  ASSIGN(self->blogID, _value);
}
- (NSString *)blogID {
  return self->blogID;
}

- (void)setPostID:(NSString *)_value {
  ASSIGNCOPY(self->postID, _value);
}
- (NSString *)postID {
  return self->postID;
}

- (void)setLogin:(NSString *)_value {
  ASSIGN(self->login, _value);
}
- (NSString *)login {
  return self->login;
}

- (void)setPassword:(NSString *)_value {
  ASSIGN(self->password, _value);
}
- (NSString *)password {
  return self->password;
}

- (void)setDoPublish:(BOOL)_flag {
  self->doPublish = _flag;
}
- (BOOL)doPublish {
  return self->doPublish;
}

/* blogs relative to clientObject */

- (id)blog {
  NSString *bid;

  if ((bid = [self blogID]) == nil)
    return nil;
  
  return [[self clientObject] lookupBlogWithID:bid inContext:[self context]];
}

- (NSArray *)fetchAllBlogInfos {
  return [[self clientObject] 
	        bloggerFetchAllBlogInfosInContext:[self context]];
}

- (id)post {
  NSString *pid;
  
  if ((pid = [self postID]) == nil)
    return nil;
  
  return [[self clientObject] lookupPostWithID:pid inContext:[self context]];
}

/* action */

- (id)defaultAction {
  [self logWithFormat:@"called unimplemented Blogger API call ..."];
  return nil;
}

- (id)deletePostAction {
  id post, result;
  
  if ((post = [self post]) == nil) {
    return [NSException exceptionWithName:@"DidNotFindPost"
			reason:@"did not find specified posting"
			userInfo:nil];
  }
  if ([post isKindOfClass:[NSException class]])
    return post;
  
  result = [post lookupName:@"DELETE" inContext:[self context] acquire:NO];
  result = [result callOnObject:post inContext:[self context]];
  if ([result isKindOfClass:[NSException class]])
    return result;
  
  return result;
}

@end /* BloggerAction */
