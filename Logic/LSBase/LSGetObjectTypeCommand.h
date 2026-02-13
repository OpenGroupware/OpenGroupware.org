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

#ifndef __SkyCommands_LSBase_LSGetObjectTypeCommand_H__
#define __SkyCommands_LSBase_LSGetObjectTypeCommand_H__

#include <LSFoundation/LSDBObjectBaseCommand.h>

/**
 * @class LSGetObjectTypeCommand
 *
 * Resolves one or more numeric object IDs to their
 * entity type names (e.g. "Person", "Enterprise",
 * "Date"). First checks the ObjectInfo table for a
 * cached type mapping; if not found, scans all entity
 * tables in the database model for a matching primary
 * key.
 *
 * Supports both single-ID and batch-ID modes. Results
 * are cached in the context under the
 * "LSObjectIdToType" key to avoid repeated lookups.
 *
 * Keys: "objectId"/"oid" (single), "oids" (array).
 * Returns a type name string (single) or an array of
 * type name strings (batch).
 */
@interface LSGetObjectTypeCommand : LSDBObjectBaseCommand
{
@private
  id   oids;
  BOOL singleFetch;
}

@end

#endif /* __SkyCommands_LSBase_LSGetObjectTypeCommand_H__ */
