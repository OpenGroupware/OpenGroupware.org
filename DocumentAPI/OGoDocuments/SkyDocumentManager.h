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

#ifndef __SkyDocumentManager_H__
#define __SkyDocumentManager_H__

#import <Foundation/NSObject.h>

/*
  This object/protocol manages document-URL/GID relations.
  
  The URLs can be specified as either a NSString or a NSURL object, but are
  always returned as NSURL objects.
  
  SKYRiX URLs:
  
    skyrix://instance-id/id
*/

@class NSArray, NSURL;
@class EOGlobalID;

@protocol SkyDocumentManager

/* accessors */

- (id)context;

/* base URL */

- (NSURL *)skyrixBaseURL;

/* GID->Doc */

- (NSArray *)documentsForGlobalIDs:(NSArray *)_gids;
- (id)documentForGlobalID:(EOGlobalID *)_gid;
- (EOGlobalID *)globalIDForDocument:(id)_doc;

/* URL->Doc */

- (NSArray *)documentsForURLs:(NSArray *)_urls;
- (id)documentForURL:(id)_url;
- (NSURL *)urlForDocument:(id)_doc;

/* GID/URL mappings */

- (NSArray *)globalIDsForURLs:(NSArray *)_urls;
- (EOGlobalID *)globalIDForURL:(id)_url;
- (NSURL *)urlForGlobalID:(EOGlobalID *)_gid;
- (NSArray *)urlsForGlobalIDs:(NSArray *)_gids;

@end

/* GlobalID Resolvers (found using BundleManager ..) */

@protocol SkyDocumentGlobalIDResolver

- (BOOL)canResolveGlobalID:(EOGlobalID *)_gid
  withDocumentManager:(id<SkyDocumentManager>)_dm;

- (NSArray *)resolveGlobalIDs:(NSArray *)_gids
  withDocumentManager:(id<SkyDocumentManager>)_dm;

@end

/* GID/URL conversion protocols */

@protocol SkyURLToGlobalIDConversion
- (EOGlobalID *)globalIDWithDocumentManager:(id<SkyDocumentManager>)_dm;
@end

@protocol SkyGlobalIDToURLConversion
- (NSURL *)urlWithDocumentManager:(id<SkyDocumentManager>)_dm;
@end


#endif /* __SkyDocumentManager_H__ */
