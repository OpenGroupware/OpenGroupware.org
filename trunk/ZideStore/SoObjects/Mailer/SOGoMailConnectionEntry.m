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

#include "SOGoMailConnectionEntry.h"
#include "common.h"

@implementation SOGoMailConnectionEntry

- (id)initWithClient:(NGImap4Client *)_client password:(NSString *)_pwd {
  if (_client == nil || _pwd == nil) {
    [self release];
    return nil;
  }
  
  if ((self = [super init])) {
    self->client   = [_client retain];
    self->password = [_pwd    copy];
    
    self->creationTime = [[NSDate alloc] init];
  }
  return self;
}
- (id)init {
  return [self initWithClient:nil password:nil];
}

- (void)dealloc {
  [self->cachedUIDs      release];
  [self->uidFolderURL    release];
  [self->uidSortOrdering release];
  [self->creationTime    release];
  [self->subfolders      release];
  [self->password        release];
  [self->client          release];
  [super dealloc];
}

/* accessors */

- (NGImap4Client *)client {
  return self->client;
}
- (BOOL)isValidPassword:(NSString *)_pwd {
  return [self->password isEqualToString:_pwd];
}

- (NSDate *)creationTime {
  return self->creationTime;
}

- (void)cacheHierarchyResults:(NSDictionary *)_hierarchy {
  ASSIGNCOPY(self->subfolders, _hierarchy);
}
- (NSDictionary *)cachedHierarchyResults {
  return self->subfolders;
}
- (void)flushFolderHierarchyCache {
  [self->subfolders release];
  self->subfolders = nil;
}

- (id)cachedUIDsForURL:(NSURL *)_url qualifier:(id)_q sortOrdering:(id)_so {
  if (_q != nil)
    return nil;
  if (![_so isEqual:self->uidSortOrdering])
    return nil;
  if (![self->uidFolderURL isEqual:_url])
    return nil;
  
  return self->cachedUIDs;
}

- (void)cacheUIDs:(NSArray *)_uids forURL:(NSURL *)_url
  qualifier:(id)_q sortOrdering:(id)_so
{
  if (_q != nil)
    return;

  ASSIGNCOPY(self->uidSortOrdering, _so);
  ASSIGNCOPY(self->uidFolderURL,    _url);
  ASSIGNCOPY(self->cachedUIDs,      _uids);
}

- (void)flushMailCaches {
  ASSIGNCOPY(self->uidSortOrdering, nil);
  ASSIGNCOPY(self->uidFolderURL,    nil);
  ASSIGNCOPY(self->cachedUIDs,      nil);
}

@end /* SOGoMailConnectionEntry */
