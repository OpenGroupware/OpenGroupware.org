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

#ifndef __SOGo_SOGoMailConnectionEntry_H__
#define __SOGo_SOGoMailConnectionEntry_H__

#import <Foundation/NSObject.h>

/* 
   SOGoMailConnectionEntry
   
   A cached connection to an IMAP4 server plus some cached objects.
*/

@class NSString, NSDate, NSArray, NSDictionary, NSURL;
@class NGImap4Client;

@interface SOGoMailConnectionEntry : NSObject
{
@public
  NGImap4Client *client;
  NSString      *password;
  NSDate        *creationTime;
  NSDictionary  *subfolders;
  
  /* uids cache */
  NSArray *cachedUIDs;
  NSURL   *uidFolderURL;
  id      uidSortOrdering;
}

- (id)initWithClient:(NGImap4Client *)_client password:(NSString *)_pwd;

/* accessors */

- (NGImap4Client *)client;
- (BOOL)isValidPassword:(NSString *)_pwd;

- (NSDate *)creationTime;

- (void)cacheHierarchyResults:(NSDictionary *)_hierarchy;
- (NSDictionary *)cachedHierarchyResults;
- (void)flushFolderHierarchyCache;

- (id)cachedUIDsForURL:(NSURL *)_url qualifier:(id)_q sortOrdering:(id)_so;
- (void)cacheUIDs:(NSArray *)_uids forURL:(NSURL *)_url
  qualifier:(id)_q sortOrdering:(id)_so;

- (void)flushMailCaches;

@end

#endif /* __SOGo_SOGoMailConnectionEntry_H__ */
