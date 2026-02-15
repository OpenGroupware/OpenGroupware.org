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

#ifndef __SkyDBDocumentDataSource_H__
#define __SkyDBDocumentDataSource_H__

#include <OGoRawDatabase/SkyAdaptorDataSource.h>

/**
 * @class SkyDBDataSource
 * @brief Data source that returns SkyDBDocument objects.
 *
 * SkyDBDataSource extends SkyAdaptorDataSource by wrapping
 * the raw dictionaries fetched from the database into
 * SkyDBDocument instances. It handles document creation,
 * insertion, update and deletion, validating documents
 * before each operation.
 *
 * The entity name is taken from the current fetch
 * specification and determines which database table is
 * accessed. Created documents are initialized with columns
 * derived from the table's attribute list.
 *   
 * TODO: we need a schema, eg the SkyDocumentType filled with the attributes
 *       available for the datasource.
 *
 * @see SkyDBDocument
 * @see SkyAdaptorDataSource
 */
@interface SkyDBDataSource : SkyAdaptorDataSource
{
}

@end

#endif /* __SkyDBDocumentDataSource_H__ */
