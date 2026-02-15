/*
  Copyright (C) 2000-2005 SKYRIX Software AG

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

#ifndef __SkyDocumentManager_H__
#define __SkyDocumentManager_H__

#import <Foundation/NSObject.h>

@class NSArray, NSURL;
@class EOGlobalID;

/**
 * @protocol SkyDocumentManager
 * @brief Manages document-URL and document-GID mappings.
 *
 * A SkyDocumentManager resolves OGo documents by their URL
 * or EOGlobalID. URLs can be specified as NSString or NSURL
 * but are always returned as NSURL objects.
 *
 * OGo URLs follow the scheme:
 * @code
 *   skyrix://hostname/instance-id/primary-key
 * @endcode
 *
 * @see SkyContext
 * @see SkyDocument
 */
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

/**
 * @protocol SkyDocumentGlobalIDResolver
 * @brief Resolves EOGlobalIDs into document objects.
 *
 * Implementations are discovered via the NGBundleManager
 * using the "SkyDocumentGlobalIDResolver" resource type.
 * Each resolver handles a specific set of global ID types.
 *
 * @see SkyDocumentManager
 */
@protocol SkyDocumentGlobalIDResolver

- (BOOL)canResolveGlobalID:(EOGlobalID *)_gid
  withDocumentManager:(id<SkyDocumentManager>)_dm;

- (NSArray *)resolveGlobalIDs:(NSArray *)_gids
  withDocumentManager:(id<SkyDocumentManager>)_dm;

@end

/**
 * @protocol SkyURLToGlobalIDConversion
 * @brief Allows URL objects to convert themselves to GIDs.
 *
 * Adopted by URL objects that know how to derive their
 * corresponding EOGlobalID given a SkyDocumentManager.
 */
@protocol SkyURLToGlobalIDConversion
- (EOGlobalID *)globalIDWithDocumentManager:(id<SkyDocumentManager>)_dm;
@end

/**
 * @protocol SkyGlobalIDToURLConversion
 * @brief Allows GID objects to convert themselves to URLs.
 *
 * Adopted by EOGlobalID objects that know how to derive
 * their corresponding NSURL given a SkyDocumentManager.
 */
@protocol SkyGlobalIDToURLConversion
- (NSURL *)urlWithDocumentManager:(id<SkyDocumentManager>)_dm;
@end


#endif /* __SkyDocumentManager_H__ */
