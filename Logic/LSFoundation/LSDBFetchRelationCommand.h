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

#ifndef __LSLogic_LSFoundation_LSDBFetchRelationCommand_H__
#define __LSLogic_LSFoundation_LSDBFetchRelationCommand_H__

#include <LSFoundation/LSDBObjectBaseCommand.h>

/**
 * @class LSDBFetchRelationCommand
 * @brief Fetches related objects for a set of source objects
 *   via a foreign-key relationship.
 *
 * Given one or more source objects, this command resolves a
 * relationship by querying the destination entity using an
 * SQL IN clause on the collected source primary keys. It
 * supports both to-one and to-many relationships and can
 * optionally attach the fetched relations back onto the source
 * objects under a configurable "relationKey".
 *
 * Internally the command always works with an array of source
 * objects. The "object" key auto-wraps a single object into
 * an array; use "objects" to supply multiple base objects.
 *
 * Queries are batched to avoid exceeding the maximum IN-clause
 * size (configurable via the
 * LSDBFetchRelationCommand_MAX_SEARCH_COUNT default).
 *
 * @see LSDBObjectBaseCommand
 */

@class NSString, NSArray;
@class EOSQLQualifier, EOEntity;

@interface LSDBFetchRelationCommand : LSDBObjectBaseCommand
{
@private
  NSArray        *currentIds;
  NSString       *relationKey;
  NSString       *sourceKey;
  NSString       *destinationKey;
  NSString       *destinationEntityName;
  BOOL           isToMany;
}

- (EOEntity *)destinationEntity;
- (void)setCurrentIds:(NSArray *)_a;
- (NSArray *)currentIds;
- (BOOL)isToMany;
- (NSString *)sourceKey;
- (NSString *)destinationKey;
- (EOSQLQualifier *)_qualifier;
- (void)setRelationKey:(NSString *)_key;
- (NSString *)relationKey;
- (NSArray *)_fetchRelations;

@end

#endif /* __LSLogic_LSFoundation_LSDBFetchRelationCommand_H__ */
