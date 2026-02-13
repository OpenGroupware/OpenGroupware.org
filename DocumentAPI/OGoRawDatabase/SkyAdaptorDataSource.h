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

#ifndef __LSFoundation_SkyAdaptorDataSource_H__
#define __LSFoundation_SkyAdaptorDataSource_H__

#include <GDLAccess/EOAdaptorDataSource.h>

/**
 * @class SkyAdaptorDataSource
 * @brief Adaptor data source integrated with LSCommandContext.
 *
 * SkyAdaptorDataSource is a thin wrapper around
 * EOAdaptorDataSource that adds two capabilities:
 *
 * - Manages the database connection and transactions
 *   through an LSCommandContext instead of a standalone
 *   adaptor channel.
 * - Automatically injects the user's timezone into fetch
 *   specification hints so that date values are returned
 *   in the correct time zone.
 *
 * It can connect either to the main OGo database (via the
 * context's channel) or to a remote database specified by
 * an adaptor name and connection dictionary.
 *
 * @see SkyDBDataSource
 * @see EOAdaptorDataSource
 */

@class NSDictionary;

@interface SkyAdaptorDataSource : EOAdaptorDataSource
{
@protected
  id context;
}

/* create a connection to a table contained in the SKYRiX database */
- (id)initWithContext:(id)_ctx;

/* create a connection to a table contained in a remote database */
- (id)initWithContext:(id)_ctx
  adaptorName:(NSString *)_adaptor
  connectionDictionary:(NSDictionary *)_condict
  primaryKeyGenerationDictionary:(NSDictionary *)_pkeydict;

@end

#endif /* __LSFoundation_SkyAdaptorDataSource_H__ */
