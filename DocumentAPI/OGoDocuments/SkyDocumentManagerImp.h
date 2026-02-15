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

#ifndef __OGoDocuments_SkyDocumentManagerImp_H__
#define __OGoDocuments_SkyDocumentManagerImp_H__

#include <OGoDocuments/SkyDocumentManager.h>

/**
 * @class SkyDocumentManager
 * @brief Private implementation of the SkyDocumentManager
 *        protocol.
 *
 * Provides the concrete implementation that resolves
 * OGo documents by EOGlobalID or URL. Uses a
 * plug-in resolver architecture: GID resolvers are
 * discovered via NGBundleManager and cached for reuse.
 *
 * Maintains a URL-to-GID cache (urlToGID) for fast
 * repeated lookups. The base URL follows the scheme
 * "skyrix://hostname/instance-id/".
 *
 * This is a private header; consumers should
 * program against the SkyDocumentManager protocol.
 *
 * @see SkyDocumentManager (protocol)
 * @see SkyDocumentGlobalIDResolver
 */

@class NSMutableArray, NSMutableDictionary;
@class LSCommandContext;

@interface SkyDocumentManager : NSObject < SkyDocumentManager >
{
  id             context;
  NSMutableArray *gidResolver;

  /* caches */
  NSMutableDictionary *urlToGID;
}

- (id)initWithContext:(LSCommandContext *)_ctx;

@end

#endif /* __SkyDocumentManagerImp_H__ */
