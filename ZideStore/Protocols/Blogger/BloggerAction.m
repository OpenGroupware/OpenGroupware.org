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

#include "BloggerAction.h"
#include "NSObject+Blogger.h"
#include "common.h"

@implementation BloggerAction

- (void)dealloc {
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

/* action */

- (id)defaultAction {
  [self logWithFormat:@"called unimplemented Blogger API call ..."];
  return nil;
}

@end /* BloggerAction */
