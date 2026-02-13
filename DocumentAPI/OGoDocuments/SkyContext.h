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

#ifndef __SkyContext_H__
#define __SkyContext_H__

#include <OGoDocuments/SkyDocumentManager.h>

/**
 * @protocol SkyContext
 * @brief Protocol for contexts that provide document management.
 *
 * Any object conforming to SkyContext can vend a
 * SkyDocumentManager, which is used to resolve documents
 * by URL or global ID.
 *
 * @see SkyDocumentManager
 */
@protocol SkyContext

- (id<SkyDocumentManager>)documentManager;

@end

#include <LSFoundation/LSCommandContext.h>

/**
 * @category LSCommandContext(DocManager)
 * @brief Adds SkyContext conformance to LSCommandContext.
 *
 * Allows the OGo command context to act as a SkyContext,
 * providing access to a SkyDocumentManager instance.
 */
@interface LSCommandContext(DocManager) < SkyContext >
@end

#endif /* __SkyContext_H__ */
