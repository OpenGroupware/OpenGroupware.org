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

#ifndef __Blogger_NSObject_Blogger_H__
#define __Blogger_NSObject_Blogger_H__

#import <Foundation/NSObject.h>

/*
  Category for Blogger related API.
*/

@class NSString, NSArray, NSDictionary, NSCalendarDate;

@interface NSObject(BlogContainer)

- (NSArray *)bloggerFetchAllBlogInfosInContext:(id)_ctx;
- (id)lookupBlogWithID:(NSString *)_blogID inContext:(id)_ctx;

@end

@interface NSObject(BlogObject)

- (NSDictionary *)bloggerBlogInfoInContext:(id)_ctx;
- (NSArray *)bloggerPostIDsInContext:(id)_ctx;

- (NSString *)bloggerPostEntryWithTitle:(NSString *)_title
  description:(NSString *)_content creationDate:(NSCalendarDate *)_date
  inContext:(id)_ctx;

- (id)lookupPostWithID:(NSString *)_postID inContext:(id)_ctx;

@end

@interface NSObject(PostObject)

- (NSString *)bloggerContentInContext:(id)_ctx;
- (NSDictionary *)bloggerPostInfoInContext:(id)_ctx;

@end

#endif /* __Blogger_NSObject_Blogger_H__ */
