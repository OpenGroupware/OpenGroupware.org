/*
  Copyright (C) 2006 Helge Hess

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

#include <LSFoundation/LSDBObjectBaseCommand.h>

/**
 * @class LSQualifierSearchCommand
 *
 * Base command for EOQualifier-driven searches. Accepts
 * an EOQualifier (or a string/dictionary/array that is
 * converted into one) and uses OGoSQLGenerator to
 * translate it into raw SQL with proper JOIN, ACL,
 * and archived-object filtering.
 *
 * Supports fetching EOGlobalIDs, primary-key
 * dictionaries, or full Enterprise Objects. Subclasses
 * can override -sqlSelect to customize the SELECT
 * columns, -aclOwnerAttributeName /
 * -aclPrivateAttributeName to enable ACL enforcement,
 * and -addConjoinSQLClausesToArray: to inject additional
 * WHERE conditions.
 *
 * Pagination is available via offset and maxSearchCount.
 * A fetchCount mode returns a COUNT(*) instead of rows.
 */

#ifndef __LSLogic_LSSearch_LSQualifierSearchCommand_H__
#define __LSLogic_LSSearch_LSQualifierSearchCommand_H__

@class NSString, NSNumber, NSArray;
@class EOQualifier;

@interface LSQualifierSearchCommand : LSDBObjectBaseCommand
{
  EOQualifier *qualifier;
  NSArray     *attributes;
  NSNumber    *offset;
  NSNumber    *maxSearchCount;
  BOOL        fetchGlobalIDs;
  BOOL        fetchCount;
  
  NSString *sql;
}

- (void)setFetchGlobalIDs:(BOOL)_fetchGlobalIDs;
- (BOOL)fetchGlobalIDs;

@end

#endif /* __LSLogic_LSSearch_LSQualifierSearchCommand_H__ */
