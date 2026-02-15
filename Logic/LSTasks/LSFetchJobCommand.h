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

#ifndef __LSTasks_LSFetchJobCommand_H__
#define __LSTasks_LSFetchJobCommand_H__

#include <LSFoundation/LSDBFetchRelationCommand.h>

@class EOSQLQualifier;

/**
 * @class LSFetchJobCommand
 * @brief Fetches Job records related to a person
 *        (account).
 *
 * Uses the Person-to-Job relation (via `companyId`)
 * to retrieve jobs assigned to accounts. If no object
 * is set, defaults to the currently logged-in account.
 *
 * When `fetchGlobalIDs` is YES, only the primary-key
 * global IDs are fetched instead of full objects,
 * which is more efficient for large result sets.
 *
 * Subclasses can override
 * -_checkConjoinWithQualifier: to refine the SQL
 * qualifier used for fetching.
 */
@interface LSFetchJobCommand : LSDBFetchRelationCommand
{
@private
  BOOL fetchGlobalIDs;
}

- (EOSQLQualifier *)_checkConjoinWithQualifier:(EOSQLQualifier *)_qualifier;

@end

#endif /* __LSTasks_LSFetchJobCommand_H__ */
