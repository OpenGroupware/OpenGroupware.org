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

#ifndef __LSFoundation_EODatabaseChannel_LSAdditions_H__
#define __LSFoundation_EODatabaseChannel_LSAdditions_H__

#import <GDLAccess/EODatabaseChannel.h>

@class NSArray;
@class EOSQLQualifier;

/**
 * @category EODatabaseChannel(LSAdditions)
 * @brief Adds global-ID fetching to EODatabaseChannel.
 *
 * Provides convenience methods to fetch an array of
 * EOGlobalIDs for all objects matching a given
 * EOSQLQualifier. The entity is derived from the
 * qualifier's root entity. Optionally accepts sort
 * orderings.
 *
 * @see EOSQLQualifier
 */
@interface EODatabaseChannel(LSAdditions)

/*
  Fetch the global-ids for all objects matching the qualifier. The
  entity scanned is the qualifiers root entity.
*/
- (NSArray *)globalIDsForSQLQualifier:(EOSQLQualifier *)_qualifier;

- (NSArray *)globalIDsForSQLQualifier:(EOSQLQualifier *)_qualifier
  sortOrderings:(NSArray *)_sortOrderings;

@end

#endif /* __LSFoundation_EODatabaseChannel_LSAdditions_H__ */
